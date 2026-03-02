# Production Standards: Vercel + Supabase Full Stack

> A comprehensive guide mapping CompTIA certification objectives to production-quality application development using Vercel and Supabase.

---

## Overview

This document establishes production standards for full-stack applications by mapping industry-standard CompTIA certification objectives to practical implementation in the Vercel + Supabase stack. These standards ensure applications meet enterprise-level security, reliability, and performance requirements.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PRODUCTION STACK ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────┐    │
│   │                    COMPTIA OBJECTIVES MAPPING                     │    │
│   ├─────────────────────────────────────────────────────────────────┤    │
│   │  Security+ (SY0-701)  →  Security, RLS, Encryption, Compliance   │    │
│   │  Network+ (N10-009)  →  API, CDN, SSL, Network Design          │    │
│   │  DataSys+ (DS0-001)  →  PostgreSQL, Indexes, Backups           │    │
│   └─────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────┐    │
│   │                      VERCEL + SUPABASE STACK                      │    │
│   │                                                                   │    │
│   │   Frontend          →  Vercel (Next.js, Edge, CDN)              │    │
│   │   Backend           →  Supabase (PostgreSQL, Auth, Storage)      │    │
│   │   API Layer         →  Vercel Functions + Supabase RPC          │    │
│   │   Security         →  RLS, SSL/TLS, Encryption, WAF             │    │
│   │   Monitoring       →  Vercel Analytics + Supabase Logs          │    │
│   └─────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Part 1: Security Implementation (CompTIA Security+ SY0-701)

### 1.1 Security Controls & Architecture

#### Objective Mapping: Security+ Domain 1.0, 3.0

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SECURITY CONTROLS IMPLEMENTATION                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  CONTROL TYPE            IMPLEMENTATION IN STACK                            │
│  ──────────────────────  ────────────────────────────────────────────────  │
│                                                                             │
│  TECHNICAL              │ Supabase RLS Policies                            │
│  CONTROLS              │ PostgreSQL row-level security                    │
│                        │ Vercel WAF rules                                 │
│                        │ API route authentication                          │
│                        │ Next.js middleware protection                    │
│  ──────────────────────│────────────────────────────────────────────────  │
│  PHYSICAL              │ Supabase infrastructure (AWS)                    │
│  CONTROLS              │ Database encryption at rest                      │
│                        │ Backup storage security                          │
│  ──────────────────────│────────────────────────────────────────────────  │
│  ADMINISTRATIVE         │ Role-based access control (RBAC)                │
│  CONTROLS              │ User roles: admin, candidate, client            │
│                        │ Password policies                                │
│                        │ Audit logging                                    │
│  ──────────────────────│────────────────────────────────────────────────  │
│  PREVENTIVE             │ Input validation                                 │
│  CONTROLS              │ SQL injection prevention                         │
│                        │ XSS protection                                   │
│                        │ CSRF tokens                                      │
│  ──────────────────────│────────────────────────────────────────────────  │
│  DETECTIVE             │ Supabase audit logs                             │
│  CONTROLS              │ Vercel function logs                            │
│                        │ Anomaly detection                                │
│  ──────────────────────│────────────────────────────────────────────────  │
│  CORRECTIVE            │ Account lockout                                  │
│  CONTROLS              │ Session termination                             │
│                        │ Password reset flow                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Implementation Examples

**1.1.1 RLS Policy Structure (Supabase)**

```sql
-- Security+ 1.1: Technical Controls via PostgreSQL RLS

-- Enable RLS on table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can read own profile (preventive control)
CREATE POLICY "profiles_select_own" ON profiles
FOR SELECT USING (auth.uid() = user_id);

-- Users can update own profile (preventive control)
CREATE POLICY "profiles_update_own" ON profiles
FOR UPDATE USING (auth.uid() = user_id);

-- Admins can select all profiles (administrative control)
CREATE POLICY "admins_select_all" ON profiles
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE role = 'admin'
    AND user_id = auth.uid()
  )
);
```

