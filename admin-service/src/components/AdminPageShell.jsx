import { Box, Button, Paper, Stack, Typography, alpha, useTheme } from '@mui/material';
import ReplayIcon from '@mui/icons-material/Replay';
import MotionPage from './MotionPage';

export default function AdminPageShell({ title, subtitle, children, error, onRetry }) {
  const theme = useTheme();

  return (
    <MotionPage>
      <Box>
        <Box mb={3.5}>
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} justifyContent="space-between" alignItems={{ xs: 'flex-start', sm: 'flex-end' }}>
            <Box>
              <Typography variant="h4" fontWeight={900} color="text.primary">
                {title}
              </Typography>
              {subtitle && (
                <Typography variant="body2" color="text.secondary" mt={0.75} maxWidth={720}>
                  {subtitle}
                </Typography>
              )}
            </Box>
            {onRetry && (
              <Button startIcon={<ReplayIcon />} variant="outlined" onClick={onRetry}>
                Retry
              </Button>
            )}
          </Stack>
        </Box>
        {error}
        <Paper
          elevation={0}
          sx={{
            borderRadius: theme.custom.radius.lg,
            border: `1px solid ${theme.palette.divider}`,
            background: theme.custom.gradients.card,
            overflow: 'hidden',
            boxShadow: theme.custom.shadows.card,
            backdropFilter: 'blur(14px)',
            transition: 'box-shadow 180ms ease, border-color 180ms ease',
            '&:hover': {
              borderColor: alpha(theme.palette.primary.main, 0.22),
            },
          }}
        >
          {children}
        </Paper>
      </Box>
    </MotionPage>
  );
}
