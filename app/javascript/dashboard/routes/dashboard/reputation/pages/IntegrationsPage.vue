<!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
<script setup>
/* eslint-disable */
import { ref, computed, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import {
  RefreshCw, Search, Plus, Check, X, RotateCcw, ChevronDown,
  LayoutGrid, Grid2X2, List, Building2, Send, CheckCircle2, Loader2,
} from 'lucide-vue-next';
import {
  RelayInput as Input, RelaySwitch,
  RelayDropdownMenu as DropdownMenu,
  RelayDropdownMenuTrigger as DropdownMenuTrigger,
  RelayDropdownMenuContent as DropdownMenuContent,
  RelayDropdownMenuItem as DropdownMenuItem,
} from 'dashboard/components-next/relay';

const axios = window.axios;
const route = useRoute();
const accountId =
  window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];
const baseApi = () => `/api/v1/accounts/${accountId}/reputation`;
// Providers the backend enum accepts directly; everything else connects as `custom`.
const ENUM_PROVIDERS = ['google', 'facebook', 'agoda', 'airbnb', 'aliexpress', 'amazon', 'angi', 'apple_app_store', 'avvo', 'custom'];
// Sample Google Business locations shown in mock mode (REPUTATION_GOOGLE_PROVIDER=mock),
// where the backend skips OAuth and seeds fake reviews on connect.
const MOCK_GOOGLE_LOCATIONS = [
  { location_id: 'accounts/mock/locations/0001', location_name: 'Apex Dental — Downtown' },
  { location_id: 'accounts/mock/locations/0002', location_name: 'Apex Dental — Westside Clinic' },
  { location_id: 'accounts/mock/locations/0003', location_name: 'Apex Dental — North Branch' },
];

const isDemoLoaded = ref(true);
const searchQuery = ref('');
const selectedStatus = ref('all');
const selectedNiche = ref('all');
const sortOrder = ref('recommended');
const viewMode = ref('grid4');
const isSyncing = ref(false);

const selectedIntegration = ref(null);
const isConfigModalOpen = ref(false);
const isRequestModalOpen = ref(false);
const requestedPlatformName = ref('');
const requestEmail = ref('');
const requestNotes = ref('');
const isRequestSubmitted = ref(false);
const requestSaving = ref(false);
const requestError = ref('');

// Live integrations loaded from the backend, keyed by grid-item id.
const liveIntegrations = ref([]);
const disconnectLoading = ref(false);

// Which listing a new connection attaches to (reputation_integrations.listing_id).
// Defaults to ?listing_id= (arriving from a listing's Connections tab) or the
// account's primary listing.
const listings = ref([]);
const selectedListingId = ref('');
const selectedListing = computed(() => listings.value.find(l => String(l.id) === String(selectedListingId.value)));
async function loadListings() {
  try {
    const { data } = await axios.get(`${baseApi()}/listings`);
    listings.value = data || [];
    selectedListingId.value = route.query.listing_id || listings.value[0]?.id || '';
  } catch (e) {
    listings.value = [];
  }
}

// Manual connect modal (non-OAuth platforms: review-page URL + business name)
const isConnectModalOpen = ref(false);
const connectTarget = ref(null);
const connectUrl = ref('');
const connectName = ref('');
const connectSaving = ref(false);
const connectError = ref('');

// Google Business location picker (after OAuth redirect)
const showLocationModal = ref(false);
const googleLocations = ref([]);
const selectedLocation = ref(null);
const loadingLocations = ref(false);
const connectingLocation = ref(false);
const locationError = ref('');
const currentOauthSessionId = ref('');

const niches = [
  { id: 'all', label: 'All Categories' },
  { id: 'local_search', label: 'Local & Search Engines' },
  { id: 'b2b_software', label: 'B2B & SaaS Software' },
  { id: 'ecommerce', label: 'E-Commerce & Retail' },
  { id: 'hospitality', label: 'Hospitality & Dining' },
  { id: 'home_services', label: 'Home & Trade Services' },
];
const statusOptions = [
  { id: 'all', label: 'All Statuses' },
  { id: 'connected', label: 'Connected' },
  { id: 'not_connected', label: 'Available / Not Connected' },
  { id: 'coming_soon', label: 'Coming Soon' },
];
const sortOptions = [
  { id: 'recommended', label: 'Recommended / Popular' },
  { id: 'name_asc', label: 'Alphabetical (A → Z)' },
  { id: 'name_desc', label: 'Alphabetical (Z → A)' },
];

