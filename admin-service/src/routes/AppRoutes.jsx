import { Routes, Route, Navigate } from 'react-router-dom';
import { Alert, Box, CircularProgress } from '@mui/material';
import { useAuth } from '../providers/authContext';
import AdminLayout from '../layouts/AdminLayout';

// Static Imports for Pages
import Login from '../pages/auth/Login';
import Dashboard from '../pages/dashboard/Dashboard';
import Users from '../pages/users/Users';
import Reports from '../pages/reports/Reports';
import Verification from '../pages/verification/Verification';
import Posts from '../pages/posts/Posts';
import Redemptions from '../pages/redemptions/Redemptions';

// Protected Route Wrapper
const ProtectedRoute = ({ children }) => {
  const { isAdmin, loading, authError } = useAuth();
  
  if (loading) {
    return (
      <Box display="flex" minHeight="100vh" alignItems="center" justifyContent="center">
        <CircularProgress />
      </Box>
    );
  }

  if (!isAdmin) return <Navigate to="/login" replace />;
  
  return children;
};

export default function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      
      <Route path="/" element={<ProtectedRoute><AdminLayout /></ProtectedRoute>}>
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<Dashboard />} />
        <Route path="users" element={<Users />} />
        <Route path="reports" element={<Reports />} />
        <Route path="verification" element={<Verification />} />
        <Route path="posts" element={<Posts />} />
        <Route path="redemptions" element={<Redemptions />} />
      </Route>
      
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
