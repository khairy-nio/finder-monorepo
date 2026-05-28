import { useEffect, useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Alert,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  LinearProgress,
  MenuItem,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Tooltip,
  Box,
  Typography,
  alpha,
  useTheme,
  Avatar,
  Card,
  InputBase,
  Grid,
  Divider,
} from '@mui/material';
import {
  EditRounded as EditIcon,
  FilterListRounded as FilterIcon,
  SearchRounded as SearchIcon,
  FileDownloadRounded as ExportIcon,
  VisibilityRounded as ViewIcon,
  InfoRounded as InfoIcon,
  LocationOnRounded as LocationIcon,
  ShieldRounded as ShieldIcon,
  HistoryRounded as HistoryIcon,
  EventNoteRounded as ActivityIcon,
  EmojiEventsRounded as PointsIcon,
} from '@mui/icons-material';
import api from '../../api/axios';
import MotionPage from '../../components/MotionPage';

const initialForm = {
  name: '',
  email: '',
  role: 'user',
  status: 'active',
  phone_number: '',
  verification_status: 'not_submitted',
  trust_score: 0,
  moderation_reason: '',
};

function StatusPill({ value }) {
  const theme = useTheme();
  const getColors = (val) => {
    switch (val?.toLowerCase()) {
      case 'active': case 'approved': case 'admin': return theme.palette.success;
      case 'suspended': case 'pending': return theme.palette.warning;
      case 'banned': case 'rejected': return theme.palette.error;
      default: return theme.palette.text;
    }
  };
  const colors = getColors(value);
  return (
    <Box
      sx={{
        px: 1.5,
        py: 0.5,
        borderRadius: '10px',
        display: 'inline-flex',
        alignItems: 'center',
        fontSize: '0.75rem',
        fontWeight: 800,
        textTransform: 'uppercase',
        letterSpacing: '0.05em',
        bgcolor: alpha(colors.main || colors.secondary, 0.1),
        color: colors.main || colors.secondary,
        border: `1px solid ${alpha(colors.main || colors.secondary, 0.2)}`,
      }}
    >
      {value}
    </Box>
  );
}

function DetailItem({ icon: Icon, label, value, color = 'text.secondary' }) {
  return (
    <Stack direction="row" spacing={2} alignItems="flex-start" sx={{ mb: 2 }}>
      <Box sx={{ p: 1, borderRadius: '10px', bgcolor: alpha(color === 'text.secondary' ? '#000' : color, 0.05) }}>
        <Icon sx={{ fontSize: 18, color: color === 'text.secondary' ? 'text.secondary' : color }} />
      </Box>
      <Box>
        <Typography variant="caption" fontWeight={700} color="text.secondary" sx={{ textTransform: 'uppercase', letterSpacing: '0.05em' }}>
          {label}
        </Typography>
        <Typography variant="body2" fontWeight={600} color="text.primary">
          {value || 'N/A'}
        </Typography>
      </Box>
    </Stack>
  );
}

