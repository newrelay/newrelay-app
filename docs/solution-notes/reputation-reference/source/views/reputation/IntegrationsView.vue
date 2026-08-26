<script setup lang="ts">
import { ref, computed } from 'vue'
import {
  Link2, CheckCircle2, AlertCircle, RefreshCw, Search,
  ExternalLink, Settings2, Plus, Sparkles, Star, ShieldCheck,
  Zap, ArrowRight, Check, X, Layers, Bell, Send, HelpCircle,
  Clock, Shield, MessageSquare, ArrowUpDown, Filter, RotateCcw,
  ChevronDown, LayoutGrid, List, Grid3X3, Grid2X2, CheckCheck
} from 'lucide-vue-next'
import { 
  Button, Input, Badge, Switch,
  DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuLabel
} from '@/components/ui'
import PremiumEmptyState from '@/components/layout/PremiumEmptyState.vue'

// State
const isDemoLoaded = ref(true)
const searchQuery = ref('')
const selectedStatus = ref<'all' | 'connected' | 'not_connected' | 'coming_soon'>('all')
const selectedNiche = ref<string>('all')
const sortOrder = ref<'name_asc' | 'name_desc' | 'recommended'>('recommended')
const viewMode = ref<'grid4' | 'grid3' | 'grid2' | 'list'>('grid4')

const isSyncing = ref(false)
const selectedIntegration = ref<any>(null)
const isConfigModalOpen = ref(false)
const isRequestModalOpen = ref(false)
const requestedPlatformName = ref('')
const requestEmail = ref('')
const requestNotes = ref('')
const isRequestSubmitted = ref(false)

// Niches / Categories definitions
const niches = [
  { id: 'all', label: 'All Categories' },
  { id: 'local_search', label: 'Local & Search Engines' },
  { id: 'b2b_software', label: 'B2B & SaaS Software' },
  { id: 'ecommerce', label: 'E-Commerce & Retail' },
  { id: 'hospitality', label: 'Hospitality & Dining' },
  { id: 'home_services', label: 'Home & Trade Services' }
]

// Status definitions
const statusOptions = [
  { id: 'all', label: 'All Statuses' },
  { id: 'connected', label: 'Connected' },
  { id: 'not_connected', label: 'Available / Not Connected' },
  { id: 'coming_soon', label: 'Coming Soon' }
]

// Sort options
const sortOptions = [
  { id: 'recommended', label: 'Recommended / Popular' },
  { id: 'name_asc', label: 'Alphabetical (A → Z)' },
  { id: 'name_desc', label: 'Alphabetical (Z → A)' }
]

// Grid View options
const gridTypes = [
  { id: 'grid4', label: '4 Columns (Default)', icon: LayoutGrid },
  { id: 'grid3', label: '3 Columns (Medium)', icon: Grid3X3 },
  { id: 'grid2', label: '2 Columns (Expanded)', icon: Grid2X2 },
  { id: 'list', label: 'List View (Detailed)', icon: List }
]

