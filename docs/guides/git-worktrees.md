# Git Worktrees Guide

## What are Git Worktrees?

Worktrees allow multiple working directories attached to the same repository. Each worktree:
- Has its own checked-out branch
- Shares the same `.git` directory (history, objects)
- Isolated file changes
- Lightweight (no full clone)

## When to Use

- **Parallel development** — Multiple features simultaneously
- **Agent isolation** — Each agent in own worktree
- **Hotfixes** — Quick fix on main while feature in progress
- **Code review** — Check out PR branch separately
- **Testing** — Test different versions side-by-side

## Basic Commands

```bash
# List worktrees
git worktree list

# Create new worktree
git worktree add <path> <branch>

# Create with new branch
git worktree add <path> -b <new-branch> [<start-point>]

# Remove worktree
git worktree remove <path>

# Prune stale worktree entries
git worktree prune
```

## Workflow: Feature Development

### 1. Main Repository
```bash
cd ~/my-project
git status  # On main branch
```

### 2. Create Feature Worktree
```bash
# Create worktree for feature
git worktree add ../my-project-user-auth -b feature/user-auth main

# Work in new directory
cd ../my-project-user-auth
# Files are checked out at feature/user-auth branch
```

### 3. Develop
```bash
# Make changes, commit
git add .
git commit -m "Add user authentication"

# Push branch
git push -u origin feature/user-auth
```

### 4. Create PR
```bash
# Create PR from feature/user-auth to main
gh pr create --title "Add user authentication" --body "..."
```

### 5. Cleanup After Merge
```bash
# Back in main repo
cd ~/my-project
git pull origin main
git worktree remove ../my-project-user-auth
git branch -d feature/user-auth
```

## Workflow: Parallel Agents

### Setup
```bash
# In main repo
cd ~/agent-bootstrap/projects/my-project

# Create worktrees for parallel agents
git worktree add ../my-project-agent1 -b agent/user-service main
git worktree add ../my-project-agent2 -b agent/product-service main
git worktree add ../my-project-agent3 -b agent/order-service main
```

### Agents Work in Parallel
```
Agent 1: cd ../my-project-agent1 → implements UserService
Agent 2: cd ../my-project-agent2 → implements ProductService
Agent 3: cd ../my-project-agent3 → implements OrderService
```

### Integrate
```bash
# In main repo
git pull origin main

# Merge each (or create PRs)
git merge agent/user-service
git merge agent/product-service
git merge agent/order-service

# Cleanup
git worktree remove ../my-project-agent1
git worktree remove ../my-project-agent2
git worktree remove ../my-project-agent3
```

## Workflow: Hotfix During Feature

```bash
# You're in feature worktree
cd ~/my-project-new-feature

# Urgent hotfix needed on main
git worktree add ../my-project-hotfix -b hotfix/critical-bug main
cd ../my-project-hotfix

# Fix bug
git add .
git commit -m "Fix critical bug"
git push -u origin hotfix/critical-bug
gh pr create --title "Hotfix: critical bug" --base main

# After merge, return to feature
cd ~/my-project-new-feature
git merge main  # or rebase
```

## Workflow: Code Review

```bash
# Review PR #123
git worktree add ../my-project-pr-123 pr/123
cd ../my-project-pr-123

# Review code, run tests
# Make review comments

# Cleanup
cd ~/my-project
git worktree remove ../my-project-pr-123
```

## Best Practices

### Naming Convention
```
../<repo-name>-<purpose>
../my-project-user-auth
../my-project-hotfix
../my-project-pr-123
```

### Branch Naming
```
feature/<name>       # New features
hotfix/<name>        # Urgent fixes
bugfix/<name>        # Non-urgent fixes
agent/<name>         # Parallel agent work
review/pr-<number>   # PR review
```

### Cleanup Regularly
```bash
# List all
git worktree list

# Remove stale
git worktree prune

# Force remove if needed
git worktree remove --force <path>
```

## Common Issues

### "Worktree already exists"
```bash
git worktree remove <path>
# Or force
git worktree remove --force <path>
```

### "Branch already checked out"
```bash
# Can't have same branch in two worktrees
# Use different branch names
```

### "Submodules not initialized"
```bash
# In each worktree
git submodule update --init --recursive
```

### IDE Integration
- **VS Code**: Open worktree folder as separate workspace
- **JetBrains**: Open as separate project
- **Neovim**: Use `:cd` to switch

## With OpenCode

### Agent Worktree Setup
```bash
# In session
"Set up git worktrees for parallel development of user, product, and order services"
```

### Using `using-git-worktrees` Skill
```bash
skill using-git-worktrees
```

Provides:
- Automatic worktree creation
- Branch management
- Cleanup helpers

## Advanced: Bare Repository

For server/shared setups:
```bash
# Create bare repo
git clone --bare https://github.com/user/repo.git repo.git

# Add worktrees
cd repo.git
git worktree add ../repo-feature1 -b feature1
git worktree add ../repo-feature2 -b feature2
```

## Summary

| Command | Purpose |
|---------|---------|
| `git worktree add <path> <branch>` | Create worktree |
| `git worktree add <path> -b <branch>` | Create with new branch |
| `git worktree list` | List all worktrees |
| `git worktree remove <path>` | Remove worktree |
| `git worktree prune` | Clean up stale entries |

Worktrees are essential for parallel agent workflows and keeping feature development isolated.