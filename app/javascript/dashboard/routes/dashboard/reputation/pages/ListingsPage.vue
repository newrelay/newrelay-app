<script setup>
/* eslint-disable */
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { isReputationDemoSurfacesEnabled } from 'dashboard/featureFlags';
import {
  Download,
  ChevronDown,
  Plus,
  Building2,
  Layers,
  TrendingUp,
  TrendingDown,
  TriangleAlert,
  Search,
  Filter as Funnel,
  CircleCheck,
  RotateCw,
  MoreHorizontal,
  Check,
  X,
  MapPin,
  Phone,
  Globe,
  Mail,
  Link as LinkIcon,
  ArrowLeft,
  Hash,
  Store,
  Image as ImageIcon,
} from 'lucide-vue-next';
import {
  RelayInput as Input, RelaySwitch,
  RelayDropdownMenu as DropdownMenu,
  RelayDropdownMenuTrigger as DropdownMenuTrigger,
  RelayDropdownMenuContent as DropdownMenuContent,
  RelayDropdownMenuItem as DropdownMenuItem,
} from 'dashboard/components-next/relay';

const router = useRouter();
const accountId =
  window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];
const showDemoSurfaces = computed(() =>
  isReputationDemoSurfacesEnabled(
    accountId,
    window.__STORE__?.getters['accounts/isFeatureEnabledonAccount']
  )
);

onMounted(() => {
  if (!showDemoSurfaces.value) {
    router.replace({ name: 'reputation_overview' });
    return;
  }
  loadListings();
});

// ---------------------------------------------------------------------------
// MOCK DATA & ICONS
// ---------------------------------------------------------------------------
const stats = [
  { icon: Building2, tone: 'bg-primary/10 text-primary border-primary/20', value: '24', label: 'Listings', delta: '12% vs last month', up: true },
  { icon: Layers, tone: 'bg-primary/10 text-primary border-primary/20', value: '67', label: 'Platforms', delta: '8% vs last month', up: true },
  { icon: TrendingUp, tone: 'bg-emerald-50 text-emerald-600 border-emerald-100', value: '98%', label: 'Sync Rate', delta: '2% vs last month', up: true },
  { icon: TriangleAlert, tone: 'bg-amber-50 text-amber-500 border-amber-100', value: '3', label: 'Need Attention', delta: '3% vs last month', up: false },
];

const googleIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>`;
const facebookIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" fill="#1877F2"/></svg>`;
const yelpIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg" fill="#E00707"><path d="M12.271 8.782c-.549-3.804-.822-5.72-.822-5.748 0-.888-.622-1.641-1.537-1.887A2.34 2.34 0 0 0 7.3 2.52L3.473 7.337a2.01 2.01 0 0 0-.302 1.895c.28.72.934 1.218 1.695 1.282l5.894.488c1.038.087 1.871-.767 1.511-2.22zm-8.245 6.253l5.374 2.186c1.004.409 2.084-.332 2.084-1.41V11.38c0-1.088-1.096-1.83-2.104-1.41l-5.374 2.185a1.85 1.85 0 0 0-1.148 1.44 1.855 1.855 0 0 0 1.168 1.44zm6.406 5.978l-3.218-4.874a1.796 1.796 0 0 0-2.97-.095 1.855 1.855 0 0 0-.17 1.98l2.28 4.374a2.316 2.316 0 0 0 2.492 1.208 2.302 2.302 0 0 0 1.586-2.593zm9.56-10.826a2.31 2.31 0 0 0-1.92-1.435l-5.916-.489a1.796 1.796 0 0 0-1.493 2.874l3.42 4.96a1.803 1.803 0 0 0 2.8.217l3.477-4.046a2.02 2.02 0 0 0 .368-.654 2.004 2.004 0 0 0-.736-1.427zm-2.278 7.916l-2.277-4.373a1.804 1.804 0 0 0-3.124.149 1.789 1.789 0 0 0 .057 1.695l3.218 4.874a2.305 2.305 0 0 0 2.534.938 2.316 2.316 0 0 0 1.57-2.593 2.31 2.31 0 0 0-1.978-0.69z"/></svg>`;
const trustpilotIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" fill="#00B67A" rx="2" ry="2"/><path d="M12 4l2.5 5.2 5.7.8-4.1 4 1 5.7-5.1-2.7-5.1 2.7 1-5.7-4.1-4 5.7-.8L12 4z" fill="#FFF"/></svg>`;
const bingIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg"><path d="M9.82 2.14L3.6 0v16l6.22 2.18V2.14zM20.4 7.64l-8.6 3v9.54l8.6-2.58V7.64z" fill="#008373"/></svg>`;

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
    platforms: [
      { name: 'Google', status: 'Connected' },
      { name: 'Facebook', status: 'Connected' },
      { name: 'Trustpilot', status: 'Connected' },
      { name: 'Yelp', status: 'Not Connected' },
      { name: 'Bing', status: 'Connected' },
    ],
  },
];

const axios = window.axios;
const baseUrl = () => `/api/v1/accounts/${accountId}/reputation`;
const platformIcons = { Google: googleIcon, Facebook: facebookIcon, Yelp: yelpIcon, Trustpilot: trustpilotIcon, Bing: bingIcon };

const getPlatformIcon = name => platformIcons[name] || googleIcon;

