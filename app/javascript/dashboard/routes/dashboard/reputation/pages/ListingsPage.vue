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
  Star,
  CheckCircle as CircleCheck,
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
} from 'lucide-vue-next';
import { RelaySwitch } from 'dashboard/components-next/relay';

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
// DEMO / MOCK DATA — no listings backend yet. The whole page is sample data;
// the single "Demo" badge in the header flags it. Wire real endpoints later.
// ---------------------------------------------------------------------------
const stats = [
  { icon: Building2, tone: 'bg-primary/10 text-primary border-primary/20', value: '24', label: 'Listings', delta: '12% vs last month', up: true },
  { icon: Layers, tone: 'bg-primary/10 text-primary border-primary/20', value: '67', label: 'Platforms', delta: '8% vs last month', up: true },
  { icon: TrendingUp, tone: 'bg-emerald-50 text-emerald-600 border-emerald-100', value: '98%', label: 'Sync Rate', delta: '2% vs last month', up: true },
  { icon: TriangleAlert, tone: 'bg-amber-50 text-amber-500 border-amber-100', value: '3', label: 'Need Attention', delta: '3% vs last month', up: false },
];

const googleIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>`;
const facebookIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" fill="#1877F2"/></svg>`;
const bingIcon = `<svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg"><path d="M5 3l4.2 1.48v11.9l5.06-2.92-2.48-1.16-1.57-3.9 7.79 2.74v4.14L9.2 21 5 18.66z" fill="#008373"/></svg>`;

const mockListings = [
  {
    id: 1,
    name: 'Jaipur HQ',
    primary: true,
    address: 'Gopalpura Bypass, Jaipur, Rajasthan 302018',
    image: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=600&auto=format&fit=crop',
    optimized: 94,
    rating: '4.8',
    reviews: 582,
    lastSync: '2 mins ago',
    synced: true,
    platforms: [
      { name: 'Google', icon: googleIcon, ok: true },
      { name: 'Facebook', icon: facebookIcon, ok: true },
      { name: 'Bing', icon: bingIcon, ok: false },
    ],
    extra: 2,
  },
  {
    id: 2,
    name: 'Mumbai Flagship',
    primary: false,
    address: 'Bandra Kurla Complex, Mumbai, Maharashtra 400051',
    image: 'https://images.unsplash.com/photo-1449157291145-7efd050a4d0e?q=80&w=600&auto=format&fit=crop',
    optimized: 88,
    rating: '4.6',
    reviews: 341,
    lastSync: '1 hour ago',
    synced: true,
    platforms: [
      { name: 'Google', icon: googleIcon, ok: true },
      { name: 'Facebook', icon: facebookIcon, ok: false },
    ],
    extra: 1,
  },
  {
    id: 3,
    name: 'Bengaluru Tech Park',
    primary: false,
    address: 'Outer Ring Road, Bengaluru, Karnataka 560103',
    image: 'https://images.unsplash.com/photo-1493397212122-2b85dda8106b?q=80&w=600&auto=format&fit=crop',
    optimized: 72,
    rating: '4.3',
    reviews: 129,
    lastSync: '3 days ago',
    synced: false,
    platforms: [
      { name: 'Google', icon: googleIcon, ok: true },
      { name: 'Bing', icon: bingIcon, ok: false },
    ],
    extra: 0,
  },
];

const axios = window.axios;
const baseUrl = () => `/api/v1/accounts/${accountId}/reputation`;
const platformIcons = { Google: googleIcon, Facebook: facebookIcon, Bing: bingIcon };
const listings = ref([]);
const usingMock = ref(false);
const loading = ref(true);

