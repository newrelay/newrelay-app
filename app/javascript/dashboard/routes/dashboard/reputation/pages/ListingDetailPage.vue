<!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
<script setup>
/* eslint-disable */
import { ref, computed, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { isReputationDemoSurfacesEnabled } from 'dashboard/featureFlags';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import {
  ArrowLeft,
  Building2,
  Layers,
  TrendingUp,
  RotateCw,
  Pencil,
  MoreHorizontal,
  ChevronDown,
  MapPin,
  Phone,
  Globe,
  Tag,
  Mail,
  Clock,
  Camera,
  Check,
  CheckCircle2,
  AlertTriangle,
  Activity,
  Compass,
  Image as ImageIcon,
  Star,
  ArrowRight,
  Sparkles,
  Users,
} from 'lucide-vue-next';
import ListingMembersPanel from '../components/ListingMembersPanel.vue';
import {
  RelayButton,
  RelayInput,
  RelayTextarea,
  RelayCheckbox,
  RelayDropdownMenu as DropdownMenu,
  RelayDropdownMenuTrigger as DropdownMenuTrigger,
  RelayDropdownMenuContent as DropdownMenuContent,
  RelayDropdownMenuItem as DropdownMenuItem,
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_HEADER_CLASS,
  RELAY_MODAL_TITLE_CLASS,
  RELAY_MODAL_DESCRIPTION_CLASS,
  RELAY_FORM_FIELD_CLASS,
  RELAY_FORM_LABEL_CLASS,
} from 'dashboard/components-next/relay';

const route = useRoute();
const router = useRouter();
const axios = window.axios;

const storeAccountId = useMapGetter('getCurrentAccountId');
const accountId = computed(
  () => storeAccountId.value || window.location.pathname.match(/accounts\/(\d+)/)?.[1]
);
const isFeatureEnabledonAccount = useMapGetter('accounts/isFeatureEnabledonAccount');
const showDemoSurfaces = computed(() =>
  isReputationDemoSurfacesEnabled(accountId.value, isFeatureEnabledonAccount.value)
);
const baseUrl = () => `/api/v1/accounts/${accountId.value}/reputation`;

const googleIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>`;
const facebookIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" fill="#1877F2"/></svg>`;
const yelpIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg" fill="#E00707"><path d="M12.271 8.782c-.549-3.804-.822-5.72-.822-5.748 0-.888-.622-1.641-1.537-1.887A2.34 2.34 0 0 0 7.3 2.52L3.473 7.337a2.01 2.01 0 0 0-.302 1.895c.28.72.934 1.218 1.695 1.282l5.894.488c1.038.087 1.871-.767 1.511-2.22zm-8.245 6.253l5.374 2.186c1.004.409 2.084-.332 2.084-1.41V11.38c0-1.088-1.096-1.83-2.104-1.41l-5.374 2.185a1.85 1.85 0 0 0-1.148 1.44 1.855 1.855 0 0 0 1.168 1.44zm6.406 5.978l-3.218-4.874a1.796 1.796 0 0 0-2.97-.095 1.855 1.855 0 0 0-.17 1.98l2.28 4.374a2.316 2.316 0 0 0 2.492 1.208 2.302 2.302 0 0 0 1.586-2.593zm9.56-10.826a2.31 2.31 0 0 0-1.92-1.435l-5.916-.489a1.796 1.796 0 0 0-1.493 2.874l3.42 4.96a1.803 1.803 0 0 0 2.8.217l3.477-4.046a2.02 2.02 0 0 0 .368-.654 2.004 2.004 0 0 0-.736-1.427zm-2.278 7.916l-2.277-4.373a1.804 1.804 0 0 0-3.124.149 1.789 1.789 0 0 0 .057 1.695l3.218 4.874a2.305 2.305 0 0 0 2.534.938 2.316 2.316 0 0 0 1.57-2.593 2.31 2.31 0 0 0-1.978-0.69z"/></svg>`;
const trustpilotIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" fill="#00B67A" rx="2" ry="2"/><path d="M12 4l2.5 5.2 5.7.8-4.1 4 1 5.7-5.1-2.7-5.1 2.7 1-5.7-4.1-4 5.7-.8L12 4z" fill="#FFF"/></svg>`;
const bingIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg"><path d="M9.82 2.14L3.6 0v16l6.22 2.18V2.14zM20.4 7.64l-8.6 3v9.54l8.6-2.58V7.64z" fill="#008373"/></svg>`;
const platformIcons = { Google: googleIcon, Facebook: facebookIcon, Yelp: yelpIcon, Trustpilot: trustpilotIcon, Bing: bingIcon };
const getPlatformIcon = name => platformIcons[name] || googleIcon;

const GRADIENTS = [
  'from-blue-500 to-indigo-600',
  'from-emerald-500 to-teal-600',
  'from-rose-500 to-pink-600',
  'from-amber-500 to-orange-600',
];
const gradientFor = key => {
  const s = String(key || 'L');
  let h = 0;
  for (let i = 0; i < s.length; i += 1) h = s.charCodeAt(i) + ((h << 5) - h);
  return GRADIENTS[Math.abs(h) % GRADIENTS.length];
};

const mockListings = [
  {
    id: 1,
    title: 'Jaipur HQ',
    badge: 'Primary',
    address: 'Gopalpura Bypass, Jaipur, Rajasthan 302018',
    image: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=600&auto=format&fit=crop',
    optimizationScore: 94,
    rating: 4.8,
    reviewsCount: 582,
    lastSync: '2 mins ago',
    phone: '+91 141 123 4567',
    website: 'www.example.com',
    email: '',
    category: 'Digital Marketing Agency',
    platforms: [
      { name: 'Google', status: 'Connected' },
      { name: 'Facebook', status: 'Connected' },
      { name: 'Trustpilot', status: 'Connected' },
      { name: 'Yelp', status: 'Not Connected' },
      { name: 'Bing', status: 'Error' },
    ],
  },
  {
    id: 2,
    title: 'Delhi Branch',
    badge: '',
    address: 'Connaught Place, New Delhi, Delhi 110001',
    image: 'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=600&auto=format&fit=crop',
    optimizationScore: 89,
    rating: 4.6,
    reviewsCount: 412,
    lastSync: '15 mins ago',
    phone: '+91 11 9876 5432',
    website: 'www.example-delhi.com',
    email: '',
    category: 'Digital Marketing Agency',
    platforms: [
      { name: 'Google', status: 'Connected' },
      { name: 'Facebook', status: 'Connected' },
      { name: 'Trustpilot', status: 'Connected' },
      { name: 'Yelp', status: 'Not Connected' },
      { name: 'Bing', status: 'Connected' },
    ],
  },
  {
    id: 3,
    title: 'Mumbai Office',
    badge: '',
    address: 'Andheri East, Mumbai, Maharashtra 400069',
    image: 'https://images.unsplash.com/photo-1430285561322-7808604715df?q=80&w=600&auto=format&fit=crop',
    optimizationScore: 76,
    rating: 4.3,
    reviewsCount: 298,
    lastSync: '1 hour ago',
    phone: '+91 22 2345 6789',
    website: 'www.example-mumbai.com',
    email: '',
    category: 'Marketing Consultant',
    platforms: [
      { name: 'Google', status: 'Connected' },
      { name: 'Facebook', status: 'Connected' },
      { name: 'Trustpilot', status: 'Connected' },
      { name: 'Yelp', status: 'Not Connected' },
      { name: 'Bing', status: 'Connected' },
    ],
  },
];

function mapListing(row) {
  return {
    id: row.id,
    title: row.name || row.title,
    badge: row.primary || row.badge === 'Primary' ? 'Primary' : row.badge || '',
    address: row.address || '',
    category: row.category || '',
    country: row.country || '',
    phone: row.phone || '',
    website: row.website || '',
    email: row.email || '',
    image: row.image || '',
    description: row.description || '',
    additionalCategories: row.additional_categories || '',
    serviceArea: row.service_area || '',
    hours: row.hours || {},
    holidayHours: row.holiday_hours || [],
    amenities: row.amenities || {},
    socialLinks: row.social_links || {},
    photoUrls: row.photo_urls || [],
    optimizationScore: row.optimized ?? row.optimizationScore ?? 90,
    rating: row.rating || 4.5,
    reviewsCount: row.reviews ?? row.reviewsCount ?? 0,
    lastSync: row.lastSync || (row.synced_at ? new Date(row.synced_at).toLocaleString() : 'Just now'),
    syncedAt: row.synced_at || null,
    createdAt: row.created_at || row.createdAt || null,
    updatedAt: row.updated_at || row.updatedAt || null,
  };
}

const loading = ref(true);
const usingMock = ref(false);
const listing = ref(null);
const activeTab = ref('Overview');
const busy = ref(false);
const editOpen = ref(false);
const WEEKDAYS = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
const AMENITY_OPTIONS = [
  { key: 'wheelchair_accessible', label: 'Wheelchair Accessible' },
  { key: 'free_wifi', label: 'Free WiFi' },
  { key: 'on_site_parking', label: 'On-site Parking' },
  { key: 'outdoor_seating', label: 'Outdoor Seating' },
];
const SOCIAL_PLATFORMS = [
  { key: 'facebook', label: 'Facebook', icon: 'facebook' },
  { key: 'instagram', label: 'Instagram', icon: 'instagram' },
  { key: 'linkedin', label: 'LinkedIn', icon: 'linkedin' },
];
function blankEditForm() {
  return {
    name: '', address: '', phone: '', website: '', email: '', category: '',
    description: '', additionalCategories: '', serviceArea: '',
    hours: Object.fromEntries(WEEKDAYS.map(d => [d, ''])),
    amenities: Object.fromEntries(AMENITY_OPTIONS.map(a => [a.key, false])),
    socialLinks: Object.fromEntries(SOCIAL_PLATFORMS.map(s => [s.key, ''])),
  };
}
const editForm = ref(blankEditForm());

// Real per-listing platform connections — reputation_integrations now carries a
// listing_id (see AddListingToReputationIntegrations migration), so this is the
// account's real Reputation::Integration rows for this listing, not a fake toggle.
const PROVIDER_LABELS = {
  google: 'Google', facebook: 'Facebook', agoda: 'Agoda', airbnb: 'Airbnb',
  aliexpress: 'AliExpress', amazon: 'Amazon', angi: 'Angi',
  apple_app_store: 'Apple App Store', avvo: 'Avvo', custom: 'Custom',
};
const listingIntegrations = ref([]);
async function loadListingIntegrations() {
  const id = route.params.listingId;
  try {
    const { data } = await axios.get(`${baseUrl()}/integrations?listing_id=${id}`);
    listingIntegrations.value = data || [];
  } catch {
    listingIntegrations.value = [];
  }
}
const connectedPlatforms = computed(() =>
  listingIntegrations.value.map(i => ({
    id: i.id,
    name: i.location_name || PROVIDER_LABELS[i.provider] || i.provider,
    status: i.status === 'active' ? 'Connected' : 'Not Connected',
  }))
);
const connectedCount = computed(() => listingIntegrations.value.filter(i => i.status === 'active').length);
const platformTotal = computed(() => listingIntegrations.value.length);
const disconnectedPlatforms = computed(() => connectedPlatforms.value.filter(p => p.status !== 'Connected'));

async function disconnectIntegration(integrationId) {
  if (!confirm('Disconnect this platform?')) return;
  try {
    await axios.delete(`${baseUrl()}/integrations/${integrationId}`);
    await loadListingIntegrations();
    useAlert('Platform disconnected');
  } catch {
    useAlert('Failed to disconnect platform');
  }
}

function goToConnectPlatform() {
  router.push({ name: 'reputation_integrations', query: { listing_id: listing.value?.id } });
}
const websiteHref = computed(() => {
  const url = listing.value?.website;
  if (!url) return '';
  return /^https?:\/\//i.test(url) ? url : `https://${url}`;
});
const editValid = computed(() => !!editForm.value.name?.trim());

// Real activity log — Reputation::Listing is now `audited` (enterprise/app/models/
// enterprise/audit/listing.rb), so every create/update is recorded with a real
// field-level diff and the acting user. Audits only exist from the point audited
// was enabled onward, so a listing with none yet falls back to its own
// created_at/updated_at/synced_at timestamps.
const activityAudits = ref([]);
async function loadActivities() {
  const id = route.params.listingId;
  try {
    const { data } = await axios.get(`${baseUrl()}/listings/${id}/activities`);
    activityAudits.value = data || [];
  } catch {
    activityAudits.value = [];
  }
}

function describePlatformChange(change) {
  const [before, after] = change;
  const beforeMap = new Map((before || []).map(p => [p.name, p.ok]));
  const diffs = (after || [])
    .filter(p => beforeMap.get(p.name) !== p.ok)
    .map(p => `${p.name} ${p.ok ? 'connected' : 'disconnected'}`);
  return diffs.length ? diffs.join(', ') : 'Platform connections updated';
}

function describeAudit(audit) {
  if (audit.action === 'create') return 'Listing created';
  if (audit.action === 'destroy') return 'Listing deleted';
  const changes = audit.audited_changes || {};
  if (changes.platforms) return describePlatformChange(changes.platforms);
  if (changes.name) return `Renamed to "${changes.name[1]}"`;
  const fields = Object.keys(changes).filter(k => k !== 'name');
  return fields.length ? `Updated ${fields.join(', ')}` : 'Listing details updated';
}

function auditTone(audit) {
  if (audit.action === 'create') return 'bg-primary/10 text-primary';
  const changes = audit.audited_changes || {};
  if (changes.platforms) {
    const [before, after] = changes.platforms;
    const beforeMap = new Map((before || []).map(p => [p.name, p.ok]));
    const nowDisconnected = (after || []).some(p => beforeMap.get(p.name) === true && p.ok === false);
    return nowDisconnected
      ? 'bg-rose-100 text-rose-600 dark:bg-rose-950 dark:text-rose-400'
      : 'bg-emerald-100 text-emerald-600 dark:bg-emerald-950 dark:text-emerald-400';
  }
  return 'bg-amber-100 text-amber-600 dark:bg-amber-950 dark:text-amber-400';
}

function auditIcon(audit) {
  if (audit.action === 'create') return Building2;
  const changes = audit.audited_changes || {};
  if (changes.platforms) return RotateCw;
  return Pencil;
}

const activityEvents = computed(() => {
  if (activityAudits.value.length) {
    return activityAudits.value.map(audit => ({
      key: audit.id,
      icon: auditIcon(audit),
      tone: auditTone(audit),
      label: describeAudit(audit),
      actor: audit.username || null,
      time: audit.created_at,
    }));
  }
  // No audit trail yet (listing untouched since audited was enabled) — fall back
  // to the listing's own real timestamps rather than showing nothing.
  if (!listing.value) return [];
  const events = [];
  if (listing.value.createdAt) {
    events.push({ key: 'created', icon: Building2, tone: 'bg-primary/10 text-primary', label: 'Listing created', time: listing.value.createdAt });
  }
  if (listing.value.updatedAt && listing.value.updatedAt !== listing.value.createdAt) {
    events.push({ key: 'updated', icon: Pencil, tone: 'bg-amber-100 text-amber-600 dark:bg-amber-950 dark:text-amber-400', label: 'Listing details updated', time: listing.value.updatedAt });
  }
  if (listing.value.syncedAt) {
    events.push({ key: 'synced', icon: RotateCw, tone: 'bg-emerald-100 text-emerald-600 dark:bg-emerald-950 dark:text-emerald-400', label: 'Platforms synced', time: listing.value.syncedAt });
  }
  return events.sort((a, b) => new Date(b.time) - new Date(a.time));
});

// Real AI insights, scoped to this listing's reviews via listing_id.
const aiInsights = ref(null);
const aiInsightsLoading = ref(false);
async function loadAiInsights() {
  if (aiInsights.value || aiInsightsLoading.value) return;
  aiInsightsLoading.value = true;
  try {
    const { data } = await axios.get(`${baseUrl()}/ai_insights?listing_id=${route.params.listingId}`);
    aiInsights.value = data && data.sentiment != null
      ? { topics: [], keywords: [], suggestions: [], ...data }
      : null;
  } catch {
    aiInsights.value = null;
  } finally {
    aiInsightsLoading.value = false;
  }
}
const sentimentLabel = computed(() => {
  const s = aiInsights.value?.sentiment;
  if (s == null) return '';
  if (s >= 80) return 'Highly Positive';
  if (s >= 60) return 'Positive';
  if (s >= 40) return 'Mixed';
  return 'Needs Attention';
});
watch(activeTab, tab => {
  if (tab === 'Insights') loadAiInsights();
});

const tabs = [
  { id: 'Overview', icon: Compass },
  { id: 'Listing Info', icon: Building2 },
  { id: 'Connections', icon: Layers },
  { id: 'Insights', icon: TrendingUp },
  { id: 'Team', icon: Users },
  { id: 'Activity', icon: Activity },
];

function goBack() {
  router.push({ name: 'reputation_listings' });
}

async function loadListing() {
  loading.value = true;
  usingMock.value = false;
  const id = route.params.listingId;
  try {
    const { data } = await axios.get(`${baseUrl()}/listings/${id}`);
    listing.value = mapListing(data);
  } catch {
    usingMock.value = true;
    const mock = mockListings.find(l => String(l.id) === String(id)) || mockListings[0];
    listing.value = mapListing(mock);
  } finally {
    loading.value = false;
  }
}

// Reviews for this listing's connected platforms only (reputation_reviews joins
// through reputation_integration -> reputation_listing_id).
const accountReviews = ref([]);
async function loadAccountReviews() {
  const id = route.params.listingId;
  try {
    const { data } = await axios.get(`${baseUrl()}/reviews?listing_id=${id}`);
    accountReviews.value = data || [];
  } catch {
    accountReviews.value = [];
  }
}
const recentReviews = computed(() => accountReviews.value.slice(0, 3));
const reviewStats = computed(() => {
  const rows = accountReviews.value;
  const total = rows.length;
  const avgRating = total ? (rows.reduce((s, r) => s + (r.rating || 0), 0) / total).toFixed(1) : '—';
  const needsReply = rows.filter(r => r.status === 'pending' && !(r.reputation_review_reply && r.reputation_review_reply.body)).length;
  return { total, avgRating, needsReply };
});
// Real weekly review counts for the last 5 weeks (no fabricated trend deltas).
const weeklyTrend = computed(() => {
  const now = Date.now();
  const week = 7 * 86400000;
  const buckets = [4, 3, 2, 1, 0].map(i => ({ start: now - (i + 1) * week, end: now - i * week, count: 0 }));
  accountReviews.value.forEach(r => {
    if (!r.reviewed_at) return;
    const t = new Date(r.reviewed_at).getTime();
    const bucket = buckets.find(b => t >= b.start && t < b.end);
    if (bucket) bucket.count += 1;
  });
  return buckets;
});
const trendMax = computed(() => Math.max(1, ...weeklyTrend.value.map(b => b.count)));
const trendPoints = computed(() =>
  weeklyTrend.value
    .map((b, i) => `${(i / 4) * 100},${100 - (b.count / trendMax.value) * 90}`)
    .join(' ')
);
function relativeDate(dateStr) {
  if (!dateStr) return '';
  const diff = Date.now() - new Date(dateStr).getTime();
  const days = Math.floor(diff / 86400000);
  if (days < 1) return 'Today';
  if (days === 1) return '1 day ago';
  if (days < 7) return `${days} days ago`;
  return `${Math.floor(days / 7)}w ago`;
}
function reviewHasReply(review) {
  return !!(review.reputation_review_reply && review.reputation_review_reply.body);
}

function openEdit() {
  if (!listing.value) return;
  editForm.value = {
    name: listing.value.title || '',
    address: listing.value.address || '',
    phone: listing.value.phone || '',
    website: listing.value.website || '',
    email: listing.value.email || '',
    category: listing.value.category || '',
    description: listing.value.description || '',
    additionalCategories: listing.value.additionalCategories || '',
    serviceArea: listing.value.serviceArea || '',
    hours: { ...Object.fromEntries(WEEKDAYS.map(d => [d, ''])), ...listing.value.hours },
    amenities: { ...Object.fromEntries(AMENITY_OPTIONS.map(a => [a.key, false])), ...listing.value.amenities },
    socialLinks: { ...Object.fromEntries(SOCIAL_PLATFORMS.map(s => [s.key, ''])), ...listing.value.socialLinks },
  };
  editOpen.value = true;
}

async function saveEdit() {
  if (!editValid.value || !listing.value) return;
  busy.value = true;
  const patch = {
    name: editForm.value.name.trim(),
    address: editForm.value.address.trim(),
    phone: editForm.value.phone.trim(),
    website: editForm.value.website.trim(),
    email: editForm.value.email.trim(),
    category: editForm.value.category.trim(),
    description: editForm.value.description.trim(),
    additional_categories: editForm.value.additionalCategories.trim(),
    service_area: editForm.value.serviceArea.trim(),
    hours: editForm.value.hours,
    amenities: editForm.value.amenities,
    social_links: editForm.value.socialLinks,
  };
  try {
    if (!usingMock.value) {
      const { data } = await axios.patch(`${baseUrl()}/listings/${listing.value.id}`, patch);
      listing.value = mapListing(data);
      loadActivities();
    } else {
      Object.assign(listing.value, {
        title: patch.name,
        address: patch.address,
        phone: patch.phone,
        website: patch.website,
        email: patch.email,
        category: patch.category,
        description: patch.description,
        additionalCategories: patch.additional_categories,
        serviceArea: patch.service_area,
        hours: patch.hours,
        amenities: patch.amenities,
        socialLinks: patch.social_links,
      });
    }
    editOpen.value = false;
    useAlert('Listing updated');
  } catch {
    useAlert('Failed to update listing');
  } finally {
    busy.value = false;
  }
}

async function addHolidayHours() {
  if (!listing.value) return;
  const date = window.prompt('Holiday date (e.g. Dec 25, 2026)');
  if (!date || !date.trim()) return;
  const label = window.prompt('Hours for that day (e.g. "Closed" or "10:00 AM - 2:00 PM")', 'Closed');
  if (label == null) return;
  const next = [...listing.value.holidayHours, { date: date.trim(), label: label.trim() }];
  try {
    if (!usingMock.value) {
      const { data } = await axios.patch(`${baseUrl()}/listings/${listing.value.id}`, { holiday_hours: next });
      listing.value = mapListing(data);
    } else {
      listing.value.holidayHours = next;
    }
  } catch {
    useAlert('Failed to add holiday hours');
  }
}

const uploadingPhotos = ref(false);
async function uploadPhotos(event) {
  const files = event.target.files;
  if (!files || !files.length || !listing.value || usingMock.value) return;
  uploadingPhotos.value = true;
  const formData = new FormData();
  Array.from(files).forEach(file => formData.append('photos[]', file));
  try {
    const { data } = await axios.post(`${baseUrl()}/listings/${listing.value.id}/photos`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    listing.value = mapListing(data);
    useAlert('Photos uploaded');
  } catch {
    useAlert('Failed to upload photos');
  } finally {
    uploadingPhotos.value = false;
    event.target.value = '';
  }
}

async function renameListing() {
  const name = window.prompt('Rename listing', listing.value.title);
  if (!name || !name.trim() || name.trim() === listing.value.title) return;
  editForm.value = {
    name: name.trim(),
    address: listing.value.address,
    phone: listing.value.phone,
    website: listing.value.website,
    email: listing.value.email,
    category: listing.value.category,
  };
  await saveEdit();
}

async function duplicateListing() {
  busy.value = true;
  try {
    if (!usingMock.value) {
      await axios.post(`${baseUrl()}/listings`, {
        name: `${listing.value.title} (Copy)`,
        address: listing.value.address,
        category: listing.value.category,
        country: listing.value.country,
        phone: listing.value.phone,
        website: listing.value.website,
        email: listing.value.email,
        image: listing.value.image,
        description: listing.value.description,
        additional_categories: listing.value.additionalCategories,
        service_area: listing.value.serviceArea,
        hours: listing.value.hours,
        amenities: listing.value.amenities,
        social_links: listing.value.socialLinks,
      });
    }
    useAlert('Listing duplicated');
    goBack();
  } catch {
    useAlert('Failed to duplicate listing');
  } finally {
    busy.value = false;
  }
}

async function deleteListing() {
  if (!confirm(`Delete ${listing.value.title}? This cannot be undone.`)) return;
  busy.value = true;
  try {
    if (!usingMock.value) await axios.delete(`${baseUrl()}/listings/${listing.value.id}`);
    useAlert('Listing deleted');
    goBack();
  } catch {
    useAlert('Failed to delete listing');
  } finally {
    busy.value = false;
  }
}

const syncing = ref(false);
async function syncNow() {
  if (!listing.value || usingMock.value || syncing.value) return;
  syncing.value = true;
  try {
    await axios.post(`${baseUrl()}/integrations/sync_all?listing_id=${listing.value.id}`);
    await Promise.all([loadListingIntegrations(), loadAccountReviews()]);
    useAlert(`Synced ${listing.value.title}`);
  } catch {
    useAlert('Failed to sync');
  } finally {
    syncing.value = false;
  }
}

function formatDate(d) {
  return d ? new Date(d).toLocaleString() : '—';
}

onMounted(() => {
  if (!showDemoSurfaces.value) {
    router.replace({ name: 'reputation_overview' });
    return;
  }
  loadListing();
  loadAccountReviews();
  loadActivities();
  loadListingIntegrations();
});

watch(() => route.params.listingId, () => {
  if (showDemoSurfaces.value) {
    loadListing();
    loadAccountReviews();
    loadActivities();
    loadListingIntegrations();
    aiInsights.value = null;
    if (activeTab.value === 'Insights') loadAiInsights();
  }
});
</script>

<template>
  <div class="flex flex-col h-[calc(100vh-4rem)] w-full overflow-hidden bg-background">
    <div v-if="loading" class="flex-1 flex items-center justify-center text-sm text-muted-foreground">
      Loading listing...
    </div>

    <template v-else-if="listing">
      <div class="px-8 pt-4 bg-card shrink-0 shadow-xs z-10 relative border-b border-border">
        <div class="flex items-center text-sm font-semibold text-muted-foreground mb-4">
          <button type="button" class="hover:text-foreground flex items-center gap-1.5 transition-colors" @click="goBack">
            <ArrowLeft class="size-4" /> Back to Listings
          </button>
        </div>

        <div class="flex flex-col xl:flex-row xl:items-start justify-between gap-6">
          <div class="flex gap-5">
            <div class="size-24 shrink-0 relative bg-muted rounded-xl shadow-xs border border-border overflow-hidden">
              <img v-if="listing.image" :src="listing.image" class="w-full h-full object-cover" @error="listing.image = ''" />
              <div
                v-else
                class="w-full h-full flex items-center justify-center bg-gradient-to-br text-white"
                :class="gradientFor(listing.title)"
              >
                <ImageIcon class="size-7 opacity-80" />
              </div>
            </div>

            <div class="flex flex-col justify-center">
              <div class="flex items-center gap-3 mb-2">
                <h1 class="text-base font-medium text-foreground tracking-tight">{{ listing.title }}</h1>
                <span
                  v-if="listing.badge"
                  class="bg-primary/10 text-primary border border-primary/20 font-semibold text-[11px] px-2.5 py-0.5 rounded-full"
                >
                  {{ listing.badge }}
                </span>
                <span
                  v-if="usingMock"
                  class="rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400"
                >Demo</span>
              </div>
              <div class="flex items-center gap-2 text-sm text-muted-foreground mb-2 font-medium">
                <div class="size-5 bg-card rounded-full flex items-center justify-center border border-border shadow-xs" v-html="getPlatformIcon('Google')"></div>
                Google Business Profile
              </div>
              <div class="flex items-center gap-2 text-sm text-muted-foreground font-medium">
                <MapPin class="size-4" />
                {{ listing.address || 'No address yet' }}
              </div>
            </div>
          </div>

          <div class="flex flex-col items-start xl:items-end gap-4">
            <div class="flex items-center gap-3">
              <RelayButton variant="outline" class="h-9 gap-2 text-xs font-semibold px-4" :disabled="busy || syncing" @click="syncNow">
                <RotateCw class="size-3.5" :class="syncing ? 'animate-spin' : ''" /> {{ syncing ? 'Syncing…' : 'Sync Now' }}
              </RelayButton>
              <RelayButton class="h-9 gap-2 text-xs font-semibold px-4" :disabled="busy" @click="openEdit">
                <Pencil class="size-3.5" /> Edit Listing
              </RelayButton>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <RelayButton variant="outline" class="h-9 gap-2 text-xs font-semibold px-4">
                    <MoreHorizontal class="size-4" /> More <ChevronDown class="size-3.5 opacity-50" />
                  </RelayButton>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" class="w-48">
                  <DropdownMenuItem @click="renameListing">Rename</DropdownMenuItem>
                  <DropdownMenuItem @click="duplicateListing">Duplicate</DropdownMenuItem>
                  <DropdownMenuItem class="text-rose-600 focus:text-rose-600" @click="deleteListing">Delete</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex items-center gap-3 border border-border rounded-xl px-3 py-2 shadow-xs bg-card">
                <Star class="size-5 text-amber-400 fill-amber-400 shrink-0" />
                <div class="flex flex-col">
                  <span class="text-[16px] font-bold text-foreground leading-tight">{{ listing.rating }}</span>
                  <span class="text-[11px] font-medium text-muted-foreground">{{ listing.reviewsCount }} Reviews</span>
                </div>
              </div>
              <div class="flex items-center gap-3 border border-border rounded-xl px-3 py-2 shadow-xs bg-card">
                <Layers class="size-5 text-primary shrink-0" />
                <div class="flex flex-col">
                  <span class="text-[16px] font-bold text-foreground leading-tight">{{ connectedCount }}/{{ platformTotal }}</span>
                  <span class="text-[11px] font-medium text-muted-foreground">Platforms Connected</span>
                </div>
              </div>
              <div class="flex items-center gap-3 border border-border rounded-xl px-3 py-2 shadow-xs bg-card">
                <RotateCw class="size-5 text-muted-foreground shrink-0" />
                <div class="flex flex-col">
                  <span class="text-[11px] font-medium text-muted-foreground">Last Sync</span>
                  <span class="text-[13px] font-bold text-foreground leading-tight">{{ listing.lastSync }}</span>
                </div>
                <div class="size-5 rounded-full bg-emerald-50 text-emerald-500 border border-emerald-200 dark:bg-emerald-950 dark:border-emerald-800 flex items-center justify-center shrink-0 ml-2">
                  <Check class="size-3.5 stroke-[3]" />
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="flex gap-8 text-[14px] font-medium mt-4 border-b border-border overflow-x-auto" role="tablist">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            type="button"
            role="tab"
            :aria-selected="activeTab === tab.id"
            class="relative -mb-px py-3 transition-colors whitespace-nowrap flex items-center gap-2 bg-transparent"
            :class="activeTab === tab.id ? 'text-primary' : 'text-muted-foreground hover:text-foreground'"
            @click="activeTab = tab.id"
          >
            <component :is="tab.icon" class="size-4" />
            {{ tab.id }}
            <span v-if="activeTab === tab.id" class="absolute inset-x-0 bottom-0 h-0.5 bg-primary" aria-hidden="true" />
          </button>
        </div>
      </div>

      <div class="flex-1 overflow-y-auto p-8">
        <div v-if="activeTab === 'Overview'" class="flex flex-col gap-6 pb-12">
          <div class="bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col gap-6">
            <div class="flex items-center justify-between">
              <h3 class="text-base font-medium text-foreground">Listing Snapshot</h3>
              <RelayButton variant="ghost" class="h-8 gap-2 text-[13px] text-primary font-semibold px-3" @click="openEdit">
                <Pencil class="size-3.5" /> Edit Information
              </RelayButton>
            </div>
            <div class="grid grid-cols-2 lg:grid-cols-4 gap-8">
              <div class="flex items-start gap-4">
                <div class="size-10 bg-primary/10 text-primary rounded-full flex items-center justify-center shrink-0">
                  <MapPin class="size-5" />
                </div>
                <div class="flex flex-col gap-1">
                  <span class="text-foreground font-medium text-[15px]">Address</span>
                  <span class="text-[14px] text-muted-foreground leading-relaxed">{{ listing.address || '—' }}</span>
                </div>
              </div>
              <div class="flex items-start gap-4">
                <div class="size-10 bg-primary/10 text-primary rounded-full flex items-center justify-center shrink-0">
                  <Phone class="size-5" />
                </div>
                <div class="flex flex-col gap-1">
                  <span class="text-foreground font-medium text-[15px]">Phone</span>
                  <span class="text-[14px] text-muted-foreground leading-relaxed">{{ listing.phone || '—' }}</span>
                </div>
              </div>
              <div class="flex items-start gap-4">
                <div class="size-10 bg-primary/10 text-primary rounded-full flex items-center justify-center shrink-0">
                  <Globe class="size-5" />
                </div>
                <div class="flex flex-col gap-1">
                  <span class="text-foreground font-medium text-[15px]">Website</span>
                  <a v-if="websiteHref" :href="websiteHref" target="_blank" rel="noopener" class="text-[14px] text-primary hover:underline leading-relaxed">{{ listing.website }}</a>
                  <span v-else class="text-[14px] text-muted-foreground">—</span>
                </div>
              </div>
              <div class="flex items-start gap-4">
                <div class="size-10 bg-primary/10 text-primary rounded-full flex items-center justify-center shrink-0">
                  <Tag class="size-5" />
                </div>
                <div class="flex flex-col gap-1">
                  <span class="text-foreground font-medium text-[15px]">Category</span>
                  <span class="text-[14px] text-muted-foreground leading-relaxed">{{ listing.category || '—' }}</span>
                </div>
              </div>
            </div>

            <div class="flex flex-col gap-4">
              <span class="text-[13px] font-medium text-foreground">Photos</span>
              <div v-if="listing.image" class="flex gap-4">
                <img :src="listing.image" class="h-[120px] w-[180px] object-cover rounded-xl shadow-xs border border-border shrink-0" />
              </div>
              <p v-else class="text-[13px] text-muted-foreground">No photos yet.</p>
            </div>
          </div>

          <div class="bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col gap-6">
            <div class="flex items-center justify-between">
              <h3 class="text-base font-medium text-foreground">Connected Platforms</h3>
              <RelayButton variant="ghost" class="h-8 text-[13px] text-primary font-semibold px-3" @click="activeTab = 'Connections'">
                Manage All
              </RelayButton>
            </div>
            <div v-if="!connectedPlatforms.length" class="text-[13px] text-muted-foreground py-2">
              No platforms connected yet.
              <button type="button" class="text-primary font-semibold hover:underline" @click="goToConnectPlatform">Connect one</button>
            </div>
            <div v-else class="flex gap-4 overflow-x-auto pb-2">
              <div
                v-for="platform in connectedPlatforms"
                :key="platform.id"
                class="flex flex-col justify-between p-5 border rounded-xl min-w-[260px] bg-card shadow-xs"
                :class="platform.status === 'Connected' ? 'border-border' : 'border-rose-200/60 dark:border-rose-900/40'"
              >
                <div class="flex items-center gap-3">
                  <div class="size-10 border border-border rounded-lg bg-card flex items-center justify-center shrink-0" v-html="getPlatformIcon(platform.name)"></div>
                  <div class="flex flex-col gap-0.5">
                    <span class="text-[14px] font-medium text-foreground">{{ platform.name }}</span>
                    <span class="text-[12px] font-medium" :class="platform.status === 'Connected' ? 'text-muted-foreground' : 'text-rose-500'">
                      {{ platform.status === 'Connected' ? `Last Sync: ${listing.lastSync}` : 'Action required' }}
                    </span>
                  </div>
                </div>
                <div class="flex items-center justify-between mt-5 pt-4 border-t border-border/50">
                  <span
                    class="px-2.5 py-0.5 rounded-full font-semibold text-[11px] inline-flex items-center gap-1"
                    :class="platform.status === 'Connected' ? 'bg-emerald-50 text-emerald-600 dark:bg-emerald-950 dark:text-emerald-400' : 'bg-rose-100 text-rose-600 dark:bg-rose-950 dark:text-rose-400'"
                  >
                    <CheckCircle2 v-if="platform.status === 'Connected'" class="size-3" />
                    <AlertTriangle v-else class="size-3" />
                    {{ platform.status === 'Connected' ? 'Connected' : 'Not Connected' }}
                  </span>
                  <button
                    v-if="platform.status === 'Connected'"
                    type="button"
                    class="h-6 px-2 text-[11px] font-semibold text-rose-600"
                    @click="disconnectIntegration(platform.id)"
                  >
                    Disconnect
                  </button>
                  <button v-else type="button" class="h-6 px-2 text-[11px] font-semibold text-primary" @click="goToConnectPlatform">
                    Reconnect
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Recent Reviews (this listing's connected platforms only) -->
          <div class="bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col gap-6">
            <div class="flex items-center justify-between">
              <h3 class="text-base font-medium text-foreground">Recent Reviews</h3>
              <RelayButton variant="ghost" class="h-8 gap-2 text-[13px] text-primary font-semibold px-3" @click="router.push({ name: 'reputation_reviews' })">
                View All Reviews <ArrowRight class="size-3.5" />
              </RelayButton>
            </div>
            <div v-if="!recentReviews.length" class="text-[13px] text-muted-foreground py-4 text-center">No reviews yet.</div>
            <div v-else class="flex flex-col gap-6">
              <div v-for="review in recentReviews" :key="review.id" class="flex items-start gap-4 pb-6 border-b border-border/50 last:border-0 last:pb-0">
                <div class="size-10 shrink-0 bg-card border border-border rounded-full flex items-center justify-center p-2 shadow-xs" v-html="getPlatformIcon((review.provider || 'google').charAt(0).toUpperCase() + (review.provider || 'google').slice(1))"></div>
                <div class="flex-1 flex flex-col gap-1 min-w-0">
                  <div class="flex items-center gap-4 flex-wrap">
                    <span class="text-[14px] font-medium text-foreground">{{ review.reviewer_name || 'Anonymous' }}</span>
                    <div class="flex gap-0.5 text-amber-400">
                      <Star v-for="i in 5" :key="i" class="size-3.5" :class="i <= (review.rating || 0) ? 'fill-amber-400' : 'text-muted-foreground/30'" />
                    </div>
                    <span class="text-[12px] font-medium text-muted-foreground">{{ relativeDate(review.reviewed_at) }}</span>
                  </div>
                  <p class="text-[13px] font-medium text-muted-foreground leading-relaxed">{{ review.body }}</p>
                </div>
                <span
                  class="px-3 py-0.5 rounded-full font-semibold text-[11px] shrink-0"
                  :class="reviewHasReply(review) ? 'bg-emerald-50 text-emerald-600 dark:bg-emerald-950 dark:text-emerald-400' : 'bg-muted text-muted-foreground'"
                >
                  {{ reviewHasReply(review) ? 'Replied' : 'Pending' }}
                </span>
              </div>
            </div>
          </div>

          <!-- Review Performance (real per-listing review stats, no fabricated trend deltas) -->
          <div class="bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col gap-6">
            <h3 class="text-base font-medium text-foreground">Review Performance</h3>
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div class="border border-border rounded-xl p-4 flex flex-col gap-2">
                <div class="flex items-center gap-2"><Star class="size-4 text-amber-400 fill-amber-400" /><span class="text-[20px] font-semibold text-foreground leading-none">{{ reviewStats.avgRating }}</span></div>
                <span class="text-[12px] font-medium text-muted-foreground">Average Rating</span>
              </div>
              <div class="border border-border rounded-xl p-4 flex flex-col gap-2">
                <span class="text-[20px] font-semibold text-foreground leading-none">{{ reviewStats.total }}</span>
                <span class="text-[12px] font-medium text-muted-foreground">Total Reviews</span>
              </div>
              <div class="border border-border rounded-xl p-4 flex flex-col gap-2">
                <span class="text-[20px] font-semibold text-foreground leading-none">{{ reviewStats.needsReply }}</span>
                <span class="text-[12px] font-medium text-muted-foreground">Needs Replies</span>
              </div>
            </div>
            <div v-if="reviewStats.total" class="relative h-[140px] w-full">
              <svg class="absolute inset-0 size-full" viewBox="0 0 100 100" preserveAspectRatio="none">
                <defs>
                  <linearGradient id="listingTrendGradient" x1="0" x2="0" y1="0" y2="1">
                    <stop offset="0%" stop-color="currentColor" class="text-primary" stop-opacity="0.25" />
                    <stop offset="100%" stop-color="currentColor" class="text-primary" stop-opacity="0.01" />
                  </linearGradient>
                </defs>
                <polygon :points="`0,100 ${trendPoints} 100,100`" fill="url(#listingTrendGradient)" />
                <polyline :points="trendPoints" fill="none" class="stroke-primary" stroke-width="1.5" vector-effect="non-scaling-stroke" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
              <div class="absolute bottom-0 left-0 right-0 flex justify-between text-[11px] font-medium text-muted-foreground translate-y-full pt-2">
                <span v-for="(b, i) in weeklyTrend" :key="i">{{ b.count }}</span>
              </div>
            </div>
          </div>

          <!-- Bottom grid: Business Health + Needs Attention -->
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div class="bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col gap-6">
              <h3 class="text-base font-medium text-foreground">Business Health</h3>
              <div class="flex flex-col items-center gap-4">
                <div class="relative size-28 flex items-center justify-center">
                  <svg class="size-full -rotate-90" viewBox="0 0 100 100">
                    <circle cx="50" cy="50" r="42" fill="none" class="stroke-emerald-50 dark:stroke-emerald-950" stroke-width="8" />
                    <circle cx="50" cy="50" r="42" fill="none" class="stroke-emerald-500" stroke-width="8" stroke-linecap="round"
                      :stroke-dasharray="263.89" :stroke-dashoffset="263.89 - (263.89 * listing.optimizationScore) / 100" />
                  </svg>
                  <div class="absolute inset-0 flex flex-col items-center justify-center">
                    <span class="text-[28px] font-extrabold text-foreground tracking-tight leading-none">{{ listing.optimizationScore }}</span>
                    <span class="text-[11px] font-semibold text-muted-foreground">/100</span>
                  </div>
                </div>
              </div>
              <div class="flex flex-col gap-2.5">
                <div v-if="connectedCount" class="flex items-center gap-3">
                  <CheckCircle2 class="size-4 text-emerald-500 shrink-0" />
                  <span class="text-[12.5px] font-medium text-muted-foreground">Connected to {{ connectedCount }} platform{{ connectedCount === 1 ? '' : 's' }}</span>
                </div>
                <div v-if="listing.address" class="flex items-center gap-3">
                  <CheckCircle2 class="size-4 text-emerald-500 shrink-0" />
                  <span class="text-[12.5px] font-medium text-muted-foreground">Business info is filled in</span>
                </div>
                <div v-for="platform in disconnectedPlatforms" :key="platform.id" class="flex items-center gap-3">
                  <AlertTriangle class="size-4 text-amber-500 shrink-0" />
                  <span class="text-[12.5px] font-medium text-muted-foreground">{{ platform.name }} needs reconnecting</span>
                </div>
              </div>
            </div>

            <div v-if="disconnectedPlatforms.length" class="bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col gap-6">
              <div class="flex items-center justify-between">
                <h3 class="text-base font-medium text-foreground">Needs Attention</h3>
                <span class="bg-rose-50 text-rose-600 dark:bg-rose-950 dark:text-rose-400 px-2 rounded-full font-semibold text-[12px]">{{ disconnectedPlatforms.length }}</span>
              </div>
              <div class="flex flex-col gap-4">
                <div v-for="platform in disconnectedPlatforms" :key="platform.id" class="flex items-start gap-3">
                  <div class="size-8 rounded-full bg-rose-50 dark:bg-rose-950 flex items-center justify-center shrink-0 mt-1">
                    <AlertTriangle class="size-4 text-rose-600" />
                  </div>
                  <div class="flex flex-col gap-0.5 flex-1">
                    <span class="text-[13px] font-medium text-foreground">{{ platform.name }} needs reconnecting</span>
                    <span class="text-[11.5px] text-muted-foreground">Reconnect to keep this listing in sync.</span>
                  </div>
                  <RelayButton variant="outline" class="h-7 text-[11px] font-semibold text-primary px-3 mt-1 shrink-0" @click="goToConnectPlatform">
                    Reconnect
                  </RelayButton>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div v-else-if="activeTab === 'Listing Info'" class="flex flex-col gap-6 pb-12">
          <div class="flex items-center justify-between">
            <div>
              <h2 class="text-base font-medium text-foreground">Listing Information</h2>
              <p class="text-[13px] text-muted-foreground mt-1">Core profile details for this location.</p>
            </div>
            <RelayButton class="gap-2 text-xs font-semibold px-4" @click="openEdit">
              <Pencil class="size-3.5" /> Edit Information
            </RelayButton>
          </div>
          <div class="bg-card border border-border rounded-xl shadow-xs p-6 flex flex-col gap-5">
            <h3 class="text-[15px] font-semibold text-foreground border-b border-border/60 pb-4">Basic Information</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="flex flex-col gap-1.5">
                <span class="text-[13px] font-medium text-foreground">Business Name</span>
                <span class="text-[14px] text-muted-foreground">{{ listing.title }}</span>
              </div>
              <div class="flex flex-col gap-1.5">
                <span class="text-[13px] font-medium text-foreground">Primary Category</span>
                <span v-if="listing.category" class="inline-flex w-fit px-2.5 py-0.5 rounded-full bg-primary/10 text-primary text-[12.5px] font-semibold">{{ listing.category }}</span>
                <span v-else class="text-[14px] text-muted-foreground">—</span>
              </div>
              <div class="flex flex-col gap-1.5">
                <span class="text-[13px] font-medium text-foreground">Additional Categories</span>
                <span class="text-[14px] text-muted-foreground">{{ listing.additionalCategories || '—' }}</span>
              </div>
              <div class="flex flex-col gap-1.5 md:col-span-2">
                <span class="text-[13px] font-medium text-foreground">Business Description</span>
                <p class="text-[14px] text-muted-foreground leading-relaxed">{{ listing.description || '—' }}</p>
              </div>
            </div>
          </div>

          <div class="bg-card border border-border rounded-xl shadow-xs p-6 flex flex-col gap-5">
            <h3 class="text-[15px] font-semibold text-foreground border-b border-border/60 pb-4">Contact Information</h3>
            <div class="flex flex-col gap-5">
              <div class="flex items-start gap-4">
                <Phone class="size-4 text-muted-foreground mt-0.5 shrink-0" />
                <div class="flex flex-col gap-1">
                  <span class="text-[13px] font-medium text-foreground">Phone Number</span>
                  <span class="text-[14px] text-muted-foreground">{{ listing.phone || '—' }}</span>
                </div>
              </div>
              <div class="flex items-start gap-4">
                <Globe class="size-4 text-muted-foreground mt-0.5 shrink-0" />
                <div class="flex flex-col gap-1">
                  <span class="text-[13px] font-medium text-foreground">Website</span>
                  <a v-if="websiteHref" :href="websiteHref" target="_blank" rel="noopener" class="text-[14px] text-primary hover:underline">{{ listing.website }}</a>
                  <span v-else class="text-[14px] text-muted-foreground">—</span>
                </div>
              </div>
              <div class="flex items-start gap-4">
                <Mail class="size-4 text-muted-foreground mt-0.5 shrink-0" />
                <div class="flex flex-col gap-1">
                  <span class="text-[13px] font-medium text-foreground">Email</span>
                  <span class="text-[14px] text-muted-foreground">{{ listing.email || '—' }}</span>
                </div>
              </div>
              <div class="flex items-start gap-4">
                <MapPin class="size-4 text-muted-foreground mt-0.5 shrink-0" />
                <div class="flex flex-col gap-1">
                  <span class="text-[13px] font-medium text-foreground">Address</span>
                  <span class="text-[14px] text-muted-foreground leading-relaxed">{{ listing.address || '—' }}</span>
                </div>
              </div>
              <div class="flex items-start gap-4">
                <MapPin class="size-4 text-emerald-500 mt-0.5 shrink-0" />
                <div class="flex flex-col gap-1">
                  <span class="text-[13px] font-medium text-foreground">Service Area</span>
                  <span class="text-[14px] text-muted-foreground">{{ listing.serviceArea || '—' }}</span>
                </div>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="bg-card border border-border rounded-xl shadow-xs p-6 flex flex-col gap-5">
              <h3 class="text-[15px] font-semibold text-foreground border-b border-border/60 pb-4">Attributes</h3>
              <div v-if="Object.values(listing.amenities).some(Boolean)" class="grid grid-cols-2 gap-4">
                <div v-for="a in AMENITY_OPTIONS.filter(o => listing.amenities[o.key])" :key="a.key" class="flex items-center gap-2.5">
                  <div class="size-5 rounded-full bg-emerald-50 text-emerald-500 flex items-center justify-center shrink-0"><Check class="size-3 stroke-[3]" /></div>
                  <span class="text-[14px] text-muted-foreground font-medium">{{ a.label }}</span>
                </div>
              </div>
              <p v-else class="text-[13.5px] text-muted-foreground">No attributes set yet.</p>
            </div>

            <div class="bg-card border border-border rounded-xl shadow-xs p-6 flex flex-col gap-5">
              <h3 class="text-[15px] font-semibold text-foreground border-b border-border/60 pb-4">Social Links</h3>
              <div v-if="Object.values(listing.socialLinks).some(Boolean)" class="flex flex-col gap-4">
                <div v-for="s in SOCIAL_PLATFORMS.filter(p => listing.socialLinks[p.key])" :key="s.key" class="flex items-center justify-between">
                  <span class="text-[14px] font-semibold text-foreground">{{ s.label }}</span>
                  <a :href="listing.socialLinks[s.key]" target="_blank" rel="noopener" class="text-[13px] text-primary hover:underline truncate max-w-[220px]">{{ listing.socialLinks[s.key] }}</a>
                </div>
              </div>
              <p v-else class="text-[13.5px] text-muted-foreground">No social links added yet.</p>
            </div>
          </div>

          <div class="bg-card border border-border rounded-xl shadow-xs p-6 flex flex-col gap-5">
            <h3 class="text-[15px] font-semibold text-foreground border-b border-border/60 pb-4 flex items-center gap-2"><Clock class="size-4 text-muted-foreground" /> Hours</h3>
            <div v-if="WEEKDAYS.some(d => listing.hours[d])" class="grid grid-cols-2 gap-y-2 text-[13px] max-w-sm">
              <template v-for="d in WEEKDAYS" :key="d">
                <span v-if="listing.hours[d]" class="text-muted-foreground font-medium capitalize">{{ d }}</span>
                <span v-if="listing.hours[d]" class="font-semibold" :class="listing.hours[d].toLowerCase() === 'closed' ? 'text-rose-500' : 'text-foreground'">{{ listing.hours[d] }}</span>
              </template>
            </div>
            <p v-else class="text-[13.5px] text-muted-foreground">Business hours not set yet.</p>

            <div class="flex flex-col gap-3 pt-4 border-t border-border/50">
              <div class="flex items-center justify-between text-[13px] font-semibold text-foreground">
                <span>Holiday Hours</span>
                <button type="button" class="text-[12px] font-semibold text-primary hover:underline" @click="addHolidayHours">Add</button>
              </div>
              <div v-if="listing.holidayHours.length" class="flex flex-col gap-2">
                <div v-for="(h, i) in listing.holidayHours" :key="i" class="flex justify-between text-[13px] p-2.5 bg-muted/40 rounded-lg border border-border/40">
                  <span class="text-foreground font-medium">{{ h.date }}</span>
                  <span class="text-muted-foreground">{{ h.label }}</span>
                </div>
              </div>
              <p v-else class="text-[13px] text-muted-foreground p-3 bg-muted/50 rounded-lg border border-border/50 text-center font-medium">
                No upcoming holiday hours set.
              </p>
            </div>
          </div>

          <div class="bg-card border border-border rounded-xl shadow-xs p-6 flex flex-col gap-5">
            <div class="flex items-center justify-between border-b border-border/60 pb-4">
              <h3 class="text-[15px] font-semibold text-foreground">Photos Gallery</h3>
              <label class="inline-flex items-center gap-2 h-8 px-3 rounded-md border border-border text-[12px] font-semibold text-foreground hover:bg-muted cursor-pointer">
                <Camera class="size-3.5" /> {{ uploadingPhotos ? 'Uploading…' : 'Upload Photos' }}
                <input type="file" accept="image/*" multiple class="hidden" :disabled="uploadingPhotos" @change="uploadPhotos" />
              </label>
            </div>
            <div v-if="listing.photoUrls.length" class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
              <div v-for="url in listing.photoUrls" :key="url" class="aspect-square rounded-xl overflow-hidden border border-border bg-muted">
                <img :src="url" class="w-full h-full object-cover" />
              </div>
            </div>
            <p v-else class="text-[13.5px] text-muted-foreground">No photos uploaded yet.</p>
          </div>
        </div>

        <div v-else-if="activeTab === 'Connections'" class="flex flex-col gap-6 pb-12">
          <div class="flex items-center justify-between">
            <div>
              <h2 class="text-base font-medium text-foreground">Connections</h2>
              <p class="text-[13px] text-muted-foreground mt-1">Connect or disconnect listing platforms for this location.</p>
            </div>
            <div class="flex items-center gap-2">
              <RelayButton variant="outline" class="gap-2 text-xs font-semibold px-4" @click="goToConnectPlatform">
                Connect Platform
              </RelayButton>
              <RelayButton class="gap-2 text-xs font-semibold px-4" :disabled="syncing" @click="syncNow">
                <RotateCw class="size-3.5" :class="syncing ? 'animate-spin' : ''" /> {{ syncing ? 'Syncing…' : 'Sync All' }}
              </RelayButton>
            </div>
          </div>
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div class="bg-card border border-border rounded-xl shadow-xs p-4 flex items-center gap-4">
              <div class="size-10 bg-emerald-50 text-emerald-600 dark:bg-emerald-950 dark:text-emerald-400 rounded-full flex items-center justify-center shrink-0">
                <Layers class="size-5" />
              </div>
              <div class="flex flex-col gap-0.5">
                <span class="text-2xl font-semibold text-foreground leading-none">{{ connectedCount }}</span>
                <span class="text-[12px] font-medium text-muted-foreground">Connected</span>
              </div>
            </div>
            <div class="bg-card border border-border rounded-xl shadow-xs p-4 flex items-center gap-4">
              <div class="size-10 bg-amber-50 text-amber-500 dark:bg-amber-950 dark:text-amber-400 rounded-full flex items-center justify-center shrink-0">
                <AlertTriangle class="size-5" />
              </div>
              <div class="flex flex-col gap-0.5">
                <span class="text-2xl font-semibold text-foreground leading-none">{{ disconnectedPlatforms.length }}</span>
                <span class="text-[12px] font-medium text-muted-foreground">Needs Attention</span>
              </div>
            </div>
            <div class="bg-card border border-border rounded-xl shadow-xs p-4 flex items-center gap-4">
              <div class="size-10 bg-primary/10 text-primary rounded-full flex items-center justify-center shrink-0">
                <RotateCw class="size-5" />
              </div>
              <div class="flex flex-col gap-0.5">
                <span class="text-lg font-semibold text-foreground leading-none">{{ listing.lastSync }}</span>
                <span class="text-[12px] font-medium text-muted-foreground">Last Sync</span>
              </div>
            </div>
          </div>
          <h3 class="text-base font-medium text-foreground -mb-1">Connected Platforms</h3>
          <div v-if="!connectedPlatforms.length" class="bg-card border border-dashed border-border rounded-xl p-10 text-center">
            <Layers class="size-8 mx-auto text-muted-foreground mb-3" />
            <p class="text-sm text-muted-foreground">No platforms connected to this listing yet.</p>
            <RelayButton variant="outline" class="mt-4" @click="goToConnectPlatform">Connect Platform</RelayButton>
          </div>
          <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div
              v-for="platform in connectedPlatforms"
              :key="platform.id"
              class="rounded-xl shadow-xs p-5 flex flex-col gap-4"
              :class="platform.status === 'Connected' ? 'bg-card border border-border' : 'bg-rose-50/60 border border-rose-200 dark:bg-rose-950/30 dark:border-rose-900/50'"
            >
              <div class="flex items-center justify-between gap-3">
                <div class="flex items-center gap-3 min-w-0">
                  <div class="size-10 border border-border rounded-lg bg-card flex items-center justify-center shrink-0" v-html="getPlatformIcon(platform.name)"></div>
                  <div class="flex flex-col gap-0.5 min-w-0">
                    <span class="text-[15px] font-medium text-foreground truncate">{{ platform.name }}</span>
                    <span class="text-[12px]" :class="platform.status === 'Connected' ? 'text-muted-foreground' : 'text-rose-600 font-medium'">
                      {{ platform.status === 'Connected' ? `Last Sync: ${listing.lastSync}` : 'Authentication expired' }}
                    </span>
                  </div>
                </div>
                <span
                  class="px-2.5 py-0.5 rounded-full font-semibold text-[11px] inline-flex items-center gap-1 shrink-0"
                  :class="platform.status === 'Connected' ? 'bg-emerald-50 text-emerald-600 dark:bg-emerald-950 dark:text-emerald-400' : 'bg-rose-100 text-rose-600 dark:bg-rose-950 dark:text-rose-400'"
                >
                  <CheckCircle2 v-if="platform.status === 'Connected'" class="size-3" />
                  <AlertTriangle v-else class="size-3" />
                  {{ platform.status === 'Connected' ? 'Connected' : 'Action Required' }}
                </span>
              </div>
              <RelayButton v-if="platform.status !== 'Connected'" class="bg-rose-600 hover:bg-rose-700 text-white" @click="goToConnectPlatform">
                Reconnect {{ platform.name }}
              </RelayButton>
              <div v-else class="flex items-center justify-end">
                <button type="button" class="text-[13px] font-semibold text-rose-600 hover:text-rose-700" @click="disconnectIntegration(platform.id)">Disconnect</button>
              </div>
            </div>
          </div>
        </div>

        <div v-else-if="activeTab === 'Insights'" class="flex flex-col gap-6 pb-12">
          <div>
            <h2 class="text-xl font-bold text-foreground flex items-center gap-2"><Sparkles class="size-5 text-primary" /> Insights</h2>
            <p class="text-[13px] text-muted-foreground mt-1">AI analysis of this listing's reviews.</p>
          </div>

          <div v-if="aiInsightsLoading" class="bg-card border border-border rounded-xl p-10 text-center text-sm text-muted-foreground">
            Analyzing reviews…
          </div>

          <div v-else-if="!aiInsights" class="bg-card border border-dashed border-border rounded-xl p-10 text-center">
            <TrendingUp class="size-8 mx-auto text-muted-foreground mb-3" />
            <p class="text-base font-medium text-foreground">Insights need review history</p>
            <p class="text-sm text-muted-foreground mt-1 max-w-md mx-auto">
              Rating trends and reply stats show up here once this account has synced reviews.
            </p>
            <RelayButton variant="outline" class="mt-4" @click="router.push({ name: 'reputation_reviews' })">
              View Reviews
            </RelayButton>
          </div>

          <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div class="lg:col-span-2 bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col gap-5">
              <h3 class="text-base font-medium text-foreground flex items-center gap-2"><Sparkles class="size-4 text-primary" /> AI Review Summary</h3>
              <div class="flex flex-col gap-4">
                <div v-for="(insight, i) in aiInsights.insights" :key="i" class="flex items-start gap-3">
                  <CheckCircle2 class="size-4 text-emerald-500 shrink-0 mt-0.5" />
                  <div class="flex flex-col gap-0.5">
                    <span class="text-[13.5px] font-semibold text-foreground">{{ insight.title }}</span>
                    <span class="text-[13px] text-muted-foreground leading-relaxed">{{ insight.text }}</span>
                  </div>
                </div>
              </div>
            </div>

            <div class="bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col items-center gap-3">
              <h3 class="text-base font-medium text-foreground self-start">Overall Sentiment</h3>
              <div class="relative size-28 flex items-center justify-center mt-2">
                <svg class="size-full -rotate-90" viewBox="0 0 100 100">
                  <circle cx="50" cy="50" r="42" fill="none" class="stroke-emerald-50 dark:stroke-emerald-950" stroke-width="8" />
                  <circle cx="50" cy="50" r="42" fill="none" class="stroke-emerald-500" stroke-width="8" stroke-linecap="round"
                    :stroke-dasharray="263.89" :stroke-dashoffset="263.89 - (263.89 * aiInsights.sentiment) / 100" />
                </svg>
                <div class="absolute inset-0 flex flex-col items-center justify-center">
                  <span class="text-[24px] font-extrabold text-foreground tracking-tight leading-none">{{ aiInsights.sentiment }}%</span>
                </div>
              </div>
              <span class="text-[13px] font-semibold text-emerald-600">{{ sentimentLabel }}</span>
              <span v-if="reviewStats.total" class="text-[11.5px] text-muted-foreground">Based on {{ reviewStats.total }} recent reviews</span>
            </div>

            <div class="lg:col-span-2 bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col gap-4">
              <h3 class="text-base font-medium text-foreground">Rating Trend</h3>
              <div class="relative h-[140px] w-full">
                <svg class="absolute inset-0 size-full" viewBox="0 0 100 100" preserveAspectRatio="none">
                  <defs>
                    <linearGradient id="insightsTrendGradient" x1="0" x2="0" y1="0" y2="1">
                      <stop offset="0%" stop-color="currentColor" class="text-primary" stop-opacity="0.25" />
                      <stop offset="100%" stop-color="currentColor" class="text-primary" stop-opacity="0.01" />
                    </linearGradient>
                  </defs>
                  <polygon :points="`0,100 ${trendPoints} 100,100`" fill="url(#insightsTrendGradient)" />
                  <polyline :points="trendPoints" fill="none" class="stroke-primary" stroke-width="1.5" vector-effect="non-scaling-stroke" stroke-linecap="round" stroke-linejoin="round" />
                </svg>
              </div>
              <p class="text-[11px] text-muted-foreground text-center">Review volume, last 5 weeks</p>
            </div>

            <div class="bg-primary text-primary-foreground rounded-xl p-6 shadow-xs flex flex-col gap-4">
              <h3 class="text-base font-medium">Monthly Summary</h3>
              <div class="grid grid-cols-2 gap-4">
                <div class="flex flex-col gap-0.5">
                  <span class="text-[22px] font-bold leading-none">{{ reviewStats.total }}</span>
                  <span class="text-[11.5px] opacity-80">Total Reviews</span>
                </div>
                <div class="flex flex-col gap-0.5">
                  <span class="text-[22px] font-bold leading-none">{{ reviewStats.avgRating }}</span>
                  <span class="text-[11.5px] opacity-80">Average Rating</span>
                </div>
              </div>
            </div>
          </div>

          <div v-if="aiInsights.topics.length || aiInsights.keywords.length" class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div v-if="aiInsights.topics.length" class="bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col gap-4">
              <h3 class="text-base font-medium text-foreground flex items-center gap-2"><TrendingUp class="size-4 text-primary" /> Trending Topics</h3>
              <div class="flex flex-col gap-3">
                <div v-for="topic in aiInsights.topics" :key="topic.name" class="flex items-center justify-between gap-3">
                  <span class="text-[13.5px] font-medium text-foreground">{{ topic.name }}</span>
                  <div class="flex gap-0.5 text-amber-400 shrink-0">
                    <Star v-for="i in 5" :key="i" class="size-3.5" :class="i <= Math.round(topic.rating) ? 'fill-amber-400' : 'text-muted-foreground/30'" />
                  </div>
                </div>
              </div>
            </div>

            <div v-if="aiInsights.keywords.length" class="bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col gap-4">
              <h3 class="text-base font-medium text-foreground">Keyword Cloud</h3>
              <div class="flex flex-wrap gap-2">
                <span v-for="kw in aiInsights.keywords" :key="kw" class="px-2.5 py-1 rounded-md bg-primary/10 text-primary text-[12.5px] font-medium">{{ kw }}</span>
              </div>
            </div>
          </div>

          <div v-if="aiInsights.suggestions.length" class="bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col gap-4">
            <h3 class="text-base font-medium text-foreground flex items-center gap-2"><Sparkles class="size-4 text-primary" /> AI Suggestions</h3>
            <div class="flex flex-col gap-3">
              <div v-for="(suggestion, i) in aiInsights.suggestions" :key="i" class="flex items-start gap-3">
                <span class="size-1.5 rounded-full bg-primary shrink-0 mt-2"></span>
                <span class="text-[13px] text-muted-foreground leading-relaxed">{{ suggestion }}</span>
              </div>
            </div>
          </div>
        </div>

        <ListingMembersPanel
          v-else-if="activeTab === 'Team' && listing"
          :listing-id="listing.id"
          :account-id="accountId"
        />

        <div v-else-if="activeTab === 'Activity'" class="flex flex-col gap-2 pb-12">
          <h2 class="text-xl font-bold text-foreground">Activity Timeline</h2>
          <p class="text-[13px] text-muted-foreground mb-4">Everything recorded for this listing, chronologically.</p>

          <div v-if="!activityEvents.length" class="bg-card border border-dashed border-border rounded-xl p-10 text-center">
            <Activity class="size-8 mx-auto text-muted-foreground mb-3" />
            <p class="text-sm text-muted-foreground">No activity recorded yet.</p>
          </div>

          <div v-else class="flex flex-col relative pl-2">
            <div class="absolute left-[13px] top-2 bottom-4 w-px bg-border/60"></div>
            <div class="flex flex-col gap-6">
              <div v-for="event in activityEvents" :key="event.key" class="flex gap-4">
                <div class="size-5 rounded-full flex items-center justify-center shrink-0 mt-0.5 z-10 ring-4 ring-background" :class="event.tone">
                  <component :is="event.icon" class="size-3 stroke-[3]" />
                </div>
                <div class="flex flex-col gap-1 flex-1 pt-0.5">
                  <div class="flex items-center justify-between gap-2">
                    <span class="text-[14px] font-semibold text-foreground">{{ event.label }}</span>
                    <span class="text-[12px] text-muted-foreground font-medium whitespace-nowrap">{{ formatDate(event.time) }}</span>
                  </div>
                  <span v-if="event.actor" class="text-[13px] text-muted-foreground">by <span class="font-semibold text-foreground">{{ event.actor }}</span></span>
                </div>
              </div>
            </div>
          </div>

          <div v-if="connectedPlatforms.length" class="bg-card border border-border rounded-xl p-5 shadow-xs mt-2">
            <h4 class="text-[13px] font-semibold text-foreground mb-3">Current platform status</h4>
            <div class="flex flex-col gap-2.5">
              <div v-for="platform in connectedPlatforms" :key="platform.id" class="flex items-center gap-3">
                <CheckCircle2 v-if="platform.status === 'Connected'" class="size-4 text-emerald-500 shrink-0" />
                <AlertTriangle v-else class="size-4 text-rose-500 shrink-0" />
                <span class="text-[12.5px] font-medium text-muted-foreground">{{ platform.name }} — {{ platform.status }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>

  <div v-if="editOpen" :class="RELAY_DIALOG_OVERLAY_CLASS" class="flex items-center justify-center p-4" @click.self="editOpen = false">
    <div class="relative w-full max-w-2xl bg-card border border-border shadow-2xl rounded-2xl overflow-hidden flex flex-col max-h-[90vh]">
      <div :class="RELAY_MODAL_HEADER_CLASS">
        <div>
          <h2 :class="RELAY_MODAL_TITLE_CLASS">Edit Listing</h2>
          <p :class="RELAY_MODAL_DESCRIPTION_CLASS">Update the details shown on this listing.</p>
        </div>
      </div>
      <div class="p-6 flex flex-col gap-4 overflow-y-auto">
        <div :class="RELAY_FORM_FIELD_CLASS">
          <label :class="RELAY_FORM_LABEL_CLASS">Business Name</label>
          <RelayInput v-model="editForm.name" placeholder="Business name" />
        </div>
        <div class="grid grid-cols-2 gap-4">
          <div :class="RELAY_FORM_FIELD_CLASS">
            <label :class="RELAY_FORM_LABEL_CLASS">Primary Category</label>
            <RelayInput v-model="editForm.category" placeholder="Category" />
          </div>
          <div :class="RELAY_FORM_FIELD_CLASS">
            <label :class="RELAY_FORM_LABEL_CLASS">Additional Categories</label>
            <RelayInput v-model="editForm.additionalCategories" placeholder="e.g. Consultant, Agency" />
          </div>
        </div>
        <div :class="RELAY_FORM_FIELD_CLASS">
          <label :class="RELAY_FORM_LABEL_CLASS">Business Description</label>
          <RelayTextarea v-model="editForm.description" placeholder="Describe this business…" rows="3" />
        </div>
        <div :class="RELAY_FORM_FIELD_CLASS">
          <label :class="RELAY_FORM_LABEL_CLASS">Address</label>
          <RelayInput v-model="editForm.address" placeholder="Address" />
        </div>
        <div :class="RELAY_FORM_FIELD_CLASS">
          <label :class="RELAY_FORM_LABEL_CLASS">Service Area</label>
          <RelayInput v-model="editForm.serviceArea" placeholder="e.g. Jaipur, Delhi, Gurgaon" />
        </div>
        <div class="grid grid-cols-2 gap-4">
          <div :class="RELAY_FORM_FIELD_CLASS">
            <label :class="RELAY_FORM_LABEL_CLASS">Phone</label>
            <RelayInput v-model="editForm.phone" placeholder="Phone" />
          </div>
          <div :class="RELAY_FORM_FIELD_CLASS">
            <label :class="RELAY_FORM_LABEL_CLASS">Email</label>
            <RelayInput v-model="editForm.email" placeholder="Email" />
          </div>
        </div>
        <div :class="RELAY_FORM_FIELD_CLASS">
          <label :class="RELAY_FORM_LABEL_CLASS">Website</label>
          <RelayInput v-model="editForm.website" placeholder="Website" />
        </div>

        <div class="pt-2 border-t border-border/60">
          <label :class="RELAY_FORM_LABEL_CLASS">Business Hours</label>
          <div class="grid grid-cols-2 gap-3 mt-2">
            <div v-for="d in WEEKDAYS" :key="d" class="flex flex-col gap-1">
              <span class="text-[12px] text-muted-foreground capitalize">{{ d }}</span>
              <RelayInput v-model="editForm.hours[d]" placeholder="e.g. 9:00 AM - 7:00 PM or Closed" />
            </div>
          </div>
        </div>

        <div class="pt-2 border-t border-border/60">
          <label :class="RELAY_FORM_LABEL_CLASS">Attributes</label>
          <div class="grid grid-cols-2 gap-3 mt-2">
            <label v-for="a in AMENITY_OPTIONS" :key="a.key" class="flex items-center gap-2 cursor-pointer">
              <RelayCheckbox v-model="editForm.amenities[a.key]" />
              <span class="text-[13.5px] text-foreground">{{ a.label }}</span>
            </label>
          </div>
        </div>

        <div class="pt-2 border-t border-border/60 flex flex-col gap-3">
          <label :class="RELAY_FORM_LABEL_CLASS">Social Links</label>
          <div v-for="s in SOCIAL_PLATFORMS" :key="s.key" :class="RELAY_FORM_FIELD_CLASS">
            <RelayInput v-model="editForm.socialLinks[s.key]" :placeholder="`${s.label} URL`" />
          </div>
        </div>
      </div>
      <div class="px-6 py-4 border-t border-border/60 flex justify-end gap-2 shrink-0">
        <RelayButton variant="outline" @click="editOpen = false">Cancel</RelayButton>
        <RelayButton :disabled="!editValid || busy" @click="saveEdit">Save</RelayButton>
      </div>
    </div>
  </div>
</template>
