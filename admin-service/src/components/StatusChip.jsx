import { Chip, alpha, useTheme } from '@mui/material';

const colorMap = {
  active: 'success',
  approved: 'success',
  verified: 'success',
  visible: 'success',
  resolved: 'success',
  found: 'success',
  pending: 'warning',
  suspended: 'warning',
  hidden: 'warning',
  lost: 'warning',
  banned: 'error',
  rejected: 'error',
  removed: 'error',
  admin: 'primary',
  user: 'info',
};

export default function StatusChip({ value }) {
  const theme = useTheme();
  const colorKey = colorMap[value] || 'default';
  const color = colorKey === 'default'
    ? theme.palette.text.secondary
    : theme.palette[colorKey].main;

  return (
    <Chip
      size="small"
      label={value || '-'}
      sx={{
        height: 26,
        borderRadius: '9px',
        border: `1px solid ${alpha(color, 0.18)}`,
        bgcolor: alpha(color, theme.palette.mode === 'dark' ? 0.16 : 0.1),
        color,
        textTransform: 'capitalize',
        fontWeight: 800,
        '& .MuiChip-label': {
          px: 1.1,
        },
      }}
    />
  );
}
