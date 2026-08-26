<script setup lang="ts">
import { ref, computed } from 'vue'
import {
  Search, Filter, Plus, ChevronDown, CheckSquare, Sparkles, MessageSquare,
  Users, Clock, Check, Calendar, Star, MoreHorizontal, X, ArrowRight,
  ThumbsUp, UserPlus, RefreshCw, Send, Image as ImageIcon, CornerDownRight, FileText,
  MessageCircle, Bot, LayoutGrid, List, Mail, Download
} from 'lucide-vue-next'
import {
  Button, Input, DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator,
  Badge, Checkbox
} from '@/components/ui'
import RequestReviewsModal from '@/views/reputation/components/RequestReviewsModal.vue'
import ReviewWidgetModal from './components/ReviewWidgetModal.vue'

// State
const isDemoLoaded = ref(true)
const searchQuery = ref('')
const selectedReviews = ref<number[]>([])
const selectedReview = ref<any>(null)
const internalNote = ref('')
const replyText = ref('')
const viewMode = ref('list')
const isRequestModalOpen = ref(false)
const isWidgetModalOpen = ref(false)
const sortOption = ref('Newest First')
const selectedPlatform = ref('All Platforms')

// Mock Data
const platformIcons: Record<string, string> = {
  'Google': '<svg viewBox="0 0 24 24" width="14" height="14" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>',
  'Facebook': '<svg viewBox="0 0 24 24" width="14" height="14" xmlns="http://www.w3.org/2000/svg"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" fill="#1877F2"/></svg>',
  'Yelp': '<svg viewBox="0 0 24 24" width="14" height="14" xmlns="http://www.w3.org/2000/svg" fill="#E00707"><path d="M12.271 8.782c-.549-3.804-.822-5.72-.822-5.748 0-.888-.622-1.641-1.537-1.887A2.34 2.34 0 0 0 7.3 2.52L3.473 7.337a2.01 2.01 0 0 0-.302 1.895c.28.72.934 1.218 1.695 1.282l5.894.488c1.038.087 1.871-.767 1.511-2.22zm-8.245 6.253l5.374 2.186c1.004.409 2.084-.332 2.084-1.41V11.38c0-1.088-1.096-1.83-2.104-1.41l-5.374 2.185a1.85 1.85 0 0 0-1.148 1.44 1.855 1.855 0 0 0 1.168 1.44zm6.406 5.978l-3.218-4.874a1.796 1.796 0 0 0-2.97-.095 1.855 1.855 0 0 0-.17 1.98l2.28 4.374a2.316 2.316 0 0 0 2.492 1.208 2.302 2.302 0 0 0 1.586-2.593zm9.56-10.826a2.31 2.31 0 0 0-1.92-1.435l-5.916-.489a1.796 1.796 0 0 0-1.493 2.874l3.42 4.96a1.803 1.803 0 0 0 2.8.217l3.477-4.046a2.02 2.02 0 0 0 .368-.654 2.004 2.004 0 0 0-.736-1.427zm-2.278 7.916l-2.277-4.373a1.804 1.804 0 0 0-3.124.149 1.789 1.789 0 0 0 .057 1.695l3.218 4.874a2.305 2.305 0 0 0 2.534.938 2.316 2.316 0 0 0 1.57-2.593 2.31 2.31 0 0 0-1.978-0.69z"/></svg>',
  'Trustpilot': '<svg viewBox="0 0 24 24" width="14" height="14" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" fill="#00B67A" rx="2" ry="2"/><path d="M12 4l2.5 5.2 5.7.8-4.1 4 1 5.7-5.1-2.7-5.1 2.7 1-5.7-4.1-4 5.7-.8L12 4z" fill="#FFF"/></svg>'
}

