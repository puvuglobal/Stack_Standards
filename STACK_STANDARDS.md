# Stack Standards: Vercel + Supabase Full Stack

> A forkable full-stack standardization template for building applications with Vercel and Supabase.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     FRONTEND (Vercel)                           │
│  Next.js 14 Mobile Web Client → Vercel Deployment              │
│  - No API keys/tokens in client                                │
│  - All sensitive data via Supabase                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND (Supabase)                           │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐   │
│  │   Auth      │  │  PostgreSQL  │  │  Storage           │   │
│  │  (Users)    │  │  RPC Funcs   │  │  (Files/Images)    │   │
│  └─────────────┘  └──────────────┘  └─────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module Index

| Module | Title | Description |
|--------|-------|-------------|
| 01 | Supabase Auth & User Identity | Email/password, OAuth, sessions, roles |
| 02 | PostgreSQL Database Schema & Tables | Core tables, RLS, file registry |
| 03 | Row Level Security (RLS) & Data Protection | Security policies, PII protection |
| 04 | RPC Functions & Backend Logic | PostgreSQL functions for business logic |
| 05 | Next.js Frontend Architecture | App Router, page registry, structure |
| 06 | Vercel Deployment & Environment | Git integration, env vars, CDN |
| 07 | Supabase Storage & File Management | Buckets, uploads, file handling |
| 08 | Role-Based Page Registry & Routing | Dynamic routing based on roles |
| 09 | Task Management System | Admin tasks, submissions, approval |
| 10 | Training & Content System | Video, text, forced completion |
| 11 | Documentation Timer & Stages | Multi-stage processing workflow |
| 12 | Admin Portal & User Management | User CRUD, compliance views |
| 13 | UI Components & Glass Design System | Reusable components, design tokens |
| 14 | Client (VIP) Features & Employer Portal | Employer-specific functionality |
| 15 | Policies, Legal & Compliance | Policy management, legal refs |
| 16 | Contract Management System | PDF contracts, signatures |
| 17 | State Management & Persistence | React Context, local storage |
| 18 | Supabase Realtime & Live Features | Real-time updates, presence |
| 19 | Code Standards & File Registry | 5-char hex IDs, naming conventions |
| 20 | Supabase CLI & Migration | Local dev, database migrations |
| 21 | Vercel Functions & API Routes | Serverless, API endpoints |
| 22 | Security & Deployment Protection | WAF, bot management, DDoS |
| 23 | Profile Settings & Theme | User settings, dark mode, sign out |
| 24 | Performance & Optimization | Caching, code splitting, indexes |
| 25 | Testing & Quality Assurance | Unit, E2E, CI/CD |
| 26 | Documentation & Forking Guide | How to fork and customize |

---

## Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/puvuglobal/Stack_Standards.git
cd Stack_Standards
npm install
```

### 2. Configure Supabase
- Create Supabase project
- Run migrations in `supabase/migrations/`
- Set up auth providers

### 3. Configure Vercel
- Connect GitHub repo to Vercel
- Add environment variables
- Deploy

### 4. Customize
- Update STACK_STANDARDS.md for your project
- Add project-specific modules
- Implement features

---

## Supabase Products Used

- **Database**: Full Postgres with extensions
- **Auth**: Email/password, OAuth, MFA
- **Storage**: File storage with RLS
- **Realtime**: Live updates and presence
- **Edge Functions**: Serverless (if needed)

## Vercel Products Used

- **Next.js**: React framework with App Router
- **Deployments**: Git auto-deploy
- **Preview**: Pre-production environments
- **Functions**: Serverless API routes
- **CDN**: Global content delivery
- **Analytics**: Performance monitoring
- **Firewall**: WAF and bot protection

```
┌─────────────────────────────────────────────────────────────────┐
│                     FRONTEND (Vercel)                           │
│  Next.js 14 Mobile Web Client → Vercel Deployment                │
│  - No API keys/tokens in client                                 │
│  - All sensitive data via Supabase                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND (Supabase)                           │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐     │
│  │   Auth      │  │  PostgreSQL  │  │  Storage           │     │
│  │  (Users)    │  │  RPC Funcs   │  │  (Files/Images)    │     │
│  └─────────────┘  └──────────────┘  └─────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module 1: Authentication & Security

