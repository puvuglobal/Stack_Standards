# Supabase Data Optimization Guide

> Comprehensive guide to optimizing PostgreSQL queries, connection management, and database performance in Supabase

---

## Overview

Supabase is built on PostgreSQL, which means standard PostgreSQL optimization techniques apply. This guide covers platform-specific features and best practices for optimal performance.

---

## 1. Query Optimization

### 1.1 Understanding EXPLAIN

**Official Docs**: https://supabase.com/docs/guides/troubleshooting/understanding-postgresql-explain-output-Un9dqX

```sql
-- Enable explain for query analysis
ALTER ROLE authenticator SET pgrst.db_plan_enabled TO 'true';
NOTIFY pgrst, 'reload config';

-- Run EXPLAIN on your query
EXPLAIN SELECT * FROM users WHERE email = 'user@example.com';

-- EXPLAIN ANALYZE for actual execution time
EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'pending';
```

### 1.2 Interpreting EXPLAIN Output

| Scan Type | Description | Performance |
|-----------|-------------|-------------|
| **Seq Scan** | Full table scan | Slowest |
| **Index Scan** | Uses index | Fast |
| **Index Only Scan** | Index covers all columns | Fastest |
| **Bitmap Scan** | Combines multiple indexes | Medium |

### 1.3 Query Patterns

```sql
-- BAD - SELECT * retrieves unnecessary columns
SELECT * FROM users WHERE id = 1;

-- GOOD - Select only needed columns
SELECT id, email, name FROM users WHERE id = 1;

-- BAD - No index on filter column
SELECT * FROM orders WHERE created_at > '2024-01-01';

-- GOOD - Index on filtered column
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- BAD - Multiple queries
SELECT COUNT(*) FROM users;
SELECT SUM(amount) FROM orders;

-- GOOD - Single query with aggregation
SELECT 
  (SELECT COUNT(*) FROM users) as user_count,
  (SELECT SUM(amount) FROM orders) as total_amount;
```

---

## 2. Indexing Strategies

### 2.1 Index Types

**Official Docs**: https://supabase.com/docs/guides/database/postgres/indexes

| Index Type | Use Case |
|------------|----------|
| **B-Tree (default)** | Equality, range queries |
| **Hash** | Simple equality (=) |
| **GIN** | Full-text search, JSONB |
| **BRIN** | Time-series, large tables |
| **HNSW** | Vector similarity search |

### 2.2 Creating Indexes

```sql
-- B-Tree index (most common)
CREATE INDEX idx_users_email ON users(email);

-- Composite index for multi-column queries
CREATE INDEX idx_orders_status_date ON orders(status, created_at DESC);

-- Partial index (filtered)
CREATE INDEX idx_active_users ON users(email) WHERE status = 'active';

-- Unique index
CREATE UNIQUE INDEX idx_users_email ON users(email);

-- JSONB index
CREATE INDEX idx_data_properties ON documents USING gin(data->'properties');

-- Index with CONCURRENTLY (no table lock)
CREATE INDEX CONCURRENTLY idx_users_name ON users(name);
```

### 2.3 Index Advisor

**Official Docs**: https://supabase.com/docs/guides/database/extensions/index_advisor

```sql
-- Get index recommendations
SELECT * FROM index_advisor('SELECT * FROM users WHERE email = $1');

-- Via Supabase Studio
-- Query Performance Report → Select Query → Indexes tab
```

---

## 3. Connection Management

### 3.1 Understanding Connection Pooling

**Official Docs**: https://supabase.com/docs/guides/database/connection-management

```
┌─────────────────────────────────────────────────────────────────┐
│                 CONNECTION POOLING ARCHITECTURE                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   CLIENT                 POOLER (Supavisor)           DATABASE  │
│   ──────                ────────────────────          ────────   │
│                                                                  │
│   ┌───────┐           ┌─────────────┐            ┌─────────┐   │
│   │Req 1  │──────────▶│ Connection 1│───────────▶│   DB    │   │
│   └───────┘           │  (Active)   │            └─────────┘   │
│                       └─────────────┘                          │
│   ┌───────┐           ┌─────────────┐            ┌─────────┐   │
│   │Req 2  │──────────▶│ Connection 2│───────────▶│   DB    │   │
│   └───────┘           │  (Idle)     │            └─────────┘   │
│                       └─────────────┘                          │
│   ┌───────┐           ┌─────────────┐            ┌─────────┐   │
│   │Req 3  │──────────▶│ Connection 3│───────────▶│   DB    │   │
│   └───────┘           │  (Waiting)  │            └─────────┘   │
│                       └─────────────┘                          │
│                                                                  │
│   Benefits:                                                    │
│   - Reuses database connections                                │
│   - Reduces connection overhead                                 │
│   - Handles traffic spikes                                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Connection Pool Modes

| Mode | Use Case | Prepared Statements |
|------|----------|-------------------|
| **Transaction** | Serverless, functions | Not supported |
| **Session** | Persistent connections | Supported |

### 3.3 Connection Configuration

```typescript
// Transaction mode (for serverless)
const supabase = createClient(
  'https://xxx.supabase.co',
  'public-anon-key',
  {
    db: {
      pooler: {
        host: 'xxx.pooler.supabase.co',
        port: 6543,
        poolMode: 'transaction'
      }
    }
  }
)

