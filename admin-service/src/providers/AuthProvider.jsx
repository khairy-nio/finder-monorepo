import { useCallback, useEffect, useMemo, useState } from 'react';
import { onAuthStateChanged, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import api from '../api/axios';
import { auth, firebaseConfigError } from '../config/firebase';
import toast from 'react-hot-toast';
import { AuthContext } from './authContext';

export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(Boolean(auth));

  const logout = useCallback(async () => {
    if (auth) {
      await signOut(auth);
    }
    localStorage.removeItem('admin_token');
    setIsAdmin(false);
    setCurrentUser(null);
  }, []);

  useEffect(() => {
    if (!auth) {
      const token = localStorage.getItem('admin_token');
      if (token && token.startsWith('mock-token-')) {
        setIsAdmin(true);
        setCurrentUser({ id: 'mock-admin-id', name: 'MOCK ADMIN', email: 'admin@example.com', role: 'admin' });
      } else {
        localStorage.removeItem('admin_token');
      }
      setLoading(false);
      return undefined;
    }

    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        try {
          const token = await firebaseUser.getIdToken();
          localStorage.setItem('admin_token', token);

          const response = await api.get('/user/me');
          const userProfile = response.data?.user || response.data || response;

          if (userProfile.role === 'admin') {
            setIsAdmin(true);
            setCurrentUser(userProfile);
          } else {
            toast.error('Unauthorized: Admin access required.');
            await logout();
          }
        } catch (error) {
          console.error('Auth validation failed:', error);
          toast.error('Authentication or role validation failed.');
          await logout();
        }
      } else {
        setIsAdmin(false);
        setCurrentUser(null);
        localStorage.removeItem('admin_token');
      }

      setLoading(false);
    });

    return unsubscribe;
  }, [logout]);

  const login = async (email, password) => {
    if (!auth) {
      if (email === 'admin@example.com' && password === 'admin123') {
        console.warn('🔑 Logging in with mock admin credentials offline.');
        localStorage.setItem('admin_token', 'mock-token-admin');
        setIsAdmin(true);
        setCurrentUser({ id: 'mock-admin-id', name: 'MOCK ADMIN', email: 'admin@example.com', role: 'admin' });
        toast.success('Signed in successfully offline!');
        return;
      }
      throw new Error(firebaseConfigError ? `${firebaseConfigError} (Use admin@example.com / admin123 for offline mock login)` : 'Firebase is not configured.');
    }
    return signInWithEmailAndPassword(auth, email, password);
  };


  const value = useMemo(
    () => ({
      currentUser,
      isAdmin,
      loading,
      login,
      logout,
      authError: firebaseConfigError,
    }),
    [currentUser, isAdmin, loading, logout]
  );

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
};
