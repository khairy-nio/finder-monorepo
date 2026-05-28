import { useEffect, useState, useMemo } from 'react';
import {
  Alert,
  Avatar,
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
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
  SearchRounded as SearchIcon,
  LocationOnRounded as LocationIcon,
  FileDownloadRounded as ExportIcon,
} from '@mui/icons-material';
import api from '../../api/axios';
import MotionPage from '../../components/MotionPage';

const initialForm = {
  title: '',
  post_type: 'lost',
  status: 'active',
  moderation_status: 'visible',
  category: '',
  country: '',
  state: '',
  city: '',
  area: '',
  latitude: '',
  longitude: '',
  description: '',
  image_url: '',
};

function StatusPill({ value }) {
  const theme = useTheme();
  const getColors = (val) => {
    switch (val?.toLowerCase()) {
      case 'lost': case 'removed': return theme.palette.error;
      case 'found': case 'active': case 'visible': return theme.palette.success;
      case 'matched': case 'pending': return theme.palette.info;
      case 'closed': case 'hidden': return theme.palette.warning;
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

export default function Posts() {
  const [posts, setPosts] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [selectedPost, setSelectedPost] = useState(null);
  const [form, setForm] = useState(initialForm);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const theme = useTheme();

  const fetchPosts = async () => {
    try {
      const response = await api.get('/post', { 
        params: { 
          limit: 100, 
          offset: 0, 
          moderationStatus: 'all',
          status: 'all' // Request all lifecycle statuses (active, matched, etc)
        } 
      });
      setPosts(response.data || []);
    } catch (err) {
      setError(err.response?.data?.message || err.message || 'Failed to load posts.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPosts();
  }, []);

  const filteredPosts = useMemo(() => {
    return posts.filter(post => {
      const matchesSearch = post.title?.toLowerCase().includes(searchQuery.toLowerCase()) || 
                           post.category?.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesType = typeFilter === 'all' || post.post_type === typeFilter;
      return matchesSearch && matchesType;
    });
  }, [posts, searchQuery, typeFilter]);

  const handleExport = () => {
    const csvContent = "data:text/csv;charset=utf-8," 
      + ["Title,Type,Status,Category,Country,City"].join(",") + "\n"
      + filteredPosts.map(p => `"${p.title}","${p.post_type}","${p.status}","${p.category}","${p.country}","${p.city}"`).join("\n");
    
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", "finder_posts_export.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const openEditor = (post) => {
    setSelectedPost(post);
    setForm({
      title: post.title || '',
      post_type: post.post_type || 'lost',
      status: post.status || 'active',
      moderation_status: post.moderation_status || 'visible',
      category: post.category || '',
      country: post.country || '',
      state: post.state || '',
      city: post.city || '',
      area: post.area || '',
      latitude: post.latitude || '',
      longitude: post.longitude || '',
      description: post.description || '',
      image_url: post.image_url || '',
    });
  };

  const updateForm = (field, value) => {
    setForm((current) => ({ ...current, [field]: value }));
  };

  const savePost = async () => {
    setSaving(true);
    setError('');
    try {
      await api.put(`/admin/posts/${selectedPost.id}`, form);
      setPosts((items) => items.map((post) => (post.id === selectedPost.id ? { ...post, ...form } : post)));
      setSelectedPost(null);
    } catch (err) {
      setError(err.response?.data?.message || err.message || 'Failed to update post.');
    } finally {
      setSaving(false);
    }
  };

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
            Posts
          </Typography>
          <Typography variant="h6" color="text.secondary" fontWeight={500}>
            Moderate platform listings, location data, and publication state.
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
              placeholder="Search by title or category..." 
              fullWidth 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              sx={{ fontSize: '0.9rem', fontWeight: 600 }}
            />
          </Box>
          
          <TextField
            select
            size="small"
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            sx={{ 
              minWidth: 140,
              '& .MuiOutlinedInput-root': { borderRadius: '14px', bgcolor: alpha(theme.palette.text.primary, 0.03) }
            }}
          >
            <MenuItem value="all">All Types</MenuItem>
            <MenuItem value="lost">Lost Items</MenuItem>
            <MenuItem value="found">Found Items</MenuItem>
          </TextField>

          <IconButton sx={{ bgcolor: alpha(theme.palette.text.primary, 0.03), borderRadius: '12px' }}>
            <FilterIcon fontSize="small" />
          </IconButton>
          
          <Typography variant="caption" fontWeight={700} color="text.secondary" sx={{ ml: 'auto' }}>
            Showing {filteredPosts.length} Results
          </Typography>
        </Box>

        <Box sx={{ overflowX: 'auto' }}>
          <Table>
            <TableHead>
              <TableRow sx={{ bgcolor: alpha(theme.palette.text.primary, 0.01) }}>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Listing</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Author</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Classification</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Visibility</TableCell>
                <TableCell sx={{ fontWeight: 800, textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.1em' }}>Location</TableCell>
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
              ) : filteredPosts.map((post) => (
                <TableRow key={post.id} sx={{ '&:hover': { bgcolor: alpha(theme.palette.primary.main, 0.02) } }}>
                  <TableCell>
                    <Stack direction="row" spacing={2} alignItems="center">
                      <Avatar src={post.image_url} variant="rounded" sx={{ width: 44, height: 44, borderRadius: '12px', border: `1px solid ${theme.palette.divider}` }} />
                      <Box>
                        <Typography variant="body2" fontWeight={700}>{post.title}</Typography>
                        <Typography variant="caption" color="text.secondary">{post.category || 'Uncategorized'}</Typography>
                      </Box>
                    </Stack>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" fontWeight={600}>{post.owner?.name || 'Anonymous'}</Typography>
                  </TableCell>
                  <TableCell>
                    <Stack direction="row" spacing={1}>
                      <StatusPill value={post.post_type} />
                      <StatusPill value={post.status} />
                    </Stack>
                  </TableCell>
                  <TableCell><StatusPill value={post.moderation_status || 'visible'} /></TableCell>
                  <TableCell>
                    <Stack direction="row" spacing={1} alignItems="center" color="text.secondary">
                      <LocationIcon sx={{ fontSize: 14 }} />
                      <Typography variant="caption" fontWeight={600}>
                        {[post.city, post.country].filter(Boolean).join(', ')}
                      </Typography>
                    </Stack>
                  </TableCell>
                  <TableCell align="right">
                    <Tooltip title="Moderate Post">
                      <IconButton onClick={() => openEditor(post)} sx={{ color: 'text.secondary', '&:hover': { color: 'primary.main', bgcolor: alpha(theme.palette.primary.main, 0.1) } }}>
                        <EditIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </Box>
      </Card>

      <Dialog 
        open={Boolean(selectedPost)} 
        onClose={() => setSelectedPost(null)} 
        fullWidth 
        maxWidth="md"
        PaperProps={{
          sx: {
            borderRadius: '24px',
            bgcolor: alpha(theme.palette.background.paper, 0.8),
            backdropFilter: 'blur(20px)',
            border: `1px solid ${theme.palette.divider}`,
          }
        }}
      >
        <DialogTitle sx={{ fontWeight: 800, fontSize: '1.5rem', letterSpacing: '-0.02em', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span>Moderate Publication</span>
          {selectedPost && (
             <Typography variant="caption" color="text.secondary">
               ID: {selectedPost.id}
             </Typography>
          )}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={4} mt={1}>
            <Grid item xs={12} md={5}>
              <Box sx={{ position: 'sticky', top: 0 }}>
                <Typography variant="subtitle2" fontWeight={700} gutterBottom>Publication Media</Typography>
                <Card variant="outlined" sx={{ borderRadius: '16px', overflow: 'hidden', mb: 2 }}>
                  <img 
                    src={form.image_url} 
                    alt={form.title} 
                    style={{ width: '100%', height: 'auto', display: 'block', maxHeight: '400px', objectFit: 'contain' }}
                  />
                </Card>
                <TextField 
                  label="Image URL" 
                  value={form.image_url} 
                  onChange={(event) => updateForm('image_url', event.target.value)} 
                  fullWidth 
                  size="small"
                />
                
                <Box sx={{ mt: 3, p: 2, bgcolor: alpha(theme.palette.primary.main, 0.05), borderRadius: '16px' }}>
                  <Typography variant="subtitle2" fontWeight={700} gutterBottom color="primary">Ownership Details</Typography>
                  <Stack direction="row" spacing={2} alignItems="center">
                    <Avatar sx={{ bgcolor: 'primary.main' }}>{selectedPost?.owner?.name?.[0] || 'U'}</Avatar>
                    <Box>
                      <Typography variant="body2" fontWeight={700}>{selectedPost?.owner?.name || 'Anonymous User'}</Typography>
                      <Typography variant="caption" color="text.secondary">{selectedPost?.owner?.email || 'No email provided'}</Typography>
                    </Box>
                  </Stack>
                </Box>
              </Box>
            </Grid>
            
            <Grid item xs={12} md={7}>
              <Stack spacing={3}>
                <TextField label="Post Title" value={form.title} onChange={(event) => updateForm('title', event.target.value)} fullWidth />
                <Stack direction="row" spacing={2}>
                  <TextField select label="Listing Type" value={form.post_type} onChange={(event) => updateForm('post_type', event.target.value)} fullWidth>
                    <MenuItem value="lost">Lost Item</MenuItem>
                    <MenuItem value="found">Found Item</MenuItem>
                  </TextField>
                  <TextField select label="Listing Status" value={form.status} onChange={(event) => updateForm('status', event.target.value)} fullWidth>
                    <MenuItem value="active">Active</MenuItem>
                    <MenuItem value="matched">Matched</MenuItem>
                    <MenuItem value="closed">Closed</MenuItem>
                    <MenuItem value="resolved">Resolved</MenuItem>
                  </TextField>
                </Stack>
                
                <TextField select label="Moderation Visibility" value={form.moderation_status} onChange={(event) => updateForm('moderation_status', event.target.value)} fullWidth>
                  <MenuItem value="visible">Visible</MenuItem>
                  <MenuItem value="hidden">Hidden</MenuItem>
                  <MenuItem value="removed">Removed (Soft Delete)</MenuItem>
                </TextField>

                <TextField label="Category" value={form.category} onChange={(event) => updateForm('category', event.target.value)} fullWidth />
                
                <Typography variant="subtitle2" fontWeight={700}>Geographic Metadata</Typography>
                <Grid container spacing={2}>
                  <Grid item xs={6}><TextField label="Country" value={form.country} onChange={(event) => updateForm('country', event.target.value)} fullWidth /></Grid>
                  <Grid item xs={6}><TextField label="State/Region" value={form.state} onChange={(event) => updateForm('state', event.target.value)} fullWidth /></Grid>
                  <Grid item xs={6}><TextField label="City" value={form.city} onChange={(event) => updateForm('city', event.target.value)} fullWidth /></Grid>
                  <Grid item xs={6}><TextField label="Specific Area" value={form.area} onChange={(event) => updateForm('area', event.target.value)} fullWidth /></Grid>
                </Grid>

                <Stack direction="row" spacing={2}>
                  <TextField label="Latitude" value={form.latitude} onChange={(event) => updateForm('latitude', event.target.value)} fullWidth />
                  <TextField label="Longitude" value={form.longitude} onChange={(event) => updateForm('longitude', event.target.value)} fullWidth />
                </Stack>

                <TextField label="Detailed Description" value={form.description} onChange={(event) => updateForm('description', event.target.value)} fullWidth multiline minRows={4} />
              </Stack>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ px: 4, pb: 4, pt: 2 }}>
          <Button onClick={() => setSelectedPost(null)} sx={{ color: 'text.secondary' }}>Discard Changes</Button>
          <Button onClick={savePost} variant="contained" disabled={saving} sx={{ borderRadius: '12px', px: 4 }}>
            {saving ? 'Saving...' : 'Confirm Updates'}
          </Button>
        </DialogActions>
      </Dialog>
    </MotionPage>
  );
}