export default function Users() {
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [selectedUser, setSelectedUser] = useState(null);
  const [viewingUser, setViewingUser] = useState(null);
  const [form, setForm] = useState(initialForm);
  const [pointsDelta, setPointsDelta] = useState('');
  const [pointsReason, setPointsReason] = useState('');
  const [pointsSubmitting, setPointsSubmitting] = useState(false);
  const theme = useTheme();
  const queryClient = useQueryClient();

  const { data: usersData, isLoading, error: fetchError } = useQuery({
    queryKey: ['users'],
    queryFn: async () => {
      const response = await api.get('/admin/users', { params: { limit: 100, offset: 0 } });
      return response.data?.users || [];
    }
  });

  const users = usersData || [];

  const updateMutation = useMutation({
    mutationFn: async ({ userId, data }) => {
      // If status changed to suspended or banned, ensure reason is provided
      if ((data.status === 'suspended' || data.status === 'banned') && !data.moderation_reason) {
        throw new Error(`Reason is required when setting status to ${data.status}`);
      }
      return await api.put(`/admin/users/${userId}`, data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      queryClient.invalidateQueries({ queryKey: ['admin-stats'] });
      setSelectedUser(null);
      setViewingUser(null);
    }
  });

  const filteredUsers = useMemo(() => {
    return users.filter(user => {
      const matchesSearch = user.name?.toLowerCase().includes(searchQuery.toLowerCase()) || 
                           user.email?.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesRole = roleFilter === 'all' || user.role === roleFilter;
      return matchesSearch && matchesRole;
    });
  }, [users, searchQuery, roleFilter]);

  const openEditor = (user) => {
    setSelectedUser(user);
    setPointsDelta('');
    setPointsReason('');
    setForm({
      name: user.name || '',
      email: user.email || '',
      role: user.role || 'user',
      status: user.status || 'active',
      phone_number: user.phone_number || '',
      verification_status: user.verification_status || 'not_submitted',
      trust_score: user.trust_score || 0,
      moderation_reason: user.moderation_reason || '',
    });
  };

  const updateForm = (field, value) => {
    setForm((current) => ({ ...current, [field]: value }));
  };

  const saveUser = () => {
    updateMutation.mutate({ userId: selectedUser.id, data: form });
  };

  const handleAdjustPoints = async () => {
    if (!pointsDelta || isNaN(parseInt(pointsDelta))) {
      alert('Please enter a valid points number');
      return;
    }
    if (!pointsReason.trim()) {
      alert('Please enter a reason for point adjustment');
      return;
    }
    setPointsSubmitting(true);
    try {
      await api.post(`/admin/users/${selectedUser.id}/points/adjust`, {
        points: parseInt(pointsDelta),
        reason: pointsReason.trim()
      });
      // Update local state in the form
      setSelectedUser(prev => ({
        ...prev,
        recovery_points: (prev?.recovery_points || 0) + parseInt(pointsDelta)
      }));
      setPointsDelta('');
      setPointsReason('');
      queryClient.invalidateQueries({ queryKey: ['users'] });
      queryClient.invalidateQueries({ queryKey: ['admin-stats'] });
      alert('Recovery points adjusted successfully!');
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to adjust points');
    } finally {
      setPointsSubmitting(false);
    }
  };

  const error = fetchError?.response?.data?.message || fetchError?.message || updateMutation.error?.response?.data?.message || updateMutation.error?.message;
  const saving = updateMutation.isPending;

  return (
    <MotionPage>
      <Stack 
        direction={{ xs: 'column', sm: 'row' }} 
        justifyContent="space-between" 
        alignItems="flex-start" 
        spacing={2} 
        sx={{ mb: '6px' }}
      >
        <Box>
          <Typography variant="h2" fontWeight={900} letterSpacing="-0.06em" mb={1}>
            Users
          </Typography>
          <Typography variant="h6" color="text.secondary" fontWeight={500}>
            Manage user accounts, trust scores, and platform verification.
          </Typography>
        </Box>
      </Stack>

      {error && <Alert severity="error" sx={{ mb: 4, borderRadius: 3 }}>{error}</Alert>}

      <Card sx={{ overflow: 'hidden', p: 0 }}>
        <Box sx={{ p: 3, borderBottom: `1px solid ${theme.palette.divider}`, display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
          <Box sx={{ 
            flexGrow: 1, 
            minWidth: 280,
            px: 2, 
            py: 1, 
            borderRadius: '16px', 
            bgcolor: alpha(theme.palette.text.primary, 0.03), 
            display: 'flex', 
            alignItems: 'center', 
            gap: 1.5,
            border: `1px solid ${alpha(theme.palette.text.primary, 0.05)}`
          }}>
            <SearchIcon fontSize="small" color="disabled" />
            <InputBase 
              placeholder="Search by name or email..." 
              fullWidth 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              sx={{ fontSize: '0.9rem', fontWeight: 600 }}
            />
          </Box>
          
          <TextField
            select
            size="small"
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            sx={{ 
              minWidth: 140,
              '& .MuiOutlinedInput-root': { borderRadius: '14px', bgcolor: alpha(theme.palette.text.primary, 0.03) }
            }}
          >
            <MenuItem value="all">All Roles</MenuItem>
            <MenuItem value="user">Users</MenuItem>
            <MenuItem value="admin">Admins</MenuItem>
          </TextField>

          <IconButton sx={{ bgcolor: alpha(theme.palette.text.primary, 0.03), borderRadius: '12px' }}>
            <FilterIcon fontSize="small" />
          </IconButton>
          
          <Typography variant="caption" fontWeight={700} color="text.secondary" sx={{ ml: 'auto' }}>
            Showing {filteredUsers.length} of {users.length} Users
          </Typography>
        </Box>

        <Box sx={{ overflowX: 'auto' }}>
          <Table>
            <TableHead>
              <TableRow sx={{ bgcolor: alpha(theme.palette.text.primary, 0.01) }}>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Identity</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Account Role</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Trust Score</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Recovery Points</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Verification</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Status</TableCell>
                <TableCell align="right" sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading ? (
                [...Array(5)].map((_, i) => (
                  <TableRow key={i}>
                    <TableCell colSpan={7}><LinearProgress sx={{ height: 2, opacity: 0.1 }} /></TableCell>
                  </TableRow>
                ))
              ) : filteredUsers.map((user) => (
                <TableRow key={user.id} sx={{ '&:hover': { bgcolor: alpha(theme.palette.primary.main, 0.02) } }}>
                  <TableCell>
                    <Stack direction="row" spacing={2} alignItems="center">
                      <Avatar src={user.profile_image_url} sx={{ width: 36, height: 36, bgcolor: alpha(theme.palette.primary.main, 0.1), color: 'primary.main', fontWeight: 800, fontSize: '0.9rem' }}>
                        {user.name?.charAt(0)}
                      </Avatar>
                      <Box>
                        <Typography variant="body2" fontWeight={700}>{user.name}</Typography>
                        <Typography variant="caption" color="text.secondary">{user.email}</Typography>
                      </Box>
                    </Stack>
                  </TableCell>
                  <TableCell><StatusPill value={user.role} /></TableCell>
                  <TableCell sx={{ minWidth: 155 }}>
                    <Box display="flex" flexDirection="column" gap={0.5}>
                      <Box display="flex" alignItems="center" gap={1.5}>
                        <Typography variant="caption" fontWeight={800}>{user.trust_score || 0}%</Typography>
                        <LinearProgress
                            variant="determinate"
                            value={Math.min(100, Number(user.trust_score || 0))}
                            color={user.trust_score > 80 ? "success" : user.trust_score > 60 ? "primary" : user.trust_score > 30 ? "warning" : "error"}
                            sx={{ flexGrow: 1, height: 6, borderRadius: 3 }}
                        />
                      </Box>
                      <Typography variant="caption" fontSize="0.65rem" fontWeight={900} sx={{
                        color: user.trust_score > 95 ? '#D4AF37' : user.trust_score > 80 ? 'success.main' : user.trust_score > 60 ? 'primary.main' : user.trust_score > 30 ? 'warning.main' : 'error.main',
                        textTransform: 'uppercase',
                        letterSpacing: '0.05em'
                      }}>
                        {user.trust_score > 95 ? 'Elite Trusted' : user.trust_score > 80 ? 'Highly Trusted' : user.trust_score > 60 ? 'Trusted User' : user.trust_score > 30 ? 'Basic Verified' : 'Low Trust'}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box display="flex" alignItems="center" gap={0.5}>
                      <Typography variant="body2" fontWeight={800} color="warning.main">
                        ★ {user.recovery_points ?? 0}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">Pts</Typography>
                    </Box>
                  </TableCell>
                  <TableCell><StatusPill value={user.verification_status || (user.verified ? 'approved' : 'not_submitted')} /></TableCell>
                  <TableCell><StatusPill value={user.status || 'active'} /></TableCell>
                  <TableCell align="right">
                    <Stack direction="row" spacing={1} justifyContent="flex-end">
                      <Tooltip title="View Full Details">
                        <IconButton onClick={() => setViewingUser(user)} sx={{ color: 'text.secondary', '&:hover': { color: 'primary.main', bgcolor: alpha(theme.palette.primary.main, 0.1) } }}>
                          <ViewIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Quick Edit">
                        <IconButton onClick={() => openEditor(user)} sx={{ color: 'text.secondary', '&:hover': { color: 'primary.main', bgcolor: alpha(theme.palette.primary.main, 0.1) } }}>
                          <EditIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </Stack>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </Box>
      </Card>

      {/* QUICK EDIT DIALOG */}
      <Dialog 
        open={Boolean(selectedUser)} 
        onClose={() => setSelectedUser(null)} 
        fullWidth 
        maxWidth="sm"
        PaperProps={{
          sx: {
            borderRadius: '24px',
            bgcolor: alpha(theme.palette.background.paper, 0.8),
            backdropFilter: 'blur(20px)',
            border: `1px solid ${theme.palette.divider}`,
          }
        }}
      >
        <DialogTitle sx={{ fontWeight: 800, fontSize: '1.5rem', letterSpacing: '-0.02em' }}>
          Edit User Profile
        </DialogTitle>
        <DialogContent>
          <Stack spacing={3} mt={2}>
            <TextField label="Full Name" value={form.name} onChange={(event) => updateForm('name', event.target.value)} fullWidth />
            <TextField label="Email Address" value={form.email} onChange={(event) => updateForm('email', event.target.value)} fullWidth />
            <Stack direction="row" spacing={2}>
              <TextField select label="Role" value={form.role} onChange={(event) => updateForm('role', event.target.value)} fullWidth>
                <MenuItem value="user">User</MenuItem>
                <MenuItem value="admin">Admin</MenuItem>
              </TextField>
              <TextField select label="Account Status" value={form.status} onChange={(event) => updateForm('status', event.target.value)} fullWidth>
                <MenuItem value="active">Active</MenuItem>
                <MenuItem value="suspended">Suspended</MenuItem>
                <MenuItem value="banned">Banned</MenuItem>
              </TextField>
            </Stack>
            {(form.status === 'suspended' || form.status === 'banned') && (
              <TextField 
                label="Moderation Reason" 
                placeholder="Required for suspension/ban..."
                value={form.moderation_reason} 
                onChange={(event) => updateForm('moderation_reason', event.target.value)} 
                fullWidth
                multiline
                rows={2}
                error={!form.moderation_reason}
                helperText={!form.moderation_reason ? 'Reason is required for punitive actions' : ''}
              />
            )}
            <Stack direction="row" spacing={2}>
              <TextField label="Phone" value={form.phone_number} onChange={(event) => updateForm('phone_number', event.target.value)} fullWidth />
              <TextField label="Trust Score" type="number" value={form.trust_score} onChange={(event) => updateForm('trust_score', Number(event.target.value))} fullWidth />
            </Stack>
            <TextField select label="Verification Status" value={form.verification_status} onChange={(event) => updateForm('verification_status', event.target.value)} fullWidth>
              <MenuItem value="not_submitted">Not Submitted</MenuItem>
              <MenuItem value="pending">Pending Review</MenuItem>
              <MenuItem value="approved">Approved</MenuItem>
              <MenuItem value="rejected">Rejected</MenuItem>
            </TextField>

            <Divider sx={{ my: 1 }} />
            
            <Typography variant="subtitle2" fontWeight={800} color="warning.main" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <PointsIcon fontSize="small" /> Adjust Recovery Points (Community System)
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Current Balance: <strong>{selectedUser?.recovery_points ?? 0} Pts</strong>
            </Typography>
            <Stack direction="row" spacing={2} alignItems="center">
              <TextField 
                label="Points Delta" 
                placeholder="e.g. +10 or -5" 
                value={pointsDelta} 
                onChange={(e) => setPointsDelta(e.target.value)} 
                sx={{ width: '40%' }}
              />
              <TextField 
                label="Adjustment Reason" 
                placeholder="e.g. Manual reward for returned keys" 
                value={pointsReason} 
                onChange={(e) => setPointsReason(e.target.value)} 
                fullWidth
              />
            </Stack>
            <Button 
              variant="outlined" 
              color="warning" 
              onClick={handleAdjustPoints} 
              disabled={pointsSubmitting}
              sx={{ borderRadius: '10px', fontWeight: 700 }}
            >
              {pointsSubmitting ? 'Adjusting...' : 'Submit Points Adjustment'}
            </Button>
          </Stack>
        </DialogContent>
        <DialogActions sx={{ px: 4, pb: 4, pt: 2 }}>
          <Button onClick={() => setSelectedUser(null)} sx={{ color: 'text.secondary' }}>Cancel</Button>
          <Button onClick={saveUser} variant="contained" disabled={saving} sx={{ borderRadius: '12px', px: 4 }}>
            {saving ? 'Updating...' : 'Save Changes'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* FULL USER DETAILS MODAL */}
      <Dialog
        open={Boolean(viewingUser)}
        onClose={() => setViewingUser(null)}
        fullWidth
        maxWidth="md"
        PaperProps={{
          sx: {
            borderRadius: '28px',
            bgcolor: alpha(theme.palette.background.paper, 0.9),
            backdropFilter: 'blur(30px)',
            border: `1px solid ${theme.palette.divider}`,
            boxShadow: theme.shadows[24],
          }
        }}
      >
        <DialogTitle sx={{ p: 4, pb: 0 }}>
          <Stack direction="row" spacing={3} alignItems="center">
            <Avatar 
              src={viewingUser?.profile_image_url} 
              sx={{ width: 80, height: 80, fontSize: '2rem', fontWeight: 900, bgcolor: 'primary.main' }}
            >
              {viewingUser?.name?.charAt(0)}
            </Avatar>
            <Box>
              <Typography variant="h4" fontWeight={900} letterSpacing="-0.04em">
                {viewingUser?.name}
              </Typography>
              <Stack direction="row" spacing={1} alignItems="center" mt={0.5}>
                <StatusPill value={viewingUser?.role} />
                <StatusPill value={viewingUser?.status} />
                <StatusPill value={viewingUser?.verification_status} />
              </Stack>
            </Box>
          </Stack>
        </DialogTitle>

        <DialogContent sx={{ p: 4 }}>
          <Grid container spacing={4} mt={1}>
            {/* ACCOUNT INFO */}
            <Grid item xs={12} md={4}>
              <Typography variant="subtitle2" fontWeight={800} color="primary" mb={2} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <InfoIcon fontSize="small" /> Account Details
              </Typography>
              <DetailItem icon={InfoIcon} label="Email" value={viewingUser?.email} />
              <DetailItem icon={InfoIcon} label="Phone" value={viewingUser?.phone_number} />
              <DetailItem icon={ShieldIcon} label="Trust Score" value={`${viewingUser?.trust_score}%`} color={theme.palette.primary.main} />
              <DetailItem icon={PointsIcon} label="Recovery Points" value={`${viewingUser?.recovery_points ?? 0} Pts`} color={theme.palette.warning.main} />
              <DetailItem icon={ActivityIcon} label="Join Date" value={viewingUser?.created_at ? new Date(viewingUser.created_at).toLocaleDateString() : 'N/A'} />
            </Grid>

            {/* LOCATION INFO */}
            <Grid item xs={12} md={4}>
              <Typography variant="subtitle2" fontWeight={800} color="primary" mb={2} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <LocationIcon fontSize="small" /> Location Info
              </Typography>
              <DetailItem icon={LocationIcon} label="Country" value={viewingUser?.country} />
              <DetailItem icon={LocationIcon} label="State/City" value={`${viewingUser?.state || ''}, ${viewingUser?.city || ''}`} />
              <DetailItem icon={LocationIcon} label="Area" value={viewingUser?.area} />
              <DetailItem icon={LocationIcon} label="Verification Region" value={viewingUser?.verification_location} />
            </Grid>

            {/* MODERATION INFO */}
            <Grid item xs={12} md={4}>
              <Typography variant="subtitle2" fontWeight={800} color="primary" mb={2} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <ShieldIcon fontSize="small" /> Moderation
              </Typography>
              <DetailItem 
                icon={ShieldIcon} 
                label="Reports Count" 
                value={viewingUser?.reports_count || 0} 
                color={viewingUser?.reports_count > 0 ? 'error.main' : 'text.secondary'} 
              />
              <DetailItem icon={HistoryIcon} label="Moderated At" value={viewingUser?.moderated_at ? new Date(viewingUser.moderated_at).toLocaleString() : 'Never'} />
              <Box sx={{ p: 2, bgcolor: alpha(theme.palette.error.main, 0.05), borderRadius: '12px', border: `1px dashed ${alpha(theme.palette.error.main, 0.2)}` }}>
                <Typography variant="caption" fontWeight={800} color="error.main" sx={{ display: 'block', mb: 0.5, textTransform: 'uppercase' }}>
                  Current Moderation Reason
                </Typography>
                <Typography variant="body2" fontWeight={600}>
                  {viewingUser?.moderation_reason || 'No active moderation reason.'}
                </Typography>
              </Box>
            </Grid>

            {/* IMAGES */}
            <Grid item xs={12}>
              <Divider sx={{ my: 2 }} />
              <Typography variant="subtitle2" fontWeight={800} color="primary" mb={2}>
                Verification Documents
              </Typography>
              <Stack direction="row" spacing={3}>
                <Box>
                  <Typography variant="caption" fontWeight={700} color="text.secondary" display="block" mb={1}>Selfie Image</Typography>
                  <Box 
                    component="img" 
                    src={viewingUser?.selfie_image_url} 
                    sx={{ width: 140, height: 180, borderRadius: '16px', objectFit: 'cover', bgcolor: 'grey.100', border: `1px solid ${theme.palette.divider}` }}
                    onError={(e) => { e.target.src = 'https://via.placeholder.com/140x180?text=No+Selfie'; }}
                  />
                </Box>
                <Box>
                  <Typography variant="caption" fontWeight={700} color="text.secondary" display="block" mb={1}>ID Document</Typography>
                  <Box 
                    component="img" 
                    src={viewingUser?.id_image_url} 
                    sx={{ width: 240, height: 180, borderRadius: '16px', objectFit: 'cover', bgcolor: 'grey.100', border: `1px solid ${theme.palette.divider}` }}
                    onError={(e) => { e.target.src = 'https://via.placeholder.com/240x180?text=No+ID+Image'; }}
                  />
                </Box>
              </Stack>
            </Grid>
          </Grid>
        </DialogContent>

        <DialogActions sx={{ p: 4, pt: 0 }}>
          <Button onClick={() => setViewingUser(null)} sx={{ color: 'text.secondary', fontWeight: 700 }}>Close View</Button>
          <Box sx={{ flexGrow: 1 }} />
          <Button 
            variant="contained" 
            color="primary" 
            startIcon={<EditIcon />}
            onClick={() => {
              const u = viewingUser;
              setViewingUser(null);
              setTimeout(() => openEditor(u), 100);
            }}
            sx={{ borderRadius: '12px', px: 3 }}
          >
            Edit User
          </Button>
        </DialogActions>
      </Dialog>
    </MotionPage>
  );
}
