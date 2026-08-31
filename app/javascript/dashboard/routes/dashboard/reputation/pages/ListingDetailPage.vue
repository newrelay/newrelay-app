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
  Check,
  CheckCircle2,
  AlertTriangle,
  Activity,
  Compass,
  Image as ImageIcon,
  Star,
  ArrowRight,
} from 'lucide-vue-next';
import {
  RelayButton,
  RelayInput,
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
  const platforms = (row.platforms || []).map(p => ({
    name: p.name,
    status: p.status || (p.ok ? 'Connected' : 'Not Connected'),
  }));
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
    optimizationScore: row.optimized ?? row.optimizationScore ?? 90,
    rating: row.rating || 4.5,
    reviewsCount: row.reviews ?? row.reviewsCount ?? 0,
    lastSync: row.lastSync || (row.synced_at ? new Date(row.synced_at).toLocaleString() : 'Just now'),
    createdAt: row.created_at || row.createdAt || null,
    updatedAt: row.updated_at || row.updatedAt || null,
    platforms: platforms.length
      ? platforms
      : [
          { name: 'Google', status: 'Connected' },
          { name: 'Facebook', status: 'Connected' },
        ],
  };
}

const platformsToApi = platforms => (platforms || []).map(p => ({ name: p.name, ok: p.status === 'Connected' }));

const loading = ref(true);
const usingMock = ref(false);
const listing = ref(null);
const activeTab = ref('Overview');
const busy = ref(false);
const editOpen = ref(false);
const editForm = ref({ name: '', address: '', phone: '', website: '', email: '', category: '' });

const connectedCount = computed(
  () => listing.value?.platforms.filter(p => p.status === 'Connected').length || 0
);
const platformTotal = computed(() => listing.value?.platforms.length || 0);
const disconnectedPlatforms = computed(
  () => listing.value?.platforms.filter(p => p.status !== 'Connected') || []
);
const websiteHref = computed(() => {
  const url = listing.value?.website;
  if (!url) return '';
  return /^https?:\/\//i.test(url) ? url : `https://${url}`;
});
const editValid = computed(() => !!editForm.value.name?.trim());