const gIcon = `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>`;

const integrations = ref([
  { id: 'google', name: 'Google', niches: ['local_search'], nicheLabel: 'Local & Search', description: 'Connect with Google Business Profile to sync Google Maps ratings, customer reviews, and automate Relay AI responses.', connected: false, tag: '✓ Popular', tagVariant: 'emerald', isComingSoon: false, autoSync: true, autoReply: true, iconSvg: gIcon },
]);

const filteredIntegrations = computed(() => {
  let list = integrations.value.filter(item => {
    const q = searchQuery.value.toLowerCase();
    const matchesSearch =
      item.name.toLowerCase().includes(q) ||
      item.description.toLowerCase().includes(q) ||
      item.nicheLabel.toLowerCase().includes(q);
    let matchesStatus = true;
    if (selectedStatus.value === 'connected') matchesStatus = item.connected;
    else if (selectedStatus.value === 'not_connected') matchesStatus = !item.connected && !item.isComingSoon;
    else if (selectedStatus.value === 'coming_soon') matchesStatus = item.isComingSoon;
    const matchesNiche = selectedNiche.value === 'all' || item.niches.includes(selectedNiche.value);
    return matchesSearch && matchesStatus && matchesNiche;
  });
  if (sortOrder.value === 'name_asc') list = [...list].sort((a, b) => a.name.localeCompare(b.name));
  else if (sortOrder.value === 'name_desc') list = [...list].sort((a, b) => b.name.localeCompare(a.name));
  return list;
});

const selectedStatusLabel = computed(() => statusOptions.find(s => s.id === selectedStatus.value)?.label || 'All Statuses');
const selectedNicheLabel = computed(() => niches.find(n => n.id === selectedNiche.value)?.label || 'All Categories');
const selectedSortLabel = computed(() => sortOptions.find(s => s.id === sortOrder.value)?.label || 'Recommended');
const hasActiveFilters = computed(() => searchQuery.value !== '' || selectedStatus.value !== 'all' || selectedNiche.value !== 'all' || sortOrder.value !== 'recommended');

function resetFilters() {
  searchQuery.value = '';
  selectedStatus.value = 'all';
  selectedNiche.value = 'all';
  sortOrder.value = 'recommended';
}
// ---- Real integration wiring (ported from SettingsPage) ----
function integrationFor(item) {
  return liveIntegrations.value.find(i =>
    i.provider === item.id || (i.provider === 'custom' && (i.location_name || '').endsWith(`- ${item.id}`))
  );
}
function applyLiveState() {
  integrations.value.forEach(item => {
    const live = integrationFor(item);
    item.connected = !!live;
    item.integrationId = live?.id || null;
  });
}
async function loadIntegrations() {
  try {
    const qs = selectedListingId.value ? `?listing_id=${selectedListingId.value}` : '';
    const { data } = await axios.get(`${baseApi()}/integrations${qs}`);
    liveIntegrations.value = data || [];
  } catch (e) {
    liveIntegrations.value = [];
  }
  applyLiveState();
}

