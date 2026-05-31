import { useCallback, useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import toast from 'react-hot-toast';
import { AuthContext } from './authContext';

const jwtLogin = async (email, password) => {
  const baseURL = import.meta.env.VITE_API_URL || 'http://localhost:3500/api/v1';
  const res = await axios.post(`${baseURL}/auth/login`, { email, password });
  const token = res.data.data.token;
  const user = res.data.data.user;
  if (!token) throw new Error('No token returned from server');
  return { token, user };
};

const jwtValidate = async () => {
  const baseURL = import.meta.env.VITE_API_URL || 'http://localhost:3500/api/v1';
  const token = localStorage.getItem('admin_token');
  if (!token) throw new Error('No token found');
  const res = await axios.get(`${baseURL}/auth/me`, {
    headers: {
      Authorization: `Bearer ${token}`
    }
  });
  return res.data.data.user;
};

export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);

  const logout = useCallback(() => {
    localStorage.removeItem('admin_token');
    setIsAdmin(false);
    setCurrentUser(null);
  }, []);

  useEffect(() => {
    const token = localStorage.getItem('admin_token');
    if (token) {
      jwtValidate()
        .then((user) => {
          if (user?.role === 'admin') {
            setIsAdmin(true);
            setCurrentUser(user);
          } else {
            localStorage.removeItem('admin_token');
            setIsAdmin(false);
            setCurrentUser(null);
          }
        })
        .catch(() => {
          localStorage.removeItem('admin_token');
          setIsAdmin(false);
          setCurrentUser(null);
        })
        .finally(() => setLoading(false));
    } else {
      setLoading(false);
    }
  }, []);

  const login = async (email, password) => {
    try {
      const data = await jwtLogin(email, password);
      
      if (data.user?.role !== 'admin') {
        throw new Error('Unauthorized: Admin access required.');
      }

      localStorage.setItem('admin_token', data.token);
      setIsAdmin(true);
      setCurrentUser(data.user);
      toast.success('Signed in successfully!');
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  };

  const value = useMemo(
    () => ({
      currentUser,
      isAdmin,
      loading,
      login,
      logout,
      authError: null,
    }),
    [currentUser, isAdmin, loading, logout]
  );

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
};
