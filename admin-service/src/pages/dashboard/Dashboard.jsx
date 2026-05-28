import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Alert,
  Box,
  Card,
  Skeleton,
  Typography,
  alpha,
  useTheme,
  Button,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Checkbox,
  CircularProgress,
} from '@mui/material';
import {
  ArrowOutwardRounded as ArrowIcon,
  PeopleRounded as PeopleIcon,
  ReportRounded as ReportIcon,
  VerifiedRounded as VerifiedIcon,
  PostAddRounded as PostIcon,
  FileDownloadRounded as ExportIcon,
  ArchiveRounded as ZipIcon,
  DescriptionRounded as CSVIcon,
  EmojiEventsRounded as PointsIcon,
  RedeemRounded as GiftIcon,
} from '@mui/icons-material';
import { motion } from 'framer-motion';
import { Area, AreaChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import JSZip from 'jszip';
import api from '../../api/axios';
import MotionPage from '../../components/MotionPage';

function StatCard({ title, value, icon, color, delay = 0 }) {
  const theme = useTheme();
  return (
    <Card
      component={motion.div}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay }}
      sx={{
        p: 4,
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        position: 'relative',
        '&:hover': {
          border: `1px solid ${alpha(color, 0.3)}`,
          transform: 'translateY(-4px)',
          transition: 'all 0.3s ease'
        }
      }}
    >
      <Box display="flex" justifyContent="space-between" alignItems="flex-start">
        <Box 
          sx={{ 
            p: 1.5, 
            borderRadius: '16px', 
            bgcolor: alpha(color, 0.1), 
            color: color 
          }}
        >
          {icon}
        </Box>
        <ArrowIcon sx={{ color: 'text.secondary', opacity: 0.5 }} />
      </Box>
      <Box mt={4}>
        <Typography variant="h3" fontWeight={900} letterSpacing="-0.05em">
          {value.toLocaleString()}
        </Typography>
        <Typography variant="body1" color="text.secondary" fontWeight={600} mt={0.5}>
          {title}
        </Typography>
      </Box>
    </Card>
  );
}

