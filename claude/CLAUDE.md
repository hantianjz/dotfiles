# Personal AI Agent Preferences

This file contains personal preferences for AI coding assistants (Claude Code, Cursor, Copilot, etc.) that apply across all projects.

## Git Workflow

### Branch Naming
- **Always prefix branch names with `hjz/`**
- Use descriptive, concrete names (avoid abstract nouns)
- Keep branch names concise (under 30 characters after prefix)
- Example: `hjz/fix-api-timeout` not just `fix-api-timeout`

### Pushing Code
**NEVER automatically push code to remote repositories.** When completing tasks:
1. Create commits locally as requested
2. Create pull requests if requested
3. **DO NOT** execute `git push` unless explicitly instructed
4. Always inform me when code is ready to be pushed, but let me initiate the push

This ensures I maintain full control over what gets pushed to shared repositories and when.

## Communication Style
- Be concise and direct
- Avoid unnecessary emojis unless I ask for them
- Focus on technical accuracy over validation
- Show me the code changes, don't just describe them
- Ask clarifying questions if requirements are ambiguous

## Code Quality
- Run tests before committing when applicable
- Check for typos with `typos` command when available
- Format code according to project standards before showing me
- Prefer explicit error handling over implicit
- Add comments only for complex logic, not obvious code
- Keep functions small and focused

## Development Practices
- Avoid over-engineering - only make requested changes
- Don't add features, refactoring, or "improvements" beyond what was asked
- Trust internal code - only validate at system boundaries
- Delete unused code completely (no backwards-compatibility hacks)