**1.1.2 Next.js Middleware Security**

```typescript
// Security+ 1.3: Change management + security boundaries
// middleware.ts

import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // Security+ 2.2: Threat mitigation - CSRF protection
  const csrfToken = request.headers.get('x-csrf-token')
  if (request.method !== 'GET' && !csrfToken) {
    return NextResponse.json({ error: 'CSRF validation failed' }, { status: 403 })
  }

  // Security+ 3.3: Secure infrastructure - Rate limiting
  const ip = request.ip
  const rateLimitKey = `rate-limit:${ip}`
  // Implement rate limiting logic here

  // Security+ 4.1: Authentication check
  const authToken = request.cookies.get('auth-token')
  if (!authToken && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboard/:path*', '/api/:path*'],
}
```

### 1.2 Threat Mitigation

#### Objective Mapping: Security+ Domain 2.0

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    THREAT MITIGATION STRATEGIES                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  THREAT TYPE               MITIGATION IN VERCEL + SUPABASE                 │
│  ────────────────────────  ─────────────────────────────────────────────   │
│                                                                             │
│  SQL Injection             │ Parameterized queries via Supabase client     │
│  XSS                      │ React auto-escaping + CSP headers              │
│  CSRF                     │ Same-origin policy + CSRF tokens               │
│  DDoS                     │ Vercel DDoS protection + rate limiting        │
│  Credential Stuffing      │ Rate limiting + account lockout               │
│  Man-in-the-Middle        │ TLS/SSL enforced                             │
│  Zero-Day                 │ Regular updates + WAF rules                   │
│  Phishing                 │ Email verification required                   │
│  Insider Threats          │ RLS + audit logging                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Implementation

**1.2.1 Input Validation with Zod**

```typescript
// Security+ 2.1: Vulnerability mitigation - Input validation
import { z } from 'zod'

// Validate all user inputs
const userSchema = z.object({
  email: z.string().email().max(255),
  password: z.string().min(16).max(128)
    .regex(/[A-Z]/, 'Must contain uppercase')
    .regex(/[a-z]/, 'Must contain lowercase')
    .regex(/[0-9]/, 'Must contain number')
    .regex(/[!@#$%^&*()_+\-=\[\]{}|;':",.\/<>?]/, 'Must contain special character'),
  name: z.string().min(1).max(100).regex(/^[a-zA-Z\s]+$/),
})

// Usage in API route
export async function POST(request: Request) {
  const body = await request.json()
  const result = userSchema.safeParse(body)
  
  if (!result.success) {
    return Response.json({ error: 'Invalid input' }, { status: 400 })
  }
  
  // Proceed with validated data
}
```

### 1.3 Cryptographic Solutions

#### Objective Mapping: Security+ Domain 1.4

**1.3.1 Encryption Implementation**

```typescript
// Security+ 1.4: Cryptographic solutions

// Supabase handles encryption at rest automatically
// PostgreSQL TDE (Transparent Data Encryption) is enabled by default

// For sensitive data application-level encryption:
import { createCipheriv, randomBytes, createDecipheriv } from 'crypto'

const ALGORITHM = 'aes-256-gcm'
const KEY = process.env.ENCRYPTION_KEY! // Must be 32 bytes

export function encrypt(text: string): string {
  const iv = randomBytes(16)
  const cipher = createCipheriv(ALGORITHM, Buffer.from(KEY, 'hex'), iv)
  
  let encrypted = cipher.update(text, 'utf8', 'hex')
  encrypted += cipher.final('hex')
  
  const authTag = cipher.getAuthTag()
  
  return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`
}

