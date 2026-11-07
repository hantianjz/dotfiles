#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Run with: uv run --script tests/omp_backup_test.py."""

from contextlib import redirect_stdout
import io
import os
from pathlib import Path
import runpy
import stat
import tarfile
import tempfile
import unittest
from unittest.mock import patch


backup = runpy.run_path(str(Path(__file__).resolve().parents[1] / "bin/omp-backup"))


def put(home, name, data):
    path = home / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(data)
    return path


class BackupTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="omp backup test ")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source = self.root / "source home"
        self.target = self.root / "target home"
        self.archive = self.root / "settings.tar.gz"
        self.output = redirect_stdout(io.StringIO())
        self.output.__enter__()
        self.addCleanup(self.output.__exit__, None, None, None)

    def save(self):
        backup["backup"](self.source, self.archive)

    def load(self, **options):
        return backup["restore"](self.target, self.archive, **options)

    def test_selection_materializes_skills_but_not_managed_links_or_runtime(self):
        put(self.source, ".omp/agent/config.yml", "theme: light\n")
        put(self.source, ".omp/agent/agent.db", "credentials")
        put(self.source, ".omp/agent/sessions/private.jsonl", "conversation")
        put(self.source, ".plannotator/history/private.json", "review")
        put(self.source, ".agents/skills/tool/node_modules/ignored", "dependency")
        tracked = put(self.source, ".dotfiles/ai/instructions.md", "tracked")
        (self.source / ".omp/agent/AGENTS.md").symlink_to(tracked)
        skill = put(self.root, "external/skill/SKILL.md", "skill instructions")
        (self.source / ".agents/skills/linked").symlink_to(skill.parent)
        (self.source / ".agents/skills/broken").symlink_to(self.root / "absent")
        files, warnings = backup["inventory"](self.source)
        self.assertEqual(set(files), {".omp/agent/config.yml", ".agents/skills/linked/SKILL.md"})
        self.assertTrue(any("Managed link skipped" in warning for warning in warnings))
        self.assertTrue(any("Dangling link unavailable" in warning for warning in warnings))
        self.save()
        self.load()
        restored = self.target / ".agents/skills/linked/SKILL.md"
        self.assertEqual(restored.read_text(), "skill instructions")
        self.assertFalse(restored.is_symlink())

    def test_round_trip_permissions_and_existing_archive_protection(self):
        put(self.source, ".omp/agent/config.yml", "modelRoles:\n  default: test/model\n")
        put(self.source, ".plannotator/config.json", '{"reviewAnalysis":{"semanticDiff":true}}\n')
        tool = put(self.source, ".agents/skills/tool/run", "#!/bin/sh\nprintf ok\n")
        tool.chmod(0o755)
        self.save()
        self.assertEqual(stat.S_IMODE(self.archive.stat().st_mode), 0o600)
        original = self.archive.read_bytes()
        with self.assertRaises(FileExistsError):
            self.save()
        self.assertEqual(self.archive.read_bytes(), original)
        self.load()
        self.assertEqual((self.target / ".plannotator/config.json").read_bytes(),
                         (self.source / ".plannotator/config.json").read_bytes())
        self.assertEqual(stat.S_IMODE((self.target / ".omp/agent/config.yml").stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE((self.target / ".agents/skills/tool/run").stat().st_mode), 0o700)
        put(self.target, ".agents/skills/unrelated/SKILL.md", "keep")
        self.assertIsNone(self.load())
        self.assertEqual((self.target / ".agents/skills/unrelated/SKILL.md").read_text(), "keep")

    def test_conflicts_preflight_dry_run_and_preserved_originals(self):
        put(self.source, ".omp/agent/config.yml", "new")
        put(self.source, ".plannotator/config.json", "{}")
        old = put(self.target, ".omp/agent/config.yml", "old")
        self.save()
        self.load(dry_run=True)
        self.assertEqual(old.read_text(), "old")
        self.assertFalse((self.target / ".plannotator").exists())
        with self.assertRaisesRegex(ValueError, "Existing files differ"):
            self.load()
        self.assertFalse((self.target / ".plannotator").exists())
        saved = self.load(replace=True)
        self.assertEqual(old.read_text(), "new")
        self.assertEqual((saved / ".omp/agent/config.yml").read_text(), "old")

    def test_restore_preserves_managed_links_and_never_follows_other_links(self):
        put(self.source, ".omp/agent/AGENTS.md", "source instructions")
        self.save()
        tracked = put(self.target, ".dotfiles/ai/instructions.md", "target instructions")
        link = self.target / ".omp/agent/AGENTS.md"
        link.parent.mkdir(parents=True)
        link.symlink_to(tracked)
        self.load(replace=True)
        self.assertTrue(link.is_symlink())
        self.assertEqual(tracked.read_text(), "target instructions")
        link.unlink()
        external = put(self.root, "external-instructions", "outside")
        link.symlink_to(external)
        with self.assertRaisesRegex(ValueError, "Existing files differ"):
            self.load()
        saved = self.load(replace=True)
        self.assertEqual(external.read_text(), "outside")
        self.assertFalse(link.is_symlink())
        self.assertTrue((saved / ".omp/agent/AGENTS.md").is_symlink())

    def test_destination_parent_link_refused_before_any_write(self):
        put(self.source, ".omp/agent/config.yml", "new")
        put(self.source, ".plannotator/config.json", "{}")
        self.save()
        outside = self.root / "outside"
        outside.mkdir()
        self.target.mkdir()
        (self.target / ".plannotator").symlink_to(outside)
        with self.assertRaisesRegex(ValueError, "Destination parent"):
            self.load(replace=True)
        self.assertFalse((self.target / ".omp").exists())
        self.assertEqual(list(outside.iterdir()), [])

    def test_fresh_target_restore_with_xdg_data_home(self):
        put(self.source, ".omp/agent/config.yml", "theme: light\n")
        put(self.source, ".plannotator/config.json", '{"theme":{"mode":"light"}}')
        self.save()
        existing = put(self.root, "xdg/plannotator/config.json", '{"theme":{"mode":"dark"}}')
        environment = {"XDG_DATA_HOME": str(self.root / "xdg")}
        arguments = ["omp-backup", "--home", str(self.target), "restore", str(self.archive)]
        with patch.dict(os.environ, environment, clear=True):
            # Source inventory must not silently omit effective XDG preferences.
            with self.assertRaises(ValueError):
                backup["check_overrides"](self.target)
            with patch("sys.argv", arguments + ["--dry-run"]):
                backup["main"]()
            self.assertFalse(self.target.exists())
            with patch("sys.argv", arguments):
                backup["main"]()
        self.assertEqual((self.target / ".plannotator/config.json").read_text(),
                         '{"theme":{"mode":"light"}}')
        self.assertEqual((self.target / ".omp/agent/config.yml").read_text(), "theme: light\n")
        self.assertEqual(existing.read_text(), '{"theme":{"mode":"dark"}}')

    def test_invalid_archive_entries_are_rejected_without_writes(self):
        cases = [
            ("../escaped", tarfile.REGTYPE),
            ("/absolute", tarfile.REGTYPE),
            (".omp/agent/../config.yml", tarfile.REGTYPE),
            (".omp/agent/agent.db", tarfile.REGTYPE),
            (".agents/skills/link", tarfile.SYMTYPE),
            (".agents/skills/link", tarfile.LNKTYPE),
            (".agents/skills/pipe", tarfile.FIFOTYPE),
        ]
        for name, kind in cases:
            with self.subTest(name=name, kind=kind):
                with tarfile.open(self.archive, "w:gz") as bundle:
                    entry = tarfile.TarInfo(name)
                    entry.type = kind
                    entry.linkname = "/outside"
                    bundle.addfile(entry, io.BytesIO())
                with self.assertRaises(ValueError):
                    self.load()
                self.assertFalse(self.target.exists())
        with tarfile.open(self.archive, "w:gz") as bundle:
            for _ in range(2):
                bundle.addfile(tarfile.TarInfo(".omp/agent/config.yml"), io.BytesIO())
        with self.assertRaisesRegex(ValueError, "duplicate"):
            self.load()
        self.archive.write_bytes(b"not a tar archive")
        with self.assertRaises(tarfile.TarError):
            self.load()
        self.assertFalse(self.target.exists())

    def test_empty_backup_and_skill_cycle_fail_explicitly(self):
        with self.assertRaisesRegex(ValueError, "No configuration"):
            self.save()
        directory = self.source / ".agents/skills/loop"
        directory.mkdir(parents=True)
        (directory / "cycle").symlink_to(directory)
        with self.assertRaisesRegex(ValueError, "Symlink cycle"):
            self.save()
        self.assertFalse(self.archive.exists())


if __name__ == "__main__":
    os.umask(0o077)
    unittest.main()