async function oauthState() {
  const { data } = await axios.get(`${baseApi()}/integrations/oauth_state`);
  return encodeURIComponent(data.state);
}
// Mock mode skips OAuth: pick a sample location and the backend persists +
// seeds reviews. Falls back to real Google OAuth only when a client id is configured.
const googleMockMode = computed(() => !!window.newrelayConfig?.reputationGoogleMock);
async function connectGoogle() {
  if (googleMockMode.value) {
    currentOauthSessionId.value = '';
    googleLocations.value = MOCK_GOOGLE_LOCATIONS;
    selectedLocation.value = MOCK_GOOGLE_LOCATIONS[0];
    loadingLocations.value = false;
    locationError.value = '';
    showLocationModal.value = true;
    return;
  }
  const clientId = window.newrelayConfig?.reputationGoogleClientId;
  if (!clientId) {
    alert('Google Client ID is not configured. Add REPUTATION_GOOGLE_CLIENT_ID to your .env and restart the server.');
    return;
  }
  const redirect = `${window.location.origin}/reputation/oauth/callback?provider=google`;
  const state = await oauthState();
  window.location.href =
    `https://accounts.google.com/o/oauth2/v2/auth?client_id=${clientId}&redirect_uri=${redirect}&scope=https://www.googleapis.com/auth/business.manage&response_type=code&access_type=offline&prompt=consent&state=${state}`;
}
async function connectFacebook() {
  const appId = window.newrelayConfig?.reputationFacebookAppId;
  const redirect = `${window.location.origin}/reputation/oauth/callback?provider=facebook`;
  const state = await oauthState();
  window.location.href =
    `https://www.facebook.com/v18.0/dialog/oauth?client_id=${appId}&redirect_uri=${redirect}&scope=pages_show_list,pages_read_engagement&state=${state}`;
}
function connect(item) {
  if (item.isComingSoon) { openRequestModal(item.name); return; }
  if (item.id === 'google') { connectGoogle(); return; }
  // Facebook only redirects to OAuth when an app id exists; otherwise it connects
  // through the manual modal like every other platform (and seeds mock reviews).
  if (item.id === 'facebook' && window.newrelayConfig?.reputationFacebookAppId) { connectFacebook(); return; }
  connectTarget.value = item;
  connectUrl.value = `https://${item.id.replace(/_/g, '')}.com/apex-dental`;
  connectName.value = 'Apex Dental';
  connectError.value = '';
  isConnectModalOpen.value = true;
}
async function submitManualConnect() {
  if (!connectUrl.value || !connectName.value) {
    connectError.value = 'Enter both the review-page URL and business name.';
    return;
  }
  const item = connectTarget.value;
  const isEnum = ENUM_PROVIDERS.includes(item.id);
  connectSaving.value = true;
  connectError.value = '';
  try {
    await axios.post(`${baseApi()}/integrations`, {
      integration: {
        provider: isEnum ? item.id : 'custom',
        location_id: connectUrl.value,
        location_name: isEnum ? connectName.value : `${connectName.value} - ${item.id}`,
        listing_id: selectedListingId.value,
      },
    });
    isConnectModalOpen.value = false;
    await loadIntegrations();
  } catch (err) {
    connectError.value = err.response?.data?.errors?.[0] || 'Failed to connect. This listing may already be connected.';
  } finally {
    connectSaving.value = false;
  }
}

async function checkGoogleOauthCallback() {
  const params = new URLSearchParams(window.location.search);
  const oauthStatus = params.get('google_oauth');
  if (!oauthStatus) return;
  const cleanUrl = window.location.pathname;
  window.history.replaceState({}, document.title, cleanUrl);
  if (oauthStatus === 'error') {
    alert(`Google Authentication Failed: ${params.get('message') || 'Unknown OAuth error'}`);
    return;
  }
  if (oauthStatus !== 'success') return;
  currentOauthSessionId.value = params.get('oauth_session_id');
  showLocationModal.value = true;
  loadingLocations.value = true;
  locationError.value = '';
  try {
    const { data } = await axios.get(`${baseApi()}/integrations/google_locations?oauth_session_id=${currentOauthSessionId.value}`);
    googleLocations.value = data;
    if (data.length > 0) selectedLocation.value = data[0];
  } catch (err) {
    locationError.value = err?.response?.data?.errors?.[0] || 'Failed to fetch Google locations. Please authenticate again.';
  } finally {
    loadingLocations.value = false;
  }
}
async function submitGoogleLocation() {
  if (!selectedLocation.value) { locationError.value = 'Select a Google Business location to connect.'; return; }
  connectingLocation.value = true;
  locationError.value = '';
  try {
    await axios.post(`${baseApi()}/integrations`, {
      integration: {
        provider: 'google',
        location_id: selectedLocation.value.location_id,
        location_name: selectedLocation.value.location_name,
        oauth_session_id: currentOauthSessionId.value,
        listing_id: selectedListingId.value,
      },
    });
    showLocationModal.value = false;
    await loadIntegrations();
  } catch (err) {
    locationError.value = err?.response?.data?.errors?.[0] || 'Failed to connect Google Business location.';
  } finally {
    connectingLocation.value = false;
  }
}

async function disconnectIntegration(item) {
  if (!item.integrationId) { item.connected = false; isConfigModalOpen.value = false; return; }
  if (!confirm(`Disconnect ${item.name}?`)) return;
  disconnectLoading.value = true;
  try {
    await axios.delete(`${baseApi()}/integrations/${item.integrationId}`);
    isConfigModalOpen.value = false;
    await loadIntegrations();
  } catch (err) {
    alert('Failed to disconnect integration');
  } finally {
    disconnectLoading.value = false;
  }
}

