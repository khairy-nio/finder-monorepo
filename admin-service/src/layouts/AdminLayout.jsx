import { useState } from 'react';
import {
  Avatar,
  Badge,
  Box,
  Drawer,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  Stack,
  Tooltip,
  Typography,
  alpha,
  useMediaQuery,
} from '@mui/material';
import {
  ArticleRounded as PostsIcon,
  DashboardRounded as DashboardIcon,
  DarkModeRounded as DarkMode,
  LightModeRounded as LightMode,
  LogoutRounded as LogoutIcon,
  MenuRounded as MenuIcon,
  NotificationsRounded as NotificationsIcon,
  PeopleRounded as UsersIcon,
  ReportRounded as ReportsIcon,
  SecurityRounded as VerifyIcon,
} from '@mui/icons-material';
import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useTheme } from '@mui/material/styles';
import { useAuth } from '../providers/authContext';
import { useThemeMode } from '../providers/themeModeContext';

const menuItems = [
  { text: 'Dashboard', icon: <DashboardIcon />, path: '/dashboard' },
  { text: 'Users', icon: <UsersIcon />, path: '/users' },
  { text: 'Verifications', icon: <VerifyIcon />, path: '/verification' },
  { text: 'Reports', icon: <ReportsIcon />, path: '/reports' },
  { text: 'Posts', icon: <PostsIcon />, path: '/posts' },
];

export default function AdminLayout() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const { logout, currentUser } = useAuth();
  const { mode, toggleMode } = useThemeMode();
  const navigate = useNavigate();
  const location = useLocation();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));

  const sidebar = (
    <Stack 
      height="100%" 
      justifyContent="space-between" 
      py={4} 
      sx={{ 
        bgcolor: 'transparent',
        alignItems: 'center'
      }}
    >
      <Stack spacing={4} alignItems="center" width="100%">
        <Box 
          onClick={() => navigate('/dashboard')}
          sx={{ 
            cursor: 'pointer',
            fontSize: 24,
            fontWeight: 900,
            color: 'primary.main',
            mb: 2
          }}
        >
          LF
        </Box>

        <List sx={{ width: '100%', px: 1 }}>
          {menuItems.map((item) => {
            const active = location.pathname.startsWith(item.path);
            return (
              <ListItem key={item.text} disablePadding sx={{ mb: 2, justifyContent: 'center' }}>
                <Tooltip title={item.text} placement="right" arrow>
                  <ListItemButton
                    onClick={() => {
                      navigate(item.path);
                      if (isMobile) setMobileOpen(false);
                    }}
                    sx={{
                      minHeight: 54,
                      width: 54,
                      borderRadius: '18px',
                      justifyContent: 'center',
                      color: active ? 'primary.main' : 'text.secondary',
                      bgcolor: active ? alpha(theme.palette.primary.main, 0.08) : 'transparent',
                      transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                      '&:hover': {
                        bgcolor: alpha(theme.palette.primary.main, 0.05),
                        transform: 'translateY(-2px)',
                      },
                      '&.Mui-selected': {
                        bgcolor: alpha(theme.palette.primary.main, 0.1),
                      },
                    }}
                  >
                    <ListItemIcon sx={{ color: 'inherit', minWidth: 0 }}>
                      {item.icon}
                    </ListItemIcon>
                  </ListItemButton>
                </Tooltip>
              </ListItem>
            );
          })}
        </List>
      </Stack>

      <Stack spacing={2} alignItems="center">
        <Tooltip title="Logout" placement="right" arrow>
          <IconButton 
            onClick={logout}
            sx={{ 
              width: 54, 
              height: 54, 
              borderRadius: '18px',
              color: 'text.secondary',
              '&:hover': { color: 'error.main', bgcolor: alpha(theme.palette.error.main, 0.05) }
            }}
          >
            <LogoutIcon />
          </IconButton>
        </Tooltip>
      </Stack>
    </Stack>
  );

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      {!isMobile && (
        <Box 
          sx={{ 
            width: 88, 
            height: '100vh', 
            position: 'fixed', 
            left: 0, 
            top: 0, 
            zIndex: 100,
            borderRight: `1px solid ${theme.palette.divider}`,
            bgcolor: alpha(theme.palette.background.default, 0.4),
            backdropFilter: 'blur(20px)'
          }}
        >
          {sidebar}
        </Box>
      )}

      <Drawer
        variant="temporary"
        open={mobileOpen}
        onClose={() => setMobileOpen(false)}
        sx={{
          display: { xs: 'block', md: 'none' },
          '& .MuiDrawer-paper': { width: 88, bgcolor: 'background.default' },
        }}
      >
        {sidebar}
      </Drawer>

      <Box sx={{ flexGrow: 1, ml: { md: '88px' }, minWidth: 0, display: 'flex', flexDirection: 'column' }}>
        {/* Header spanning the full width of the content area */}
        <Box 
          sx={{ 
            px: { xs: 2, sm: 4, lg: 6 }, 
            py: 2, 
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            borderBottom: `1px solid ${theme.palette.divider}`,
            bgcolor: alpha(theme.palette.background.paper, 0.4),
            backdropFilter: 'blur(10px)',
            position: 'sticky',
            top: 0,
            zIndex: theme.zIndex.appBar,
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            {isMobile && (
              <IconButton onClick={() => setMobileOpen(true)}>
                <MenuIcon />
              </IconButton>
            )}
            <Typography variant="h5" fontWeight={800} letterSpacing="-0.02em">
              Finder Admin
            </Typography>
          </Box>

          {/* Force actions to the far right side */}
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 3, ml: 'auto' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Tooltip title={mode === 'dark' ? 'Light mode' : 'Dark mode'}>
                <IconButton onClick={toggleMode} sx={{ p: 1.5, bgcolor: alpha(theme.palette.text.primary, 0.03) }}>
                  {mode === 'dark' ? <LightMode fontSize="small" /> : <DarkMode fontSize="small" />}
                </IconButton>
              </Tooltip>
              
              <Tooltip title="Notifications">
                <IconButton sx={{ p: 1.5, bgcolor: alpha(theme.palette.text.primary, 0.03) }}>
                  <Badge color="secondary" variant="dot">
                    <NotificationsIcon fontSize="small" />
                  </Badge>
                </IconButton>
              </Tooltip>
            </Box>

            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <Box textAlign="right" sx={{ display: { xs: 'none', sm: 'block' } }}>
                <Typography variant="body2" fontWeight={800} lineHeight={1.2}>
                  {currentUser?.name || 'Administrator'}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Root Access
                </Typography>
              </Box>
              <Avatar 
                sx={{ 
                  width: 44, 
                  height: 44, 
                  cursor: 'pointer',
                  bgcolor: 'primary.main',
                  fontSize: '1rem',
                  fontWeight: 800,
                  border: `2px solid ${alpha(theme.palette.primary.main, 0.2)}`
                }}
              >
                {(currentUser?.name || 'A').charAt(0).toUpperCase()}
              </Avatar>
            </Box>
          </Box>
        </Box>

        <Box component="main" sx={{ p: { xs: 2, sm: 4, lg: 6 }, flexGrow: 1 }}>
          <Outlet />
        </Box>
      </Box>
    </Box>
  );
}
