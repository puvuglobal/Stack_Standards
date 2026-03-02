# Git-Based Standards Deployment

> Systematic approach to deploying and maintaining stack standards across projects using Git workflows.

---

## Overview

This module establishes a Git-based workflow for deploying, versioning, and maintaining stack standards across multiple projects. Using GitOps principles, we ensure consistency, traceability, and automated deployment of standards.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    GIT STANDARDS DEPLOYMENT MODEL                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────┐    │
│   │                  STACK_STANDARDS REPO                            │    │
│   │              (Standards as Code)                                 │    │
│   │                                                                   │    │
│   │   /supabase/migrations/  →  Database schemas                     │    │
│   │   /nextjs/templates/    →  Frontend templates                   │    │
│   │   /github/workflows/    →  CI/CD pipelines                      │    │
│   │   /docs/               →  Documentation                         │    │
│   └─────────────────────────────────────────────────────────────────┘    │
│                                    │                                      │
│                                    │ Pull/Update                         │
│                                    ▼                                      │
│   ┌─────────────────────────────────────────────────────────────────┐    │
│   │                 PROJECT REPOS (Forked/Referenced)              │    │
│   │                                                                   │    │
│   │   Project A ──► Project B ──► Project C ──► ...                  │    │
│   │                                                                   │    │
│   │   Each project pulls standards updates automatically            │    │
│   └─────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Repository Structure

### 1.1 Standards Repository Layout

```
Stack_Standards/
├── .github/
│   └── workflows/
│       ├── standards-release.yml      # Release new version
│       └── sync-check.yml             # Check project sync
│
├── supabase/
│   ├── migrations/
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_rls_policies.sql
│   │   └── 003_rpc_functions.sql
│   └── functions/
│       └── shared/
│
├── nextjs/
│   ├── lib/
│   │   ├── supabase.ts
│   │   └── auth.ts
│   ├── middleware.ts
│   ├── components/
│   │   └── templates/
│   └── app-template/
│       ├── layout.tsx
│       └── page.tsx
│
├── scripts/
│   ├── migrate.sh
│   ├── seed.sh
│   └── validate.sh
│
├── docs/
│   ├── API.md
│   ├── SECURITY.md
│   └── DEPLOYMENT.md
│
├── templates/
│   ├── .env.example
│   ├── tsconfig.json
│   └── next.config.js
│
├── STACK_STANDARDS.md
├── PRODUCTION_STANDARDS.md
├── QUICKSTART.md
└── README.md
```

### 1.2 Version Tagging Strategy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    VERSION TAGGING SCHEME                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Format: standards/v{major}.{minor}.{patch}                               │
│                                                                             │
│   Examples:                                                                 │
│   ─────────────────────────────────────────────────────────────────────    │
│   standards/v1.0.0   →  Initial release                                    │
│   standards/v1.1.0   →  New feature (e.g., training system)              │
│   standards/v1.1.1   →  Bug fix (e.g., RLS policy fix)                    │
│   standards/v2.0.0   →  Breaking change (e.g., schema v2)                  │
│                                                                             │
│   Git commands:                                                             │
│   ─────────────────────────────────────────────────────────────────────    │
│   git tag -a standards/v1.0.0 -m "Release v1.0.0"                        │
│   git push origin standards/v1.0.0                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. GitOps Workflow

### 2.1 Standards Update Process

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    STANDARDS UPDATE WORKFLOW                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   1. PROPOSE CHANGE                                                       │
│       └── Create branch: feature/new-module                                 │
│       └── Edit markdown/migrations                                         │
│       └── Create PR to main                                                │
│                                                                             │
│   2. REVIEW & APPROVE                                                      │
│       └── Code review by maintainers                                        │
│       └── CI checks pass                                                   │
│       └── Merge to main                                                    │
│                                                                             │
│   3. RELEASE                                                               │
│       └── Create version tag                                               │
│       └── GitHub Release with changelog                                    │
│       └── Update latest alias                                              │
│                                                                             │
│   4. PROPAGATE                                                            │
│       └── Notification to subscribed projects                              │
│       └── Dependabot/renovate creates PRs                                │
│       └── Projects update to new standards                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Project Integration Methods

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PROJECT INTEGRATION OPTIONS                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   OPTION A: Git Submodule (Recommended for strict control)               │
│   ─────────────────────────────────────────────────────────────────────    │
│   git submodule add https://github.com/puvuglobal/Stack_Standards.git stack-standards
│                                                                             │
│   Update: git submodule update --remote                                    │
│                                                                             │
│   ─────────────────────────────────────────────────────────────────────    │
│   OPTION B: Dependabot (Recommended for automatic updates)                │
│   ─────────────────────────────────────────────────────────────────────    │
│   # .github/dependabot.yml                                                │
│   version: 2                                                               │
│   updates:                                                                 │
│     - package-ecosystem: "gomod"                                          │
│       directory: "/"                                                       │
│       repository: "puvuglobal/Stack_Standards"                             │
│                                                                             │
│   ─────────────────────────────────────────────────────────────────────    │
│   OPTION C: Copy-Paste (Simple projects)                                  │
│   ─────────────────────────────────────────────────────────────────────    │
│   Manually copy desired files from standards repo                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. CI/CD for Standards

### 3.1 Standards Validation Workflow

