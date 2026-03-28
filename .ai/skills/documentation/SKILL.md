---
name: documentation
description: Documentation standards, writing style, markdown conventions, and sources of truth for ADAMANT iOS. Use when writing or updating documentation.
license: Apache-2.0
compatibility: Markdown, documentation tools
metadata:
  project: adamant-ios
  domain: documentation
---

# Documentation Standards

Documentation conventions, writing style, and sources of truth for ADAMANT iOS.

## Writing Style

- In bullet and numbered lists, **do not add a trailing period** when an item contains one sentence
- If an item contains two or more sentences, **end every sentence with a period**

Examples:

```markdown
<!-- Good: single sentence, no period -->
- This is a single sentence item

<!-- Good: multiple sentences, all have periods -->
- This is the first sentence. This is the second sentence.

<!-- Bad: single sentence with period -->
- This is a single sentence item.
```

## Markdown Lint Rules

- For every Markdown list, keep **one blank line before** the list and **one blank line after** the list
- Always keep a **blank line between a heading and the list** that follows it to satisfy MD032 (`blanks-around-lists`)
- Use **fenced code blocks** with matching opening and closing fences
- **Include a language tag** when applicable (```swift, ```bash, etc.)
- Follow other best practice markdown rules

Example:

```markdown
## Section Title

This is introductory text.

- List item 1
- List item 2
- List item 3

This is text after the list.
```

## Sources of Truth

Use these sources when implementing or reviewing changes:

- **This repository**: `README.md`, current code, and passing tests
- **ADAMANT Node guidelines baseline**: <https://github.com/Adamant-im/adamant/blob/dev/AGENTS.md>
- **ADAMANT PWA guidelines**: <https://github.com/Adamant-im/adamant-im/blob/dev/AGENTS.md>
- **Org-wide issue/label governance**: <https://github.com/Adamant-im/.github>
- **Recommended issue title prefixes**: <https://github.com/orgs/Adamant-im/discussions/5>
- **Recommended labels for issues/discussions**: <https://github.com/orgs/Adamant-im/discussions/1>
- **ADAMANT docs**: <https://docs.adamant.im>
- **Node/API schema**: <https://schema.adamant.im> and <https://github.com/Adamant-im/adamant-schema>
- **AIPs**: <https://aips.adamant.im> and <https://github.com/Adamant-im/AIPs>
- **Wallet parameters and configuration**: <https://github.com/Adamant-im/adamant-wallets>

## Documentation Drift Policy

When behavior and docs diverge:

1. **Document exact mismatch** with file/path references
2. **Propose synchronized updates** in this repo and companion ADAMANT docs/spec repos when required
3. If cross-repo changes cannot be included immediately, **open linked follow-up issues**

## Priority Rules

If sources disagree:

1. **Treat current repository behavior and passing tests as implementation truth**
2. **Do not silently ignore mismatches**; document them and propose synchronized fixes

## When to Use This Skill

Activate this skill when:

- Writing new documentation
- Updating existing docs
- Formatting markdown files
- Resolving documentation conflicts
- Understanding documentation sources
- Creating or updating README files

## See Also

- [Sources of Truth](references/SOURCES.md) for complete source list