const reviews = [
  { 
    id: 1, 
    author: 'Sarah Jenkins', 
    avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704d', 
    platform: 'Google', 
    location: 'New York, USA',
    rating: 5, 
    date: '2 hours ago', 
    content: '"Absolutely incredible service! The team was super responsive and helped me resolve my issue within..."',
    status: 'Needs Reply',
    assignee: null,
    notes: [],
    sentiment: 'Positive',
    aiDraft: true,
    history: { conversations: 12, deals: 3, memberSince: '2 years', ltv: '$4,200' },
    timelineDate: { title: 'Today', sub: '21 Jul, 2026' }
  },
  { 
    id: 2, 
    author: 'Michael Chang', 
    avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704e', 
    platform: 'Yelp', 
    location: 'New York, USA',
    rating: 4, 
    date: '1 day ago', 
    content: '"Good overall experience, but the onboarding process could be a little smoother. The product itself..."',
    status: 'Replied',
    assignee: 'Jane Doe',
    reply: 'Hi Michael, thanks for the feedback! We are constantly working on improving our onboarding process and your input is invaluable.',
    notes: [{ author: 'System', text: 'Sentiment flagged as mixed. Assigned to Jane.' }],
    sentiment: 'Needs Escalation',
    aiDraft: false,
    history: { conversations: 4, deals: 1, memberSince: '6 months', ltv: '$800' },
    timelineDate: { title: 'Yesterday', sub: '20 Jul, 2026' }
  },
  { 
    id: 3, 
    author: 'Emily Rodriguez', 
    avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704f', 
    platform: 'Facebook', 
    location: 'New York, USA',
    rating: 5, 
    date: '1 day ago', 
    content: '"We\'ve been using this for 3 months now and it has completely transformed how we handle our..."',
    status: 'Replied',
    assignee: null,
    notes: [],
    sentiment: 'Positive',
    aiDraft: false,
    history: { conversations: 28, deals: 5, memberSince: '3 years', ltv: '$12,500' }
  },
  { 
    id: 4, 
    author: 'David Lee', 
    avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704g', 
    platform: 'Trustpilot', 
    location: 'New York, USA',
    rating: 1, 
    date: '2 days ago', 
    content: '"Terrible experience. The system crashed and I lost all my data. Support took 3 days to respond."',
    status: 'Needs Reply',
    assignee: 'John Smith',
    notes: [{ author: 'John Smith', text: 'Called David on 10/19. Engineering is pushing a hotfix today.' }],
    sentiment: 'Negative',
    aiDraft: true,
    history: { conversations: 3, deals: 1, memberSince: '1 month', ltv: '$150' },
    timelineDate: { title: '18 Jul', sub: '2026' }
  },
]

const aiSuggestions = [
  "Thank you for the review! We're thrilled to hear you had a great experience.",
  "Hi [Name], we appreciate your feedback! It's great to hear you're enjoying our AI features.",
  "Thanks for bringing this to our attention. I apologize for the inconvenience and I've forwarded this to our team."
]

// Computed
const filteredReviews = computed(() => {
  let list = reviews.filter(r => {
    const matchesSearch = r.author.toLowerCase().includes(searchQuery.value.toLowerCase()) || r.content.toLowerCase().includes(searchQuery.value.toLowerCase())
    const matchesPlatform = selectedPlatform.value === 'All Platforms' || r.platform.toLowerCase() === selectedPlatform.value.toLowerCase()
    return matchesSearch && matchesPlatform
  })

  if (sortOption.value === 'Highest Rating') {
    return [...list].sort((a, b) => b.rating - a.rating)
  } else if (sortOption.value === 'Lowest Rating') {
    return [...list].sort((a, b) => a.rating - b.rating)
  } else if (sortOption.value === 'Oldest First') {
    return [...list].reverse()
  }
  return list
})

const isAllSelected = computed(() => {
  return filteredReviews.value.length > 0 && selectedReviews.value.length === filteredReviews.value.length
})

// Actions
function toggleSelectAll(checked: boolean) {
  if (checked) {
    selectedReviews.value = filteredReviews.value.map(r => r.id)
  } else {
    selectedReviews.value = []
  }
}

function openReviewDetail(review: any) {
  selectedReview.value = review
  replyText.value = review.reply || ''
}

function closeReviewDetail() {
  selectedReview.value = null
  replyText.value = ''
  internalNote.value = ''
}

function useAiSuggestion(text: string) {
  replyText.value = text.replace('[Name]', selectedReview.value.author.split(' ')[0])
}

function addInternalNote() {
  if (!internalNote.value.trim()) return
  if (!selectedReview.value.notes) selectedReview.value.notes = []
  selectedReview.value.notes.push({ author: 'You', text: internalNote.value })
  internalNote.value = ''
}
</script>

