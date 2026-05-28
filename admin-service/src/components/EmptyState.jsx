import { Box, Button, Stack, Typography, alpha, useTheme } from '@mui/material';
import InboxOutlinedIcon from '@mui/icons-material/InboxOutlined';
import ReplayIcon from '@mui/icons-material/Replay';

export default function EmptyState({ message, onRetry }) {
  const theme = useTheme();

  return (
    <Box py={7} px={3} textAlign="center">
      <Stack spacing={2} alignItems="center">
        <Box
          sx={{
            width: 54,
            height: 54,
            borderRadius: '18px',
            display: 'grid',
            placeItems: 'center',
            color: 'primary.main',
            bgcolor: alpha(theme.palette.primary.main, 0.1),
            border: `1px solid ${alpha(theme.palette.primary.main, 0.16)}`,
          }}
        >
          <InboxOutlinedIcon />
        </Box>
        <Typography color="text.primary" fontWeight={800}>Nothing to review</Typography>
        <Typography color="text.secondary" maxWidth={420}>{message}</Typography>
        {onRetry && (
          <Button startIcon={<ReplayIcon />} variant="outlined" onClick={onRetry}>
            Retry
          </Button>
        )}
      </Stack>
    </Box>
  );
}
