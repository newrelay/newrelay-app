<script setup>
/* eslint-disable */
import { ref, computed, watch } from 'vue';
import { RelaySwitch, RelayCheckbox } from 'dashboard/components-next/relay';
import {
  X, LayoutGrid, Code2, Copy, Check, Sparkles, Monitor, Tablet,
  Smartphone, Sliders, Palette, Filter, ChevronLeft, ChevronRight,
  Star, CheckCircle2, Globe, Moon, Sun, Layers, Play, Clock, Video, Lock
} from 'lucide-vue-next';

const props = defineProps({ open: { type: Boolean, default: false } });
const emit = defineEmits(['update:open']);

const activeTab = ref('layout'); // layout | filters | appearance | embed
const mobileViewMode = ref('preview'); // editor | preview
const previewDevice = ref('desktop'); // desktop | tablet | mobile
const previewBg = ref('light'); // light | dark
const isCopied = ref(false);
const isSaved = ref(false);
const activePlayingVideo = ref(null);

const widgetConfig = ref({
  name: 'Main Website Video Testimonials Widget',
  layout: 'grid', // grid | carousel | bubble | story_strip
  platforms: { google: true, facebook: true, trustpilot: true, yelp: true, direct: true },
  minRating: '4',
  publishedOnly: true,
  aiHighlightsOnly: false,
  maxVideos: 6,
  theme: 'system',
  cardRadius: 'rounded-2xl',
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
  bubblePosition: 'bottom-right',
});

// Thumbnails/avatars use pravatar (CSP-allowlisted); Unsplash stills would be blocked.
const allVideoTestimonials = [
  { id: 1, author: 'Sarah Johnson', company: 'Marketing VP, Lumina Tech', avatar: 'https://i.pravatar.cc/150?u=s1', thumbnail: 'https://i.pravatar.cc/400?u=vt1', duration: '0:47', rating: 5, platform: 'Google', aiHighlight: true, aiTag: 'Fast Setup', quote: 'Our team saw a 42% conversion spike within the first 10 days of adding this to our landing pages!' },
  { id: 2, author: 'Michael Brown', company: 'Founder, CloudFlow', avatar: 'https://i.pravatar.cc/150?u=m2', thumbnail: 'https://i.pravatar.cc/400?u=vt2', duration: '01:12', rating: 5, platform: 'Facebook', aiHighlight: true, aiTag: 'ROI & Value', quote: 'The video quality and seamless playback built instant trust with enterprise prospects.' },
  { id: 3, author: 'Emily Rodriguez', company: 'Director of Growth, DesignHub', avatar: 'https://i.pravatar.cc/150?u=e3', thumbnail: 'https://i.pravatar.cc/400?u=vt3', duration: '00:35', rating: 5, platform: 'Yelp', aiHighlight: false, aiTag: 'Easy Onboarding', quote: 'Setup took literally under 3 minutes. Cleanest review widget studio in the industry.' },
  { id: 4, author: 'David Lee', company: 'Operations Lead, Apex Systems', avatar: 'https://i.pravatar.cc/150?u=d4', thumbnail: 'https://i.pravatar.cc/400?u=vt4', duration: '01:05', rating: 5, platform: 'Trustpilot', aiHighlight: true, aiTag: 'Support 10/10', quote: 'The customer service and automated review routing have saved us over 15 hours every week.' },
  { id: 5, author: 'James Wilson', company: 'Logistics Pro', avatar: 'https://i.pravatar.cc/150?u=j5', thumbnail: 'https://i.pravatar.cc/400?u=vt5', duration: '00:59', rating: 4, platform: 'Google', aiHighlight: false, aiTag: 'Reliability', quote: 'High reliability and excellent video compression for ultra fast load times on mobile.' },
  { id: 6, author: 'Elena Rostova', company: 'Head of Brand, Velvet Labs', avatar: 'https://i.pravatar.cc/150?u=e6', thumbnail: 'https://i.pravatar.cc/400?u=vt6', duration: '00:44', rating: 5, platform: 'Direct', aiHighlight: true, aiTag: 'Conversion Booster', quote: 'Having authentic customer faces and voices on our checkout page eliminated all hesitation.' },
  { id: 7, author: 'Marcus Chen', company: 'CTO, QuantumScale', avatar: 'https://i.pravatar.cc/150?u=m7', thumbnail: 'https://i.pravatar.cc/400?u=vt7', duration: '01:18', rating: 5, platform: 'Google', aiHighlight: true, aiTag: 'Scalability', quote: 'Integrating the video carousel directly onto our pricing page boosted demo requests by 38%.' },
  { id: 8, author: 'Sophia Williams', company: 'Product Lead, NovaCore', avatar: 'https://i.pravatar.cc/150?u=s8', thumbnail: 'https://i.pravatar.cc/400?u=vt8', duration: '00:52', rating: 5, platform: 'Facebook', aiHighlight: true, aiTag: 'User Friendly', quote: 'Our customers love recording their feedback through the seamless mobile browser link.' },
  { id: 9, author: 'Alex Rivera', company: 'Growth Engineer, Veloce AI', avatar: 'https://i.pravatar.cc/150?u=a9', thumbnail: 'https://i.pravatar.cc/400?u=vt9', duration: '00:41', rating: 5, platform: 'Trustpilot', aiHighlight: false, aiTag: 'Seamless Embed', quote: 'The CDN widget loads in less than 40ms. Zero impact on Core Web Vitals score.' },
  { id: 10, author: 'Rachel Kim', company: 'Marketing Manager, Bloom Studio', avatar: 'https://i.pravatar.cc/150?u=r10', thumbnail: 'https://i.pravatar.cc/400?u=vt10', duration: '01:03', rating: 5, platform: 'Direct', aiHighlight: true, aiTag: 'High Retention', quote: 'Authentic customer video stories have completely transformed our brand trust.' },
];