### 1.1 Authentication Flow

```
┌──────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────┐
│  Login   │───▶│ Supabase     │───▶│  Session    │───▶│Dashboard │
│  Page    │    │  Auth        │    │  Created    │    │  Home    │
└──────────┘    └──────────────┘    └─────────────┘    └──────────┘
       │               │                   │
       ▼               ▼                   ▼
┌──────────┐    ┌──────────────┐    ┌─────────────┐
│  Gmail   │    │ Email        │    │  Unique     │
│  OAuth   │    │ Verification │    │  Session ID │
└──────────┘    └──────────────┘    └─────────────┘
```

### 1.2 Security Requirements

| Requirement | Implementation |
|-------------|----------------|
| No hardcoded content | All data from SQL tables |
| No API keys in client | Supabase anon key only |
| Password storage | Supabase Auth (bcrypt) |
| Unique sessions | UUID per session |
| Data exposure | Zero PII in frontend |

### 1.3 Password Policy

```
┌────────────────────────────────────────────────────────┐
│              PASSWORD REQUIREMENTS                      │
├────────────────────────────────────────────────────────┤
│  Length:     16 characters minimum                      │
│  Uppercase:  A-Z (required)                             │
│  Lowercase:  a-z (required)                             │
│  Numbers:    0-9 (required)                             │
│  Special:    !@#$%^&*()_+-=[]{}|;':",./<>? (required)   │
└────────────────────────────────────────────────────────┘
```

### 1.4 Role-Based Access Control

```
┌─────────────────────────────────────────────────────────┐
│                    ROLE HIERARCHY                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│    ┌─────────┐                                          │
│    │  Admin  │  Full access to all data                 │
│    └────┬────┘  Manage users, contracts, tasks          │
│         │                                                │
│    ┌────┴────┐                                          │
│    │         │                                          │
│ ┌──┴──┐  ┌───┴───┐                                      │
│ │Candi│  │ VIP   │  Role display: Candidate/Employer   │
│ │date │  │Client │                                      │
│ └─────┘  └───────┘                                      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Module 2: Database Architecture

### 2.1 Core Tables Schema

```
┌─────────────────────────────────────────────────────────────────┐
│                      CORE TABLES                                │
├────────────────────┬────────────────────────────────────────────┤
│ Table              │ Purpose                                    │
├────────────────────┼────────────────────────────────────────────┤
│ profiles           │ User profiles with role                   │
│ sessions           │ Unique session management                 │
│ page_registry      │ Role-based page access mapping             │
│ file_registry      │ File metadata with 5-char hex IDs          │
│ password_policy    │ Password validation rules                  │
└────────────────────┴────────────────────────────────────────────┘
```

### 2.2 Data Tables

```
┌─────────────────────────────────────────────────────────────────┐
│                      DATA TABLES                                 │
├─────────────────────┬───────────────────────────────────────────┤
│ Table               │ Purpose                                   │
├─────────────────────┼───────────────────────────────────────────┤
│ tasks               │ Admin-assigned tasks                      │
│ task_submissions    │ User submissions with approval status     │
│ trainings           │ Video/content training assignments         │
│ training_progress  │ Forced watch/scroll completion tracking   │
│ documentation_stages│ Timer stages                              │
│ user_documentation │ Per-user documentation tracking           │
│ policies            │ Admin-loaded policies per user            │
│ contracts           │ Labor contracts (PDF)                     │
│ legal_references    │ Federal/state legal links (50 states)     │
│ employer_requests   │ Employer job/employee requests            │
│ candidate_recommendations │ Admin推荐的候选人              │
└─────────────────────┴───────────────────────────────────────────┘
```

### 2.3 File Registry System

```
┌─────────────────────────────────────────────────────────────────┐
│                    FILE REGISTRY SYSTEM                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   5-CHAR HEX ID FORMAT: [A-F0-9]{5}                            │
│   Example: A1B2C, D3E4F, G5H6I                                 │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │ file_registry Table                                      │  │
│   ├──────────────────┬──────────────────────────────────────┤  │
│   │ Column            │ Description                          │  │
│   ├──────────────────┼──────────────────────────────────────┤  │
│   │ file_id           │ 5-char hex ID                        │  │
│   │ filename          │ Original filename                    │  │
│   │ description       │ What the file does                    │  │
│   │ functionality     │ How it's used                         │  │
│   │ connection        │ How it's connected to other files     │  │
│   │ created_at        │ Creation timestamp                    │  │
│   └──────────────────┴──────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module 3: Backend Functions (RPC)