function mapListing(row) {
  const platforms = (row.platforms || []).map(p => ({
    name: p.name,
    ok: !!p.ok,
    icon: platformIcons[p.name] || googleIcon,
  }));
  return {
    id: row.id,
    name: row.name,
    primary: !!row.primary,
    address: row.address || '',
    image:
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=600&auto=format&fit=crop',
    optimized: row.optimized ?? 0,
    rating: row.rating || '—',
    reviews: row.reviews ?? 0,
    lastSync: row.synced_at ? new Date(row.synced_at).toLocaleString() : 'Never',
    synced: !!row.synced_at,
    platforms,
    extra: 0,
    autoSync: row.auto_sync ?? true,
    autoReply: row.auto_reply ?? false,
  };
}

// --- Integration settings modal (Auto Sync / Smart Auto-Reply / Webhook) ---
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
  showToast(`${settingsListing.value?.name || 'Listing'} settings saved`);
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
    console.error('Failed to load listings', err);
    usingMock.value = true;
    listings.value = mockListings;
  } finally {
    loading.value = false;
  }
}

const query = ref('');
const statusFilter = ref('All'); // All | Connected | Needs Attention
const statusOptions = ['All', 'Connected', 'Needs Attention'];
const listingStatus = l => (l.platforms.every(p => p.ok) ? 'Connected' : 'Needs Attention');

const filtered = computed(() => {
  const q = query.value.trim().toLowerCase();
  return listings.value.filter(l => {
    const matchesQuery =
      !q || l.name.toLowerCase().includes(q) || l.address.toLowerCase().includes(q);
    const matchesStatus =
      statusFilter.value === 'All' || listingStatus(l) === statusFilter.value;
    return matchesQuery && matchesStatus;
  });
});

// --- Lightweight dropdown menus (one open at a time; backdrop closes) ---
const openMenu = ref(null);
const toggleMenu = key => {
  openMenu.value = openMenu.value === key ? null : key;
};
const closeMenus = () => {
  openMenu.value = null;
};

// --- Toast ---
const toast = ref({ visible: false, message: '' });
let toastTimer = null;
const showToast = message => {
  toast.value = { visible: true, message };
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    toast.value.visible = false;
  }, 3000);
};

// --- Export feature (dropdown → toast, or Advanced → modal) ---
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
    showToast(`Exporting ${type} file…`);
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

// --- Add Listing feature (multi-step modal) ---
const blankForm = () => ({
  name: '',
  category: 'Digital Marketing Agency',
  country: 'India',
  address: '',
  phone: '',
  website: '',
  email: '',
});
const addOpen = ref(false);
const addStep = ref('info'); // info | connect | success
const addForm = ref(blankForm());
const connectPlatforms = [
  { name: 'Google', icon: googleIcon },
  { name: 'Facebook', icon: facebookIcon },
  { name: 'Bing', icon: bingIcon },
];
const connectSelected = ref('Google');
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
      platforms: [{ name: connectSelected.value, ok: true }],
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
</script>