// Direct connection (for long-running processes)
const supabase = createClient(
  'https://xxx.supabase.co',
  'public-anon-key',
  {
    db: {
      schema: 'public'
    }
  }
)
```

### 3.4 Pool Size Guidelines

```
┌─────────────────────────────────────────────────────────────────┐
│                   POOL SIZE RECOMMENDATIONS                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Guideline:                                                     │
│  - Heavy PostgREST usage: ≤40% of max connections              │
│  - Light PostgREST: ≤80% of max connections                    │
│                                                                  │
│  Example (500 max connections):                                  │
│  - Pool size: 200-400                                          │
│  - Leaves room for auth server                                  │
│                                                                  │
│  Compute Add-on | Max Connections | Recommended Pool Size      │
│  ─────────────────────────────────────────────────────────────  │
│  Free            |  60                |  25                   │
│  Pro             |  125               |  50                   │
│  Team            |  500               |  200                  │
│  Enterprise      |  Custom            |  Custom                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Row Level Security (RLS) Optimization

### 4.1 RLS Performance Impact

```sql
-- BAD: Complex RLS policy with subqueries
CREATE POLICY "complex_policy" ON users
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM organizations o
    JOIN user_orgs uo ON o.id = uo.org_id
    WHERE uo.user_id = auth.uid()
    AND o.status = 'active'
  )
);

-- GOOD: Simple indexed RLS policy
CREATE POLICY "simple_policy" ON users
FOR SELECT USING (id = auth.uid());
```

### 4.2 Index RLS Policy Columns

```sql
-- Create index on column used in RLS
CREATE INDEX idx_users_auth_uid ON users(id) WHERE auth.uid() IS NOT NULL;
```

---

## 5. Caching Strategies

### 5.1 Postgres Query Cache

```sql
-- Enable query plan caching
SET plan_cache_mode = 'force_custom_plan';

-- Prepared statements
PREPARE user_lookup AS SELECT * FROM users WHERE email = $1;
EXECUTE user_lookup('test@example.com');
```

### 5.2 Application-Level Caching

```typescript
// Use SWR with Supabase for client-side caching
import useSWR from 'swr'

const fetcher = (key) => supabase.from(key).select('*')

function UsersList() {
  const { data } = useSWR('users', fetcher)
  // SWR handles caching automatically
}
```

### 5.3 Edge Function Caching

```typescript
// supabase/functions/my-function/index.ts
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Cache-Control': 'public, max-age=3600, s-maxage=3600',
}

Deno.serve(async (req) => {
  const cache = await caches.open('my-cache')
  const url = new URL(req.url)
  
  // Check cache first
  const cached = await cache.match(req)
  if (cached) return cached
  
  // Fetch and cache
  const response = await fetch('https://api.example.com/data')
  
  return new Response(response.body, {
    headers: { ...corsHeaders, 'Cache-Control': 'public, max-age=3600' }
  })
})
```

---

## 6. Query Patterns & Best Practices

### 6.1 Pagination

```typescript
// BAD - Offset pagination (slow on large tables)
const { data } = await supabase
  .from('messages')
  .select('*')
  .range(10000, 10020) // Slow with high offset

// GOOD - Keyset pagination (fast)
const { data } = await supabase
  .from('messages')
  .select('*')
  .lt('id', lastId) // Use indexed column
  .order('id', { ascending: false })
  .limit(20)
```

### 6.2 Batch Operations

```typescript
// BAD - Individual inserts
for (const item of items) {
  await supabase.from('records').insert(item)
}

// GOOD - Batch insert (max 1000 rows)
await supabase.from('records').insert(items)

// GOOD - Upsert for existing records
await supabase.from('records').upsert(items, { 
  onConflict: 'unique_column' 
})
```