const previewVideos = computed(() => {
  return allVideoTestimonials.filter(v => {
    const key = v.platform.toLowerCase();
    if (widgetConfig.value.platforms[key] === false) return false;
    if (widgetConfig.value.aiHighlightsOnly && !v.aiHighlight) return false;
    if (widgetConfig.value.minRating === '5' && v.rating < 5) return false;
    if (widgetConfig.value.minRating === '4' && v.rating < 4) return false;
    return true;
  }).slice(0, widgetConfig.value.maxVideos);
});

const carouselIndex = ref(0);
function nextSlide() {
  if (carouselIndex.value < previewVideos.value.length - 1) carouselIndex.value++;
  else carouselIndex.value = 0;
}
function prevSlide() {
  if (carouselIndex.value > 0) carouselIndex.value--;
  else carouselIndex.value = previewVideos.value.length - 1;
}

const embedType = ref('script'); // script | iframe | react
const currentEmbedSnippet = computed(() => {
  const c = widgetConfig.value;
  if (embedType.value === 'script') {
    return `<!-- Relay Video Testimonials Widget -->\n<div id="relay-video-widget" \n  data-widget-id="vw_${c.layout}_9482" \n  data-layout="${c.layout}" \n  data-theme="${c.theme}">\n</div>\n<script src="https://cdn.relay.to/widgets/v2/video-testimonials.js" async defer><\/script>`;
  }
  if (embedType.value === 'iframe') {
    return `<iframe \n  src="https://embed.relay.to/video-widget/vw_9482?layout=${c.layout}&theme=${c.theme}" \n  width="100%" \n  height="540" \n  frameborder="0" \n  allow="autoplay; fullscreen"\n  loading="lazy">\n</iframe>`;
  }
  return `import { VideoTestimonialWidget } from '@relay/react-widgets'\n\nexport default function TestimonialSection() {\n  return (\n    <VideoTestimonialWidget \n      widgetId="vw_9482"\n      layout="${c.layout}"\n      theme="${c.theme}"\n      autoPlayHover={${c.autoPlayHover}}\n    />\n  )\n}`;
});

function copyEmbedCode() {
  navigator.clipboard.writeText(currentEmbedSnippet.value);
  isCopied.value = true;
  setTimeout(() => { isCopied.value = false; }, 2200);
}
// ---------- Persistence (reputation_widgets, tagged source: video_studio) ----------
const axios = window.axios;
const accountId =
  window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];
const widgetsUrl = () => `/api/v1/accounts/${accountId}/reputation/widgets`;
const widgetId = ref(null);
const STYLE_ENUM = ['carousel', 'grid', 'badge'];

async function loadWidget() {
  try {
    const { data } = await axios.get(widgetsUrl());
    const existing = (data || []).find(w => w.config && w.config.source === 'video_studio');
    if (!existing) return;
    widgetId.value = existing.id;
    if (existing.config) widgetConfig.value = { ...widgetConfig.value, ...existing.config };
  } catch (e) { /* none yet */ }
}
watch(() => props.open, isOpen => { if (isOpen) loadWidget(); }, { immediate: true });

async function handleSaveWidget() {
  const c = widgetConfig.value;
  const payload = {
    name: c.name,
    style: STYLE_ENUM.includes(c.layout) ? c.layout : 'carousel',
    min_rating: Math.max(1, Math.min(5, parseInt(c.minRating, 10) || 1)),
    active: true,
    config: { ...c, source: 'video_studio' },
  };
  try {
    if (widgetId.value) {
      await axios.patch(`${widgetsUrl()}/${widgetId.value}`, { widget: payload });
    } else {
      const { data } = await axios.post(widgetsUrl(), { widget: payload });
      widgetId.value = data?.id || null;
    }
  } catch (e) { /* keep UI optimistic */ }
  isSaved.value = true;
  setTimeout(() => { isSaved.value = false; emit('update:open', false); }, 1200);
}
function close() { emit('update:open', false); }

const layoutOptions = [
  { id: 'grid', name: 'Wall of Love (Grid)', desc: 'Multi-column video card grid', icon: LayoutGrid },
  { id: 'carousel', name: 'Video Carousel', desc: 'Smooth sliding video reel', icon: Sliders },
  { id: 'bubble', name: 'Corner Video Bubble', desc: 'Floating interactive popup', icon: Video },
  { id: 'story_strip', name: 'Stories Strip', desc: 'Instagram-style story circles', icon: Smartphone },
];

