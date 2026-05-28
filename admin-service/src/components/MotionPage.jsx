import { motion, useReducedMotion } from 'framer-motion';
import { Box } from '@mui/material';

export default function MotionPage({ children }) {
  const reduceMotion = useReducedMotion();

  return (
    <Box
      component={motion.div}
      initial={reduceMotion ? false : { opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={reduceMotion ? undefined : { opacity: 0, y: 8 }}
      transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </Box>
  );
}