export function decrypt(encryptedText: string): string {
  const [ivHex, authTagHex, encrypted] = encryptedText.split(':')
  
  const decipher = createDecipheriv(
    ALGORITHM,
    Buffer.from(KEY, 'hex'),
    Buffer.from(ivHex, 'hex')
  )
  decipher.setAuthTag(Buffer.from(authTagHex, 'hex'))
  
  let decrypted = decipher.update(encrypted, 'hex', 'utf8')
  decrypted += decipher.final('utf8')
  
  return decrypted
}
```

### 1.4 Incident Response

#### Objective Mapping: Security+ Domain 4.0

**1.4.1 Incident Response Plan**

```typescript
// Security+ 4.0: Operations and Incident Response

// Types for incident tracking
interface SecurityIncident {
  id: string
  type: 'failed_login' | 'suspicious_activity' | 'data_breach' | 'account_compromise'
  severity: 'low' | 'medium' | 'high' | 'critical'
  user_id?: string
  ip_address: string
  description: string
  status: 'open' | 'investigating' | 'resolved' | 'escalated'
  created_at: Date
  resolved_at?: Date
}

// Supabase function to log incidents
export async function logSecurityIncident(
  supabase: SupabaseClient,
  incident: Omit<SecurityIncident, 'id' | 'created_at' | 'status'>
) {
  const { data, error } = await supabase
    .from('security_incidents')
    .insert({
      ...incident,
      status: 'open'
    })
    .select()
    .single()
  
  return { data, error }
}

// Incident response workflow
export const incidentResponsePlan = {
  containment: [
    'Isolate affected account',
    'Revoke active sessions',
    'Block suspicious IP',
    'Enable enhanced monitoring'
  ],
  eradication: [
    'Remove malicious entries',
    'Reset compromised credentials',
    'Patch vulnerability'
  ],
  recovery: [
    'Restore from clean backup',
    'Verify system integrity',
    'Monitor for recurrence'
  ],
  lessonsLearned: [
    'Document incident timeline',
    'Update security policies',
    'Implement additional controls'
  ]
}
```

### 1.5 Governance & Compliance

#### Objective Mapping: Security+ Domain 5.0

**1.5.1 Compliance Framework Implementation**

```typescript
// Security+ 5.0: Governance, Risk, and Compliance

// GDPR Compliance Types
interface GDPRCompliance {
  dataProcessed: string[]
  legalBasis: string
  retentionPeriod: number
  dataSubjectRights: {
    access: boolean
    rectification: boolean
    erasure: boolean
    portability: boolean
  }
}

// HIPAA Compliance - PHI handling
interface PHIData {
  patientId: string
  medicalRecord: string
  treatmentHistory: string
  accessLog: { user: string; timestamp: Date; action: string }[]
}

// Audit logging for compliance
export async function createAuditLog(
  supabase: SupabaseClient,
  params: {
    userId: string
    action: string
    resource: string
    ipAddress: string
    userAgent: string
    metadata?: Record<string, unknown>
  }
) {
  const { error } = await supabase.from('audit_logs').insert({
    user_id: params.userId,
    action: params.action,
    resource: params.resource,
    ip_address: params.ipAddress,
    user_agent: params.userAgent,
    metadata: params.metadata,
    created_at: new Date().toISOString()
  })
  
  return { error }
}
```

---

## Part 2: Network Implementation (CompTIA Network+ N10-009)

### 2.1 Network Fundamentals

#### Objective Mapping: Network+ Domain 1.0, 2.0

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    NETWORK IMPLEMENTATION                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  CONCEPT                    IMPLEMENTATION                                 │
│  ────────────────────────   ─────────────────────────────────────────────   │
│                                                                             │
│  OSI Model                 │ HTTP/HTTPS (L7) → Supabase API                │
│                           │ WebSocket (Supabase Realtime)                  │
│                           │ Database connections (L4/L5)                    │
│  ────────────────────────│────────────────────────────────────────────────   │
│  TCP/IP                   │ Connection pooling (Supavisor)                │
│  Protocols                │ Keep-alive management                          │
│                           │ Timeout configuration                          │
│  ────────────────────────│────────────────────────────────────────────────   │
│  DNS                      │ Custom domain in Vercel                       │
│                           │ Supabase project URL                          │
│  ────────────────────────│────────────────────────────────────────────────   │
│  Subnetting               │ Database connection pools                      │
│  ────────────────────────│────────────────────────────────────────────────   │
│  Ports                    │ 443 (HTTPS), 5432 (Postgres)                  │
│                           │ 6543 (Pooler)                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**2.1.1 Network Configuration**

```typescript
// Network+ 1.5: Port and protocol configuration
// next.config.js - Vercel network settings