<template>
  <div class="relative flex h-[calc(100vh-4rem)] w-full overflow-hidden bg-[#FAFAFA] dark:bg-background">
    <RequestReviewsModal v-model:open="isRequestModalOpen" />
    <ReviewWidgetModal v-model:open="isWidgetModalOpen" />

    <!-- Main List -->
    <div class="flex-1 overflow-y-auto w-full hide-scrollbar flex flex-col transition-all duration-300" :class="selectedReview ? 'mr-[400px]' : ''">
      <!-- Top Page Header -->
      <div class="px-8 py-6 border-b border-border bg-white dark:bg-card shrink-0 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div class="flex items-center gap-2.5">
            <h1 class="text-base font-medium tracking-tight text-foreground">Reviews</h1>
            <Badge variant="secondary" class="bg-primary/10 text-primary dark:bg-primary/10 dark:text-primary text-[11.5px] font-medium">1,096 Reviews</Badge>
          </div>
          <p class="text-[13.5px] text-muted-foreground mt-0.5">Monitor, manage and respond to customer reviews across all connected platforms.</p>
        </div>
        
        <div class="flex items-center gap-3">
          <Button 
            variant="outline" 
            class="gap-2 shadow-xs border border-border hover:border-transparent text-[13.5px] bg-white dark:bg-card"
            @click="isWidgetModalOpen = true"
          >
            <LayoutGrid class="size-4" />
            Widget
          </Button>

          <Button class="gap-2 shadow-xs text-[13.5px]" @click="isRequestModalOpen = true">
            <Mail class="size-4" />
            Request Reviews
          </Button>
        </div>
      </div>

      <!-- Single Unified Toolbar, Filter & Pagination Line -->
      <div class="px-8 py-2.5 border-b border-border/80 bg-white/70 dark:bg-card/70 backdrop-blur-sm shrink-0 flex items-center justify-between gap-4 overflow-x-auto hide-scrollbar">
        <!-- Left Side: Batch Select & Search -->
        <div class="flex items-center gap-3 min-w-0">
          <Checkbox v-if="viewMode === 'list'" :model-value="isAllSelected" @update:model-value="toggleSelectAll" class="rounded-sm shrink-0" />
          <span v-if="viewMode === 'list' && selectedReviews.length > 0" class="text-xs text-primary font-semibold shrink-0">
            {{ selectedReviews.length }} selected
          </span>
          <div class="relative w-52 sm:w-64 lg:w-72">
            <Search class="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              v-model="searchQuery"
              type="text"
              placeholder="Search reviews..."
              class="w-full pl-9 bg-background border-border shadow-xs h-9 text-[13.5px] rounded-lg"
            />
          </div>
        </div>
        
        <!-- Right Side: Filter Dropdowns, View Switcher & Pagination Controls -->
        <div class="flex items-center gap-2 shrink-0">
          <!-- Sort Dropdown -->
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <Button variant="outline" class="h-9 gap-1.5 shadow-xs border border-border hover:border-transparent rounded-lg font-medium text-[13px] bg-white dark:bg-card px-3">
                <span>{{ sortOption }}</span>
                <ChevronDown class="size-3 opacity-50" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem @click="sortOption = 'Newest First'">Newest First</DropdownMenuItem>
              <DropdownMenuItem @click="sortOption = 'Oldest First'">Oldest First</DropdownMenuItem>
              <DropdownMenuItem @click="sortOption = 'Highest Rating'">Highest Rating</DropdownMenuItem>
              <DropdownMenuItem @click="sortOption = 'Lowest Rating'">Lowest Rating</DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          <!-- Platform Dropdown -->
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <Button variant="outline" class="h-9 gap-1.5 shadow-xs border border-border hover:border-transparent rounded-lg font-medium text-[13px] bg-white dark:bg-card px-3">
                <span>{{ selectedPlatform }}</span>
                <ChevronDown class="size-3 opacity-50" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent class="w-44" align="end">
              <DropdownMenuItem @click="selectedPlatform = 'All Platforms'">All Platforms</DropdownMenuItem>
              <DropdownMenuItem @click="selectedPlatform = 'Google'">Google</DropdownMenuItem>
              <DropdownMenuItem @click="selectedPlatform = 'Yelp'">Yelp</DropdownMenuItem>
              <DropdownMenuItem @click="selectedPlatform = 'Facebook'">Facebook</DropdownMenuItem>
              <DropdownMenuItem @click="selectedPlatform = 'Trustpilot'">Trustpilot</DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          <!-- Filters Button -->
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <Button variant="outline" class="h-9 gap-1.5 shadow-xs border border-border hover:border-transparent rounded-lg font-medium text-[13px] bg-white dark:bg-card px-3">
                <Filter class="size-3.5" /> 
                <span>Filters</span>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent class="w-64" align="end">
              <div class="max-h-[300px] overflow-y-auto p-1">
                <div class="px-2 py-1.5 text-xs font-semibold text-muted-foreground uppercase tracking-wider">Status</div>
                <DropdownMenuItem>Needs Reply</DropdownMenuItem>
                <DropdownMenuItem>Replied</DropdownMenuItem>
                <DropdownMenuItem>Assigned To...</DropdownMenuItem>
                
                <DropdownMenuSeparator />
                <div class="px-2 py-1.5 text-xs font-semibold text-muted-foreground uppercase tracking-wider">Properties</div>
                <DropdownMenuItem><Star class="mr-2 size-4 text-[#FFB020]" /> Rating (1-5)</DropdownMenuItem>
                <DropdownMenuItem><Calendar class="mr-2 size-4 text-slate-500" /> Date Range</DropdownMenuItem>
                
                <DropdownMenuSeparator />
                <div class="px-2 py-1.5 text-xs font-semibold text-muted-foreground uppercase tracking-wider">Content</div>
                <DropdownMenuItem><ImageIcon class="mr-2 size-4" /> With Photos</DropdownMenuItem>
                <DropdownMenuItem><FileText class="mr-2 size-4" /> Has Attachments</DropdownMenuItem>
                <DropdownMenuItem><Check class="mr-2 size-4 text-emerald-600" /> Verified Purchase</DropdownMenuItem>
              </div>
            </DropdownMenuContent>
          </DropdownMenu>

          <!-- Subtle Divider -->
          <div class="h-5 w-px bg-border/80 mx-1"></div>

          <!-- View Switcher (Grid | List | Timeline) -->
          <div class="flex bg-muted/40 border border-border/80 rounded-lg p-0.5 shadow-2xs">
            <button 
              @click="viewMode = 'grid'" 
              class="p-1.5 rounded-md transition-all cursor-pointer" 
              :class="viewMode === 'grid' ? 'bg-white dark:bg-card text-foreground shadow-2xs' : 'text-muted-foreground hover:text-foreground'"
              title="Grid view"
            >
              <LayoutGrid class="size-3.5" />
            </button>
            <button 
              @click="viewMode = 'list'" 
              class="p-1.5 rounded-md transition-all cursor-pointer" 
              :class="viewMode === 'list' ? 'bg-white dark:bg-card text-foreground shadow-2xs' : 'text-muted-foreground hover:text-foreground'"
              title="List view"
            >
              <List class="size-3.5" />
            </button>
            <button 
              @click="viewMode = 'timeline'" 
              class="p-1.5 rounded-md transition-all cursor-pointer" 
              :class="viewMode === 'timeline' ? 'bg-white dark:bg-card text-foreground shadow-2xs' : 'text-muted-foreground hover:text-foreground'"
              title="Timeline view"
            >
              <Clock class="size-3.5" />
            </button>
          </div>

          <!-- Subtle Divider -->
          <div class="h-5 w-px bg-border/80 mx-1"></div>

          <!-- Pagination Info & Arrows -->
          <div class="flex items-center gap-2">
            <span class="text-xs font-semibold text-foreground whitespace-nowrap">1-20 of 1,096</span>
            <div class="flex items-center gap-1">
              <Button variant="outline" size="icon" class="size-8 rounded-lg bg-white dark:bg-card border-border/80 hover:border-transparent shadow-2xs">
                <ChevronDown class="size-3.5 rotate-90" />
              </Button>
              <Button variant="outline" size="icon" class="size-8 rounded-lg bg-white dark:bg-card border-border/80 hover:border-transparent shadow-2xs">
                <ChevronDown class="size-3.5 -rotate-90" />
              </Button>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content Area -->
      <div class="flex-1 bg-[#FAFAFA] dark:bg-background overflow-y-auto pb-10">
        <div 
          class="transition-all duration-300"
          :class="[
            viewMode === 'list' ? 'flex flex-col gap-0 bg-card divide-y divide-border/50 border-y border-border/50' : '',
            viewMode === 'timeline' ? 'flex flex-col gap-6 ml-[130px] border-l-2 border-primary/10 pl-8 pt-8 pr-8' : '',
            viewMode === 'grid' && selectedReview ? 'grid grid-cols-1 xl:grid-cols-2 gap-6 p-8' : '',
            viewMode === 'grid' && !selectedReview ? 'grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6 p-8' : ''
          ]"
        >
          <div 
            v-for="review in filteredReviews" 
            :key="review.id"
            class="relative group"
          >
            <!-- Timeline elements -->
            <div v-if="viewMode === 'timeline'" class="absolute -left-[38.5px] top-8 size-3.5 rounded-full bg-primary ring-4 ring-white dark:ring-[#FAFAFA] transition-colors z-10" :class="selectedReview?.id === review.id ? 'ring-primary/20 scale-125' : ''"></div>
            
            <div v-if="viewMode === 'timeline' && review.timelineDate" class="absolute -left-[145px] top-6 w-[90px] text-left z-10">
              <div class="font-bold text-foreground text-[13.5px]">{{ review.timelineDate.title }}</div>
              <div class="text-xs text-muted-foreground mt-0.5">{{ review.timelineDate.sub }}</div>
            </div>

            <!-- Review Card Body -->
            <div
              @click="openReviewDetail(review)"
              class="transition-all duration-300 cursor-pointer overflow-hidden relative"
              :class="[
                viewMode === 'list' ? 'px-8 py-5 flex items-center gap-6 hover:bg-muted/30' : 'bg-white dark:bg-card border rounded-xl hover:shadow-md p-6 flex flex-col h-full',
                selectedReview?.id === review.id && viewMode === 'list' ? 'bg-primary/10/30 dark:bg-primary/10/10 border-l-[3px] border-l-[#8B5CF6]' : viewMode === 'list' ? 'border-l-[3px] border-l-transparent' : '',
                selectedReview?.id === review.id && viewMode !== 'list' ? 'border-primary ring-1 ring-primary shadow-md scale-[1.02]' : viewMode !== 'list' ? 'border-border shadow-sm scale-100' : ''
              ]"
            >
              <!-- Grid Content -->
              <div v-if="viewMode === 'grid'" class="flex flex-col h-full gap-4">
                <div class="flex items-start justify-between">
                  <div class="flex items-center gap-3">
                    <img :src="review.avatar" class="size-10 rounded-full object-cover" />
                    <div>
                      <div class="font-bold text-[14px] text-foreground">{{ review.author }}</div>
                      <div class="flex items-center gap-1.5 text-xs text-muted-foreground mt-0.5">
                        <div v-if="platformIcons[review.platform]" v-html="platformIcons[review.platform]" class="shrink-0 flex items-center justify-center"></div>
                        <span class="font-medium text-foreground/80">{{ review.platform }}</span>
                      </div>
                    </div>
                  </div>
                  <div class="flex text-[#FFB020]">
                    <Star v-for="i in 5" :key="i" class="size-3" :class="i <= review.rating ? 'fill-[#FFB020]' : 'text-muted-foreground/30'" />
                  </div>
                </div>
                
                <p class="text-[13.5px] font-medium text-muted-foreground leading-relaxed line-clamp-3 flex-1 mt-2">
                  {{ review.content }}
                </p>
                
                <div class="flex items-center justify-between pt-2 mt-auto">
                  <Badge 
                    v-if="review.status === 'Needs Reply' && review.aiDraft"
                    variant="outline" 
                    class="px-2.5 py-1 text-[10px] font-semibold bg-primary/10 border-primary/20 text-primary dark:bg-primary/10 dark:border-primary/20 dark:text-primary rounded-md gap-1"
                  >
                    <Sparkles class="size-3" /> AI Draft Ready
                  </Badge>
                  <Badge 
                    v-else-if="review.status === 'Needs Reply'"
                    variant="outline" 
                    class="px-2.5 py-1 text-[10px] font-semibold bg-[#F3E8FF] border-[#E9D5FF] text-[#7E22CE] dark:bg-[#7E22CE]/20 dark:border-[#7E22CE]/30 dark:text-[#D8B4FE] rounded-md gap-1"
                  >
                    Reply <ArrowRight class="size-3" />
                  </Badge>
                  <Badge 
                    v-else
                    variant="outline" 
                    class="px-2.5 py-1 text-[10px] font-semibold border-0 rounded-md bg-[#DCFCE7] text-[#166534] dark:bg-[#166534]/20 dark:text-[#86EFAC]"
                  >
                    {{ review.status }}
                  </Badge>
                  <span class="text-[11px] text-muted-foreground">{{ review.date }}</span>
                </div>
              </div>

              <!-- List / Timeline Content -->
              <div v-else class="flex w-full min-w-0" :class="viewMode === 'timeline' ? 'flex-row items-start gap-6' : 'items-center gap-6'">
                <!-- Checkbox (List Only) -->
                <div v-if="viewMode === 'list'" class="flex justify-center shrink-0" @click.stop>
                  <Checkbox class="rounded-sm" :model-value="selectedReviews.includes(review.id)" @update:model-value="(c) => c ? selectedReviews.push(review.id) : selectedReviews.splice(selectedReviews.indexOf(review.id), 1)" />
                </div>
                
                <!-- User & Platform Info -->
                <div class="w-[320px] shrink-0 flex items-center gap-4">
                  <div class="relative group/avatar cursor-help shrink-0">
                    <img :src="review.avatar" class="size-11 rounded-full object-cover shrink-0" />
                    <!-- Customer History Popup -->
                    <div class="absolute left-0 bottom-full mb-2 hidden group-hover/avatar:block z-50 w-64 p-4 bg-popover border border-border rounded-xl shadow-xl animate-in fade-in zoom-in-95 duration-200 origin-bottom-left">
                      <div class="font-bold text-foreground mb-3 text-sm flex items-center gap-2">
                        <img :src="review.avatar" class="size-6 rounded-full object-cover" />
                        {{ review.author }}
                      </div>
                      <div class="space-y-2 text-[13px]">
                        <div class="flex justify-between items-center">
                          <span class="text-muted-foreground">Conversations</span>
                          <span class="font-medium text-foreground">{{ review.history?.conversations || 0 }}</span>
                        </div>
                        <div class="flex justify-between items-center">
                          <span class="text-muted-foreground">Deals</span>
                          <span class="font-medium text-foreground">{{ review.history?.deals || 0 }}</span>
                        </div>
                        <div class="flex justify-between items-center">
                          <span class="text-muted-foreground">Customer Since</span>
                          <span class="font-medium text-foreground">{{ review.history?.memberSince || 'New' }}</span>
                        </div>
                        <div class="pt-2 mt-2 border-t border-border flex justify-between items-center">
                          <span class="text-muted-foreground font-medium">Lifetime Value</span>
                          <span class="font-bold text-emerald-600 dark:text-emerald-400">{{ review.history?.ltv || '$0' }}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <div class="flex flex-col min-w-0">
                    <div class="flex flex-col gap-1 mb-1">
                      <div class="flex items-center gap-2">
                        <span class="font-bold text-[13.5px] text-foreground truncate">{{ review.author }}</span>
                        <span class="text-[11px] text-muted-foreground whitespace-nowrap">{{ review.date }}</span>
                      </div>
                      <div class="flex flex-wrap items-center gap-2">
                        <div class="flex gap-0.5 text-[#FFB020]">
                          <Star v-for="i in 5" :key="i" class="size-[13px]" :class="i <= review.rating ? 'fill-[#FFB020]' : 'text-muted-foreground/30'" />
                        </div>
                        <div v-if="review.sentiment" class="flex items-center gap-1 text-[10px] font-medium px-1.5 py-0.5 rounded-md"
                            :class="{'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400': review.sentiment === 'Positive', 'bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400': review.sentiment === 'Negative' || review.sentiment === 'Needs Escalation', 'bg-muted text-muted-foreground': review.sentiment !== 'Positive' && review.sentiment !== 'Negative' && review.sentiment !== 'Needs Escalation'}">
                          <span>{{ review.sentiment }}</span>
                        </div>
                      </div>
                    </div>
                    <div class="flex items-center gap-1.5 text-xs text-muted-foreground mt-0.5">
                      <div v-if="platformIcons[review.platform]" v-html="platformIcons[review.platform]" class="shrink-0 flex items-center justify-center"></div>
                      <span class="font-medium text-foreground/80">{{ review.platform }}</span>
                      <span class="mx-0.5 opacity-50">&bull;</span>
                      <span class="truncate">{{ review.location }}</span>
                    </div>
                  </div>
                </div>
                
                <!-- Review Content -->
                <div class="flex-1 min-w-0 pr-8">
                  <p class="text-[13.5px] font-medium text-muted-foreground leading-relaxed line-clamp-2 pr-4">{{ review.content }}</p>
                </div>

                <!-- Status & Actions -->
                <div class="flex items-center gap-3 shrink-0">
                  <Button 
                    v-if="review.status === 'Needs Reply' && review.aiDraft"
                    variant="outline" 
                    size="sm"
                    class="h-8 px-3 text-xs font-semibold bg-primary/10 border-primary/20 text-primary hover:bg-primary/20 gap-1.5 shadow-sm"
                    @click.stop="openReviewDetail(review)"
                  >
                    <Sparkles class="size-3.5" /> AI Draft Ready
                  </Button>

                  <Button 
                    v-else-if="review.status === 'Needs Reply'"
                    variant="outline" 
                    size="sm"
                    class="h-8 px-3 text-xs font-semibold bg-primary/10 border-primary/20 text-primary hover:bg-primary/20 gap-1.5 shadow-sm"
                    @click.stop="openReviewDetail(review)"
                  >
                    Reply <ArrowRight class="size-3.5" />
                  </Button>
                  
                  <Badge 
                    v-else
                    variant="outline" 
                    class="px-3 py-1.5 text-xs font-semibold border-0 rounded-md bg-[#DCFCE7] text-[#166534] dark:bg-[#166534]/20 dark:text-[#86EFAC]"
                  >
                    {{ review.status }}
                  </Badge>
                  
                  <DropdownMenu>
                    <DropdownMenuTrigger as-child>
                      <Button variant="ghost" size="icon" class="size-8 text-muted-foreground hover:bg-muted shrink-0" @click.stop>
                        <MoreHorizontal class="size-5" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end" class="w-48">
                      <DropdownMenuItem @click="openReviewDetail(review)"><MessageSquare class="mr-2 size-4" /> View Details</DropdownMenuItem>
                      <DropdownMenuItem><UserPlus class="mr-2 size-4" /> Assign</DropdownMenuItem>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem><CheckSquare class="mr-2 size-4" /> Mark Resolved</DropdownMenuItem>
                      <DropdownMenuItem class="text-rose-600 focus:text-rose-600 dark:text-rose-400"><X class="mr-2 size-4" /> Delete</DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div v-if="filteredReviews.length === 0" class="p-12 text-center text-muted-foreground flex flex-col items-center">
          <MessageSquare class="size-10 opacity-20 mb-3" />
          <p>No reviews found matching your search.</p>
        </div>
      </div>
    </div>
      <!-- Review Details Panel -->
      <div 
        class="fixed top-16 bottom-0 right-0 w-[400px] bg-card border-l border-border shadow-xl transform transition-transform duration-300 ease-in-out z-40 flex flex-col"
        :class="selectedReview ? 'translate-x-0' : 'translate-x-full'"
      >
        <div v-if="selectedReview" class="flex-1 flex flex-col overflow-hidden">
          <!-- Header -->
          <div class="px-5 py-4 border-b border-border flex items-center justify-between bg-muted/10 shrink-0">
            <h2 class="text-base font-semibold text-foreground">Review Details</h2>
            <div class="flex items-center gap-1">

              <Button variant="ghost" size="icon" class="size-8 text-muted-foreground hover:text-foreground" @click="closeReviewDetail">
                <X class="size-4" />
              </Button>
            </div>
          </div>
  
          <!-- Scrollable Content -->
          <div class="flex-1 overflow-y-auto p-5 space-y-6">
            <!-- Customer Info & Review -->
            <div>
              <div class="flex items-center justify-between mb-4">
                <div class="flex items-center gap-3">
                  <img :src="selectedReview.avatar" class="size-10 rounded-full border border-border" />
                  <div>
                    <h3 class="font-medium text-sm text-foreground">{{ selectedReview.author }}</h3>
                    <div class="flex items-center gap-2 mt-0.5">
                      <span class="text-xs text-muted-foreground">{{ selectedReview.date }} on {{ selectedReview.platform }}</span>
                    </div>
                  </div>
                </div>
                <div class="flex gap-0.5 text-[#FFB020]">
                  <Star v-for="i in 5" :key="i" class="size-3.5" :class="i <= selectedReview.rating ? 'fill-[#FFB020]' : 'text-muted-foreground/30'" />
                </div>
              </div>
              <p class="text-sm text-foreground leading-relaxed bg-muted/30 p-4 rounded-xl border border-border/50">
                {{ selectedReview.content }}
              </p>
            </div>

          <!-- Assignment & Status -->
          <div class="flex items-center gap-4 bg-muted/20 p-3 rounded-xl border border-border/50">
            <div class="flex-1">
              <label class="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-1 block">Assignee</label>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <Button variant="outline" size="sm" class="h-8 w-full justify-between bg-card text-xs">
                    {{ selectedReview.assignee || 'Unassigned' }}
                    <ChevronDown class="size-3 opacity-50" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="w-[200px]">
                  <DropdownMenuItem>Unassigned</DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem>Jane Doe</DropdownMenuItem>
                  <DropdownMenuItem>John Smith</DropdownMenuItem>
                  <DropdownMenuItem>Sarah Jenkins</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
            <div class="flex-1">
              <label class="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-1 block">Status</label>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <Button variant="outline" size="sm" class="h-8 w-full justify-between bg-card text-xs">
                    {{ selectedReview.status }}
                    <ChevronDown class="size-3 opacity-50" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="w-[200px]">
                  <DropdownMenuItem>Unreplied</DropdownMenuItem>
                  <DropdownMenuItem>In Progress</DropdownMenuItem>
                  <DropdownMenuItem>Replied</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>

          <!-- Public Reply Section -->
          <div>
            <h3 class="text-sm font-semibold text-foreground flex items-center gap-2 mb-3">
              <MessageCircle class="size-4 text-primary" /> Public Reply
            </h3>
            
            <div v-if="!selectedReview.reply" class="bg-primary/5 rounded-xl p-4 border border-primary/20 mb-4">
              <div class="flex items-center gap-2 mb-3 text-primary text-sm font-medium">
                <Sparkles class="size-4" /> AI Suggestions
              </div>
              <div class="space-y-2">
                <button 
                  v-for="(sug, idx) in aiSuggestions" 
                  :key="idx"
                  @click="useAiSuggestion(sug)"
                  class="w-full text-left text-xs bg-white dark:bg-card hover:bg-primary/10 text-muted-foreground hover:text-primary p-2.5 rounded-lg border border-border shadow-sm transition-colors leading-relaxed"
                >
                  {{ sug.replace('[Name]', selectedReview.author.split(' ')[0]) }}
                </button>
              </div>
            </div>

            <div class="relative">
              <textarea 
                v-model="replyText"
                rows="4" 
                class="w-full text-sm bg-background border border-border rounded-xl p-3 pb-12 focus:outline-none focus:ring-2 focus:ring-ring resize-none"
                placeholder="Write a response..."
              ></textarea>
              <div class="absolute bottom-3 left-3 right-3 flex justify-between items-center">
                <div class="flex items-center gap-1">
                  <Button variant="ghost" size="icon" class="size-8 text-muted-foreground hover:text-foreground">
                    <ImageIcon class="size-4" />
                  </Button>
                  <Button variant="ghost" size="icon" class="size-8 text-primary hover:text-primary hover:bg-primary/10">
                    <Sparkles class="size-4" />
                  </Button>
                </div>
                <Button size="sm" class="h-8 gap-1.5 shadow-sm bg-primary hover:bg-primary/90 text-primary-foreground">
                  Send <Send class="size-3.5" />
                </Button>
              </div>
            </div>
          </div>

          <hr class="border-border border-dashed" />

          <!-- Internal Notes Section -->
          <div>
            <h3 class="text-sm font-semibold text-foreground flex items-center gap-2 mb-3">
              <FileText class="size-4 text-orange-500" /> Internal Notes
            </h3>
            
            <div class="space-y-3 mb-4">
              <div v-for="(note, idx) in selectedReview.notes || []" :key="idx" class="bg-orange-50/50 dark:bg-orange-950/20 border border-orange-100 dark:border-orange-900/30 p-3 rounded-lg text-sm">
                <div class="flex justify-between items-center mb-1">
                  <span class="font-medium text-xs text-orange-800 dark:text-orange-400">{{ note.author }}</span>
                  <span class="text-[10px] text-muted-foreground uppercase">Today</span>
                </div>
                <p class="text-orange-900/80 dark:text-orange-200/80 leading-relaxed">{{ note.text }}</p>
              </div>
              <div v-if="(!selectedReview.notes || selectedReview.notes.length === 0)" class="text-xs text-muted-foreground text-center py-2 italic">
                No internal notes yet.
              </div>
            </div>

            <div class="relative">
              <Input
                v-model="internalNote"
                @keyup.enter="addInternalNote"
                type="text"
                class="w-full text-sm bg-orange-50/30 dark:bg-orange-950/10 border-orange-200 dark:border-orange-900/30 pr-10"
                placeholder="Add a private note..."
              />
              <Button @click="addInternalNote" variant="ghost" size="icon" class="absolute right-1 top-1 size-7 text-orange-500 hover:text-orange-600 hover:bg-orange-100 dark:hover:bg-orange-900/50">
                <Plus class="size-3.5" />
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- Floating Bulk Actions Toolbar -->
    <div v-if="selectedReviews.length > 0" class="fixed bottom-10 left-1/2 -translate-x-1/2 z-50 flex items-center gap-2 p-2 bg-white/90 dark:bg-card/90 backdrop-blur-md border border-border rounded-full shadow-2xl animate-in slide-in-from-bottom-10 fade-in duration-300">
      <div class="flex items-center justify-center px-4 shrink-0 border-r border-border/50">
        <Badge class="bg-primary hover:bg-primary text-white mr-2">{{ selectedReviews.length }}</Badge>
        <span class="text-sm font-semibold text-foreground">Selected</span>
      </div>
      
      <div class="flex items-center gap-1 px-2">
        <Button size="sm" variant="ghost" class="rounded-full h-8 px-3 gap-1.5 hover:bg-muted text-sm font-medium">
          <UserPlus class="size-4" /> Assign
        </Button>
        <Button size="sm" variant="ghost" class="rounded-full h-8 px-3 gap-1.5 hover:bg-primary/10 hover:text-primary dark:hover:bg-indigo-900/30 text-sm font-medium">
          <Sparkles class="size-4" /> AI Reply
        </Button>
        <Button size="sm" variant="ghost" class="rounded-full h-8 px-3 gap-1.5 hover:bg-emerald-50 hover:text-emerald-600 dark:hover:bg-emerald-900/30 text-sm font-medium">
          <CheckSquare class="size-4" /> Mark Resolved
        </Button>
        <Button size="sm" variant="ghost" class="rounded-full h-8 px-3 gap-1.5 hover:bg-muted text-sm font-medium">
          <CornerDownRight class="size-4" /> Export
        </Button>
      </div>
      
      <div class="pl-2 border-l border-border/50 shrink-0">
        <Button size="icon" variant="ghost" class="rounded-full size-8 text-rose-500 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/50" @click="selectedReviews = []">
          <X class="size-4" />
        </Button>
      </div>
    </div>
  </div>
</template>