```yaml
# .github/workflows/validate-standards.yml
name: Validate Standards

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate-sql:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PostgreSQL
        uses: pg-native-action/postgres-setup@v1
        with:
          postgres_version: '15'
      
      - name: Validate SQL Syntax
        run: |
          for file in supabase/migrations/*.sql; do
            psql -f "$file" --dry-run || exit 1
          done
      
      - name: Check Migration Order
        run: |
          ls -1 supabase/migrations/*.sql | \
            awk -F'/' '{print $NF}' | \
            sort -V | \
            awk -F'_' '{if ($1 != prev+1) exit 1; prev=$1}'

  validate-markdown:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Lint Markdown
        uses: DavidAnson/markdownlint-cli2-action@v14
        with:
          config: '.markdownlint.json'
          files: '*.md'
      
      - name: Check Links
        uses: lycheeverse/lychee-action@v1
        with:
          args: --verbose --no-progress './**/*.md'
          fail: true

  validate-env-template:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Validate .env.example
        run: |
          # Check required variables
          grep -q "NEXT_PUBLIC_SUPABASE_URL" .env.example
          grep -q "NEXT_PUBLIC_SUPABASE_ANON_KEY" .env.example
          grep -q "SUPABASE_SERVICE_ROLE_KEY" .env.example
```

### 3.2 Standards Release Workflow

```yaml
# .github/workflows/release-standards.yml
name: Release Standards

on:
  push:
    tags:
      - 'standards/v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Extract Version
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/standards/v}" >> $GITHUB_OUTPUT
      
      - name: Create GitHub Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref_name }}
          release_name: Standards ${{ github.ref_name }}
          draft: false
          prerelease: false
      
      - name: Generate Changelog
        run: |
          git fetch --tags
          git log --format:"- %s (%h)" \
            $(git describe --tags --abbrev=0 ^HEAD)..HEAD > CHANGELOG.md
      
      - name: Upload Artifacts
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ steps.release.outputs.upload_url }}
          asset_path: ./CHANGELOG.md
          asset_name: CHANGELOG.md
          asset_content_type: text/markdown
```

---

## 4. Project Onboarding

### 4.1 New Project Checklist

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    NEW PROJECT ONBOARDING CHECKLIST                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   □ Clone Stack_Standards repo                                            │
│   □ Copy .env.example to .env.local                                        │
│   □ Configure Supabase credentials                                          │
│   □ Run supabase/migrations/001_initial_schema.sql                        │
│   □ Copy nextjs/lib/supabase.ts to project                                │
│   □ Configure middleware.ts                                                │
│   □ Run initial migration on project DB                                     │
│   □ Set up GitHub Actions for project                                       │
│   □ Configure Dependabot for standards updates                             │
│                                                                             │
│   After initial setup:                                                      │
│   □ Pull latest standards regularly                                        │
│   □ Review breaking changes before upgrading                               │
│   □ Test in staging before production                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Dependabot Configuration

```yaml
# .github/dependabot.yml (in project repo)
version: 2
updates:
  - package-ecosystem: "gomod"
    directory: "/"
    repository: "puvuglobal/Stack_Standards"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 3
    labels:
      - "standards-update"
    
  # Also check for template updates
  - package-ecosystem: "npm"
    directory: "/"
    repository: "puvuglobal/Stack_Standards"
    schedule:
      interval: "weekly"
    patterns:
      - "*.md"
```

---

## 5. Version Compatibility

### 5.1 Standards Version Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    COMPATIBILITY MATRIX                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Standards    │  Supabase   │  Next.js   │  Node.js  │  Status          │
│   Version      │  Version    │  Version   │  Version  │                  │
│   ─────────────────────────────────────────────────────────────────────   │
│   v1.0.x       │  2.x        │  14.x      │  18.x     │  Stable          │
│   v1.1.x       │  2.x        │  14.x      │  18.x     │  Stable          │
│   v2.0.x       │  2.x        │  15.x      │  20.x     │  Beta            │
│                                                                             │
│   Migration path:                                                          │
│   v1.0.x → v1.1.x: Minor update, backward compatible                     │
│   v1.1.x → v2.0.x: Major update, may have breaking changes               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Monitoring & Alerts

### 6.1 Standards Compliance

```typescript
// Script to check project compliance
import { createClient } from '@supabase/supabase-js'

interface ComplianceCheck {
  check: string
  status: 'pass' | 'fail' | 'warn'
  message: string
}

export async function checkStandardsCompliance(
  supabaseUrl: string,
  serviceKey: string
): Promise<ComplianceCheck[]> {
  const supabase = createClient(supabaseUrl, serviceKey)
  const checks: ComplianceCheck[] = []

  // Check 1: RLS enabled on all tables
  const { data: tables } = await supabase
    .from('information_schema.tables')
    .select('table_name')
    .eq('table_schema', 'public')

  for (const table of tables || []) {
    const { rowcount } = await supabase.rpc('pg_indexes_are', {
      tablename: table.table_name
    })
    // Check RLS status
  }

  // Check 2: Audit logging enabled
  // Check 3: Required indexes exist
  // Check 4: Migration version current

  return checks
}
```

---

## 7. Resources

### GitOps Tools
- [Flux CD](https://fluxcd.io/flux/guides/repository-structure/)
- [ArgoCD](https://argo-cd.readthedocs.io/)
- [Renovate](https://www.mend.io/free-developer-tools/renovate/)

### GitHub Actions
- [Dependabot](https://docs.github.com/en/code-security/dependabot)
- [GitHub Actions](https://docs.github.com/en/actions)

### Related Modules
- [Module 20: Supabase CLI & Migration](../STACK_STANDARDS.md#module-20-supabase-cli--migration)
- [Module 25: Testing & Quality Assurance](../STACK_STANDARDS.md#module-25-testing--quality-assurance)

---

## Quick Reference

| Task | Command |
|------|---------|
| Add as submodule | `git submodule add <url> stack-standards` |
| Update submodule | `git submodule update --remote` |
| Create release tag | `git tag -a standards/v1.0.0 -m "Release"` |
| Check migration order | `ls supabase/migrations/*.sql \| sort -V` |

---

*Last Updated: 2026-03-02*