async function handleSyncAll() {
  isSyncing.value = true;
  try {
    await axios.post(`${baseApi()}/integrations/sync_all`);
  } catch (e) {
    // ignore — reload picks up whatever synced
  }
  await loadIntegrations();
  isSyncing.value = false;
}
function openConfigure(item) {
  selectedIntegration.value = item;
  isConfigModalOpen.value = true;
}

onMounted(async () => {
  await loadListings();
  await loadIntegrations();
  await checkGoogleOauthCallback();
});
watch(selectedListingId, loadIntegrations);
function openRequestModal(platformName) {
  requestedPlatformName.value = platformName || '';
  requestEmail.value = '';
  requestNotes.value = '';
  isRequestSubmitted.value = false;
  requestError.value = '';
  isRequestModalOpen.value = true;
}
async function submitRequest() {
  if (!requestedPlatformName.value) return;
  requestSaving.value = true;
  try {
    await axios.post(`${baseApi()}/integration_requests`, {
      integration_request: {
        platform: requestedPlatformName.value,
        email: requestEmail.value,
        notes: requestNotes.value,
      },
    });
    isRequestSubmitted.value = true;
    setTimeout(() => { isRequestModalOpen.value = false; }, 2000);
  } catch (err) {
    requestError.value = 'Failed to submit your request. Please try again.';
  } finally {
    requestSaving.value = false;
  }
}
function tagStyles(variant) {
  if (variant === 'emerald') return 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400';
  if (variant === 'primary') return 'bg-primary/10 text-primary';
  if (variant === 'amber') return 'bg-amber-500/10 text-amber-600 dark:text-amber-400';
  return 'bg-muted text-muted-foreground';
}
</script>

