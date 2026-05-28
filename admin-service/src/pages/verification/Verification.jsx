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
  Link,
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
  LinearProgress,
  InputBase,
  Grid,
  Divider,
  Chip,
  MenuItem,
} from '@mui/material';
import {
  RateReviewRounded as ReviewIcon,
  VerifiedUserRounded as VerifiedIcon,
  OpenInNewRounded as OpenIcon,
  ContactPageRounded as IDIcon,
  SearchRounded as SearchIcon,
  FileDownloadRounded as ExportIcon,
  LocationOnRounded as LocationIcon,
  StarRounded as StarIcon,
  InfoRounded as InfoIcon,
  CalendarTodayRounded as CalendarIcon,
  ReportProblemRounded as ReportIcon,
  PhoneRounded as PhoneIcon,
  PersonOutlineRounded as UserIcon,
} from '@mui/icons-material';
import api from '../../api/axios';
import MotionPage from '../../components/MotionPage';

function StatusPill({ value }) {
  const theme = useTheme();
  const getColors = (val) => {
    switch (val?.toLowerCase()) {
      case 'approved': case 'active': return theme.palette.success;
      case 'pending': return theme.palette.warning;
      case 'rejected': case 'banned': return theme.palette.error;
      default: return theme.palette.text;
    }
  };
  const colors = getColors(value);
  return (
    <Box
      sx={{
        px: 1,
        py: 0.25,
        borderRadius: '8px',
        display: 'inline-flex',
        alignItems: 'center',
        fontSize: '0.65rem',
        fontWeight: 800,
        textTransform: 'uppercase',
        letterSpacing: '0.05em',
        bgcolor: alpha(colors.main || colors.secondary, 0.1),
        color: colors.main || colors.secondary,
        border: `1px solid ${alpha(colors.main || colors.secondary, 0.2)}`,
        mt: 0.5
      }}
    >
      {value}
    </Box>
  );
}