/** @type {import('next').NextConfig} */
const nextConfig = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          // Network+ 4.1: Security - TLS enforcement
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=31536000; includeSubDomains'
          },
          // Network+ 4.1: Security - XSS protection
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block'
          },
          // Network+ 4.1: Security - MIME sniffing
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff'
          },
          // Network+ 4.1: Security - Frame embedding
          {
            key: 'X-Frame-Options',
            value: 'DENY'
          },
          // Network+ 4.1: Security - Referrer policy
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin'
          }
        ]
      }
    ]
  },
  
  // Network+ 2.3: Network device configuration - CDN
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**.supabase.co',
        pathname: '/storage/v1/object/**'
      }
    ]
  }
}

module.exports = nextConfig
```

### 2.2 Network Security

#### Objective Mapping: Network+ Domain 4.0

**2.2.1 Vercel Deployment Security**

```typescript
// Network+ 4.3: Network hardening techniques
// Vercel project settings recommendations:

/*
 * SECURITY HEADERS CONFIGURATION
 * 
 * Network+ Objective: Implement network hardening techniques
 * 
 * 1. Content Security Policy (CSP)
 * 2. HSTS (HTTP Strict Transport Security)
 * 3. CORS configuration
 * 4. Rate limiting
 */

export const securityHeaders = {
  // CSP - Prevent XSS and data injection
  'Content-Security-Policy': [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: https:",
    "font-src 'self'",
    "connect-src 'self' https://*.supabase.co wss://*.supabase.co",
    "frame-ancestors 'none'"
  ].join('; '),
  
  // HSTS - Enforce HTTPS
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
  
  // CORS - Control cross-origin access
  'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGIN || '',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization'
}
```

### 2.3 Network Troubleshooting

#### Objective Mapping: Network+ Domain 5.0

**2.3.1 Troubleshooting Utilities**

```typescript
// Network+ 5.0: Network troubleshooting

export interface NetworkDiagnostics {
  ping(host: string): Promise<boolean>
  traceroute(host: string): Promise<string[]>
  dnsLookup(domain: string): Promise<string[]>
  sslCheck(domain: string): Promise<SSLInfo>
}

// SSL/TLS Certificate Check
export async function checkSSLExpiry(domain: string): Promise<number> {
  const response = await fetch(`https://${domain}`)
  const cert = response.headers.get('ssl-certificate')
  // Extract and calculate days until expiry
  return daysUntilExpiry
}