### 3.1 Authentication Functions

```
┌─────────────────────────────────────────────────────────────────┐
│                AUTHENTICATION RPC FUNCTIONS                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  auth.create_user(email, password, role)                        │
│      → Create user with role, password hash                     │
│                                                                  │
│  auth.validate_password(password)                               │
│      → Validate 16-char password policy                         │
│                                                                  │
│  auth.initiate_recovery(email)                                  │
│      → Trigger account recovery flow                            │
│                                                                  │
│  auth.verify_email(token)                                       │
│      → Verify user email                                        │
│                                                                  │
│  auth.link_gmail(user_id, gmail)                                │
│      → Associate Gmail account                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Session Management Functions

```
┌─────────────────────────────────────────────────────────────────┐
│                SESSION MANAGEMENT FUNCTIONS                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  sessions.create(user_id)                                       │
│      → Create unique session, return session_id                 │
│                                                                  │
│  sessions.validate(session_id)                                  │
│      → Validate session exists and active                      │
│                                                                  │
│  sessions.refresh(session_id)                                   │
│      → Refresh session expiry                                   │
│                                                                  │
│  sessions.terminate(session_id)                                 │
│      → Sign out, invalidate session                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 Role-Based Access Control Functions

```
┌─────────────────────────────────────────────────────────────────┐
│                RBAC FUNCTIONS                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  rbac.get_user_role(user_id)                                    │
│      → Return: 'candidate' | 'client' | 'admin'                 │
│                                                                  │
│  rbac.can_access_page(user_id, page_id)                         │
│      → Boolean: Can user access this page                       │
│                                                                  │
│  rbac.can_access_data(user_id, data_type, target_user_id)      │
│      → Boolean: Can user access this data                       │
│                                                                  │
│  rbac.is_admin(user_id)                                         │
│      → Boolean: Is user admin                                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module 4: Frontend Architecture

### 4.1 Page Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                    PAGE REGISTRY                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐  ┌─────────────────────────────────────────┐   │
│  │  Page ID    │  │  Access                                  │   │
│  ├─────────────┼──┼─────────────────────────────────────────┤   │
│  │  A1B2C      │  │  /login          - Public               │   │
│  │  D3E4F      │  │  /signup          - Public               │   │
│  │  G5H6I      │  │  /recover         - Public               │   │
│  │  J7K8L      │  │  /dashboard/home - Candidate/Client     │   │
│  │  M9N0O      │  │  /dashboard/classroom - Candidate/Client │   │
│  │  P1Q2R      │  │  /dashboard/policies - Candidate/Client │   │
│  │  S3T4U      │  │  /dashboard/profile - Candidate/Client  │   │
│  │  V5W6X      │  │  /admin/*         - Admin only           │   │
│  └─────────────┘  └─────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Directory Structure

```
app/
├── (auth)/
│   ├── login/
│   │   └── page.tsx              # ID: A1B2C
│   ├── signup/
│   │   └── page.tsx              # ID: D3E4F
│   ├── recover/
│   │   └── page.tsx              # ID: G5H6I
│   └── callback/
│       └── route.ts              # ID: J7K8L
├── (dashboard)/
│   ├── layout.tsx                # ID: M9N0O
│   ├── home/
│   │   └── page.tsx              # ID: P1Q2R
│   ├── classroom/
│   │   └── page.tsx              # ID: S3T4U
│   ├── policies/
│   │   └── page.tsx              # ID: V5W6X
│   └── profile/
│       └── page.tsx              # ID: Y7Z8A
├── admin/
│   ├── users/
│   │   └── page.tsx              # ID: B9C0D
│   ├── tasks/
│   │   └── page.tsx              # ID: E1F2G
│   ├── contracts/
│   │   └── page.tsx              # ID: H3I4J
│   └── legal/
│       └── page.tsx              # ID: K5L6M
├── api/
│   └── auth/
│       └── callback/
│           └── route.ts          # ID: N7O8P
├── layout.tsx                    # ID: Q9R0S
└── page.tsx                      # ID: T1U2V
```

### 4.3 Component Architecture

```
components/
├── ui/                           # Reusable UI Components
│   ├── Button.tsx                # ID: W3X4Y
│   ├── Input.tsx                 # ID: Z5A6B
│   ├── Card.tsx                  # ID: C7D8E
│   ├── Modal.tsx                 # ID: F9G0H
│   ├── BottomNav.tsx             # ID: I1J2K
│   ├── GlassPill.tsx             # ID: L3M4N
│   └── ...
├── auth/
│   ├── LoginForm.tsx             # ID: O5P6Q
│   ├── SignupForm.tsx            # ID: R7S8T
│   ├── PasswordInput.tsx         # ID: U9V0W
│   └── RecoveryForm.tsx          # ID: X1Y2Z
├── dashboard/
│   ├── TaskCard.tsx              # ID: A3B4C
│   ├── TrainingPlayer.tsx        # ID: D5E6F
│   ├── DocumentationTimer.tsx    # ID: G7H8I
│   ├── PendingDisplay.tsx        # ID: J9K0L
│   └── ProfileDrawer.tsx         # ID: M1N2O
├── forms/
│   ├── ImageUpload.tsx           # ID: P3Q4R
│   ├── DocumentUpload.tsx       # ID: S5T6U
│   └── TaskForm.tsx              # ID: V7W8X
└── admin/
    ├── UserManager.tsx           # ID: Y9Z0A
    ├── TaskAssigner.tsx          # ID: B1C2D
    └── ContractViewer.tsx        # ID: E3F4G
