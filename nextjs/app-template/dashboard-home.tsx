/**
 * Stack Standards: Dashboard Page Templates
 * Version: 1.0
 * Reusable page templates for common dashboard pages
 */

import Link from 'next/link'
import { createClientClient, queries } from '@/lib/supabase'

// =====================================================
// HOME PAGE TEMPLATE
// =====================================================

export default async function DashboardHomePage() {
  const supabase = createClientClient()
  
  // Get session
  const { data: { session } } = await supabase.auth.getSession()
  
  if (!session) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <p>Please log in to access your dashboard.</p>
      </div>
    )
  }
  
  // Get user profile
  const { data: profile } = await queries.getProfile(supabase, session.user.id)
  
  // Get tasks
  const { data: tasks } = await queries.getTasks(supabase, session.user.id)
  
  // Get documentation stage
  const { data: docStage } = await queries.getDocumentationStage(supabase, session.user.id)
  
  const pendingTasks = tasks?.filter(t => t.status === 'pending').length || 0
  const submittedTasks = tasks?.filter(t => t.status === 'submitted').length || 0
  
  return (
    <div className="p-6 space-y-6">
      {/* Welcome Header */}
      <header className="mb-8">
        <h1 className="text-2xl font-bold">
          Welcome back, {profile?.full_name || 'User'}
        </h1>
        <p className="text-gray-600">
          {new Date().toLocaleDateString('en-US', { 
            weekday: 'long', 
            year: 'numeric', 
            month: 'long', 
            day: 'numeric' 
          })}
        </p>
      </header>
      
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <StatCard 
          title="Pending Tasks" 
          value={pendingTasks}
          href="/dashboard/classroom"
          color="yellow"
        />
        <StatCard 
          title="Awaiting Review" 
          value={submittedTasks}
          href="/dashboard/classroom"
          color="blue"
        />
        <StatCard 
          title="Documentation Stage" 
          value={docStage?.stage?.name || 'Complete'}
          href="/dashboard/policies"
          color="green"
        />
      </div>
      
      {/* Task List */}
      <section>
        <h2 className="text-xl font-semibold mb-4">Your Tasks</h2>
        <div className="space-y-3">
          {tasks?.slice(0, 5).map((task) => (
            <TaskCard key={task.id} task={task} />
          ))}
          {(!tasks || tasks.length === 0) && (
            <p className="text-gray-500">No tasks assigned yet.</p>
          )}
        </div>
      </section>
    </div>
  )
}

// Stat Card Component
function StatCard({ 
  title, 
  value, 
  href, 
  color = 'blue' 
}: { 
  title: string
  value: string | number
  href: string
  color?: 'blue' | 'yellow' | 'green' | 'red'
}) {
  const colors = {
    blue: 'bg-blue-50 border-blue-200 text-blue-800',
    yellow: 'bg-yellow-50 border-yellow-200 text-yellow-800',
    green: 'bg-green-50 border-green-200 text-green-800',
    red: 'bg-red-50 border-red-200 text-red-800',
  }
  
  return (
    <Link 
      href={href}
      className={`p-4 rounded-lg border ${colors[color]} hover:shadow-md transition-shadow`}
    >
      <p className="text-sm opacity-75">{title}</p>
      <p className="text-2xl font-bold">{value}</p>
    </Link>
  )
}

// Task Card Component  
function TaskCard({ task }: { task: any }) {
  const statusColors = {
    pending: 'bg-yellow-100 text-yellow-800',
    in_progress: 'bg-blue-100 text-blue-800',
    submitted: 'bg-purple-100 text-purple-800',
    approved: 'bg-green-100 text-green-800',
    rejected: 'bg-red-100 text-red-800',
  }
  
  return (
    <div className="flex items-center justify-between p-4 bg-white border rounded-lg hover:shadow-md transition-shadow">
      <div>
        <h3 className="font-medium">{task.title}</h3>
        <p className="text-sm text-gray-500">{task.description}</p>
      </div>
      <div className="flex items-center gap-3">
        <span className={`px-3 py-1 rounded-full text-xs ${statusColors[task.status as keyof typeof statusColors]}`}>
          {task.status}
        </span>
        {task.due_date && (
          <span className="text-sm text-gray-500">
            Due: {new Date(task.due_date).toLocaleDateString()}
          </span>
        )}
      </div>
    </div>
  )
}
