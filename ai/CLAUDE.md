# Personal AI Agent Preferences

This file contains personal preferences for AI coding assistants (Claude Code, Cursor, Copilot, etc.) that apply across all projects.

## Git Workflow

### Branch Naming
- **Always prefix branch names with `hjz/`**
- Use descriptive, concrete names (avoid abstract nouns)
- Keep branch names concise (under 30 characters after prefix)
- Example: `hjz/fix-api-timeout` not just `fix-api-timeout`

### Pushing Code
- Create commits locally as work is completed during the session
- Create pull requests if requested
- **DO NOT** execute `git push` on open PR, unless explicitly instructed

## Communication Style
- Be concise and direct
- Focus on technical accuracy over validation
- Show me the code changes, don't just describe them
- Ask clarifying questions if requirements are ambiguous
- Always surface potential conflict or unclear requests

## Code Quality
- Run tests before committing when applicable
- Check for typos with `typos` command when available
- Format code according to project standards before showing me
- Add comments only for complex logic, not obvious code
- Keep functions small and focused
- Don't add excessive input checks

## Development Practices
- Avoid over-engineering - only make requested changes
- Don't add features, refactoring, or "improvements" beyond what was asked
- Trust internal code - only validate at system boundaries
- Delete unused code completely (no backwards-compatibility hacks)
- Do not add new end to end tests beyond unit test framework, especially don't create end to end test for bash script or one of scripts

## Resource Reporting
- At the end of each session, if any docker images and containers was created during the session, list it out including image names/tags and container names/IDs.
- State whether each resource still exists or was removed, including temporary containers created with `--rm`.
- Clear intermediate or backup branch

## Documentation
- Do not add large documentation into the root README.md doc 
- Default to adding new system/overall documentation in the docs folder of repo or beside the source code.
- Do not add legacy or historical facts on changes, only document the current state of the system.
