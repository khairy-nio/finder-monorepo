import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Alert,
  Box,
  Button,
  Card,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Divider,
  FormControl,
  IconButton,
  InputLabel,
  MenuItem,
  Select,
  Skeleton,
  Stack,
  Tab,
  Tabs,
  TextField,
  Tooltip,
  Typography,
  alpha,
  useTheme,
} from '@mui/material';
import {
  AccountBalanceWallet as WalletIcon,
  CheckCircleOutline as ApproveIcon,
  CancelOutlined as RejectIcon,
  PaidOutlined as PaidIcon,
  BlockOutlined as CancelIcon,
  RefreshRounded as RefreshIcon,
  HourglassEmptyRounded as PendingIcon,
  InfoOutlined as InfoIcon,
} from '@mui/icons-material';
import { motion } from 'framer-motion';
import toast from 'react-hot-toast';
import api from '../../api/axios';
import MotionPage from '../../components/MotionPage';

// ─── Constants ────────────────────────────────────────────────────────────────

const STATUS_CONFIG = {
  pending:   { label: 'Pending',   color: 'warning' },
  approved:  { label: 'Approved',  color: 'info' },
  paid:      { label: 'Paid',      color: 'success' },
  rejected:  { label: 'Rejected',  color: 'error' },
  cancelled: { label: 'Cancelled', color: 'default' },
};

const PROVIDER_LABELS = {
  vodafone_cash:  'Vodafone Cash',
  orange_cash:    'Orange Cash',
  etisalat_cash:  'Etisalat Cash',
  instapay:       'InstaPay',
  other_wallet:   'Other Wallet',
};

// ─── RedemptionCard ───────────────────────────────────────────────────────────

function RedemptionCard({ item, onAction }) {
  const theme = useTheme();
  const cfg = STATUS_CONFIG[item.status] || STATUS_CONFIG.pending;

  return (
    <Card
      component={motion.div}
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      sx={{ p: 3, mb: 2 }}
    >
      <Box display="flex" justifyContent="space-between" alignItems="flex-start" flexWrap="wrap" gap={2}>
        {/* Left — user + amount */}
        <Box display="flex" gap={2} alignItems="flex-start">
          <Box
            sx={{
              width: 48,
              height: 48,
              borderRadius: '14px',
              bgcolor: alpha(theme.palette.primary.main, 0.1),
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
            }}
          >
            <WalletIcon sx={{ color: 'primary.main' }} />
          </Box>
          <Box>
            <Typography fontWeight={800} fontSize={16}>
              {item.cash_amount_egp} EGP
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {item.points_spent} pts via {PROVIDER_LABELS[item.wallet_provider] || item.wallet_provider}
            </Typography>
            {item.user && (
              <Typography variant="caption" color="text.secondary">
                {item.user.name} · {item.user.email}
              </Typography>
            )}
            <Typography variant="caption" color="text.secondary" display="block">
              Wallet: <strong>{item.wallet_number || item.wallet_number_masked}</strong>
            </Typography>
            <Typography variant="caption" color="text.disabled">
              Requested: {item.created_at ? new Date(item.created_at).toLocaleDateString('en-EG') : '—'}
            </Typography>
            {item.paid_at && (
              <Typography variant="caption" color="success.main" display="block">
                Paid: {new Date(item.paid_at).toLocaleDateString('en-EG')}
              </Typography>
            )}
            {item.failure_reason && (
              <Alert severity="error" sx={{ mt: 1, py: 0, fontSize: 12 }}>
                {item.failure_reason}
              </Alert>
            )}
            {item.processed_by && (
              <Typography variant="caption" color="text.disabled" display="block">
                Processed by: {item.processed_by.name}
              </Typography>
            )}
          </Box>
        </Box>

        {/* Right — status + actions */}
        <Stack alignItems="flex-end" spacing={1}>
          <Chip
            label={cfg.label}
            color={cfg.color}
            size="small"
            sx={{ fontWeight: 700, borderRadius: '8px' }}
          />
          <Stack direction="row" spacing={1} flexWrap="wrap" justifyContent="flex-end">
            {item.status === 'pending' && (
              <>
                <Tooltip title="Approve">
                  <IconButton
                    size="small"
                    color="info"
                    onClick={() => onAction('approve', item)}
                    sx={{ bgcolor: alpha(theme.palette.info.main, 0.08) }}
                  >
                    <ApproveIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
                <Tooltip title="Reject & Refund">
                  <IconButton
                    size="small"
                    color="error"
                    onClick={() => onAction('reject', item)}
                    sx={{ bgcolor: alpha(theme.palette.error.main, 0.08) }}
                  >
                    <RejectIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
                <Tooltip title="Cancel & Refund">
                  <IconButton
                    size="small"
                    onClick={() => onAction('cancel', item)}
                    sx={{ bgcolor: alpha(theme.palette.action.hover, 1) }}
                  >
                    <CancelIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              </>
            )}
            {item.status === 'approved' && (
              <Tooltip title="Mark as Paid">
                <Button
                  size="small"
                  variant="contained"
                  color="success"
                  startIcon={<PaidIcon />}
                  onClick={() => onAction('paid', item)}
                  sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 700 }}
                >
                  Mark Paid
                </Button>
              </Tooltip>
            )}
          </Stack>
        </Stack>
      </Box>
    </Card>
  );
}

