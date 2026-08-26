<!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
<script setup>
/* eslint-disable */
import { ref, computed } from 'vue';
import {
  RefreshCw, Search, Plus, Check, X, RotateCcw, ChevronDown,
  LayoutGrid, Grid2X2, List, Building2, Send, CheckCircle2,
} from 'lucide-vue-next';
import {
  RelayInput as Input, RelaySwitch,
  RelayDropdownMenu as DropdownMenu,
  RelayDropdownMenuTrigger as DropdownMenuTrigger,
  RelayDropdownMenuContent as DropdownMenuContent,
  RelayDropdownMenuItem as DropdownMenuItem,
} from 'dashboard/components-next/relay';

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
const fbIcon = `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" fill="#1877F2"/></svg>`;
const yIcon = `<svg viewBox="0 0 24 24" class="size-6" fill="#E00707" xmlns="http://www.w3.org/2000/svg"><path d="M12.271 8.782c-.549-3.804-.822-5.72-.822-5.748 0-.888-.622-1.641-1.537-1.887A2.34 2.34 0 0 0 7.3 2.52L3.473 7.337a2.01 2.01 0 0 0-.302 1.895c.28.72.934 1.218 1.695 1.282l5.894.488c1.038.087 1.871-.767 1.511-2.22zm-8.245 6.253l5.374 2.186c1.004.409 2.084-.332 2.084-1.41V11.38c0-1.088-1.096-1.83-2.104-1.41l-5.374 2.185a1.85 1.85 0 0 0-1.148 1.44 1.855 1.855 0 0 0 1.168 1.44zm6.406 5.978l-3.218-4.874a1.796 1.796 0 0 0-2.97-.095 1.855 1.855 0 0 0-.17 1.98l2.28 4.374a2.316 2.316 0 0 0 2.492 1.208 2.302 2.302 0 0 0 1.586-2.593zm9.56-10.826a2.31 2.31 0 0 0-1.92-1.435l-5.916-.489a1.796 1.796 0 0 0-1.493 2.874l3.42 4.96a1.803 1.803 0 0 0 2.8.217l3.477-4.046a2.02 2.02 0 0 0 .368-.654 2.004 2.004 0 0 0-.736-1.427zm-2.278 7.916l-2.277-4.373a1.804 1.804 0 0 0-3.124.149 1.789 1.789 0 0 0 .057 1.695l3.218 4.874a2.305 2.305 0 0 0 2.534.938 2.316 2.316 0 0 0 1.57-2.593 2.31 2.31 0 0 0-1.978-.69z"/></svg>`;
const tpIcon = `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" fill="#00B67A" rx="4"/><path d="M12 4.2l2.4 5 5.5.8-4 3.9 1 5.5-4.9-2.6-4.9 2.6 1-5.5-4-3.9 5.5-.8 2.4-5z" fill="#FFF"/></svg>`;
const genIcon = c => `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" rx="6" fill="${c}"/><path d="M12 6l6 12h-3.2l-1.2-2.6h-3.2L9.2 18H6l6-12z" fill="#FFF"/></svg>`;

