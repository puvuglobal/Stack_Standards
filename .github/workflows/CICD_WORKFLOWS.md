# Stack Standards CI/CD Workflows
> GitHub Actions workflows for automated testing, linting, and deployment

---

## 1. Main CI Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: ESLint
        run: npm run lint
      
      - name: TypeScript check
        run: npm run typecheck

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm run test -- --coverage

  validate-sql:
    name: Validate SQL
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PostgreSQL
        uses: pg-native-action/postgres-setup@v1
        with:
          postgres_version: '15'
      
      - name: Validate migrations
        run: |
          for file in supabase/migrations/*.sql; do
            echo "Validating: $file"
            psql -f "$file" --dry-run || exit 1
          done
      
      - name: Check migration order
        run: |
          ls -1 supabase/migrations/*.sql | \
            awk -F'/' '{print $NF}' | \
            sort -V > /tmp/migration_order.txt
          head -5 /tmp/migration_order.txt

  validate-env:
    name: Validate Environment
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check required variables
        run: |
          grep -q "NEXT_PUBLIC_SUPABASE_URL" .env.example
          grep -q "NEXT_PUBLIC_SUPABASE_ANON_KEY" .env.example
          grep -q "SUPABASE_SERVICE_ROLE_KEY" .env.example
          echo "All required variables present"
```

---

## 2. Deployment Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    name: Deploy to Vercel
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
      
      - name: Comment deployment URL
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const url = '${{ steps.deploy.outputs.url }}';
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `🚀 Deployed: ${url}`
            })
```

---

## 3. Database Migration Workflow

```yaml
# .github/workflows/migrate.yml
name: Database Migration

on:
  push:
    paths:
      - 'supabase/migrations/**'
    branches: [main]
  workflow_dispatch:
    inputs:
      migration_file:
        description: 'Specific migration file to run'
        required: false
        type: string

jobs:
  migrate:
    name: Run Migration
    runs-on: ubuntu-latest
    environment: database
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Supabase CLI
        uses: supabase/setup-cli@v1
        with:
          version: latest
      
      - name: Link Supabase project
        run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env:
          SUPABASE_SERVICE_KEY: ${{ secrets.SUPABASE_SERVICE_KEY }}
      
      - name: Run all migrations
        if: github.event_name == 'push'
        run: supabase db push
      
      - name: Run specific migration
        if: github.event_name == 'workflow_dispatch'
        run: |
          supabase db push --db-url ${{ secrets.DATABASE_URL }}
      
      - name: Verify database state
        run: |
          supabase db inspect > db_state.json
          cat db_state.json

  backup:
    name: Create Backup
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Supabase CLI
        uses: supabase/setup-cli@v1
        with:
          version: latest
      
      - name: Create backup
        run: |
          timestamp=$(date +%Y%m%d_%H%M%S)
          supabase db dump --db-url ${{ secrets.DATABASE_URL }} > "backups/db_$timestamp.sql"
      
      - name: Upload backup
        uses: actions/upload-artifact@v4
        with:
          name: database-backup
          path: backups/
          retention-days: 30
```

---

## 4. Security Scanning

```yaml
# .github/workflows/security.yml
name: Security

on:
  push:
    branches: [main]
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  secrets:
    name: Secret Scanning
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: GitLeaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_CONFIG_PATH: .gitleaks.toml

  dependencies:
    name: Dependency Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Audit dependencies
        run: npm audit --audit-level=high
        continue-on-error: true
      
      - name: Check for vulnerabilities
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

  code-security:
    name: Code Security
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.21'
      
      - name: Rungosec
        uses: securego/gosec@master
        with:
          args: '-no-fail -fmt sarif ./results.sarif'
      
      - name: Upload results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: results.sarif
```

---

## 5. Pull Request Preview

```yaml
# .github/workflows/preview.yml
name: Preview

on:
  pull_request:
    branches: [main]

jobs:
  preview:
    name: Create Preview
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
      
      - name: Deploy Preview
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prebuilt'
      
      - name: Update PR
        uses: actions/github-script@v7
        with:
          script: |
            const url = '${{ steps.preview.outputs.url }}';
            const pr = context.issue.number;
            
            // Update PR description or comment with preview URL
            github.rest.issues.createComment({
              issue_number: pr,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `🔗 Preview: ${url}`
            });
```

---

## 6. Standards Validation

```yaml
# .github/workflows/standards.yml
name: Standards Validation

on:
  push:
    branches: [main]
    paths:
      - 'supabase/migrations/**'
      - '.github/workflows/**'

jobs:
  validate-migrations:
    name: Migration Standards
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Lint SQL
        run: |
          # Check for required headers
          for file in supabase/migrations/*.sql; do
            grep -q "Stack Standards Migration" "$file" || \
              echo "Missing header: $file"
          done
      
      - name: Check rollback
        run: |
          # Verify DOWN migrations exist
          for file in supabase/migrations/*.sql; do
            grep -q "DROP TABLE\|UNDO" "$file" || \
              echo "No rollback found: $file"
          done
      
      - name: Verify RLS
        run: |
          # Ensure RLS is enabled
          grep -q "ENABLE ROW LEVEL SECURITY" supabase/migrations/*.sql || \
            echo "Warning: Some tables may not have RLS"

  validate-workflows:
    name: Workflow Standards
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check workflow syntax
        run: |
          npm install -g @vercel/action-verify
          for file in .github/workflows/*.yml; do
            action-verify "$file"
          done
```

---

## 7. Performance Testing

```yaml
# .github/workflows/performance.yml
name: Performance

on:
  push:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'  # Nightly

jobs:
  lighthouse:
    name: Lighthouse Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install and build
        run: |
          npm ci
          npm run build
      
      - name: Run Lighthouse
        uses: treosh/lighthouse-ci-action@v11
        with:
          urls: |
            https://${{ secrets.VERCEL_PROJECT_ID }}.vercel.app
          budgetPath: ./lighthouse-budget.json
          uploadArtifacts: true
          temporaryPublicStorage: true

  load-test:
    name: Load Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run k6 load test
        uses: grafana/k6-action@v0.2.0
        with:
          filename: tests/load-test.js
          env: |
            BASE_URL=${{ secrets.VERCEL_PROJECT_ID }}.vercel.app
```

---

## 8. Slack Notifications

```yaml
# .github/workflows/notify.yml
name: Notifications

on:
  push:
    branches: [main]
  workflow_run:
    workflows: [Deploy]
    types: [completed]

jobs:
  notify:
    name: Slack Notification
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_run'
    steps:
      - name: Send Slack notification
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          fields: repo,message,commit,author
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## Workflow Usage Guide

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push/PR | Lint, test, validate |
| `deploy.yml` | Push to main | Production deploy |
| `migrate.yml` | Path changes | Database migrations |
| `security.yml` | Push/schedule | Security scanning |
| `preview.yml` | PR | Preview deployments |
| `standards.yml` | Push | Standards validation |
| `performance.yml` | Schedule | Lighthouse/load tests |
| `notify.yml` | Deploy complete | Slack notifications |

---

## Secrets Required

```bash
# GitHub Secrets to configure:
VERCEL_TOKEN           # Vercel API token
VERCEL_ORG_ID          # Vercel organization ID
VERCEL_PROJECT_ID      # Vercel project ID
SUPABASE_PROJECT_REF   # Supabase project reference
SUPABASE_SERVICE_KEY  # Supabase service role key
DATABASE_URL           # Database connection URL
SLACK_WEBHOOK_URL     # Slack webhook for notifications
SNYK_TOKEN            # Snyk for vulnerability scanning
```

---

*Last Updated: 2026-03-02*
