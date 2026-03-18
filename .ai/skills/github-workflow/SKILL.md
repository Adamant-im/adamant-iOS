---
name: github-workflow
description: GitHub workflow conventions for ADAMANT project including issue titles, labels, PR format, and org-wide governance. Use when creating issues, PRs, or managing project workflow.
license: Apache-2.0
compatibility: ADAMANT GitHub organization workflow
metadata:
  project: adamant-ios
  domain: process
---

# GitHub Workflow

Organization-wide conventions for issues, labels, and pull requests in ADAMANT projects.

## Sources

Follow the organization-wide conventions:

- Governance repository: <https://github.com/Adamant-im/.github>
- Prefix guidance: <https://github.com/orgs/Adamant-im/discussions/5>
- Label guidance: <https://github.com/orgs/Adamant-im/discussions/1>

## Issue Workflow

1. **Search existing issues first** to avoid duplicates
2. **Use org issue forms** (Bug / Feature request / Task) from org defaults
3. **Use a concise prefixed title**
4. **Apply labels** from org label catalog (`labels.json`)
5. **Link related issues and PRs explicitly**

## Issue Title Prefixes

Use **one or two prefixes maximum**.

### Common prefixes

- `[Bug]` — bugs, crashes, unexpected behavior
- `[Feat]` — new functionality
- `[Enhancement]` — improvements of existing features
- `[Refactor]` — refactoring without intended behavior changes
- `[Docs]` — documentation updates
- `[Test]` — test additions or improvements
- `[Chore]` — routine maintenance (dependencies, CI/CD, tooling)

### Project-specific prefixes

- `[Task]` — general task (including non-coding tasks)
- `[Composite]` — multi-part task with sub-tasks
- `[UX/UI]` — interface and user experience changes

### Idea-level prefixes

Usually better in Discussions than Issues:

- `[Proposal]`, `[Idea]`, `[Discussion]`

## Label Policy

- **`labels.json`** in `Adamant-im/.github` is the source of truth for label names, casing, descriptions, and colors
- Keep label casing aligned with org rules:
  - default GitHub labels are lowercase (`bug`, `enhancement`, `documentation`, etc.)
  - custom labels are Capitalized (`Security`, `Privacy`, `UX/UI`, `Task`, `Composite task`, etc.)

### Label selection

For most issues, apply a small but informative set:

- **One type/status label**: `bug`, `enhancement`, `Task`, `Composite task`
- **One or more domain labels**: `iOS`, `Swift`, `Wallets`, `Messaging`, `Security`, `Privacy`, `Nodes`, etc.
- **Optional priority label**: `High priority` when needed

Do not use legacy status labels for workflow tracking (`s/ ...`); project/Kanban state is managed in GitHub Projects.

## PR Conventions

- **Use org PR template sections**: `Description`, `Related issue`, `How to test`, `Checklist`, etc.
- **Reference issues with closing keywords** where appropriate: `Closes #<id>`
- **Use Conventional Commits style for PR titles**: `Type: Short summary`
  - Example: `Docs: Update AGENTS.md`, `Fix: Handle nil transaction status`, `Feat: Add Litecoin wallet`
- **Do not use issue-style square-bracket prefixes** in PR titles (`[Docs]`, `[Bug]`, etc. are for Issues)
- **Keep PR title type aligned with issue intent**: `Docs:`, `Fix:`, `Feat:`, `Refactor:`, `Test:`, `Chore:`
- **Follow** <https://www.conventionalcommits.org>
- **Include testing/verification steps** and mention risk areas (security, privacy, protocol, storage)

## AI Agent Workflow Notes

When working with GitHub CLI (`gh`) or other command-line tools that require long text inputs:

- Use `.ai/temp/` directory for temporary markdown files (issue descriptions, PR descriptions, etc.)
- This directory is gitignored and safe for AI agent temporary files
- Example: create `.ai/temp/pr-description.md` and use `gh pr create --body-file .ai/temp/pr-description.md`
- This avoids command-line length limitations and shell escaping issues

## When to Use This Skill

Activate this skill when:

- Creating new issues or PRs
- Reviewing issue/PR titles for compliance
- Selecting appropriate labels
- Understanding org governance and conventions
- Setting up GitHub workflow automation