export default function Dashboard() {
  const [exportOpen, setExportOpen] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [selectedItems, setSelectedItems] = useState(['users', 'posts', 'reports', 'verifications']);
  const theme = useTheme();

  const { data: stats, isLoading, error: fetchError } = useQuery({
    queryKey: ['admin-stats'],
    queryFn: async () => {
      const response = await api.get('/admin/stats');
      return response.data;
    }
  });

  const error = fetchError ? 'Connection failed. Please refresh.' : null;

  const chartData = useMemo(() => [
    { name: 'Mon', val: 40 }, { name: 'Tue', val: 30 }, { name: 'Wed', val: 60 },
    { name: 'Thu', val: 80 }, { name: 'Fri', val: 50 }, { name: 'Sat', val: 90 }, { name: 'Sun', val: 100 }
  ], []);

  const toggleItem = (item) => {
    setSelectedItems(prev => 
      prev.includes(item) ? prev.filter(i => i !== item) : [...prev, item]
    );
  };

  const convertToCSV = (data, type) => {
    if (!data || !data.length) return '';
    let headers = [];
    let rows = [];

    if (type === 'users') {
      headers = ['Name', 'Email', 'Role', 'Status', 'Trust Score'];
      rows = data.map(u => [`"${u.name}"`, `"${u.email}"`, `"${u.role}"`, `"${u.status}"`, u.trust_score]);
    } else if (type === 'posts') {
      headers = ['Title', 'Type', 'Status', 'Category', 'Country', 'City'];
      rows = data.map(p => [`"${p.title}"`, `"${p.post_type}"`, `"${p.status}"`, `"${p.category}"`, `"${p.country}"`, `"${p.city}"`]);
    } else if (type === 'reports') {
      headers = ['Type', 'Reason', 'Status', 'Reporter ID'];
      rows = data.map(r => [`"${r.reportType}"`, `"${r.reason}"`, `"${r.status}"`, `"${r.reporter_id}"`]);
    } else if (type === 'verifications') {
      headers = ['Name', 'Email', 'National ID', 'Phone'];
      rows = data.map(v => [`"${v.name}"`, `"${v.email}"`, `"${v.national_id || ''}"`, `"${v.phone_number || ''}"`]);
    }

    return [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
  };

  const handleExportAction = async () => {
    if (selectedItems.length === 0) return;
    setExporting(true);
    try {
      const zip = new JSZip();
      
      const fetchPromises = selectedItems.map(async (type) => {
        let endpoint = '';
        if (type === 'users') endpoint = '/admin/users';
        else if (type === 'posts') endpoint = '/post';
        else if (type === 'reports') endpoint = '/report/all';
        else if (type === 'verifications') endpoint = '/admin/verifications/pending';

        const res = await api.get(endpoint, { params: { limit: 1000 } });
        const data = res.data?.users || res.data?.reports || res.data?.verifications || res.data || [];
        const csv = convertToCSV(data, type);
        
        if (selectedItems.length === 1) {
          const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
          const url = URL.createObjectURL(blob);
          const link = document.createElement("a");
          link.setAttribute("href", url);
          link.setAttribute("download", `finder_${type}_export.csv`);
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
        } else {
          zip.file(`finder_${type}_export.csv`, csv);
        }
      });

      await Promise.all(fetchPromises);

      if (selectedItems.length > 1) {
        const content = await zip.generateAsync({ type: 'blob' });
        const url = URL.createObjectURL(content);
        const link = document.createElement("a");
        link.setAttribute("href", url);
        link.setAttribute("download", "finder_admin_exports.zip");
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      }
      
      setExportOpen(false);
    } catch (err) {
      console.error('Export failed', err);
      alert('Failed to generate export. Check console for details.');
    } finally {
      setExporting(false);
    }
  };

  if (isLoading) return (
    <Box sx={{ display: 'grid', gap: 4, gridTemplateColumns: 'repeat(12, 1fr)' }}>
      <Skeleton variant="rounded" height={400} sx={{ gridColumn: 'span 12', borderRadius: 8 }} />
    </Box>
  );

  return (
    <MotionPage>
      <Box sx={{ display: 'grid', gap: 4, gridTemplateColumns: { xs: '1fr', lg: 'repeat(12, 1fr)' } }}>
        
        {/* Hero Section */}
        <Box sx={{ gridColumn: { lg: 'span 8' } }}>
          <Typography variant="h2" fontWeight={900} letterSpacing="-0.06em" mb={1}>
            Overview
          </Typography>
          <Typography variant="h6" color="text.secondary" mb={4} fontWeight={500}>
            Live platform analytics and moderation status.
          </Typography>
          
          <Card sx={{ p: 4, height: 400 }}>
            <Box display="flex" justifyContent="space-between" mb={4}>
              <Typography variant="h6">Activity Trends</Typography>
              <Stack direction="row" spacing={2}>
                <Box display="flex" alignItems="center" gap={1}>
                  <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: 'primary.main' }} />
                  <Typography variant="caption">New Reports</Typography>
                </Box>
              </Stack>
            </Box>
            <Box sx={{ width: '100%', height: 280 }}>
              <ResponsiveContainer>
                <AreaChart data={chartData}>
                  <defs>
                    <linearGradient id="colorVal" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor={theme.palette.primary.main} stopOpacity={0.3} />
                      <stop offset="95%" stopColor={theme.palette.primary.main} stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <Tooltip 
                    contentStyle={{ borderRadius: '16px', border: 'none', background: theme.palette.background.paper }} 
                  />
                  <Area 
                    type="monotone" 
                    dataKey="val" 
                    stroke={theme.palette.primary.main} 
                    strokeWidth={4} 
                    fillOpacity={1} 
                    fill="url(#colorVal)" 
                  />
                </AreaChart>
              </ResponsiveContainer>
            </Box>
          </Card>
        </Box>

        {/* Sidebar Stats */}
        <Box sx={{ gridColumn: { lg: 'span 4' }, display: 'grid', gap: 4 }}>
          <StatCard 
            title="Total Users" 
            value={stats?.totalUsers || 0} 
            icon={<PeopleIcon />} 
            color={theme.palette.primary.main} 
            delay={0.1}
          />
          <StatCard 
            title="Pending Reports" 
            value={stats?.pendingReports || 0} 
            icon={<ReportIcon />} 
            color={theme.palette.error.main} 
            delay={0.2}
          />
        </Box>

        {/* Bottom Bento Row */}
        <Box sx={{ gridColumn: { xs: 'span 12', sm: 'span 6', md: 'span 3' } }}>
          <StatCard 
            title="Verified" 
            value={stats?.verifiedUsers || 0} 
            icon={<VerifiedIcon />} 
            color={theme.palette.success.main} 
            delay={0.3}
          />
        </Box>
        <Box sx={{ gridColumn: { xs: 'span 12', sm: 'span 6', md: 'span 3' } }}>
          <StatCard 
            title="Active Posts" 
            value={stats?.activePosts || 0} 
            icon={<PostIcon />} 
            color={theme.palette.secondary.main} 
            delay={0.4}
          />
        </Box>
        <Box sx={{ gridColumn: { xs: 'span 12', sm: 'span 6', md: 'span 3' } }}>
          <StatCard 
            title="Recovery Points" 
            value={stats?.totalRecoveryPoints || 0} 
            icon={<PointsIcon />} 
            color="#FF9900" 
            delay={0.5}
          />
        </Box>
        <Box sx={{ gridColumn: { xs: 'span 12', sm: 'span 6', md: 'span 3' } }}>
          <StatCard 
            title="Redemptions" 
            value={stats?.totalRewardsRedeemed || 0} 
            icon={<GiftIcon />} 
            color="#146B93" 
            delay={0.6}
          />
        </Box>

        <Box sx={{ gridColumn: 'span 12' }}>
          <Card sx={{ p: 4, display: 'flex', alignItems: 'center', justifyContent: 'space-between', position: 'relative', flexWrap: 'wrap', gap: 2 }}>
            <Box>
              <Typography variant="h5" fontWeight={800} mb={0.5}>Export Administration Data</Typography>
              <Typography variant="body2" color="text.secondary">Securely download platform backups and audit trails in CSV and ZIP formats.</Typography>
            </Box>
            <Button 
              variant="contained" 
              startIcon={<ExportIcon />}
              onClick={() => setExportOpen(true)}
              sx={{ borderRadius: '14px', py: 1.5, px: 4 }}
            >
              Export Data
            </Button>
          </Card>
        </Box>
      </Box>

      {/* Advanced Export Dialog */}
      <Dialog 
        open={exportOpen} 
        onClose={() => !exporting && setExportOpen(false)}
        fullWidth
        maxWidth="xs"
        PaperProps={{
          sx: { borderRadius: '24px', p: 1 }
        }}
      >
        <DialogTitle sx={{ fontWeight: 800 }}>Choose Reports to Export</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" mb={2}>
            Select the categories you want to include. Selecting multiple will bundle them into a ZIP archive.
          </Typography>
          <List>
            {[
              { id: 'users', label: 'User Directory', icon: <PeopleIcon fontSize="small" /> },
              { id: 'posts', label: 'Platform Posts', icon: <PostIcon fontSize="small" /> },
              { id: 'reports', label: 'Moderation Reports', icon: <ReportIcon fontSize="small" /> },
              { id: 'verifications', label: 'ID Verifications', icon: <VerifiedIcon fontSize="small" /> },
            ].map((item) => (
              <ListItem key={item.id} disablePadding>
                <ListItemButton onClick={() => toggleItem(item.id)} sx={{ borderRadius: '12px' }}>
                  <ListItemIcon sx={{ minWidth: 40 }}>
                    <Checkbox 
                      edge="start" 
                      checked={selectedItems.includes(item.id)} 
                      disableRipple
                    />
                  </ListItemIcon>
                  <ListItemIcon sx={{ minWidth: 32, color: 'primary.main' }}>{item.icon}</ListItemIcon>
                  <ListItemText primary={item.label} primaryTypographyProps={{ fontWeight: 600 }} />
                </ListItemButton>
              </ListItem>
            ))}
          </List>
        </DialogContent>
        <DialogActions sx={{ p: 3 }}>
          <Button onClick={() => setExportOpen(false)} disabled={exporting}>Cancel</Button>
          <Button 
            variant="contained" 
            onClick={handleExportAction} 
            disabled={exporting || selectedItems.length === 0}
            startIcon={exporting ? <CircularProgress size={20} color="inherit" /> : (selectedItems.length > 1 ? <ZipIcon /> : <CSVIcon />)}
            sx={{ borderRadius: '12px', px: 3 }}
          >
            {exporting ? 'Generating...' : (selectedItems.length > 1 ? 'Download All (ZIP)' : 'Download CSV')}
          </Button>
        </DialogActions>
      </Dialog>
    </MotionPage>
  );
}
