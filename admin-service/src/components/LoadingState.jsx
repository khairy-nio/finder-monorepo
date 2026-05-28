import { Box, Skeleton, Stack } from '@mui/material';

export default function LoadingState({ rows = 6 }) {
  return (
    <Box p={2}>
      <Stack spacing={1.25}>
        {Array.from({ length: rows }).map((_, index) => (
          <Skeleton
            key={index}
            variant="rounded"
            height={54}
            animation="wave"
            sx={{ borderRadius: 2 }}
          />
        ))}
      </Stack>
    </Box>
  );
}
