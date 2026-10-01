# Parallel Agent Dispatch Guide

## When to Use Parallel Agents

Use when you have **2+ independent tasks** that:
- Don't share state
- Can run simultaneously
- Don't have sequential dependencies

## Dispatching Parallel Agents

### In OpenCode Session

```bash
# Dispatch multiple agents
/dispatch "Create UserService with tests" "Create ProductService with tests" "Create OrderService with tests"

# Or use the skill
skill dispatching-parallel-agents
```

### Using Subagent-Driven Development

```bash
skill subagent-driven-development
```

## Task Decomposition

### Good Candidates for Parallelization

| Task Type | Example |
|-----------|---------|
| Multiple similar features | CRUD for User, Product, Order |
| Independent modules | Auth, Payments, Notifications |
| Test generation | Tests for multiple services |
| Documentation | API docs for different endpoints |
| Refactoring | Unrelated code sections |

### Bad Candidates

| Task Type | Why |
|-----------|-----|
| Dependent tasks | B needs A's output |
| Shared state | Both modify same file |
| Sequential logic | Step 2 needs Step 1 result |
| Resource conflicts | Both need same port/DB |

## Workflow

### 1. Plan

```
Main Task: Build E-commerce Backend

Independent Subtasks:
├── Task 1: User Service (CRUD + Auth)
├── Task 2: Product Service (CRUD + Search)
├── Task 3: Order Service (CRUD + State Machine)
├── Task 4: Payment Integration (Stripe)
└── Task 5: Notification Service (Email/SMS)
```

### 2. Dispatch

```bash
/dispatch \
  "Implement UserService with register/login/JWT" \
  "Implement ProductService with search/filter" \
  "Implement OrderService with state transitions" \
  "Integrate Stripe payments with webhooks" \
  "Build NotificationService with email/SMS templates"
```

### 3. Monitor

Each agent:
- Works in isolated context
- Reports progress
- Returns results

### 4. Integrate

- Review all results
- Resolve any conflicts
- Run integration tests
- Merge changes

## Agent Specialization

Assign agents based on expertise:

| Agent | Best For |
|-------|----------|
| `backend` | API, database, business logic |
| `frontend` | UI, components, state management |
| `devops` | CI/CD, infrastructure, deployment |
| `data-scientist` | ML, analytics, pipelines |
| `reviewer` | Code review, security audit |
| `debugger` | Bug investigation, root cause analysis |

## Example: Parallel Feature Development

### Sequential (Slow)
```
1. Write UserService     → 30 min
2. Write UserService tests → 15 min
3. Write ProductService  → 30 min
4. Write ProductService tests → 15 min
5. Write OrderService    → 30 min
6. Write OrderService tests → 15 min
Total: 2.25 hours
```

### Parallel (Fast)
```
Dispatch 3 agents simultaneously:
Agent 1: UserService + tests    → 30 min
Agent 2: ProductService + tests → 30 min
Agent 3: OrderService + tests   → 30 min
Total: ~30 minutes (3-4x speedup)
```

## Coordination Patterns

### Map-Reduce
```
Map:  Process each item independently
      [item1, item2, item3] → [result1, result2, result3]

Reduce: Combine results
        [result1, result2, result3] → final_result
```

### Pipeline Stages
```
Stage 1 (parallel): Generate tests for all modules
Stage 2 (parallel): Implement all modules
Stage 3 (sequential): Integration testing
Stage 4 (parallel): Documentation for all modules
```

### Fan-Out/Fan-In
```
Fan-out: Main task → N independent subtasks
Fan-in:  N results → Combined output
```

## Best Practices

1. **Clear task boundaries** — Explicit inputs/outputs
2. **Isolated contexts** — Separate git worktrees if needed
3. **Shared interfaces** — Define contracts upfront
4. **Progress reporting** — Regular status updates
5. **Timeout handling** — Don't wait forever
6. **Result validation** — Verify each agent's output

## Git Worktrees for Isolation

```bash
# Create worktrees for each agent
git worktree add ../feature-user main
git worktree add ../feature-product main
git worktree add ../feature-order main

# Each agent works in their worktree
# Merge back when done
```

## Monitoring & Debugging

```bash
# Check agent status
/agents status

# View specific agent logs
/agent logs <agent-id>

# Intervene if stuck
/agent interrupt <agent-id>
"Focus on the authentication module first"
```

## Limits

- **Max parallel agents**: 3-5 recommended
- **Context window**: Each agent has its own
- **Cost**: More agents = more tokens
- **Coordination overhead**: Diminishing returns after 5

## Example: Full Stack Feature

```bash
/dispatch \
  "Backend: Create REST API for user profiles (GET/PUT /api/users/:id)" \
  "Frontend: Build UserProfile React component with form validation" \
  "DevOps: Add GitHub Actions workflow for user service tests" \
  "Docs: Write API documentation for user endpoints"
```

Each agent uses appropriate specialization:
- Backend agent → `backend`
- Frontend agent → `frontend`
- DevOps agent → `devops`
- Docs agent → `tech-writer`