<template>
  <!-- eslint-disable -->
  <div class="flex flex-col h-full w-full overflow-y-auto bg-background">
    <!-- Header -->
    <div class="px-8 py-6 border-b border-border bg-card shrink-0">
      <div class="flex items-center text-sm text-muted-foreground mb-2">
        <span>Reputation</span><span class="mx-2">/</span><span class="text-foreground">Listings</span>
      </div>
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 class="text-base font-medium text-foreground flex items-center gap-2">
            Listings
            <span v-if="usingMock" class="rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400" title="Demo — sample data until you add a real listing">Demo</span>
          </h1>
          <p class="text-sm text-muted-foreground mt-1">Manage all business listings and connected review platforms.</p>
        </div>
        <div class="flex items-center gap-3">
          <!-- Export dropdown -->
          <div class="relative">
            <button
              class="inline-flex items-center h-9 gap-2 shadow-sm bg-card border border-input text-[13px] font-semibold px-4 rounded-md hover:bg-accent hover:text-accent-foreground transition-colors"
              @click.stop="toggleMenu('export')"
            >
              <Download class="size-4" /> Export <ChevronDown class="size-3 opacity-50 ml-1" />
            </button>
            <div
              v-if="openMenu === 'export'"
              class="absolute right-0 mt-1 w-48 rounded-lg border border-border bg-card shadow-lg py-1 z-40"
            >
              <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="handleExport('CSV')">CSV</button>
              <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="handleExport('Excel')">Excel</button>
              <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="handleExport('PDF Report')">PDF Report</button>
              <div class="my-1 border-t border-border"></div>
              <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="handleExport('advanced')">Advanced Export…</button>
            </div>
          </div>

          <!-- Add Listing dropdown -->
          <div class="relative">
            <button
              class="inline-flex items-center h-9 gap-2 shadow-sm bg-primary hover:bg-primary/90 text-primary-foreground text-[13px] font-semibold px-4 rounded-md transition-colors"
              @click.stop="toggleMenu('add')"
            >
              <Plus class="size-4" /> Add Listing <ChevronDown class="size-3 opacity-50 ml-1" />
            </button>
            <div
              v-if="openMenu === 'add'"
              class="absolute right-0 mt-1 w-56 rounded-lg border border-border bg-card shadow-lg py-1 z-40"
            >
              <button class="w-full text-left px-3 py-2 text-sm font-medium text-primary hover:bg-muted transition-colors" @click="openAdd('connect')">Connect existing profile</button>
              <button class="w-full text-left px-3 py-2 text-sm text-foreground hover:bg-muted transition-colors" @click="openAdd('manual')">Add manually</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Stat cards -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-8">
        <div v-for="s in stats" :key="s.label" class="bg-card border border-border rounded-xl p-4 shadow-sm flex flex-col justify-between">
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

    <!-- Filter bar -->
    <div class="px-8 py-5 border-b border-border bg-background shrink-0 sticky top-0 z-10 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div class="flex flex-wrap items-center gap-2">
        <div class="relative w-48 mr-2">
          <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <input
            v-model="query"
            type="text"
            placeholder="Search listings..."
            class="w-full pl-9 bg-card border border-border shadow-sm h-9 text-sm rounded-lg focus-visible:ring-1 focus-visible:ring-ring focus-visible:outline-none placeholder:text-muted-foreground px-3 py-1 transition-colors"
          />
        </div>
        <!-- Status filter (functional) -->
        <div class="relative">
          <button
            class="inline-flex items-center h-9 gap-1.5 rounded-lg text-xs font-medium bg-card border border-input shadow-sm px-3 hover:bg-muted transition-colors"
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

        <!-- Platform / Location / Score (Demo menus) -->
        <div v-for="f in ['Platform', 'Location', 'Score']" :key="f" class="relative">
          <button
            class="inline-flex items-center h-9 gap-1.5 rounded-lg text-xs font-medium bg-card border border-input shadow-sm px-3 hover:bg-muted transition-colors"
            @click.stop="toggleMenu(f)"
          >
            {{ f }} <ChevronDown class="size-3 opacity-50 ml-1" />
          </button>
          <div v-if="openMenu === f" class="absolute left-0 mt-1 w-44 rounded-lg border border-border bg-card shadow-lg py-2 px-3 z-40">
            <span class="rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400">Demo</span>
            <p class="text-xs text-muted-foreground mt-1.5">{{ f }} filtering not wired yet.</p>
          </div>
        </div>
      </div>
      <div class="flex items-center gap-3">
        <button class="inline-flex items-center h-9 gap-2 rounded-lg text-xs font-medium bg-card border border-input shadow-sm px-3 hover:bg-muted transition-colors">
          <Funnel class="size-3.5" /> Filters
        </button>
      </div>
    </div>

    <!-- Listing cards -->
    <div class="px-8 pb-10 pt-6">
      <div v-if="filtered.length === 0" class="py-16 text-center text-sm text-muted-foreground">
        No listings match “{{ query }}”.
      </div>
      <div v-else class="flex flex-col gap-5">
        <div
          v-for="l in filtered"
          :key="l.id"
          class="bg-card border border-border rounded-xl overflow-hidden hover:shadow-md transition-all duration-300 flex cursor-pointer relative shadow-sm"
        >
          <!-- Image -->
          <div class="w-56 shrink-0 relative border-r border-border hidden sm:block">
            <img :src="l.image" class="w-full h-full object-cover" />
          </div>

          <!-- Content -->
          <div class="p-6 flex flex-col flex-1">
            <div class="flex items-start justify-between mb-1">
              <div class="flex flex-col">
                <div class="flex items-center gap-2 mb-1">
                  <h3 class="font-bold text-[16px] text-foreground">{{ l.name }}</h3>
                  <span v-if="l.primary" class="inline-flex items-center bg-primary/10 text-primary border border-primary/20 font-medium text-[10px] px-2 py-0.5 rounded-full">Primary</span>
                </div>
                <p class="text-[13px] text-muted-foreground">{{ l.address }}</p>
              </div>
              <div class="flex items-center gap-2">
                <span class="inline-flex items-center bg-emerald-50 text-emerald-600 border border-emerald-100 font-bold text-xs px-2 py-0.5 rounded-md">{{ l.optimized }}%</span>
                <span class="text-xs text-muted-foreground font-medium">Optimized</span>
              </div>
            </div>

            <div class="flex items-center justify-between mt-6">
              <!-- Connected platforms -->
              <div>
                <h4 class="text-[11px] font-bold text-muted-foreground mb-2">Connected Platforms</h4>
                <div class="flex items-center gap-3">
                  <div v-for="p in l.platforms" :key="p.name" class="relative group">
                    <div class="size-8 rounded-full bg-white border border-border shadow-sm flex items-center justify-center p-1.5" v-html="p.icon"></div>
                    <div class="absolute -bottom-1 -right-1 size-4 rounded-full flex items-center justify-center ring-2 ring-card" :class="p.ok ? 'bg-emerald-500' : 'bg-rose-500'">
                      <Check v-if="p.ok" class="size-2.5 text-white" style="stroke-width: 3" />
                      <X v-else class="size-2.5 text-white" style="stroke-width: 3" />
                    </div>
                    <div class="absolute -top-8 left-1/2 -translate-x-1/2 px-2 py-1 bg-black/80 backdrop-blur-sm text-white text-[10px] font-medium rounded opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap shadow-sm z-10">{{ p.name }}</div>
                  </div>
                  <div v-if="l.extra > 0" class="size-8 rounded-full bg-muted border border-border flex items-center justify-center text-[11px] font-semibold text-muted-foreground ml-1">+{{ l.extra }}</div>
                </div>
              </div>

              <!-- Rating + last sync -->
              <div class="flex flex-col items-end gap-3 text-right">
                <div class="flex items-center text-[13px] font-bold text-foreground">
                  <Star class="size-3.5 mr-1.5" fill="#FBBF24" stroke="#FBBF24" />
                  {{ l.rating }}
                  <span class="text-muted-foreground font-normal mx-1.5">•</span>
                  <span class="text-muted-foreground font-medium">{{ l.reviews }} Reviews</span>
                </div>
                <div class="flex items-center gap-2">
                  <div class="flex flex-col text-right">
                    <span class="text-[10px] text-muted-foreground">Last sync</span>
                    <span class="text-[11.5px] font-semibold text-foreground">{{ l.lastSync }}</span>
                  </div>
                  <CircleCheck class="size-4 ml-1" :class="l.synced ? 'text-emerald-500' : 'text-amber-500'" />
                </div>
              </div>
            </div>

            <!-- Footer actions -->
            <div class="flex items-center justify-between mt-6 pt-4 border-t border-border">
              <div class="flex items-center gap-3">
                <button class="inline-flex items-center h-8 gap-2 text-xs font-semibold text-primary border border-primary/30 hover:bg-primary/5 rounded-md px-3 shadow-sm transition-colors" @click="openSettings(l)">
                  <Building2 class="size-3.5" /> Manage Listing
                </button>
                <button class="inline-flex items-center h-8 gap-2 text-xs font-medium bg-card border border-border hover:bg-muted rounded-md px-3 shadow-sm transition-colors" @click="showToast(`${l.reviews} reviews for ${l.name}`)">
                  View Reviews
                </button>
                <button class="inline-flex items-center h-8 gap-2 text-xs font-medium bg-card border border-border hover:bg-muted rounded-md px-3 shadow-sm transition-colors" @click="showToast(`Syncing ${l.name}…`)">
                  <RotateCw class="size-3.5" /> Sync Now
                </button>
              </div>
              <button class="inline-flex items-center justify-center size-8 rounded-md border border-border bg-card hover:bg-muted shadow-sm transition-colors" @click="showToast('More actions coming soon')">
                <MoreHorizontal class="size-4 text-muted-foreground" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Click-away backdrop for dropdown menus -->
    <div v-if="openMenu" class="fixed inset-0 z-30" @click="closeMenus"></div>

    <!-- Toast -->
    <transition name="fade">
      <div v-if="toast.visible" class="fixed bottom-6 left-1/2 -translate-x-1/2 z-[60] flex items-center gap-2 rounded-lg bg-foreground text-background px-4 py-2.5 text-sm font-medium shadow-lg">
        <CircleCheck class="size-4 text-emerald-400" />
        {{ toast.message }}
      </div>
    </transition>

    <!-- Add Listing modal (multi-step) -->
    <div v-if="addOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-black/50 backdrop-blur-sm" @click="closeAdd"></div>
      <div class="relative w-full max-w-xl bg-card border border-border shadow-2xl rounded-2xl overflow-hidden flex flex-col max-h-[90vh]">
        <!-- Header -->
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

        <!-- Body -->
        <div class="px-6 py-5 overflow-y-auto">
          <!-- Step: info -->
          <div v-if="addStep === 'info'" class="space-y-4">
            <div class="space-y-1.5">
              <label class="text-xs font-semibold text-foreground">Business name</label>
              <input v-model="addForm.name" type="text" placeholder="e.g. Jaipur HQ" class="w-full h-10 rounded-lg border border-border bg-background px-3 text-sm shadow-sm focus-visible:ring-1 focus-visible:ring-ring focus-visible:outline-none" />
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div class="space-y-1.5">
                <label class="text-xs font-semibold text-foreground">Category</label>
                <input v-model="addForm.category" type="text" class="w-full h-10 rounded-lg border border-border bg-background px-3 text-sm shadow-sm focus-visible:ring-1 focus-visible:ring-ring focus-visible:outline-none" />
              </div>
              <div class="space-y-1.5">
                <label class="text-xs font-semibold text-foreground">Country</label>
                <input v-model="addForm.country" type="text" class="w-full h-10 rounded-lg border border-border bg-background px-3 text-sm shadow-sm focus-visible:ring-1 focus-visible:ring-ring focus-visible:outline-none" />
              </div>
            </div>
            <div class="space-y-1.5">
              <label class="text-xs font-semibold text-foreground flex items-center gap-1.5"><MapPin class="size-3.5" /> Address</label>
              <input v-model="addForm.address" type="text" placeholder="Street, city, state" class="w-full h-10 rounded-lg border border-border bg-background px-3 text-sm shadow-sm focus-visible:ring-1 focus-visible:ring-ring focus-visible:outline-none" />
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div class="space-y-1.5">
                <label class="text-xs font-semibold text-foreground flex items-center gap-1.5"><Phone class="size-3.5" /> Phone</label>
                <input v-model="addForm.phone" type="text" class="w-full h-10 rounded-lg border border-border bg-background px-3 text-sm shadow-sm focus-visible:ring-1 focus-visible:ring-ring focus-visible:outline-none" />
              </div>
              <div class="space-y-1.5">
                <label class="text-xs font-semibold text-foreground flex items-center gap-1.5"><Globe class="size-3.5" /> Website</label>
                <input v-model="addForm.website" type="text" class="w-full h-10 rounded-lg border border-border bg-background px-3 text-sm shadow-sm focus-visible:ring-1 focus-visible:ring-ring focus-visible:outline-none" />
              </div>
            </div>
            <div class="space-y-1.5">
              <label class="text-xs font-semibold text-foreground flex items-center gap-1.5"><Mail class="size-3.5" /> Business email</label>
              <input v-model="addForm.email" type="email" class="w-full h-10 rounded-lg border border-border bg-background px-3 text-sm shadow-sm focus-visible:ring-1 focus-visible:ring-ring focus-visible:outline-none" />
            </div>
          </div>

          <!-- Step: connect -->
          <div v-else-if="addStep === 'connect'" class="space-y-3">
            <p class="text-sm text-muted-foreground">Choose a platform to connect this listing to.</p>
            <button
              v-for="p in connectPlatforms"
              :key="p.name"
              class="w-full flex items-center gap-3 p-3 rounded-xl border transition-colors"
              :class="connectSelected === p.name ? 'border-primary bg-primary/5' : 'border-border hover:bg-muted/50'"
              @click="connectSelected = p.name"
            >
              <span class="size-9 rounded-full bg-white border border-border shadow-sm flex items-center justify-center p-1.5" v-html="p.icon"></span>
              <span class="text-sm font-medium text-foreground">{{ p.name }} Business Profile</span>
              <Check v-if="connectSelected === p.name" class="size-4 text-primary ml-auto" />
            </button>
          </div>

          <!-- Step: success -->
          <div v-else class="flex flex-col items-center justify-center text-center py-8">
            <div class="size-14 rounded-full bg-emerald-500/10 text-emerald-500 flex items-center justify-center mb-4">
              <CircleCheck class="size-8" />
            </div>
            <h3 class="text-base font-semibold text-foreground">Listing added</h3>
            <p class="text-sm text-muted-foreground mt-1 max-w-xs">
              {{ addForm.name || 'Your listing' }} is set up. Reviews will sync once the platform connection is live.
            </p>
          </div>
        </div>

        <!-- Footer -->
        <div class="px-6 py-4 border-t border-border flex items-center justify-between shrink-0 bg-muted/20">
          <button v-if="addStep === 'connect'" class="inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground hover:text-foreground transition-colors" @click="addBack">
            <ArrowLeft class="size-4" /> Back
          </button>
          <span v-else></span>
          <div class="flex items-center gap-2">
            <button class="rounded-lg border border-border px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted/50 transition-colors" @click="closeAdd">
              {{ addStep === 'success' ? 'Close' : 'Cancel' }}
            </button>
            <button v-if="addStep !== 'success'" class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors disabled:opacity-50" :disabled="addStep === 'info' && !addForm.name" @click="addNext">
              {{ addStep === 'info' ? 'Next' : 'Connect' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Export modal (advanced) -->
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
          <button v-if="!exportDone" class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors" @click="runExport">
            <Download class="size-4" /> Export
          </button>
        </div>
      </div>
    </div>

    <!-- Integration Settings modal (Auto Sync / Smart Auto-Reply / Webhook) -->
    <div v-if="settingsOpen && settingsListing" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-background/80 backdrop-blur-sm" @click="settingsOpen = false"></div>
      <div class="relative bg-card border border-border rounded-2xl shadow-lg max-w-lg w-full p-6 space-y-5">
        <div class="flex items-center justify-between pb-3 border-b border-border">
          <div class="flex items-center gap-2.5">
            <Building2 class="size-5 text-primary" />
            <h2 class="text-[15px] font-semibold text-foreground">{{ settingsListing.name }} Integration Settings</h2>
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
          <button class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors" @click="saveSettings">
            Save Changes
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
