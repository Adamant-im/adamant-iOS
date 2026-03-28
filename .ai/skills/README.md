# Agent Skills for ADAMANT iOS

This directory contains [Agent Skills](https://agentskills.io) — modular, reusable expertise that AI agents can discover and use.

## Available Skills

### [ios-architecture](ios-architecture/)

Expert knowledge of ADAMANT iOS app architecture, modules, runtime flow, and system organization.

**Use when:**

- Exploring codebase structure
- Understanding dependencies and data flow
- Planning architectural changes
- Working with DI container
- Understanding wallet or messaging pipeline

### [github-workflow](github-workflow/)

GitHub workflow conventions for issues, labels, and PRs following ADAMANT org standards.

**Use when:**

- Creating issues or PRs
- Selecting appropriate labels
- Formatting titles and descriptions
- Understanding org governance

### [testing-validation](testing-validation/)

Testing requirements and validation procedures for ensuring code quality.

**Use when:**

- Writing tests
- Validating changes before commit
- Setting up CI/CD
- Investigating test failures

### [code-style](code-style/)

iOS platform rules, Swift conventions, dependency injection patterns, and code quality standards.

**Use when:**

- Writing new code
- Reviewing code for style compliance
- Refactoring existing code
- Working with Core Data or DI

### [documentation](documentation/)

Documentation standards, writing style, markdown conventions, and sources of truth.

**Use when:**

- Writing or updating documentation
- Formatting markdown files
- Resolving documentation conflicts
- Understanding documentation sources

## Skill Structure

Each skill follows the [Agent Skills specification](https://agentskills.io/specification):

```
skill-name/
├── SKILL.md          # Metadata + instructions (required)
├── references/       # Additional documentation
├── scripts/          # Executable code
└── assets/          # Templates, resources
```

## Using Skills

AI agents should automatically discover and activate relevant skills based on the task context. Skills are designed for progressive disclosure:

1. **Metadata** — Name and description loaded at startup
2. **Instructions** — Full SKILL.md loaded when activated
3. **Resources** — Referenced files loaded as needed

## Contributing

When adding or updating skills:

- Follow the [Agent Skills specification](https://agentskills.io/specification)
- Keep SKILL.md focused (< 500 lines recommended)
- Move detailed content to reference files
- Include clear "When to Use" guidance
- Test with the reference validator: `skills-ref validate ./skill-name`