// Integrations Data
const integrations = ref([
  // --- Core Active & Widely Used Platforms ---
  {
    id: 'google',
    name: 'Google',
    subtitle: 'Google Business Profile',
    niches: ['local_search'],
    nicheLabel: 'Local & Search',
    description: 'Connect with Google Business Profile to sync Google Maps ratings, customer reviews, and automate Relay AI responses.',
    connected: true,
    tag: '✓ Popular',
    tagVariant: 'emerald',
    rawTag: 'popular',
    isComingSoon: false,
    rating: '4.8 ★',
    reviewsCount: '452 reviews',
    lastSync: '2 mins ago',
    autoSync: true,
    autoReply: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg">
      <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
      <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
      <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
      <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
    </svg>`
  },
  {
    id: 'yelp',
    name: 'Yelp',
    subtitle: 'Yelp for Business',
    niches: ['local_search', 'home_services'],
    nicheLabel: 'Local & Services',
    description: 'Monitor Yelp local ratings, pull customer feedback in real time, and trigger notifications when mixed sentiment is detected.',
    connected: true,
    tag: '✓ Easy setup',
    tagVariant: 'emerald',
    rawTag: 'easy_setup',
    isComingSoon: false,
    rating: '4.3 ★',
    reviewsCount: '128 reviews',
    lastSync: '1 hour ago',
    autoSync: true,
    autoReply: false,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#E00707] fill-current" xmlns="http://www.w3.org/2000/svg">
      <path d="M12.271 8.782c-.549-3.804-.822-5.72-.822-5.748 0-.888-.622-1.641-1.537-1.887A2.34 2.34 0 0 0 7.3 2.52L3.473 7.337a2.01 2.01 0 0 0-.302 1.895c.28.72.934 1.218 1.695 1.282l5.894.488c1.038.087 1.871-.767 1.511-2.22zm-8.245 6.253l5.374 2.186c1.004.409 2.084-.332 2.084-1.41V11.38c0-1.088-1.096-1.83-2.104-1.41l-5.374 2.185a1.85 1.85 0 0 0-1.148 1.44 1.855 1.855 0 0 0 1.168 1.44zm6.406 5.978l-3.218-4.874a1.796 1.796 0 0 0-2.97-.095 1.855 1.855 0 0 0-.17 1.98l2.28 4.374a2.316 2.316 0 0 0 2.492 1.208 2.302 2.302 0 0 0 1.586-2.593zm9.56-10.826a2.31 2.31 0 0 0-1.92-1.435l-5.916-.489a1.796 1.796 0 0 0-1.493 2.874l3.42 4.96a1.803 1.803 0 0 0 2.8.217l3.477-4.046a2.02 2.02 0 0 0 .368-.654 2.004 2.004 0 0 0-.736-1.427zm-2.278 7.916l-2.277-4.373a1.804 1.804 0 0 0-3.124.149 1.789 1.789 0 0 0 .057 1.695l3.218 4.874a2.305 2.305 0 0 0 2.534.938 2.316 2.316 0 0 0 1.57-2.593 2.31 2.31 0 0 0-1.978-0.69z"/>
    </svg>`
  },
  {
    id: 'trustpilot',
    name: 'Trustpilot',
    subtitle: 'Trustpilot Reviews',
    niches: ['ecommerce', 'b2b_software'],
    nicheLabel: 'E-Commerce & B2B',
    description: 'Sync verified customer reviews, monitor your TrustScore badge, and direct post-purchase reviewers to your official Trustpilot portal.',
    connected: true,
    tag: '✓ Recommended',
    tagVariant: 'primary',
    rawTag: 'recommended',
    isComingSoon: false,
    rating: '4.6 ★',
    reviewsCount: '204 reviews',
    lastSync: '3 hours ago',
    autoSync: true,
    autoReply: false,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6" xmlns="http://www.w3.org/2000/svg">
      <rect width="24" height="24" fill="#00B67A" rx="4"/>
      <path d="M12 4.2l2.4 5 5.5.8-4 3.9 1 5.5-4.9-2.6-4.9 2.6 1-5.5-4-3.9 5.5-.8 2.4-5z" fill="#FFF"/>
    </svg>`
  },
  {
    id: 'facebook',
    name: 'Facebook',
    subtitle: 'Pages & Recommendations',
    niches: ['local_search'],
    nicheLabel: 'Social & Local',
    description: 'Aggregate Facebook recommendations, post replies directly from New Relay, and display verified social proof on your landing pages.',
    connected: true,
    tag: '✓ Popular',
    tagVariant: 'emerald',
    rawTag: 'popular',
    isComingSoon: false,
    rating: '4.9 ★',
    reviewsCount: '312 reviews',
    lastSync: '15 mins ago',
    autoSync: true,
    autoReply: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#1877F2] fill-current" xmlns="http://www.w3.org/2000/svg">
      <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
    </svg>`
  },
  {
    id: 'tripadvisor',
    name: 'TripAdvisor',
    subtitle: 'Traveler Reviews',
    niches: ['hospitality'],
    nicheLabel: 'Hospitality & Travel',
    description: 'Collect and manage hospitality, dining, and venue traveler feedback with automatic ranking and traveler score insights.',
    connected: false,
    tag: '✓ Easy setup',
    tagVariant: 'emerald',
    rawTag: 'easy_setup',
    isComingSoon: false,
    rating: null,
    reviewsCount: null,
    lastSync: null,
    autoSync: false,
    autoReply: false,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#00AF87] fill-current" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="10" fill="#00AF87"/>
      <circle cx="8" cy="12" r="2.5" fill="#FFF"/>
      <circle cx="16" cy="12" r="2.5" fill="#FFF"/>
      <circle cx="8" cy="12" r="1.2" fill="#000"/>
      <circle cx="16" cy="12" r="1.2" fill="#000"/>
    </svg>`
  },
  {
    id: 'apple_maps',
    name: 'Apple Maps',
    subtitle: 'Apple Business Connect',
    niches: ['local_search'],
    nicheLabel: 'Local & Search',
    description: 'Publish verified business details, showcase photos, and sync ratings from millions of iOS Apple Maps and Spotlight users.',
    connected: false,
    tag: '• Beta',
    tagVariant: 'amber',
    rawTag: 'coming_soon',
    isComingSoon: false,
    rating: null,
    reviewsCount: null,
    lastSync: null,
    autoSync: false,
    autoReply: false,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 fill-current text-foreground" xmlns="http://www.w3.org/2000/svg">
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.87c.66-.81 1.11-1.94.99-3.07-1 .04-2.16.67-2.82 1.48-.58.67-1.1 1.82-.96 2.93 1.12.09 2.19-.58 2.79-1.34z"/>
    </svg>`
  },

  // --- Upcoming Review Platforms (Marked Coming Soon) ---
  {
    id: 'amazon',
    name: 'Amazon',
    subtitle: 'Product & Seller Reviews',
    niches: ['ecommerce'],
    nicheLabel: 'E-Commerce & Retail',
    description: 'Aggregate verified Amazon buyer ratings, monitor product feedback, and sync seller performance metrics.',
    connected: false,
    tag: '⚡ Coming Soon',
    tagVariant: 'amber',
    rawTag: 'coming_soon',
    isComingSoon: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#FF9900] fill-current" xmlns="http://www.w3.org/2000/svg">
      <path d="M13.9 14.5c-2.3 1.7-5.7 2.6-8.6 2.6-4.1 0-7.8-1.5-10.6-4-.2-.2 0-.5.2-.3 3 1.8 6.7 2.8 10.4 2.8 2.6 0 5.4-.6 8-1.7.4-.2.8.2.6.6zM22.8 17.6c-.3-.4-1.9-.2-2.9 0-.3.1-.3-.2-.1-.4 1.3-1.1 2.9-.8 3.2-.4.3.4-.1 2.3-1.4 3.4-.2.2-.4.1-.3-.1.5-.7 1.8-2.1 1.5-2.5z"/>
      <path d="M14.7 10.9c0-1.8-1.1-2.9-2.9-2.9-1.5 0-2.8.9-3.1 2.3-.1.4.2.5.5.5.7 0 1.2-.5 1.7-.8.5-.3 1-.4 1.6-.4.9 0 1.3.5 1.3 1.4v.3c-2.8.2-4.5 1.2-4.5 3 0 1.5 1.1 2.4 2.5 2.4 1.3 0 2.2-.6 2.6-1.5h.1v1.2c0 .3.2.5.5.5h.8c.3 0 .5-.2.5-.5v-5.5z"/>
    </svg>`
  },
  {
    id: 'g2',
    name: 'G2',
    subtitle: 'B2B Software & SaaS',
    niches: ['b2b_software'],
    nicheLabel: 'B2B & SaaS Software',
    description: 'Collect verified B2B customer reviews on G2, track grid quadrant ranking, and syndicate buyer badges.',
    connected: false,
    tag: '⚡ Coming Soon',
    tagVariant: 'amber',
    rawTag: 'coming_soon',
    isComingSoon: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#FF492C] fill-current" xmlns="http://www.w3.org/2000/svg">
      <rect width="24" height="24" rx="4" fill="#FF492C"/>
      <path d="M12 6c-3.3 0-6 2.7-6 6s2.7 6 6 6c2.5 0 4.6-1.5 5.5-3.7.1-.3-.1-.6-.4-.6h-1.8c-.2 0-.4.1-.5.3-.6 1.2-1.7 2-3 2-1.9 0-3.5-1.4-3.8-3.3h9.4c.3 0 .5-.2.5-.5 0-3.3-2.6-5.9-5.9-5.9zm-3.8 5c.3-1.9 1.9-3.3 3.8-3.3s3.5 1.4 3.8 3.3H8.2z" fill="#FFF"/>
    </svg>`
  },
  {
    id: 'capterra',
    name: 'Capterra',
    subtitle: 'Software Directory',
    niches: ['b2b_software'],
    nicheLabel: 'B2B & Software',
    description: 'Sync vendor ratings and buyer testimonials from Gartner Capterra & GetApp software directories.',
    connected: false,
    tag: '⚡ Coming Soon',
    tagVariant: 'amber',
    rawTag: 'coming_soon',
    isComingSoon: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#003B5C] fill-current" xmlns="http://www.w3.org/2000/svg">
      <rect width="24" height="24" rx="4" fill="#003B5C"/>
      <path d="M7 16l5-8 5 8h-3l-2-3.5L10 16H7z" fill="#FF6B4A"/>
    </svg>`
  },
  {
    id: 'bbb',
    name: 'BBB',
    subtitle: 'Better Business Bureau',
    niches: ['local_search', 'home_services'],
    nicheLabel: 'Accredited Business',
    description: 'Monitor accredited business ratings, customer complaints, and official BBB trust seal verification.',
    connected: false,
    tag: '⚡ Coming Soon',
    tagVariant: 'amber',
    rawTag: 'coming_soon',
    isComingSoon: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#005A9C] fill-current" xmlns="http://www.w3.org/2000/svg">
      <rect width="24" height="24" rx="4" fill="#005A9C"/>
      <text x="50%" y="65%" text-anchor="middle" fill="#FFF" font-family="sans-serif" font-weight="bold" font-size="9">BBB</text>
    </svg>`
  },
  {
    id: 'angi',
    name: 'Angi',
    subtitle: 'Home & Trade Services',
    niches: ['home_services'],
    nicheLabel: 'Home & Trade Services',
    description: 'Sync certified homeowner and contractor reviews from Angi and HomeAdvisor service networks.',
    connected: false,
    tag: '⚡ Coming Soon',
    tagVariant: 'amber',
    rawTag: 'coming_soon',
    isComingSoon: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#00B074] fill-current" xmlns="http://www.w3.org/2000/svg">
      <rect width="24" height="24" rx="4" fill="#00B074"/>
      <path d="M12 5l6 14h-3.2l-1.3-3.2H10.5L9.2 19H6l6-14zm0 4.5L11.2 13h1.6L12 9.5z" fill="#FFF"/>
    </svg>`
  },
  {
    id: 'opentable',
    name: 'OpenTable',
    subtitle: 'Diner & Restaurant Ratings',
    niches: ['hospitality'],
    nicheLabel: 'Hospitality & Dining',
    description: 'Gather verified post-meal diner ratings and reservation feedback directly from OpenTable.',
    connected: false,
    tag: '⚡ Coming Soon',
    tagVariant: 'amber',
    rawTag: 'coming_soon',
    isComingSoon: true,
    iconSvg: `<svg viewBox="0 0 24 24" class="size-6 text-[#DA3743] fill-current" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="10" fill="#DA3743"/>
      <circle cx="12" cy="12" r="4.5" fill="#FFF"/>
      <circle cx="17" cy="12" r="2" fill="#FFF"/>
    </svg>`
  }
])

// Filtered & Sorted Integrations
const filteredIntegrations = computed(() => {
  let list = integrations.value.filter(item => {
    // Search query filter
    const matchesSearch = 
      item.name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      item.subtitle.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      item.description.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      item.nicheLabel.toLowerCase().includes(searchQuery.value.toLowerCase())

    // Status filter
    let matchesStatus = true
    if (selectedStatus.value === 'connected') {
      matchesStatus = item.connected
    } else if (selectedStatus.value === 'not_connected') {
      matchesStatus = !item.connected && !item.isComingSoon
    } else if (selectedStatus.value === 'coming_soon') {
      matchesStatus = item.isComingSoon
    }

    // Niche filter
    let matchesNiche = true
    if (selectedNiche.value !== 'all') {
      matchesNiche = item.niches.includes(selectedNiche.value)
    }

    return matchesSearch && matchesStatus && matchesNiche
  })

  // Sort order
  if (sortOrder.value === 'name_asc') {
    list = [...list].sort((a, b) => a.name.localeCompare(b.name))
  } else if (sortOrder.value === 'name_desc') {
    list = [...list].sort((a, b) => b.name.localeCompare(a.name))
  }

  return list
})

// Active labels for dropdown triggers
const selectedStatusLabel = computed(() => statusOptions.find(s => s.id === selectedStatus.value)?.label || 'All Statuses')
const selectedNicheLabel = computed(() => niches.find(n => n.id === selectedNiche.value)?.label || 'All Categories')
const selectedSortLabel = computed(() => sortOptions.find(s => s.id === sortOrder.value)?.label || 'Recommended')

const hasActiveFilters = computed(() => {
  return searchQuery.value !== '' || selectedStatus.value !== 'all' || selectedNiche.value !== 'all' || sortOrder.value !== 'recommended'
})

function resetFilters() {
  searchQuery.value = ''
  selectedStatus.value = 'all'
  selectedNiche.value = 'all'
  sortOrder.value = 'recommended'
}

function handleSyncAll() {
  isSyncing.value = true
  setTimeout(() => {
    isSyncing.value = false
  }, 1200)
}

function openConfigure(item: any) {
  selectedIntegration.value = item
  isConfigModalOpen.value = true
}

function toggleConnection(item: any) {
  item.connected = !item.connected
}

function openRequestModal(platformName?: string) {
  requestedPlatformName.value = platformName || ''
  requestEmail.value = ''
  requestNotes.value = ''
  isRequestSubmitted.value = false
  isRequestModalOpen.value = true
}

function submitRequest() {
  if (!requestedPlatformName.value) return
  isRequestSubmitted.value = true
  setTimeout(() => {
    isRequestModalOpen.value = false
  }, 2000)
}

function getTagStyles(variant: string) {
  switch (variant) {
    case 'emerald':
      return 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400'
    case 'primary':
      return 'bg-primary/10 text-primary'
    case 'amber':
      return 'bg-amber-500/10 text-amber-600 dark:text-amber-400'
    default:
      return 'bg-muted text-muted-foreground'
  }
}
</script>

<template>
  <div class="flex-1 overflow-y-auto w-full hide-scrollbar bg-background p-6 lg:p-8">
    <!-- Populated State -->
    <div v-if="isDemoLoaded" class="max-w-7xl mx-auto space-y-6">
      
      <!-- Top Page Header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-border/60">
        <div>
          <h1 class="text-base font-medium tracking-tight text-foreground">Integrations</h1>
          <p class="text-[13.5px] text-muted-foreground mt-0.5">Connect external review platforms to automatically monitor ratings, aggregate reviews, and route Relay AI responses.</p>
        </div>
        
        <div class="flex items-center gap-3">
          <Button 
            variant="outline" 
            class="gap-2 border border-border hover:border-transparent text-[13.5px]" 
            @click="isDemoLoaded = false"
          >
            Preview Empty State
          </Button>

          <Button 
            variant="outline"
            class="gap-2 border border-border hover:border-transparent shadow-xs text-[13.5px]" 
            :disabled="isSyncing"
            @click="handleSyncAll"
          >
            <RefreshCw :class="['size-3.5', isSyncing ? 'animate-spin' : '']" />
            {{ isSyncing ? 'Syncing...' : 'Sync All Accounts' }}
          </Button>
        </div>
      </div>

      <!-- Pill-Style Filter Toolbar (Matching User Reference Image) -->
      <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-3 pt-1">
        
        <!-- Left Side: Search Input Pill + Dropdown Pills -->
        <div class="flex items-center gap-2 flex-wrap">
          
          <!-- Search Pill -->
          <div class="relative w-48 sm:w-56">
            <Search class="absolute left-3.5 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
            <Input 
              v-model="searchQuery" 
              placeholder="Search platforms..." 
              class="pl-9.5 pr-4 h-9 text-[13px] rounded-xl bg-card border border-border shadow-xs focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>

          <!-- Platform / Status Dropdown Pill -->
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <Button 
                variant="outline" 
                class="h-9 gap-1.5 rounded-xl text-[13px] font-medium bg-card border border-border shadow-xs px-3 hover:border-transparent"
              >
                <span>{{ selectedStatus === 'all' ? 'Platform Status' : selectedStatusLabel }}</span>
                <ChevronDown class="size-3.5 opacity-50 ml-0.5" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start" class="w-48">
              <DropdownMenuLabel class="text-[11.5px] text-muted-foreground font-medium uppercase tracking-wider">
                Connection Status
              </DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem 
                v-for="opt in statusOptions" 
                :key="opt.id"
                class="text-[13px] flex items-center justify-between cursor-pointer"
                @click="selectedStatus = opt.id as any"
              >
                <span>{{ opt.label }}</span>
                <Check v-if="selectedStatus === opt.id" class="size-3.5 text-primary ml-2" />
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          <!-- Category / Niche Dropdown Pill -->
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <Button 
                variant="outline" 
                class="h-9 gap-1.5 rounded-xl text-[13px] font-medium bg-card border border-border shadow-xs px-3 hover:border-transparent"
              >
                <span>{{ selectedNiche === 'all' ? 'Category / Niche' : selectedNicheLabel }}</span>
                <ChevronDown class="size-3.5 opacity-50 ml-0.5" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start" class="w-56">
              <DropdownMenuLabel class="text-[11.5px] text-muted-foreground font-medium uppercase tracking-wider">
                Platform Niche
              </DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem 
                v-for="niche in niches" 
                :key="niche.id"
                class="text-[13px] flex items-center justify-between cursor-pointer"
                @click="selectedNiche = niche.id"
              >
                <span>{{ niche.label }}</span>
                <Check v-if="selectedNiche === niche.id" class="size-3.5 text-primary ml-2" />
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          <!-- Sort Order Dropdown Pill -->
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <Button 
                variant="outline" 
                class="h-9 gap-1.5 rounded-xl text-[13px] font-medium bg-card border border-border shadow-xs px-3 hover:border-transparent"
              >
                <span>{{ selectedSortLabel }}</span>
                <ChevronDown class="size-3.5 opacity-50 ml-0.5" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start" class="w-52">
              <DropdownMenuLabel class="text-[11.5px] text-muted-foreground font-medium uppercase tracking-wider">
                Sort Order
              </DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem 
                v-for="sort in sortOptions" 
                :key="sort.id"
                class="text-[13px] flex items-center justify-between cursor-pointer"
                @click="sortOrder = sort.id as any"
              >
                <span>{{ sort.label }}</span>
                <Check v-if="sortOrder === sort.id" class="size-3.5 text-primary ml-2" />
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          <!-- Reset Pill Button (shown when filters are active) -->
          <Button 
            v-if="hasActiveFilters"
            variant="ghost" 
            size="sm"
            class="h-9 rounded-xl text-[12.5px] text-muted-foreground hover:text-foreground border border-border hover:border-transparent gap-1 px-2.5"
            @click="resetFilters"
          >
            <RotateCcw class="size-3" />
            Reset
          </Button>
        </div>

        <!-- Right Side: Grid Type Switcher (In place of Newest First button) -->
        <div class="flex items-center gap-2 self-end lg:self-auto">
          <!-- Quick Icon View Switcher -->
          <div class="flex items-center bg-card border border-border rounded-xl p-0.5 shadow-xs">
            <button 
              class="p-1.5 rounded-lg transition-colors"
              :class="viewMode === 'grid4' ? 'bg-muted text-foreground' : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'"
              title="4 Columns Grid"
              @click="viewMode = 'grid4'"
            >
              <LayoutGrid class="size-4" />
            </button>
            <button 
              class="p-1.5 rounded-lg transition-colors"
              :class="viewMode === 'grid2' ? 'bg-muted text-foreground' : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'"
              title="2 Columns Grid"
              @click="viewMode = 'grid2'"
            >
              <Grid2X2 class="size-4" />
            </button>
            <button 
              class="p-1.5 rounded-lg transition-colors"
              :class="viewMode === 'list' ? 'bg-muted text-foreground' : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'"
              title="List View"
              @click="viewMode = 'list'"
            >
              <List class="size-4" />
            </button>
          </div>
        </div>
      </div>

      <!-- Active Filter Summary Strip -->
      <div v-if="hasActiveFilters" class="flex items-center gap-2 text-[12.5px] text-muted-foreground">
        <span>Showing <strong class="text-foreground">{{ filteredIntegrations.length }}</strong> of {{ integrations.length }} platforms matching filters</span>
      </div>

      <!-- ==================== GRID / LIST AREA ==================== -->

      <!-- 1. Grid Views (4, 3, or 2 Columns) -->
      <div 
        v-if="viewMode !== 'list'"
        class="grid gap-4 transition-all"
        :class="[
          viewMode === 'grid4' ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4' : '',
          viewMode === 'grid3' ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3' : '',
          viewMode === 'grid2' ? 'grid-cols-1 md:grid-cols-2' : ''
        ]"
      >
        <!-- Platform Cards -->
        <div 
          v-for="item in filteredIntegrations" 
          :key="item.id"
          class="bg-card rounded-2xl border border-border p-6 shadow-xs flex flex-col justify-between hover:border-border/80 hover:shadow-sm transition-all"
        >
          <div>
            <!-- Card Brand Logo & Title -->
            <div class="flex items-center justify-between gap-3 mb-3">
              <div class="flex items-center gap-3">
                <div class="size-8 flex items-center justify-center shrink-0" v-html="item.iconSvg"></div>
                <div>
                  <h3 class="text-[16px] font-semibold text-foreground tracking-tight leading-snug">{{ item.name }}</h3>
                </div>
              </div>
              <Badge variant="outline" class="text-[10.5px] font-normal py-0 text-muted-foreground">
                {{ item.nicheLabel }}
              </Badge>
            </div>

            <!-- Card Description -->
            <p class="text-[13px] text-muted-foreground leading-relaxed">
              {{ item.description }}
            </p>
          </div>

          <!-- Bottom Action & Status Tag Row -->
          <div class="pt-5 mt-5 border-t border-border/50 flex items-center justify-between">
            <!-- Left: Badge Tag Pill -->
            <div 
              class="flex items-center gap-1 text-[12px] font-medium px-2.5 py-0.5 rounded-md"
              :class="getTagStyles(item.tagVariant)"
            >
              <span>{{ item.tag }}</span>
            </div>

            <!-- Right: Action Link / Button -->
            <div>
              <!-- Coming Soon Platforms -->
              <template v-if="item.isComingSoon">
                <button 
                  class="text-[13px] font-medium text-primary hover:underline flex items-center gap-1"
                  @click="openRequestModal(item.name)"
                >
                  Notify Me →
                </button>
              </template>

              <!-- Connected Platform -->
              <template v-else-if="item.connected">
                <button 
                  class="text-[13px] font-medium text-primary hover:underline flex items-center gap-1"
                  @click="openConfigure(item)"
                >
                  Configure →
                </button>
              </template>

              <!-- Available & Connectable Platform -->
              <template v-else>
                <button 
                  class="text-[13px] font-medium text-primary hover:underline flex items-center gap-1"
                  @click="toggleConnection(item)"
                >
                  Connect →
                </button>
              </template>
            </div>
          </div>
        </div>

        <!-- "More coming soon" Card (Matching Reference Screenshot) -->
        <div 
          v-if="selectedStatus === 'all' || selectedStatus === 'coming_soon'"
          class="bg-card rounded-2xl border border-dashed border-border p-6 shadow-xs flex flex-col justify-between hover:border-primary/50 hover:bg-muted/10 transition-all"
        >
          <div>
            <!-- Plus Circle Icon & Title -->
            <div class="flex items-center gap-3 mb-3">
              <div class="size-8 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
                <Plus class="size-4" />
              </div>
              <h3 class="text-[16px] font-semibold text-foreground tracking-tight">More coming soon</h3>
            </div>

            <!-- Description -->
            <p class="text-[13px] text-muted-foreground leading-relaxed">
              Don't see what you need? Request an integration with your favorite review platform or POS software.
            </p>
          </div>

          <!-- Bottom Action Row -->
          <div class="pt-5 mt-5 border-t border-border/50 flex items-center justify-start">
            <button 
              class="text-[13px] font-medium text-primary hover:underline flex items-center gap-1"
              @click="openRequestModal('')"
            >
              Request integration →
            </button>
          </div>
        </div>
      </div>

      <!-- 2. List View (Detailed Horizontal Rows) -->
      <div v-else class="space-y-3">
        <div 
          v-for="item in filteredIntegrations" 
          :key="item.id"
          class="bg-card rounded-2xl border border-border p-5 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:border-border/80 hover:shadow-sm transition-all"
        >
          <div class="flex items-start sm:items-center gap-4 flex-1">
            <div class="size-10 rounded-xl bg-muted/30 border border-border/60 flex items-center justify-center shrink-0 p-2" v-html="item.iconSvg"></div>
            
            <div class="space-y-1 flex-1">
              <div class="flex items-center gap-2.5 flex-wrap">
                <h3 class="text-[15px] font-semibold text-foreground tracking-tight">{{ item.name }}</h3>
                <Badge variant="outline" class="text-[11px] font-normal py-0 text-muted-foreground">
                  {{ item.nicheLabel }}
                </Badge>
                <div 
                  class="flex items-center gap-1 text-[11.5px] font-medium px-2 py-0.5 rounded-md"
                  :class="getTagStyles(item.tagVariant)"
                >
                  <span>{{ item.tag }}</span>
                </div>
              </div>
              <p class="text-[13px] text-muted-foreground leading-relaxed line-clamp-2">
                {{ item.description }}
              </p>
            </div>
          </div>

          <div class="flex items-center gap-3 shrink-0 self-end sm:self-center pt-2 sm:pt-0 border-t sm:border-t-0 border-border/50 w-full sm:w-auto justify-end">
            <!-- Coming Soon Platforms -->
            <template v-if="item.isComingSoon">
              <Button 
                variant="outline" 
                size="sm"
                class="h-8 text-[12.5px] border border-border hover:border-transparent gap-1 text-primary"
                @click="openRequestModal(item.name)"
              >
                Notify Me →
              </Button>
            </template>

            <!-- Connected Platform -->
            <template v-else-if="item.connected">
              <Button 
                variant="outline" 
                size="sm"
                class="h-8 text-[12.5px] border border-border hover:border-transparent gap-1 text-primary"
                @click="openConfigure(item)"
              >
                Configure →
              </Button>
            </template>

            <!-- Available Platform -->
            <template v-else>
              <Button 
                size="sm"
                class="h-8 text-[12.5px] gap-1 shadow-xs"
                @click="toggleConnection(item)"
              >
                Connect →
              </Button>
            </template>
          </div>
        </div>

        <!-- "More coming soon" List Row -->
        <div 
          v-if="selectedStatus === 'all' || selectedStatus === 'coming_soon'"
          class="bg-card rounded-2xl border border-dashed border-border p-5 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:border-primary/50 hover:bg-muted/10 transition-all"
        >
          <div class="flex items-center gap-4">
            <div class="size-10 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
              <Plus class="size-5" />
            </div>
            <div>
              <h3 class="text-[15px] font-semibold text-foreground tracking-tight">More coming soon</h3>
              <p class="text-[13px] text-muted-foreground">
                Don't see what you need? Request an integration with your favorite review platform or POS software.
              </p>
            </div>
          </div>

          <Button 
            variant="outline"
            size="sm"
            class="h-8 text-[12.5px] border border-border hover:border-transparent text-primary shrink-0 self-end sm:self-center"
            @click="openRequestModal('')"
          >
            Request integration →
          </Button>
        </div>
      </div>

      <!-- Search No Results State -->
      <div v-if="filteredIntegrations.length === 0" class="text-center py-16 bg-card rounded-2xl border border-border">
        <Layers class="size-8 text-muted-foreground mx-auto mb-2 opacity-50" />
        <h3 class="text-[15px] font-semibold text-foreground">No review platforms match your filters</h3>
        <p class="text-[13px] text-muted-foreground mt-1">Try resetting or broadening your category, status, or search filters.</p>
        <Button 
          variant="outline" 
          size="sm" 
          class="mt-4 text-[12.5px] border border-border hover:border-transparent"
          @click="resetFilters"
        >
          Reset All Filters
        </Button>
      </div>
    </div>

    <!-- Empty State View -->
    <div v-else class="flex flex-col min-h-[calc(100vh-10rem)] w-full">
      <PremiumEmptyState
        :icon="Link2"
        title="No Connected Integrations"
        description="Connect your review platforms like Google, Yelp, Trustpilot, and Facebook to automate your reputation workflows."
        primaryAction="Browse All Integrations"
        secondaryAction="View Setup Guide"
        @primary-click="isDemoLoaded = true"
      />

      <!-- Developer button at bottom of empty state to toggle mock data -->
      <div class="mt-8 pt-4 border-t border-border flex items-center justify-center">
        <Button 
          variant="outline" 
          size="sm" 
          class="border border-border hover:border-transparent text-[12.5px] text-muted-foreground"
          @click="isDemoLoaded = true"
        >
          Developer Preview: Load Demo Data
        </Button>
      </div>
    </div>

    <!-- Configuration & Settings Modal (For Connected Active Platforms) -->
    <div 
      v-if="isConfigModalOpen && selectedIntegration"
      class="fixed inset-0 z-50 bg-background/80 backdrop-blur-sm flex items-center justify-center p-4"
    >
      <div class="bg-card border border-border rounded-2xl shadow-lg max-w-lg w-full p-6 space-y-5">
        <div class="flex items-center justify-between pb-3 border-b border-border">
          <div class="flex items-center gap-2.5">
            <div class="size-6 flex items-center justify-center" v-html="selectedIntegration.iconSvg"></div>
            <h2 class="text-[15px] font-semibold text-foreground">{{ selectedIntegration.name }} Integration Settings</h2>
          </div>
          <button 
            class="text-muted-foreground hover:text-foreground"
            @click="isConfigModalOpen = false"
          >
            <X class="size-4" />
          </button>
        </div>

        <div class="space-y-4 text-[13.5px]">
          <div class="flex items-center justify-between p-3.5 rounded-xl bg-muted/40 border border-border">
            <div>
              <div class="font-medium text-foreground">Automatic Review Sync</div>
              <div class="text-[12px] text-muted-foreground">Pull incoming reviews in real-time every 15 minutes</div>
            </div>
            <Switch v-model:checked="selectedIntegration.autoSync" />
          </div>

          <div class="flex items-center justify-between p-3.5 rounded-xl bg-muted/40 border border-border">
            <div>
              <div class="font-medium text-foreground">Relay AI Smart Auto-Reply</div>
              <div class="text-[12px] text-muted-foreground">Auto-draft and publish on-brand responses to 5-star ratings</div>
            </div>
            <Switch v-model:checked="selectedIntegration.autoReply" />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">Sync Webhook Endpoint</label>
            <Input 
              readonly 
              :value="'https://api.newrelay.com/v1/reputation/sync/' + selectedIntegration.id"
              class="text-[14px] bg-muted/30 font-mono"
            />
          </div>
        </div>

        <div class="flex items-center justify-between pt-3 border-t border-border">
          <Button 
            variant="destructive-ghost" 
            class="text-[13px] border border-border hover:border-transparent"
            @click="toggleConnection(selectedIntegration); isConfigModalOpen = false"
          >
            Disconnect Account
          </Button>

          <div class="flex items-center gap-2">
            <Button 
              variant="outline" 
              class="border border-border hover:border-transparent text-[13px]"
              @click="isConfigModalOpen = false"
            >
              Cancel
            </Button>
            <Button 
              class="text-[13px]"
              @click="isConfigModalOpen = false"
            >
              Save Changes
            </Button>
          </div>
        </div>
      </div>
    </div>

    <!-- Request Integration / Notify Me Modal -->
    <div 
      v-if="isRequestModalOpen"
      class="fixed inset-0 z-50 bg-background/80 backdrop-blur-sm flex items-center justify-center p-4"
    >
      <div class="bg-card border border-border rounded-2xl shadow-lg max-w-md w-full p-6 space-y-5">
        <div class="flex items-center justify-between pb-3 border-b border-border">
          <div class="flex items-center gap-2">
            <Sparkles class="size-4 text-primary" />
            <h2 class="text-[15px] font-semibold text-foreground">
              {{ requestedPlatformName ? 'Get Notified for ' + requestedPlatformName : 'Request New Integration' }}
            </h2>
          </div>
          <button 
            class="text-muted-foreground hover:text-foreground"
            @click="isRequestModalOpen = false"
          >
            <X class="size-4" />
          </button>
        </div>

        <div v-if="isRequestSubmitted" class="py-6 text-center space-y-2">
          <div class="size-12 rounded-full bg-emerald-500/10 text-emerald-500 mx-auto flex items-center justify-center">
            <Check class="size-6" />
          </div>
          <h3 class="text-[15px] font-semibold text-foreground">Request Received!</h3>
          <p class="text-[13px] text-muted-foreground">
            Thank you. We'll notify you as soon as this review platform integration goes live.
          </p>
        </div>

        <div v-else class="space-y-4 text-[13.5px]">
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">Platform / Software Name</label>
            <Input 
              v-model="requestedPlatformName" 
              placeholder="e.g. Amazon, G2, Tripadvisor, Toast POS"
              class="text-[14px]"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">Your Email Address</label>
            <Input 
              v-model="requestEmail" 
              type="email"
              placeholder="you@company.com"
              class="text-[14px]"
            />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">Use Case / Notes (Optional)</label>
            <textarea 
              v-model="requestNotes"
              rows="3"
              placeholder="How would your team use this integration?"
              class="w-full text-[14px] p-3 rounded-lg border border-border bg-background text-foreground shadow-xs focus:ring-1 focus:ring-primary/30 outline-none leading-relaxed"
            ></textarea>
          </div>

          <div class="flex items-center justify-end gap-2 pt-2 border-t border-border">
            <Button 
              variant="outline" 
              class="border border-border hover:border-transparent text-[13px]"
              @click="isRequestModalOpen = false"
            >
              Cancel
            </Button>
            <Button 
              class="text-[13px]"
              :disabled="!requestedPlatformName || !requestEmail"
              @click="submitRequest"
            >
              Submit Request
            </Button>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>
