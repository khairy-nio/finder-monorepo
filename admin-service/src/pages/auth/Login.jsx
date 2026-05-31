import { useState } from 'react';
import { Box, Button, TextField, Typography, Paper, Alert } from '@mui/material';
import { useAuth } from '../../providers/authContext';
import { Navigate, useNavigate } from 'react-router-dom';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { login, isAdmin } = useAuth();
  const navigate = useNavigate();

  if (isAdmin) return <Navigate to="/dashboard" replace />;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setIsSubmitting(true);
    
    try {
      await login(email, password);
      navigate('/dashboard');
    } catch (err) {
      console.error('Login component error:', err);
      const errMsg = err.response?.data?.message || err.message || 'Invalid credentials or unauthorized access.';
      setError(errMsg);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', bgcolor: '#F4F6F8' }}>
      <Paper sx={{ p: 4, maxWidth: 400, width: '100%', borderRadius: 2 }}>
        <Typography variant="h5" fontWeight="bold" textAlign="center" mb={1} color="#0A3D91">
          Admin Portal
        </Typography>
        <Typography variant="body2" color="text.secondary" textAlign="center" mb={3}>
          Sign in with your admin credentials
        </Typography>

        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

        <form onSubmit={handleSubmit}>
          <TextField
            fullWidth
            label="Email"
            margin="normal"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            type="email"
          />
          <TextField
            fullWidth
            label="Password"
            type="password"
            margin="normal"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          <Button
            fullWidth
            type="submit"
            variant="contained"
            size="large"
            disabled={isSubmitting}
            sx={{ mt: 3, bgcolor: '#0A3D91' }}
          >
            {isSubmitting ? 'Signing In...' : 'Sign In'}
          </Button>
        </form>
      </Paper>
    </Box>
  );
}