```

---

## Module 5: UI/UX Standards

### 5.1 Bottom Navigation Bar

```
┌─────────────────────────────────────────────────────────────────┐
│                    BOTTOM NAV DESIGN                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                                                         │  │
│   │                    CONTENT AREA                         │  │
│   │                                                         │  │
│   ├─────────────────────────────────────────────────────────┤  │
│   │   ┌─────────────────────────────────────────────────┐   │  │
│   │   │  ┌─────┐   ┌─────┐   ┌─────┐   ┌─────┐         │   │  │
│   │   │  │Home │   │Class│   │Policy│   │Profile      │   │  │
│   │   │  │     │   │room │   │     │   │             │   │  │
│   │   │  └─────┘   └─────┘   └─────┘   └─────┘         │   │  │
│   │   │        FLOATING PILL - GLASS EFFECT             │   │  │
│   │   │   bg-white/20 backdrop-blur-lg shadow-xl        │   │  │
│   │   │   border-white/30 rounded-full                   │   │  │
│   │   └─────────────────────────────────────────────────┘   │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
│   ICONS: Professional, NO EMOJIS                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Profile Drawer

```
┌─────────────────────────────────────────────────────────────────┐
│                  PROFILE DRAWER DESIGN                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │  ════════════════════════════════════════════════════   │  │
│   │                                                         │  │
│   │   ┌──────┐                                            │  │
│   │   │      │  Profile Picture (uploaded, admin-        │  │
│   │   │ IMG  │  validated)                                 │  │
│   │   │      │                                            │  │
│   │   └──────┘                                            │  │
│   │                                                         │  │
│   │   ─────────────────────────────────────────────        │  │
│   │                                                         │  │
│   │   ⚙ Settings                                           │  │
│   │   🌙 Light/Dark Theme                                   │  │
│   │   📍 Address                                            │  │
│   │   📞 Contact Info                                       │  │
│   │                                                         │  │
│   │   ─────────────────────────────────────────────        │  │
│   │                                                         │  │
│   │   📄 Terms & Conditions                                 │  │
│   │   🔒 Privacy Policy                                     │  │
│   │                                                         │  │
│   │   ─────────────────────────────────────────────        │  │
│   │                                                         │  │
│   │   ┌─────────────────────────────────────────────────┐   │  │
│   │   │              SIGN OUT (Glass Pill)              │   │  │
│   │   └─────────────────────────────────────────────────┘   │  │
│   │                                                         │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
│   ANIMATION: Slides from right to left                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module 6: Feature Implementation

### 6.1 Task System Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    TASK SYSTEM FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ADMIN                    USER                  SYSTEM         │
│   ─────                   ─────                 ──────         │
│     │                       │                      │            │
│     ▼                       │                      │            │
│  Assign Task ──────────────▶│                      │            │
│     │                       │                      │            │
│     │                       ▼                      │            │
│     │                  View Task                   │            │
│     │                       │                      │            │
│     │                       ▼                      │            │
│     │              Submit Work ──────────────▶ Pending         │
│     │                       │                      │            │
│     │◀──────────────────────┤                      │            │
│     │   Review/Approve      │                      │            │
│     │◀──────────────────────┤                      │            │
│     │   or Reject           │                      │            │
│     │                       ▼                      │            │
│     │                  Complete                     │            │
│     │                       │                      │            │
│                                                                  │
│   TASK TYPES: Upload Image | Fill Form | Watch Video |         │
│               Read Content | Complete Training                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 Training System

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRAINING SYSTEM                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   VIDEO TRAINING:                                               │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │  ┌────────────────────────────────────────────────────┐  │  │
│   │  │                                                    │  │  │
│   │  │              VIDEO PLAYER                         │  │  │
│   │  │                                                    │  │  │
│   │  │                                                    │  │  │
│   │  └────────────────────────────────────────────────────┘  │  │
│   │                                                         │  │
│   │   [▶] ════════════════════════════════════════════ [■]  │  │
│   │        Progress Bar - MUST WATCH TO COMPLETE            │  │
│   │                                                         │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
│   TEXT/SCROLL TRAINING:                                         │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                                                         │  │
│   │   Content that must be scrolled to completion.         │  │
│   │   Progress tracked at bottom.                          │  │
│   │   Cannot proceed until 100% scroll reached.            │  │
│   │                                                         │  │
│   │   ═══════════════════════════════════════════════════   │  │
│   │   [███████░░░░░░░░░░░░░░░░░░░░░░░░] 70%               │  │
│   │                                                         │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.3 Documentation Timer Stages

```
┌─────────────────────────────────────────────────────────────────┐
│               DOCUMENTATION TIMER STAGES                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                                                         │  │
│   │   Stage 1: Document Validation  ═══════════▶ Stage 2  │  │
│   │              (Admin reviews uploaded docs)            │  │
│   │                                                         │  │
│   │   Stage 2: Background Check    ═══════════▶ Stage 3  │  │
│   │              (Admin runs background check)             │  │
│   │                                                         │  │
│   │   Stage 3: Skill Validation    ═══════════▶ Stage 4  │  │
│   │              (Admin verifies skills)                   │  │
│   │                                                         │  │
│   │   Stage 4: Education Validation═══════════▶ Stage 5  │  │
│   │              (Admin verifies education)                │  │
│   │                                                         │  │
│   │   Stage 5: Visa Expiration     ═══════════▶ COMPLETE  │  │
│   │              (Admin verifies work authorization)       │  │
│   │                                                         │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
│   ADMIN CAN:                                                     │
│   - Move user between stages                                    │
│   - Set timer values per stage                                  │
│   - View stage history                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.4 Image Upload with Validation

