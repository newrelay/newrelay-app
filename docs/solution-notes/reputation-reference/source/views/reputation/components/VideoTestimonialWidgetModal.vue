<script setup lang="ts">
import { ref, computed } from 'vue'
import {
  X, LayoutGrid, Code2, Copy, Check, Sparkles, Monitor, Tablet,
  Smartphone, Eye, Sliders, Palette, Filter, RefreshCw, ChevronLeft,
  ChevronRight, Star, CheckCircle2, Globe, ExternalLink, Moon, Sun,
  Layers, Play, Clock, MessageSquare, Volume2, ShieldCheck, Share2,
  Video, EyeOff, Radio
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
const previewDevice = ref<'desktop' | 'tablet' | 'mobile'>('desktop')
const previewBg = ref<'light' | 'dark'>('light')

// Copied feedback
const isCopied = ref(false)
const isSaved = ref(false)

// Active video preview player modal
const activePlayingVideo = ref<any | null>(null)

// Video Widget Configurations
const widgetConfig = ref({
  name: 'Main Website Video Testimonials Widget',
  layout: 'grid', // 'grid' | 'carousel' | 'bubble' | 'story_strip'
  
  // Platform filters
  platforms: {
    google: true,
    facebook: true,
    trustpilot: true,
    yelp: true,
    direct: true
  },
  
  // Star & rating filters
  minRating: '4', // 'all' | '4' | '5'
  publishedOnly: true,
  aiHighlightsOnly: false,
  maxVideos: 6,
  
  // Appearance
  theme: 'system', // 'light' | 'dark' | 'system'
  cardRadius: 'rounded-2xl', // 'rounded-none' | 'rounded-lg' | 'rounded-2xl' | 'rounded-3xl'
  aspectRatio: 'portrait', // 'portrait' (4:5) | 'story' (9:16) | 'landscape' (16:9)
  accentColor: 'indigo', // 'indigo' | 'emerald' | 'blue' | 'rose' | 'amber'
  
  // Video & Element Visibility
  autoPlayHover: true,
  showPlayButton: true,
  showDuration: true,
  showTranscript: true,
  showStars: true,
  showAuthorAvatar: true,
  showCompany: true,
  showPlatformBadge: true,
  showVerifiedCheck: true,
  showAiTags: true,
  
  // Carousel / Bubble specific
  autoPlayCarousel: true,
  carouselSpeed: 5,
  bubblePosition: 'bottom-right', // 'bottom-right' | 'bottom-left' | 'top-right' | 'top-left'
  bubblePulseAnimation: true
})

// Mock Video Testimonial items for live widget preview
const allVideoTestimonials = [
  {
    id: 1,
    author: 'Sarah Johnson',
    company: 'Marketing VP, Lumina Tech',
    avatar: 'https://i.pravatar.cc/150?u=s1',
    thumbnail: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=600&auto=format&fit=crop',
    duration: '0:47',
    rating: 5,
    platform: 'Google',
    status: 'Published',
    aiHighlight: true,
    aiTag: 'Fast Setup',
    quote: 'Our team saw a 42% conversion spike within the first 10 days of adding this to our landing pages!'
  },
  {
    id: 2,
    author: 'Michael Brown',
    company: 'Founder, CloudFlow',
    avatar: 'https://i.pravatar.cc/150?u=m2',
    thumbnail: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=600&auto=format&fit=crop',
    duration: '01:12',
    rating: 5,
    platform: 'Facebook',
    status: 'Published',
    aiHighlight: true,
    aiTag: 'ROI & Value',
    quote: 'The video quality and seamless playback built instant trust with enterprise prospects.'
  },
  {
    id: 3,
    author: 'Emily Rodriguez',
    company: 'Director of Growth, DesignHub',
    avatar: 'https://i.pravatar.cc/150?u=e3',
    thumbnail: 'https://images.unsplash.com/photo-1573164713988-8665fc963095?q=80&w=600&auto=format&fit=crop',
    duration: '00:35',
    rating: 5,
    platform: 'Yelp',
    status: 'Published',
    aiHighlight: false,
    aiTag: 'Easy Onboarding',
    quote: 'Setup took literally under 3 minutes. Cleanest review widget studio in the industry.'
  },
  {
    id: 4,
    author: 'David Lee',
    company: 'Operations Lead, Apex Systems',
    avatar: 'https://i.pravatar.cc/150?u=d4',
    thumbnail: 'https://images.unsplash.com/photo-1556761175-5973dc0f32d7?q=80&w=600&auto=format&fit=crop',
    duration: '01:05',
    rating: 5,
    platform: 'Trustpilot',
    status: 'Published',
    aiHighlight: true,
    aiTag: 'Support 10/10',
    quote: 'The customer service and automated review routing have saved us over 15 hours every week.'
  },
  {
    id: 5,
    author: 'James Wilson',
    company: 'Logistics Pro',
    avatar: 'https://i.pravatar.cc/150?u=j5',
    thumbnail: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?q=80&w=600&auto=format&fit=crop',
    duration: '00:59',
    rating: 4,
    platform: 'Google',
    status: 'Published',
    aiHighlight: false,
    aiTag: 'Reliability',
    quote: 'High reliability and excellent video compression for ultra fast load times on mobile.'
  },
  {
    id: 6,
    author: 'Elena Rostova',
    company: 'Head of Brand, Velvet Labs',
    avatar: 'https://i.pravatar.cc/150?u=e6',
    thumbnail: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=600&auto=format&fit=crop',
    duration: '00:44',
    rating: 5,
    platform: 'Direct',
    status: 'Published',
    aiHighlight: true,
    aiTag: 'Conversion Booster',
    quote: 'Having authentic customer faces and voices on our checkout page eliminated all hesitation.'
  }
]

// Filtered videos based on customizer settings
const previewVideos = computed(() => {
  return allVideoTestimonials.filter(v => {
    // Platform check
    const platformKey = v.platform.toLowerCase() as keyof typeof widgetConfig.value.platforms
    if (widgetConfig.value.platforms[platformKey] === false) return false
    
    // Min rating check
    if (widgetConfig.value.minRating === '5' && v.rating < 5) return false
    if (widgetConfig.value.minRating === '4' && v.rating < 4) return false
    
    // AI highlights only check
    if (widgetConfig.value.aiHighlightsOnly && !v.aiHighlight) return false
    
    return true
  }).slice(0, widgetConfig.value.maxVideos)
})

// Carousel active index
const carouselIndex = ref(0)
function nextSlide() {
  if (carouselIndex.value < previewVideos.value.length - 1) {
    carouselIndex.value++
  } else {
    carouselIndex.value = 0
  }
}
function prevSlide() {
  if (carouselIndex.value > 0) {
    carouselIndex.value--
  } else {
    carouselIndex.value = previewVideos.value.length - 1
  }
}

// Embed code type
const embedType = ref<'script' | 'iframe' | 'react'>('script')

const generatedScriptCode = computed(() => {
  return `<!-- New Relay Video Testimonials Widget -->
<div id="nr-video-widget" 
  data-widget-id="vw_${widgetConfig.value.layout}_9482" 
  data-layout="${widgetConfig.value.layout}" 
  data-theme="${widgetConfig.value.theme}">
</div>
<script src="https://cdn.newrelay.com/widgets/v2/video-testimonials.js" async defer><\/script>`
})

const generatedIframeCode = computed(() => {
  return `<iframe 
  src="https://embed.newrelay.com/video-widget/vw_9482?layout=${widgetConfig.value.layout}&theme=${widgetConfig.value.theme}" 
  width="100%" 
  height="540" 
  frameborder="0" 
  allow="autoplay; fullscreen"
  loading="lazy">
</iframe>`
})

const generatedReactCode = computed(() => {
  return `import { VideoTestimonialWidget } from '@newrelay/react-widgets'

export default function TestimonialSection() {
  return (
    <VideoTestimonialWidget 
      widgetId="vw_9482"
      layout="${widgetConfig.value.layout}"
      theme="${widgetConfig.value.theme}"
      autoPlayHover={${widgetConfig.value.autoPlayHover}}
    />
  )
}`
})

const currentEmbedSnippet = computed(() => {
  if (embedType.value === 'script') return generatedScriptCode.value
  if (embedType.value === 'iframe') return generatedIframeCode.value
  return generatedReactCode.value
})

function copyEmbedCode() {
  navigator.clipboard.writeText(currentEmbedSnippet.value)
  isCopied.value = true
  setTimeout(() => {
    isCopied.value = false
  }, 2200)
}

function handleSaveWidget() {
  isSaved.value = true
  setTimeout(() => {
    isSaved.value = false
  }, 2000)
}

function close() {
  emit('update:open', false)
}
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center p-2 sm:p-4 lg:p-6">
    <!-- Backdrop -->
    <div class="absolute inset-0 bg-background/80 backdrop-blur-md" @click="close"></div>

    <!-- Modal Container -->
    <div class="relative w-[98vw] sm:w-[96vw] max-w-[1440px] h-[96vh] sm:h-[92vh] bg-card rounded-xl sm:rounded-2xl shadow-2xl border border-border flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200">
      
      <!-- Top Modal Header -->
      <div class="px-4 sm:px-6 py-3.5 border-b border-border bg-muted/30 flex items-center justify-between shrink-0">
        <div class="flex items-center gap-3">
          <div class="p-2 bg-primary/10 rounded-xl text-primary shrink-0">
            <LayoutGrid class="size-5" />
          </div>
          <div>
            <div class="flex items-center gap-2 flex-wrap">
              <h2 class="text-base font-semibold text-foreground">Video Testimonial Widget Studio</h2>
              <Badge variant="secondary" class="bg-primary/10 text-primary text-[11px] font-medium hidden sm:inline-flex">Live Video Embed</Badge>
            </div>
            <p class="text-[12.5px] text-muted-foreground hidden sm:block">Customize, preview in real time, and generate authentic video testimonial widgets for your website.</p>
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
              <span>Filters</span>
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
              <span>Embed Code</span>
            </button>
          </div>

          <!-- Tab Panels Container -->
          <div class="flex-1 overflow-y-auto p-4 sm:p-5 space-y-6 hide-scrollbar">
            
            <!-- ==================== TAB 1: LAYOUT ==================== -->
            <div v-if="activeTab === 'layout'" class="space-y-5">
              <!-- Layout Picker Cards -->
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Video Display Template</label>
                <p class="text-[12px] text-muted-foreground mb-3">Select how customer video testimonials are showcased on your site.</p>
                
                <div class="grid grid-cols-2 gap-2.5">
                  <!-- Grid -->
                  <div 
                    @click="widgetConfig.layout = 'grid'"
                    :class="[
                      'p-3 rounded-xl border cursor-pointer transition-all flex flex-col gap-2',
                      widgetConfig.layout === 'grid' 
                        ? 'border-primary bg-primary/5 ring-1 ring-primary/30 shadow-2xs' 
                        : 'border-border hover:border-border/80 hover:bg-muted/30'
                    ]"
                  >
                    <div class="flex items-center justify-between">
                      <div class="p-1.5 rounded-lg bg-primary/10 text-primary">
                        <LayoutGrid class="size-4" />
                      </div>
                      <CheckCircle2 v-if="widgetConfig.layout === 'grid'" class="size-4 text-primary shrink-0" />
                    </div>
                    <div>
                      <div class="text-[13px] font-semibold text-foreground">Wall of Love (Grid)</div>
                      <p class="text-[11px] text-muted-foreground">Multi-column video card grid</p>
                    </div>
                  </div>

                  <!-- Carousel -->
                  <div 
                    @click="widgetConfig.layout = 'carousel'"
                    :class="[
                      'p-3 rounded-xl border cursor-pointer transition-all flex flex-col gap-2',
                      widgetConfig.layout === 'carousel' 
                        ? 'border-primary bg-primary/5 ring-1 ring-primary/30 shadow-2xs' 
                        : 'border-border hover:border-border/80 hover:bg-muted/30'
                    ]"
                  >
                    <div class="flex items-center justify-between">
                      <div class="p-1.5 rounded-lg bg-primary/10 text-primary">
                        <Sliders class="size-4" />
                      </div>
                      <CheckCircle2 v-if="widgetConfig.layout === 'carousel'" class="size-4 text-primary shrink-0" />
                    </div>
                    <div>
                      <div class="text-[13px] font-semibold text-foreground">Video Carousel</div>
                      <p class="text-[11px] text-muted-foreground">Smooth sliding video reel</p>
                    </div>
                  </div>

                  <!-- Floating Story Bubble -->
                  <div 
                    @click="widgetConfig.layout = 'bubble'"
                    :class="[
                      'p-3 rounded-xl border cursor-pointer transition-all flex flex-col gap-2',
                      widgetConfig.layout === 'bubble' 
                        ? 'border-primary bg-primary/5 ring-1 ring-primary/30 shadow-2xs' 
                        : 'border-border hover:border-border/80 hover:bg-muted/30'
                    ]"
                  >
                    <div class="flex items-center justify-between">
                      <div class="p-1.5 rounded-lg bg-primary/10 text-primary">
                        <Video class="size-4" />
                      </div>
                      <CheckCircle2 v-if="widgetConfig.layout === 'bubble'" class="size-4 text-primary shrink-0" />
                    </div>
                    <div>
                      <div class="text-[13px] font-semibold text-foreground">Corner Video Bubble</div>
                      <p class="text-[11px] text-muted-foreground">Floating interactive popup</p>
                    </div>
                  </div>

                  <!-- Story Strip -->
                  <div 
                    @click="widgetConfig.layout = 'story_strip'"
                    :class="[
                      'p-3 rounded-xl border cursor-pointer transition-all flex flex-col gap-2',
                      widgetConfig.layout === 'story_strip' 
                        ? 'border-primary bg-primary/5 ring-1 ring-primary/30 shadow-2xs' 
                        : 'border-border hover:border-border/80 hover:bg-muted/30'
                    ]"
                  >
                    <div class="flex items-center justify-between">
                      <div class="p-1.5 rounded-lg bg-primary/10 text-primary">
                        <Smartphone class="size-4" />
                      </div>
                      <CheckCircle2 v-if="widgetConfig.layout === 'story_strip'" class="size-4 text-primary shrink-0" />
                    </div>
                    <div>
                      <div class="text-[13px] font-semibold text-foreground">Stories Strip</div>
                      <p class="text-[11px] text-muted-foreground">Instagram-style story circles</p>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Video Interaction Settings -->
              <div class="space-y-3 pt-3 border-t border-border/80">
                <label class="text-[13.5px] font-medium text-foreground block">Playback & Video Controls</label>
                
                <div class="flex items-center justify-between p-3 rounded-xl bg-muted/20 border border-border/80">
                  <div>
                    <div class="text-[13px] font-medium text-foreground">Autoplay Video on Hover</div>
                    <div class="text-[11.5px] text-muted-foreground">Muted video preview starts automatically on mouse hover</div>
                  </div>
                  <Switch v-model="widgetConfig.autoPlayHover" />
                </div>

                <div class="flex items-center justify-between p-3 rounded-xl bg-muted/20 border border-border/80">
                  <div>
                    <div class="text-[13px] font-medium text-foreground">Center Play Overlay Button</div>
                    <div class="text-[11.5px] text-muted-foreground">Display prominent translucent play icon over video cards</div>
                  </div>
                  <Switch v-model="widgetConfig.showPlayButton" />
                </div>

                <div class="flex items-center justify-between p-3 rounded-xl bg-muted/20 border border-border/80">
                  <div>
                    <div class="text-[13px] font-medium text-foreground">Duration Timestamp Badge</div>
                    <div class="text-[11.5px] text-muted-foreground">Show video run time (e.g. 0:47) in the bottom corner</div>
                  </div>
                  <Switch v-model="widgetConfig.showDuration" />
                </div>

                <div class="flex items-center justify-between p-3 rounded-xl bg-muted/20 border border-border/80">
                  <div>
                    <div class="text-[13px] font-medium text-foreground">Show Transcript Excerpt</div>
                    <div class="text-[11.5px] text-muted-foreground">Display key quote snippet under the video card</div>
                  </div>
                  <Switch v-model="widgetConfig.showTranscript" />
                </div>
              </div>

              <!-- Corner Bubble Position (If bubble layout) -->
              <div v-if="widgetConfig.layout === 'bubble'" class="p-3.5 bg-muted/30 border border-border rounded-xl space-y-3">
                <label class="text-[13px] font-semibold text-foreground">Bubble Floating Position</label>
                <div class="grid grid-cols-2 gap-2">
                  <button 
                    v-for="pos in [
                      { id: 'bottom-right', label: 'Bottom Right' },
                      { id: 'bottom-left', label: 'Bottom Left' },
                      { id: 'top-right', label: 'Top Right' },
                      { id: 'top-left', label: 'Top Left' }
                    ]" 
                    :key="pos.id"
                    type="button"
                    @click="widgetConfig.bubblePosition = pos.id"
                    class="py-2 px-3 rounded-lg border text-xs font-medium transition-colors text-center"
                    :class="widgetConfig.bubblePosition === pos.id ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border text-muted-foreground'"
                  >
                    {{ pos.label }}
                  </button>
                </div>
              </div>
            </div>

            <!-- ==================== TAB 2: FILTERS & SOURCES ==================== -->
            <div v-else-if="activeTab === 'filters'" class="space-y-5">
              <!-- Platforms Checkboxes -->
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Source Platforms</label>
                <p class="text-[12px] text-muted-foreground mb-3">Select which channels feed videos into this widget.</p>
                
                <div class="space-y-2">
                  <label class="flex items-center justify-between p-2.5 rounded-xl border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5">
                      <span class="size-6 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-[11px] font-bold text-foreground">G</span>
                      <span class="text-[13px] font-medium text-foreground">Google Reviews</span>
                    </div>
                    <Checkbox v-model="widgetConfig.platforms.google" />
                  </label>

                  <label class="flex items-center justify-between p-2.5 rounded-xl border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5">
                      <span class="size-6 rounded-full bg-blue-500/10 text-blue-600 dark:text-blue-400 flex items-center justify-center text-[11px] font-bold">f</span>
                      <span class="text-[13px] font-medium text-foreground">Facebook Testimonials</span>
                    </div>
                    <Checkbox v-model="widgetConfig.platforms.facebook" />
                  </label>

                  <label class="flex items-center justify-between p-2.5 rounded-xl border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5">
                      <span class="size-6 rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center text-[11px] font-bold">★</span>
                      <span class="text-[13px] font-medium text-foreground">Trustpilot Verified</span>
                    </div>
                    <Checkbox v-model="widgetConfig.platforms.trustpilot" />
                  </label>

                  <label class="flex items-center justify-between p-2.5 rounded-xl border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5">
                      <span class="size-6 rounded-full bg-rose-500/10 text-rose-600 dark:text-rose-400 flex items-center justify-center text-[11px] font-bold">Y</span>
                      <span class="text-[13px] font-medium text-foreground">Yelp Video Reviews</span>
                    </div>
                    <Checkbox v-model="widgetConfig.platforms.yelp" />
                  </label>

                  <label class="flex items-center justify-between p-2.5 rounded-xl border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5">
                      <span class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center text-[11px] font-bold">NR</span>
                      <span class="text-[13px] font-medium text-foreground">Direct Video Form Submissions</span>
                    </div>
                    <Checkbox v-model="widgetConfig.platforms.direct" />
                  </label>
                </div>
              </div>

              <!-- Rating Filter -->
              <div class="pt-3 border-t border-border">
                <label class="text-[13.5px] font-medium text-foreground block mb-2">Minimum Star Rating</label>
                <div class="grid grid-cols-3 gap-2">
                  <button 
                    v-for="r in [
                      { id: 'all', label: 'All Ratings' },
                      { id: '4', label: '4★ & Above' },
                      { id: '5', label: '5★ Only' }
                    ]"
                    :key="r.id"
                    type="button"
                    @click="widgetConfig.minRating = r.id"
                    class="py-2 px-3 rounded-lg border text-xs text-center cursor-pointer transition-colors"
                    :class="widgetConfig.minRating === r.id ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                  >
                    {{ r.label }}
                  </button>
                </div>
              </div>

              <!-- AI Highlights Only Filter -->
              <div class="flex items-center justify-between p-3.5 bg-muted/20 rounded-xl border border-border">
                <div>
                  <div class="text-[13px] font-semibold text-foreground flex items-center gap-1.5">
                    <Sparkles class="size-3.5 text-primary" />
                    <span>Relay AI Highlights Only</span>
                  </div>
                  <div class="text-[11.5px] text-muted-foreground mt-0.5">Filter for videos marked as best marketing highlights</div>
                </div>
                <Switch v-model="widgetConfig.aiHighlightsOnly" />
              </div>

              <!-- Max Videos Slider -->
              <div class="pt-2">
                <div class="flex items-center justify-between mb-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">Maximum Videos Displayed</label>
                  <span class="text-xs font-semibold text-primary">{{ widgetConfig.maxVideos }} videos</span>
                </div>
                <input 
                  type="range" 
                  min="2" 
                  max="12" 
                  step="1"
                  v-model.number="widgetConfig.maxVideos"
                  class="w-full accent-primary cursor-pointer"
                />
              </div>
            </div>

            <!-- ==================== TAB 3: APPEARANCE & THEME ==================== -->
            <div v-else-if="activeTab === 'appearance'" class="space-y-5">
              <!-- Color Theme -->
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-2">Widget Theme</label>
                <div class="grid grid-cols-3 gap-2">
                  <button 
                    v-for="t in [
                      { id: 'light', label: 'Light', icon: Sun },
                      { id: 'dark', label: 'Dark', icon: Moon },
                      { id: 'system', label: 'Adaptive', icon: Globe }
                    ]"
                    :key="t.id"
                    type="button"
                    @click="widgetConfig.theme = t.id"
                    class="py-2.5 px-3 rounded-xl border text-xs text-center cursor-pointer transition-colors flex items-center justify-center gap-1.5"
                    :class="widgetConfig.theme === t.id ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                  >
                    <component :is="t.icon" class="size-3.5" />
                    <span>{{ t.label }}</span>
                  </button>
                </div>
              </div>

              <!-- Video Card Corner Radius -->
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-2">Card Corner Radius</label>
                <div class="grid grid-cols-4 gap-2">
                  <button 
                    v-for="rad in [
                      { id: 'rounded-none', label: 'Square' },
                      { id: 'rounded-lg', label: 'Medium' },
                      { id: 'rounded-2xl', label: 'Large' },
                      { id: 'rounded-[28px]', label: 'Pill' }
                    ]"
                    :key="rad.id"
                    type="button"
                    @click="widgetConfig.cardRadius = rad.id"
                    class="py-2 px-2 rounded-lg border text-xs text-center cursor-pointer transition-colors"
                    :class="widgetConfig.cardRadius === rad.id ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                  >
                    {{ rad.label }}
                  </button>
                </div>
              </div>

              <!-- Visible Badges & Metadata Toggle List -->
              <div class="space-y-3 pt-3 border-t border-border">
                <label class="text-[13.5px] font-medium text-foreground block">Display Elements</label>
                
                <div class="flex items-center justify-between p-2.5 rounded-xl bg-muted/20 border border-border">
                  <span class="text-[13px] text-foreground">Star Rating Bar</span>
                  <Switch v-model="widgetConfig.showStars" />
                </div>

                <div class="flex items-center justify-between p-2.5 rounded-xl bg-muted/20 border border-border">
                  <span class="text-[13px] text-foreground">Author Avatar & Name</span>
                  <Switch v-model="widgetConfig.showAuthorAvatar" />
                </div>

                <div class="flex items-center justify-between p-2.5 rounded-xl bg-muted/20 border border-border">
                  <span class="text-[13px] text-foreground">Company / Role Subtitle</span>
                  <Switch v-model="widgetConfig.showCompany" />
                </div>

                <div class="flex items-center justify-between p-2.5 rounded-xl bg-muted/20 border border-border">
                  <span class="text-[13px] text-foreground">Source Platform Icon</span>
                  <Switch v-model="widgetConfig.showPlatformBadge" />
                </div>

                <div class="flex items-center justify-between p-2.5 rounded-xl bg-muted/20 border border-border">
                  <span class="text-[13px] text-foreground">Relay AI Topic Pills</span>
                  <Switch v-model="widgetConfig.showAiTags" />
                </div>
              </div>
            </div>

            <!-- ==================== TAB 4: EMBED CODE ==================== -->
            <div v-else-if="activeTab === 'embed'" class="space-y-5">
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Integration Format</label>
                <p class="text-[12px] text-muted-foreground mb-3">Copy and paste this snippet anywhere on your website.</p>
                
                <div class="grid grid-cols-3 gap-2">
                  <button 
                    v-for="fmt in [
                      { id: 'script', label: 'HTML / JS' },
                      { id: 'iframe', label: 'iFrame' },
                      { id: 'react', label: 'React / Next' }
                    ]"
                    :key="fmt.id"
                    type="button"
                    @click="embedType = fmt.id as any"
                    class="py-2 px-3 rounded-lg border text-xs text-center cursor-pointer transition-colors"
                    :class="embedType === fmt.id ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                  >
                    {{ fmt.label }}
                  </button>
                </div>
              </div>

              <!-- Code Box -->
              <div class="relative rounded-xl border border-border bg-slate-950 text-slate-100 p-4 font-mono text-xs overflow-x-auto shadow-inner">
                <pre class="whitespace-pre-wrap break-all leading-relaxed">{{ currentEmbedSnippet }}</pre>
                
                <Button 
                  size="sm" 
                  class="absolute top-3 right-3 h-8 gap-1.5 text-xs shadow-md"
                  @click="copyEmbedCode"
                >
                  <Check v-if="isCopied" class="size-3.5 text-emerald-400" />
                  <Copy v-else class="size-3.5" />
                  {{ isCopied ? 'Copied!' : 'Copy Code' }}
                </Button>
              </div>

              <!-- 1-Click Platform Guides -->
              <div class="p-4 rounded-xl bg-muted/20 border border-border space-y-2">
                <div class="text-[13px] font-semibold text-foreground flex items-center gap-2">
                  <Globe class="size-4 text-primary" />
                  <span>Works with all website builders</span>
                </div>
                <div class="flex flex-wrap gap-2 pt-1 text-[11.5px] text-muted-foreground">
                  <Badge variant="outline">Webflow</Badge>
                  <Badge variant="outline">Shopify</Badge>
                  <Badge variant="outline">WordPress</Badge>
                  <Badge variant="outline">Framer</Badge>
                  <Badge variant="outline">Squarespace</Badge>
                  <Badge variant="outline">Next.js</Badge>
                </div>
              </div>
            </div>

          </div>

          <!-- Bottom Customizer Footer -->
          <div class="p-4 border-t border-border bg-muted/20 flex items-center justify-between shrink-0">
            <Button variant="outline" size="sm" class="border border-border hover:border-transparent text-xs" @click="copyEmbedCode">
              <Code2 class="size-3.5 mr-1.5" />
              {{ isCopied ? 'Code Copied!' : 'Get Code' }}
            </Button>
            <Button size="sm" class="text-xs gap-1.5 shadow-xs" @click="handleSaveWidget">
              <Check v-if="isSaved" class="size-3.5 text-emerald-300" />
              <span>{{ isSaved ? 'Saved!' : 'Save Widget' }}</span>
            </Button>
          </div>
        </div>

        <!-- Right Column: Live Interactive Device Canvas Preview -->
        <div 
          :class="[
            'flex-1 flex flex-col overflow-hidden relative',
            mobileViewMode === 'preview' ? 'flex flex-1' : 'hidden lg:flex'
          ]"
        >
          <!-- Canvas Top Controls Toolbar -->
          <div class="h-12 border-b border-border bg-card/60 backdrop-blur-md px-4 flex items-center justify-between shrink-0 z-20">
            <!-- Device View Switcher -->
            <div class="flex items-center gap-1 bg-muted p-1 rounded-lg border border-border/60">
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
              'flex-1 overflow-y-auto p-3 sm:p-5 flex items-center justify-center transition-colors duration-300 hide-scrollbar',
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

              <!-- Scrollable Mobile Webpage Content -->
              <div class="flex-1 overflow-y-auto p-3.5 space-y-3.5 hide-scrollbar">
                <!-- Mobile Hero Header -->
                <div class="text-center pt-1.5 pb-0.5 space-y-0.5">
                  <span class="text-[8.5px] uppercase tracking-wider font-semibold text-primary">CUSTOMER TESTIMONIALS</span>
                  <h3 class="text-xs font-bold text-foreground">Loved by thousands</h3>
                </div>

                <!-- RENDERED WIDGET CONTAINER (Mobile View) -->
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
                  <!-- 1. Wall of Love (Mobile Grid - 1 Col) -->
                  <div v-if="widgetConfig.layout === 'grid'" class="space-y-3">
                    <div 
                      v-for="item in previewVideos.slice(0, 2)" 
                      :key="item.id"
                      class="group relative overflow-hidden border rounded-xl flex flex-col cursor-pointer transition-all"
                      :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'bg-slate-800/90 border-slate-700/80' : 'bg-slate-50/90 border-slate-200/80'"
                      @click="activePlayingVideo = item"
                    >
                      <div class="relative w-full aspect-[4/3] overflow-hidden bg-slate-900">
                        <img :src="item.thumbnail" :alt="item.author" class="w-full h-full object-cover" />
                        <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent"></div>
                        <div v-if="widgetConfig.showPlayButton" class="absolute inset-0 flex items-center justify-center">
                          <div class="size-9 rounded-full bg-white/90 text-slate-900 flex items-center justify-center shadow-lg">
                            <Play class="size-4 ml-0.5 fill-current" />
                          </div>
                        </div>
                        <div v-if="widgetConfig.showDuration" class="absolute bottom-2 right-2 px-1.5 py-0.5 rounded bg-black/60 text-white text-[9px] font-mono">
                          {{ item.duration }}
                        </div>
                      </div>
                      <div class="p-2.5 space-y-1.5">
                        <div v-if="widgetConfig.showStars" class="flex items-center gap-0.5 text-amber-400">
                          <Star v-for="s in item.rating" :key="s" class="size-2.5 fill-amber-400" />
                        </div>
                        <p v-if="widgetConfig.showTranscript" class="text-[10.5px] line-clamp-2 italic" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-300' : 'text-slate-600'">
                          "{{ item.quote }}"
                        </p>
                        <div v-if="widgetConfig.showAuthorAvatar" class="flex items-center gap-1.5 pt-1 border-t" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'border-slate-700' : 'border-slate-200'">
                          <img :src="item.avatar" :alt="item.author" class="size-5 rounded-full object-cover" />
                          <span class="text-[11px] font-semibold truncate">{{ item.author }}</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- 2. Video Carousel (Mobile 1-Card) -->
                  <div v-else-if="widgetConfig.layout === 'carousel'" class="relative">
                    <div class="overflow-hidden w-full">
                      <div 
                        class="transition-transform duration-300 ease-out flex"
                        :style="{ transform: `translateX(-${carouselIndex * 100}%)` }"
                      >
                        <div 
                          v-for="item in previewVideos" 
                          :key="item.id"
                          class="shrink-0 w-full min-w-full border rounded-xl overflow-hidden shadow-xs flex flex-col cursor-pointer"
                          :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'bg-slate-800/90 border-slate-700/80' : 'bg-slate-50/90 border-slate-200/80'"
                          @click="activePlayingVideo = item"
                        >
                          <div class="relative w-full aspect-[4/3] bg-slate-900 overflow-hidden">
                            <img :src="item.thumbnail" :alt="item.author" class="w-full h-full object-cover" />
                            <div class="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent"></div>
                            <div v-if="widgetConfig.showPlayButton" class="absolute inset-0 flex items-center justify-center">
                              <div class="size-9 rounded-full bg-white text-slate-900 flex items-center justify-center shadow-lg">
                                <Play class="size-4 ml-0.5 fill-current" />
                              </div>
                            </div>
                            <div v-if="widgetConfig.showDuration" class="absolute bottom-2 right-2 px-1.5 py-0.5 rounded bg-black/70 text-white text-[9px] font-mono">
                              {{ item.duration }}
                            </div>
                          </div>
                          <div class="p-2.5 space-y-1.5">
                            <div v-if="widgetConfig.showStars" class="flex items-center gap-0.5 text-amber-400">
                              <Star v-for="s in item.rating" :key="s" class="size-2.5 fill-amber-400" />
                            </div>
                            <p v-if="widgetConfig.showTranscript" class="text-[10.5px] line-clamp-2" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-300' : 'text-slate-600'">
                              "{{ item.quote }}"
                            </p>
                            <div v-if="widgetConfig.showAuthorAvatar" class="flex items-center gap-1.5 pt-1 border-t" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'border-slate-700' : 'border-slate-200'">
                              <img :src="item.avatar" :alt="item.author" class="size-5 rounded-full object-cover" />
                              <span class="text-[11px] font-semibold truncate">{{ item.author }}</span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <!-- Controls -->
                    <div class="flex items-center justify-between mt-2.5 pt-1">
                      <div class="flex items-center gap-1">
                        <span 
                          v-for="(_, i) in previewVideos.slice(0, 4)" 
                          :key="i"
                          @click="carouselIndex = i"
                          :class="[
                            'h-1 rounded-full transition-all cursor-pointer',
                            carouselIndex === i ? 'w-3.5 bg-primary' : 'w-1 bg-muted-foreground/30'
                          ]"
                        ></span>
                      </div>
                      <div class="flex items-center gap-1">
                        <button @click="prevSlide" class="size-5 rounded-full border border-border flex items-center justify-center hover:bg-muted">
                          <ChevronLeft class="size-2.5" />
                        </button>
                        <button @click="nextSlide" class="size-5 rounded-full border border-border flex items-center justify-center hover:bg-muted">
                          <ChevronRight class="size-2.5" />
                        </button>
                      </div>
                    </div>
                  </div>

                  <!-- 3. Corner Video Bubble (Mobile) -->
                  <div v-else-if="widgetConfig.layout === 'bubble'" class="py-4 flex flex-col items-center justify-center">
                    <div 
                      :class="[
                        'relative p-1 rounded-full border shadow-xl flex items-center gap-2 pr-3 group cursor-pointer hover:scale-105 transition-all',
                        widgetConfig.theme === 'dark' || previewBg === 'dark' 
                          ? 'bg-slate-800 text-white border-primary shadow-lg ring-1 ring-white/10' 
                          : 'bg-white text-slate-900 border-primary shadow-md'
                      ]"
                      @click="activePlayingVideo = previewVideos[0]"
                    >
                      <div class="relative size-10 rounded-full overflow-hidden border border-white/40 shrink-0">
                        <img :src="previewVideos[0]?.thumbnail || allVideoTestimonials[0].thumbnail" class="w-full h-full object-cover" />
                        <div class="absolute inset-0 bg-black/30 flex items-center justify-center">
                          <Play class="size-3 text-white fill-white" />
                        </div>
                      </div>
                      <div class="min-w-0">
                        <div class="flex items-center gap-1">
                          <span class="text-[10.5px] font-bold truncate">Watch Story</span>
                          <Badge class="h-3 text-[8px] px-1 bg-primary text-primary-foreground font-semibold">Video</Badge>
                        </div>
                        <div class="text-[9.5px] text-muted-foreground truncate">{{ previewVideos[0]?.author || 'Sarah J.' }} · 5★</div>
                      </div>
                    </div>
                  </div>

                  <!-- 4. Stories Strip (Mobile) -->
                  <div v-else-if="widgetConfig.layout === 'story_strip'" class="py-2 overflow-x-auto hide-scrollbar flex items-center gap-2.5 justify-start">
                    <div 
                      v-for="item in previewVideos" 
                      :key="item.id"
                      class="flex flex-col items-center gap-1 cursor-pointer shrink-0"
                      @click="activePlayingVideo = item"
                    >
                      <div class="p-0.5 rounded-full bg-gradient-to-tr from-amber-500 via-rose-500 to-primary">
                        <div class="size-11 rounded-full overflow-hidden border border-white bg-slate-900 relative">
                          <img :src="item.thumbnail" class="w-full h-full object-cover" />
                          <div class="absolute inset-0 bg-black/20 flex items-center justify-center">
                            <Play class="size-2.5 text-white fill-white" />
                          </div>
                        </div>
                      </div>
                      <span class="text-[9.5px] font-medium max-w-[48px] truncate text-center">{{ item.author }}</span>
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
                  <span class="text-xs uppercase tracking-wider font-semibold text-primary">CUSTOMER TESTIMONIALS</span>
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
                  <!-- 1. Wall of Love (Desktop/Tablet Grid) -->
                  <div 
                    v-if="widgetConfig.layout === 'grid'"
                    :class="[
                      'grid gap-4 w-full',
                      previewDevice === 'tablet' ? 'grid-cols-2' : 'grid-cols-3'
                    ]"
                  >
                    <div 
                      v-for="item in previewVideos" 
                      :key="item.id"
                      class="group relative overflow-hidden border transition-all hover:shadow-lg hover:-translate-y-0.5 cursor-pointer flex flex-col"
                      :class="[
                        widgetConfig.cardRadius,
                        widgetConfig.theme === 'dark' || previewBg === 'dark' 
                          ? 'bg-slate-800/90 border-slate-700/80 text-white' 
                          : 'bg-slate-50/90 border-slate-200/80 text-slate-900 shadow-xs'
                      ]"
                      @click="activePlayingVideo = item"
                    >
                      <!-- Video Thumbnail Media Frame -->
                      <div class="relative w-full aspect-[4/5] overflow-hidden bg-slate-900">
                        <img :src="item.thumbnail" :alt="item.author" class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105" />
                        <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent"></div>

                        <!-- Play Button Overlay -->
                        <div v-if="widgetConfig.showPlayButton" class="absolute inset-0 flex items-center justify-center">
                          <div class="size-11 rounded-full bg-white/90 text-slate-900 flex items-center justify-center shadow-xl group-hover:scale-110 group-hover:bg-primary group-hover:text-primary-foreground transition-all">
                            <Play class="size-5 ml-0.5 fill-current" />
                          </div>
                        </div>

                        <!-- Duration Pill -->
                        <div v-if="widgetConfig.showDuration" class="absolute bottom-3 right-3 px-2 py-0.5 rounded-md bg-black/60 backdrop-blur-md text-white text-[10px] font-mono font-medium flex items-center gap-1">
                          <Clock class="size-2.5" />
                          <span>{{ item.duration }}</span>
                        </div>

                        <!-- Platform Badge -->
                        <div v-if="widgetConfig.showPlatformBadge" class="absolute top-3 left-3 px-2 py-0.5 rounded-full bg-black/50 backdrop-blur-md text-white text-[10px] font-semibold">
                          {{ item.platform }}
                        </div>

                        <!-- AI Highlight Pill -->
                        <div v-if="widgetConfig.showAiTags && item.aiTag" class="absolute top-3 right-3 px-2 py-0.5 rounded-full bg-primary/90 text-primary-foreground text-[10px] font-semibold flex items-center gap-1 shadow-sm">
                          <Sparkles class="size-2.5" />
                          <span>{{ item.aiTag }}</span>
                        </div>
                      </div>

                      <!-- Video Details Footer -->
                      <div 
                        v-if="widgetConfig.showStars || widgetConfig.showTranscript || widgetConfig.showAuthorAvatar" 
                        class="p-3.5 space-y-2 flex-1 flex flex-col justify-between"
                        :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'bg-slate-800/90 text-slate-100' : 'bg-slate-50/90 text-slate-900'"
                      >
                        <div class="space-y-1.5">
                          <div v-if="widgetConfig.showStars" class="flex items-center gap-0.5 text-amber-400">
                            <Star v-for="s in item.rating" :key="s" class="size-3 fill-amber-400" />
                          </div>
                          <p v-if="widgetConfig.showTranscript" class="text-[11.5px] line-clamp-2 leading-relaxed italic" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-300' : 'text-slate-600'">
                            "{{ item.quote }}"
                          </p>
                        </div>
                        <div v-if="widgetConfig.showAuthorAvatar" class="flex items-center gap-2 pt-1 border-t" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'border-slate-700' : 'border-slate-200'">
                          <img :src="item.avatar" :alt="item.author" class="size-6 rounded-full object-cover border border-border" />
                          <div class="min-w-0">
                            <div class="text-[12px] font-semibold truncate flex items-center gap-1" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-white' : 'text-slate-900'">
                              <span>{{ item.author }}</span>
                              <CheckCircle2 v-if="widgetConfig.showVerifiedCheck" class="size-3 text-primary shrink-0" />
                            </div>
                            <div v-if="widgetConfig.showCompany" class="text-[10px] truncate" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-400' : 'text-slate-500'">{{ item.company }}</div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- 2. Video Carousel (Desktop/Tablet) -->
                  <div v-else-if="widgetConfig.layout === 'carousel'" class="w-full relative py-2">
                    <div class="relative overflow-hidden w-full">
                      <div 
                        class="flex gap-4 transition-transform duration-500 ease-out"
                        :style="{ transform: `translateX(-${carouselIndex * (previewDevice === 'tablet' ? 100 : 50)}%)` }"
                      >
                        <div 
                          v-for="item in previewVideos" 
                          :key="item.id"
                          class="shrink-0 w-full sm:w-[calc(50%-8px)] border overflow-hidden shadow-md flex flex-col group cursor-pointer transition-all"
                          :class="[
                            widgetConfig.cardRadius,
                            widgetConfig.theme === 'dark' || previewBg === 'dark' 
                              ? 'bg-slate-800/90 border-slate-700/80 text-white' 
                              : 'bg-slate-50/90 border-slate-200 text-slate-900'
                          ]"
                          @click="activePlayingVideo = item"
                        >
                          <div class="relative w-full aspect-[16/9] sm:aspect-[4/3] bg-slate-900 overflow-hidden">
                            <img :src="item.thumbnail" :alt="item.author" class="w-full h-full object-cover group-hover:scale-105 transition-transform" />
                            <div class="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent"></div>
                            <div v-if="widgetConfig.showPlayButton" class="absolute inset-0 flex items-center justify-center">
                              <div class="size-12 rounded-full bg-white text-slate-900 flex items-center justify-center shadow-xl group-hover:scale-110 group-hover:bg-primary group-hover:text-white transition-all">
                                <Play class="size-5 ml-0.5 fill-current" />
                              </div>
                            </div>
                            <div v-if="widgetConfig.showDuration" class="absolute bottom-2 right-2 px-2 py-0.5 rounded bg-black/70 text-white text-[10px] font-mono">
                              {{ item.duration }}
                            </div>
                            <div v-if="widgetConfig.showPlatformBadge" class="absolute top-2 left-2 px-2 py-0.5 rounded-full bg-black/60 backdrop-blur-md text-white text-[10px] font-semibold">
                              {{ item.platform }}
                            </div>
                            <div v-if="widgetConfig.showAiTags && item.aiTag" class="absolute top-2 right-2 px-2 py-0.5 rounded-full bg-primary/90 text-primary-foreground text-[10px] font-semibold flex items-center gap-1 shadow-sm">
                              <Sparkles class="size-2.5" />
                              <span>{{ item.aiTag }}</span>
                            </div>
                          </div>
                          <div 
                            v-if="widgetConfig.showStars || widgetConfig.showTranscript || widgetConfig.showAuthorAvatar"
                            class="p-4 space-y-2 flex-1 flex flex-col justify-between"
                            :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'bg-slate-800/90 text-slate-100' : 'bg-slate-50/90 text-slate-900'"
                          >
                            <div class="space-y-2">
                              <div v-if="widgetConfig.showStars" class="flex items-center gap-0.5 text-amber-400">
                                <Star v-for="s in item.rating" :key="s" class="size-3 fill-amber-400" />
                              </div>
                              <p v-if="widgetConfig.showTranscript" class="text-[12px] font-medium line-clamp-2" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-200' : 'text-slate-700'">
                                "{{ item.quote }}"
                              </p>
                            </div>
                            <div v-if="widgetConfig.showAuthorAvatar" class="flex items-center gap-2 pt-1 border-t" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'border-slate-700' : 'border-slate-200'">
                              <img :src="item.avatar" :alt="item.author" class="size-5 rounded-full object-cover" />
                              <div class="min-w-0">
                                <div class="text-[11.5px] font-semibold truncate flex items-center gap-1" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-white' : 'text-slate-900'">
                                  <span>{{ item.author }}</span>
                                  <CheckCircle2 v-if="widgetConfig.showVerifiedCheck" class="size-3 text-primary shrink-0" />
                                </div>
                                <div v-if="widgetConfig.showCompany" class="text-[10px] truncate" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-400' : 'text-slate-500'">{{ item.company }}</div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <button 
                      @click="prevSlide" 
                      class="absolute -left-3 top-1/2 -translate-y-1/2 size-8 rounded-full border shadow-md flex items-center justify-center z-10 cursor-pointer transition-colors"
                      :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'bg-slate-800 border-slate-700 text-white hover:bg-slate-700' : 'bg-white border-border text-foreground hover:bg-muted'"
                    >
                      <ChevronLeft class="size-4" />
                    </button>
                    <button 
                      @click="nextSlide" 
                      class="absolute -right-3 top-1/2 -translate-y-1/2 size-8 rounded-full border shadow-md flex items-center justify-center z-10 cursor-pointer transition-colors"
                      :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'bg-slate-800 border-slate-700 text-white hover:bg-slate-700' : 'bg-white border-border text-foreground hover:bg-muted'"
                    >
                      <ChevronRight class="size-4" />
                    </button>
                  </div>

                  <!-- 3. Corner Video Bubble (Desktop/Tablet) -->
                  <div v-else-if="widgetConfig.layout === 'bubble'" class="w-full py-8 flex flex-col items-center justify-center min-h-[260px]">
                    <div class="text-center text-xs mb-6 max-w-sm" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-400' : 'text-muted-foreground'">
                      Floating video bubble is docked to the <span class="font-bold" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-200' : 'text-foreground'">{{ widgetConfig.bubblePosition }}</span> of your user's viewport.
                    </div>
                    <div 
                      :class="[
                        'relative p-1.5 rounded-full border-2 shadow-2xl flex items-center gap-3 pr-4 group cursor-pointer hover:scale-105 transition-all',
                        widgetConfig.theme === 'dark' || previewBg === 'dark' 
                          ? 'bg-slate-800 text-white border-primary shadow-[0_15px_40px_rgba(0,0,0,0.8)] ring-1 ring-white/10' 
                          : 'bg-white text-slate-900 border-primary shadow-xl ring-1 ring-black/5'
                      ]"
                      @click="activePlayingVideo = previewVideos[0]"
                    >
                      <div 
                        class="relative size-14 rounded-full overflow-hidden border-2 shadow-md shrink-0"
                        :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'border-slate-700 bg-slate-900' : 'border-white bg-slate-100'"
                      >
                        <img :src="previewVideos[0]?.thumbnail || allVideoTestimonials[0].thumbnail" class="w-full h-full object-cover" />
                        <div class="absolute inset-0 bg-black/30 flex items-center justify-center">
                          <Play class="size-5 text-white fill-white" />
                        </div>
                      </div>
                      <div>
                        <div class="flex items-center gap-1.5">
                          <span class="text-[12px] font-bold" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-white' : 'text-slate-900'">
                            Watch Patient Story
                          </span>
                          <Badge class="h-4 text-[9px] px-1 bg-primary text-primary-foreground font-semibold">Video</Badge>
                        </div>
                        <div class="text-[11px]" :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-400' : 'text-slate-500'">
                          {{ previewVideos[0]?.author || 'Sarah J.' }} · 5★ Experience
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- 4. Stories Strip (Desktop/Tablet) -->
                  <div v-else-if="widgetConfig.layout === 'story_strip'" class="w-full py-4 overflow-x-auto hide-scrollbar flex items-center gap-4 justify-center">
                    <div 
                      v-for="item in previewVideos" 
                      :key="item.id"
                      class="flex flex-col items-center gap-1.5 cursor-pointer group shrink-0"
                      @click="activePlayingVideo = item"
                    >
                      <div class="p-0.5 rounded-full bg-gradient-to-tr from-amber-500 via-rose-500 to-primary group-hover:scale-105 transition-transform shadow-md">
                        <div 
                          class="size-16 rounded-full overflow-hidden border-2 bg-slate-900 relative"
                          :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'border-slate-900' : 'border-white'"
                        >
                          <img :src="item.thumbnail" class="w-full h-full object-cover" />
                          <div class="absolute inset-0 bg-black/20 flex items-center justify-center">
                            <Play class="size-4 text-white fill-white" />
                          </div>
                        </div>
                      </div>
                      <span 
                        class="text-[11px] font-medium max-w-[70px] truncate text-center"
                        :class="widgetConfig.theme === 'dark' || previewBg === 'dark' ? 'text-slate-200' : 'text-slate-800'"
                      >
                        {{ item.author }}
                      </span>
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

    <!-- Active Video Player Popup Modal inside Studio -->
    <div 
      v-if="activePlayingVideo"
      class="fixed inset-0 z-60 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-in fade-in"
      @click.self="activePlayingVideo = null"
    >
      <div class="relative w-full max-w-md bg-slate-950 text-white rounded-2xl overflow-hidden border border-slate-800 shadow-2xl flex flex-col">
        <!-- Top bar -->
        <div class="p-3 bg-black/40 flex items-center justify-between border-b border-slate-800">
          <div class="flex items-center gap-2">
            <img :src="activePlayingVideo.avatar" class="size-6 rounded-full object-cover" />
            <span class="text-xs font-semibold">{{ activePlayingVideo.author }}</span>
          </div>
          <button @click="activePlayingVideo = null" class="size-7 rounded-full bg-slate-800 hover:bg-slate-700 flex items-center justify-center text-white">
            <X class="size-4" />
          </button>
        </div>

        <!-- Video Frame -->
        <div class="relative aspect-[9/16] bg-slate-900 flex items-center justify-center">
          <img :src="activePlayingVideo.thumbnail" class="w-full h-full object-cover opacity-80" />
          <div class="absolute inset-0 bg-gradient-to-t from-black/90 via-transparent to-transparent flex flex-col justify-end p-5 space-y-2">
            <div class="flex items-center gap-0.5 text-amber-400">
              <Star v-for="s in 5" :key="s" class="size-3.5 fill-amber-400" />
            </div>
            <p class="text-xs text-slate-200 leading-relaxed font-medium">"{{ activePlayingVideo.quote }}"</p>
            <div class="text-[10px] text-slate-400">{{ activePlayingVideo.company }} · Verified on {{ activePlayingVideo.platform }}</div>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>