// ─── Main Page ─────────────────────────────────────────────────────────────────

export default function Redemptions() {
  const theme = useTheme();
  const queryClient = useQueryClient();

  const [statusFilter, setStatusFilter] = useState('pending');
  const [actionDialog, setActionDialog] = useState({ open: false, type: null, item: null });
  const [rejectReason, setRejectReason] = useState('');

  // ── Data Fetching ──────────────────────────────────────────────────────────

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['admin-redemptions', statusFilter],
    queryFn: () =>
      api.get('/admin/redemptions', { params: { status: statusFilter, limit: 100 } })
         .then(r => r.data),
    refetchInterval: 30000,
  });

  const redemptions = data?.redemptions || [];
  const total = data?.pagination?.total || 0;

  // ── Counts per status (for tab badges) ───────────────────────────────────

  const { data: pendingCount } = useQuery({
    queryKey: ['admin-redemptions-pending-count'],
    queryFn: () =>
      api.get('/admin/redemptions', { params: { status: 'pending', limit: 1 } })
         .then(r => r.data?.pagination?.total || 0),
    refetchInterval: 30000,
  });

  // ── Mutations ──────────────────────────────────────────────────────────────

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['admin-redemptions'] });
    queryClient.invalidateQueries({ queryKey: ['admin-redemptions-pending-count'] });
    queryClient.invalidateQueries({ queryKey: ['admin-notifications'] });
    queryClient.invalidateQueries({ queryKey: ['admin-stats'] });
  };

  const actionMutation = useMutation({
    mutationFn: async ({ type, id, reason }) => {
      if (type === 'approve') return api.post(`/admin/redemptions/${id}/approve`);
      if (type === 'paid')    return api.post(`/admin/redemptions/${id}/paid`);
      if (type === 'reject')  return api.post(`/admin/redemptions/${id}/reject`, { reason });
      if (type === 'cancel')  return api.post(`/admin/redemptions/${id}/cancel`);
    },
    onSuccess: (_, { type }) => {
      const msgs = {
        approve: 'Redemption approved',
        paid:    'Marked as paid — funds transferred',
        reject:  'Rejected and points refunded to user',
        cancel:  'Cancelled and points refunded to user',
      };
      toast.success(msgs[type] || 'Action completed');
      invalidate();
      closeDialog();
    },
    onError: (err) => {
      toast.error(err?.response?.data?.message || 'Action failed');
    },
  });

  // ── Dialog helpers ─────────────────────────────────────────────────────────

  const openDialog = (type, item) => {
    setRejectReason('');
    setActionDialog({ open: true, type, item });
  };

  const closeDialog = () => {
    if (actionMutation.isPending) return;
    setActionDialog({ open: false, type: null, item: null });
    setRejectReason('');
  };

  const confirmAction = () => {
    const { type, item } = actionDialog;
    if (type === 'reject' && !rejectReason.trim()) {
      toast.error('Please enter a rejection reason');
      return;
    }
    actionMutation.mutate({ type, id: item.id, reason: rejectReason.trim() });
  };

  // ── Render ─────────────────────────────────────────────────────────────────

  const dialogCfg = {
    approve: { title: 'Approve Redemption',     color: 'info',    desc: 'Confirm you intend to process this payout. The user will be notified.' },
    paid:    { title: 'Mark as Paid',           color: 'success', desc: 'Confirm that the cash has been sent to the user\'s wallet.' },
    reject:  { title: 'Reject & Refund Points', color: 'error',   desc: 'Points will be automatically refunded to the user. Please provide a reason.' },
    cancel:  { title: 'Cancel & Refund Points', color: 'warning', desc: 'This will cancel the request and refund the user\'s points.' },
  };

  return (
    <MotionPage>
      {/* ── Header ── */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4} flexWrap="wrap" gap={2}>
        <Box>
          <Typography variant="h4" fontWeight={900} letterSpacing="-0.04em">
            Cash Redemptions
          </Typography>
          <Typography variant="body1" color="text.secondary" mt={0.5}>
            Manage wallet cash payout requests from users.
          </Typography>
        </Box>
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={refetch}
          disabled={isLoading}
          sx={{ borderRadius: '12px', textTransform: 'none', fontWeight: 600 }}
        >
          Refresh
        </Button>
      </Box>

      {/* ── Stats strip ── */}
      <Box display="flex" gap={2} mb={4} flexWrap="wrap">
        {Object.entries(STATUS_CONFIG).map(([key, cfg]) => (
          <Card
            key={key}
            component={motion.div}
            whileHover={{ y: -2 }}
            onClick={() => setStatusFilter(key)}
            sx={{
              px: 3,
              py: 1.5,
              cursor: 'pointer',
              border: statusFilter === key
                ? `2px solid ${theme.palette[cfg.color]?.main || theme.palette.grey[400]}`
                : '2px solid transparent',
              flex: '1 1 120px',
            }}
          >
            <Typography variant="caption" color="text.secondary" fontWeight={600}>
              {cfg.label}
            </Typography>
          </Card>
        ))}
      </Box>

      {/* ── Status Filter Tabs ── */}
      <Card sx={{ mb: 3 }}>
        <Tabs
          value={statusFilter}
          onChange={(_, v) => setStatusFilter(v)}
          variant="scrollable"
          scrollButtons="auto"
          sx={{ borderBottom: 1, borderColor: 'divider', px: 2 }}
        >
          <Tab
            value="pending"
            label={
              <Box display="flex" gap={1} alignItems="center">
                Pending
                {pendingCount > 0 && (
                  <Chip label={pendingCount} size="small" color="warning" sx={{ height: 18, fontSize: 10 }} />
                )}
              </Box>
            }
          />
          <Tab value="approved"  label="Approved" />
          <Tab value="paid"      label="Paid" />
          <Tab value="rejected"  label="Rejected" />
          <Tab value="cancelled" label="Cancelled" />
          <Tab value="all"       label="All" />
        </Tabs>
      </Card>

      {/* ── List ── */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          Failed to load redemptions. Please try again.
        </Alert>
      )}

      {isLoading ? (
        <Stack spacing={2}>
          {[1, 2, 3].map(i => <Skeleton key={i} variant="rounded" height={120} sx={{ borderRadius: 3 }} />)}
        </Stack>
      ) : redemptions.length === 0 ? (
        <Card sx={{ p: 8, textAlign: 'center' }}>
          <PendingIcon sx={{ fontSize: 64, color: 'text.disabled', mb: 2 }} />
          <Typography color="text.secondary" fontWeight={600}>
            No {statusFilter === 'all' ? '' : statusFilter} redemption requests
          </Typography>
        </Card>
      ) : (
        <Box>
          <Typography variant="body2" color="text.secondary" mb={2}>
            Showing {redemptions.length} of {total} results
          </Typography>
          {redemptions.map(item => (
            <RedemptionCard key={item.id} item={item} onAction={openDialog} />
          ))}
        </Box>
      )}

      {/* ── Action Confirmation Dialog ── */}
      <Dialog
        open={actionDialog.open}
        onClose={closeDialog}
        maxWidth="xs"
        fullWidth
        PaperProps={{ sx: { borderRadius: '20px', p: 1 } }}
      >
        {actionDialog.type && (
          <>
            <DialogTitle sx={{ fontWeight: 800 }}>
              {dialogCfg[actionDialog.type]?.title}
            </DialogTitle>
            <DialogContent>
              <DialogContentText mb={2}>
                {dialogCfg[actionDialog.type]?.desc}
              </DialogContentText>
              {actionDialog.item && (
                <Box
                  sx={{
                    p: 2,
                    borderRadius: 2,
                    bgcolor: alpha(theme.palette.primary.main, 0.06),
                    mb: 2,
                  }}
                >
                  <Typography variant="body2" fontWeight={700}>
                    {actionDialog.item.cash_amount_egp} EGP → {PROVIDER_LABELS[actionDialog.item.wallet_provider] || actionDialog.item.wallet_provider}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {actionDialog.item.wallet_number || actionDialog.item.wallet_number_masked}
                  </Typography>
                  {actionDialog.item.user && (
                    <Typography variant="caption" color="text.secondary" display="block">
                      User: {actionDialog.item.user.name}
                    </Typography>
                  )}
                </Box>
              )}
              {actionDialog.type === 'reject' && (
                <TextField
                  fullWidth
                  multiline
                  rows={3}
                  label="Rejection Reason"
                  placeholder="e.g. Invalid wallet number provided"
                  value={rejectReason}
                  onChange={e => setRejectReason(e.target.value)}
                  required
                  sx={{ '& .MuiOutlinedInput-root': { borderRadius: '12px' } }}
                />
              )}
            </DialogContent>
            <DialogActions sx={{ px: 3, pb: 3, gap: 1 }}>
              <Button
                onClick={closeDialog}
                disabled={actionMutation.isPending}
                sx={{ borderRadius: '10px', textTransform: 'none' }}
              >
                Cancel
              </Button>
              <Button
                variant="contained"
                color={dialogCfg[actionDialog.type]?.color || 'primary'}
                onClick={confirmAction}
                disabled={actionMutation.isPending}
                startIcon={actionMutation.isPending ? <CircularProgress size={18} color="inherit" /> : null}
                sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 700, px: 3 }}
              >
                {actionMutation.isPending ? 'Processing...' : 'Confirm'}
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </MotionPage>
  );
}