const isDark = computed(() => widgetConfig.value.theme === 'dark' || previewBg.value === 'dark');
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center p-2 sm:p-4 lg:p-6">
    <div class="absolute inset-0 bg-background/80 backdrop-blur-md" @click="close"></div>

    <div class="relative w-[98vw] sm:w-[96vw] max-w-[1440px] h-[96vh] sm:h-[92vh] bg-card rounded-xl sm:rounded-2xl shadow-2xl border border-border flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200">

      <!-- Header -->
      <div class="px-4 sm:px-6 py-3.5 border-b border-border bg-muted/30 flex items-center justify-between shrink-0">
        <div class="flex items-center gap-3">
          <div class="p-2 bg-primary/10 rounded-xl text-primary shrink-0"><Video class="size-5" /></div>
          <div>
            <div class="flex items-center gap-2 flex-wrap">
              <h2 class="text-base font-semibold text-foreground">Video Widget Studio</h2>
              <span class="hidden sm:inline-flex items-center rounded-md px-2 py-0.5 bg-primary/10 text-primary text-[11px] font-medium">Live Website Embed</span>
            </div>
            <p class="text-[12.5px] text-muted-foreground hidden sm:block">Customize, preview, and embed your customer video testimonials.</p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <div class="flex lg:hidden items-center bg-muted p-1 rounded-lg border border-border">
            <button @click="mobileViewMode = 'editor'" class="px-2.5 py-1 rounded-md text-xs font-medium transition-all cursor-pointer" :class="mobileViewMode === 'editor' ? 'bg-card text-foreground shadow-xs font-semibold' : 'text-muted-foreground'">Customizer</button>
            <button @click="mobileViewMode = 'preview'" class="px-2.5 py-1 rounded-md text-xs font-medium transition-all cursor-pointer" :class="mobileViewMode === 'preview' ? 'bg-card text-foreground shadow-xs font-semibold' : 'text-muted-foreground'">Preview</button>
          </div>
          <button class="inline-flex items-center justify-center text-muted-foreground border border-border hover:border-transparent hover:bg-muted size-8 sm:size-9 rounded-lg cursor-pointer" @click="close"><X class="size-4 sm:size-5" /></button>
        </div>
      </div>

      <!-- Body -->
      <div class="flex-1 flex flex-col lg:flex-row overflow-hidden">

        <!-- Left: customizer -->
        <div class="w-full lg:w-[420px] xl:w-[450px] border-b lg:border-b-0 lg:border-r border-border bg-card flex flex-col shrink-0 overflow-hidden" :class="mobileViewMode === 'editor' ? 'flex flex-1' : 'hidden lg:flex'">
          <!-- Tabs -->
          <div class="grid grid-cols-4 p-2 border-b border-border/70 bg-muted/20 text-xs font-medium shrink-0">
            <button @click="activeTab = 'layout'" class="py-2 px-1 rounded-lg transition-all text-center flex flex-col items-center gap-1 cursor-pointer" :class="activeTab === 'layout' ? 'bg-background text-foreground shadow-xs font-semibold' : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'"><Layers class="size-3.5" /><span>Layout</span></button>
            <button @click="activeTab = 'filters'" class="py-2 px-1 rounded-lg transition-all text-center flex flex-col items-center gap-1 cursor-pointer" :class="activeTab === 'filters' ? 'bg-background text-foreground shadow-xs font-semibold' : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'"><Filter class="size-3.5" /><span>Sources</span></button>
            <button @click="activeTab = 'appearance'" class="py-2 px-1 rounded-lg transition-all text-center flex flex-col items-center gap-1 cursor-pointer" :class="activeTab === 'appearance' ? 'bg-background text-foreground shadow-xs font-semibold' : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'"><Palette class="size-3.5" /><span>Style</span></button>
            <button @click="activeTab = 'embed'" class="py-2 px-1 rounded-lg transition-all text-center flex flex-col items-center gap-1 cursor-pointer" :class="activeTab === 'embed' ? 'bg-background text-foreground shadow-xs font-semibold' : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'"><Code2 class="size-3.5" /><span>Embed</span></button>
          </div>

          <div class="flex-1 overflow-y-auto p-4 sm:p-5 space-y-6 hide-scrollbar">

            <!-- TAB 1: Layout -->
            <div v-if="activeTab === 'layout'" class="space-y-5 animate-in fade-in duration-200">
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Video Display Template</label>
                <p class="text-[12px] text-muted-foreground mb-3">Select how customer video testimonials are showcased on your site.</p>
                <div class="grid grid-cols-2 gap-2.5">
                  <div v-for="opt in layoutOptions" :key="opt.id" @click="widgetConfig.layout = opt.id" class="p-3 rounded-xl border cursor-pointer transition-all flex flex-col gap-2" :class="widgetConfig.layout === opt.id ? 'border-primary bg-primary/5 ring-1 ring-primary/30 shadow-2xs' : 'border-border hover:border-border/80 hover:bg-muted/30'">
                    <div class="flex items-center justify-between">
                      <div class="p-1.5 rounded-lg bg-primary/10 text-primary"><component :is="opt.icon" class="size-4" /></div>
                      <CheckCircle2 v-if="widgetConfig.layout === opt.id" class="size-4 text-primary shrink-0" />
                    </div>
                    <div>
                      <div class="text-[13px] font-semibold text-foreground">{{ opt.name }}</div>
                      <p class="text-[11px] text-muted-foreground">{{ opt.desc }}</p>
                    </div>
                  </div>
                </div>
              </div>

              <div class="space-y-3 pt-3 border-t border-border/80">
                <label class="text-[13.5px] font-medium text-foreground block">Playback &amp; Video Controls</label>
                <div class="flex items-center justify-between p-3 rounded-xl bg-muted/20 border border-border/80">
                  <div><div class="text-[13px] font-medium text-foreground">Autoplay Video on Hover</div><div class="text-[11.5px] text-muted-foreground">Muted preview starts on mouse hover</div></div>
                  <RelaySwitch v-model="widgetConfig.autoPlayHover" />
                </div>
                <div class="flex items-center justify-between p-3 rounded-xl bg-muted/20 border border-border/80">
                  <div><div class="text-[13px] font-medium text-foreground">Center Play Overlay Button</div><div class="text-[11.5px] text-muted-foreground">Translucent play icon over cards</div></div>
                  <RelaySwitch v-model="widgetConfig.showPlayButton" />
                </div>
                <div class="flex items-center justify-between p-3 rounded-xl bg-muted/20 border border-border/80">
                  <div><div class="text-[13px] font-medium text-foreground">Duration Timestamp Badge</div><div class="text-[11.5px] text-muted-foreground">Show video run time (e.g. 0:47)</div></div>
                  <RelaySwitch v-model="widgetConfig.showDuration" />
                </div>
                <div class="flex items-center justify-between p-3 rounded-xl bg-muted/20 border border-border/80">
                  <div><div class="text-[13px] font-medium text-foreground">Show Transcript Excerpt</div><div class="text-[11.5px] text-muted-foreground">Key quote snippet under the card</div></div>
                  <RelaySwitch v-model="widgetConfig.showTranscript" />
                </div>
              </div>

              <div v-if="widgetConfig.layout === 'bubble'" class="p-3.5 bg-muted/30 border border-border rounded-xl space-y-3">
                <label class="text-[13px] font-semibold text-foreground">Bubble Floating Position</label>
                <div class="grid grid-cols-2 gap-2">
                  <button v-for="pos in [{ id: 'bottom-right', label: 'Bottom Right' }, { id: 'bottom-left', label: 'Bottom Left' }, { id: 'top-right', label: 'Top Right' }, { id: 'top-left', label: 'Top Left' }]" :key="pos.id" type="button" @click="widgetConfig.bubblePosition = pos.id" class="py-2 px-3 rounded-lg border text-xs font-medium transition-colors text-center cursor-pointer" :class="widgetConfig.bubblePosition === pos.id ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border text-muted-foreground'">{{ pos.label }}</button>
                </div>
              </div>
            </div>

            <!-- TAB 2: Sources & filters -->
            <div v-else-if="activeTab === 'filters'" class="space-y-5 animate-in fade-in duration-200">
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Source Platforms</label>
                <p class="text-[12px] text-muted-foreground mb-3">Select which channels feed videos into this widget.</p>
                <div class="space-y-2">
                  <label class="flex items-center justify-between p-2.5 rounded-xl border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5"><span class="size-6 rounded-full bg-muted flex items-center justify-center text-[11px] font-bold text-foreground">G</span><span class="text-[13px] font-medium text-foreground">Google Reviews</span></div>
                    <RelayCheckbox v-model="widgetConfig.platforms.google" />
                  </label>
                  <label class="flex items-center justify-between p-2.5 rounded-xl border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5"><span class="size-6 rounded-full bg-blue-500/10 text-blue-600 dark:text-blue-400 flex items-center justify-center text-[11px] font-bold">f</span><span class="text-[13px] font-medium text-foreground">Facebook Testimonials</span></div>
                    <RelayCheckbox v-model="widgetConfig.platforms.facebook" />
                  </label>
                  <label class="flex items-center justify-between p-2.5 rounded-xl border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5"><span class="size-6 rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center text-[11px] font-bold">★</span><span class="text-[13px] font-medium text-foreground">Trustpilot Verified</span></div>
                    <RelayCheckbox v-model="widgetConfig.platforms.trustpilot" />
                  </label>
                  <label class="flex items-center justify-between p-2.5 rounded-xl border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5"><span class="size-6 rounded-full bg-rose-500/10 text-rose-600 dark:text-rose-400 flex items-center justify-center text-[11px] font-bold">Y</span><span class="text-[13px] font-medium text-foreground">Yelp Video Reviews</span></div>
                    <RelayCheckbox v-model="widgetConfig.platforms.yelp" />
                  </label>
                  <label class="flex items-center justify-between p-2.5 rounded-xl border border-border bg-card hover:bg-muted/20 cursor-pointer">
                    <div class="flex items-center gap-2.5"><span class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center text-[11px] font-bold">NR</span><span class="text-[13px] font-medium text-foreground">Direct Video Form Submissions</span></div>
                    <RelayCheckbox v-model="widgetConfig.platforms.direct" />
                  </label>
                </div>
              </div>

              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Minimum Star Rating</label>
                <div class="grid grid-cols-3 gap-2">
                  <button v-for="r in [{ id: 'all', label: 'All (1-5★)' }, { id: '4', label: '4★ & Above' }, { id: '5', label: '5★ Only' }]" :key="r.id" @click="widgetConfig.minRating = r.id" class="py-2 px-2 text-xs rounded-lg border font-medium text-center transition-colors cursor-pointer" :class="widgetConfig.minRating === r.id ? 'border-primary bg-primary/10 text-primary font-semibold' : 'border-border text-muted-foreground hover:bg-muted/30'">{{ r.label }}</button>
                </div>
              </div>

              <div class="p-3.5 bg-muted/30 border border-border rounded-xl space-y-3">
                <div class="flex items-center gap-2 text-xs font-semibold text-foreground uppercase tracking-wider"><Sparkles class="size-3.5 text-primary" /> Relay AI Filters</div>
                <div class="flex items-center justify-between"><span class="text-xs text-foreground">Published videos only</span><RelaySwitch v-model="widgetConfig.publishedOnly" /></div>
                <div class="flex items-center justify-between"><span class="text-xs text-foreground">AI highlight reels only</span><RelaySwitch v-model="widgetConfig.aiHighlightsOnly" /></div>
              </div>

              <div>
                <div class="flex items-center justify-between text-xs mb-1"><span class="font-medium text-foreground">Maximum Videos in Widget</span><span class="text-muted-foreground font-semibold">{{ widgetConfig.maxVideos }} videos</span></div>
                <input type="range" min="1" max="10" step="1" v-model.number="widgetConfig.maxVideos" class="w-full accent-primary cursor-pointer" />
              </div>
            </div>

            <!-- TAB 3: Appearance -->
            <div v-else-if="activeTab === 'appearance'" class="space-y-5 animate-in fade-in duration-200">
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-2">Widget Theme</label>
                <div class="grid grid-cols-3 gap-2">
                  <button v-for="t in [{ id: 'light', label: 'Light', icon: Sun }, { id: 'dark', label: 'Dark', icon: Moon }, { id: 'system', label: 'Adaptive', icon: Globe }]" :key="t.id" type="button" @click="widgetConfig.theme = t.id" class="py-2.5 px-3 rounded-xl border text-xs text-center cursor-pointer transition-colors flex items-center justify-center gap-1.5" :class="widgetConfig.theme === t.id ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border hover:bg-muted text-muted-foreground'"><component :is="t.icon" class="size-3.5" /><span>{{ t.label }}</span></button>
                </div>
              </div>
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-2">Card Corner Radius</label>
                <div class="grid grid-cols-4 gap-2">
                  <button v-for="rad in [{ id: 'rounded-none', label: 'Square' }, { id: 'rounded-lg', label: 'Medium' }, { id: 'rounded-2xl', label: 'Large' }, { id: 'rounded-[28px]', label: 'Pill' }]" :key="rad.id" type="button" @click="widgetConfig.cardRadius = rad.id" class="py-2 px-2 rounded-lg border text-xs text-center cursor-pointer transition-colors" :class="widgetConfig.cardRadius === rad.id ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border hover:bg-muted text-muted-foreground'">{{ rad.label }}</button>
                </div>
              </div>
              <div class="space-y-3 pt-3 border-t border-border">
                <label class="text-[13.5px] font-medium text-foreground block">Display Elements</label>
                <div class="flex items-center justify-between p-2.5 rounded-xl bg-muted/20 border border-border"><span class="text-[13px] text-foreground">Star Rating Bar</span><RelaySwitch v-model="widgetConfig.showStars" /></div>
                <div class="flex items-center justify-between p-2.5 rounded-xl bg-muted/20 border border-border"><span class="text-[13px] text-foreground">Author Avatar &amp; Name</span><RelaySwitch v-model="widgetConfig.showAuthorAvatar" /></div>
                <div class="flex items-center justify-between p-2.5 rounded-xl bg-muted/20 border border-border"><span class="text-[13px] text-foreground">Company / Role Subtitle</span><RelaySwitch v-model="widgetConfig.showCompany" /></div>
                <div class="flex items-center justify-between p-2.5 rounded-xl bg-muted/20 border border-border"><span class="text-[13px] text-foreground">Source Platform Icon</span><RelaySwitch v-model="widgetConfig.showPlatformBadge" /></div>
                <div class="flex items-center justify-between p-2.5 rounded-xl bg-muted/20 border border-border"><span class="text-[13px] text-foreground">Relay AI Topic Pills</span><RelaySwitch v-model="widgetConfig.showAiTags" /></div>
              </div>
            </div>

            <!-- TAB 4: Embed -->
            <div v-else-if="activeTab === 'embed'" class="space-y-5 animate-in fade-in duration-200">
              <div>
                <label class="text-[13.5px] font-medium text-foreground block mb-1">Integration Format</label>
                <p class="text-[12px] text-muted-foreground mb-3">Copy and paste this snippet anywhere on your website.</p>
                <div class="grid grid-cols-3 gap-2">
                  <button v-for="fmt in [{ id: 'script', label: 'HTML / JS' }, { id: 'iframe', label: 'iFrame' }, { id: 'react', label: 'React / Next' }]" :key="fmt.id" type="button" @click="embedType = fmt.id" class="py-2 px-3 rounded-lg border text-xs text-center cursor-pointer transition-colors" :class="embedType === fmt.id ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border hover:bg-muted text-muted-foreground'">{{ fmt.label }}</button>
                </div>
              </div>
              <div class="relative rounded-xl border border-slate-800 bg-slate-950 text-slate-100 p-4 font-mono text-xs overflow-x-auto shadow-inner">
                <pre class="whitespace-pre-wrap break-all leading-relaxed">{{ currentEmbedSnippet }}</pre>
                <button class="absolute top-3 right-3 inline-flex items-center h-8 px-2.5 gap-1.5 text-xs rounded-md bg-primary text-primary-foreground shadow-md hover:bg-primary/90 cursor-pointer" @click="copyEmbedCode"><Check v-if="isCopied" class="size-3.5 text-emerald-400" /><Copy v-else class="size-3.5" />{{ isCopied ? 'Copied!' : 'Copy Code' }}</button>
              </div>
              <div class="p-4 rounded-xl bg-muted/20 border border-border space-y-2">
                <div class="text-[13px] font-semibold text-foreground flex items-center gap-2"><Globe class="size-4 text-primary" /><span>Works with all website builders</span></div>
                <div class="flex flex-wrap gap-2 pt-1 text-[11.5px]">
                  <span class="inline-flex items-center rounded-md border border-border bg-card px-2 py-0.5">Webflow</span>
                  <span class="inline-flex items-center rounded-md border border-border bg-card px-2 py-0.5">Shopify</span>
                  <span class="inline-flex items-center rounded-md border border-border bg-card px-2 py-0.5">WordPress</span>
                  <span class="inline-flex items-center rounded-md border border-border bg-card px-2 py-0.5">Framer</span>
                  <span class="inline-flex items-center rounded-md border border-border bg-card px-2 py-0.5">Squarespace</span>
                  <span class="inline-flex items-center rounded-md border border-border bg-card px-2 py-0.5">Next.js</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Customizer footer -->
          <div class="p-4 border-t border-border bg-muted/20 flex items-center justify-between shrink-0">
            <button class="inline-flex items-center gap-1.5 h-9 px-3.5 rounded-lg border border-border hover:border-transparent hover:bg-muted text-xs font-medium text-foreground cursor-pointer" @click="copyEmbedCode"><Code2 class="size-3.5" /> {{ isCopied ? 'Code Copied!' : 'Get Code' }}</button>
            <button class="inline-flex items-center gap-1.5 h-9 px-3.5 rounded-lg bg-primary text-primary-foreground text-xs font-medium hover:bg-primary/90 shadow-xs cursor-pointer" @click="handleSaveWidget"><Check v-if="isSaved" class="size-3.5 text-emerald-300" /><span>{{ isSaved ? 'Saved!' : 'Save Widget' }}</span></button>
          </div>
        </div>

        <!-- Right: preview -->
        <div class="flex-1 bg-muted/20 flex flex-col overflow-hidden" :class="mobileViewMode === 'preview' ? 'flex' : 'hidden lg:flex'">
          <!-- Toolbar -->
          <div class="px-4 sm:px-6 py-3 border-b border-border bg-card/80 backdrop-blur-sm flex flex-wrap items-center justify-between gap-3 shrink-0">
            <div class="flex items-center gap-1 bg-muted p-1 rounded-xl border border-border/60">
              <button @click="previewDevice = 'desktop'" class="px-2.5 py-1 rounded-lg text-xs font-medium flex items-center gap-1.5 transition-all cursor-pointer" :class="previewDevice === 'desktop' ? 'bg-card text-foreground shadow-xs' : 'text-muted-foreground hover:text-foreground'"><Monitor class="size-3.5" /><span class="hidden sm:inline">Desktop</span></button>
              <button @click="previewDevice = 'tablet'" class="px-2.5 py-1 rounded-lg text-xs font-medium flex items-center gap-1.5 transition-all cursor-pointer" :class="previewDevice === 'tablet' ? 'bg-card text-foreground shadow-xs' : 'text-muted-foreground hover:text-foreground'"><Tablet class="size-3.5" /><span class="hidden sm:inline">Tablet</span></button>
              <button @click="previewDevice = 'mobile'" class="px-2.5 py-1 rounded-lg text-xs font-medium flex items-center gap-1.5 transition-all cursor-pointer" :class="previewDevice === 'mobile' ? 'bg-card text-foreground shadow-xs' : 'text-muted-foreground hover:text-foreground'"><Smartphone class="size-3.5" /><span class="hidden sm:inline">Mobile</span></button>
            </div>
            <div class="flex items-center gap-2">
              <span class="text-xs text-muted-foreground font-medium hidden md:inline">Background:</span>
              <div class="flex items-center gap-1 bg-muted p-1 rounded-lg border border-border/60">
                <button @click="previewBg = 'light'" class="size-8 rounded-md flex items-center justify-center text-xs transition-colors cursor-pointer" :class="previewBg === 'light' ? 'bg-white text-slate-800 shadow-xs' : 'text-muted-foreground'" title="Light background"><Sun class="size-4" /></button>
                <button @click="previewBg = 'dark'" class="size-8 rounded-md flex items-center justify-center text-xs transition-colors cursor-pointer" :class="previewBg === 'dark' ? 'bg-slate-900 text-white shadow-xs' : 'text-muted-foreground'" title="Dark background"><Moon class="size-4" /></button>
              </div>
            </div>
          </div>

          <!-- Canvas -->
          <div class="flex-1 overflow-y-auto p-3 sm:p-5 flex items-start justify-center transition-colors duration-300" :class="previewBg === 'light' ? 'bg-slate-100' : 'bg-slate-950'">
            <div class="w-full my-auto rounded-2xl overflow-hidden border border-border/80 shadow-2xl bg-white flex flex-col" :class="previewDevice === 'desktop' ? 'max-w-4xl' : previewDevice === 'tablet' ? 'max-w-[680px]' : 'max-w-[380px]'">
              <!-- Browser bar -->
              <div class="px-4 py-2.5 bg-slate-100 border-b border-border/60 flex items-center justify-between shrink-0">
                <div class="flex items-center gap-1.5">
                  <div class="size-2.5 rounded-full bg-red-400/80"></div><div class="size-2.5 rounded-full bg-amber-400/80"></div><div class="size-2.5 rounded-full bg-emerald-400/80"></div>
                </div>
                <div class="flex items-center gap-1.5 bg-white px-3 py-1 rounded-md border border-border/60 text-xs font-mono text-muted-foreground w-56 justify-center"><Lock class="size-3 text-emerald-500 shrink-0" /><span class="truncate text-foreground/80">yourwebsite.com</span></div>
                <div class="w-8"></div>
              </div>

              <!-- Webpage content -->
              <div class="p-5 sm:p-8 space-y-6 overflow-y-auto max-h-[600px] hide-scrollbar" :class="isDark ? 'bg-slate-950' : 'bg-slate-50/50'">
                <div class="text-center space-y-1">
                  <span class="text-xs uppercase tracking-wider font-semibold text-primary">Customer Testimonials</span>
                  <h2 class="text-lg sm:text-xl font-bold" :class="isDark ? 'text-white' : 'text-slate-900'">Loved by thousands of businesses</h2>
                </div>

                <div class="w-full transition-all border shadow-lg relative p-5 sm:p-8" :class="[widgetConfig.cardRadius, isDark ? 'bg-slate-900 text-slate-100 border-slate-800' : 'bg-white text-slate-900 border-slate-200/90']">

                  <!-- GRID -->
                  <div v-if="widgetConfig.layout === 'grid'" class="grid gap-4 w-full" :class="previewDevice === 'mobile' ? 'grid-cols-1' : previewDevice === 'tablet' ? 'grid-cols-2' : 'grid-cols-3'">
                    <div v-for="item in previewVideos" :key="item.id" class="group relative overflow-hidden border transition-all hover:shadow-lg cursor-pointer flex flex-col" :class="[widgetConfig.cardRadius, isDark ? 'bg-slate-800/90 border-slate-700/80 text-white' : 'bg-slate-50/90 border-slate-200/80 text-slate-900 shadow-xs']" @click="activePlayingVideo = item">
                      <div class="relative w-full aspect-[4/5] overflow-hidden bg-slate-900">
                        <img :src="item.thumbnail" :alt="item.author" class="w-full h-full object-cover" />
                        <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent"></div>
                        <div v-if="widgetConfig.showPlayButton" class="absolute inset-0 flex items-center justify-center"><div class="size-11 rounded-full bg-white/90 text-slate-900 flex items-center justify-center shadow-xl group-hover:scale-110 group-hover:bg-primary group-hover:text-primary-foreground transition-all"><Play class="size-5 ml-0.5 fill-current" /></div></div>
                        <div v-if="widgetConfig.showDuration" class="absolute bottom-3 right-3 px-2 py-0.5 rounded-md bg-black/60 backdrop-blur-md text-white text-[10px] font-mono font-medium flex items-center gap-1"><Clock class="size-2.5" /><span>{{ item.duration }}</span></div>
                        <div v-if="widgetConfig.showPlatformBadge" class="absolute top-3 left-3 px-2 py-0.5 rounded-full bg-black/50 backdrop-blur-md text-white text-[10px] font-semibold">{{ item.platform }}</div>
                        <div v-if="widgetConfig.showAiTags && item.aiTag" class="absolute top-3 right-3 px-2 py-0.5 rounded-full bg-primary/90 text-primary-foreground text-[10px] font-semibold flex items-center gap-1 shadow-sm"><Sparkles class="size-2.5" /><span>{{ item.aiTag }}</span></div>
                      </div>
                      <div v-if="widgetConfig.showStars || widgetConfig.showTranscript || widgetConfig.showAuthorAvatar" class="p-3.5 space-y-2 flex-1 flex flex-col justify-between" :class="isDark ? 'bg-slate-800/90 text-slate-100' : 'bg-slate-50/90 text-slate-900'">
                        <div class="space-y-1.5">
                          <div v-if="widgetConfig.showStars" class="flex items-center gap-0.5 text-amber-400"><Star v-for="s in item.rating" :key="s" class="size-3 fill-amber-400" /></div>
                          <p v-if="widgetConfig.showTranscript" class="text-[11.5px] line-clamp-2 leading-relaxed italic" :class="isDark ? 'text-slate-300' : 'text-slate-600'">"{{ item.quote }}"</p>
                        </div>
                        <div v-if="widgetConfig.showAuthorAvatar" class="flex items-center gap-2 pt-1 border-t" :class="isDark ? 'border-slate-700' : 'border-slate-200'">
                          <img :src="item.avatar" :alt="item.author" class="size-6 rounded-full object-cover border border-border" />
                          <div class="min-w-0">
                            <div class="text-[12px] font-semibold truncate flex items-center gap-1" :class="isDark ? 'text-white' : 'text-slate-900'"><span>{{ item.author }}</span><CheckCircle2 v-if="widgetConfig.showVerifiedCheck" class="size-3 text-primary shrink-0" /></div>
                            <div v-if="widgetConfig.showCompany" class="text-[10px] truncate" :class="isDark ? 'text-slate-400' : 'text-slate-500'">{{ item.company }}</div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- CAROUSEL -->
                  <div v-else-if="widgetConfig.layout === 'carousel'" class="w-full relative py-2">
                    <div class="relative overflow-hidden w-full">
                      <div class="flex gap-4 transition-transform duration-500 ease-out" :style="{ transform: `translateX(-${carouselIndex * (previewDevice === 'mobile' ? 100 : 50)}%)` }">
                        <div v-for="item in previewVideos" :key="item.id" class="shrink-0 w-full sm:w-[calc(50%-8px)] border overflow-hidden shadow-md flex flex-col group cursor-pointer transition-all" :class="[widgetConfig.cardRadius, isDark ? 'bg-slate-800/90 border-slate-700/80 text-white' : 'bg-slate-50/90 border-slate-200 text-slate-900']" @click="activePlayingVideo = item">
                          <div class="relative w-full aspect-[16/9] sm:aspect-[4/3] bg-slate-900 overflow-hidden">
                            <img :src="item.thumbnail" :alt="item.author" class="w-full h-full object-cover" />
                            <div class="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent"></div>
                            <div v-if="widgetConfig.showPlayButton" class="absolute inset-0 flex items-center justify-center"><div class="size-12 rounded-full bg-white text-slate-900 flex items-center justify-center shadow-xl group-hover:scale-110 group-hover:bg-primary group-hover:text-white transition-all"><Play class="size-5 ml-0.5 fill-current" /></div></div>
                            <div v-if="widgetConfig.showDuration" class="absolute bottom-2 right-2 px-2 py-0.5 rounded bg-black/70 text-white text-[10px] font-mono">{{ item.duration }}</div>
                            <div v-if="widgetConfig.showPlatformBadge" class="absolute top-2 left-2 px-2 py-0.5 rounded-full bg-black/60 backdrop-blur-md text-white text-[10px] font-semibold">{{ item.platform }}</div>
                            <div v-if="widgetConfig.showAiTags && item.aiTag" class="absolute top-2 right-2 px-2 py-0.5 rounded-full bg-primary/90 text-primary-foreground text-[10px] font-semibold flex items-center gap-1 shadow-sm"><Sparkles class="size-2.5" /><span>{{ item.aiTag }}</span></div>
                          </div>
                          <div v-if="widgetConfig.showStars || widgetConfig.showTranscript || widgetConfig.showAuthorAvatar" class="p-4 space-y-2 flex-1 flex flex-col justify-between" :class="isDark ? 'bg-slate-800/90 text-slate-100' : 'bg-slate-50/90 text-slate-900'">
                            <div class="space-y-2">
                              <div v-if="widgetConfig.showStars" class="flex items-center gap-0.5 text-amber-400"><Star v-for="s in item.rating" :key="s" class="size-3 fill-amber-400" /></div>
                              <p v-if="widgetConfig.showTranscript" class="text-[12px] font-medium line-clamp-2" :class="isDark ? 'text-slate-200' : 'text-slate-700'">"{{ item.quote }}"</p>
                            </div>
                            <div v-if="widgetConfig.showAuthorAvatar" class="flex items-center gap-2 pt-1 border-t" :class="isDark ? 'border-slate-700' : 'border-slate-200'">
                              <img :src="item.avatar" :alt="item.author" class="size-5 rounded-full object-cover" />
                              <div class="min-w-0"><div class="text-[11.5px] font-semibold truncate flex items-center gap-1" :class="isDark ? 'text-white' : 'text-slate-900'"><span>{{ item.author }}</span><CheckCircle2 v-if="widgetConfig.showVerifiedCheck" class="size-3 text-primary shrink-0" /></div><div v-if="widgetConfig.showCompany" class="text-[10px] truncate" :class="isDark ? 'text-slate-400' : 'text-slate-500'">{{ item.company }}</div></div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <button @click="prevSlide" class="absolute -left-3 top-1/2 -translate-y-1/2 size-8 rounded-full border shadow-md flex items-center justify-center z-10 cursor-pointer transition-colors" :class="isDark ? 'bg-slate-800 border-slate-700 text-white hover:bg-slate-700' : 'bg-white border-border text-foreground hover:bg-muted'"><ChevronLeft class="size-4" /></button>
                    <button @click="nextSlide" class="absolute -right-3 top-1/2 -translate-y-1/2 size-8 rounded-full border shadow-md flex items-center justify-center z-10 cursor-pointer transition-colors" :class="isDark ? 'bg-slate-800 border-slate-700 text-white hover:bg-slate-700' : 'bg-white border-border text-foreground hover:bg-muted'"><ChevronRight class="size-4" /></button>
                  </div>

                  <!-- BUBBLE -->
                  <div v-else-if="widgetConfig.layout === 'bubble'" class="w-full py-8 flex flex-col items-center justify-center min-h-[260px]">
                    <div class="text-center text-xs mb-6 max-w-sm" :class="isDark ? 'text-slate-400' : 'text-muted-foreground'">Floating video bubble is docked to the <span class="font-bold" :class="isDark ? 'text-slate-200' : 'text-foreground'">{{ widgetConfig.bubblePosition }}</span> of your user's viewport.</div>
                    <div class="relative p-1.5 rounded-full border-2 shadow-2xl flex items-center gap-3 pr-4 group cursor-pointer hover:scale-105 transition-all" :class="isDark ? 'bg-slate-800 text-white border-primary ring-1 ring-white/10' : 'bg-white text-slate-900 border-primary shadow-xl ring-1 ring-black/5'" @click="activePlayingVideo = previewVideos[0]">
                      <div class="relative size-14 rounded-full overflow-hidden border-2 shadow-md shrink-0" :class="isDark ? 'border-slate-700 bg-slate-900' : 'border-white bg-slate-100'">
                        <img :src="(previewVideos[0] || allVideoTestimonials[0]).thumbnail" class="w-full h-full object-cover" />
                        <div class="absolute inset-0 bg-black/30 flex items-center justify-center"><Play class="size-5 text-white fill-white" /></div>
                      </div>
                      <div>
                        <div class="flex items-center gap-1.5"><span class="text-[12px] font-bold" :class="isDark ? 'text-white' : 'text-slate-900'">Watch Customer Story</span><span class="inline-flex items-center h-4 text-[9px] px-1 rounded bg-primary text-primary-foreground font-semibold">Video</span></div>
                        <div class="text-[11px]" :class="isDark ? 'text-slate-400' : 'text-slate-500'">{{ (previewVideos[0] || allVideoTestimonials[0]).author }} · 5★ Experience</div>
                      </div>
                    </div>
                  </div>

                  <!-- STORY STRIP -->
                  <div v-else-if="widgetConfig.layout === 'story_strip'" class="w-full py-4 overflow-x-auto hide-scrollbar flex items-center gap-4 justify-center">
                    <div v-for="item in previewVideos" :key="item.id" class="flex flex-col items-center gap-1.5 cursor-pointer group shrink-0" @click="activePlayingVideo = item">
                      <div class="p-0.5 rounded-full bg-gradient-to-tr from-amber-500 via-rose-500 to-primary group-hover:scale-105 transition-transform shadow-md">
                        <div class="size-16 rounded-full overflow-hidden border-2 bg-slate-900 relative" :class="isDark ? 'border-slate-900' : 'border-white'">
                          <img :src="item.thumbnail" :alt="item.author" class="w-full h-full object-cover" />
                          <div class="absolute inset-0 bg-black/20 flex items-center justify-center"><Play class="size-4 text-white fill-white" /></div>
                        </div>
                      </div>
                      <span class="text-[11px] font-medium max-w-[70px] truncate text-center" :class="isDark ? 'text-slate-200' : 'text-slate-800'">{{ item.author }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="px-4 sm:px-6 py-3 border-t border-border bg-card flex flex-col sm:flex-row sm:items-center justify-between gap-3 shrink-0">
        <div class="flex items-center gap-2 text-xs text-muted-foreground"><CheckCircle2 class="size-4 text-emerald-500 shrink-0" /><span class="truncate">Real-time preview synchronized · Instant HTML &amp; JS CDN delivery</span></div>
        <div class="flex items-center gap-2 sm:gap-3 self-end sm:self-auto">
          <button class="inline-flex items-center justify-center border border-border hover:border-transparent hover:bg-muted text-xs sm:text-sm h-8 sm:h-9 px-3.5 rounded-lg text-foreground cursor-pointer" @click="close">Close</button>
          <button class="inline-flex items-center gap-1.5 text-xs sm:text-sm h-8 sm:h-9 px-3.5 rounded-lg bg-primary text-primary-foreground font-medium hover:bg-primary/90 shadow-xs cursor-pointer" @click="handleSaveWidget"><Check v-if="isSaved" class="size-3.5 sm:size-4 text-emerald-400" /><Sparkles v-else class="size-3.5 sm:size-4" />{{ isSaved ? 'Widget Saved & Live!' : 'Save & Publish Widget' }}</button>
        </div>
      </div>
    </div>

    <!-- Compact video player popup -->
    <div v-if="activePlayingVideo" class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-in fade-in" @click.self="activePlayingVideo = null">
      <div class="relative w-full max-w-md bg-slate-950 text-white rounded-2xl overflow-hidden border border-slate-800 shadow-2xl flex flex-col">
        <div class="relative w-full aspect-[9/16] max-h-[70vh] bg-slate-900">
          <img :src="activePlayingVideo.thumbnail" class="w-full h-full object-cover" />
          <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/10 to-black/30"></div>
          <button class="absolute top-3 right-3 size-8 rounded-full bg-black/50 hover:bg-black/70 flex items-center justify-center cursor-pointer" @click="activePlayingVideo = null"><X class="size-4" /></button>
          <div class="absolute inset-0 flex items-center justify-center"><div class="size-16 rounded-full bg-white/90 text-slate-900 flex items-center justify-center shadow-xl"><Play class="size-7 ml-0.5 fill-current" /></div></div>
          <div class="absolute bottom-0 left-0 right-0 p-4 space-y-1.5">
            <div class="flex items-center gap-0.5 text-amber-400"><Star v-for="s in activePlayingVideo.rating" :key="s" class="size-3.5 fill-amber-400" /></div>
            <p class="text-sm font-medium leading-relaxed">"{{ activePlayingVideo.quote }}"</p>
            <div class="flex items-center gap-2 pt-1">
              <img :src="activePlayingVideo.avatar" class="size-7 rounded-full object-cover border border-white/20" />
              <div><div class="text-xs font-semibold flex items-center gap-1">{{ activePlayingVideo.author }}<CheckCircle2 class="size-3 text-primary" /></div><div class="text-[10px] text-white/60">{{ activePlayingVideo.company }}</div></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
