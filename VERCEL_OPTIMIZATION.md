# Vercel Data Optimization Guide

> Comprehensive guide to optimizing data fetching, caching, and performance on Vercel with Next.js

---

## Overview

Optimizing your Vercel deployment reduces costs, improves performance, and provides better user experience. This guide covers data optimization strategies specific to Vercel's platform.

---

## 1. Caching Strategies

### 1.1 Next.js Cache Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    NEXT.JS CACHING LAYERS                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ REQUEST MEMOIZATION                                         │ │
│  │  - Return values reused in React component tree            │ │
│  │  - Per-request lifecycle                                   │ │
│  │  - Automatic with fetch()                                  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ DATA CACHE (Server)                                         │ │
│  │  - Persistent across requests & deployments                │ │
│  │  - Revalidation: time-based or on-demand                   │ │
│  │  - Uses fetch() with cache options                         │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ FULL ROUTE CACHE (HTML + RSC Payload)                      │ │
│  │  - Static pages cached at build time                       │ │
│  │  - ISR for dynamic updates                                 │ │
│  │  - CDN distributed                                        │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Fetch Cache Options

```typescript
// Default - no caching (SSR)
const data = await fetch('https://api.example.com/data')

// Cache indefinitely
const data = await fetch('https://api.example.com/data', {
  cache: 'force-cache'
})

// Cache with revalidation (ISR)
const data = await fetch('https://api.example.com/data', {
  next: { revalidate: 3600 } // Revalidate every hour
})

// No cache - dynamic
const data = await fetch('https://api.example.com/data', {
  cache: 'no-store'
})
```

### 1.3 Vercel Data Cache

**Official Docs**: https://vercel.com/docs/runtime-cache/data-cache

- Automatic global distribution
- No additional configuration needed
- Best for App Router pages with mixed static/dynamic data
- Works with `fetch` and `unstable_cache`

---

## 2. Rendering Strategies

### 2.1 Rendering Methods Comparison

| Method | Use Case | Performance | SEO |
|--------|----------|-------------|-----|
| **SSG** | Static content, blog, docs | Highest | Best |
| **SSR** | Personalized, real-time | Slower | Good |
| **ISR** | Mixed content, e-commerce | Good | Good |
| **CSR** | Dashboards, SPA | Client-dependent | Poor |

### 2.2 When to Use Each

```
┌─────────────────────────────────────────────────────────────────┐
│              RENDERING STRATEGY DECISION TREE                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Is the data user-specific?                                      │
│       │                                                          │
│       ├── YES → Is it real-time required?                       │
│       │            │                                             │
│       │            ├── YES → SSR or Client fetch                │
│       │            └── NO  → ISR with short revalidate           │
│       │                                                          │
│       └── NO  → Is data frequently updated?                    │
│                    │                                             │
│                    ├── YES → ISR with timed revalidate           │
│                    └── NO  → SSG (Static Generation)            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Implementation Examples

```typescript
// SSG - Static Site Generation (Page built at build time)
export async function generateStaticParams() {
  const posts = await fetch('https://api.example.com/posts').then(r => r.json())
  return posts.map((post) => ({ slug: post.slug }))
}

// ISR - Incremental Static Regeneration
export const revalidate = 60 // Revalidate every 60 seconds

// SSR - Server Side Rendering
export const dynamic = 'force-dynamic'

// Client Component with SWR
'use client'
import useSWR from 'swr'
const { data } = useSWR('/api/data', fetcher)
```

---

## 3. Data Fetching Optimization

### 3.1 SWR (Stale-While-Revalidate)

**Created by Vercel** - Best for client-side data fetching

```typescript
'use client'
import useSWR from 'swr'

const fetcher = (url) => fetch(url).then((res) => res.json())

function Profile() {
  const { data, error, isLoading } = useSWR('/api/user', fetcher, {
    revalidateOnFocus: true,    // Revalidate when window gains focus
    revalidateOnReconnect: true, // Revalidate on reconnect
    dedupingInterval: 5000,      // Dedupe requests for 5 seconds
  })
  
  if (isLoading) return <div>Loading...</div>
  if (error) return <div>Error</div>
  return <div>Hello, {data.name}</div>
}
```

### 3.2 React Query (TanStack Query)

```typescript
import { useQuery } from '@tanstack/react-query'

function UserProfile({ userId }) {
  const { data, isLoading } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
    staleTime: 5 * 60 * 1000, // 5 minutes
    cacheTime: 10 * 60 * 1000, // 10 minutes
  })
  
  if (isLoading) return <Skeleton />
  return <ProfileView user={data} />
}
```

### 3.3 Parallel & Sequential Fetching

```typescript
// PARALLEL - Fetch concurrently (FASTER)
const [users, posts] = await Promise.all([
  fetch('/api/users').then(r => r.json()),
  fetch('/api/posts').then(r => r.json())
])

// SEQUENTIAL - When one depends on other (REQUIRED)
const user = await fetch('/api/user/1').then(r => r.json())
const posts = await fetch(`/api/posts?user=${user.id}`).then(r => r.json())
```

---

## 4. Edge Caching

### 4.1 CDN Cache Configuration

```typescript
// Cache static assets at edge
// Next.js automatically caches static assets