<template>
  <div class="flex-1 overflow-y-auto w-full bg-background p-6 lg:p-8">
    <div v-if="isDemoLoaded" class="max-w-7xl mx-auto space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-border/60">
        <div>
          <h1 class="text-base font-medium tracking-tight text-foreground">Integrations</h1>
          <p class="text-[13.5px] text-muted-foreground mt-0.5">Connect external review platforms to automatically monitor ratings, aggregate reviews, and route Relay AI responses.</p>
        </div>
        <div class="flex items-center gap-3">
          <div v-if="listings.length > 1" class="flex items-center gap-2 text-[13px]">
            <span class="text-muted-foreground">Connecting to:</span>
            <select
              v-model="selectedListingId"
              class="h-9 rounded-lg border border-border bg-card shadow-xs text-[13px] font-medium px-2.5 cursor-pointer"
            >
              <option v-for="l in listings" :key="l.id" :value="l.id">{{ l.name }}</option>
            </select>
          </div>
          <span v-else-if="selectedListing" class="text-[13px] text-muted-foreground">
            Connecting to <span class="font-medium text-foreground">{{ selectedListing.name }}</span>
          </span>
          <button class="h-9 gap-2 rounded-lg border border-border bg-card hover:bg-muted shadow-xs text-[13.5px] font-medium px-3 inline-flex items-center cursor-pointer disabled:opacity-60" :disabled="isSyncing" @click="handleSyncAll">
            <RefreshCw :class="['size-3.5', isSyncing ? 'animate-spin' : '']" />
            {{ isSyncing ? 'Syncing…' : 'Sync All Accounts' }}
          </button>
        </div>
      </div>

      <!-- Filter toolbar -->
      <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-3 pt-1">
        <div class="flex items-center gap-2 flex-wrap">
          <div class="relative w-48 sm:w-56">
            <Search class="absolute left-3.5 top-1/2 -translate-y-1/2 size-4 text-muted-foreground z-10" />
            <Input v-model="searchQuery" placeholder="Search platforms…" class="pl-9 h-9 text-[13px] rounded-xl bg-card border border-border shadow-xs" />
          </div>
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <button class="h-9 gap-1.5 rounded-xl text-[13px] font-medium bg-card border border-border shadow-xs px-3 hover:bg-muted inline-flex items-center cursor-pointer">
                <span>{{ selectedStatus === 'all' ? 'Platform Status' : selectedStatusLabel }}</span>
                <ChevronDown class="size-3.5 opacity-50 ml-0.5" />
              </button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start" class="w-48">
              <DropdownMenuItem v-for="opt in statusOptions" :key="opt.id" class="text-[13px] flex items-center justify-between cursor-pointer" @click="selectedStatus = opt.id">
                <span>{{ opt.label }}</span>
                <Check v-if="selectedStatus === opt.id" class="size-3.5 text-primary ml-2" />
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <button class="h-9 gap-1.5 rounded-xl text-[13px] font-medium bg-card border border-border shadow-xs px-3 hover:bg-muted inline-flex items-center cursor-pointer">
                <span>{{ selectedNiche === 'all' ? 'Category / Niche' : selectedNicheLabel }}</span>
                <ChevronDown class="size-3.5 opacity-50 ml-0.5" />
              </button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start" class="w-56">
              <DropdownMenuItem v-for="niche in niches" :key="niche.id" class="text-[13px] flex items-center justify-between cursor-pointer" @click="selectedNiche = niche.id">
                <span>{{ niche.label }}</span>
                <Check v-if="selectedNiche === niche.id" class="size-3.5 text-primary ml-2" />
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <button class="h-9 gap-1.5 rounded-xl text-[13px] font-medium bg-card border border-border shadow-xs px-3 hover:bg-muted inline-flex items-center cursor-pointer">
                <span>{{ selectedSortLabel }}</span>
                <ChevronDown class="size-3.5 opacity-50 ml-0.5" />
              </button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start" class="w-52">
              <DropdownMenuItem v-for="sort in sortOptions" :key="sort.id" class="text-[13px] flex items-center justify-between cursor-pointer" @click="sortOrder = sort.id">
                <span>{{ sort.label }}</span>
                <Check v-if="sortOrder === sort.id" class="size-3.5 text-primary ml-2" />
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
          <button v-if="hasActiveFilters" class="h-9 rounded-xl text-[12.5px] text-muted-foreground hover:text-foreground border border-border hover:bg-muted gap-1 px-2.5 inline-flex items-center cursor-pointer" @click="resetFilters">
            <RotateCcw class="size-3" /> Reset
          </button>
        </div>
        <div class="flex items-center gap-2 self-end lg:self-auto">
          <div class="flex items-center bg-card border border-border rounded-xl p-0.5 shadow-xs">
            <button class="p-1.5 rounded-lg transition-colors" :class="viewMode === 'grid4' ? 'bg-muted text-foreground' : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'" title="4 Columns" @click="viewMode = 'grid4'"><LayoutGrid class="size-4" /></button>
            <button class="p-1.5 rounded-lg transition-colors" :class="viewMode === 'grid2' ? 'bg-muted text-foreground' : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'" title="2 Columns" @click="viewMode = 'grid2'"><Grid2X2 class="size-4" /></button>
            <button class="p-1.5 rounded-lg transition-colors" :class="viewMode === 'list' ? 'bg-muted text-foreground' : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'" title="List View" @click="viewMode = 'list'"><List class="size-4" /></button>
          </div>
        </div>
      </div>

      <div v-if="hasActiveFilters" class="flex items-center gap-2 text-[12.5px] text-muted-foreground">
        <span>Showing <strong class="text-foreground">{{ filteredIntegrations.length }}</strong> of {{ integrations.length }} platforms matching filters</span>
      </div>

      <!-- Grid views -->
      <div v-if="viewMode !== 'list'" class="grid gap-4" :class="viewMode === 'grid4' ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4' : 'grid-cols-1 md:grid-cols-2'">
        <div v-for="item in filteredIntegrations" :key="item.id" class="bg-card rounded-2xl border border-border p-6 shadow-xs flex flex-col justify-between hover:shadow-sm transition-all">
          <div>
            <div class="flex items-center justify-between gap-3 mb-3">
              <div class="flex items-center gap-3">
                <div class="size-8 flex items-center justify-center shrink-0" v-html="item.iconSvg"></div>
                <h3 class="text-[16px] font-semibold text-foreground tracking-tight leading-snug">{{ item.name }}</h3>
              </div>
              <span class="text-[10.5px] font-normal py-0.5 px-2 rounded-md border border-border text-muted-foreground shrink-0">{{ item.nicheLabel }}</span>
            </div>
            <p class="text-[13px] text-muted-foreground leading-relaxed">{{ item.description }}</p>
          </div>
          <div class="pt-5 mt-5 border-t border-border/50 flex items-center justify-between">
            <div class="flex items-center gap-1 text-[12px] font-medium px-2.5 py-0.5 rounded-md" :class="tagStyles(item.tagVariant)"><span>{{ item.tag }}</span></div>
            <button v-if="item.connected" class="text-[13px] font-medium text-primary hover:underline cursor-pointer" @click="openConfigure(item)">Configure →</button>
            <button v-else-if="item.isComingSoon" class="text-[13px] font-medium text-primary hover:underline cursor-pointer" @click="openRequestModal(item.name)">Notify Me →</button>
            <button v-else class="text-[13px] font-medium text-primary hover:underline cursor-pointer" @click="connect(item)">Connect →</button>
          </div>
        </div>
        <div v-if="selectedStatus === 'all' || selectedStatus === 'coming_soon'" class="bg-card rounded-2xl border border-dashed border-border p-6 shadow-xs flex flex-col justify-between hover:border-primary/50 hover:bg-muted/10 transition-all">
          <div>
            <div class="flex items-center gap-3 mb-3">
              <div class="size-8 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0"><Plus class="size-4" /></div>
              <h3 class="text-[16px] font-semibold text-foreground tracking-tight">More coming soon</h3>
            </div>
            <p class="text-[13px] text-muted-foreground leading-relaxed">Don't see what you need? Request an integration with your favorite review platform or POS software.</p>
          </div>
          <div class="pt-5 mt-5 border-t border-border/50">
            <button class="text-[13px] font-medium text-primary hover:underline cursor-pointer" @click="openRequestModal('')">Request integration →</button>
          </div>
        </div>
      </div>

      <!-- List view -->
      <div v-else class="space-y-3">
        <div v-for="item in filteredIntegrations" :key="item.id" class="bg-card rounded-2xl border border-border p-5 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:shadow-sm transition-all">
          <div class="flex items-start sm:items-center gap-4 flex-1">
            <div class="size-10 rounded-xl bg-muted/30 border border-border/60 flex items-center justify-center shrink-0 p-2" v-html="item.iconSvg"></div>
            <div class="space-y-1 flex-1">
              <div class="flex items-center gap-2.5 flex-wrap">
                <h3 class="text-[15px] font-semibold text-foreground tracking-tight">{{ item.name }}</h3>
                <span class="text-[11px] font-normal py-0.5 px-2 rounded-md border border-border text-muted-foreground">{{ item.nicheLabel }}</span>
                <div class="flex items-center gap-1 text-[11.5px] font-medium px-2 py-0.5 rounded-md" :class="tagStyles(item.tagVariant)"><span>{{ item.tag }}</span></div>
              </div>
              <p class="text-[13px] text-muted-foreground leading-relaxed line-clamp-2">{{ item.description }}</p>
            </div>
          </div>
          <div class="flex items-center gap-3 shrink-0 self-end sm:self-center w-full sm:w-auto justify-end">
            <button v-if="item.connected" class="h-8 px-3 text-[12.5px] rounded-lg border border-border hover:bg-muted text-primary inline-flex items-center cursor-pointer" @click="openConfigure(item)">Configure</button>
            <button v-else-if="item.isComingSoon" class="h-8 px-3 text-[12.5px] rounded-lg border border-border hover:bg-muted text-primary inline-flex items-center cursor-pointer" @click="openRequestModal(item.name)">Notify Me</button>
            <button v-else class="h-8 px-3 text-[12.5px] rounded-lg bg-primary text-primary-foreground hover:bg-primary/90 inline-flex items-center cursor-pointer" @click="connect(item)">Connect</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-else class="max-w-md mx-auto flex flex-col items-center justify-center text-center py-24">
      <div class="size-14 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mb-4"><Building2 class="size-7" /></div>
      <h2 class="text-[20px] font-[600] text-foreground mb-1">No integrations connected</h2>
      <p class="text-sm text-muted-foreground mb-6">Connect your first review platform to start monitoring ratings and automating responses.</p>
      <button class="h-9 px-4 rounded-lg bg-primary text-primary-foreground text-sm font-semibold inline-flex items-center gap-2 cursor-pointer" @click="isDemoLoaded = true">
        <Plus class="size-4" /> Browse platforms
      </button>
    </div>

    <!-- Configure modal -->
    <div v-if="isConfigModalOpen && selectedIntegration" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-background/80 backdrop-blur-sm" @click="isConfigModalOpen = false"></div>
      <div class="relative bg-card border border-border rounded-2xl shadow-lg max-w-lg w-full p-6 space-y-5">
        <div class="flex items-center justify-between pb-3 border-b border-border">
          <div class="flex items-center gap-2.5">
            <div class="size-6 flex items-center justify-center" v-html="selectedIntegration.iconSvg"></div>
            <h2 class="text-[15px] font-semibold text-foreground">{{ selectedIntegration.name }} Integration Settings</h2>
          </div>
          <button class="text-muted-foreground hover:text-foreground" @click="isConfigModalOpen = false"><X class="size-4" /></button>
        </div>
        <div class="space-y-4 text-[13.5px]">
          <div class="flex items-center justify-between p-3.5 rounded-xl bg-muted/40 border border-border">
            <div>
              <div class="font-medium text-foreground">Automatic Review Sync</div>
              <div class="text-[12px] text-muted-foreground">Pull incoming reviews in real-time every 15 minutes</div>
            </div>
            <RelaySwitch v-model="selectedIntegration.autoSync" />
          </div>
          <div class="flex items-center justify-between p-3.5 rounded-xl bg-muted/40 border border-border">
            <div>
              <div class="font-medium text-foreground">Relay AI Smart Auto-Reply</div>
              <div class="text-[12px] text-muted-foreground">Auto-draft and publish on-brand responses to 5-star ratings</div>
            </div>
            <RelaySwitch v-model="selectedIntegration.autoReply" />
          </div>
        </div>
        <div class="flex items-center justify-between pt-3 border-t border-border">
          <button class="text-[13px] text-destructive border border-border hover:bg-muted rounded-lg px-3 py-2 font-medium cursor-pointer" @click="disconnectIntegration(selectedIntegration)">Disconnect Account</button>
          <div class="flex items-center gap-2">
            <button class="rounded-lg border border-border px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted/50 cursor-pointer" @click="isConfigModalOpen = false">Cancel</button>
            <button class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90 cursor-pointer" @click="isConfigModalOpen = false">Save Changes</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Request integration modal -->
    <div v-if="isRequestModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-background/80 backdrop-blur-sm" @click="isRequestModalOpen = false"></div>
      <div class="relative bg-card border border-border rounded-2xl shadow-lg max-w-md w-full p-6 space-y-5">
        <template v-if="!isRequestSubmitted">
          <div class="flex items-center justify-between pb-3 border-b border-border">
            <h2 class="text-[15px] font-semibold text-foreground">Request an Integration</h2>
            <button class="text-muted-foreground hover:text-foreground" @click="isRequestModalOpen = false"><X class="size-4" /></button>
          </div>
          <div class="space-y-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13px] font-medium text-foreground">Platform name</label>
              <Input v-model="requestedPlatformName" placeholder="e.g. Booking.com" class="h-9 text-[14px]" />
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-[13px] font-medium text-foreground">Your email</label>
              <Input v-model="requestEmail" placeholder="you@company.com" class="h-9 text-[14px]" />
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-[13px] font-medium text-foreground">Notes <span class="text-muted-foreground font-normal">(optional)</span></label>
              <textarea v-model="requestNotes" rows="3" class="w-full text-[13.5px] p-3 rounded-lg border border-border bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30"></textarea>
            </div>
            <p v-if="requestError" class="text-[13px] text-destructive">{{ requestError }}</p>
          </div>
          <div class="flex items-center justify-end gap-2 pt-3 border-t border-border">
            <button class="rounded-lg border border-border px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted/50 cursor-pointer" @click="isRequestModalOpen = false">Cancel</button>
            <button class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90 inline-flex items-center gap-1.5 cursor-pointer disabled:opacity-50" :disabled="!requestedPlatformName || requestSaving" @click="submitRequest">
              <Send class="size-3.5" /> {{ requestSaving ? 'Submitting…' : 'Submit Request' }}
            </button>
          </div>
        </template>
        <div v-else class="py-8 flex flex-col items-center text-center">
          <div class="size-14 rounded-full bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 flex items-center justify-center mb-4"><CheckCircle2 class="size-7" /></div>
          <h3 class="text-base font-semibold text-foreground mb-1">Request received</h3>
          <p class="text-sm text-muted-foreground">We'll notify you when {{ requestedPlatformName || 'this platform' }} is available.</p>
        </div>
      </div>
    </div>

    <!-- Manual connect modal (non-OAuth platforms) -->
    <div v-if="isConnectModalOpen && connectTarget" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-background/80 backdrop-blur-sm" @click="isConnectModalOpen = false"></div>
      <div class="relative bg-card border border-border rounded-2xl shadow-lg max-w-md w-full p-6 space-y-5">
        <div class="flex items-center justify-between pb-3 border-b border-border">
          <div class="flex items-center gap-2.5">
            <div class="size-6 flex items-center justify-center" v-html="connectTarget.iconSvg"></div>
            <h2 class="text-[15px] font-semibold text-foreground">Connect {{ connectTarget.name }}</h2>
          </div>
          <button class="text-muted-foreground hover:text-foreground" @click="isConnectModalOpen = false"><X class="size-4" /></button>
        </div>
        <div class="space-y-4">
          <div class="flex flex-col gap-1.5">
            <label class="text-[13px] font-medium text-foreground">Review page URL</label>
            <Input v-model="connectUrl" placeholder="https://…/your-business" class="h-9 text-[14px]" />
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-[13px] font-medium text-foreground">Business / listing name</label>
            <Input v-model="connectName" placeholder="e.g. Apex Dental — Downtown" class="h-9 text-[14px]" />
          </div>
          <p v-if="connectError" class="text-[12.5px] text-destructive">{{ connectError }}</p>
        </div>
        <div class="flex items-center justify-end gap-2 pt-3 border-t border-border">
          <button class="rounded-lg border border-border px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted/50 cursor-pointer" @click="isConnectModalOpen = false">Cancel</button>
          <button class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90 inline-flex items-center gap-1.5 cursor-pointer disabled:opacity-50" :disabled="connectSaving" @click="submitManualConnect">
            <Loader2 v-if="connectSaving" class="size-3.5 animate-spin" /><Check v-else class="size-3.5" /> Connect
          </button>
        </div>
      </div>
    </div>

    <!-- Google Business location picker -->
    <div v-if="showLocationModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-background/80 backdrop-blur-sm" @click="showLocationModal = false"></div>
      <div class="relative bg-card border border-border rounded-2xl shadow-lg max-w-md w-full p-6 space-y-5">
        <div class="flex items-center justify-between pb-3 border-b border-border">
          <div class="flex items-center gap-2.5">
            <div class="size-6 flex items-center justify-center" v-html="gIcon"></div>
            <h2 class="text-[15px] font-semibold text-foreground">Select a Google Business location</h2>
          </div>
          <button class="text-muted-foreground hover:text-foreground" @click="showLocationModal = false"><X class="size-4" /></button>
        </div>
        <div v-if="loadingLocations" class="py-8 flex items-center justify-center text-muted-foreground gap-2 text-sm">
          <Loader2 class="size-4 animate-spin" /> Loading your locations…
        </div>
        <template v-else>
          <div v-if="googleLocations.length" class="space-y-2 max-h-72 overflow-y-auto">
            <button v-for="loc in googleLocations" :key="loc.location_id" type="button" class="w-full text-left p-3 rounded-xl border transition-colors cursor-pointer" :class="selectedLocation && selectedLocation.location_id === loc.location_id ? 'border-primary bg-primary/5' : 'border-border hover:bg-muted/40'" @click="selectedLocation = loc">
              <div class="text-[13.5px] font-medium text-foreground">{{ loc.location_name }}</div>
              <div class="text-[12px] text-muted-foreground truncate">{{ loc.location_id }}</div>
            </button>
          </div>
          <p v-else class="text-[13px] text-muted-foreground py-4 text-center">No Google Business locations found for this account.</p>
        </template>
        <p v-if="locationError" class="text-[12.5px] text-destructive">{{ locationError }}</p>
        <div class="flex items-center justify-end gap-2 pt-3 border-t border-border">
          <button class="rounded-lg border border-border px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted/50 cursor-pointer" @click="showLocationModal = false">Cancel</button>
          <button class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90 inline-flex items-center gap-1.5 cursor-pointer disabled:opacity-50" :disabled="connectingLocation || !selectedLocation" @click="submitGoogleLocation">
            <Loader2 v-if="connectingLocation" class="size-3.5 animate-spin" /><Check v-else class="size-3.5" /> Connect Location
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
