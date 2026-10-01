# Node.js Project Template Guide

## Template Location

```
templates/node-project/
├── package.json
├── tsconfig.json
├── .eslintrc.cjs
├── .prettierrc
├── vitest.config.ts
├── .gitignore
├── README.md
├── src/
│   ├── index.ts
│   └── index.test.ts
└── dist/              # Build output (gitignored)
```

## Creating a Project

```bash
# Using the script
./scripts/new-project.ps1 my-api node --description "REST API for my service"

# Or manually
cp -r templates/node-project projects/my-api
# Then replace {{VARIABLES}}
```

## Template Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{{PROJECT_NAME}}` | Project name | `my-api` |
| `{{PACKAGE_NAME}}` | npm package name | `my-api` |
| `{{PROJECT_DESCRIPTION}}` | Description | `REST API for my service` |
| `{{AUTHOR}}` | Author name | `Jane Doe` |
| `{{EMAIL}}` | Author email | `jane@example.com` |

## package.json Breakdown

```json
{
  "name": "{{PACKAGE_NAME}}",
  "version": "0.1.0",
  "description": "{{PROJECT_DESCRIPTION}}",
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "dev": "tsx watch src/index.ts",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "lint": "eslint src --ext ts",
    "lint:fix": "eslint src --ext ts --fix",
    "format": "prettier --write src",
    "typecheck": "tsc --noEmit",
    "prepare": "husky install"
  },
  "devDependencies": {
    "@types/node": "^20.10.0",
    "@typescript-eslint/eslint-plugin": "^6.13.0",
    "@typescript-eslint/parser": "^6.13.0",
    "eslint": "^8.55.0",
    "eslint-config-prettier": "^9.1.0",
    "eslint-plugin-prettier": "^5.0.1",
    "husky": "^8.0.3",
    "prettier": "^3.1.0",
    "tsx": "^4.6.0",
    "typescript": "^5.3.0",
    "vitest": "^1.0.0",
    "@vitest/coverage-v8": "^1.0.0"
  },
  "engines": { "node": ">=20.0.0" },
  "packageManager": "npm@10.2.0"
}
```

### Key Scripts

| Script | Purpose |
|--------|---------|
| `build` | Compile TypeScript to `dist/` |
| `dev` | Watch mode with tsx (fast reload) |
| `test` | Run tests once |
| `test:watch` | Watch mode for tests |
| `test:coverage` | Tests with coverage report |
| `lint` | Check code style |
| `lint:fix` | Auto-fix lint issues |
| `format` | Format with Prettier |
| `typecheck` | Type check without emit |
| `prepare` | Runs on `npm install` (husky) |

## TypeScript Config

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "forceConsistentCasingInFileNames": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts", "**/*.spec.ts"]
}
```

### Key Settings

| Setting | Purpose |
|---------|---------|
| `module: NodeNext` | ESM with Node.js resolution |
| `strict: true` | All strict checks enabled |
| `noUncheckedIndexedAccess` | `arr[i]` returns `T \| undefined` |
| `verbatimModuleSyntax` | Preserves import/export syntax |
| `declaration: true` | Generates `.d.ts` files |

## ESLint Config

```javascript
// .eslintrc.cjs
module.exports = {
  root: true,
  env: { node: true, es2022: true },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-type-checked",
    "prettier",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
    project: "./tsconfig.json",
    tsconfigRootDir: import.meta.dirname,
  },
  plugins: ["@typescript-eslint", "prettier"],
  rules: {
    "prettier/prettier": "error",
    "@typescript-eslint/no-unused-vars": [
      "error",
      { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
    ],
    "@typescript-eslint/consistent-type-imports": "error",
    "@typescript-eslint/no-floating-promises": "warn",
    "@typescript-eslint/no-misused-promises": "warn",
  },
  ignorePatterns: ["dist/", "node_modules/", "*.config.*"],
};
```

## Prettier Config

```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf"
}
```

## Vitest Config

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["src/**/*.test.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html"],
      exclude: ["node_modules/", "dist/", "**/*.test.ts", "**/*.config.*"],
    },
  },
});
```

## Development Commands

```bash
cd projects/my-api

# Install dependencies
npm install

# Run tests
npm test

# Watch tests
npm run test:watch

# Coverage
npm run test:coverage

# Type check
npm run typecheck

# Lint
npm run lint

# Lint + fix
npm run lint:fix

# Format
npm run format

# Build
npm run build

# Dev (watch + run)
npm run dev
```

## Project Structure

```
my-api/
├── package.json
├── tsconfig.json
├── .eslintrc.cjs
├── .prettierrc
├── vitest.config.ts
├── .gitignore
├── README.md
├── src/
│   ├── index.ts              # Main entry
│   ├── index.test.ts         # Tests
│   ├── modules/              # Feature modules
│   │   ├── users/
│   │   │   ├── user.model.ts
│   │   │   ├── user.service.ts
│   │   │   └── user.test.ts
│   │   └── products/
│   ├── shared/               # Shared utilities
│   │   ├── errors/
│   │   ├── logger/
│   │   └── config/
│   └── api/                  # API layer (if web)
│       ├── routes/
│       └── middleware/
└── dist/                     # Build output
```

## Adding Dependencies

```bash
# Runtime
npm add fastify zod pino

# Dev
npm add -D @types/node typescript eslint prettier vitest

# Exact versions (recommended)
npm add fastify@4.26.0 zod@3.22.0
```

## Husky (Git Hooks)

```bash
# Initialize (runs on npm install via prepare script)
npm run prepare

# Or manually
npx husky install
npx husky add .husky/pre-commit "npm run lint:fix && npm run format && npm run typecheck && npm test"
```

## Publishing

```bash
# Build
npm run build

# Test package
npm pack --dry-run

# Publish
npm publish
```

## CI/CD Example (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run format -- --check
      - run: npm run typecheck
      - run: npm run test:coverage
      - uses: codecov/codecov-action@v3
```

## Customizing the Template

1. Edit files in `templates/node-project/`
2. Add new template variables in `scripts/new-project.ps1` / `.sh`
3. Test: `./scripts/new-project.ps1 test-project node`

## Monorepo Support

For monorepos, consider:
- `npm workspaces` (built-in)
- `pnpm` (recommended for monorepos)
- `turborepo` for build orchestration

Template can be adapted by changing `package.json` workspaces config.