// Connection Health Check
export async function checkSupabaseConnection(): Promise<{
  database: boolean
  auth: boolean
  storage: boolean
  realtime: boolean
}> {
  const results = await Promise.allSettled([
    supabase.from('*').select('count').limit(1),
    supabase.auth.getSession(),
    supabase.storage.listBuckets(),
    supabase.channel('health').subscribe()
  ])
  
  return {
    database: results[0].status === 'fulfilled',
    auth: results[1].status === 'fulfilled',
    storage: results[2].status === 'fulfilled',
    realtime: results[3].status === 'fulfilled'
  }
}
```

---

## Part 3: Database Implementation (CompTIA DataSys+ DS0-001)

### 3.1 Database Fundamentals

#### Objective Mapping: DataSys+ Domain 1.0

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DATABASE DESIGN STANDARDS                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  CONCEPT                    IMPLEMENTATION                                 │
│  ────────────────────────   ─────────────────────────────────────────────   │
│                                                                             │
│  Normalization             │ 1NF: Atomic values                            │
│                           │ 2NF: No partial dependencies                  │
│                           │ 3NF: No transitive dependencies               │
│  ────────────────────────│────────────────────────────────────────────────   │
│  Entity Relationships     │ Foreign keys with indexes                     │
│                           │ CASCADE DELETE policies                        │
│  ────────────────────────│────────────────────────────────────────────────   │
│  Indexes                  │ B-Tree for equality/range                    │
│                           │ GIN for full-text search                      │
│                           │ BRIN for time-series                          │
│  ────────────────────────│────────────────────────────────────────────────   │
│  Data Types               │ UUID for identifiers                          │
│                           │ TIMESTAMPTZ for dates                         │
│                           │ JSONB for flexible data                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**3.1.1 Schema Design**

```sql
-- DataSys+ 1.2: Database design principles
-- Complete schema example with proper normalization

-- Users table (normalized to 3NF)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'candidate', 'client')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance (DataSys+ 1.3)
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_profiles_email ON profiles(email) WHERE status = 'active';
CREATE INDEX idx_profiles_role ON profiles(role);

-- Tasks table with foreign key
CREATE TABLE public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL CHECK (type IN ('upload', 'form', 'video', 'training')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'submitted', 'approved', 'rejected')),
  due_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date) WHERE due_date IS NOT NULL;
```

### 3.2 Database Deployment

#### Objective Mapping: DataSys+ Domain 2.0

**3.2.1 Supabase Configuration**

```typescript
// DataSys+ 2.3: Database configuration

export interface DatabaseConfig {
  // Connection settings
  pooler: {
    host: string
    port: number
    poolMode: 'transaction' | 'session'
    maxClientConnections: number
  }
  
  // Performance settings
  statementTimeout: number
  lockTimeout: number
  
  // Replication settings
  replication: {
    enabled: boolean
    replicaCount: number
  }
}

// Recommended settings for production
export const productionConfig: DatabaseConfig = {
  pooler: {
    host: process.env.SUPABASE_POOLER_HOST,
    port: 6543,
    poolMode: 'transaction',
    maxClientConnections: 200 // 40% of 500 max connections
  },
  
  // Prevent long-running queries
  statementTimeout: 30000, // 30 seconds
  lockTimeout: 5000, // 5 seconds
  
  replication: {
    enabled: true,
    replicaCount: 1
  }
}
```

### 3.3 Database Security

#### Objective Mapping: DataSys+ Domain 4.0

**3.3.1 Security Implementation**

```sql
-- DataSys+ 4.1: Data encryption and security

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_submissions ENABLE ROW LEVEL SECURITY;

-- Comprehensive RLS policies
-- Read policy with role-based filtering
CREATE POLICY "profiles_read_policy" ON profiles
FOR SELECT USING (
  auth.uid() = user_id
  OR EXISTS (
    SELECT 1 FROM profiles p2 
    WHERE p2.user_id = auth.uid() 
    AND p2.role = 'admin'
  )
);

-- Update policy - only own records
CREATE POLICY "profiles_update_policy" ON profiles
FOR UPDATE USING (auth.uid() = user_id);

-- Insert policy
CREATE POLICY "profiles_insert_policy" ON profiles
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Delete policy
CREATE POLICY "profiles_delete_policy" ON profiles
FOR DELETE USING (
  auth.uid() = user_id
  OR EXISTS (
    SELECT 1 FROM profiles p2 
    WHERE p2.user_id = auth.uid() 
    AND p2.role = 'admin'
  )
);

-- Audit log table (DataSys+ 4.2: Audit logging)
CREATE TABLE public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS but allow admin read
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit_logs_admin_read" ON audit_logs
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);
```

### 3.4 Business Continuity

#### Objective Mapping: DataSys+ Domain 5.0

**3.4.1 Backup & Recovery Strategy**

```typescript
// DataSys+ 5.0: Business continuity

