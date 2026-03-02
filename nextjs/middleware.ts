/**
 * Stack Standards: Authentication Middleware
 * Version: 1.0
 * Purpose: Role-based route protection
 */

import { createServerClient, getServerClient } from '@/lib/supabase'
import { NextResponse, type NextRequest } from 'next/server'

// Routes that don't require authentication
const publicRoutes = [
  '/',
  '/login',
  '/signup',
  '/recover',
  '/auth/callback',
  '/api/auth/callback',
]

// Routes that require admin
const adminRoutes = [
  '/admin',
  '/admin/users',
  '/admin/tasks',
  '/admin/contracts',
  '/admin/settings',
]

// Routes that require client (employer)
const clientRoutes = [
  '/dashboard/employer',
  '/dashboard/requests',
]

export async function middleware(request: NextRequest) {
  const { nextUrl, cookies } = request
  
  // Skip for static files and API
  if (
    nextUrl.pathname.startsWith('/_next') ||
    nextUrl.pathname.startsWith('/api') ||
    nextUrl.pathname.includes('.')
  ) {
    return NextResponse.next()
  }

  // Get Supabase response with cookies
  const supabase = createServerClient()
  
  // Refresh session if needed
  const {
    data: { session },
    error: sessionError,
  } = await supabase.auth.getSession()

  const isAuthenticated = !!session?.user
  const userId = session?.user?.id

  // Get user profile for role
  let profile = null
  if (userId) {
    const { data: profileData } = await supabase
      .from('profiles')
      .select('*')
      .eq('user_id', userId)
      .single()
    
    profile = profileData
  }

  // Check if route is public
  const isPublicRoute = publicRoutes.some(route => 
    nextUrl.pathname === route || nextUrl.pathname.startsWith(route + '/')
  )

  // Redirect authenticated users away from auth pages
  if (isPublicRoute && isAuthenticated && nextUrl.pathname !== '/') {
    // Already logged in, redirect to dashboard
    return NextResponse.redirect(new URL('/dashboard/home', request.url))
  }

  // Redirect unauthenticated users to login
  if (!isPublicRoute && !isAuthenticated) {
    const loginUrl = new URL('/login', request.url)
    loginUrl.searchParams.set('redirect', nextUrl.pathname)
    return NextResponse.redirect(loginUrl)
  }

  // Check admin routes
  if (userId && adminRoutes.some(route => nextUrl.pathname.startsWith(route))) {
    if (profile?.role !== 'admin') {
      return NextResponse.redirect(new URL('/dashboard/home', request.url))
    }
  }

  // Check client routes
  if (userId && clientRoutes.some(route => nextUrl.pathname.startsWith(route))) {
    if (profile?.role !== 'client' && profile?.role !== 'admin') {
      return NextResponse.redirect(new URL('/dashboard/home', request.url))
    }
  }

  // Add headers for security
  const response = NextResponse.next()
  
  // Security headers
  response.headers.set('X-Frame-Options', 'DENY')
  response.headers.set('X-Content-Type-Options', 'nosniff')
  response.headers.set('X-XSS-Protection', '1; mode=block')
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin')
  response.headers.set(
    'Strict-Transport-Security',
    'max-age=31536000; includeSubDomains'
  )

  // Pass user info to server components via headers
  if (userId && profile) {
    response.headers.set('x-user-id', userId)
    response.headers.set('x-user-role', profile.role)
    response.headers.set('x-user-email', session?.user?.email || '')
  }

  return response
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder files
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\..*$).*)',
  ],
}
