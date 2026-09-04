<script setup>
/* eslint-disable */
import { ref, computed, onMounted, watch } from 'vue';
import { RelayInput as Input, RelayBadge as Badge, RelayButton } from 'dashboard/components-next/relay';
import {
  Play, MoreHorizontal, MessageSquare, Heart, Share2, 
  CheckCircle, Search, Filter, Calendar, ExternalLink, 
  X, Eye, Download, LayoutGrid, List, Sparkles,
  Trash2, Edit, Check, ChevronDown, Clock, Quote,
  Bot, ThumbsUp, Send, Globe, FileText, Plus, Star
} from 'lucide-vue-next';
import RequestVideoTestimonialModal from '../components/RequestVideoTestimonialModal.vue';
import VideoTestimonialWidgetModal from '../components/VideoTestimonialWidgetModal.vue';
import { isReputationDemoSurfacesEnabled } from 'dashboard/featureFlags';

const isWidgetModalOpen = ref(false);

// Real data — de-mocked (Phase 1). AI fields (topics/transcript/aiTags) are Phase 3,
// so they render empty until that ships.
const axios = window.axios;
const accountId = window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];
const baseUrl = () => `/api/v1/accounts/${accountId}/reputation/video_testimonials`;

const mockVideos = ref([]); // holds the real, mapped rows (name kept to avoid touching the template)
const loading = ref(true);

// enum (backend) → display label (UI) and back.
const STATUS_LABEL = { pending: 'Pending Approval', approved: 'Approved', published: 'Published', rejected: 'Rejected' };
const STATUS_KEY = { 'Pending Approval': 'pending', Approved: 'approved', Published: 'published', Rejected: 'rejected' };

