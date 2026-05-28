import { useEffect, useState, useMemo } from 'react';
import {
  Alert,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
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
  Card,
  LinearProgress,
  InputBase,
} from '@mui/material';
import {
  EditRounded as EditIcon,
  FilterListRounded as FilterIcon,
  ReportProblemRounded as ReportIcon,
  SearchRounded as SearchIcon,
  FileDownloadRounded as ExportIcon,
} from '@mui/icons-material';
import api from '../../api/axios';
import MotionPage from '../../components/MotionPage';

function StatusPill({ value }) {
  const theme = useTheme();
  const getColors = (val) => {
    switch (val?.toLowerCase()) {
      case 'resolved': case 'approved': return theme.palette.success;
      case 'pending': return theme.palette.warning;
      case 'rejected': case 'flagged': return theme.palette.error;
      default: return theme.palette.info;
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

export default function Reports() {
  const [reports, setReports] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedReport, setSelectedReport] = useState(null);
  const [form, setForm] = useState({ status: 'pending', reason: '', note: '' });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const theme = useTheme();

  const [inspectingChatId, setInspectingChatId] = useState(null);
  const [chatInspectionData, setChatInspectionData] = useState(null);
  const [loadingInspection, setLoadingInspection] = useState(false);
  const [inspectionError, setInspectionError] = useState('');

  const inspectChat = async (chatId) => {
    console.log("🔍 [inspectChat] Triggered for chatId:", chatId);
    setInspectingChatId(chatId);
    setLoadingInspection(true);
    setInspectionError('');
    setChatInspectionData(null);
    try {
      const response = await api.get(`/admin/chats/${chatId}/messages`);
      console.log("🔍 [inspectChat] Raw API Response:", response);
      
      // Handle either { success, message, data: { chat, messages } } or direct { chat, messages }
      let targetData = null;
      if (response) {
        if (response.chat && response.messages) {
          targetData = response;
        } else if (response.data && response.data.chat && response.data.messages) {
          targetData = response.data;
        } else if (response.data) {
          targetData = response.data;
        } else {
          targetData = response;
        }
      }
      
      console.log("🔍 [inspectChat] Resolved inspection data:", targetData);
      setChatInspectionData(targetData || null);
    } catch (err) {
      console.error("❌ [inspectChat] Error:", err);
      setInspectionError(err.response?.data?.message || err.message || 'Failed to retrieve chat logs.');
    } finally {
      setLoadingInspection(false);
    }
  };

  const fetchReports = async () => {
    try {
      const response = await api.get('/report/all', { params: { limit: 100, offset: 0 } });
      setReports(response.data?.reports || []);
    } catch (err) {
      setError(err.response?.data?.message || err.message || 'Failed to load reports.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReports();
  }, []);

  const filteredReports = useMemo(() => {
    return reports.filter(report => {
      const target = report.reportedUser?.email || report.reportedPost?.title || '';
      const reasonStr = report.reason || '';
      const typeStr = report.reportType || '';
      const matchesSearch = reasonStr.toLowerCase().includes(searchQuery.toLowerCase()) || 
                           target.toLowerCase().includes(searchQuery.toLowerCase()) ||
                           typeStr.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesStatus = statusFilter === 'all' || report.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [reports, searchQuery, statusFilter]);

  const handleExport = () => {
    const csvContent = "data:text/csv;charset=utf-8," 
      + ["Type,Reporter,Target,Reason,Status"].join(",") + "\n"
      + filteredReports.map(r => {
        const target = r.reportedUser?.email || r.reportedPost?.title || 'Unknown';
        return `"${r.reportType}","${r.reporter?.email || 'N/A'}","${target}","${r.reason}","${r.status}"`;
      }).join("\n");
    
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", "finder_reports_export.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const openEditor = (report) => {
    setSelectedReport(report);
    setForm({
      status: report.status || 'pending',
      reason: report.reason || '',
      note: report.note || '',
    });
  };

  const updateForm = (field, value) => {
    setForm((current) => ({ ...current, [field]: value }));
  };

  const saveReport = async () => {
    setSaving(true);
    setError('');
    try {
      await api.put(`/report/${selectedReport.id}/status`, form);
      setReports((items) => items.map((report) => (report.id === selectedReport.id ? { ...report, ...form } : report)));
      setSelectedReport(null);
    } catch (err) {
      setError(err.response?.data?.message || err.message || 'Failed to update report.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <MotionPage>
      <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems="flex-start" spacing={2} sx={{ mb: '6px' }}>
        <Box>
          <Typography variant="h2" fontWeight={900} letterSpacing="-0.06em" mb={1}>
            Moderation
          </Typography>
          <Typography variant="h6" color="text.secondary" fontWeight={500}>
            Review platform reports for accounts, posts, and community safety.
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
              placeholder="Search reports..." 
              fullWidth 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              sx={{ fontSize: '0.9rem', fontWeight: 600 }}
            />
          </Box>
          
          <TextField
            select
            size="small"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            sx={{ 
              minWidth: 140,
              '& .MuiOutlinedInput-root': { borderRadius: '14px', bgcolor: alpha(theme.palette.text.primary, 0.03) }
            }}
          >
            <MenuItem value="all">All Status</MenuItem>
            <MenuItem value="pending">Pending</MenuItem>
            <MenuItem value="resolved">Resolved</MenuItem>
          </TextField>

          <IconButton sx={{ bgcolor: alpha(theme.palette.text.primary, 0.03), borderRadius: '12px' }}>
            <FilterIcon fontSize="small" />
          </IconButton>
          
          <Typography variant="caption" fontWeight={700} color="text.secondary" sx={{ ml: 'auto' }}>
            {filteredReports.length} Reports
          </Typography>
        </Box>

        <Box sx={{ overflowX: 'auto' }}>
          <Table>
            <TableHead>
              <TableRow sx={{ bgcolor: alpha(theme.palette.text.primary, 0.01) }}>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Violation Type</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Reporter</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Target Subject</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Internal Reason</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Decision</TableCell>
                <TableCell align="right" sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                [...Array(5)].map((_, i) => (
                  <TableRow key={i}>
                    <TableCell colSpan={6}><LinearProgress sx={{ height: 2, opacity: 0.1 }} /></TableCell>
                  </TableRow>
                ))
              ) : filteredReports.map((report) => {
                const target = report.reportedUser?.email || report.reportedPost?.title || report.reported_message_id || report.reported_chat_id || 'ID: ' + (report.reported_user_id || report.reported_post_id);

                return (
                  <TableRow key={report.id} sx={{ '&:hover': { bgcolor: alpha(theme.palette.primary.main, 0.02) } }}>
                    <TableCell><StatusPill value={report.reportType} /></TableCell>
                    <TableCell>
                      <Typography variant="body2" fontWeight={600}>{report.reporter?.email || 'ID: ' + report.reporter_id}</Typography>
                    </TableCell>
                    <TableCell>
                      {report.reportType === 'chat' && report.reported_chat_id ? (
                        <Button 
                          size="small" 
                          variant="outlined" 
                          color="error" 
                          onClick={() => inspectChat(report.reported_chat_id)}
                          sx={{ borderRadius: '8px', textTransform: 'none', fontWeight: 700 }}
                        >
                          Inspect Chat ({report.reported_chat_id.substring(0, 8)}...)
                        </Button>
                      ) : (
                        <Typography variant="body2" color="text.secondary" noWrap sx={{ maxWidth: 200 }}>{target}</Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ opacity: 0.8 }}>{report.reason}</Typography>
                    </TableCell>
                    <TableCell><StatusPill value={report.status || 'pending'} /></TableCell>
                    <TableCell align="right">
                      <Tooltip title="Update Status">
                        <IconButton onClick={() => openEditor(report)} sx={{ color: 'text.secondary', '&:hover': { color: 'primary.main', bgcolor: alpha(theme.palette.primary.main, 0.1) } }}>
                          <EditIcon fontSize="small" />
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
        open={Boolean(selectedReport)} 
        onClose={() => setSelectedReport(null)} 
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
          Update Case Status
        </DialogTitle>
        <DialogContent>
          <Stack spacing={3} mt={2}>
            <TextField select label="Resolution Status" value={form.status} onChange={(event) => updateForm('status', event.target.value)} fullWidth>
              <MenuItem value="pending">Pending Review</MenuItem>
              <MenuItem value="resolved">Mark as Resolved</MenuItem>
            </TextField>
            <TextField label="Moderation Reason" value={form.reason} onChange={(event) => updateForm('reason', event.target.value)} fullWidth />
            <TextField label="Internal Admin Note" value={form.note} onChange={(event) => updateForm('note', event.target.value)} fullWidth multiline minRows={4} />
          </Stack>
        </DialogContent>
        <DialogActions sx={{ px: 4, pb: 4, pt: 2 }}>
          <Button onClick={() => setSelectedReport(null)} sx={{ color: 'text.secondary' }}>Cancel</Button>
          <Button onClick={saveReport} variant="contained" disabled={saving} sx={{ borderRadius: '12px', px: 4 }}>
            {saving ? 'Processing...' : 'Confirm Resolution'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Secure Conversation History Inspector */}
      <Dialog
        open={Boolean(inspectingChatId)}
        onClose={() => setInspectingChatId(null)}
        fullWidth
        maxWidth="md"
        PaperProps={{
          sx: {
            borderRadius: '24px',
            bgcolor: alpha(theme.palette.background.paper, 0.95),
            backdropFilter: 'blur(20px)',
            border: `1px solid ${theme.palette.divider}`,
            maxHeight: '85vh',
          }
        }}
      >
        <DialogTitle sx={{ fontWeight: 800, fontSize: '1.5rem', letterSpacing: '-0.02em', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Stack direction="row" spacing={1.5} alignItems="center">
            <ReportIcon color="error" />
            <Typography variant="h5" fontWeight={850} letterSpacing="-0.04em">Secure Chat Audit Logs</Typography>
          </Stack>
          <Button onClick={() => setInspectingChatId(null)} sx={{ color: 'text.secondary', fontWeight: 800 }}>Close</Button>
        </DialogTitle>
        <DialogContent sx={{ p: 4, display: 'flex', flexDirection: 'column', minHeight: '350px' }}>
          {loadingInspection && (
            <Box sx={{ py: 8, textAlign: 'center' }}>
              <LinearProgress sx={{ mb: 2, borderRadius: 2 }} />
              <Typography variant="body2" color="text.secondary">Accessing secure conversation vault...</Typography>
            </Box>
          )}
          
          {inspectionError && (
            <Alert severity="error" sx={{ borderRadius: 3, mb: 2 }}>{inspectionError}</Alert>
          )}

          {!loadingInspection && chatInspectionData && (
            <Stack spacing={3}>
              {/* Chat metadata card */}
              <Card variant="outlined" sx={{ p: 2.5, borderRadius: '16px', bgcolor: alpha(theme.palette.text.primary, 0.02) }}>
                <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" spacing={2}>
                  <Box>
                    <Typography variant="caption" fontWeight={800} color="text.secondary" sx={{ textTransform: 'uppercase', letterSpacing: '0.05em' }}>Participant 1</Typography>
                    <Typography variant="body2" fontWeight={700}>{chatInspectionData.chat?.firstUser?.name || 'Unknown'}</Typography>
                    <Typography variant="caption" color="text.secondary" display="block">{chatInspectionData.chat?.firstUser?.email || 'N/A'}</Typography>
                  </Box>
                  <Box>
                    <Typography variant="caption" fontWeight={800} color="text.secondary" sx={{ textTransform: 'uppercase', letterSpacing: '0.05em' }}>Participant 2</Typography>
                    <Typography variant="body2" fontWeight={700}>{chatInspectionData.chat?.secondUser?.name || 'Unknown'}</Typography>
                    <Typography variant="caption" color="text.secondary" display="block">{chatInspectionData.chat?.secondUser?.email || 'N/A'}</Typography>
                  </Box>
                  <Box>
                    <Typography variant="caption" fontWeight={800} color="text.secondary" sx={{ textTransform: 'uppercase', letterSpacing: '0.05em' }}>Chat Reference ID</Typography>
                    <Typography variant="body2" fontWeight={700} color="primary" sx={{ wordBreak: 'break-all' }}>{chatInspectionData.chat?.id}</Typography>
                  </Box>
                </Stack>
              </Card>

              {/* Chat transcript list */}
              <Box sx={{ 
                maxHeight: '400px', 
                overflowY: 'auto', 
                p: 2.5, 
                borderRadius: '16px', 
                border: `1px solid ${theme.palette.divider}`,
                bgcolor: alpha(theme.palette.background.default, 0.5),
                display: 'flex',
                flexDirection: 'column',
                gap: 2
              }}>
                {chatInspectionData.messages?.length === 0 ? (
                  <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic', textAlign: 'center', py: 4 }}>
                    No messages recorded in this chat room.
                  </Typography>
                ) : (
                  chatInspectionData.messages?.map((msg) => {
                    const isFirstUser = msg.sender_id === chatInspectionData.chat?.user_1;
                    return (
                      <Box 
                        key={msg.id}
                        sx={{
                          alignSelf: isFirstUser ? 'flex-start' : 'flex-end',
                          maxWidth: '75%',
                          p: 2,
                          borderRadius: isFirstUser ? '16px 16px 16px 4px' : '16px 16px 4px 16px',
                          bgcolor: isFirstUser ? alpha(theme.palette.primary.main, 0.06) : alpha(theme.palette.secondary.main, 0.06),
                          border: `1px solid ${isFirstUser ? alpha(theme.palette.primary.main, 0.12) : alpha(theme.palette.secondary.main, 0.12)}`,
                        }}
                      >
                        <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 0.5 }}>
                          <Typography variant="caption" fontWeight={800} color={isFirstUser ? 'primary.main' : 'secondary.main'}>
                            {msg.sender?.name || 'Unknown'} ({msg.sender?.email})
                          </Typography>
                          <Typography variant="caption" sx={{ opacity: 0.5, fontSize: '0.65rem' }}>
                            {new Date(msg.created_at || msg.timestamp).toLocaleString()}
                          </Typography>
                        </Stack>
                        <Typography variant="body2" sx={{ wordBreak: 'break-word', fontWeight: 500, color: theme.palette.text.primary }}>
                          {msg.content}
                        </Typography>
                      </Box>
                    );
                  })
                )}
              </Box>
            </Stack>
          )}
        </DialogContent>
        <DialogActions sx={{ px: 4, pb: 4, pt: 2 }}>
          <Button onClick={() => setInspectingChatId(null)} variant="contained" sx={{ borderRadius: '12px', px: 4 }}>
            Done Auditing
          </Button>
        </DialogActions>
      </Dialog>
    </MotionPage>
  );
}