export interface BackupConfig {
  // Point-in-time recovery
  pitrEnabled: boolean
  retentionDays: 30
  
  // Manual backups
  scheduledBackups: {
    frequency: 'daily' | 'weekly'
    time: string // UTC
    retention: number
  }
  
  // Cross-region
  geoRedundancy: boolean
  region?: string
}

// Backup types for Supabase:
// 1. Manual backups (Dashboard or API)
// 2. Point-in-time recovery (Pro plan+)
// 3. Export to external storage

export async function triggerManualBackup(supabase: SupabaseClient) {
  const { data, error } = await supabase.functions.invoke('trigger-backup')
  return { data, error }
}

// Database connection for failover
export const failoverConfig = {
  // Primary connection
  primary: {
    host: process.env.SUPABASE_DB_HOST,
    port: 5432
  },
  // Read replica (if available)
  replica: {
    host: process.env.SUPABASE_REPLICA_HOST,
    port: 5432
  },
  // Health check interval
  healthCheckInterval: 30000 // 30 seconds
}
```

---

## Part 4: Production Checklist

### 4.1 Security Checklist (Security+ Aligned)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SECURITY PRODUCTION CHECKLIST                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ✓ RLS enabled on ALL tables                                              │
│  ✓ RLS policies tested for all user roles                                 │
│  ✓ Password policy: 16+ chars, complexity requirements                     │
│  ✓ Email verification required                                            │
│  ✓ Account lockout after failed attempts                                  │
│  ✓ Session timeout configured                                             │
│  ✓ HTTPS enforced (HSTS)                                                  │
│  ✓ Security headers configured                                           │
│  ✓ Input validation on all forms                                         │
│  ✓ SQL injection prevention (parameterized queries)                       │
│  ✓ CSRF protection implemented                                           │
│  ✓ Rate limiting on authentication endpoints                             │
│  ✓ Audit logging enabled                                                 │
│  ✓ Encryption at rest verified                                           │
│  ✓ Encryption in transit verified                                        │
│  ✓ WAF rules configured                                                  │
│  ✓ DDoS protection enabled                                               │
│  ✓ Incident response plan documented                                     │
│  ✓ Security team contact configured                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Network Checklist (Network+ Aligned)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    NETWORK PRODUCTION CHECKLIST                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ✓ Custom domain configured with SSL                                     │
│  ✓ CDN enabled for static assets                                         │
│  ✓ Image optimization enabled                                             │
│  ✓ CORS configured correctly                                             │
│  ✓ DNS properly configured                                                │
│  ✓ SSL certificate valid and not expiring                                │
│  ✓ Connection pooling configured                                         │
│  ✓ Database connection limits tested                                     │
│  ✓ API rate limiting implemented                                         │
│  ✓ Network latency monitored                                             │
│  ✓ Uptime monitoring configured                                          │
│  ✓ SSL/TLS version min: TLS 1.2                                         │
│  ✓ Perfect forward secrecy enabled                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.3 Database Checklist (DataSys+ Aligned)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DATABASE PRODUCTION CHECKLIST                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ✓ Schema normalized to 3NF                                               │
│  ✓ Primary keys use UUID                                                  │
│  ✓ Foreign keys have indexes                                              │
│  ✓ Query columns indexed                                                   │
│  ✓ EXPLAIN analyzed for slow queries                                     │
│  ✓ Connection pool properly sized                                         │
│  ✓ RLS enabled on all tables                                             │
│  ✓ Backup schedule configured                                            │
│  ✓ Point-in-time recovery enabled (if Pro)                              │
│  ✓ Failover/replica configured (if Enterprise)                          │
│  ✓ Connection timeout configured                                         │
│  ✓ Statement timeout configured                                         │
│  ✓ Monitoring alerts configured                                          │
│  ✓ Query performance monitored                                           │
│  ✓ Index advisor reviewed                                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.4 Monitoring Checklist

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MONITORING PRODUCTION CHECKLIST                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ✓ Vercel Analytics enabled                                               │
│  ✓ Core Web Vitals monitored                                              │
│  ✓ Function execution monitored                                          │
│  ✓ Error tracking configured                                              │
│  ✓ Supabase logs enabled                                                 │
│  ✓ Database query logs enabled (non-production)                         │
│  ✓ Custom dashboards configured                                          │
│  ✓ Alert thresholds set                                                   │
│  ✓ On-call rotation configured                                           │
│  ✓ Incident escalation documented                                        │
│  ✓ Runbook created for common issues                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Part 5: Module Cross-Reference

### 5.1 CompTIA to Stack Standards Mapping

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    COMPTOIA OBJECTIVES → MODULES                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  SECURITY+ (SY0-701)           STACK MODULES                               │
│  ───────────────────────────────────────────────────────────────────────   │
│  Domain 1: Security Concepts  →  Module 03 (RLS), Module 22 (Security)     │
│  Domain 2: Threats            →  Module 22 (Security), Module 35 (WAF)     │
│  Domain 3: Architecture        →  Module 06 (Vercel), Module 31 (DB)       │
│  Domain 4: Incident Response  →  Module 18 (Realtime), This Doc           │
│  Domain 5: Governance         →  Module 15 (Policies), Module 26 (Docs)   │
│                                                                             │
│  NETWORK+ (N10-009)              STACK MODULES                             │
│  ───────────────────────────────────────────────────────────────────────   │
│  Domain 1: Fundamentals       →  Module 06 (Vercel), Module 31 (DB)        │
│  Domain 2: Implementations    →  Module 06 (Vercel Deployment)            │
│  Domain 3: Operations         →  Module 18 (Realtime), Module 24 (Perf)    │
│  Domain 4: Security           →  Module 22 (Security), This Doc            │
│  Domain 5: Troubleshooting    →  Module 31 (DB Optimization)               │
│                                                                             │
│  DATASYS+ (DS0-001)              STACK MODULES                             │
│  ───────────────────────────────────────────────────────────────────────   │
│  Domain 1: Fundamentals       →  Module 02 (Schema), Module 31 (DB)       │
│  Domain 2: Deployment          →  Module 06 (Vercel), Module 20 (CLI)     │
│  Domain 3: Management          →  Module 20 (Migrations), Module 31 (DB)   │
│  Domain 4: Security            →  Module 03 (RLS), This Doc                │
│  Domain 5: Business Continuity →  Module 16 (Contracts), This Doc         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Resources

### Official Documentation
- **Vercel Docs**: https://vercel.com/docs
- **Supabase Docs**: https://supabase.com/docs
- **CompTIA Security+**: https://www.comptia.org/certifications/security
- **CompTIA Network+**: https://www.comptia.org/certifications/network
- **CompTIA DataSys+**: https://www.comptia.org/certifications/datasys

### Study Resources
- **Security+ SY0-701**: [COMPTIA_SECURITYPLUS.md](../COMPTIA_SECURITYPLUS.md)
- **Network+ N10-009**: [COMPTIA_NETWORKPLUS.md](../COMPTIA_NETWORKPLUS.md)
- **DataSys+ DS0-001**: [COMPTIA_DATASYS.md](../COMPTIA_DATASYS.md)

### Optimization Guides
- **Vercel Optimization**: [VERCEL_OPTIMIZATION.md](../VERCEL_OPTIMIZATION.md)
- **Supabase Optimization**: [SUPABASE_OPTIMIZATION.md](../SUPABASE_OPTIMIZATION.md)

---

*Last Updated: 2026-03-02*
*This document establishes production standards for Vercel + Supabase applications aligned with CompTIA certification objectives.*