const formatDuration = secs => {
  if (!secs && secs !== 0) return '--:--';
  const m = Math.floor(secs / 60);
  const s = String(secs % 60).padStart(2, '0');
  return `${m}:${s}`;
};
const formatDate = ts => new Date(ts * 1000).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
const formatEventTime = ts => new Date(ts * 1000).toLocaleString('en-GB', { day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit' });

// Real activity timeline from the moderation timestamps (D4) — no separate events table.
const TIMELINE_META = {
  submitted: { icon: Play, dot: 'bg-primary/10', ic: 'text-primary' },
  approved: { icon: ThumbsUp, dot: 'bg-primary/10', ic: 'text-primary' },
  published: { icon: Check, dot: 'bg-emerald-100', ic: 'text-emerald-600' },
  rejected: { icon: X, dot: 'bg-destructive/15', ic: 'text-destructive' },
};
const iconFor = key => TIMELINE_META[key].icon;
const timeline = computed(() => {
  const v = selectedVideo.value;
  if (!v) return [];
  return [
    { key: 'submitted', label: 'Video Submitted', ts: v.submittedAt },
    { key: 'approved', label: 'Approved', ts: v.approvedAt },
    { key: 'published', label: 'Published', ts: v.publishedAt },
    { key: 'rejected', label: 'Rejected', ts: v.rejectedAt },
  ].filter(e => e.ts)
    .sort((a, b) => b.ts - a.ts)
    .map(e => ({ ...e, at: formatEventTime(e.ts), dot: TIMELINE_META[e.key].dot, ic: TIMELINE_META[e.key].ic }));
});

// Map an API row to the shape the template expects.
function mapVideo(v) {
  const ai = v.ai_insights && typeof v.ai_insights === 'object' && !Array.isArray(v.ai_insights)
    ? v.ai_insights
    : {};
  return {
    id: v.id,
    author: v.customer_name || v.contact?.name || v.title || 'Customer',
    company: v.company || '',
    avatar: '',
    thumbnail: v.thumbnail_url || '',
    videoUrl: v.video_url || '',
    shareUrl: v.share_url || '',
    duration: formatDuration(v.duration_seconds),
    date: v.created_at ? formatDate(v.created_at) : '',
    submittedAt: v.created_at || null,
    approvedAt: v.approved_at || null,
    publishedAt: v.published_at || null,
    rejectedAt: v.rejected_at || null,
    notes: v.notes || [],
    email: v.email || '',
    status: STATUS_LABEL[v.status] || 'Pending Approval',
    platform: v.platform || '',
    rating: v.rating || 0,
    views: v.views || 0,
    likes: 0,
    aiTags: [STATUS_LABEL[v.status] || 'Pending Approval'],
    aiInsights: ai,
    topics: Array.isArray(ai.topics) ? ai.topics : [],
    transcriptSummary: ai.summary || ''
  };
}

async function loadVideos({ silent } = {}) {
  if (!accountId) { loading.value = false; return; }
  if (!silent) loading.value = true;
  try {
    const params = {};
    if (activeStatus.value) params.status = activeStatus.value;
    if (activePlatform.value) params.platform = activePlatform.value;
    if (activeMinRating.value) params.min_rating = activeMinRating.value;
    if (activeSort.value) params.sort = activeSort.value;
    const { data } = await axios.get(baseUrl(), { params });
    mockVideos.value = (data || []).map(mapVideo);
  } catch (err) {
    console.error('Failed to load video testimonials', err);
    mockVideos.value = [];
  } finally {
    if (!silent) loading.value = false;
  }
}

const selectedVideo = ref(null);
const viewMode = ref('grid');
const activeTab = ref('Overview');
const DETAIL_TABS = ['Overview', 'Transcript', 'AI Insights', 'Activity', 'Notes'];

// AI-tag filter is still demo-flagged; the detail tabs themselves are always shown.
const showDemoSurfaces = computed(() =>
  isReputationDemoSurfacesEnabled(
    accountId,
    window.__STORE__?.getters['accounts/isFeatureEnabledonAccount']
  )
);
const insights = computed(() => selectedVideo.value?.aiInsights || {});
const hasInsights = computed(() => !!insights.value.processed_at);
const analyzing = ref(false);

function selectTab(name) {
  activeTab.value = name;
}

// POST /analyze, then poll index until this video's ai_insights fills in (or errors).
async function analyzeVideo() {
  const v = selectedVideo.value;
  if (!v || analyzing.value) return;
  analyzing.value = true;
  try {
    await axios.post(`${baseUrl()}/${v.id}/analyze`);
    let settled = false;
    for (let i = 0; i < 12; i += 1) {
      await new Promise(r => setTimeout(r, 4000));
      await loadVideos({ silent: true });
      const fresh = mockVideos.value.find(x => x.id === v.id);
      if (fresh) selectedVideo.value = fresh;
      const ai = fresh?.aiInsights || {};
      if (ai.processed_at || ai.error) {
        settled = true;
        if (ai.error) showToast(`Couldn't analyze: ${ai.error}`);
        break;
      }
    }
    if (!settled) showToast('Analysis is still running. Check back in a moment.');
  } catch (err) {
    showToast('Could not start analysis.');
  } finally {
    analyzing.value = false;
  }
}
const searchQuery = ref('');

const showPlatformDropdown = ref(false);
const showRatingDropdown = ref(false);
const showDurationDropdown = ref(false);
const showStatusDropdown = ref(false);
const showAiTagsDropdown = ref(false);
const showSortDropdown = ref(false);
const showDetailStatusDropdown = ref(false);

// Filter state (server-side via loadVideos). Empty = no filter.
const activeStatus = ref('');
const activePlatform = ref('');
const activeMinRating = ref('');
const activeSort = ref('');
const activeTag = ref(''); // B7: client-side AI-topic filter

function setTagFilter(tag) { activeTag.value = tag === 'All Tags' ? '' : tag; showAiTagsDropdown.value = false; }

function setStatusFilter(label) { activeStatus.value = STATUS_KEY[label] || ''; showStatusDropdown.value = false; }
function setPlatformFilter(name) { activePlatform.value = name === 'All Platforms' ? '' : name; showPlatformDropdown.value = false; }
function setRatingFilter(label) { activeMinRating.value = { '5 Stars': 5, '4 Stars & Up': 4, '3 Stars & Up': 3, '2 Stars & Below': 2 }[label] || ''; showRatingDropdown.value = false; }
function setSortFilter(label) { activeSort.value = { 'Newest First': '', 'Oldest First': 'oldest', 'Highest Rating': 'rating', 'Most Views': 'views' }[label] ?? ''; showSortDropdown.value = false; }

onMounted(loadVideos);
watch([activeStatus, activePlatform, activeMinRating, activeSort], loadVideos);

const toastState = ref({ visible: false, message: '' });
let toastTimeout = null;

const showToast = (message) => {
  toastState.value.message = message;
  toastState.value.visible = true;
  if (toastTimeout) clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => {
    toastState.value.visible = false;
  }, 3000);
};

const platforms = [
  { name: 'Google', color: '#4285F4', icon: '<svg viewBox="0 0 24 24" width="14" height="14" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>' },
  { name: 'Facebook', color: '#1877F2', icon: '<svg viewBox="0 0 24 24" width="14" height="14" xmlns="http://www.w3.org/2000/svg"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" fill="#1877F2"/></svg>' },
  { name: 'Yelp', color: '#E00707', icon: '<svg viewBox="0 0 24 24" width="14" height="14" xmlns="http://www.w3.org/2000/svg" fill="#E00707"><path d="M12.271 8.782c-.549-3.804-.822-5.72-.822-5.748 0-.888-.622-1.641-1.537-1.887A2.34 2.34 0 0 0 7.3 2.52L3.473 7.337a2.01 2.01 0 0 0-.302 1.895c.28.72.934 1.218 1.695 1.282l5.894.488c1.038.087 1.871-.767 1.511-2.22zm-8.245 6.253l5.374 2.186c1.004.409 2.084-.332 2.084-1.41V11.38c0-1.088-1.096-1.83-2.104-1.41l-5.374 2.185a1.85 1.85 0 0 0-1.148 1.44 1.855 1.855 0 0 0 1.168 1.44zm6.406 5.978l-3.218-4.874a1.796 1.796 0 0 0-2.97-.095 1.855 1.855 0 0 0-.17 1.98l2.28 4.374a2.316 2.316 0 0 0 2.492 1.208 2.302 2.302 0 0 0 1.586-2.593zm9.56-10.826a2.31 2.31 0 0 0-1.92-1.435l-5.916-.489a1.796 1.796 0 0 0-1.493 2.874l3.42 4.96a1.803 1.803 0 0 0 2.8.217l3.477-4.046a2.02 2.02 0 0 0 .368-.654 2.004 2.004 0 0 0-.736-1.427zm-2.278 7.916l-2.277-4.373a1.804 1.804 0 0 0-3.124.149 1.789 1.789 0 0 0 .057 1.695l3.218 4.874a2.305 2.305 0 0 0 2.534.938 2.316 2.316 0 0 0 1.57-2.593 2.31 2.31 0 0 0-1.978-0.69z"/></svg>' },
  { name: 'Trustpilot', color: '#00B67A', icon: '<svg viewBox="0 0 24 24" width="14" height="14" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" fill="#00B67A" rx="2" ry="2"/><path d="M12 4l2.5 5.2 5.7.8-4.1 4 1 5.7-5.1-2.7-5.1 2.7 1-5.7-4.1-4 5.7-.8L12 4z" fill="#FFF"/></svg>' }
];

const getPlatformIcon = (name) => platforms.find(p => p.name === name)?.icon || '';

const selectVideo = (video) => {
  selectedVideo.value = video;
  replyVariant.value = 0;
  if (!DETAIL_TABS.includes(activeTab.value)) activeTab.value = 'Overview';
};

const closePanel = () => {
  selectedVideo.value = null;
};

const isRequestModalOpen = ref(false);

const handleRequestTestimonial = () => {
  isRequestModalOpen.value = true;
};

const handleModalSubmit = () => {
  // The request modal already POSTed; the video arrives later via the public page.
  showToast('Request sent successfully.');
  loadVideos();
};

const noteDraft = ref('');
const savingNote = ref(false);
async function addNote() {
  const body = noteDraft.value.trim();
  if (!body || !selectedVideo.value) return;
  savingNote.value = true;
  try {
    const { data } = await axios.post(`${baseUrl()}/${selectedVideo.value.id}/add_note`, { body });
    selectedVideo.value.notes = [...(selectedVideo.value.notes || []), data];
    noteDraft.value = '';
  } catch (e) {
    showToast('Failed to add note.');
  } finally {
    savingNote.value = false;
  }
}

function localReply(video, variant = 0) {
  const name = (video?.author || 'there').split(' ')[0];
  const variants = [
    `Thank you so much, ${name}! We're thrilled you took the time to share this. We're always here if you need anything.`,
    `Hi ${name}, we really appreciate this testimonial — it means a lot to the team. Thank you!`,
    `Thanks ${name}! Hearing this from you made our day. We'll keep working to earn that trust.`,
  ];
  return variants[variant % variants.length];
}
const replyVariant = ref(0);
const displayedReply = computed(() => {
  const v = selectedVideo.value;
  if (!v) return '';
  if (replyVariant.value === 0 && insights.value.suggested_reply) return insights.value.suggested_reply;
  const offset = insights.value.suggested_reply ? replyVariant.value - 1 : replyVariant.value;
  return localReply(v, Math.max(0, offset));
});
const handleReply = async () => {
  const v = selectedVideo.value;
  if (!v) return;
  const text = displayedReply.value;
  try { await navigator.clipboard.writeText(text); } catch { /* ignore */ }
  if (v.email) {
    window.location.href = `mailto:${encodeURIComponent(v.email)}?subject=${encodeURIComponent('Thank you for your testimonial')}&body=${encodeURIComponent(text)}`;
    return;
  }
  showToast('Reply copied. No customer email on this video.');
};
const handleShare = async () => {
  const url = selectedVideo.value?.shareUrl || selectedVideo.value?.videoUrl;
  if (!url) { showToast('No shareable link yet.'); return; }
  try {
    await navigator.clipboard.writeText(url);
    showToast('Share link copied to clipboard!');
  } catch (e) {
    showToast('Could not copy link.');
  }
};
const handleDownload = () => {
  const url = selectedVideo.value?.videoUrl;
  if (!url) { showToast('No video to download.'); return; }
  const a = document.createElement('a');
  a.href = url;
  a.download = `${selectedVideo.value.author || 'testimonial'}.mp4`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  showToast('Downloading video…');
};
const handleEdit = async () => {
  const v = selectedVideo.value;
  if (!v) return;
  const name = window.prompt('Customer name', v.author);
  if (!name || !name.trim() || name.trim() === v.author) return;
  try {
    await axios.patch(`${baseUrl()}/${v.id}`, { customer_name: name.trim() });
    v.author = name.trim();
    const idx = mockVideos.value.findIndex(row => row.id === v.id);
    if (idx !== -1) mockVideos.value[idx].author = name.trim();
    showToast('Name updated');
  } catch (err) {
    showToast('Failed to update name');
  }
};
// F6: embed = an iframe of the public share page (reuses F2; no separate video widget).
const handleEmbed = async () => {
  const url = selectedVideo.value?.shareUrl;
  if (!url) { showToast('No embed available yet.'); return; }
  const code = `<iframe src="${url}" width="360" height="640" frameborder="0" allowfullscreen loading="lazy"></iframe>`;
  try {
    await navigator.clipboard.writeText(code);
    showToast('Embed code copied to clipboard!');
  } catch (e) {
    showToast('Could not copy embed code.');
  }
};

const handleStatusChange = async (newStatus) => {
  if (!selectedVideo.value) return;
  const video = selectedVideo.value;
  const prev = video.status;
  video.status = newStatus; // optimistic
  showDetailStatusDropdown.value = false;
  try {
    await axios.patch(`${baseUrl()}/${video.id}`, { status: STATUS_KEY[newStatus] });
    const now = Math.floor(Date.now() / 1000);
    if (newStatus === 'Approved') video.approvedAt = now;
    if (newStatus === 'Published') {
      video.publishedAt = now;
      video.approvedAt = video.approvedAt || now;
    }
    if (newStatus === 'Rejected') video.rejectedAt = now;
    const idx = mockVideos.value.findIndex(v => v.id === video.id);
    if (idx !== -1) mockVideos.value[idx].status = newStatus;
    showToast(`Status changed to ${newStatus}`);
  } catch (err) {
    video.status = prev; // revert on failure
    showToast('Failed to update status.');
  }
};

const handleDelete = async () => {
  if (!selectedVideo.value || !confirm('Are you sure you want to delete this video?')) return;
  const id = selectedVideo.value.id;
  try {
    await axios.delete(`${baseUrl()}/${id}`);
    mockVideos.value = mockVideos.value.filter(v => v.id !== id);
    selectedVideo.value = null;
    showToast('Video deleted successfully.');
  } catch (err) {
    showToast('Failed to delete video.');
  }
};

const handleGenerateNew = () => {
  if (!selectedVideo.value) return;
  replyVariant.value += 1;
  showToast('New reply suggestion ready');
};
const handleUseReply = async () => {
  if (!displayedReply.value) return;
  try {
    await navigator.clipboard.writeText(displayedReply.value);
    showToast('Reply copied to clipboard');
  } catch (e) {
    showToast('Could not copy reply');
  }
};

// B7: distinct AI topic tags across loaded rows (only analyzed videos have any).
const availableTags = computed(() => {
  const seen = new Set();
  mockVideos.value.forEach(v => (v.topics || []).forEach(t => t && seen.add(t)));
  return [...seen].sort();
});

const filteredVideos = computed(() => {
  const q = searchQuery.value.toLowerCase();
  return mockVideos.value.filter(v => {
    if (activeTag.value && !(v.topics || []).includes(activeTag.value)) return false;
    if (!q) return true;
    return (v.author || '').toLowerCase().includes(q) ||
      (v.transcriptSummary || '').toLowerCase().includes(q);
  });
});

// Real KPI numbers computed from the loaded rows (was hardcoded).
const stats = computed(() => {
  const rows = mockVideos.value;
  const total = rows.length;
  const published = rows.filter(v => v.status === 'Published').length;
  const awaiting = rows.filter(v => v.status === 'Pending Approval').length;
  const rated = rows.filter(v => v.rating > 0);
  const avgRating = rated.length ? (rated.reduce((s, v) => s + v.rating, 0) / rated.length).toFixed(1) : '—';
  return {
    total,
    publishedPct: total ? Math.round((published / total) * 100) : 0,
    avgRating,
    awaiting
  };
});
</script>

<template>
  <div class="relative flex h-[calc(100vh-4rem)] min-h-0 w-full overflow-hidden bg-background">
    <VideoTestimonialWidgetModal v-model:open="isWidgetModalOpen" />
    <RequestVideoTestimonialModal v-model:open="isRequestModalOpen" @submit="handleModalSubmit" />

    <!-- Main Content Area (Left) -->
    <div 
      class="flex flex-col h-full overflow-y-auto transition-all duration-300 hide-scrollbar"
      :class="selectedVideo ? 'w-full lg:w-[65%] xl:w-[70%]' : 'w-full'"
    >
      <div class="px-8 py-6 border-b border-border bg-card shrink-0">
        <div class="flex items-center text-sm text-muted-foreground mb-2">
          <span>Reputation</span>
          <span class="mx-2">/</span>
          <span class="text-foreground font-medium">Video Reviews</span>
        </div>
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 class="text-base font-medium text-foreground">Video Reviews</h1>
            <p class="text-sm text-muted-foreground mt-1">Collect, manage and share authentic video testimonials from your customers.</p>
          </div>
          <div class="flex items-center gap-3">
            <!-- Widget Button -->
            <button
              @click="isWidgetModalOpen = true"
              class="inline-flex items-center gap-2 h-9 px-3.5 rounded-lg border border-border bg-card text-[13.5px] font-medium text-foreground hover:bg-muted shadow-xs cursor-pointer"
            >
              <LayoutGrid class="size-4" /> Widget
            </button>

            <!-- Request Video Button -->
            <button 
              @click="handleRequestTestimonial" 
              class="h-9 gap-2 shadow-xs bg-primary hover:bg-primary/90 text-primary-foreground text-[13px] font-semibold px-4 rounded-lg inline-flex items-center cursor-pointer transition-colors"
            >
              <Play class="size-4 fill-current" /> 
              Request Video Testimonial
            </button>
          </div>
        </div>
        
        <!-- Top 5 KPI Cards -->
        <div class="grid grid-cols-2 md:grid-cols-5 gap-4 mt-8">
          <div class="bg-card border border-border rounded-xl p-4 shadow-xs flex flex-col justify-between">
            <div class="flex items-center gap-3 mb-2">
              <div class="size-8 rounded-full bg-primary/10 text-primary flex items-center justify-center border border-primary/20">
                <Play class="size-4" />
              </div>
              <span class="text-2xl font-bold text-foreground">{{ stats.total }}</span>
            </div>
            <span class="text-xs text-muted-foreground font-medium">Total Videos</span>
          </div>
          
          <div class="bg-card border border-border rounded-xl p-4 shadow-xs flex flex-col justify-between">
            <div class="flex items-center gap-3 mb-2">
              <div class="size-8 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center border border-emerald-100 dark:bg-emerald-900/30 dark:border-emerald-800 dark:text-emerald-400">
                <CheckCircle class="size-4" />
              </div>
              <span class="text-2xl font-bold text-foreground">{{ stats.publishedPct }}%</span>
            </div>
            <span class="text-xs text-muted-foreground font-medium">Published</span>
          </div>
          
          <div class="bg-card border border-border rounded-xl p-4 shadow-xs flex flex-col justify-between">
            <div class="flex items-center gap-3 mb-2">
              <div class="size-8 rounded-full bg-amber-50 text-amber-500 flex items-center justify-center border border-amber-100 dark:bg-amber-900/30 dark:border-amber-800 dark:text-amber-400">
                <Star class="size-4 fill-amber-500 text-amber-500" />
              </div>
              <span class="text-2xl font-bold text-foreground">{{ stats.avgRating }}</span>
            </div>
            <span class="text-xs text-muted-foreground font-medium">Average Rating</span>
          </div>
          
          <div class="bg-card border border-border rounded-xl p-4 shadow-xs flex flex-col justify-between">
            <div class="flex items-center gap-3 mb-2">
              <div class="size-8 rounded-full bg-rose-50 text-rose-500 flex items-center justify-center border border-rose-100 dark:bg-rose-900/30 dark:border-rose-800 dark:text-rose-400">
                <Calendar class="size-4" />
              </div>
              <span class="text-2xl font-bold text-foreground">{{ stats.awaiting }}</span>
            </div>
            <span class="text-xs text-muted-foreground font-medium">Awaiting Approval</span>
          </div>
          
          <div class="bg-card border border-border rounded-xl p-4 shadow-xs flex flex-col justify-between">
            <div class="flex items-center gap-3 mb-2">
              <div class="size-8 rounded-full bg-primary/10 text-primary flex items-center justify-center border border-primary/20">
                <Sparkles class="size-4" />
              </div>
              <span class="text-2xl font-bold text-foreground">—</span>
            </div>
            <span class="text-xs text-muted-foreground font-medium">Relay AI Highlights</span>
          </div>
        </div>
      </div>

      <!-- Filters & Toolbar -->
      <div class="px-8 py-5 border-b border-border bg-background shrink-0 sticky top-0 z-10 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div class="flex flex-wrap items-center gap-2">
          <div class="relative w-48 mr-2">
            <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              v-model="searchQuery"
              type="text"
              placeholder="Search videos..."
              class="w-full pl-9 bg-card border-border shadow-xs h-9 text-xs rounded-lg"
            />
          </div>
          
          <!-- Platform Filter -->
          <div class="relative">
            <button 
              @click="showPlatformDropdown = !showPlatformDropdown"
              class="h-9 gap-1.5 rounded-lg text-xs font-medium bg-card border border-border shadow-xs px-3 hover:bg-muted inline-flex items-center cursor-pointer text-foreground"
            >
              Platform <ChevronDown class="size-3.5 text-muted-foreground shrink-0" />
            </button>
            <div v-if="showPlatformDropdown" class="absolute left-0 mt-1.5 w-40 bg-card border border-border rounded-xl p-1 shadow-xl z-50 space-y-0.5">
              <button v-for="p in ['All Platforms', 'Google', 'Facebook', 'Yelp', 'Trustpilot']" :key="p" @click="setPlatformFilter(p)" class="w-full text-left px-3 py-1.5 text-xs rounded-md font-medium hover:bg-muted text-foreground cursor-pointer">{{ p }}</button>
            </div>
          </div>

          <!-- Rating Filter -->
          <div class="relative">
            <button 
              @click="showRatingDropdown = !showRatingDropdown"
              class="h-9 gap-1.5 rounded-lg text-xs font-medium bg-card border border-border shadow-xs px-3 hover:bg-muted inline-flex items-center cursor-pointer text-foreground"
            >
              Rating <ChevronDown class="size-3.5 text-muted-foreground shrink-0" />
            </button>
            <div v-if="showRatingDropdown" class="absolute left-0 mt-1.5 w-44 bg-card border border-border rounded-xl p-1 shadow-xl z-50 space-y-0.5">
              <button v-for="r in ['5 Stars', '4 Stars & Up', '3 Stars & Up', '2 Stars & Below']" :key="r" @click="setRatingFilter(r)" class="w-full text-left px-3 py-1.5 text-xs rounded-md font-medium hover:bg-muted text-foreground cursor-pointer">{{ r }}</button>
            </div>
          </div>

          <!-- Duration Filter -->
          <div class="relative">
            <button 
              @click="showDurationDropdown = !showDurationDropdown"
              class="h-9 gap-1.5 rounded-lg text-xs font-medium bg-card border border-border shadow-xs px-3 hover:bg-muted inline-flex items-center cursor-pointer text-foreground"
            >
              Duration <ChevronDown class="size-3.5 text-muted-foreground shrink-0" />
            </button>
            <div v-if="showDurationDropdown" class="absolute left-0 mt-1.5 w-36 bg-card border border-border rounded-xl p-1 shadow-xl z-50 space-y-0.5">
              <button v-for="d in ['< 30s', '30s - 1m', '> 1m']" :key="d" @click="showDurationDropdown = false" class="w-full text-left px-3 py-1.5 text-xs rounded-md font-medium hover:bg-muted text-foreground cursor-pointer">{{ d }}</button>
            </div>
          </div>

          <!-- Status Filter -->
          <div class="relative">
            <button 
              @click="showStatusDropdown = !showStatusDropdown"
              class="h-9 gap-1.5 rounded-lg text-xs font-medium bg-card border border-border shadow-xs px-3 hover:bg-muted inline-flex items-center cursor-pointer text-foreground"
            >
              Status <ChevronDown class="size-3.5 text-muted-foreground shrink-0" />
            </button>
            <div v-if="showStatusDropdown" class="absolute left-0 mt-1.5 w-40 bg-card border border-border rounded-xl p-1 shadow-xl z-50 space-y-0.5">
              <button v-for="s in ['Approved', 'Pending Approval', 'Published', 'Rejected']" :key="s" @click="setStatusFilter(s)" class="w-full text-left px-3 py-1.5 text-xs rounded-md font-medium hover:bg-muted text-foreground cursor-pointer">{{ s }}</button>
            </div>
          </div>

          <!-- AI Tags Filter (B7) — real topics from AI analysis; demo-flag only -->
          <div v-if="showDemoSurfaces" class="relative">
            <button
              @click="showAiTagsDropdown = !showAiTagsDropdown"
              class="h-9 gap-1.5 rounded-lg text-xs font-medium shadow-xs px-3 inline-flex items-center cursor-pointer"
              :class="activeTag ? 'bg-primary/10 border border-primary/20 text-primary' : 'bg-card border border-border hover:bg-muted text-foreground'"
            >
              {{ activeTag || 'Relay AI Tags' }} <ChevronDown class="size-3.5 shrink-0" :class="activeTag ? 'text-primary' : 'text-muted-foreground'" />
            </button>
            <div v-if="showAiTagsDropdown" class="absolute left-0 mt-1.5 w-44 max-h-64 overflow-y-auto bg-card border border-border rounded-xl p-1 shadow-xl z-50 space-y-0.5">
              <button @click="setTagFilter('All Tags')" class="w-full text-left px-3 py-1.5 text-xs rounded-md font-medium hover:bg-muted text-foreground cursor-pointer">All Tags</button>
              <p v-if="!availableTags.length" class="px-3 py-1.5 text-xs text-muted-foreground">No AI tags yet — analyze a video.</p>
              <button v-for="tag in availableTags" :key="tag" @click="setTagFilter(tag)" class="w-full text-left px-3 py-1.5 text-xs rounded-md font-medium hover:bg-muted text-foreground cursor-pointer">{{ tag }}</button>
            </div>
          </div>
        </div>
        
        <div class="flex items-center gap-3">
          <div class="relative">
            <button 
              @click="showSortDropdown = !showSortDropdown"
              class="h-9 gap-1.5 rounded-lg text-xs font-medium bg-card border border-border shadow-xs px-3 hover:bg-muted inline-flex items-center cursor-pointer text-foreground"
            >
              Newest First <ChevronDown class="size-3.5 text-muted-foreground shrink-0" />
            </button>
            <div v-if="showSortDropdown" class="absolute right-0 mt-1.5 w-40 bg-card border border-border rounded-xl p-1 shadow-xl z-50 space-y-0.5">
              <button v-for="sort in ['Newest First', 'Oldest First', 'Highest Rating', 'Most Views']" :key="sort" @click="setSortFilter(sort)" class="w-full text-left px-3 py-1.5 text-xs rounded-md font-medium hover:bg-muted text-foreground cursor-pointer">{{ sort }}</button>
            </div>
          </div>
        </div>
      </div>
      
      <div class="px-8 py-4 flex items-center justify-between text-xs text-muted-foreground font-medium">
        Showing {{ filteredVideos.length }} of {{ stats.total }} videos
        <div class="flex bg-card border border-border rounded-lg p-0.5 shadow-xs">
          <button @click="viewMode = 'grid'" class="p-1.5 rounded-md transition-colors cursor-pointer" :class="viewMode === 'grid' ? 'bg-muted text-foreground' : 'text-muted-foreground hover:text-foreground hover:bg-muted'"><LayoutGrid class="size-4" /></button>
          <button @click="viewMode = 'list'" class="p-1.5 rounded-md transition-colors cursor-pointer" :class="viewMode === 'list' ? 'bg-muted text-foreground' : 'text-muted-foreground hover:text-foreground hover:bg-muted'"><List class="size-4" /></button>
          <button @click="viewMode = 'timeline'" class="p-1.5 rounded-md transition-colors cursor-pointer" :class="viewMode === 'timeline' ? 'bg-muted text-foreground' : 'text-muted-foreground hover:text-foreground hover:bg-muted'"><Clock class="size-4" /></button>
        </div>
      </div>

      <!-- Video Grid Area -->
      <div class="px-8 pb-10">
        <div 
          class="grid gap-6 transition-all"
          :class="[
            viewMode === 'list' ? 'grid-cols-1' : '',
            viewMode === 'timeline' ? 'grid-cols-1 border-l-2 border-primary/20 ml-[130px] pl-8' : '',
            viewMode === 'grid' && selectedVideo ? 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-3' : '',
            viewMode === 'grid' && !selectedVideo ? 'grid-cols-1 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-4' : ''
          ]"
        >
          <div 
            v-for="video in filteredVideos" 
            :key="video.id"
            class="relative"
          >
            <!-- Timeline dot -->
            <div v-if="viewMode === 'timeline'" class="absolute -left-[38.5px] top-8 size-3.5 rounded-full bg-primary ring-4 ring-background transition-colors z-10" :class="selectedVideo?.id === video.id ? 'ring-primary/20 scale-125' : ''"></div>
            
            <!-- Timeline Date Label -->
            <div v-if="viewMode === 'timeline' && video.timelineDate" class="absolute -left-[145px] top-6 w-[90px] text-left z-10">
              <div class="font-bold text-foreground text-[13.5px]">{{ video.timelineDate.title }}</div>
              <div class="text-xs text-muted-foreground mt-0.5">{{ video.timelineDate.sub }}</div>
            </div>
            
            <!-- Card Body -->
            <div 
              @click="selectVideo(video)"
              class="bg-card border rounded-xl overflow-hidden hover:shadow-md transition-all duration-300 group flex cursor-pointer relative"
              :class="[
                selectedVideo?.id === video.id ? 'border-primary ring-1 ring-primary shadow-md scale-[1.02]' : 'border-border shadow-xs scale-100',
                (viewMode === 'list' || viewMode === 'timeline') ? 'flex-col sm:flex-row' : 'flex-col h-full'
              ]"
            >
              <!-- Thumbnail & Player overlay -->
              <div 
                class="relative bg-muted overflow-hidden shrink-0 border-b sm:border-b-0 sm:border-r border-border"
                :class="(viewMode === 'list' || viewMode === 'timeline') ? 'w-full sm:w-56 aspect-video' : 'w-full aspect-[4/3]'"
              >
                <img :src="video.thumbnail" class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105" />
                <div class="absolute inset-0 bg-black/10 group-hover:bg-black/30 transition-colors flex items-center justify-center">
                  <div class="size-12 rounded-full bg-white/90 backdrop-blur-xs flex items-center justify-center text-foreground shadow-lg transform transition-transform group-hover:scale-110">
                    <Play class="size-5 ml-1 fill-current opacity-80" />
                  </div>
                </div>
                
                <!-- Top Left Platform Icon (14px SVG) -->
                <div class="absolute top-3 left-3 bg-white size-7 rounded-full flex items-center justify-center shadow-md overflow-hidden p-1.5" v-html="getPlatformIcon(video.platform)"></div>
                
                <!-- Bottom Right Duration -->
                <div class="absolute bottom-3 right-3 px-2 py-1 bg-black/70 backdrop-blur-xs rounded text-[10px] font-bold text-white tracking-wider shadow-xs">
                  {{ video.duration }}
                </div>
              </div>

              <!-- Content (Grid) -->
              <div v-if="viewMode === 'grid'" class="p-4 flex flex-col flex-1 min-w-0">
                <div class="flex items-start justify-between mb-2 gap-2">
                  <h3 class="font-bold text-[13px] text-foreground truncate flex-1">{{ video.author }}</h3>
                  <div class="flex text-amber-400 shrink-0 mt-0.5">
                    <Star
                      v-for="i in 5"
                      :key="i"
                      class="size-3"
                      :class="i <= Math.round(video.rating || 0) ? 'fill-amber-400 text-amber-400' : 'text-muted-foreground/30'"
                    />
                  </div>
                </div>
                
                <div class="flex items-center gap-1.5 text-xs text-muted-foreground mb-4">
                  <span>{{ video.platform }}</span>
                  <span class="size-1 rounded-full bg-muted-foreground/30"></span>
                  <span>{{ video.date }}</span>
                </div>
                
                <div class="mt-auto flex items-center justify-between gap-2">
                  <div class="flex flex-wrap gap-2">
                    <Badge v-for="tag in video.aiTags.filter(t => t !== 'AI Summary')" :key="tag" 
                      class="inline-flex items-center transition-colors focus:outline-none focus:ring-1 focus:ring-ring shadow-none font-medium text-[10px] px-2 py-0.5 rounded-md border"
                      :class="
                        tag === 'Approved' ? 'bg-emerald-50 text-emerald-600 border-emerald-100 dark:bg-emerald-900/30 dark:border-emerald-900/50' : 
                        tag === 'Published' ? 'bg-primary/10 text-primary border-primary/20 dark:bg-primary/10 dark:border-primary/20' : 
                        'bg-amber-50 text-amber-600 border-amber-100 dark:bg-amber-900/30 dark:border-amber-900/50'
                      "
                    >
                      {{ tag }}
                    </Badge>
                  </div>
                  
                  <button class="h-6 text-[10px] text-primary font-semibold opacity-0 group-hover:opacity-100 transition-opacity px-2 gap-1 bg-primary/10 hover:bg-primary/20 rounded-md inline-flex items-center shrink-0 cursor-pointer" @click.stop="selectVideo(video)">
                    <Sparkles class="size-3" /> Summarize
                  </button>
                </div>
              </div>

              <!-- Content (List / Timeline) -->
              <div v-else class="p-6 flex flex-col sm:flex-row flex-1 min-w-0 gap-6 items-start relative">
                <!-- Author Info Column -->
                <div class="flex flex-col w-[200px] shrink-0">
                  <h3 class="font-bold text-[14.5px] text-foreground mb-2">{{ video.author }}</h3>

                  <div class="flex text-amber-400 shrink-0 mb-3">
                    <Star
                      v-for="i in 5"
                      :key="i"
                      class="size-3.5"
                      :class="i <= Math.round(video.rating || 0) ? 'fill-amber-400 text-amber-400' : 'text-muted-foreground/30'"
                    />
                  </div>
                  <Badge
                    class="inline-flex items-center transition-colors focus:outline-none focus:ring-1 focus:ring-ring shadow-none font-medium text-[10.5px] px-2.5 py-0.5 rounded-full border w-max mb-1"
                    :class="
                      video.status === 'Approved' ? 'bg-emerald-50 text-emerald-600 border-emerald-100 dark:bg-emerald-900/30 dark:border-emerald-900/50' : 
                      video.status === 'Published' ? 'bg-primary/10 text-primary border-primary/20 dark:bg-primary/10 dark:border-primary/20' : 
                      'bg-amber-50 text-amber-600 border-amber-100 dark:bg-amber-900/30 dark:border-amber-900/50'
                    "
                  >
                    {{ video.status }}
                  </Badge>
                  <div class="text-[11.5px] text-muted-foreground font-medium mt-2">{{ video.date }}</div>
                </div>
                
                <!-- Transcript Summary Column -->
                <div class="flex-1 min-w-0 pr-4 mt-1">
                  <p class="text-[13px] leading-relaxed text-muted-foreground line-clamp-3 italic">
                    "{{ video.transcriptSummary }}"
                  </p>
                </div>

                <!-- Topics Column -->
                <div class="w-[180px] shrink-0 mt-1">
                  <h4 class="text-[11px] font-bold text-muted-foreground mb-3">Topics</h4>
                  <div class="flex flex-wrap gap-2">
                    <Badge v-for="topic in video.topics.slice(0, 3)" :key="topic" class="bg-muted text-muted-foreground border border-border shadow-none font-medium text-[11px] px-2.5 py-1 rounded-full">
                      {{ topic }}
                    </Badge>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Loading -->
        <div v-if="loading" class="p-16 flex flex-col items-center justify-center gap-3 text-muted-foreground">
          <div class="size-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
          <p class="text-[13.5px]">Loading video testimonials…</p>
        </div>

        <!-- Empty State matching AGENTS.md rule 6 (text-[20px] font-[600]) -->
        <div v-else-if="filteredVideos.length === 0" class="p-12 text-center text-muted-foreground flex flex-col items-center">
          <Play class="size-10 opacity-20 mb-3" />
          <h3 class="text-[20px] font-[600] text-foreground mb-1">No video testimonials yet</h3>
          <p class="text-[13.5px] text-muted-foreground leading-relaxed mb-4">Request a video from a happy customer to see it here.</p>
          <button @click="handleRequestTestimonial" class="px-4 py-2 rounded-lg bg-primary text-primary-foreground text-[13.5px] font-semibold hover:bg-primary/90 transition-colors cursor-pointer inline-flex items-center gap-1.5">
            <Play class="size-4 fill-current" /> Request Video Testimonial
          </button>
        </div>
      </div>
    </div>
    
    <!-- Side Panel (Master-Detail Video Panel) -->
    <div 
      class="h-full min-h-0 min-w-0 border-l border-border bg-card transition-all duration-300 shadow-2xl lg:shadow-none absolute lg:relative right-0 flex flex-col z-40"
      :class="selectedVideo ? 'w-full sm:w-[450px] lg:w-[35%] xl:w-[30%] translate-x-0' : 'w-full sm:w-[450px] lg:w-[35%] xl:w-[30%] translate-x-full lg:hidden hidden'"
    >
      <div v-if="selectedVideo" class="flex flex-col h-full min-h-0 overflow-hidden">
        <!-- Header -->
        <div class="px-6 py-4 border-b border-border flex items-center justify-between shrink-0 bg-muted/20">
          <div class="flex items-center gap-3">
            <div class="size-6 bg-white rounded-full overflow-hidden flex items-center justify-center shrink-0 p-1 border border-border" v-html="getPlatformIcon(selectedVideo.platform)"></div>
            <h2 class="font-bold text-foreground text-sm">{{ selectedVideo.author }}</h2>
            <Badge v-if="insights.marketing_score >= 70" class="bg-primary/10 text-primary border border-primary/20 shadow-none font-medium text-[10px] px-2 py-0.5 rounded-md ml-1">Marketing Ready</Badge>
          </div>
          <button class="p-1.5 text-muted-foreground hover:text-foreground rounded-lg hover:bg-muted cursor-pointer" @click="closePanel">
            <X class="size-4" />
          </button>
        </div>
        
          <!-- Tabs Nav -->
          <div class="px-6 border-b border-border flex gap-4 text-[13px] font-semibold shrink-0 pt-2 bg-card overflow-x-auto hide-scrollbar" role="tablist">
            <button
              v-for="tab in DETAIL_TABS" :key="tab"
              type="button"
              role="tab"
              :aria-selected="activeTab === tab"
              class="relative -mb-px py-3 px-0.5 whitespace-nowrap shrink-0 cursor-pointer bg-transparent border-0"
              :class="activeTab === tab ? 'text-primary' : 'text-muted-foreground hover:text-foreground'"
              @click.stop="selectTab(tab)"
            >
              {{ tab }}
              <span v-if="activeTab === tab" class="absolute inset-x-0 bottom-0 h-0.5 bg-primary" aria-hidden="true" />
            </button>
          </div>
        
        <div class="flex-1 min-h-0 overflow-y-auto bg-card">
          <!-- Tab Content -->
          <div class="p-6 space-y-6">
            <div v-if="activeTab === 'Overview'" class="space-y-6">
              <div class="-mx-6 -mt-6">
                <div class="w-full bg-black relative aspect-video max-h-[120px] group">
                  <video
                    v-if="selectedVideo.videoUrl"
                    :key="selectedVideo.id"
                    :src="selectedVideo.videoUrl"
                    :poster="selectedVideo.thumbnail"
                    class="w-full h-full object-contain"
                    controls
                    playsinline
                  />
                  <template v-else>
                    <img :src="selectedVideo.thumbnail" class="w-full h-full object-cover opacity-80" />
                    <div class="absolute inset-0 flex items-center justify-center">
                      <span class="text-white/70 text-xs font-medium">Video not available</span>
                    </div>
                  </template>
                </div>
                <div class="px-6 py-3 border-b border-border flex items-center justify-between text-xs font-medium text-muted-foreground bg-card">
                  <div class="flex items-center gap-4">
                    <span class="flex items-center gap-1.5"><div class="size-3.5 flex items-center justify-center" v-html="getPlatformIcon(selectedVideo.platform)"></div> {{ selectedVideo.platform }}</span>
                    <span class="flex items-center gap-1.5"><Calendar class="size-3.5 opacity-70" /> {{ selectedVideo.date }}</span>
                    <span class="flex items-center gap-1.5"><Clock class="size-3.5 opacity-70" /> {{ selectedVideo.duration }}</span>
                  </div>
                  <div class="flex text-amber-400">
                    <Star
                      v-for="i in 5"
                      :key="i"
                      class="size-3"
                      :class="i <= Math.round(selectedVideo.rating || 0) ? 'fill-amber-400 text-amber-400' : 'text-muted-foreground/30'"
                    />
                  </div>
                </div>
              </div>
              <!-- AI Summary Box -->
              <div class="space-y-2.5">
                <h3 class="text-xs font-bold tracking-wide text-foreground flex items-center gap-2">
                  <div class="size-5 rounded-full bg-primary/10 text-primary flex items-center justify-center"><Sparkles class="size-3" /></div>
                  Relay AI Summary
                </h3>
                <div v-if="selectedVideo.transcriptSummary" class="bg-muted/30 border border-border/50 rounded-xl p-4 text-[13px] text-muted-foreground leading-relaxed">
                  {{ selectedVideo.transcriptSummary }}
                </div>
                <div v-else class="bg-muted/30 border border-border/50 rounded-xl p-4 text-center space-y-2">
                  <p class="text-[13px] text-muted-foreground">{{ analyzing ? 'Analyzing this video…' : 'No summary yet.' }}</p>
                  <button v-if="!analyzing" type="button" class="inline-flex items-center gap-1.5 text-[13px] font-semibold text-primary hover:underline" @click="analyzeVideo">
                    <Sparkles class="size-4" /> Analyze video
                  </button>
                </div>
              </div>
              
              <!-- Topics Box -->
              <div class="space-y-3">
                <h3 class="text-xs font-bold tracking-wide text-foreground">Topics</h3>
                <div v-if="selectedVideo.topics.length" class="flex flex-wrap gap-2">
                  <Badge v-for="topic in selectedVideo.topics" :key="topic" class="bg-muted text-muted-foreground border border-border shadow-none font-medium text-xs px-3 py-1 rounded-full">
                    {{ topic }}
                  </Badge>
                </div>
                <p v-else class="text-[13px] text-muted-foreground">No topics yet. Analyze the video to extract them.</p>
              </div>
              
              <!-- Suggested Reply Box -->
              <div class="space-y-2.5">
                <div class="flex items-center justify-between">
                  <h3 class="text-xs font-bold tracking-wide text-primary flex items-center gap-1.5">
                    <div class="size-5 rounded-full bg-primary/10 text-primary flex items-center justify-center"><Sparkles class="size-3 fill-current" /></div>
                    Suggested Reply
                  </h3>
                  <button type="button" class="text-[11px] font-semibold text-primary hover:text-primary/90 cursor-pointer" @click="handleGenerateNew">Generate New</button>
                </div>
                <div class="bg-card border border-primary/20 rounded-xl p-4 shadow-xs relative group">
                  <p class="text-[13px] text-muted-foreground leading-relaxed mb-4 whitespace-pre-line">{{ displayedReply }}</p>
                  <div class="flex justify-end">
                    <button type="button" class="h-7 text-xs font-semibold border border-primary/30 text-primary hover:bg-primary/10 rounded-md px-3 cursor-pointer" @click="handleUseReply">
                      Use this Reply
                    </button>
                  </div>
                </div>
              </div>
            </div>
            
            <div v-else-if="activeTab === 'Transcript'">
              <p v-if="insights.transcript" class="text-[13px] leading-relaxed text-foreground whitespace-pre-wrap">{{ insights.transcript }}</p>
              <div v-else class="flex flex-col items-center justify-center text-center py-10 gap-3">
                <Bot class="size-8 text-muted-foreground" />
                <p v-if="analyzing" class="text-[13px] text-muted-foreground">Transcribing this video… this can take a moment.</p>
                <p v-else-if="insights.error" class="text-[13px] text-muted-foreground">Couldn't transcribe: {{ insights.error }}</p>
                <p v-else class="text-[13px] text-muted-foreground">No transcript yet.</p>
                <button v-if="!analyzing" type="button" @click="analyzeVideo" class="inline-flex items-center gap-1.5 text-[13px] font-semibold text-primary hover:underline">
                  <Sparkles class="size-4" /> Analyze video
                </button>
              </div>
            </div>

            <div v-else-if="activeTab === 'AI Insights'" class="space-y-6">
              <template v-if="hasInsights && !insights.error">
                <p v-if="insights.summary" class="text-[13px] leading-relaxed text-foreground">{{ insights.summary }}</p>

                <div class="grid grid-cols-2 gap-4">
                  <div class="bg-muted/30 border border-border rounded-xl p-4">
                    <div class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider mb-2">Sentiment</div>
                    <div class="flex items-end gap-1"><span class="text-xl font-bold text-foreground">{{ insights.sentiment }}%</span></div>
                  </div>
                  <div class="bg-muted/30 border border-border rounded-xl p-4">
                    <div class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider mb-2">Marketing Score</div>
                    <div class="flex items-center gap-2">
                      <div class="flex-1 h-2 bg-muted rounded-full overflow-hidden">
                        <div class="h-full bg-emerald-500 rounded-full" :style="{ width: (insights.marketing_score || 0) + '%' }"></div>
                      </div>
                      <span class="text-xs font-bold text-foreground">{{ insights.marketing_score }}%</span>
                    </div>
                  </div>
                </div>

                <div v-if="insights.topics && insights.topics.length" class="space-y-2">
                  <div class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider px-1">Topics</div>
                  <div class="flex flex-wrap gap-2">
                    <span v-for="t in insights.topics" :key="t" class="text-[12px] font-medium text-foreground bg-muted px-2.5 py-1 rounded-full">{{ t }}</span>
                  </div>
                </div>

                <div v-if="insights.quotable" class="space-y-2">
                  <div class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider px-1">Most Quotable Line</div>
                  <div class="bg-primary/5 border border-primary/20 rounded-xl p-4 relative">
                    <Quote class="absolute top-3 right-3 size-4 text-primary/30" />
                    <p class="text-[14px] font-medium text-foreground pr-6 leading-relaxed italic">"{{ insights.quotable }}"</p>
                  </div>
                </div>

                <div v-if="insights.suggested_reply" class="space-y-2">
                  <div class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider px-1">Suggested Reply</div>
                  <div class="bg-muted/30 border border-border rounded-xl p-4">
                    <p class="text-[13px] leading-relaxed text-foreground">{{ insights.suggested_reply }}</p>
                  </div>
                </div>
              </template>

              <div v-else class="flex flex-col items-center justify-center text-center py-10 gap-3">
                <Sparkles class="size-8 text-muted-foreground" />
                <p v-if="analyzing" class="text-[13px] text-muted-foreground">Analyzing this video…</p>
                <p v-else-if="insights.error" class="text-[13px] text-muted-foreground">Couldn't analyze: {{ insights.error }}</p>
                <p v-else class="text-[13px] text-muted-foreground">No AI insights yet.</p>
                <button v-if="!analyzing" type="button" @click="analyzeVideo" class="inline-flex items-center gap-1.5 text-[13px] font-semibold text-primary hover:underline">
                  <Sparkles class="size-4" /> Analyze video
                </button>
              </div>
            </div>

            <div v-else-if="activeTab === 'Activity'" class="pb-10">
              <div v-if="timeline.length === 0" class="text-[13px] text-muted-foreground text-center py-10">
                No activity yet.
              </div>
              <div v-else class="relative border-l-2 border-border ml-2.5 pl-6 space-y-6">
                <div v-for="event in timeline" :key="event.key" class="relative">
                  <div class="absolute -left-[35.5px] top-0 size-6 rounded-full flex items-center justify-center ring-4 ring-white dark:ring-card" :class="event.dot">
                    <component :is="iconFor(event.key)" class="size-3.5" :class="event.ic" />
                  </div>
                  <div class="font-medium text-[13.5px] text-foreground">{{ event.label }}</div>
                  <div class="text-[11px] text-muted-foreground mt-0.5">{{ event.at }}</div>
                </div>
              </div>
            </div>
            
            <div v-else-if="activeTab === 'Notes'">
              <div class="flex items-center gap-2 text-foreground font-semibold text-[15px] mb-2">
                <FileText class="size-4" /> Notes
              </div>
              <p class="text-[13px] text-muted-foreground mb-4">
                Collaborate with your team about this testimonial.
              </p>

              <div class="space-y-3 mb-4">
                <div v-for="(note, i) in (selectedVideo?.notes || [])" :key="i" class="rounded-lg border border-border bg-muted/30 p-3">
                  <div class="flex items-center justify-between mb-1">
                    <span class="text-[12px] font-semibold text-foreground">{{ note.author }}</span>
                    <span class="text-[11px] text-muted-foreground">{{ formatEventTime(note.at) }}</span>
                  </div>
                  <p class="text-[13px] text-foreground whitespace-pre-line">{{ note.body }}</p>
                </div>
                <div v-if="!(selectedVideo?.notes || []).length" class="text-xs text-muted-foreground text-center py-4">No notes yet.</div>
              </div>

              <div class="border-t border-border pt-4 space-y-2">
                <textarea v-model="noteDraft" rows="3" placeholder="Add a note for your team…" class="w-full rounded-lg border border-border bg-background p-3 text-[13px] focus:outline-none focus:ring-1 focus:ring-primary/30 resize-none"></textarea>
                <button @click="addNote" :disabled="savingNote || !noteDraft.trim()" class="h-8 px-4 text-xs font-semibold bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 disabled:opacity-50 cursor-pointer inline-flex items-center gap-1.5">
                  <Plus class="size-3.5" /> {{ savingNote ? 'Saving…' : 'Add Note' }}
                </button>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Footer Actions -->
        <div class="p-4 border-t border-border bg-card shrink-0 space-y-2">
          <div class="flex flex-wrap gap-2">
            <RelayButton class="h-9 flex-1 px-2.5 text-xs" @click="handleReply">
              <MessageSquare class="size-4" /> Reply
            </RelayButton>
            <RelayButton variant="outline" class="h-9 flex-1 px-2.5 text-xs" @click="handleShare">
              <Share2 class="size-3.5" /> Share
            </RelayButton>
            <RelayButton variant="outline" class="h-9 flex-1 px-2.5 text-xs" @click="handleDownload">
              <Download class="size-3.5" /> Download
            </RelayButton>
            <RelayButton variant="outline" size="icon" class="h-9 w-9 shrink-0" title="Copy embed code" @click="handleEmbed">
              <MoreHorizontal class="size-4" />
            </RelayButton>
          </div>

          <div class="flex flex-wrap items-center gap-2">
            <div class="relative min-w-0 flex-1">
              <button
                type="button"
                class="inline-flex h-9 w-full min-w-0 items-center justify-between gap-1.5 rounded-lg border px-3 text-xs font-semibold cursor-pointer"
                :class="selectedVideo.status === 'Approved' || selectedVideo.status === 'Published' ? 'text-emerald-600 dark:text-emerald-400 border-emerald-500/20 bg-emerald-500/10' : 'text-amber-600 dark:text-amber-400 border-amber-500/20 bg-amber-500/10'"
                @click="showDetailStatusDropdown = !showDetailStatusDropdown"
              >
                <span class="truncate">{{ selectedVideo.status }}</span>
                <ChevronDown class="size-3 opacity-50 shrink-0" />
              </button>
              <div v-if="showDetailStatusDropdown" class="absolute bottom-full mb-1.5 left-0 w-44 bg-popover text-popover-foreground border border-border rounded-md p-1 shadow-md z-50 space-y-0.5">
                <button type="button" class="w-full text-left px-2 py-1.5 text-sm rounded-sm hover:bg-accent hover:text-accent-foreground cursor-pointer flex items-center justify-between" @click="handleStatusChange('Approved')">
                  <span>Approved</span>
                  <Check v-if="selectedVideo.status === 'Approved'" class="size-3.5 text-emerald-600" />
                </button>
                <button type="button" class="w-full text-left px-2 py-1.5 text-sm rounded-sm hover:bg-accent hover:text-accent-foreground cursor-pointer flex items-center justify-between" @click="handleStatusChange('Published')">
                  <span>Published</span>
                  <Check v-if="selectedVideo.status === 'Published'" class="size-3.5 text-emerald-600" />
                </button>
                <button type="button" class="w-full text-left px-2 py-1.5 text-sm rounded-sm hover:bg-accent hover:text-accent-foreground cursor-pointer flex items-center justify-between" @click="handleStatusChange('Pending Approval')">
                  <span>Pending Approval</span>
                  <Check v-if="selectedVideo.status === 'Pending Approval'" class="size-3.5 text-amber-600" />
                </button>
                <button type="button" class="w-full text-left px-2 py-1.5 text-sm rounded-sm hover:bg-accent hover:text-accent-foreground cursor-pointer flex items-center justify-between" @click="handleStatusChange('Rejected')">
                  <span>Rejected</span>
                  <Check v-if="selectedVideo.status === 'Rejected'" class="size-3.5 text-rose-600" />
                </button>
              </div>
            </div>

            <div class="flex gap-2 shrink-0">
              <RelayButton variant="outline" class="h-9 px-2.5 text-xs" @click="handleEdit">
                <Edit class="size-3.5" /> Edit
              </RelayButton>
              <RelayButton variant="outline" class="h-9 px-2.5 text-xs text-destructive border-destructive/20 hover:bg-destructive/10 hover:text-destructive hover:border-transparent" @click="handleDelete">
                <Trash2 class="size-3.5" /> Delete
              </RelayButton>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div
      class="fixed bottom-6 right-6 z-50 bg-foreground text-background px-4 py-3 rounded-xl shadow-2xl font-medium text-xs transition-all duration-300 transform flex items-center gap-2"
      :class="toastState.visible ? 'translate-y-0 opacity-100' : 'translate-y-4 opacity-0 pointer-events-none'"
    >
      <CheckCircle class="size-4 text-emerald-400" />
      {{ toastState.message }}
    </div>
  </div>
</template>