```
┌─────────────────────────────────────────────────────────────────┐
│                IMAGE UPLOAD WORKFLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────┐    ┌────────────┐    ┌─────────────┐          │
│   │  Admin   │    │    User    │    │   System    │          │
│   │Assigns  │───▶│  Uploads   │───▶│  Stores in  │          │
│   │Task     │    │  Image     │    │  Supabase   │          │
│   └──────────┘    └────────────┘    └──────┬──────┘          │
│         │                                   │                  │
│         ▼                                   ▼                  │
│   ┌──────────┐                       ┌─────────────┐          │
│   │ Reviews  │◀──────────────────────│ Admin Sees  │          │
│   │ Image    │    View              │ Image       │          │
│   └────┬─────┘                       └──────┬──────┘          │
│        │                                   │                  │
│        ▼                                   ▼                  │
│   ┌──────────┐                       ┌─────────────┐          │
│   │Approve   │                       │  Pending    │          │
│   │OR        │                       │  Display    │          │
│   │Reject    │                       │  Status     │          │
│   └──────────┘                       └─────────────┘          │
│                                                                  │
│   If Rejected: User must retake/resubmit                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module 7: Admin Portal

### 7.1 Admin Features

```
┌─────────────────────────────────────────────────────────────────┐
│                    ADMIN PORTAL FEATURES                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│   │   Users      │  │    Tasks     │  │  Contracts   │         │
│   │   Manager    │  │   Assigner   │  │   Viewer     │         │
│   └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│   │   Legal      │  │  Page        │  │   Data       │         │
│   │   References │  │  Templates  │  │  Compliance  │         │
│   │   (50 States)│  │   Viewer     │  │    Views     │         │
│   └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
│   ADMIN CAPABILITIES:                                           │
│   ✓ Terminate user accounts                                     │
│   ✓ Recover user accounts                                       │
│   ✓ Assign tasks to users                                       │
│   ✓ Approve/reject submissions                                  │
│   ✓ View contracts (PDF)                                        │
│   ✓ Manage legal references                                     │
│   ✓ View all data (compliance)                                 │
│   ✓ Assign policies to users                                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Page Template Viewer

