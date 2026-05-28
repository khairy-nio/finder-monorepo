import { useMemo, useState } from 'react';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { getAdminTheme } from '../theme/adminTheme';
import { ThemeModeContext } from './themeModeContext';

const getInitialMode = () => {
  const stored = localStorage.getItem('admin_theme_mode');
  if (stored === 'light' || stored === 'dark') return stored;
  return window.matchMedia?.('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
};

export function ThemeModeProvider({ children }) {
  const [mode, setMode] = useState(getInitialMode);

  const value = useMemo(() => ({
    mode,
    toggleMode: () => {
      setMode((current) => {
        const next = current === 'dark' ? 'light' : 'dark';
        localStorage.setItem('admin_theme_mode', next);
        return next;
      });
    },
  }), [mode]);

  const theme = useMemo(() => getAdminTheme(mode), [mode]);

  return (
    <ThemeModeContext.Provider value={value}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        {children}
      </ThemeProvider>
    </ThemeModeContext.Provider>
  );
}