### 6.3 Realtime Optimization

```typescript
// Subscribe only to relevant channels
const channel = supabase
  .channel('table-changes')
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'notifications',
      filter: 'user_id=eq.' + userId // Filter at source
    },
    (payload) => console.log(payload)
  )
  .subscribe()
```

---

## 7. Monitoring & Debugging

### 7.1 Supabase Query Performance

```sql
-- Use Performance Advisor (Dashboard)
-- Query Performance Report shows:
-- - Slow queries
-- - Missing indexes
-- - Query statistics
```

### 7.2 Supabase Grafana

**Official Docs**: https://supabase.com/docs/guides/platform/metrics

```bash
# Deploy Supabase Grafana
git clone https://github.com/supabase/grafana-deploy.git
cd grafana-deploy
flyctl deploy
```

Metrics available:
- Database connections
- Query latency
- Throughput
- Cache hit ratios

### 7.3 Logs Analysis

```sql
-- Check query timing
SELECT 
  query,
  calls,
  mean_time,
  total_time,
  rows
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 20;
```

---

## 8. Database Design Optimization

### 8.1 Normalization vs Performance

```
┌─────────────────────────────────────────────────────────────────┐
│              NORMALIZATION GUIDELINES                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  NORMALIZED (3NF+)              DENORMALIZED                   │
│  ────────────────────           ─────────────                   │
│  - Less storage                - Read performance              │
│  - Data integrity              - Fewer joins                   │
│  - Update simplicity           - Aggregate tables               │
│                                                                  │
│  Best for:                     Best for:                       │
│  - OLTP (transactions)         - OLAP (analytics)             │
│  - Frequent updates            - Reporting                     │
│  - Complex queries             - Cached data                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Partitioning (Large Tables)

```sql
-- Range partitioning by date
CREATE TABLE logs (
  id BIGSERIAL,
  created_at TIMESTAMP,
  data JSONB
) PARTITION BY RANGE (created_at);

-- Create partitions
CREATE TABLE logs_2024_01 PARTITION OF logs
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE logs_2024_02 PARTITION OF logs
  FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
```

---

## 9. Supabase-Specific Optimizations

### 9.1 PostgREST Cache

```sql
-- Increase cache for frequently accessed data
ALTER DATABASE postgres SET pgrst.http_cache TO '1000';
```

### 9.2 Select Optimization

```typescript
// Always specify columns
const { data } = await supabase
  .from('users')
  .select('id, name, email') // Only needed columns
  .eq('status', 'active')
```

### 9.3 Storage Optimization

```sql
-- Analyze table for query planner
ANALYZE users;

-- Vacuum to reclaim space
VACUUM (VERBOSE, ANALYZE) users;

-- Autovacuum is enabled by default
-- Monitor with pg_stat_user_tables
```

---

## 10. Resources

### Official Documentation
- **Query Optimization**: https://supabase.com/docs/guides/database/query-optimization
- **Indexes**: https://supabase.com/docs/guides/database/postgres/indexes
- **Connection Management**: https://supabase.com/docs/guides/database/connection-management
- **Performance Tuning**: https://supabase.com/docs/guides/platform/performance
- **EXPLAIN Guide**: https://supabase.com/docs/guides/troubleshooting/understanding-postgresql-explain-output-Un9dqX

### Tools
- **pg_stat_statements**: Track query performance
- **index_advisor**: Automatic index recommendations
- **Supabase Grafana**: Real-time metrics
- **Query Performance Report**: Dashboard analysis

### Related Modules
- [Module 02: PostgreSQL Database Schema & Tables](../STACK_STANDARDS.md#module-02-postgresql-database-schema--tables)
- [Module 03: Row Level Security (RLS) & Data Protection](../STACK_STANDARDS.md#module-03-row-level-security-rls--data-protection)
- [Module 24: Performance & Optimization](../STACK_STANDARDS.md#module-24-performance--optimization)

---

## Quick Reference Card

| Task | Solution |
|------|----------|
| Slow queries | EXPLAIN + indexes |
| Connection errors | Pool sizing |
| Large tables | Partitioning |
| RLS slow | Simplify policies |
| Pagination slow | Keyset pagination |
| Frequent reads | Application cache |
| Realtime | Filter at source |

---

*Last Updated: 2026-03-02*
*Source: Supabase Docs, PostgreSQL Documentation*
