import { Navigate, useLocation } from 'react-router-dom'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import Layout from './Layout'
import Dashboard from './pages/Dashboard'
import HabitTemplates from './pages/HabitTemplates'
import Login from './pages/Login'
import Notices from './pages/Notices'
import SystemConfig from './pages/SystemConfig'
import Users from './pages/Users'

function getToken(): string | null {
  return localStorage.getItem('bloom_admin_token')
}

function Protected({ children }: { children: React.ReactNode }) {
  const location = useLocation()
  const token = getToken()
  if (!token) {
    return <Navigate to="/login" state={{ from: location }} replace />
  }
  return <>{children}</>
}

function PublicOnly({ children }: { children: React.ReactNode }) {
  const token = getToken()
  if (token) {
    return <Navigate to="/" replace />
  }
  return <>{children}</>
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<PublicOnly><Login /></PublicOnly>} />
        <Route
          path="/"
          element={
            <Protected>
              <Layout />
            </Protected>
          }
        >
          <Route index element={<Dashboard />} />
          <Route path="users" element={<Users />} />
          <Route path="habit-templates" element={<HabitTemplates />} />
          <Route path="notices" element={<Notices />} />
          <Route path="system-config" element={<SystemConfig />} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