// Deterministic gradient fallback when a listing has no fetched storefront photo.
const GRADIENTS = [
  'from-blue-500 to-indigo-600', 'from-emerald-500 to-teal-600', 'from-rose-500 to-pink-600',
  'from-amber-500 to-orange-600', 'from-violet-500 to-purple-600', 'from-cyan-500 to-blue-600',
];
const gradientFor = key => {
  const s = String(key || 'L');
  let h = 0;
  for (let i = 0; i < s.length; i += 1) h = s.charCodeAt(i) + ((h << 5) - h);
  return GRADIENTS[Math.abs(h) % GRADIENTS.length];
};

const listings = ref([]);
const usingMock = ref(false);
const loading = ref(true);

function mapListing(row) {
  const platforms = (row.platforms || []).map(p => ({
    name: p.name,
    status: p.ok ? 'Connected' : 'Not Connected',
  }));
  return {
    id: row.id,
    title: row.name || row.title,
    badge: row.primary ? 'Primary' : '',
    address: row.address || '',
    image: row.image || '',
    optimizationScore: row.optimized ?? row.optimizationScore ?? 90,
    rating: row.rating || 4.5,
    reviewsCount: row.reviews ?? row.reviewsCount ?? 0,
    lastSync: row.synced_at ? new Date(row.synced_at).toLocaleString() : 'Just now',
    platforms: platforms.length ? platforms : [
      { name: 'Google', status: 'Connected' },
      { name: 'Facebook', status: 'Connected' },
    ],
  };
}

async function loadListings() {
  loading.value = true;
  usingMock.value = false;
  try {
    const { data } = await axios.get(`${baseUrl()}/listings`);
    const rows = Array.isArray(data) ? data : [];
    if (rows.length) {
      listings.value = rows.map(mapListing);
    } else {
      usingMock.value = true;
      listings.value = mockListings;
    }
  } catch (err) {
    usingMock.value = true;
    listings.value = mockListings;
  } finally {
    loading.value = false;
  }
}

const query = ref('');
const platformFilter = ref('All');
const statusFilter = ref('All');
const locationFilter = ref('All');
const scoreFilter = ref('All');

const statusOptions = ['All', 'Connected', 'Needs Attention'];
const platformOptions = ['All', 'Google', 'Facebook', 'Yelp', 'Trustpilot', 'Bing'];
const locationOptions = ['All', 'Jaipur', 'Delhi', 'Mumbai'];
const scoreOptions = ['All', '90% - 100%', '80% - 89%', '< 80%'];

const filtered = computed(() => {
  const q = query.value.trim().toLowerCase();
  return listings.value.filter(l => {
    const matchesQuery =
      !q || l.title.toLowerCase().includes(q) || l.address.toLowerCase().includes(q);
    const matchesStatus =
      statusFilter.value === 'All' ||
      (statusFilter.value === 'Connected' && l.platforms.every(p => p.status === 'Connected')) ||
      (statusFilter.value === 'Needs Attention' && l.platforms.some(p => p.status !== 'Connected'));
    return matchesQuery && matchesStatus;
  });
});

// Dropdown state
const openMenu = ref(null);
const toggleMenu = key => {
  openMenu.value = openMenu.value === key ? null : key;
};
const closeMenus = () => {
  openMenu.value = null;
};

// Toast
const toastState = ref({ visible: false, message: '' });
let toastTimer = null;
const showToast = message => {
  toastState.value = { visible: true, message };
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    toastState.value.visible = false;
  }, 3000);
};

// Export modal & Add modal
const exportOpen = ref(false);
const exportDone = ref(false);
const exportFields = ref({
  businessName: true,
  address: true,
  phone: true,
  rating: true,
  reviews: true,
  platforms: true,
  healthScore: true,
  website: false,
  syncStatus: false,
});
const exportFieldLabels = {
  businessName: 'Business name',
  address: 'Address',
  phone: 'Phone',
  rating: 'Rating',
  reviews: 'Reviews count',
  platforms: 'Connected platforms',
  healthScore: 'Health score',
  website: 'Website',
  syncStatus: 'Sync status',
};
const handleExport = type => {
  closeMenus();
  if (type === 'advanced') {
    exportOpen.value = true;
    exportDone.value = false;
  } else {
    showToast(`Exporting ${type} file...`);
  }
};
const runExport = () => {
  exportDone.value = true;
};
const closeExport = () => {
  exportOpen.value = false;
  setTimeout(() => {
    exportDone.value = false;
  }, 300);
};

