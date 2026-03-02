/**
 * Stack Standards: Supabase Client Library
 * Version: 1.0
 * Purpose: Centralized Supabase client configuration
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js'
import { cookies } from 'next/headers'

// Types for environment
interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          user_id: string
          email: string
          full_name: string | null
          role: 'admin' | 'candidate' | 'client'
          status: 'active' | 'inactive' | 'suspended' | 'pending'
          avatar_url: string | null
          phone: string | null
          address: Json | null
          metadata: Json
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          email: string
          full_name?: string | null
          role?: 'admin' | 'candidate' | 'client'
          status?: 'active' | 'inactive' | 'suspended' | 'pending'
          avatar_url?: string | null
          phone?: string | null
          address?: Json | null
          metadata?: Json
        }
        Update: {
          id?: string
          user_id?: string
          email?: string
          full_name?: string | null
          role?: 'admin' | 'candidate' | 'client'
          status?: 'active' | 'inactive' | 'suspended' | 'pending'
          avatar_url?: string | null
          phone?: string | null
          address?: Json | null
          metadata?: Json
        }
      }
      tasks: {
        Row: {
          id: string
          user_id: string
          title: string
          description: string | null
          type: 'upload' | 'form' | 'video' | 'training' | 'document'
          status: 'pending' | 'in_progress' | 'submitted' | 'approved' | 'rejected'
          priority: 'low' | 'normal' | 'high' | 'urgent'
          due_date: string | null
          assigned_by: string | null
          metadata: Json
          created_at: string
          updated_at: string
        }
      }
      // Add more tables as needed
    }
  }
}

type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

// Singleton pattern for server-side
let serverClient: SupabaseClient | null = null
let clientClient: SupabaseClient | null = null

/**
 * Get Supabase client for server-side operations
 * Uses cookies for auth
 */
export function createServerClient(): SupabaseClient<Database> {
  if (serverClient) {
    return serverClient
  }

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

  serverClient = createClient<Database>(supabaseUrl, supabaseKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  })

  return serverClient
}

/**
 * Get Supabase client for client-side operations
 * Uses public anon key
 */
export function createClientClient(): SupabaseClient<Database> {
  if (clientClient) {
    return clientClient
  }

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

  clientClient = createClient<Database>(supabaseUrl, supabaseKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  })

  return clientClient
}

/**
 * Get client with session from cookies (Next.js App Router)
 */
export async function getServerClient(): Promise<SupabaseClient<Database>> {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

  const cookieStore = await cookies()

  return createClient<Database>(supabaseUrl, supabaseKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
    global: {
      headers: {
        cookie: cookieStore.toString(),
      },
    },
  })
}

/**
 * Type-safe database helper
 */
export type Tables<T extends keyof Database['public']['Tables']> = Database['public']['Tables'][T]['Row']
export type Insert<T extends keyof Database['public']['Tables']> = Database['public']['Tables'][T]['Insert']
export type Update<T extends keyof Database['public']['Tables']> = Database['public']['Tables'][T]['Update']

/**
 * Common query helpers
 */
export const queries = {
  /**
   * Get user profile with role
   */
  async getProfile(supabase: SupabaseClient, userId: string) {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('user_id', userId)
      .single()

    return { data, error }
  },

  /**
   * Get tasks for user
   */
  async getTasks(supabase: SupabaseClient, userId: string, status?: string) {
    let query = supabase
      .from('tasks')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })

    if (status) {
      query = query.eq('status', status)
    }

    const { data, error } = await query
    return { data, error }
  },

  /**
   * Get user's documentation stage
   */
  async getDocumentationStage(supabase: SupabaseClient, userId: string) {
    const { data, error } = await supabase
      .from('user_documentation')
      .select(`
        *,
        stage:documentation_stages(*)
      `)
      .eq('user_id', userId)
      .eq('status', 'in_progress')
      .single()

    return { data, error }
  },

  /**
   * Get page registry for role
   */
  async getPagesForRole(supabase: SupabaseClient, role: string) {
    const { data, error } = await supabase
      .from('page_registry')
      .select('*')
      .or(`required_role.eq.${role},required_role.eq.public`)
      .eq('is_active', true)
      .order('order_index')

    return { data, error }
  },
}

/**
 * Role checking helpers
 */
export const roles = {
  isAdmin(profile: Tables<'profiles'> | null): boolean {
    return profile?.role === 'admin'
  },

  isClient(profile: Tables<'profiles'> | null): boolean {
    return profile?.role === 'client'
  },

  isCandidate(profile: Tables<'profiles'> | null): boolean {
    return profile?.role === 'candidate'
  },

  canAccess(profile: Tables<'profiles'> | null, requiredRole: string): boolean {
    if (requiredRole === 'public') return true
    if (!profile) return false
    if (profile.role === 'admin') return true
    return profile.role === requiredRole
  },

  getDisplayName(profile: Tables<'profiles'> | null): string {
    if (!profile) return 'Guest'
    if (profile.role === 'admin') return 'Admin'
    if (profile.role === 'client') return 'VIP Client'
    return 'Candidate'
  },
}

export default {
  createServerClient,
  createClientClient,
  getServerClient,
  queries,
  roles,
}