const integrations = ref([
  { id: 'google', name: 'Google', niches: ['local_search'], nicheLabel: 'Local & Search', description: 'Connect with Google Business Profile to sync Google Maps ratings, customer reviews, and automate Relay AI responses.', connected: true, tag: '✓ Popular', tagVariant: 'emerald', isComingSoon: false, autoSync: true, autoReply: true, iconSvg: gIcon },
  { id: 'yelp', name: 'Yelp', niches: ['local_search', 'home_services'], nicheLabel: 'Local & Services', description: 'Monitor Yelp local ratings, pull customer feedback in real time, and trigger notifications when mixed sentiment is detected.', connected: true, tag: '✓ Easy setup', tagVariant: 'emerald', isComingSoon: false, autoSync: true, autoReply: false, iconSvg: yIcon },
  { id: 'trustpilot', name: 'Trustpilot', niches: ['ecommerce', 'b2b_software'], nicheLabel: 'E-Commerce & B2B', description: 'Sync verified customer reviews, monitor your TrustScore badge, and direct post-purchase reviewers to your official Trustpilot portal.', connected: true, tag: '✓ Recommended', tagVariant: 'primary', isComingSoon: false, autoSync: true, autoReply: false, iconSvg: tpIcon },
  { id: 'facebook', name: 'Facebook', niches: ['local_search'], nicheLabel: 'Social & Local', description: 'Aggregate Facebook recommendations, post replies directly from Relay, and display verified social proof on your landing pages.', connected: true, tag: '✓ Popular', tagVariant: 'emerald', isComingSoon: false, autoSync: true, autoReply: true, iconSvg: fbIcon },
  { id: 'tripadvisor', name: 'TripAdvisor', niches: ['hospitality'], nicheLabel: 'Hospitality & Travel', description: 'Collect and manage hospitality, dining, and venue traveler feedback with automatic ranking and traveler score insights.', connected: false, tag: '✓ Easy setup', tagVariant: 'emerald', isComingSoon: false, autoSync: false, autoReply: false, iconSvg: genIcon('#00AF87') },
  { id: 'apple_maps', name: 'Apple Maps', niches: ['local_search'], nicheLabel: 'Local & Search', description: 'Publish verified business details, showcase photos, and sync ratings from millions of iOS Apple Maps and Spotlight users.', connected: false, tag: '• Beta', tagVariant: 'amber', isComingSoon: false, autoSync: false, autoReply: false, iconSvg: genIcon('#111827') },
  { id: 'amazon', name: 'Amazon', niches: ['ecommerce'], nicheLabel: 'E-Commerce & Retail', description: 'Aggregate verified Amazon buyer ratings, monitor product feedback, and sync seller performance metrics.', connected: false, tag: '⚡ Coming Soon', tagVariant: 'amber', isComingSoon: true, iconSvg: genIcon('#FF9900') },
  { id: 'g2', name: 'G2', niches: ['b2b_software'], nicheLabel: 'B2B & SaaS Software', description: 'Collect verified B2B customer reviews on G2, track grid quadrant ranking, and syndicate buyer badges.', connected: false, tag: '⚡ Coming Soon', tagVariant: 'amber', isComingSoon: true, iconSvg: genIcon('#FF492C') },
  { id: 'capterra', name: 'Capterra', niches: ['b2b_software'], nicheLabel: 'B2B & Software', description: 'Sync vendor ratings and buyer testimonials from Gartner Capterra & GetApp software directories.', connected: false, tag: '⚡ Coming Soon', tagVariant: 'amber', isComingSoon: true, iconSvg: genIcon('#003B5C') },
  { id: 'bbb', name: 'BBB', niches: ['local_search', 'home_services'], nicheLabel: 'Accredited Business', description: 'Monitor accredited business ratings, customer complaints, and official BBB trust seal verification.', connected: false, tag: '⚡ Coming Soon', tagVariant: 'amber', isComingSoon: true, iconSvg: genIcon('#005A9C') },
  { id: 'angi', name: 'Angi', niches: ['home_services'], nicheLabel: 'Home & Trade Services', description: 'Sync certified homeowner and contractor reviews from Angi and HomeAdvisor service networks.', connected: false, tag: '⚡ Coming Soon', tagVariant: 'amber', isComingSoon: true, iconSvg: genIcon('#00B074') },
  { id: 'opentable', name: 'OpenTable', niches: ['hospitality'], nicheLabel: 'Hospitality & Dining', description: 'Gather verified post-meal diner ratings and reservation feedback directly from OpenTable.', connected: false, tag: '⚡ Coming Soon', tagVariant: 'amber', isComingSoon: true, iconSvg: genIcon('#DA3743') },
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
function handleSyncAll() {
  isSyncing.value = true;
  setTimeout(() => { isSyncing.value = false; }, 1200);
}
function openConfigure(item) {
  selectedIntegration.value = item;
  isConfigModalOpen.value = true;
}
function toggleConnection(item) {
  item.connected = !item.connected;
}
function openRequestModal(platformName) {
  requestedPlatformName.value = platformName || '';
  requestEmail.value = '';
  requestNotes.value = '';
  isRequestSubmitted.value = false;
  isRequestModalOpen.value = true;
}
function submitRequest() {
  if (!requestedPlatformName.value) return;
  isRequestSubmitted.value = true;
  setTimeout(() => { isRequestModalOpen.value = false; }, 2000);
}
const webhookUrl = computed(() =>
  selectedIntegration.value ? `${window.location.origin}/api/v1/reputation/sync/${selectedIntegration.value.id}` : ''
);
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
          <div class="flex items-center gap-2">
            <h1 class="text-base font-medium tracking-tight text-foreground">Integrations</h1>
            <span class="rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400" title="Showcase — real platform connection lives in Reputation Settings">Demo</span>
          </div>
          <p class="text-[13.5px] text-muted-foreground mt-0.5">Connect external review platforms to automatically monitor ratings, aggregate reviews, and route Relay AI responses.</p>
        </div>
        <div class="flex items-center gap-3">
          <button class="h-9 gap-2 rounded-lg border border-border bg-card hover:bg-muted text-[13.5px] font-medium px-3 inline-flex items-center cursor-pointer" @click="isDemoLoaded = false">
            Preview Empty State
          </button>
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
            <button v-if="item.isComingSoon" class="text-[13px] font-medium text-primary hover:underline cursor-pointer" @click="openRequestModal(item.name)">Notify Me →</button>
            <button v-else-if="item.connected" class="text-[13px] font-medium text-primary hover:underline cursor-pointer" @click="openConfigure(item)">Configure →</button>
            <button v-else class="text-[13px] font-medium text-primary hover:underline cursor-pointer" @click="toggleConnection(item)">Connect →</button>
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
            <button v-if="item.isComingSoon" class="h-8 px-3 text-[12.5px] rounded-lg border border-border hover:bg-muted text-primary inline-flex items-center cursor-pointer" @click="openRequestModal(item.name)">Notify Me</button>
            <button v-else-if="item.connected" class="h-8 px-3 text-[12.5px] rounded-lg border border-border hover:bg-muted text-primary inline-flex items-center cursor-pointer" @click="openConfigure(item)">Configure</button>
            <button v-else class="h-8 px-3 text-[12.5px] rounded-lg bg-primary text-primary-foreground hover:bg-primary/90 inline-flex items-center cursor-pointer" @click="toggleConnection(item)">Connect</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-else class="max-w-md mx-auto flex flex-col items-center justify-center text-center py-24">
      <div class="size-14 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mb-4"><Building2 class="size-7" /></div>
      <h2 class="text-lg font-semibold text-foreground mb-1">No integrations connected</h2>
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
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">Sync Webhook Endpoint</label>
            <input readonly :value="webhookUrl" class="h-9 px-3 text-[13px] rounded-md border border-border bg-muted/30 font-mono text-muted-foreground focus:outline-none" />
          </div>
        </div>
        <div class="flex items-center justify-between pt-3 border-t border-border">
          <button class="text-[13px] text-destructive border border-border hover:bg-muted rounded-lg px-3 py-2 font-medium cursor-pointer" @click="toggleConnection(selectedIntegration); isConfigModalOpen = false">Disconnect Account</button>
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
          </div>
          <div class="flex items-center justify-end gap-2 pt-3 border-t border-border">
            <button class="rounded-lg border border-border px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted/50 cursor-pointer" @click="isRequestModalOpen = false">Cancel</button>
            <button class="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90 inline-flex items-center gap-1.5 cursor-pointer disabled:opacity-50" :disabled="!requestedPlatformName" @click="submitRequest">
              <Send class="size-3.5" /> Submit Request
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
  </div>
</template>
