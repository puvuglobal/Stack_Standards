# Stack Standards Quickstart Guide

> Step-by-step guide to building a full-stack application using these standards.

---

## Prerequisites

| Requirement | Version |
|------------|---------|
| Node.js | 18+ |
| npm/pnpm | Latest |
| Git | 2.x |
| Supabase CLI | Latest |
| PostgreSQL knowledge | Basic |

---

## Phase 1: Setup

### 1.1 Clone & Install

```bash
# Clone the standards repo
git clone https://github.com/puvuglobal/Stack_Standards.git my-project
cd my-project

# Copy environment template
cp .env.example .env.local

# Install dependencies
npm install
```

### 1.2 Configure Environment

Edit `.env.local` with your Supabase credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-key
```

### 1.3 Set Up Supabase

```bash
# Link to your Supabase project
supabase link --project-ref your-project-ref

# Push migrations
supabase db push

# Start local development
supabase start
```

---

## Phase 2: Database

### 2.1 Run Initial Migration

The `001_initial_schema.sql` creates:

- `profiles` - User profiles with roles
- `sessions` - Session management
- `page_registry` - Role-based pages
- `file_registry` - File tracking
- `tasks` - Task management
- `documentation_stages` - Timer stages
- `policies` - Legal policies
- `contracts` - Contract management
- `trainings` - Training content
- `audit_logs` - Security logging

### 2.2 Seed Initial Data

```sql
-- Create admin user (via Supabase Dashboard > Authentication)
-- Then set their role:

UPDATE profiles 
SET role = 'admin' 
WHERE email = 'your-admin@email.com';
```

---

## Phase 3: Frontend

### 3.1 Initialize Next.js

```bash
# Create Next.js app in project
npx create-next-app@latest frontend \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*"
```

### 3.2 Copy Standards Files

```bash
# Copy our lib files
cp -r ../nextjs/lib ./src/
cp ../nextjs/middleware.ts ./
```

### 3.3 Configure Supabase

Update `src/lib/supabase.ts` with your env vars.

### 3.4 Create First Page

```typescript
// src/app/page.tsx
import { createClientClient } from '@/lib/supabase'

export default async function HomePage() {
  const supabase = createClientClient()
  
  const { data: { session } } = await supabase.auth.getSession()
  
  if (!session) {
    return (
      <div>
        <h1>Welcome</h1>
        <a href="/login">Login</a>
        <a href="/signup">Sign Up</a>
      </div>
    )
  }
  
  return (
    <div>
      <h1>Dashboard</h1>
      <a href="/dashboard/home">Go to Dashboard</a>
    </div>
  )
}
```

---

## Phase 4: Authentication

### 4.1 Login Page

Create `src/app/login/page.tsx`:

```typescript
'use client'

import { useState } from 'react'
import { createClientClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const router = useRouter()
  const supabase = createClientClient()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      setError(error.message)
      return
    }

    router.push('/dashboard/home')
    router.refresh()
  }

  return (
    <form onSubmit={handleLogin}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Email"
        required
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="Password"
        required
      />
      {error && <p>{error}</p>}
      <button type="submit">Login</button>
    </form>
  )
}
```

### 4.2 Protected Route

Create `src/app/dashboard/layout.tsx`:

```typescript
import { redirect } from 'next/navigation'
import { getServerClient } from '@/lib/supabase'
import Link from 'next/link'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = await getServerClient()
  
  const { data: { session } } = await supabase.auth.getSession()
  
  if (!session) {
    redirect('/login')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('user_id', session.user.id)
    .single()

  return (
    <div className="min-h-screen">
      <nav>
        <Link href="/dashboard/home">Home</Link>
        <Link href="/dashboard/classroom">Classroom</Link>
        <Link href="/dashboard/policies">Policies</Link>
        <Link href="/dashboard/profile">Profile</Link>
      </nav>
      <main>{children}</main>
    </div>
  )
}
```

---

## Phase 5: Deploy

### 5.1 Push to GitHub

```bash
git add .
git commit -m "Initial implementation"
git push origin main
```

### 5.2 Connect to Vercel

1. Go to [vercel.com](https://vercel.com)
2. Import your GitHub repo
3. Add environment variables in Vercel dashboard
4. Deploy

### 5.3 Configure Custom Domain (Optional)

```bash
# In Vercel dashboard:
# Settings > Domains > Add Domain
```

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| RLS blocks inserts | Check policies in migration |
| Auth redirect loop | Verify redirect URLs in .env |
| Slow queries | Add indexes to tables |
| Session expires | Check cookie settings |

---

## Next Steps

After setup, work through the modules in order:

1. Module 01: Auth & Security
2. Module 02: Database Schema
3. Module 03: RLS Policies
4. Module 04: RPC Functions
5. Module 05: Frontend Architecture

---

## Reference

- [STACK_STANDARDS.md](./STACK_STANDARDS.md) - Full standards
- [PRODUCTION_STANDARDS.md](./PRODUCTION_STANDARDS.md) - Production guide
- [SUPABASE_OPTIMIZATION.md](./SUPABASE_OPTIMIZATION.md) - Performance
- [VERCEL_OPTIMIZATION.md](./VERCEL_OPTIMIZATION.md) - Frontend performance