const blankForm = () => ({
  name: '',
  category: 'Restaurant',
  primaryPlatform: 'Google Business Profile',
  country: 'United States',
  address: '',
  phone: '',
  website: '',
  email: '',
  storeId: '',
  image: '',
});
const categoryOptions = ['Restaurant', 'Agency', 'Healthcare', 'Retail', 'Digital Marketing Agency', 'Other'];
const addPlatformOptions = ['Google Business Profile', 'Facebook', 'Yelp', 'Manual'];
const countryOptions = ['United States', 'India', 'United Kingdom', 'Canada'];
const addOpen = ref(false);
const addStep = ref('info');
const addForm = ref(blankForm());
const connectOption = ref('');
const connectOptionsFor = computed(() => {
  switch (addForm.value.primaryPlatform) {
    case 'Facebook': return ['Login', 'Skip'];
    case 'Yelp': return ['Connect', 'Skip'];
    case 'Manual': return ['Create Manual Listing', 'Finish'];
    default: return ['Connect Existing Account', 'Import Existing Listing', 'Skip for Now'];
  }
});
const openAdd = type => {
  closeMenus();
  addOpen.value = true;
  addStep.value = type === 'connect' ? 'connect' : 'info';
};
const addNext = async () => {
  if (addStep.value === 'info') {
    addStep.value = 'connect';
    return;
  }
  try {
    await axios.post(`${baseUrl()}/listings`, {
      name: addForm.value.name,
      address: addForm.value.address,
      category: addForm.value.category,
      country: addForm.value.country,
      phone: addForm.value.phone,
      website: addForm.value.website,
      email: addForm.value.email,
      image: addForm.value.image,
      primary: addForm.value.primaryPlatform,
      platforms: [{ name: addForm.value.primaryPlatform, ok: true }],
    });
    await loadListings();
  } catch (err) {
    console.error('Failed to create listing', err);
  }
  addStep.value = 'success';
};
const addBack = () => {
  if (addStep.value === 'connect') addStep.value = 'info';
};
const closeAdd = () => {
  addOpen.value = false;
  setTimeout(() => {
    addStep.value = 'info';
    addForm.value = blankForm();
  }, 300);
};

// Integration settings modal
const settingsOpen = ref(false);
const settingsListing = ref(null);
function openSettings(l) {
  if (l.autoSync === undefined) l.autoSync = true;
  if (l.autoReply === undefined) l.autoReply = false;
  settingsListing.value = l;
  settingsOpen.value = true;
}
const webhookUrl = computed(() =>
  settingsListing.value
    ? `${window.location.origin}/api/v1/reputation/sync/${settingsListing.value.id}`
    : ''
);
function saveSettings() {
  settingsOpen.value = false;
  showToast(`${settingsListing.value?.title || 'Listing'} settings saved`);
}
</script>

