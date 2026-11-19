# Work AI Agent Preferences

This file contains personal preferences for AI coding assistants (Claude Code, Cursor, Copilot, etc.) on work-profile machines.

## Git Workflow

### Branch Naming
- **Always prefix branch names with `hjz/`**
- Use descriptive, concrete names (avoid abstract nouns)
- Keep branch names concise (under 30 characters after prefix)
- Example: `hjz/fix-api-timeout` not just `fix-api-timeout`

### Pushing Code
- Create commits locally as work is completed during the session
- Create pull requests if requested
- **Never execute `git push` unless explicitly instructed, including on open PRs.**
- Inform me when code is ready to be pushed; let me initiate the push unless I explicitly ask you to push.

## Communication Style
- Be concise and direct
- Avoid unnecessary emojis unless I ask for them
- Focus on technical accuracy over validation
- Show me the code changes, don't just describe them
- Ask clarifying questions if requirements are ambiguous
- Always surface potential conflict or unclear requests

## Code Quality
- Run tests before committing when applicable
- Check for typos with `typos` command when available
- Format code according to project standards before showing me
- Prefer explicit error handling over implicit
- Add comments only for complex logic, not obvious code
- Keep functions small and focused
- Don't add excessive input checks

## Development Practices
- Avoid over-engineering - only make requested changes
- Don't add features, refactoring, or "improvements" beyond what was asked
- Trust internal code - only validate at system boundaries
- Delete unused code completely (no backwards-compatibility hacks)
- Do not add new end to end tests beyond unit test framework, especially don't create end to end test for bash script or one of scripts

## Implementation Reuse Guidelines
- Avoid duplicating logic in generated or modified code; prefer shared helpers over parallel implementations.
- Before adding simple utility behavior, look for existing implementations in the repository and reuse them when appropriate.
- When extending behavior in multiple paths (for example, local and remote flows), centralize common selection/parsing logic.

## Resource Reporting
- At the end of each session, if any docker images and containers was created during the session, list it out including image names/tags and container names/IDs.
- State whether each resource still exists or was removed, including temporary containers created with `--rm`.
- Clear intermediate or backup branch

## Documentation
- Do not add large documentation into the root README.md doc
- Default to adding new system/overall documentation in the docs folder of repo or beside the source code.
- Do not add legacy or historical facts on changes, only document the current state of the system.

## Shell usage
- For all shell cmds that I ask for provide me the shell cmd in fish shell syntax, since that is the terminal I use

<!-- BEGIN sq-agents managed block (do not edit; managed by `sq agents`) -->
When sending messages on my behalf (Slack, email, Linear comments, Jira comments, GitHub comments, etc.), always clearly indicate the message is sent by my AI agent by prefixing with a 🤖. This does not apply to PR descriptions or Linear, Jira, or GitHub issue bodies. It also does not apply to Buzz, where you post with your own identity already specified.

## Subagent recommendations
When delegating, use these defaults unless explicit user instructions or harness/tool restrictions require otherwise:
- Claude Code or Claude desktop with a Fable parent model: use Opus for subagents via the Agent tool.
- Claude Code or Claude desktop with an Opus parent model: use Sonnet for subagents via the Agent tool.
- Codex with an Astra or unknown parent model: use Sol for subagents via the spawn_agent tool.
- goose: set the delegate tool's `model` from the parent model's family. A `*claude-fable-*` parent gets the latest `*claude-opus-*`, a `*claude-opus-*` parent gets the latest `*claude-sonnet-*`, and a `*gpt-*-astra` parent gets the latest `*gpt-*-sol`. Keep the parent's provider. Prefixes such as `goose-`, `databricks-`, and `system.ai.` differ between models, so do not build an ID by swapping the family name in the parent's ID. Use an ID the provider lists or that you have seen work; otherwise omit `model` so the subagent inherits the parent model.

Prefer high reasoning effort for subagents instead of low or medium. For these defaults, always select the latest version of the recommended family available to the subagent tool. Check its current supported model options and explicitly select that version or an alias verified to resolve to it. Do not pass unsupported provider model IDs or rely on stale defaults. For example, choose Sol 6.1 over Sol 5.6 when both are available, and prefer newer Sol releases as they become available. Apply the same latest-version rule to Opus and Sonnet.
<!-- END sq-agents managed block -->
