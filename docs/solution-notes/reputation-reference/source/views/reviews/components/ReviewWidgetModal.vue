<script setup lang="ts">
import { ref, computed } from 'vue'
import {
  X, LayoutGrid, Code2, Copy, Check, Sparkles, Monitor, Tablet,
  Smartphone, Eye, Sliders, Palette, Filter, RefreshCw, ChevronLeft,
  ChevronRight, Star, StarHalf, ShieldCheck, CheckCircle2, Globe,
  ExternalLink, Moon, Sun, Layers, Share2, ArrowRight, Settings2,
  Signal, Wifi
} from 'lucide-vue-next'
import { Button, Input, Badge, Switch, Checkbox } from '@/components/ui'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  (e: 'update:open', value: boolean): void
}>()

// Active Config Tab
const activeTab = ref<'layout' | 'filters' | 'appearance' | 'embed'>('layout')

// Small screen view toggle: 'editor' | 'preview'
const mobileViewMode = ref<'editor' | 'preview'>('preview')

// Device Preview Simulation Mode
const previewDevice = ref<'desktop' | 'tablet' | 'mobile'>('mobile')
const previewBg = ref<'light' | 'dark'>('light')

// Copied feedback
const isCopied = ref(false)
const isSaved = ref(false)

// Widget Configurations
const widgetConfig = ref({
  name: 'Main Website Reviews Widget',
  layout: 'carousel', // 'carousel' | 'grid' | 'badge' | 'compact'
  
  // Platform filters
  platforms: {
    google: true,
    facebook: true,
    trustpilot: true,
    yelp: true
  },
  
  // Star & sentiment filters
  minRating: '4', // 'all' | '4' | '5'
  positiveOnly: true,
  excludeUnresolved: true,
  maxReviews: 12,
  
  // Appearance
  theme: 'system', // 'light' | 'dark' | 'system'
  cardRadius: 'rounded-2xl', // 'rounded-none' | 'rounded-lg' | 'rounded-2xl' | 'rounded-[28px]'
  
  // Visible Elements
  showStars: true,
  showAvatar: true,
  showPlatformLogo: true,
  showVerifiedBadge: true,
  showDate: true,
  showTrustHeader: true,
  autoPlay: true,
  autoPlaySpeed: 5,
  badgePosition: 'bottom-right'
})

// Mock review items for the live widget preview
const allReviews = [
  {
    id: 1,
    author: 'Sarah Jenkins',
    role: 'Verified Customer',
    avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704d',
    platform: 'Google',
    rating: 5,
    date: '2 days ago',
    content: 'Absolutely incredible service! The team was super responsive and helped me resolve my issue within minutes. Highly recommended to anyone looking for a solid solution.'
  },
  {
    id: 2,
    author: 'Michael Chang',
    role: 'Local Guide',
    avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704e',
    platform: 'Yelp',
    rating: 4,
    date: '4 days ago',
    content: 'Good overall experience, smooth workflows and the product itself is fantastic. The customer support team has been very helpful.'
  },
  {
    id: 3,
    author: 'Emily Rodriguez',
    role: 'Verified Buyer',
    avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704f',
    platform: 'Facebook',
    rating: 5,
    date: '1 week ago',
    content: 'We\'ve been using this for 3 months now and it has completely transformed how we handle customer engagement. The AI features are a true game changer.'
  },
  {
    id: 4,
    author: 'Chloe Bennett',
    role: 'Verified Customer',
    avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704a',
    platform: 'Trustpilot',
    rating: 5,
    date: '2 weeks ago',
    content: 'Super slick interface, great customer support, and fast setup. Our conversion rates increased by 22% after adding the reviews widget.'
  },
  {
    id: 5,
    author: 'David Lee',
    role: 'Business Owner',
    avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704b',
    platform: 'Google',
    rating: 5,
    date: '3 weeks ago',
    content: 'The best investment our team made this year. High quality service and very friendly support staff whenever we needed anything.'
  },
  {
    id: 6,
    author: 'Jessica Taylor',
    role: 'Verified Buyer',
    avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704c',
    platform: 'Google',
    rating: 5,
    date: '1 month ago',
    content: 'Couldn\'t be happier with the results. Seamless experience and our clients constantly mention how trustworthy the reviews look!'
  }
]

// Filtered reviews based on config
const previewReviews = computed(() => {
  return allReviews.filter(r => {
    // Platform check
    const platformKey = r.platform.toLowerCase() as keyof typeof widgetConfig.value.platforms
    if (widgetConfig.value.platforms[platformKey] === false) return false
    
    // Min rating check
    if (widgetConfig.value.minRating === '5' && r.rating < 5) return false
    if (widgetConfig.value.minRating === '4' && r.rating < 4) return false
    
    return true
  }).slice(0, widgetConfig.value.maxReviews)
})

// Carousel active index
const carouselIndex = ref(0)
function nextSlide() {
  if (carouselIndex.value < previewReviews.value.length - 1) {
    carouselIndex.value++
  } else {
    carouselIndex.value = 0
  }
}
function prevSlide() {
  if (carouselIndex.value > 0) {
    carouselIndex.value--
  } else {
    carouselIndex.value = previewReviews.value.length - 1
  }
}

// Layout Options
const layoutOptions = [
  {
    id: 'carousel',
    name: 'Carousel Slider',
    description: 'Horizontal sliding cards with navigation arrows. Best for homepages & landing pages.',
    icon: Layers
  },
  {
    id: 'grid',
    name: 'Masonry Grid',
    description: 'Multi-column responsive grid layout showcasing authentic social proof.',
    icon: LayoutGrid
  },
  {
    id: 'badge',
    name: 'Floating Trust Badge',
    description: 'Minimal floating pill with overall rating and review count fixed to screen corners.',
    icon: ShieldCheck
  },
  {
    id: 'compact',
    name: 'Sidebar Feed',
    description: 'Compact vertical list designed for product sidebars, pricing pages & checkouts.',
    icon: Sliders
  }
]

// Generated Embed Snippets
const embedFormat = ref<'html' | 'iframe' | 'react'>('html')

const activeSnippet = computed(() => {
  if (embedFormat.value === 'html') {
    return `<!-- New Relay Review Widget -->\n<div id="nr-reviews-widget" \n  data-widget-id="rw_${widgetConfig.value.layout}_9482" \n  data-theme="${widgetConfig.value.theme}">\n</div>\n<script src="https://cdn.newrelay.com/widgets/v2/reviews.js" async defer><\/script>`
  }
  if (embedFormat.value === 'iframe') {
    return `<iframe \n  src="https://embed.newrelay.com/widget/rw_9482?layout=${widgetConfig.value.layout}&theme=${widgetConfig.value.theme}" \n  width="100%" \n  height="480" \n  frameborder="0" \n  loading="lazy">\n</iframe>`
  }
  return `import { ReviewWidget } from '@newrelay/react-widgets'\n\nexport default function TestimonialSection() {\n  return (\n    <ReviewWidget \n      widgetId="rw_9482"\n      layout="${widgetConfig.value.layout}"\n      theme="${widgetConfig.value.theme}"\n    />\n  )\n}`
})