<template>
  <div class="relative flex h-[calc(100vh-4rem)] w-full overflow-hidden bg-[#FAFAFA] dark:bg-background">
    <!-- Main Content Area -->
    <div class="flex flex-col h-full w-full overflow-y-auto transition-all duration-300 custom-scrollbar">
      <!-- Header -->
      <div class="px-8 py-6 border-b border-border bg-white dark:bg-card shrink-0">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 class="text-base font-medium text-foreground flex items-center gap-2">
              Listings
              <span v-if="usingMock" class="rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400" title="Demo — sample data until you add a real listing">Demo</span>
            </h1>
            <p class="text-sm text-muted-foreground mt-1">Manage all business listings and connected review platforms.</p>
          </div>
          <div class="flex items-center gap-3">
            <!-- Export Dropdown -->
            <div class="relative">
              <button
                class="inline-flex items-center h-9 gap-2 shadow-xs bg-white dark:bg-card border border-input text-[13px] font-semibold px-4 rounded-md hover:bg-accent hover:text-accent-foreground transition-colors"
                @click.stop="toggleMenu('export')"
              >
                <Download class="size-4" /> 
                Export <ChevronDown class="size-3 opacity-50 ml-1" />
              </button>
              <div
                v-if="openMenu === 'export'"
                class="absolute right-0 mt-1 w-48 rounded-lg border border-border bg-card shadow-lg py-1 z-40"
              >
                <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="handleExport('CSV')">CSV</button>
                <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="handleExport('Excel')">Excel</button>
                <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="handleExport('PDF Report')">PDF Report</button>
                <div class="my-1 border-t border-border"></div>
                <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="handleExport('advanced')">Advanced Export...</button>
              </div>
            </div>

            <!-- Add Listing Dropdown -->
            <div class="relative">
              <button
                class="inline-flex items-center h-9 gap-2 shadow-xs bg-primary hover:bg-primary/90 text-primary-foreground text-[13px] font-semibold px-4 rounded-md transition-colors"
                @click.stop="toggleMenu('add')"
              >
                <Plus class="size-4" /> 
                Add Listing <ChevronDown class="size-3 opacity-50 ml-1" />
              </button>
              <div
                v-if="openMenu === 'add'"
                class="absolute right-0 mt-1 w-56 rounded-lg border border-border bg-card shadow-lg py-1 z-40"
              >
                <button class="w-full text-left px-3 py-2 text-sm font-medium text-primary hover:bg-muted transition-colors" @click="openAdd('connect')">
                  Connect Existing Business
                </button>
                <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="openAdd('manual')">
                  Create Manually
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- KPI Cards -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-8">
          <div v-for="s in stats" :key="s.label" class="bg-card border border-border rounded-xl p-4 shadow-xs flex flex-col justify-between">
            <div class="flex items-center gap-3 mb-2">
              <div class="size-8 rounded-full flex items-center justify-center border" :class="s.tone">
                <component :is="s.icon" class="size-4" />
              </div>
              <span class="text-2xl font-bold text-foreground">{{ s.value }}</span>
            </div>
            <span class="text-xs text-muted-foreground font-medium mb-3">{{ s.label }}</span>
            <div class="text-[10px] font-semibold flex items-center gap-1" :class="s.up ? 'text-emerald-600' : 'text-rose-600'">
              <TrendingUp v-if="s.up" class="size-3" /><TrendingDown v-else class="size-3" /> {{ s.delta }}
            </div>
          </div>
        </div>
      </div>

      <!-- Filters & Toolbar -->
      <div class="px-8 py-5 border-b border-border bg-[#FAFAFA] dark:bg-background shrink-0 sticky top-0 z-10 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div class="flex flex-wrap items-center gap-2">
          <div class="relative w-48 mr-2">
            <Search class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground z-10" />
            <Input
              v-model="query"
              type="text"
              placeholder="Search listings..."
              class-name="w-full pl-9 h-9 text-sm rounded-lg border-border bg-white dark:bg-card shadow-xs"
            />
          </div>

          <!-- Platform Dropdown -->
          <div class="relative">
            <button
              class="inline-flex items-center h-9 gap-1.5 rounded-lg text-xs font-medium bg-white dark:bg-card border border-border shadow-xs px-3 hover:bg-muted transition-colors text-foreground"
              @click.stop="toggleMenu('platform')"
            >
              Platform <ChevronDown class="size-3 opacity-50 ml-1" />
            </button>
            <div v-if="openMenu === 'platform'" class="absolute left-0 mt-1 w-44 rounded-lg border border-border bg-card shadow-lg py-1 z-40">
              <button
                v-for="opt in platformOptions"
                :key="opt"
                class="w-full flex items-center justify-between px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors"
                @click="platformFilter = opt; closeMenus()"
              >
                {{ opt }}
                <Check v-if="platformFilter === opt" class="size-3.5 text-primary" />
              </button>
            </div>
          </div>

          <!-- Status Dropdown -->
          <div class="relative">
            <button
              class="inline-flex items-center h-9 gap-1.5 rounded-lg text-xs font-medium bg-white dark:bg-card border border-border shadow-xs px-3 hover:bg-muted transition-colors text-foreground"
              :class="statusFilter !== 'All' ? 'text-primary border-primary/40' : ''"
              @click.stop="toggleMenu('status')"
            >
              {{ statusFilter === 'All' ? 'Status' : statusFilter }} <ChevronDown class="size-3 opacity-50 ml-1" />
            </button>
            <div v-if="openMenu === 'status'" class="absolute left-0 mt-1 w-44 rounded-lg border border-border bg-card shadow-lg py-1 z-40">
              <button
                v-for="opt in statusOptions"
                :key="opt"
                class="w-full flex items-center justify-between px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors"
                @click="statusFilter = opt; closeMenus()"
              >
                {{ opt }}
                <Check v-if="statusFilter === opt" class="size-3.5 text-primary" />
              </button>
            </div>
          </div>

          <!-- Location Dropdown -->
          <div class="relative">
            <button
              class="inline-flex items-center h-9 gap-1.5 rounded-lg text-xs font-medium bg-white dark:bg-card border border-border shadow-xs px-3 hover:bg-muted transition-colors text-foreground"
              @click.stop="toggleMenu('location')"
            >
              Location <ChevronDown class="size-3 opacity-50 ml-1" />
            </button>
            <div v-if="openMenu === 'location'" class="absolute left-0 mt-1 w-44 rounded-lg border border-border bg-card shadow-lg py-1 z-40">
              <button
                v-for="opt in locationOptions"
                :key="opt"
                class="w-full flex items-center justify-between px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors"
                @click="locationFilter = opt; closeMenus()"
              >
                {{ opt }}
                <Check v-if="locationFilter === opt" class="size-3.5 text-primary" />
              </button>
            </div>
          </div>

          <!-- Score Dropdown -->
          <div class="relative">
            <button
              class="inline-flex items-center h-9 gap-1.5 rounded-lg text-xs font-medium bg-white dark:bg-card border border-border shadow-xs px-3 hover:bg-muted transition-colors text-foreground"
              @click.stop="toggleMenu('score')"
            >
              Score <ChevronDown class="size-3 opacity-50 ml-1" />
            </button>
            <div v-if="openMenu === 'score'" class="absolute left-0 mt-1 w-44 rounded-lg border border-border bg-card shadow-lg py-1 z-40">
              <button
                v-for="opt in scoreOptions"
                :key="opt"
                class="w-full flex items-center justify-between px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors"
                @click="scoreFilter = opt; closeMenus()"
              >
                {{ opt }}
                <Check v-if="scoreFilter === opt" class="size-3.5 text-primary" />
              </button>
            </div>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <button class="inline-flex items-center h-9 gap-2 rounded-lg text-xs font-medium bg-white dark:bg-card border border-border shadow-xs px-3 hover:bg-muted transition-colors text-foreground">
            <Funnel class="size-3.5" /> Filters
          </button>
        </div>
      </div>

      <!-- List Area -->
      <div class="px-8 pb-10 pt-6">
        <div v-if="filtered.length === 0" class="py-16 text-center text-sm text-muted-foreground">
          No listings match “{{ query }}”.
        </div>
        <div v-else class="flex flex-col gap-5">
          <div
            v-for="listing in filtered"
            :key="listing.id"
            class="bg-white dark:bg-card border border-border rounded-xl overflow-hidden hover:shadow-md transition-all duration-300 flex cursor-pointer relative shadow-xs"
          >
            <!-- Left Thumbnail -->
            <div class="w-56 shrink-0 relative border-r border-border">
              <img v-if="listing.image" :src="listing.image" class="w-full h-full object-cover" @error="listing.image = ''" />
              <div v-else class="w-full h-full flex items-center justify-center bg-gradient-to-br text-white text-3xl font-bold select-none" :class="gradientFor(listing.title)">
                {{ (listing.title || 'L').charAt(0).toUpperCase() }}
              </div>
            </div>

            <!-- Right Content -->
            <div class="p-6 flex flex-col flex-1">
              <!-- Top Row: Title & Badges -->
              <div class="flex items-start justify-between mb-1">
                <div class="flex flex-col">
                  <div class="flex items-center gap-2 mb-1">
                    <h3 class="font-bold text-[16px] text-foreground">{{ listing.title }}</h3>
                    <span v-if="listing.badge" class="bg-primary/10 text-primary border border-primary/20 shadow-none font-medium text-[10px] px-2 py-0.5 rounded-full">
                      {{ listing.badge }}
                    </span>
                  </div>
                  <p class="text-[13px] text-muted-foreground">{{ listing.address }}</p>
                </div>

                <div class="flex items-center gap-4">
                  <div class="flex items-center gap-2">
                    <span class="bg-emerald-50 text-emerald-600 border border-emerald-100 shadow-none font-bold text-xs px-2 py-0.5 rounded-md">
                      {{ listing.optimizationScore }}%
                    </span>
                    <span class="text-xs text-muted-foreground font-medium">Optimized</span>
                  </div>
                </div>
              </div>

              <!-- Middle Row: Connected Platforms & Ratings -->
              <div class="flex items-center justify-between mt-6">
                <div>
                  <h4 class="text-[11px] font-bold text-muted-foreground mb-2">Connected Platforms</h4>
                  <div class="flex items-center gap-3">
                    <div v-for="platform in listing.platforms" :key="platform.name" class="relative group cursor-pointer">
                      <div class="size-8 rounded-full bg-white border border-border shadow-xs flex items-center justify-center p-1.5" v-html="getPlatformIcon(platform.name)"></div>
                      <div
                        class="absolute -bottom-1 -right-1 size-4 rounded-full flex items-center justify-center ring-2 ring-white dark:ring-card"
                        :class="platform.status === 'Connected' ? 'bg-emerald-500' : 'bg-rose-500'"
                      >
                        <Check v-if="platform.status === 'Connected'" class="size-2.5 text-white" style="stroke-width: 3" />
                        <X v-else class="size-2.5 text-white" style="stroke-width: 3" />
                      </div>

                      <!-- Tooltip -->
                      <div class="absolute -top-8 left-1/2 -translate-x-1/2 px-2 py-1 bg-black/80 backdrop-blur-sm text-white text-[10px] font-medium rounded opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap shadow-xs border border-white/10 z-10">
                        {{ platform.name }}
                      </div>
                    </div>
                    <div class="size-8 rounded-full bg-muted border border-border flex items-center justify-center text-[11px] font-semibold text-muted-foreground ml-1">+2</div>
                  </div>
                </div>

                <div class="flex flex-col items-end gap-3 text-right">
                  <div class="flex items-center gap-2">
                    <div class="flex items-center text-[13px] font-bold text-foreground">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="#FBBF24" stroke="#FBBF24" stroke-width="1" stroke-linecap="round" stroke-linejoin="round" class="mr-1.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                      {{ listing.rating }}
                      <span class="text-muted-foreground font-normal mx-1.5">•</span>
                      <span class="text-muted-foreground font-medium">{{ listing.reviewsCount }} Reviews</span>
                    </div>
                  </div>
                  <div class="flex items-center gap-2">
                    <div class="flex flex-col text-right">
                      <span class="text-[10px] text-muted-foreground">Last sync</span>
                      <span class="text-[11.5px] font-semibold text-foreground">{{ listing.lastSync }}</span>
                    </div>
                    <CircleCheck class="size-4 text-emerald-500 ml-1" />
                  </div>
                </div>
              </div>

              <!-- Bottom Actions -->
              <div class="flex items-center justify-between mt-6 pt-4 border-t border-border">
                <div class="flex items-center gap-3">
                  <button
                    class="inline-flex items-center h-8 gap-2 text-xs font-semibold text-primary border border-primary/30 hover:bg-primary/5 rounded-md px-3 shadow-xs transition-colors"
                    @click.stop="openSettings(listing)"
                  >
                    <Building2 class="size-3.5" /> Manage Listing
                  </button>
                  <button
                    class="inline-flex items-center h-8 gap-2 text-xs font-medium bg-white dark:bg-card border border-border hover:bg-muted rounded-md px-3 shadow-xs transition-colors text-foreground"
                    @click.stop="showToast(`${listing.reviewsCount} reviews for ${listing.title}`)"
                  >
                    View Reviews
                  </button>
                  <button
                    class="inline-flex items-center h-8 gap-2 text-xs font-medium bg-white dark:bg-card border border-border hover:bg-muted rounded-md px-3 shadow-xs transition-colors text-foreground"
                    @click.stop="showToast(`Syncing ${listing.title}...`)"
                  >
                    <RotateCw class="size-3.5" /> Sync Now
                  </button>
                </div>
                <div class="relative">
                  <button
                    class="inline-flex items-center justify-center size-8 bg-white dark:bg-card border border-border hover:bg-muted rounded-md shadow-xs transition-colors"
                    @click.stop="toggleMenu('actions_' + listing.id)"
                  >
                    <MoreHorizontal class="size-4 text-muted-foreground" />
                  </button>
                  <div
                    v-if="openMenu === 'actions_' + listing.id"
                    class="absolute right-0 mt-1 w-48 rounded-lg border border-border bg-card shadow-lg py-1 z-40"
                  >
                    <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="showToast('Rename action')">Rename</button>
                    <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="showToast('Duplicate action')">Duplicate</button>
                    <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="showToast('Disconnect action')">Disconnect</button>
                    <button class="w-full text-left px-3 py-2 text-sm text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950 transition-colors" @click="showToast('Delete action')">Delete</button>
                    <div class="my-1 border-t border-border"></div>
                    <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="showToast('View history')">View History</button>
                    <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="showToast('Exporting listing...')">Export</button>
                    <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="showToast('Copied review link!')">Copy Review Link</button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Backdrop for dropdowns -->
    <div v-if="openMenu" class="fixed inset-0 z-30" @click="closeMenus"></div>

    <!-- Toast Notification -->
    <div
      class="fixed bottom-6 right-6 z-50 bg-foreground text-background px-4 py-3 rounded-lg shadow-xl font-medium text-sm transition-all duration-300 transform flex items-center gap-2"
      :class="toastState.visible ? 'translate-y-0 opacity-100' : 'translate-y-4 opacity-0 pointer-events-none'"
    >
      <CircleCheck class="size-4 text-emerald-400" />
      {{ toastState.message }}
    </div>

    <!-- Add Listing Modal (multi-step) -->
    <div v-if="addOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-black/50 backdrop-blur-sm" @click="closeAdd"></div>
      <div class="relative w-full max-w-xl bg-card border border-border shadow-2xl rounded-2xl overflow-hidden flex flex-col max-h-[90vh]">
        <div class="px-6 py-5 border-b border-border flex items-center justify-between bg-muted/30 shrink-0">
          <div class="flex items-center gap-3">
            <div class="size-10 rounded-xl bg-primary/10 flex items-center justify-center border border-primary/20 text-primary">
              <Building2 v-if="addStep === 'info'" class="size-5" />
              <LinkIcon v-else-if="addStep === 'connect'" class="size-5" />
              <CircleCheck v-else class="size-5" />
            </div>
            <div>
              <h2 class="text-lg font-bold text-foreground">
                {{ addStep === 'info' ? 'Add New Listing' : addStep === 'connect' ? 'Connect Platform' : 'Listing Added' }}
              </h2>
              <p class="text-sm text-muted-foreground font-medium">
                {{ addStep === 'info' ? 'Create a new business location.' : addStep === 'connect' ? 'Step 2 / 2' : 'You’re all set.' }}
              </p>
            </div>
          </div>
          <button class="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:bg-muted transition-colors" @click="closeAdd">
            <X class="size-5" />
          </button>
        </div>

        <!-- Step 1: Info -->
        <div v-if="addStep === 'info'" class="p-6 flex flex-col gap-6 overflow-y-auto">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Business Name <span class="text-destructive">*</span></label>
              <input v-model="addForm.name" type="text" placeholder="E.g. Jaipur HQ" class="reset-base h-10 px-4 text-[14px] shadow-sm rounded-md border border-border/80 bg-background text-foreground focus-visible:ring-1 focus-visible:ring-primary/30 focus-visible:outline-none" />
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Business Category <span class="text-destructive">*</span></label>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <button type="button" class="w-full h-10 px-4 inline-flex items-center justify-between text-[14px] font-normal shadow-sm rounded-md border border-border/80 bg-background text-foreground focus-visible:ring-1 focus-visible:ring-primary/30 focus-visible:outline-none cursor-pointer">
                    <span class="truncate">{{ addForm.category }}</span> <ChevronDown class="size-4 opacity-50 shrink-0" />
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="min-w-[12rem]">
                  <DropdownMenuItem v-for="c in categoryOptions" :key="c" class="text-[13px] cursor-pointer" @click="addForm.category = c">{{ c }}</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Primary Platform <span class="text-destructive">*</span></label>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <button type="button" class="w-full h-10 px-4 inline-flex items-center justify-between text-[14px] font-normal shadow-sm rounded-md border border-border/80 bg-background text-foreground focus-visible:ring-1 focus-visible:ring-primary/30 focus-visible:outline-none cursor-pointer">
                    <span class="truncate">{{ addForm.primaryPlatform }}</span> <ChevronDown class="size-4 opacity-50 shrink-0" />
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="min-w-[12rem]">
                  <DropdownMenuItem v-for="p in addPlatformOptions" :key="p" class="text-[13px] cursor-pointer" @click="addForm.primaryPlatform = p">{{ p }}</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Country <span class="text-destructive">*</span></label>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <button type="button" class="w-full h-10 px-4 inline-flex items-center justify-between text-[14px] font-normal shadow-sm rounded-md border border-border/80 bg-background text-foreground focus-visible:ring-1 focus-visible:ring-primary/30 focus-visible:outline-none cursor-pointer">
                    <span class="truncate">{{ addForm.country }}</span> <ChevronDown class="size-4 opacity-50 shrink-0" />
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="min-w-[12rem]">
                  <DropdownMenuItem v-for="c in countryOptions" :key="c" class="text-[13px] cursor-pointer" @click="addForm.country = c">{{ c }}</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Address <span class="text-destructive">*</span></label>
              <div class="relative">
                <MapPin class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
                <input v-model="addForm.address" type="text" placeholder="123 Main St, City, State" class="reset-base w-full pl-9 pr-4 h-10 text-[14px] shadow-sm rounded-md border border-border/80 bg-background text-foreground focus-visible:ring-1 focus-visible:ring-primary/30 focus-visible:outline-none" />
              </div>
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Phone <span class="text-destructive">*</span></label>
              <div class="relative">
                <Phone class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
                <input v-model="addForm.phone" type="text" placeholder="+1 (555) 000-0000" class="reset-base w-full pl-9 pr-4 h-10 text-[14px] shadow-sm rounded-md border border-border/80 bg-background text-foreground focus-visible:ring-1 focus-visible:ring-primary/30 focus-visible:outline-none" />
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Website</label>
              <div class="relative">
                <Globe class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
                <input v-model="addForm.website" type="text" placeholder="https://example.com" class="reset-base w-full pl-9 pr-4 h-10 text-[14px] shadow-sm rounded-md border border-border/80 bg-background text-foreground focus-visible:ring-1 focus-visible:ring-primary/30 focus-visible:outline-none" />
              </div>
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Business Email</label>
              <div class="relative">
                <Mail class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
                <input v-model="addForm.email" type="email" placeholder="hello@company.com" class="reset-base w-full pl-9 pr-4 h-10 text-[14px] shadow-sm rounded-md border border-border/80 bg-background text-foreground focus-visible:ring-1 focus-visible:ring-primary/30 focus-visible:outline-none" />
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Store ID <span class="text-muted-foreground font-normal">(Optional)</span></label>
              <div class="relative">
                <Hash class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
                <input v-model="addForm.storeId" type="text" placeholder="Internal ID or Code" class="reset-base w-full pl-9 pr-4 h-10 text-[14px] shadow-sm rounded-md border border-border/80 bg-background text-foreground focus-visible:ring-1 focus-visible:ring-primary/30 focus-visible:outline-none" />
              </div>
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Photo URL <span class="text-muted-foreground font-normal">(Optional)</span></label>
              <div class="relative">
                <ImageIcon class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
                <input v-model="addForm.image" type="text" placeholder="https://…/photo.jpg" class="reset-base w-full pl-9 pr-4 h-10 text-[14px] shadow-sm rounded-md border border-border/80 bg-background text-foreground focus-visible:ring-1 focus-visible:ring-primary/30 focus-visible:outline-none" />
              </div>
            </div>
          </div>
          <p class="text-[12px] text-muted-foreground -mt-2">Leave Photo URL blank to auto-fetch the storefront photo from Google.</p>
        </div>

        <!-- Step 2: Connect -->
        <div v-else-if="addStep === 'connect'" class="p-6 flex flex-col gap-6 overflow-y-auto">
          <div class="flex items-center gap-3 mb-1">
            <div class="size-10 rounded-full flex items-center justify-center shadow-sm border border-border shrink-0"
                 :class="addForm.primaryPlatform === 'Manual' ? 'bg-muted text-muted-foreground' : 'bg-white'"
                 v-html="addForm.primaryPlatform === 'Manual' ? '' : getPlatformIcon(addForm.primaryPlatform.split(' ')[0])">
            </div>
            <div>
              <h3 class="text-lg font-bold text-foreground">
                {{ addForm.primaryPlatform === 'Manual' ? 'Create Manual Listing' : `Connect ${addForm.primaryPlatform}` }}
              </h3>
              <p class="text-[13px] text-muted-foreground">
                {{ addForm.primaryPlatform === 'Manual' ? 'This listing will not be synced to external platforms.' : 'Select how you want to connect.' }}
              </p>
            </div>
          </div>

          <div class="flex flex-col gap-3">
            <label v-for="opt in connectOptionsFor" :key="opt" class="flex items-center gap-3 p-4 border rounded-lg cursor-pointer transition-colors" :class="connectOption === opt ? 'bg-primary/5 border-primary ring-1 ring-primary/20' : 'border-border hover:bg-muted/50'">
              <input type="radio" :value="opt" v-model="connectOption" class="size-4 accent-[color:var(--primary)]" />
              <span class="text-[14px] font-semibold text-foreground">{{ opt }}</span>
            </label>
          </div>
        </div>

        <!-- Step 3: Success -->
        <div v-else class="p-8 flex flex-col items-center justify-center gap-6 min-h-[320px] text-center">
          <div class="size-16 rounded-full bg-emerald-500/10 text-emerald-500 flex items-center justify-center border-4 border-emerald-500/15">
            <CircleCheck class="size-8" />
          </div>
          <div>
            <div class="text-xl font-bold text-foreground">Listing Created</div>
            <div class="text-[15px] font-semibold text-primary mt-1">{{ addForm.name || 'Your Business' }}</div>
          </div>
          <div class="w-full mt-2 flex flex-col items-center gap-4">
            <p class="text-[13px] text-muted-foreground font-semibold">What would you like to do?</p>
            <div class="flex flex-col w-full max-w-xs gap-3">
              <button class="w-full h-10 rounded-lg font-semibold border border-border bg-card shadow-sm text-[14px] text-foreground hover:bg-muted transition-colors" @click="closeAdd">Connect Platform</button>
              <button class="w-full h-10 rounded-lg font-semibold border border-border bg-card shadow-sm text-[14px] text-foreground hover:bg-muted transition-colors" @click="closeAdd">Add Business Hours</button>
              <button class="w-full h-10 rounded-lg font-semibold border border-border bg-card shadow-sm text-[14px] text-foreground hover:bg-muted transition-colors" @click="closeAdd">Open Listing</button>
              <button class="w-full h-10 rounded-lg font-semibold bg-primary hover:bg-primary/90 text-primary-foreground shadow-sm text-[14px] transition-colors" @click="closeAdd">Done</button>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div v-if="addStep === 'info' || addStep === 'connect'" class="px-6 py-4 border-t border-border flex items-center justify-between shrink-0 bg-muted/20">
          <button class="inline-flex items-center gap-1.5 text-sm font-semibold text-muted-foreground hover:text-foreground transition-colors px-2" @click="addStep === 'info' ? closeAdd() : addBack()">
            <template v-if="addStep === 'connect'"><ArrowLeft class="size-4" /> Back</template>
            <template v-else>Cancel</template>
          </button>
          <button class="rounded-md bg-primary px-6 py-2 text-sm font-semibold text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors disabled:opacity-50 inline-flex items-center gap-1.5" :disabled="addStep === 'info' && !addForm.name" @click="addNext">
            {{ addStep === 'info' ? 'Continue →' : 'Create Listing' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Export Modal (advanced) -->
    <div v-if="exportOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-black/50 backdrop-blur-sm" @click="closeExport"></div>
      <div class="relative w-full max-w-md bg-card border border-border shadow-2xl rounded-2xl overflow-hidden flex flex-col">
        <div class="px-6 py-5 border-b border-border flex items-center justify-between bg-muted/30">
          <div class="flex items-center gap-3">
            <div class="size-10 rounded-xl bg-primary/10 flex items-center justify-center border border-primary/20 text-primary">
              <Download class="size-5" />
            </div>
            <div>
              <h2 class="text-lg font-bold text-foreground">Advanced Export</h2>
              <p class="text-sm text-muted-foreground font-medium">Choose the columns to include.</p>
            </div>
          </div>
          <button class="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:bg-muted transition-colors" @click="closeExport">
            <X class="size-5" />
          </button>
        </div>

        <div class="px-6 py-5">
          <div v-if="!exportDone" class="grid grid-cols-2 gap-2.5">
            <label v-for="(label, key) in exportFieldLabels" :key="key" class="flex items-center gap-2 p-2.5 rounded-lg border border-border hover:bg-muted/40 cursor-pointer transition-colors">
              <input type="checkbox" v-model="exportFields[key]" class="size-4 accent-[color:var(--primary)]" />
              <span class="text-sm text-foreground">{{ label }}</span>
            </label>
          </div>
          <div v-else class="flex flex-col items-center justify-center text-center py-6">
            <div class="size-14 rounded-full bg-emerald-500/10 text-emerald-500 flex items-center justify-center mb-4">
              <CircleCheck class="size-8" />
            </div>
            <h3 class="text-base font-semibold text-foreground">Export ready</h3>
            <p class="text-sm text-muted-foreground mt-1">Your file has been generated.</p>
          </div>
        </div>

        <div class="px-6 py-4 border-t border-border flex justify-end gap-2 bg-muted/20">
          <button class="rounded-lg border border-border px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted/50 transition-colors" @click="closeExport">
            {{ exportDone ? 'Close' : 'Cancel' }}
          </button>
          <button v-if="!exportDone" class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow-xs hover:bg-primary/90 transition-colors" @click="runExport">
            <Download class="size-4" /> Export
          </button>
        </div>
      </div>
    </div>

    <!-- Integration Settings Modal -->
    <div v-if="settingsOpen && settingsListing" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-background/80 backdrop-blur-sm" @click="settingsOpen = false"></div>
      <div class="relative bg-card border border-border rounded-2xl shadow-lg max-w-lg w-full p-6 space-y-5">
        <div class="flex items-center justify-between pb-3 border-b border-border">
          <div class="flex items-center gap-2.5">
            <Building2 class="size-5 text-primary" />
            <h2 class="text-[15px] font-semibold text-foreground">{{ settingsListing.title }} Integration Settings</h2>
          </div>
          <button class="text-muted-foreground hover:text-foreground" @click="settingsOpen = false">
            <X class="size-4" />
          </button>
        </div>

        <div class="space-y-4 text-[13.5px]">
          <div class="flex items-center justify-between p-3.5 rounded-xl bg-muted/40 border border-border">
            <div>
              <div class="font-medium text-foreground">Automatic Review Sync</div>
              <div class="text-[12px] text-muted-foreground">Pull incoming reviews in real-time every 15 minutes</div>
            </div>
            <RelaySwitch v-model="settingsListing.autoSync" />
          </div>

          <div class="flex items-center justify-between p-3.5 rounded-xl bg-muted/40 border border-border">
            <div>
              <div class="font-medium text-foreground">Relay AI Smart Auto-Reply</div>
              <div class="text-[12px] text-muted-foreground">Auto-draft and publish on-brand responses to 5-star ratings</div>
            </div>
            <RelaySwitch v-model="settingsListing.autoReply" />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">Sync Webhook Endpoint</label>
            <input readonly :value="webhookUrl" class="h-9 px-3 text-[13px] rounded-md border border-border bg-muted/30 font-mono text-muted-foreground focus:outline-none" />
          </div>
        </div>

        <div class="flex items-center justify-end gap-2 pt-3 border-t border-border">
          <button class="rounded-lg border border-border px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted/50 transition-colors" @click="settingsOpen = false">
            Cancel
          </button>
          <button class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow-xs hover:bg-primary/90 transition-colors" @click="saveSettings">
            Save Changes
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
