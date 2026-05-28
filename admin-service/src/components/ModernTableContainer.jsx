import { TableContainer } from '@mui/material';

export default function ModernTableContainer({ children }) {
  return (
    <TableContainer
      sx={{
        maxHeight: 'calc(100vh - 260px)',
        overflowX: 'auto',
        '& .MuiTableHead-root .MuiTableCell-root': {
          position: 'sticky',
          top: 0,
          zIndex: 1,
          backdropFilter: 'blur(12px)',
        },
        '& .MuiTableRow-root': {
          transition: 'background-color 160ms ease, transform 160ms ease',
        },
        '& .MuiTableBody-root .MuiTableRow-root:hover': {
          bgcolor: 'action.hover',
        },
        '& .MuiTableCell-root': {
          whiteSpace: 'nowrap',
        },
      }}
    >
      {children}
    </TableContainer>
  );
}
