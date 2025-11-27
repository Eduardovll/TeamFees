import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import Landing from './pages/Landing';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Fees from './pages/Fees';
import MyFees from './pages/MyFees';
import Payments from './pages/Payments';
import Members from './pages/Members';
import Profile from './pages/Profile';
import Activate from './pages/Activate';
import GenerateFees from './pages/GenerateFees';
import Billing from './pages/Billing';
import AdminTenants from './pages/AdminTenants';

function PrivateRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center">
      <div className="text-xl">Carregando...</div>
    </div>;
  }

  return user ? <>{children}</> : <Navigate to="/login" />;
}

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="/login" element={<Login />} />
          <Route path="/activate/:token" element={<Activate />} />
          <Route path="/dashboard" element={
            <PrivateRoute>
              <Dashboard />
            </PrivateRoute>
          } />
          <Route path="/my-fees" element={
            <PrivateRoute>
              <MyFees />
            </PrivateRoute>
          } />
          <Route path="/fees" element={
            <PrivateRoute>
              <Fees />
            </PrivateRoute>
          } />
          <Route path="/payments" element={
            <PrivateRoute>
              <Payments />
            </PrivateRoute>
          } />
          <Route path="/members" element={
            <PrivateRoute>
              <Members />
            </PrivateRoute>
          } />
          <Route path="/profile" element={
            <PrivateRoute>
              <Profile />
            </PrivateRoute>
          } />
          <Route path="/generate-fees" element={
            <PrivateRoute>
              <GenerateFees />
            </PrivateRoute>
          } />
          <Route path="/billing" element={
            <PrivateRoute>
              <Billing />
            </PrivateRoute>
          } />
          <Route path="/admin/tenants" element={
            <PrivateRoute>
              <AdminTenants />
            </PrivateRoute>
          } />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