function copyEmbedCode() {
  navigator.clipboard.writeText(activeSnippet.value)
  isCopied.value = true
  setTimeout(() => {
    isCopied.value = false
  }, 2200)
}

function handleSaveWidget() {
  isSaved.value = true
  setTimeout(() => {
    isSaved.value = false
    emit('update:open', false)
  }, 1200)
}

function close() {
  emit('update:open', false)
}

function resetDefaults() {
  widgetConfig.value = {
    name: 'Main Website Reviews Widget',
    layout: 'carousel',
    platforms: { google: true, facebook: true, trustpilot: true, yelp: true },
    minRating: '4',
    positiveOnly: true,
    excludeUnresolved: true,
    maxReviews: 12,
    theme: 'system',
    cardRadius: 'rounded-2xl',
    showStars: true,
    showAvatar: true,
    showPlatformLogo: true,
    showVerifiedBadge: true,
    showDate: true,
    showTrustHeader: true,
    autoPlay: true,
    autoPlaySpeed: 5,
    badgePosition: 'bottom-right'
  }
  carouselIndex.value = 0
}
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center p-2 sm:p-4 lg:p-6">
    <!-- Backdrop -->
    <div class="absolute inset-0 bg-background/80 backdrop-blur-md" @click="close"></div>

    <!-- Modal Container (Expansive & fully responsive) -->
    <div class="relative w-[98vw] sm:w-[96vw] max-w-[1440px] h-[96vh] sm:h-[92vh] bg-card rounded-xl sm:rounded-2xl shadow-2xl border border-border flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200">
      
      <!-- Top Modal Header -->
      <div class="px-4 sm:px-6 py-3.5 border-b border-border bg-muted/30 flex items-center justify-between shrink-0">
        <div class="flex items-center gap-3">
          <div class="p-2 bg-primary/10 rounded-xl text-primary shrink-0">
            <LayoutGrid class="size-5" />
          </div>
          <div>
            <div class="flex items-center gap-2 flex-wrap">
              <h2 class="text-base font-semibold text-foreground">Review Widget Studio</h2>
              <Badge variant="secondary" class="bg-primary/10 text-primary text-[11px] font-medium hidden sm:inline-flex">Live Website Embed</Badge>
            </div>
            <p class="text-[12.5px] text-muted-foreground hidden sm:block">Customize, preview in real time, and generate embed code for your website.</p>
          </div>
        </div>

        <!-- Right Header Actions -->
        <div class="flex items-center gap-2">
          <!-- Mobile View Switcher (Visible on < lg screens) -->
          <div class="flex lg:hidden items-center bg-muted p-1 rounded-lg border border-border">
            <button 
              @click="mobileViewMode = 'editor'"
              :class="['px-2.5 py-1 rounded-md text-xs font-medium transition-all', mobileViewMode === 'editor' ? 'bg-card text-foreground shadow-xs font-semibold' : 'text-muted-foreground']"
            >
              Customizer
            </button>
            <button 
              @click="mobileViewMode = 'preview'"
              :class="['px-2.5 py-1 rounded-md text-xs font-medium transition-all', mobileViewMode === 'preview' ? 'bg-card text-foreground shadow-xs font-semibold' : 'text-muted-foreground']"
            >
              Preview
            </button>
          </div>

          <Button variant="ghost" size="icon" class="text-muted-foreground border border-border hover:border-transparent size-8 sm:size-9" @click="close">
            <X class="size-4 sm:size-5" />
          </Button>
        </div>
      </div>

      <!-- Main Body: Two Column Studio -->
      <div class="flex-1 flex flex-col lg:flex-row overflow-hidden">
        
        <!-- Left Column: Customization Controls (420px) -->
        <div 
          :class="[
            'w-full lg:w-[420px] xl:w-[450px] border-b lg:border-b-0 lg:border-r border-border bg-card flex flex-col shrink-0 overflow-hidden',
            mobileViewMode === 'editor' ? 'flex flex-1' : 'hidden lg:flex'
          ]"
        >
          
          <!-- Customizer Navigation Tabs -->
          <div class="grid grid-cols-4 p-2 border-b border-border/70 bg-muted/20 text-xs font-medium shrink-0">
            <button 
              @click="activeTab = 'layout'"
              :class="[
                'py-2 px-1 rounded-lg transition-all text-center flex flex-col items-center gap-1',
                activeTab === 'layout' 
                  ? 'bg-background text-foreground shadow-xs font-semibold' 
                  : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'
              ]"
            >
              <Layers class="size-4" />
              <span>Layout</span>
            </button>
            <button 
              @click="activeTab = 'filters'"
              :class="[
                'py-2 px-1 rounded-lg transition-all text-center flex flex-col items-center gap-1',
                activeTab === 'filters' 
                  ? 'bg-background text-foreground shadow-xs font-semibold' 
                  : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'
              ]"
            >
              <Filter class="size-4" />
              <span>Sources</span>
            </button>
            <button 
              @click="activeTab = 'appearance'"
              :class="[
                'py-2 px-1 rounded-lg transition-all text-center flex flex-col items-center gap-1',
                activeTab === 'appearance' 
                  ? 'bg-background text-foreground shadow-xs font-semibold' 
                  : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'
              ]"
            >
              <Palette class="size-4" />
              <span>Style</span>
            </button>
            <button 
              @click="activeTab = 'embed'"
              :class="[
                'py-2 px-1 rounded-lg transition-all text-center flex flex-col items-center gap-1',
                activeTab === 'embed' 
                  ? 'bg-background text-foreground shadow-xs font-semibold' 
                  : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'
              ]"
            >
              <Code2 class="size-4" />
              <span>Embed</span>
            </button>
          </div>

          <!-- Controls Content Area -->
          <div class="flex-1 overflow-y-auto p-4 sm:p-5 space-y-5 hide-scrollbar">
            
            <!-- TAB 1: LAYOUT & TEMPLATES -->
            <div v-if="activeTab === 'layout'" class="space-y-4 animate-in fade-in duration-200">
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Widget Layout Template</label>
                <p class="text-[12px] text-muted-foreground mb-3">Choose the structure that matches your website section.</p>
                
                <div class="grid grid-cols-1 gap-2.5">
                  <div 
                    v-for="opt in layoutOptions" 
                    :key="opt.id"
                    @click="widgetConfig.layout = opt.id"
                    :class="[
                      'p-3.5 rounded-xl border transition-all cursor-pointer flex items-start gap-3.5',
                      widgetConfig.layout === opt.id 
                        ? 'border-primary bg-primary/5 ring-1 ring-primary/30' 
                        : 'border-border bg-card hover:bg-muted/30 hover:border-border/80'
                    ]"
                  >
                    <div :class="['p-2 rounded-lg shrink-0 mt-0.5', widgetConfig.layout === opt.id ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground']">
                      <component :is="opt.icon" class="size-4" />
                    </div>
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center justify-between">
                        <span class="text-sm font-semibold text-foreground">{{ opt.name }}</span>
                        <CheckCircle2 v-if="widgetConfig.layout === opt.id" class="size-4 text-primary shrink-0" />
                      </div>
                      <p class="text-[12px] text-muted-foreground mt-0.5 leading-relaxed">{{ opt.description }}</p>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Layout Specific Settings -->
              <div v-if="widgetConfig.layout === 'carousel'" class="p-3.5 bg-muted/20 border border-border rounded-xl space-y-3">
                <div class="flex items-center justify-between">
                  <div>
                    <span class="text-[13px] font-medium text-foreground">Auto-Play Carousel</span>
                    <p class="text-[11.5px] text-muted-foreground">Automatically rotate slides every 5s</p>
                  </div>
                  <Switch v-model="widgetConfig.autoPlay" />
                </div>
              </div>

              <div v-if="widgetConfig.layout === 'badge'" class="p-3.5 bg-muted/20 border border-border rounded-xl space-y-2">
                <label class="text-[13px] font-medium text-foreground">Badge Screen Position</label>
                <div class="grid grid-cols-2 gap-2 text-xs">
                  <button 
                    v-for="pos in ['bottom-right', 'bottom-left', 'top-right', 'top-left']" 
                    :key="pos"
                    @click="widgetConfig.badgePosition = pos"
                    :class="[
                      'p-2 rounded-lg border text-center capitalize',
                      widgetConfig.badgePosition === pos ? 'border-primary bg-primary/10 text-primary font-semibold' : 'border-border text-muted-foreground'
                    ]"
                  >
                    {{ pos.replace('-', ' ') }}
                  </button>
                </div>
              </div>
            </div>

            <!-- TAB 2: REVIEW SOURCES & FILTERS -->
            <div v-if="activeTab === 'filters'" class="space-y-5 animate-in fade-in duration-200">
              
              <!-- Source Platforms -->
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Source Platforms</label>
                <p class="text-[12px] text-muted-foreground mb-3">Select which connected platforms sync to this widget.</p>
                
                <div class="space-y-2">
                  <label class="flex items-center justify-between p-2.5 rounded-lg border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5">
                      <Checkbox v-model="widgetConfig.platforms.google" />
                      <span class="text-sm font-medium text-foreground">Google Business Profile</span>
                    </div>
                    <Badge variant="outline" class="text-[11px]">452 reviews</Badge>
                  </label>

                  <label class="flex items-center justify-between p-2.5 rounded-lg border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5">
                      <Checkbox v-model="widgetConfig.platforms.facebook" />
                      <span class="text-sm font-medium text-foreground">Facebook Recommendations</span>
                    </div>
                    <Badge variant="outline" class="text-[11px]">312 reviews</Badge>
                  </label>

                  <label class="flex items-center justify-between p-2.5 rounded-lg border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5">
                      <Checkbox v-model="widgetConfig.platforms.trustpilot" />
                      <span class="text-sm font-medium text-foreground">Trustpilot Verified</span>
                    </div>
                    <Badge variant="outline" class="text-[11px]">204 reviews</Badge>
                  </label>

                  <label class="flex items-center justify-between p-2.5 rounded-lg border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5">
                      <Checkbox v-model="widgetConfig.platforms.yelp" />
                      <span class="text-sm font-medium text-foreground">Yelp for Business</span>
                    </div>
                    <Badge variant="outline" class="text-[11px]">128 reviews</Badge>
                  </label>
                </div>
              </div>

              <!-- Rating Filter -->
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Minimum Star Rating</label>
                <p class="text-[12px] text-muted-foreground mb-2">Only display reviews matching or exceeding this threshold.</p>
                <div class="grid grid-cols-3 gap-2">
                  <button 
                    v-for="r in [{ id: 'all', label: 'All (1-5★)' }, { id: '4', label: '4★ & Above' }, { id: '5', label: '5★ Only' }]" 
                    :key="r.id"
                    @click="widgetConfig.minRating = r.id"
                    :class="[
                      'py-2 px-2 text-xs rounded-lg border font-medium text-center transition-colors',
                      widgetConfig.minRating === r.id ? 'border-primary bg-primary/10 text-primary font-semibold' : 'border-border text-muted-foreground hover:bg-muted/30'
                    ]"
                  >
                    {{ r.label }}
                  </button>
                </div>
              </div>

              <!-- Relay AI Quality Protection -->
              <div class="p-3.5 bg-muted/30 border border-border rounded-xl space-y-3">
                <div class="flex items-center gap-2 text-xs font-semibold text-foreground uppercase tracking-wider">
                  <Sparkles class="size-3.5 text-primary" />
                  Relay AI Smart Quality Filter
                </div>
                
                <div class="flex items-center justify-between">
                  <span class="text-xs text-foreground">Positive Sentiment Only</span>
                  <Switch v-model="widgetConfig.positiveOnly" />
                </div>
                <div class="flex items-center justify-between">
                  <span class="text-xs text-foreground">Exclude Unresolved Feedback</span>
                  <Switch v-model="widgetConfig.excludeUnresolved" />
                </div>
              </div>

              <!-- Max Reviews Count -->
              <div>
                <div class="flex items-center justify-between text-xs mb-1">
                  <span class="font-medium text-foreground">Maximum Reviews in Feed</span>
                  <span class="text-muted-foreground font-semibold">{{ widgetConfig.maxReviews }} items</span>
                </div>
                <input 
                  type="range" 
                  min="4" 
                  max="24" 
                  step="2"
                  v-model.number="widgetConfig.maxReviews" 
                  class="w-full accent-primary cursor-pointer"
                />
              </div>

            </div>

            <!-- TAB 3: STYLING & APPEARANCE -->
            <div v-if="activeTab === 'appearance'" class="space-y-4 animate-in fade-in duration-200">
              
              <!-- Color Theme -->
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Color Theme</label>
                <div class="grid grid-cols-3 gap-2">
                  <button 
                    v-for="t in [{ id: 'light', label: 'Clean Light', icon: Sun }, { id: 'dark', label: 'Sleek Dark', icon: Moon }, { id: 'system', label: 'Adaptive', icon: Monitor }]" 
                    :key="t.id"
                    @click="widgetConfig.theme = t.id"
                    :class="[
                      'py-2 px-2 text-xs rounded-lg border font-medium text-center flex items-center justify-center gap-1.5 transition-colors',
                      widgetConfig.theme === t.id ? 'border-primary bg-primary/10 text-primary font-semibold' : 'border-border text-muted-foreground hover:bg-muted/30'
                    ]"
                  >
                    <component :is="t.icon" class="size-3.5" />
                    {{ t.label }}
                  </button>
                </div>
              </div>

              <!-- Card Radius -->
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Corner Radius</label>
                <div class="grid grid-cols-4 gap-1.5 text-xs">
                  <button 
                    v-for="rad in [{ id: 'rounded-none', label: 'Square' }, { id: 'rounded-lg', label: 'Medium' }, { id: 'rounded-2xl', label: 'Large' }, { id: 'rounded-[28px]', label: 'Pill' }]" 
                    :key="rad.id"
                    @click="widgetConfig.cardRadius = rad.id"
                    :class="[
                      'py-1.5 px-2 rounded-lg border font-medium text-center transition-colors',
                      widgetConfig.cardRadius === rad.id ? 'border-primary bg-primary/10 text-primary font-semibold' : 'border-border text-muted-foreground hover:bg-muted/30'
                    ]"
                  >
                    {{ rad.label }}
                  </button>
                </div>
              </div>

              <!-- Display Elements Toggle List -->
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-2">Display Elements</label>
                
                <div class="space-y-2.5 bg-muted/20 border border-border p-3.5 rounded-xl text-xs">
                  <div class="flex items-center justify-between">
                    <span class="text-foreground">Show Aggregated Trust Banner</span>
                    <Switch v-model="widgetConfig.showTrustHeader" />
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-foreground">Show Star Rating Stars</span>
                    <Switch v-model="widgetConfig.showStars" />
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-foreground">Show Customer Avatars</span>
                    <Switch v-model="widgetConfig.showAvatar" />
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-foreground">Show Platform Logos</span>
                    <Switch v-model="widgetConfig.showPlatformLogo" />
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-foreground">Show Verified Badge</span>
                    <Switch v-model="widgetConfig.showVerifiedBadge" />
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-foreground">Show Review Date</span>
                    <Switch v-model="widgetConfig.showDate" />
                  </div>
                </div>
              </div>

            </div>

            <!-- TAB 4: EMBED & INSTALLATION CODE -->
            <div v-if="activeTab === 'embed'" class="space-y-5 animate-in fade-in duration-200">
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Integration Format</label>
                <p class="text-[12px] text-muted-foreground mb-3">Select your preferred embedding method to install on your website.</p>
                
                <!-- Format Switcher Pills -->
                <div class="grid grid-cols-3 gap-2">
                  <button 
                    v-for="fmt in [
                      { id: 'html', label: 'HTML / JS' },
                      { id: 'iframe', label: 'iFrame' },
                      { id: 'react', label: 'React / Next' }
                    ]"
                    :key="fmt.id"
                    type="button"
                    @click="embedFormat = fmt.id as any"
                    class="py-2 px-3 rounded-lg border text-xs text-center cursor-pointer transition-colors"
                    :class="embedFormat === fmt.id ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                  >
                    {{ fmt.label }}
                  </button>
                </div>
              </div>

              <!-- High-End Terminal / Code Box -->
              <div class="rounded-xl border border-slate-800 bg-slate-950 overflow-hidden shadow-lg flex flex-col">
                <!-- Code Box Header Bar -->
                <div class="px-4 py-2.5 bg-slate-900 border-b border-slate-800 flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <div class="flex items-center gap-1.5">
                      <div class="size-2 rounded-full bg-slate-600"></div>
                      <div class="size-2 rounded-full bg-slate-600"></div>
                      <div class="size-2 rounded-full bg-slate-600"></div>
                    </div>
                    <span class="text-[11px] font-mono text-slate-400 ml-1 font-medium">
                      {{ embedFormat === 'html' ? 'widget-embed.html' : embedFormat === 'iframe' ? 'iframe-embed.html' : 'ReviewWidget.tsx' }}
                    </span>
                  </div>
                  
                  <Button 
                    size="sm" 
                    variant="ghost"
                    class="h-7 px-2.5 text-[11px] gap-1.5 text-slate-300 hover:text-white hover:bg-slate-800 border border-slate-700/80 hover:border-transparent transition-all"
                    @click="copyEmbedCode"
                  >
                    <Check v-if="isCopied" class="size-3.5 text-emerald-400" />
                    <Copy v-else class="size-3.5" />
                    <span>{{ isCopied ? 'Copied to Clipboard' : 'Copy Code' }}</span>
                  </Button>
                </div>

                <!-- Code Content Body -->
                <div class="p-4 font-mono text-xs text-slate-200 overflow-x-auto hide-scrollbar leading-relaxed">
                  <pre class="whitespace-pre-wrap break-all font-mono text-[11.5px] leading-relaxed select-all"><code>{{ activeSnippet }}</code></pre>
                </div>
              </div>

              <!-- One-Click Guides for Website Builders -->
              <div class="p-4 bg-muted/20 border border-border rounded-xl space-y-2.5">
                <div class="flex items-center gap-2 text-[13px] font-semibold text-foreground">
                  <Globe class="size-4 text-primary" />
                  <span>Compatible with all modern platforms</span>
                </div>
                <div class="flex flex-wrap gap-1.5 pt-0.5 text-[11px]">
                  <Badge variant="outline" class="border-border bg-card">WordPress / Divi</Badge>
                  <Badge variant="outline" class="border-border bg-card">Webflow & Framer</Badge>
                  <Badge variant="outline" class="border-border bg-card">Shopify Store</Badge>
                  <Badge variant="outline" class="border-border bg-card">Squarespace & Wix</Badge>
                  <Badge variant="outline" class="border-border bg-card">Next.js / Nuxt</Badge>
                </div>
              </div>
            </div>

          </div>

          <!-- Left Column Bottom Action -->
          <div class="p-3.5 sm:p-4 border-t border-border bg-muted/10 flex items-center justify-between shrink-0">
            <button 
              @click="resetDefaults" 
              class="text-xs text-muted-foreground hover:text-foreground font-medium transition-colors"
            >
              Reset to Defaults
            </button>
            
            <Button 
              size="sm" 
              class="gap-1.5 text-xs shadow-xs" 
              @click="copyEmbedCode"
            >
              <Check v-if="isCopied" class="size-3.5 text-emerald-400" />
              <Copy v-else class="size-3.5" />
              {{ isCopied ? 'Code Copied!' : 'Copy Embed Code' }}
            </Button>
          </div>

        </div>

        <!-- Right Column: Live Interactive Preview Canvas (Flex-1) -->
        <div 
          :class="[
            'flex-1 bg-muted/20 flex flex-col overflow-hidden',
            mobileViewMode === 'preview' ? 'flex' : 'hidden lg:flex'
          ]"
        >
          
          <!-- Canvas Top Toolbar -->
          <div class="px-4 sm:px-6 py-3 border-b border-border bg-card/80 backdrop-blur-sm flex flex-wrap items-center justify-between gap-3 shrink-0">
            
            <!-- Device Toggle -->
            <div class="flex items-center gap-1 bg-muted p-1 rounded-xl border border-border/60">
              <button 
                @click="previewDevice = 'desktop'"
                :class="['px-2.5 py-1 rounded-lg text-xs font-medium flex items-center gap-1.5 transition-all', previewDevice === 'desktop' ? 'bg-card text-foreground shadow-xs' : 'text-muted-foreground hover:text-foreground']"
              >
                <Monitor class="size-3.5" />
                <span class="hidden sm:inline">Desktop</span>
              </button>
              <button 
                @click="previewDevice = 'tablet'"
                :class="['px-2.5 py-1 rounded-lg text-xs font-medium flex items-center gap-1.5 transition-all', previewDevice === 'tablet' ? 'bg-card text-foreground shadow-xs' : 'text-muted-foreground hover:text-foreground']"
              >
                <Tablet class="size-3.5" />
                <span class="hidden sm:inline">Tablet (768px)</span>
              </button>
              <button 
                @click="previewDevice = 'mobile'"
                :class="['px-2.5 py-1 rounded-lg text-xs font-medium flex items-center gap-1.5 transition-all', previewDevice === 'mobile' ? 'bg-card text-foreground shadow-xs' : 'text-muted-foreground hover:text-foreground']"
              >
                <Smartphone class="size-3.5" />
                <span class="hidden sm:inline">Mobile (390px)</span>
              </button>
            </div>

            <!-- Preview Canvas Background Switcher -->
            <div class="flex items-center gap-2">
              <span class="text-xs text-muted-foreground font-medium hidden md:inline">Background:</span>
              <div class="flex items-center gap-1 bg-muted p-1 rounded-lg border border-border/60">
                <button 
                  @click="previewBg = 'light'"
                  :class="['size-6 rounded-md flex items-center justify-center text-xs transition-colors', previewBg === 'light' ? 'bg-white text-slate-800 shadow-xs' : 'text-muted-foreground']"
                  title="Light background"
                >
                  <Sun class="size-3.5" />
                </button>
                <button 
                  @click="previewBg = 'dark'"
                  :class="['size-6 rounded-md flex items-center justify-center text-xs transition-colors', previewBg === 'dark' ? 'bg-slate-900 text-white shadow-xs' : 'text-muted-foreground']"
                  title="Dark background"
                >
                  <Moon class="size-3.5" />
                </button>
              </div>
            </div>

          </div>

          <!-- Canvas Preview Area -->
          <div 
            :class="[
              'flex-1 overflow-y-auto p-3 sm:p-5 flex items-center justify-center transition-colors duration-300',
              previewBg === 'light' ? 'bg-slate-100/90 dark:bg-slate-900/50' : 'bg-slate-950'
            ]"
          >
            <!-- 1. MOBILE SMARTPHONE SIMULATOR FRAME -->
            <div 
              v-if="previewDevice === 'mobile'"
              class="w-[340px] sm:w-[360px] h-[520px] max-h-[calc(100%-1rem)] bg-white dark:bg-card rounded-2xl shadow-xl border border-border flex flex-col relative overflow-hidden shrink-0 m-auto"
            >
              <!-- Mobile Browser Header Bar -->
              <div class="px-3.5 py-2 bg-slate-100/90 dark:bg-slate-800/90 border-b border-border/70 flex items-center justify-between text-[11px] text-muted-foreground shrink-0 z-10">
                <div class="flex items-center gap-1.5 font-mono text-[10px] truncate bg-white dark:bg-slate-900 px-2.5 py-1 rounded-md flex-1 mr-2 border border-border/40 shadow-2xs">
                  <span class="text-emerald-500 text-xs">🔒</span>
                  <span class="text-foreground/90 font-medium truncate">yourwebsite.com</span>
                </div>
                <div class="text-[10px] font-semibold text-muted-foreground">AA</div>
              </div>

              <!-- Scrollable Webpage Content with Embedded Widget Inside -->
              <div class="flex-1 overflow-y-auto p-3.5 space-y-3.5 hide-scrollbar">
                  <!-- Simulated Webpage Hero -->
                  <div class="text-center pt-1.5 pb-0.5 space-y-0.5">
                    <span class="text-[8.5px] uppercase tracking-wider font-semibold text-primary">Reviews & Proof</span>
                    <h3 class="text-xs font-bold text-foreground">Loved by thousands</h3>
                  </div>

                  <!-- THE RENDERED WIDGET CONTAINER (Mobile View) -->
                  <div 
                    :class="[
                      'w-full transition-all border shadow-xs relative',
                      widgetConfig.cardRadius,
                      'p-3',
                      widgetConfig.theme === 'dark' || previewBg === 'dark' 
                        ? 'bg-slate-900 text-slate-100 border-slate-800' 
                        : 'bg-white text-slate-900 border-slate-200/90'
                    ]"
                  >
                    <!-- 1. Responsive Aggregated Trust Banner Header -->
                    <div 
                      v-if="widgetConfig.showTrustHeader" 
                      class="mb-3 pb-2.5 border-b transition-colors"
                      :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'border-slate-800' : 'border-slate-100'"
                    >
                      <div class="flex items-center justify-between gap-2">
                        <div class="flex items-center gap-2 min-w-0">
                          <div class="size-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center font-bold text-xs shrink-0">
                            4.9
                          </div>
                          <div class="min-w-0">
                            <div class="flex items-center gap-0.5 text-amber-500">
                              <Star v-for="s in 4" :key="s" class="size-2.5 fill-amber-500 text-amber-500" />
                              <StarHalf class="size-2.5 fill-amber-500 text-amber-500" />
                              <span class="text-[10px] font-semibold ml-0.5 shrink-0" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-100' : 'text-slate-800'">4.9/5</span>
                            </div>
                            <p class="text-[9.5px] mt-0.5 truncate" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-400' : 'text-slate-500'">
                              1,096+ reviews
                            </p>
                          </div>
                        </div>

                        <div 
                          class="gap-1 text-[9.5px] py-0.5 px-2 rounded-md border shrink-0 font-medium whitespace-nowrap flex items-center transition-colors"
                          :class="widgetConfig.theme === 'dark' || previewBg === 'dark'
                            ? 'border-emerald-500/40 bg-emerald-500/15 text-emerald-400'
                            : 'border-emerald-500/30 bg-emerald-500/10 text-emerald-700'"
                        >
                          <ShieldCheck class="size-3 text-emerald-500 shrink-0" />
                          <span>Verified</span>
                        </div>
                      </div>
                    </div>

                    <!-- 2. WIDGET LAYOUT: CAROUSEL SLIDER (Mobile) -->
                    <div v-if="widgetConfig.layout === 'carousel'" class="relative">
                      <div class="overflow-hidden w-full">
                        <div 
                          class="transition-transform duration-300 ease-out flex"
                          :style="{ transform: `translateX(-${carouselIndex * 100}%)` }"
                        >
                          <div 
                            v-for="item in previewReviews" 
                            :key="item.id"
                            :class="[
                              'border flex flex-col justify-between shrink-0 transition-all shadow-xs box-border w-full min-w-full p-3.5',
                              widgetConfig.cardRadius,
                              widgetConfig.theme === 'dark' || previewBg === 'dark' 
                                ? 'bg-slate-800/80 border-slate-700/80' 
                                : 'bg-slate-50/90 border-slate-200/80'
                            ]"
                          >
                            <div class="space-y-2">
                              <div class="flex items-center justify-between gap-1.5">
                                <div class="flex items-center gap-2 min-w-0">
                                  <img 
                                    v-if="widgetConfig.showAvatar" 
                                    :src="item.avatar" 
                                    :alt="item.author"
                                    class="size-7 rounded-full object-cover border border-border/60 shrink-0"
                                  />
                                  <div class="min-w-0">
                                    <div class="flex items-center gap-1">
                                      <span class="text-xs font-semibold truncate" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-100' : 'text-slate-900'">{{ item.author }}</span>
                                      <span v-if="widgetConfig.showVerifiedBadge" class="text-[9px] text-emerald-500 font-medium shrink-0">
                                        <CheckCircle2 class="size-2.5" />
                                      </span>
                                    </div>
                                    <span v-if="widgetConfig.showDate" class="text-[9.5px] text-muted-foreground block truncate">{{ item.date }}</span>
                                  </div>
                                </div>

                                <span 
                                  v-if="widgetConfig.showPlatformLogo" 
                                  class="text-[9px] px-1.5 py-0.5 rounded-full font-medium shrink-0"
                                  :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'bg-slate-700 text-slate-300' : 'bg-slate-200/90 text-slate-700'"
                                >
                                  {{ item.platform }}
                                </span>
                              </div>

                              <div v-if="widgetConfig.showStars" class="flex gap-0.5 text-amber-500">
                                <Star v-for="s in item.rating" :key="s" class="size-3 fill-amber-500 text-amber-500" />
                              </div>

                              <p class="text-[11px] leading-relaxed line-clamp-3" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-300' : 'text-slate-600'">
                                "{{ item.content }}"
                              </p>
                            </div>
                          </div>
                        </div>
                      </div>

                      <!-- Carousel Controls -->
                      <div class="flex items-center justify-between mt-3 pt-1">
                        <div class="flex items-center gap-1">
                          <span 
                            v-for="(_, i) in previewReviews.slice(0, 6)" 
                            :key="i"
                            @click="carouselIndex = i"
                            :class="[
                              'h-1 rounded-full transition-all cursor-pointer',
                              carouselIndex === i ? 'w-4 bg-primary' : 'w-1 bg-muted-foreground/30 hover:bg-muted-foreground/50'
                            ]"
                          ></span>
                        </div>

                        <div class="flex items-center gap-1">
                          <button 
                            @click="prevSlide" 
                            class="size-6 rounded-full border border-border/80 flex items-center justify-center hover:bg-muted transition-colors"
                          >
                            <ChevronLeft class="size-3" />
                          </button>
                          <button 
                            @click="nextSlide" 
                            class="size-6 rounded-full border border-border/80 flex items-center justify-center hover:bg-muted transition-colors"
                          >
                            <ChevronRight class="size-3" />
                          </button>
                        </div>
                      </div>
                    </div>

                    <!-- 3. MASONRY GRID (Mobile) -->
                    <div v-else-if="widgetConfig.layout === 'grid'" class="space-y-2.5">
                      <div 
                        v-for="item in previewReviews.slice(0, 2)" 
                        :key="item.id"
                        :class="[
                          'p-3 border space-y-1.5 shadow-xs',
                          widgetConfig.cardRadius,
                          widgetConfig.theme === 'dark' || previewBg === 'dark' 
                            ? 'bg-slate-800/90 border-slate-700/80' 
                            : 'bg-slate-50/90 border-slate-200/80'
                        ]"
                      >
                        <div class="flex items-center justify-between gap-1.5">
                          <div class="flex items-center gap-1.5 min-w-0">
                            <img v-if="widgetConfig.showAvatar" :src="item.avatar" class="size-6 rounded-full object-cover shrink-0" />
                            <span class="text-xs font-semibold truncate" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-100' : 'text-slate-900'">{{ item.author }}</span>
                          </div>
                          <span v-if="widgetConfig.showPlatformLogo" class="text-[9px] font-medium text-muted-foreground">{{ item.platform }}</span>
                        </div>
                        <div v-if="widgetConfig.showStars" class="flex gap-0.5 text-amber-500">
                          <Star v-for="s in item.rating" :key="s" class="size-2.5 fill-amber-500 text-amber-500" />
                        </div>
                        <p class="text-[11px] leading-relaxed line-clamp-2" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-300' : 'text-slate-600'">
                          "{{ item.content }}"
                        </p>
                      </div>
                    </div>

                    <!-- 4. FLOATING BADGE (Mobile) -->
                    <div v-else-if="widgetConfig.layout === 'badge'" class="py-4 flex items-center justify-center">
                      <div 
                        class="p-3 rounded-xl border shadow-md flex items-center gap-2.5 w-full max-w-[240px]"
                        :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'bg-slate-800/90 border-slate-700' : 'bg-white border-slate-200'"
                      >
                        <div class="p-1.5 rounded-lg bg-primary/10 text-primary shrink-0">
                          <Star class="size-4 fill-amber-500 text-amber-500" />
                        </div>
                        <div class="min-w-0">
                          <div class="flex items-center gap-1 text-xs font-bold" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-100' : 'text-slate-900'">
                            <span>4.9 ★★★★★</span>
                            <span class="text-[10px] text-emerald-500 font-semibold">(1,096)</span>
                          </div>
                          <p class="text-[9.5px] truncate text-muted-foreground">Google & Trustpilot</p>
                        </div>
                      </div>
                    </div>

                    <!-- 5. COMPACT (Mobile) -->
                    <div v-else-if="widgetConfig.layout === 'compact'" class="space-y-2">
                      <div 
                        v-for="item in previewReviews.slice(0, 2)" 
                        :key="item.id"
                        class="p-2.5 rounded-lg border space-y-1"
                        :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'bg-slate-800/80 border-slate-700' : 'bg-muted/20 border-border/80'"
                      >
                        <div class="flex items-center justify-between text-xs gap-1.5">
                          <span class="font-semibold text-[11px] truncate" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-100' : 'text-foreground'">{{ item.author }}</span>
                          <div class="flex gap-0.5 text-amber-500 shrink-0">
                            <Star v-for="s in 5" :key="s" class="size-2 fill-amber-500 text-amber-500" />
                          </div>
                        </div>
                        <p class="text-[10.5px] line-clamp-2 leading-relaxed text-muted-foreground">
                          "{{ item.content }}"
                        </p>
                      </div>
                    </div>
                  </div>

                  <!-- Simulated Webpage Footer -->
                  <div class="pt-3 pb-1 text-center text-[8.5px] text-muted-foreground border-t border-border/40">
                    © 2026 Your Company. All rights reserved.
                  </div>
                </div>
            </div>

            <!-- 2. DESKTOP / TABLET DEVICE SIMULATOR FRAME -->
            <div 
              v-else
              :class="[
                'w-full transition-all duration-300 my-auto rounded-2xl overflow-hidden border border-border/80 shadow-2xl bg-white dark:bg-card flex flex-col',
                previewDevice === 'desktop' ? 'max-w-4xl' : 'max-w-[680px]'
              ]"
            >
              <!-- Browser Header Bar -->
              <div class="px-4 py-2.5 bg-slate-100/90 dark:bg-slate-800/90 border-b border-border/60 flex items-center justify-between shrink-0">
                <div class="flex items-center gap-1.5">
                  <div class="size-2.5 rounded-full bg-red-400/80"></div>
                  <div class="size-2.5 rounded-full bg-amber-400/80"></div>
                  <div class="size-2.5 rounded-full bg-emerald-400/80"></div>
                </div>
                <div class="flex items-center gap-1.5 bg-white dark:bg-slate-900 px-3 py-1 rounded-md border border-border/60 text-xs font-mono text-muted-foreground w-64 justify-center">
                  <span class="text-emerald-500">🔒</span>
                  <span class="truncate text-foreground/80">https://yourwebsite.com</span>
                </div>
                <div class="w-8"></div>
              </div>

              <!-- Browser Webpage Content -->
              <div class="p-6 sm:p-8 space-y-6 bg-slate-50/50 dark:bg-background overflow-y-auto max-h-[600px] hide-scrollbar">
                <!-- Website Hero Header -->
                <div class="text-center space-y-1">
                  <span class="text-xs uppercase tracking-wider font-semibold text-primary">Customer Testimonials</span>
                  <h2 class="text-lg sm:text-xl font-bold text-foreground">Loved by thousands of businesses</h2>
                </div>

                <!-- THE RENDERED WIDGET CONTAINER (Desktop/Tablet) -->
                <div 
                  :class="[
                    'w-full transition-all border shadow-lg relative',
                    widgetConfig.cardRadius,
                    'p-6 sm:p-8',
                    widgetConfig.theme === 'dark' || previewBg === 'dark' 
                      ? 'bg-slate-900 text-slate-100 border-slate-800' 
                      : 'bg-white text-slate-900 border-slate-200/90'
                  ]"
                >
                  <!-- 1. Responsive Aggregated Trust Banner Header -->
                  <div 
                    v-if="widgetConfig.showTrustHeader" 
                    class="mb-4 sm:mb-6 pb-3.5 sm:pb-5 border-b transition-colors"
                    :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'border-slate-800' : 'border-slate-100'"
                  >
                    <div class="flex items-center justify-between gap-2.5">
                      <div class="flex items-center gap-2.5 sm:gap-3 min-w-0">
                        <div class="size-9 sm:size-10 rounded-xl bg-primary/10 text-primary flex items-center justify-center font-bold text-sm sm:text-base shrink-0">
                          4.9
                        </div>
                        <div class="min-w-0">
                          <div class="flex items-center gap-1 text-amber-500">
                            <Star class="size-3.5 sm:size-4 fill-amber-500 text-amber-500" />
                            <Star class="size-3.5 sm:size-4 fill-amber-500 text-amber-500" />
                            <Star class="size-3.5 sm:size-4 fill-amber-500 text-amber-500" />
                            <Star class="size-3.5 sm:size-4 fill-amber-500 text-amber-500" />
                            <StarHalf class="size-3.5 sm:size-4 fill-amber-500 text-amber-500" />
                            <span class="text-xs font-semibold ml-1 shrink-0" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-100' : 'text-slate-800'">4.9 / 5</span>
                          </div>
                          <p class="text-[11px] sm:text-xs mt-0.5 truncate" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-400' : 'text-slate-500'">
                            Based on 1,096+ verified reviews across Google, Yelp & Facebook
                          </p>
                        </div>
                      </div>

                      <div 
                        class="gap-1.5 text-[10.5px] sm:text-xs py-1 px-2.5 rounded-md border shrink-0 font-medium whitespace-nowrap flex items-center transition-colors shadow-2xs"
                        :class="widgetConfig.theme === 'dark' || previewBg === 'dark'
                          ? 'border-emerald-500/40 bg-emerald-500/15 text-emerald-400'
                          : 'border-emerald-500/30 bg-emerald-500/10 text-emerald-700'"
                      >
                        <ShieldCheck class="size-3.5 sm:size-4 text-emerald-500 shrink-0" />
                        <span>Verified Customer Proof</span>
                      </div>
                    </div>
                  </div>

                  <!-- 2. WIDGET LAYOUT: CAROUSEL SLIDER (Desktop/Tablet) -->
                  <div v-if="widgetConfig.layout === 'carousel'" class="relative">
                    <div class="overflow-hidden w-full">
                      <div 
                        class="transition-transform duration-300 ease-out flex"
                        :style="{ 
                          transform: `translateX(calc(-${carouselIndex} * (50% + 8px)))`,
                          gap: '16px'
                        }"
                      >
                        <div 
                          v-for="item in previewReviews" 
                          :key="item.id"
                          :class="[
                            'border flex flex-col justify-between shrink-0 transition-all shadow-xs box-border w-[calc(50%-8px)] min-w-[calc(50%-8px)] p-5',
                            widgetConfig.cardRadius,
                            widgetConfig.theme === 'dark' || previewBg === 'dark' 
                              ? 'bg-slate-800/80 border-slate-700/80' 
                              : 'bg-slate-50/90 border-slate-200/80'
                          ]"
                        >
                          <div class="space-y-2.5">
                            <div class="flex items-center justify-between gap-2">
                              <div class="flex items-center gap-2.5 min-w-0">
                                <img 
                                  v-if="widgetConfig.showAvatar" 
                                  :src="item.avatar" 
                                  :alt="item.author"
                                  class="size-8 sm:size-9 rounded-full object-cover border border-border/60 shrink-0"
                                />
                                <div class="min-w-0">
                                  <div class="flex items-center gap-1">
                                    <span class="text-xs font-semibold truncate" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-100' : 'text-slate-900'">{{ item.author }}</span>
                                    <span v-if="widgetConfig.showVerifiedBadge" class="text-[10px] text-emerald-500 font-medium shrink-0">
                                      <CheckCircle2 class="size-3" />
                                    </span>
                                  </div>
                                  <span v-if="widgetConfig.showDate" class="text-[10.5px] text-muted-foreground block truncate">{{ item.date }}</span>
                                </div>
                              </div>

                              <span 
                                v-if="widgetConfig.showPlatformLogo" 
                                class="text-[10px] sm:text-[11px] px-2 py-0.5 rounded-full font-medium shrink-0"
                                :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'bg-slate-700 text-slate-300' : 'bg-slate-200/90 text-slate-700'"
                              >
                                {{ item.platform }}
                              </span>
                            </div>

                            <div v-if="widgetConfig.showStars" class="flex gap-0.5 text-amber-500">
                              <Star v-for="s in item.rating" :key="s" class="size-3.5 fill-amber-500 text-amber-500" />
                            </div>

                            <p class="text-xs leading-relaxed line-clamp-3" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-300' : 'text-slate-600'">
                              "{{ item.content }}"
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Carousel Controls -->
                    <div class="flex items-center justify-between mt-4 pt-2">
                      <div class="flex items-center gap-1.5">
                        <span 
                          v-for="(_, i) in previewReviews.slice(0, 6)" 
                          :key="i"
                          @click="carouselIndex = i"
                          :class="[
                            'h-1.5 rounded-full transition-all cursor-pointer',
                            carouselIndex === i ? 'w-5 bg-primary' : 'w-1.5 bg-muted-foreground/30 hover:bg-muted-foreground/50'
                          ]"
                        ></span>
                      </div>

                      <div class="flex items-center gap-1.5">
                        <button 
                          @click="prevSlide" 
                          class="size-7 sm:size-8 rounded-full border border-border/80 flex items-center justify-center hover:bg-muted transition-colors"
                        >
                          <ChevronLeft class="size-3.5 sm:size-4" />
                        </button>
                        <button 
                          @click="nextSlide" 
                          class="size-7 sm:size-8 rounded-full border border-border/80 flex items-center justify-center hover:bg-muted transition-colors"
                        >
                          <ChevronRight class="size-3.5 sm:size-4" />
                        </button>
                      </div>
                    </div>
                  </div>

                  <!-- 3. MASONRY GRID (Desktop/Tablet) -->
                  <div v-else-if="widgetConfig.layout === 'grid'" class="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                    <div 
                      v-for="item in previewReviews.slice(0, 4)" 
                      :key="item.id"
                      :class="[
                        'p-4 border flex flex-col justify-between shadow-xs transition-colors',
                        widgetConfig.cardRadius,
                        widgetConfig.theme === 'dark' || previewBg === 'dark' 
                          ? 'bg-slate-800/90 border-slate-700/80' 
                          : 'bg-slate-50/90 border-slate-200/80'
                      ]"
                    >
                      <div class="space-y-2">
                        <div class="flex items-center justify-between gap-2">
                          <div class="flex items-center gap-2 min-w-0">
                            <img v-if="widgetConfig.showAvatar" :src="item.avatar" class="size-7 rounded-full object-cover shrink-0" />
                            <span class="text-xs font-semibold truncate" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-100' : 'text-slate-900'">{{ item.author }}</span>
                          </div>
                          <span v-if="widgetConfig.showPlatformLogo" class="text-[10px] font-medium shrink-0" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-400' : 'text-slate-500'">{{ item.platform }}</span>
                        </div>
                        <div v-if="widgetConfig.showStars" class="flex gap-0.5 text-amber-500">
                          <Star v-for="s in item.rating" :key="s" class="size-3 fill-amber-500 text-amber-500" />
                        </div>
                        <p class="text-xs leading-relaxed line-clamp-3" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-300' : 'text-slate-600'">
                          "{{ item.content }}"
                        </p>
                      </div>
                    </div>
                  </div>

                  <!-- 4. FLOATING BADGE (Desktop/Tablet) -->
                  <div v-else-if="widgetConfig.layout === 'badge'" class="py-6 sm:py-8 flex items-center justify-center">
                    <div 
                      class="p-3.5 sm:p-4 rounded-2xl border shadow-xl flex items-center gap-3 max-w-xs sm:max-w-sm w-full transition-colors"
                      :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'bg-slate-800/90 border-slate-700' : 'bg-white border-slate-200'"
                    >
                      <div class="p-2 sm:p-2.5 rounded-xl bg-primary/10 text-primary shrink-0">
                        <Star class="size-5 sm:size-6 fill-amber-500 text-amber-500" />
                      </div>
                      <div class="min-w-0">
                        <div class="flex items-center gap-1.5">
                          <span class="text-sm sm:text-base font-bold" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-100' : 'text-slate-900'">4.9 ★★★★★</span>
                          <span class="text-xs font-semibold text-emerald-500">(1,096)</span>
                        </div>
                        <p class="text-[11px] mt-0.5 truncate" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-400' : 'text-slate-500'">Verified reviews on Google & Trustpilot</p>
                      </div>
                    </div>
                  </div>

                  <!-- 5. COMPACT (Desktop/Tablet) -->
                  <div v-else-if="widgetConfig.layout === 'compact'" class="space-y-2.5 max-w-md mx-auto">
                    <div 
                      v-for="item in previewReviews.slice(0, 3)" 
                      :key="item.id"
                      class="p-3 rounded-xl border space-y-1.5 transition-colors"
                      :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'bg-slate-800/80 border-slate-700' : 'bg-muted/20 border-border/80'"
                    >
                      <div class="flex items-center justify-between text-xs gap-2">
                        <span class="font-semibold truncate" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-100' : 'text-foreground'">{{ item.author }}</span>
                        <div class="flex gap-0.5 text-amber-500 shrink-0">
                          <Star v-for="s in 5" :key="s" class="size-2.5 fill-amber-500 text-amber-500" />
                        </div>
                      </div>
                      <p class="text-[11.5px] line-clamp-2 leading-relaxed" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-300' : 'text-muted-foreground'">
                        "{{ item.content }}"
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

        </div>

      </div>

      <!-- Footer Action Bar -->
      <div class="px-4 sm:px-6 py-3 border-t border-border bg-card flex flex-col sm:flex-row sm:items-center justify-between gap-3 shrink-0">
        <div class="flex items-center gap-2 text-xs text-muted-foreground">
          <CheckCircle2 class="size-4 text-emerald-500 shrink-0" />
          <span class="truncate">Real-time preview synchronized · Instant HTML & JS CDN delivery</span>
        </div>

        <div class="flex items-center gap-2 sm:gap-3 self-end sm:self-auto">
          <Button variant="ghost" class="border border-border hover:border-transparent text-xs sm:text-sm h-8 sm:h-9" @click="close">
            Close
          </Button>
          <Button class="gap-1.5 text-xs sm:text-sm h-8 sm:h-9" @click="handleSaveWidget">
            <Check v-if="isSaved" class="size-3.5 sm:size-4 text-emerald-400" />
            <Sparkles v-else class="size-3.5 sm:size-4" />
            {{ isSaved ? 'Widget Saved & Live!' : 'Save & Publish Widget' }}
          </Button>
        </div>
      </div>

    </div>
  </div>
</template>