export default function Verification() {
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('pending');
  const [selectedUser, setSelectedUser] = useState(null);
  const [notes, setNotes] = useState('');
  const theme = useTheme();
  const queryClient = useQueryClient();

  const { data: verificationsData, isLoading, error: fetchError } = useQuery({
    queryKey: ['verifications', statusFilter],
    queryFn: async () => {
      const response = await api.get('/admin/verifications', { 
        params: { 
          limit: 100, 
          offset: 0,
          status: statusFilter
        } 
      });
      return response.data?.verifications || [];
    }
  });

  const verifications = verificationsData || [];

  const reviewMutation = useMutation({
    mutationFn: async ({ userId, action, notes }) => {
      return await api.post(`/admin/verifications/${userId}/${action}`, { notes });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['verifications'] });
      queryClient.invalidateQueries({ queryKey: ['admin-stats'] });
      setSelectedUser(null);
    }
  });

  const filteredVerifications = useMemo(() => {
    return verifications.filter(user => {
      return user.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
             user.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
             user.national_id?.includes(searchQuery);
    });
  }, [verifications, searchQuery]);

  const handleExport = () => {
    const csvContent = "data:text/csv;charset=utf-8,"
      + ["Name,Email,National ID,Phone,Location"].join(",") + "\n"
      + filteredVerifications.map(u => `"${u.name}","${u.email}","${u.national_id || 'N/A'}","${u.phone_number || 'N/A'}","${u.verification_location || 'N/A'}"`).join("\n");

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", "finder_verifications_export.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const openReview = (user) => {
    // Parse location if it's a JSON string
    let parsedLocation = null;
    if (user.verification_location) {
      try {
        parsedLocation = JSON.parse(user.verification_location);
      } catch (e) {
        parsedLocation = { city: user.verification_location, country: 'Manual', source: 'legacy' };
      }
    }
    setSelectedUser({ ...user, parsedLocation });
    setNotes(user.verification_notes || '');
  };

  const reviewVerification = (userId, action) => {
    reviewMutation.mutate({ userId, action, notes });
  };

  const error = fetchError?.response?.data?.message || fetchError?.message || reviewMutation.error?.response?.data?.message || reviewMutation.error?.message;
  const saving = reviewMutation.isPending;

  return (
    <MotionPage>
      <Box mb={6} position="relative">
        <Typography variant="h2" fontWeight={900} letterSpacing="-0.06em" mb={1}>
          Trust & Safety
        </Typography>
        <Typography variant="h6" color="text.secondary" fontWeight={500}>
          Review submitted identity documents and selfies to verify platform users.
        </Typography>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 4, borderRadius: 3 }}>{error}</Alert>}

      <Card sx={{ overflow: 'hidden', p: 0, borderRadius: 4, boxShadow: '0 10px 40px rgba(0,0,0,0.04)' }}>
        <Box sx={{ p: 3, borderBottom: `1px solid ${theme.palette.divider}`, display: 'flex', gap: 2, alignItems: 'center', flexWrap: 'wrap' }}>
          <Box sx={{ 
            flexGrow: 1, 
            minWidth: 300,
            px: 2, 
            py: 1.5, 
            borderRadius: '16px', 
            bgcolor: alpha(theme.palette.text.primary, 0.03), 
            display: 'flex', 
            alignItems: 'center', 
            gap: 1.5,
            border: `1px solid ${alpha(theme.palette.text.primary, 0.05)}`
          }}>
            <SearchIcon fontSize="small" color="disabled" />
            <InputBase 
              placeholder="Search by name, email or ID..." 
              fullWidth 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              sx={{ fontSize: '0.9rem', fontWeight: 600 }}
            />
          </Box>
          
          <TextField
            select
            size="small"
            label="Filter Status"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            sx={{ minWidth: 160, '& .MuiOutlinedInput-root': { borderRadius: '14px' } }}
          >
            <MenuItem value="all">All Requests</MenuItem>
            <MenuItem value="pending">Pending Review</MenuItem>
            <MenuItem value="approved">Approved</MenuItem>
            <MenuItem value="rejected">Rejected</MenuItem>
          </TextField>

          <Stack direction="row" spacing={2} alignItems="center" sx={{ ml: 'auto' }}>
            <Button 
              startIcon={<ExportIcon />} 
              onClick={handleExport}
              sx={{ borderRadius: '12px', fontWeight: 700, px: 2 }}
            >
              Export CSV
            </Button>
            <Divider orientation="vertical" flexItem />
            <Typography variant="caption" fontWeight={700} color="text.secondary">
              {filteredVerifications.length} {statusFilter} Results
            </Typography>
          </Stack>
        </Box>

        <Box sx={{ overflowX: 'auto' }}>
          <Table>
            <TableHead>
              <TableRow sx={{ bgcolor: alpha(theme.palette.text.primary, 0.01) }}>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Applicant</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Identity Details</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Location & Trust</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>History</TableCell>
                <TableCell align="right" sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading ? (
                [...Array(5)].map((_, i) => (
                  <TableRow key={i}>
                    <TableCell colSpan={5}><LinearProgress sx={{ height: 2, opacity: 0.1 }} /></TableCell>
                  </TableRow>
                ))
              ) : filteredVerifications.map((user) => {
                const loc = user.verification_location ? (() => {
                  try { return JSON.parse(user.verification_location); } catch (e) { return null; }
                })() : null;

                return (
                  <TableRow 
                    key={user.id} 
                    onClick={() => openReview(user)}
                    sx={{ 
                      cursor: 'pointer',
                      '&:hover': { bgcolor: alpha(theme.palette.primary.main, 0.02) } 
                    }}
                  >
                    <TableCell>
                      <Stack direction="row" spacing={2} alignItems="center">
                        <Avatar 
                          src={user.profile_image_url || user.selfie_image_url}
                          sx={{ 
                            width: 44, 
                            height: 44, 
                            bgcolor: alpha(theme.palette.primary.main, 0.1), 
                            color: 'primary.main', 
                            fontWeight: 800, 
                            fontSize: '1rem',
                            border: `2px solid ${alpha(theme.palette.primary.main, 0.2)}`
                          }}
                        >
                          {user.name?.charAt(0)}
                        </Avatar>
                        <Box>
                          <Typography variant="body2" fontWeight={700}>{user.name}</Typography>
                          <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>{user.email}</Typography>
                        </Box>
                      </Stack>
                    </TableCell>
                    <TableCell>
                      <Stack spacing={0.5}>
                        <Typography variant="caption" fontWeight={700} sx={{ opacity: 0.6 }}>ID: {user.national_id || 'N/A'}</Typography>
                        <Typography variant="caption" fontWeight={600} color="text.secondary">{user.phone_number || 'No Phone'}</Typography>
                      </Stack>
                    </TableCell>
                    <TableCell>
                      <Stack spacing={0.5}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                          <LocationIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
                          <Typography variant="caption" fontWeight={600}>
                            {loc ? `${loc.city}, ${loc.country}` : 'Not Shared'}
                          </Typography>
                        </Box>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                          <StarIcon sx={{ fontSize: 14, color: 'warning.main' }} />
                          <Typography variant="caption" fontWeight={700}>Trust: {user.trust_score?.toFixed(1) || '0.0'}</Typography>
                        </Box>
                        <StatusPill value={user.verification_status} />
                      </Stack>
                    </TableCell>
                    <TableCell>
                      {user.reports_count > 0 ? (
                        <Chip 
                          label={`${user.reports_count} Reports`} 
                          size="small" 
                          color="error" 
                          variant="outlined"
                          icon={<ReportIcon sx={{ fontSize: '12px !important' }} />}
                          sx={{ fontWeight: 800, borderRadius: '6px' }}
                        />
                      ) : (
                        <Typography variant="caption" color="success.main" fontWeight={700}>Clean Record</Typography>
                      )}
                    </TableCell>
                    <TableCell align="right">
                      <Tooltip title="Start Audit">
                        <IconButton sx={{ color: 'text.secondary', '&:hover': { color: 'primary.main', bgcolor: alpha(theme.palette.primary.main, 0.1) } }}>
                          <ReviewIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </Box>
      </Card>

      <Dialog 
        open={Boolean(selectedUser)} 
        onClose={() => setSelectedUser(null)} 
        fullWidth 
        maxWidth="lg"
        PaperProps={{
          sx: {
            borderRadius: '28px',
            bgcolor: alpha(theme.palette.background.paper, 0.95),
            backdropFilter: 'blur(20px)',
            border: `1px solid ${theme.palette.divider}`,
            boxShadow: '0 20px 60px rgba(0,0,0,0.1)'
          }
        }}
      >
        <DialogTitle sx={{ fontWeight: 900, fontSize: '1.75rem', letterSpacing: '-0.03em', pt: 4, px: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          Identity Verification Audit
          {selectedUser && (
            <Stack direction="row" spacing={1}>
              <Chip 
                label={(selectedUser.verification_status || 'unknown').toUpperCase()} 
                color={selectedUser.verification_status === 'approved' ? 'success' : (selectedUser.verification_status === 'pending' ? 'warning' : 'error')} 
                size="small" 
                sx={{ fontWeight: 800, borderRadius: '8px' }} 
              />
              <Chip 
                label={(selectedUser.status || 'unknown').toUpperCase()} 
                color={selectedUser.status === 'active' ? 'success' : 'error'} 
                size="small" 
                sx={{ fontWeight: 800, borderRadius: '8px' }} 
              />
            </Stack>
          )}
        </DialogTitle>
        <DialogContent sx={{ px: 4, pb: 2 }}>
          {selectedUser && (
            <Grid container spacing={4} mt={0}>
              {/* Left Side: Images & Intelligence */}
              <Grid item xs={12} md={7}>
                <Stack spacing={4}>
                  <Box>
                    <Typography variant="caption" fontWeight={800} color="text.secondary" textTransform="uppercase" letterSpacing="0.1em" mb={2} display="block">
                      Verification Media
                    </Typography>
                    <Grid container spacing={2}>
                      {/* ID Preview */}
                      <Grid item xs={6}>
                        <Box sx={{ p: 1, borderRadius: '20px', bgcolor: alpha(theme.palette.text.primary, 0.03), border: `1px solid ${theme.palette.divider}` }}>
                          <Typography variant="caption" fontWeight={700} mb={1} display="block" textAlign="center">Government ID</Typography>
                          <Box sx={{ height: 200, borderRadius: '14px', overflow: 'hidden', bgcolor: 'black', position: 'relative' }}>
                            {selectedUser.id_image_url ? (
                              <>
                                <img src={selectedUser.id_image_url} alt="ID" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                                <Box sx={{ position: 'absolute', bottom: 8, right: 8 }}>
                                  <IconButton size="small" component="a" href={selectedUser.id_image_url} target="_blank" sx={{ bgcolor: 'rgba(0,0,0,0.5)', color: 'white', '&:hover': { bgcolor: 'black' } }}>
                                    <OpenIcon fontSize="small" />
                                  </IconButton>
                                </Box>
                              </>
                            ) : (
                              <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100%', color: 'white', opacity: 0.5 }}>
                                <IDIcon sx={{ fontSize: 48, mb: 1 }} />
                                <Typography variant="caption">Not Provided</Typography>
                              </Box>
                            )}
                          </Box>
                        </Box>
                      </Grid>
                      {/* Selfie Preview */}
                      <Grid item xs={6}>
                        <Box sx={{ p: 1, borderRadius: '20px', bgcolor: alpha(theme.palette.text.primary, 0.03), border: `1px solid ${theme.palette.divider}` }}>
                          <Typography variant="caption" fontWeight={700} mb={1} display="block" textAlign="center">Live Selfie</Typography>
                          <Box sx={{ height: 200, borderRadius: '14px', overflow: 'hidden', bgcolor: 'black', position: 'relative' }}>
                            {selectedUser.selfie_image_url ? (
                              <>
                                <img src={selectedUser.selfie_image_url} alt="Selfie" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                                <Box sx={{ position: 'absolute', bottom: 8, right: 8 }}>
                                  <IconButton size="small" component="a" href={selectedUser.selfie_image_url} target="_blank" sx={{ bgcolor: 'rgba(0,0,0,0.5)', color: 'white', '&:hover': { bgcolor: 'black' } }}>
                                    <OpenIcon fontSize="small" />
                                  </IconButton>
                                </Box>
                              </>
                            ) : (
                              <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100%', color: 'white', opacity: 0.5 }}>
                                <UserIcon sx={{ fontSize: 48, mb: 1 }} />
                                <Typography variant="caption">Not Provided</Typography>
                              </Box>
                            )}
                          </Box>
                        </Box>
                      </Grid>
                    </Grid>
                  </Box>

                  {/* Submission Intelligence */}
                  <Box sx={{ p: 3, borderRadius: '24px', bgcolor: alpha(theme.palette.primary.main, 0.04), border: `1px solid ${alpha(theme.palette.primary.main, 0.1)}` }}>
                    <Typography variant="caption" fontWeight={800} color="primary.main" textTransform="uppercase" letterSpacing="0.1em" mb={2} display="block">
                      Submission Intelligence
                    </Typography>
                    <Grid container spacing={3}>
                      <Grid item xs={6}>
                        <Stack spacing={1}>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <LocationIcon sx={{ fontSize: 18, color: 'primary.main' }} />
                            <Box>
                              <Typography variant="caption" color="text.secondary">Capture Context</Typography>
                              <Typography variant="body2" fontWeight={700}>
                                {selectedUser.parsedLocation ? `${selectedUser.parsedLocation.city}, ${selectedUser.parsedLocation.country}` : 'Unavailable'}
                              </Typography>
                            </Box>
                          </Box>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <InfoIcon sx={{ fontSize: 18, color: 'primary.main' }} />
                            <Box>
                              <Typography variant="caption" color="text.secondary">Location Source</Typography>
                              <Typography variant="body2" fontWeight={700} sx={{ textTransform: 'uppercase' }}>
                                {selectedUser.parsedLocation?.source || 'LEGACY'}
                              </Typography>
                            </Box>
                          </Box>
                        </Stack>
                      </Grid>
                      <Grid item xs={6}>
                        <Stack spacing={1}>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <CalendarIcon sx={{ fontSize: 18, color: 'primary.main' }} />
                            <Box>
                              <Typography variant="caption" color="text.secondary">Submitted At</Typography>
                              <Typography variant="body2" fontWeight={700}>
                                {selectedUser.verification_submitted_at ? new Date(selectedUser.verification_submitted_at).toLocaleString() : 'N/A'}
                              </Typography>
                            </Box>
                          </Box>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <StarIcon sx={{ fontSize: 18, color: 'warning.main' }} />
                            <Box>
                              <Typography variant="caption" color="text.secondary">Current Trust Score</Typography>
                              <Typography variant="body2" fontWeight={700}>{(selectedUser.trust_score || 0).toFixed(1)}</Typography>
                            </Box>
                          </Box>
                        </Stack>
                      </Grid>
                    </Grid>
                  </Box>
                </Stack>
              </Grid>

              {/* Right Side: Applicant & Decision */}
              <Grid item xs={12} md={5}>
                <Stack spacing={4}>
                  <Box>
                    <Typography variant="caption" fontWeight={800} color="text.secondary" textTransform="uppercase" letterSpacing="0.1em" mb={2} display="block">
                      Applicant Profile
                    </Typography>
                    <Stack spacing={2}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Avatar src={selectedUser.profile_image_url} sx={{ width: 64, height: 64, border: `3px solid ${theme.palette.background.paper}`, boxShadow: theme.shadows[2] }}>
                          {selectedUser.name?.charAt(0)}
                        </Avatar>
                        <Box>
                          <Typography variant="h5" fontWeight={900} letterSpacing="-0.02em">{selectedUser.name || 'Unknown User'}</Typography>
                          <Typography variant="body2" color="text.secondary" fontWeight={600}>{selectedUser.email || 'No Email'}</Typography>
                        </Box>
                      </Box>
                      
                      <Stack spacing={1.5} sx={{ p: 2, borderRadius: '16px', bgcolor: alpha(theme.palette.text.primary, 0.03) }}>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <PhoneIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                            <Typography variant="caption" color="text.secondary">Phone</Typography>
                          </Box>
                          <Typography variant="body2" fontWeight={700}>{selectedUser.phone_number || 'N/A'}</Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <IDIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                            <Typography variant="caption" color="text.secondary">National ID</Typography>
                          </Box>
                          <Typography variant="body2" fontWeight={700}>{selectedUser.national_id || 'N/A'}</Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <CalendarIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                            <Typography variant="caption" color="text.secondary">Member Since</Typography>
                          </Box>
                          <Typography variant="body2" fontWeight={700}>
                            {selectedUser.created_at ? new Date(selectedUser.created_at).toLocaleDateString() : 'N/A'}
                          </Typography>
                        </Box>
                      </Stack>

                      {selectedUser.reports_count > 0 && (
                        <Box sx={{ p: 2, borderRadius: '16px', bgcolor: alpha(theme.palette.error.main, 0.08), border: `1px solid ${alpha(theme.palette.error.main, 0.2)}`, display: 'flex', alignItems: 'center', gap: 1.5 }}>
                          <ReportIcon color="error" />
                          <Box>
                            <Typography variant="body2" color="error" fontWeight={900}>Flagged Profile</Typography>
                            <Typography variant="caption" color="error" sx={{ opacity: 0.8 }}>
                              This user has been reported {selectedUser.reports_count} times by the community.
                            </Typography>
                          </Box>
                        </Box>
                      )}
                    </Stack>
                  </Box>

                  <Divider />

                  <Box>
                    <Typography variant="caption" fontWeight={800} color="text.secondary" textTransform="uppercase" letterSpacing="0.1em" mb={2} display="block">
                      Moderation Decision
                    </Typography>
                    {selectedUser.verification_status !== 'pending' && (
                       <Box sx={{ p: 2, mb: 2, borderRadius: '16px', bgcolor: alpha(theme.palette.info.main, 0.1), border: `1px solid ${alpha(theme.palette.info.main, 0.2)}` }}>
                        <Typography variant="caption" fontWeight={800} color="info.main" display="block">Existing Decision Notes</Typography>
                        <Typography variant="body2">{selectedUser.verification_notes || 'No notes provided.'}</Typography>
                        <Typography variant="caption" color="text.secondary" display="block" mt={1}>
                          Reviewed on: {selectedUser.verification_reviewed_at ? new Date(selectedUser.verification_reviewed_at).toLocaleString() : 'N/A'}
                        </Typography>
                      </Box>
                    )}
                    <TextField 
                      label={selectedUser.verification_status === 'pending' ? "Internal Review Notes" : "Update Review Notes"}
                      placeholder="Enter feedback for approval or rejection..."
                      value={notes} 
                      onChange={(event) => setNotes(event.target.value)} 
                      fullWidth 
                      multiline 
                      minRows={4} 
                      variant="outlined"
                      sx={{ '& .MuiOutlinedInput-root': { borderRadius: '16px', bgcolor: theme.palette.background.paper } }}
                    />
                  </Box>
                </Stack>
              </Grid>
            </Grid>
          )}
        </DialogContent>
        <DialogActions sx={{ px: 4, pb: 4, pt: 2, justifyContent: 'space-between' }}>
          <Button onClick={() => setSelectedUser(null)} sx={{ color: 'text.secondary', fontWeight: 700, borderRadius: '12px' }}>Close Audit</Button>
          {selectedUser && selectedUser.verification_status === 'pending' && (
            <Stack direction="row" spacing={2}>
              <Button variant="outlined" color="error" disabled={saving} onClick={() => reviewVerification(selectedUser.id, 'reject')} sx={{ borderRadius: '14px', px: 4, fontWeight: 800 }}>Reject</Button>
              <Button variant="contained" color="success" disabled={saving} onClick={() => reviewVerification(selectedUser.id, 'approve')} sx={{ borderRadius: '14px', px: 4, fontWeight: 800, boxShadow: '0 8px 20px ' + alpha(theme.palette.success.main, 0.3) }}>Approve</Button>
            </Stack>
          )}
        </DialogActions>
      </Dialog>
    </MotionPage>
  );
}