```
┌─────────────────────────────────────────────────────────────────┐
│               PAGE TEMPLATE VIEWER                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Admin can view all pages as:                                   │
│   - Candidate (Employee)                                        │
│   - VIP Client (Employer)                                        │
│   - See what each role sees                                     │
│   - Understand task assignment locations                        │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │  [View as: ▼ Candidate] [▼ VIP Client] [▼ Admin]       │  │
│   ├─────────────────────────────────────────────────────────┤  │
│   │                                                         │  │
│   │            Selected Role Page Preview                  │  │
│   │                                                         │  │
│   │            with explanations                            │  │
│   │                                                         │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module 8: Environment Configuration

### 8.1 Environment Variables

```
┌─────────────────────────────────────────────────────────────────┐
│                ENVIRONMENT VARIABLES                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   # .env.local (Client-side)                                    │
│   NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co           │
│   NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_xxxxxxxxx       │
│                                                                  │
│   # .env (Server-side only)                                     │
│   SUPABASE_SERVICE_ROLE_KEY=sb_secret_xxxxxxxxxxxx             │
│                                                                  │
│   ⚠️  ANON KEY IS SAFE TO EXPOSE IN CLIENT                      │
│   ⚠️  SERVICE ROLE KEY MUST REMAIN SERVER-SIDE                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module 9: Data Privacy & Compliance

### 9.1 Data Access Rules

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATA ACCESS RULES                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   CANDIDATE → Can see own data                                  │
│   VIP CLIENT → Can see own data + assigned candidates          │
│   ADMIN → Can see ALL data (compliance view)                   │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                                                         │  │
│   │   EMPLOYER (VIP Client) CANNOT SEE:                    │  │
│   │   ✗ Candidate PII (SSN, DOB, address)                  │  │
│   │   ✗ Confidential documents                             │  │
│   │   ✓ Name, profile picture, assigned status            │  │
│   │                                                         │  │
│   │   ALL DATA SECURED IN DATABASE                         │  │
│   │   NO REFERENCES IN FRONTEND CODE                       │  │
│   │                                                         │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 9.2 Row Level Security

