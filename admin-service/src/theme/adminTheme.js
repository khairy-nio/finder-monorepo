import { alpha, createTheme } from '@mui/material/styles';

const radius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
};

const buildPalette = (mode) => {
  const dark = mode === 'dark';

  return {
    mode,
    primary: {
      main: dark ? '#FFFFFF' : '#000000',
      contrastText: dark ? '#000000' : '#FFFFFF',
    },
    secondary: {
      main: '#6366F1', // Indigo
    },
    background: {
      default: dark ? '#000000' : '#FFFFFF',
      paper: dark ? '#0A0A0A' : '#FFFFFF',
    },
    text: {
      primary: dark ? '#FFFFFF' : '#000000',
      secondary: dark ? '#A1A1AA' : '#52525B',
    },
    divider: dark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.08)',
  };
};

export const getAdminTheme = (mode) => {
  const dark = mode === 'dark';
  const palette = buildPalette(mode);

  return createTheme({
    palette,
    shape: {
      borderRadius: radius.md,
    },
    typography: {
      fontFamily: '"Urbanist", sans-serif',
      h4: { fontWeight: 800, letterSpacing: '-0.04em' },
      h5: { fontWeight: 800, letterSpacing: '-0.03em' },
      h6: { fontWeight: 800, letterSpacing: '-0.02em' },
      button: { textTransform: 'none', fontWeight: 600 },
    },
    custom: {
      radius,
      shadows: {
        card: dark ? '0 0 0 1px rgba(255,255,255,0.1), 0 20px 40px rgba(0,0,0,0.4)' : '0 0 0 1px rgba(0,0,0,0.05), 0 20px 40px rgba(0,0,0,0.05)',
      }
    },
    components: {
      MuiCssBaseline: {
        styleOverrides: {
          body: {
            backgroundColor: palette.background.default,
            backgroundAttachment: 'fixed',
            backgroundImage: dark 
              ? `radial-gradient(at 0% 0%, rgba(99, 102, 241, 0.15) 0px, transparent 50%), radial-gradient(at 100% 100%, rgba(168, 85, 247, 0.15) 0px, transparent 50%)`
              : `radial-gradient(at 0% 0%, rgba(99, 102, 241, 0.05) 0px, transparent 50%), radial-gradient(at 100% 100%, rgba(168, 85, 247, 0.05) 0px, transparent 50%)`,
          }
        }
      },
      MuiCard: {
        styleOverrides: {
          root: {
            borderRadius: radius.xl,
            backgroundImage: 'none',
            backgroundColor: dark ? 'rgba(10, 10, 10, 0.7)' : 'rgba(255, 255, 255, 0.7)',
            backdropFilter: 'blur(20px)',
            border: `1px solid ${palette.divider}`,
            boxShadow: 'none',
          }
        }
      },
      MuiButton: {
        styleOverrides: {
          root: {
            borderRadius: radius.md,
            padding: '10px 20px',
          }
        }
      }
    }
  });
};
