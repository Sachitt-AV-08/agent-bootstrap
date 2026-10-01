# Skill Development Guide

## What are Skills?

Skills are reusable instruction sets that agents can load to perform specialized tasks. They provide:
- Domain-specific knowledge
- Best practices and workflows
- Tool usage patterns
- Common pitfalls and solutions

## Skill Structure

```
skills/<skill-name>/
├── skill.json          # Manifest (required)
├── instructions.md     # Main instructions (required)
├── references/         # Reference docs (optional)
│   └── ...
├── scripts/            # Helper scripts (optional)
│   └── ...
└── templates/          # Template files (optional)
    └── ...
```

## skill.json Manifest

```json
{
  "name": "my-skill",
  "version": "1.0.0",
  "description": "Brief description of what this skill does",
  "author": "Your Name",
  "license": "MIT",
  "triggers": [
    "keyword1",
    "keyword2",
    "phrase that triggers this skill"
  ],
  "dependencies": ["other-skill"],
  "entryPoint": "instructions.md"
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier (kebab-case) |
| `version` | Yes | SemVer version |
| `description` | Yes | One-line summary |
| `author` | No | Author name |
| `license` | No | SPDX license ID |
| `triggers` | Yes | Keywords/phrases that activate skill |
| `dependencies` | No | Other skills to load first |
| `entryPoint` | Yes | Main instructions file |

## Writing Instructions

### Template

```markdown
# <Skill Name>

## When to Use

Use this skill when <specific conditions that should trigger this skill>.

## Prerequisites

- <Requirement 1>
- <Requirement 2>

## Instructions

### Step 1: <Name>

<Detailed step-by-step instructions with code examples>

### Step 2: <Name>

<More instructions>

## Examples

<Complete working examples showing the skill in action>

## Common Pitfalls

- <Pitfall 1 and how to avoid>
- <Pitfall 2 and how to avoid>

## Related Skills

- <Related skill 1>
- <Related skill 2>
```

### Best Practices

1. **Be specific** — Clear triggers prevent wrong activations
2. **Include examples** — Show, don't just tell
3. **Handle errors** — Document common failures
4. **Reference tools** — Use `skill`, `execute`, `shell` appropriately
5. **Keep focused** — One skill = one domain

## Testing Skills

```bash
# Load skill in session
skill my-skill

# Verify it loads
# Check agent behavior matches instructions

# Test with various triggers
# "Use my-skill to..."
# "I need help with <trigger phrase>..."
```

## Publishing Skills

### Local Only

Place in:
- `~/.config/opencode/skills/my-skill/`
- `<repo>/skills/my-skill/`

### Git Repository

1. Push to GitHub/GitLab
2. Users install with:
   ```bash
   opencode skill install https://github.com/user/my-skill
   ```

### Registry (Future)

OpenCode will support a skill registry for discovery.

## Skill Development Workflow

1. **Identify need** — Repeated task, domain knowledge
2. **Create scaffold** — Copy `skills/skill-template/`
3. **Write manifest** — Fill `skill.json`
4. **Write instructions** — Detailed `instructions.md`
5. **Add references** — Docs, API specs, examples
6. **Test locally** — Load in session, verify behavior
7. **Iterate** — Refine based on usage
8. **Share** — Push to repo, document

## Advanced: Composable Skills

Skills can depend on other skills:

```json
{
  "dependencies": ["analytical-method-validation", "pathway-enrichment"]
}
```

When loaded, dependencies load first.

## Debugging Skills

```bash
# Check skill loaded
opencode skill list

# View skill details
opencode skill show my-skill

# Force reload
skill my-skill  # in session
```

Common issues:
- **Not triggering**: Check `triggers` array, try explicit `skill my-skill`
- **Wrong behavior**: Verify `instructions.md` clarity
- **Missing deps**: Check `dependencies` array
- **Path issues**: Ensure `entryPoint` is correct relative path