```
┌─────────────────────────────────────────────────────────────────┐
│                    RLS POLICIES                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   All tables have RLS enabled:                                  │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │  CREATE POLICY "users_select_own" ON profiles         │  │
│   │  FOR SELECT USING (auth.uid() = user_id);              │  │
│   │                                                          │  │
│   │  CREATE POLICY "admins_select_all" ON profiles         │  │
│   │  FOR SELECT USING (                                      │  │
│   │    EXISTS (SELECT 1 FROM profiles                       │  │
│   │             WHERE role = 'admin'                        │  │
│   │             AND user_id = auth.uid())                   │  │
│   │  );                                                     │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Implementation Checklist

```
┌─────────────────────────────────────────────────────────────────┐
│                IMPLEMENTATION CHECKLIST                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Phase 1: Database Setup                                        │
│   □ Create all core tables                                      │
│   □ Set up RLS policies                                         │
│   □ Create file_registry table                                  │
│   □ Create page_registry table                                  │
│                                                                  │
│   Phase 2: Backend Functions                                     │
│   □ Auth RPC functions                                          │
│   □ Session management functions                                │
│   □ RBAC functions                                              │
│   □ File registry functions                                     │
│                                                                  │
│   Phase 3: Frontend Setup                                        │
│   □ Initialize Next.js 14                                        │
│   □ Configure Supabase client                                   │
│   □ Set up authentication flow                                   │
│                                                                  │
│   Phase 4: Core Features                                         │
│   □ Login/Signup/Recovery                                        │
│   □ Dashboard with bottom nav                                   │
│   □ Task system                                                  │
│   □ Training system                                              │
│   □ Documentation timer                                          │
│   □ Policy pages                                                 │
│   □ Profile drawer                                              │
│                                                                  │
│   Phase 5: Admin Portal                                          │
│   □ User management                                             │
│   □ Task assignment                                              │
│   □ Contract viewing                                             │
│   □ Legal references (50 states)                                │
│                                                                  │
│   Phase 6: Security & Optimization                              │
│   □ Data optimization                                            │
│   □ Performance testing                                          │
│   □ Security audit                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Code Standards

### File Naming Convention

```
┌─────────────────────────────────────────────────────────────────┐
│                    FILE NAMING CONVENTION                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   All files must include 5-character hex ID:                   │
│                                                                  │
│   ✓ page.tsx              → A1B2C-page.tsx                     │
│   ✓ Button.tsx            → C3D4E-Button.tsx                   │
│   ✓ LoginForm.tsx         → F5G6H-LoginForm.tsx                │
│                                                                  │
│   Format: [A-F0-9]{5}-[ComponentName].tsx                       │
│                                                                  │
│   ID Assignment: Sequential, unique per file                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Code Principles

```
┌─────────────────────────────────────────────────────────────────┐
│                    CODE PRINCIPLES                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   1. NO GOD FILES                                               │
│      - Split large components                                  │
│      - Single responsibility per file                            │
│                                                                  │
│   2. LOGIC IN BACKEND                                           │
│      - All business logic in Supabase RPC                       │
│      - Frontend only for display                                │
│                                                                  │
│   3. NO DATA EXPOSURE                                           │
│      - No PII in client code                                    │
│      - All queries through RPC                                  │
│                                                                  │
│   4. OPTIMIZED DATA FETCHING                                    │
│      - No data overload                                         │
│      - Pagination for large lists                              │
│      - Selective field fetching                                │
│                                                                  │
│   5. TYPE SAFETY                                                 │
│      - TypeScript for all components                            │
│      - Strict type checking                                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

*Last Updated: 2026-03-02*
*Stack: Vercel + Supabase + Next.js 14*