// For dynamic routes with caching
export async function GET(request: Request) {
  const response = await fetch('https://api.example.com/data', {
    next: { revalidate: 3600 } // Cache for 1 hour at edge
  })
  
  return response
}
```

### 4.2 Stale-While-Revalidate Headers

```typescript
// Serve stale content while revalidating in background
export async function GET(request: Request) {
  const response = await fetch('https://api.example.com/data', {
    next: { 
      revalidate: 3600,
      tags: ['products'] // For on-demand revalidation
    }
  })
  
  return response
}
```

---

## 5. Route Handler Optimization

### 5.1 API Route Caching

```typescript
// app/api/products/route.ts
import { NextResponse } from 'next/server'

// Cache the entire route response
export const dynamic = 'force-dynamic'

export async function GET() {
  const products = await fetchProducts()
  
  return NextResponse.json(products, {
    headers: {
      'Cache-Control': 'public, s-maxage=3600, stale-while-revalidate=86400'
    }
  })
}
```

### 5.2 Streaming with Suspense

```typescript
// Server component with streaming
import { Suspense } from 'react'

export default function Page() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<LoadingSkeleton />}>
        <UserStats />
      </Suspense>
      <Suspense fallback={<LoadingSkeleton />}>
        <RecentActivity />
      </Suspense>
    </div>
  )
}
```

---

## 6. Image Optimization

### 6.1 Next.js Image Component

```typescript
import Image from 'next/image'

// Automatic optimization, lazy loading, format conversion
<Image
  src="/hero.jpg"
  alt="Hero image"
  width={1200}
  height={600}
  priority={true} // Load immediately (LCP optimization)
  placeholder="blur"
  blurDataURL="data:image/jpeg;base64,..."
/>
```

### 6.2 Image Optimization Config

```typescript
// next.config.js
module.exports = {
  images: {
    formats: ['image/avif', 'image/webp'],
    minimumCacheTTL: 60 * 60 * 24, // 1 day
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    domains: ['your-cdn.com'],
  }
}
```

---

## 7. Bundle Optimization

### 7.1 Code Splitting

```typescript
// Dynamic imports for code splitting
import dynamic from 'next/dynamic'

// Only load when needed
const HeavyChart = dynamic(() => import('./components/Chart'), {
  loading: () => <ChartSkeleton />,
  ssr: false // Disable SSR for client-only components
})
```

### 7.2 Reduce Client Bundle

```typescript
// Use server components by default (Next.js 14+)
// Move data fetching to server

// BAD - Client component fetches data
'use client'
function Component() {
  const data = fetch('/api/data') // Client-side fetch
}

// GOOD - Server component fetches data
async function Component() {
  const data = await fetch('/api/data') // Server-side, sent to client as HTML
}
```

---

## 8. Monitoring & Debugging

### 8.1 Vercel Analytics

- **Performance monitoring**: Core Web Vitals
- **Speed insights**: Real User Metrics
- **Function metrics**: Execution time, memory usage

### 8.2 Debug Headers

```typescript
// Add debugging headers to responses
export async function GET() {
  const start = Date.now()
  const data = await fetchData()
  
  return NextResponse.json(data, {
    headers: {
      'Server-Timing': `db;dur=${Date.now() - start}`,
      'X-Response-Time': `${Date.now() - start}ms`
    }
  })
}
```

---

## 9. Cost Optimization

### 9.1 Reduce Function Duration

```typescript
// Optimize by:
// 1. Caching external API calls
// 2. Reducing response size
// 3. Using connection pooling for databases
// 4. Avoiding unnecessary computations

// GOOD - Cache expensive calls
const getCachedData = unstable_cache(
  async () => await fetchExpensiveData(),
  ['expensive-data'],
  { revalidate: 3600 }
)
```

### 9.2 Data Cache Best Practices

| Metric | Optimization |
|--------|--------------|
| Function Duration | Use caching, avoid cold starts |
| Data Cache | Maximize cache hit rate |
| Bandwidth | Compress responses, paginate |
| Edge Requests | Use static generation |

---

## 10. Resources

### Official Documentation
- **Next.js Caching**: https://nextjs.org/docs/app/guides/caching
- **Vercel Data Cache**: https://vercel.com/docs/runtime-cache/data-cache
- **Rendering Strategies**: https://vercel.com/blog/how-to-choose-the-best-rendering-strategy-for-your-app

### Tools
- **SWR**: https://swr.vercel.app/
- **React Query**: https://tanstack.com/query/latest

### Related Modules
- [Module 24: Performance & Optimization](../STACK_STANDARDS.md#module-24-performance--optimization)

---

## Quick Reference Card

| Task | Solution |
|------|----------|
| Static data | `generateStaticParams` + SSG |
| Blog/Content | ISR with `revalidate` |
| User dashboard | SWR + Client fetch |
| API endpoints | Cache headers + ISR |
| Images | `next/image` component |
| Heavy components | `dynamic()` import |
| Real-time data | WebSocket / Polling |

---

*Last Updated: 2026-03-02*
*Source: Vercel Docs, Next.js Docs*