const tabs = [
  { id: 'Overview', icon: Compass },
  { id: 'Listing Info', icon: Building2 },
  { id: 'Connections', icon: Layers },
  { id: 'Insights', icon: TrendingUp },
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

// Reviews aren't scoped per-listing in the schema (reputation_reviews has no
// listing_id) — this shows the account's real recent reviews, same as the
// Reviews page, rather than fabricating listing-specific data.
const accountReviews = ref([]);
async function loadAccountReviews() {
  try {
    const { data } = await axios.get(`${baseUrl()}/reviews`);
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
  };
  try {
    if (!usingMock.value) {
      const { data } = await axios.patch(`${baseUrl()}/listings/${listing.value.id}`, patch);
      listing.value = mapListing(data);
    } else {
      Object.assign(listing.value, {
        title: patch.name,
        address: patch.address,
        phone: patch.phone,
        website: patch.website,
        email: patch.email,
        category: patch.category,
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

async function persistPlatforms(platforms) {
  if (!listing.value) return;
  const next = platforms.map(p => ({ ...p }));
  try {
    if (!usingMock.value) {
      await axios.patch(`${baseUrl()}/listings/${listing.value.id}`, { platforms: platformsToApi(next) });
    }
    listing.value.platforms = next;
  } catch {
    useAlert('Failed to update platforms');
  }
}

async function togglePlatform(platform) {
  const next = listing.value.platforms.map(p =>
    p.name === platform.name
      ? { ...p, status: p.status === 'Connected' ? 'Not Connected' : 'Connected' }
      : p
  );
  await persistPlatforms(next);
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
        platforms: platformsToApi(listing.value.platforms),
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

function syncNow() {
  useAlert(`Syncing ${listing.value?.title || 'listing'}...`);
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
});

watch(() => route.params.listingId, () => {
  if (showDemoSurfaces.value) loadListing();
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
              <RelayButton variant="outline" class="h-9 gap-2 text-xs font-semibold px-4" :disabled="busy" @click="syncNow">
                <RotateCw class="size-3.5" /> Sync Now
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
            <div class="flex gap-4 overflow-x-auto pb-2">
              <div
                v-for="platform in listing.platforms"
                :key="platform.name"
                class="flex flex-col justify-between p-5 border rounded-xl min-w-[260px] bg-card shadow-xs"
                :class="platform.status === 'Connected' ? 'border-border' : 'border-rose-200/60 dark:border-rose-900/40'"
              >
                <div class="flex items-center gap-3">
                  <div class="size-10 border border-border rounded-lg bg-card flex items-center justify-center shrink-0" v-html="getPlatformIcon(platform.name)"></div>
                  <div class="flex flex-col gap-0.5">
                    <span class="text-[14px] font-medium text-foreground">{{ platform.name }}</span>
                    <span class="text-[12px] font-medium" :class="platform.status === 'Connected' ? 'text-muted-foreground' : 'text-rose-500'">
                      {{ platform.status === 'Connected' ? `Last Sync: ${listing.lastSync}` : platform.status }}
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
                    type="button"
                    class="h-6 px-2 text-[11px] font-semibold"
                    :class="platform.status === 'Connected' ? 'text-primary' : 'text-rose-600'"
                    @click="togglePlatform(platform)"
                  >
                    {{ platform.status === 'Connected' ? 'Disconnect' : 'Connect' }}
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Recent Reviews (account-wide — reviews aren't scoped per listing) -->
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

          <!-- Review Performance (real account review stats, no fabricated trend deltas) -->
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
                <div class="flex items-center gap-3">
                  <CheckCircle2 class="size-4 text-emerald-500 shrink-0" />
                  <span class="text-[12.5px] font-medium text-muted-foreground">Connected to {{ connectedCount }} of {{ platformTotal }} platforms</span>
                </div>
                <div v-if="listing.address" class="flex items-center gap-3">
                  <CheckCircle2 class="size-4 text-emerald-500 shrink-0" />
                  <span class="text-[12.5px] font-medium text-muted-foreground">Business info is filled in</span>
                </div>
                <div v-for="platform in disconnectedPlatforms" :key="platform.name" class="flex items-center gap-3">
                  <AlertTriangle class="size-4 text-amber-500 shrink-0" />
                  <span class="text-[12.5px] font-medium text-muted-foreground">{{ platform.name }} is disconnected</span>
                </div>
              </div>
            </div>

            <div v-if="disconnectedPlatforms.length" class="bg-card border border-border rounded-xl p-6 shadow-xs flex flex-col gap-6">
              <div class="flex items-center justify-between">
                <h3 class="text-base font-medium text-foreground">Needs Attention</h3>
                <span class="bg-rose-50 text-rose-600 dark:bg-rose-950 dark:text-rose-400 px-2 rounded-full font-semibold text-[12px]">{{ disconnectedPlatforms.length }}</span>
              </div>
              <div class="flex flex-col gap-4">
                <div v-for="platform in disconnectedPlatforms" :key="platform.name" class="flex items-start gap-3">
                  <div class="size-8 rounded-full bg-rose-50 dark:bg-rose-950 flex items-center justify-center shrink-0 mt-1">
                    <AlertTriangle class="size-4 text-rose-600" />
                  </div>
                  <div class="flex flex-col gap-0.5 flex-1">
                    <span class="text-[13px] font-medium text-foreground">{{ platform.name }} is disconnected</span>
                    <span class="text-[11.5px] text-muted-foreground">Reconnect to keep this listing in sync.</span>
                  </div>
                  <RelayButton variant="outline" class="h-7 text-[11px] font-semibold text-primary px-3 mt-1 shrink-0" @click="togglePlatform(platform)">
                    Connect
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
          <div class="bg-card border border-border rounded-xl shadow-xs p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="flex flex-col gap-1.5">
              <span class="text-[13px] font-medium text-foreground">Business Name</span>
              <span class="text-[14px] text-muted-foreground">{{ listing.title }}</span>
            </div>
            <div class="flex flex-col gap-1.5">
              <span class="text-[13px] font-medium text-foreground">Category</span>
              <span class="text-[14px] text-muted-foreground">{{ listing.category || '—' }}</span>
            </div>
            <div class="flex flex-col gap-1.5">
              <span class="text-[13px] font-medium text-foreground">Phone</span>
              <span class="text-[14px] text-muted-foreground">{{ listing.phone || '—' }}</span>
            </div>
            <div class="flex flex-col gap-1.5">
              <span class="text-[13px] font-medium text-foreground">Website</span>
              <a v-if="websiteHref" :href="websiteHref" target="_blank" rel="noopener" class="text-[14px] text-primary hover:underline">{{ listing.website }}</a>
              <span v-else class="text-[14px] text-muted-foreground">—</span>
            </div>
            <div class="flex flex-col gap-1.5">
              <span class="text-[13px] font-medium text-foreground">Email</span>
              <span class="text-[14px] text-muted-foreground">{{ listing.email || '—' }}</span>
            </div>
            <div class="flex flex-col gap-1.5 md:col-span-2">
              <span class="text-[13px] font-medium text-foreground">Address</span>
              <span class="text-[14px] text-muted-foreground">{{ listing.address || '—' }}</span>
            </div>
          </div>
        </div>

        <div v-else-if="activeTab === 'Connections'" class="flex flex-col gap-6 pb-12">
          <div class="flex items-center justify-between">
            <div>
              <h2 class="text-base font-medium text-foreground">Connections</h2>
              <p class="text-[13px] text-muted-foreground mt-1">Connect or disconnect listing platforms for this location.</p>
            </div>
            <RelayButton class="gap-2 text-xs font-semibold px-4" @click="syncNow">
              <RotateCw class="size-3.5" /> Sync All
            </RelayButton>
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
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div
              v-for="platform in listing.platforms"
              :key="platform.name"
              class="bg-card border border-border rounded-xl shadow-xs p-5 flex items-center justify-between gap-4"
            >
              <div class="flex items-center gap-3">
                <div class="size-10 border border-border rounded-lg bg-card flex items-center justify-center" v-html="getPlatformIcon(platform.name)"></div>
                <div class="flex flex-col gap-0.5">
                  <span class="text-[15px] font-medium text-foreground">{{ platform.name }}</span>
                  <span class="text-[12px] text-muted-foreground">{{ platform.status }}</span>
                </div>
              </div>
              <RelayButton variant="outline" size="sm" @click="togglePlatform(platform)">
                {{ platform.status === 'Connected' ? 'Disconnect' : 'Connect' }}
              </RelayButton>
            </div>
          </div>
        </div>

        <div v-else-if="activeTab === 'Insights'" class="bg-card border border-dashed border-border rounded-xl p-10 text-center">
          <TrendingUp class="size-8 mx-auto text-muted-foreground mb-3" />
          <p class="text-base font-medium text-foreground">Insights need review history</p>
          <p class="text-sm text-muted-foreground mt-1 max-w-md mx-auto">
            Rating trends and reply stats show up here once this listing has synced reviews.
          </p>
          <RelayButton variant="outline" class="mt-4" @click="router.push({ name: 'reputation_reviews' })">
            View Reviews
          </RelayButton>
        </div>

        <div v-else class="bg-card border border-border rounded-xl p-6 shadow-xs">
          <h3 class="text-base font-medium text-foreground mb-4">Activity</h3>
          <div class="flex flex-col gap-3 text-sm">
            <div class="flex items-center justify-between py-2 border-b border-border">
              <span class="text-muted-foreground">Last sync</span>
              <span class="font-medium text-foreground">{{ listing.lastSync }}</span>
            </div>
            <div class="flex items-center justify-between py-2 border-b border-border">
              <span class="text-muted-foreground">Updated</span>
              <span class="font-medium text-foreground">{{ formatDate(listing.updatedAt) }}</span>
            </div>
            <div class="flex items-center justify-between py-2">
              <span class="text-muted-foreground">Created</span>
              <span class="font-medium text-foreground">{{ formatDate(listing.createdAt) }}</span>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>

  <div v-if="editOpen" :class="RELAY_DIALOG_OVERLAY_CLASS" class="flex items-center justify-center p-4" @click.self="editOpen = false">
    <div class="relative w-full max-w-lg bg-card border border-border shadow-2xl rounded-2xl overflow-hidden flex flex-col">
      <div :class="RELAY_MODAL_HEADER_CLASS">
        <div>
          <h2 :class="RELAY_MODAL_TITLE_CLASS">Edit Listing</h2>
          <p :class="RELAY_MODAL_DESCRIPTION_CLASS">Update the details shown on this listing.</p>
        </div>
      </div>
      <div class="p-6 flex flex-col gap-4">
        <div :class="RELAY_FORM_FIELD_CLASS">
          <label :class="RELAY_FORM_LABEL_CLASS">Business Name</label>
          <RelayInput v-model="editForm.name" placeholder="Business name" />
        </div>
        <div :class="RELAY_FORM_FIELD_CLASS">
          <label :class="RELAY_FORM_LABEL_CLASS">Category</label>
          <RelayInput v-model="editForm.category" placeholder="Category" />
        </div>
        <div :class="RELAY_FORM_FIELD_CLASS">
          <label :class="RELAY_FORM_LABEL_CLASS">Address</label>
          <RelayInput v-model="editForm.address" placeholder="Address" />
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
      </div>
      <div class="px-6 pb-6 flex justify-end gap-2">
        <RelayButton variant="outline" @click="editOpen = false">Cancel</RelayButton>
        <RelayButton :disabled="!editValid || busy" @click="saveEdit">Save</RelayButton>
      </div>
    </div>
  </div>
</template>
