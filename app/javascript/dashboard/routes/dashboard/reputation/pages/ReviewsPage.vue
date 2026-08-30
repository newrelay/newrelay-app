<script setup>
/* eslint-disable */
import { ref, computed, onMounted } from 'vue';
import { RelayInput as Input, RelayCheckbox as Checkbox } from 'dashboard/components-next/relay';
import {
  Search, Filter, ChevronDown, CheckSquare, Sparkles, MessageSquare,
  Clock, Check, Calendar, Star, MoreHorizontal, X, ArrowRight,
  UserPlus, Send, Image as ImageIcon, CornerDownRight, FileText,
  MessageCircle, LayoutGrid, List, Plus, Mail
} from 'lucide-vue-next';
import RequestReviewsModal from '../components/RequestReviewsModal.vue';
import ReviewWidgetModal from '../components/ReviewWidgetModal.vue';

const axios = window.axios;
const accountId = window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];
const baseUrl = () => `/api/v1/accounts/${accountId}/reputation`;

const searchQuery = ref('');
const selectedReviews = ref([]);
const selectedReview = ref(null);
const activeReviewMenuId = ref(null);
const internalNote = ref('');
const replyText = ref('');
const viewMode = ref('list');
const loading = ref(true);
const sortOption = ref('Newest First');
const selectedPlatform = ref('All Platforms');
const isRequestModalOpen = ref(false);
const isWidgetModalOpen = ref(false);

const platformIcons = {
  'Google': '<svg viewBox="0 0 24 24" width="14" height="14" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>',
  'Facebook': '<svg viewBox="0 0 24 24" width="14" height="14" xmlns="http://www.w3.org/2000/svg"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" fill="#1877F2"/></svg>',
  'Yelp': '<svg viewBox="0 0 24 24" width="14" height="14" xmlns="http://www.w3.org/2000/svg" fill="#E00707"><path d="M12.271 8.782c-.549-3.804-.822-5.72-.822-5.748 0-.888-.622-1.641-1.537-1.887A2.34 2.34 0 0 0 7.3 2.52L3.473 7.337a2.01 2.01 0 0 0-.302 1.895c.28.72.934 1.218 1.695 1.282l5.894.488c1.038.087 1.871-.767 1.511-2.22zm-8.245 6.253l5.374 2.186c1.004.409 2.084-.332 2.084-1.41V11.38c0-1.088-1.096-1.83-2.104-1.41l-5.374 2.185a1.85 1.85 0 0 0-1.148 1.44 1.855 1.855 0 0 0 1.168 1.44zm6.406 5.978l-3.218-4.874a1.796 1.796 0 0 0-2.97-.095 1.855 1.855 0 0 0-.17 1.98l2.28 4.374a2.316 2.316 0 0 0 2.492 1.208 2.302 2.302 0 0 0 1.586-2.593zm9.56-10.826a2.31 2.31 0 0 0-1.92-1.435l-5.916-.489a1.796 1.796 0 0 0-1.493 2.874l3.42 4.96a1.803 1.803 0 0 0 2.8.217l3.477-4.046a2.02 2.02 0 0 0 .368-.654 2.004 2.004 0 0 0-.736-1.427zm-2.278 7.916l-2.277-4.373a1.804 1.804 0 0 0-3.124.149 1.789 1.789 0 0 0 .057 1.695l3.218 4.874a2.305 2.305 0 0 0 2.534.938 2.316 2.316 0 0 0 1.57-2.593 2.31 2.31 0 0 0-1.978-0.69z"/></svg>',
  'Trustpilot': '<svg viewBox="0 0 24 24" width="14" height="14" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" fill="#00B67A" rx="2" ry="2"/><path d="M12 4l2.5 5.2 5.7.8-4.1 4 1 5.7-5.1-2.7-5.1 2.7 1-5.7-4.1-4 5.7-.8L12 4z" fill="#FFF"/></svg>'
};

const reviews = ref([]);

function formatRelativeDate(dateStr) {
  if (!dateStr) return '';
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 7) return `${days}d ago`;
  const weeks = Math.floor(days / 7);
  return `${weeks}w ago`;
}

function mapReview(r) {
  const provider = (r.provider || 'google');
  const displayPlatform = provider.charAt(0).toUpperCase() + provider.slice(1);
  const hasReply = r.reputation_review_reply && r.reputation_review_reply.body;
  return {
    id: r.id,
    author: r.reviewer_name || 'Anonymous',
    avatar: `https://i.pravatar.cc/150?u=review${r.id}`,
    platform: displayPlatform,
    location: '',
    rating: r.rating || 5,
    date: formatRelativeDate(r.reviewed_at),
    sortAt: r.reviewed_at ? new Date(r.reviewed_at).getTime() : 0,
    content: r.body || '',
    status: hasReply ? 'Replied' : (r.status === 'ignored' ? 'Replied' : 'Needs Reply'),
    assignee: null,
    reply: hasReply ? r.reputation_review_reply.body : null,
    notes: [],
    sentiment: r.rating >= 4 ? 'Positive' : (r.rating <= 2 ? 'Negative' : 'Needs Escalation'),
    aiDraft: r.status === 'pending' && !hasReply,
    history: {},
  };
}

async function loadReviews() {
  loading.value = true;
  try {
    const { data } = await axios.get(`${baseUrl()}/reviews`);
    reviews.value = (data || []).map(mapReview);
  } catch (err) {
    console.error('Failed to load reviews', err);
  } finally {
    loading.value = false;
  }
}

onMounted(loadReviews);

const aiSuggestions = [
  "Thank you for the review! We're thrilled to hear you had a great experience.",
  "Hi [Name], we appreciate your feedback! It's great to hear you're enjoying our features.",
  "Thanks for bringing this to our attention. I apologize for the inconvenience and I've forwarded this to our team."
];

// Dropdown Toggles
const showFilterDropdown = ref(false);
const showPlatformDropdown = ref(false);
const showSortDropdown = ref(false);
const showAssigneeDropdown = ref(false);
const showStatusDropdown = ref(false);

const getSentimentClass = (sentiment) => {
  if (sentiment === 'Positive') return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400';
  if (sentiment === 'Needs Escalation' || sentiment === 'Negative') return 'bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400';
  return 'bg-muted text-muted-foreground';
};

const getStatusClass = (status) => {
  if (status === 'Replied' || status === 'Approved') return 'bg-emerald-50 text-emerald-600 border border-emerald-100 dark:bg-emerald-900/30 dark:border-emerald-800 dark:text-emerald-400';
  if (status === 'Pending') return 'bg-amber-50 text-amber-600 border border-amber-100 dark:bg-amber-900/30 dark:border-amber-800 dark:text-amber-400';
  if (status === 'Needs Reply') return 'bg-purple-500/15 text-purple-700 dark:text-purple-300 border border-purple-500/20';
  return 'bg-muted text-muted-foreground border border-border';
};

const filteredReviews = computed(() => {
  const q = searchQuery.value.toLowerCase();
  const list = reviews.value.filter(r => {
    const matchesSearch =
      r.author.toLowerCase().includes(q) || r.content.toLowerCase().includes(q);
    const matchesPlatform =
      selectedPlatform.value === 'All Platforms' ||
      r.platform.toLowerCase() === selectedPlatform.value.toLowerCase();
    return matchesSearch && matchesPlatform;
  });

  if (sortOption.value === 'Highest Rating') {
    return [...list].sort((a, b) => b.rating - a.rating);
  }
  if (sortOption.value === 'Lowest Rating') {
    return [...list].sort((a, b) => a.rating - b.rating);
  }
  if (sortOption.value === 'Oldest First') {
    return [...list].sort((a, b) => a.sortAt - b.sortAt);
  }
  return [...list].sort((a, b) => b.sortAt - a.sortAt);
});

const isAllSelected = computed(() => {
  return filteredReviews.value.length > 0 && selectedReviews.value.length === filteredReviews.value.length;
});

function toggleSelectAll(checked) {
  if (checked) {
    selectedReviews.value = filteredReviews.value.map(r => r.id);
  } else {
    selectedReviews.value = [];
  }
}

function openReviewDetail(review) {
  selectedReview.value = review;
  replyText.value = review.reply || '';
}

function closeReviewDetail() {
  selectedReview.value = null;
  replyText.value = '';
  internalNote.value = '';
}

function useAiSuggestion(text) {
  if (!selectedReview.value) return;
  replyText.value = text.replace('[Name]', selectedReview.value.author.split(' ')[0]);
}

function addInternalNote() {
  if (!internalNote.value.trim() || !selectedReview.value) return;
  if (!selectedReview.value.notes) selectedReview.value.notes = [];
  selectedReview.value.notes.push({ author: 'You', text: internalNote.value });
  internalNote.value = '';
}

const isSendingReply = ref(false);
async function sendReply() {
  if (!selectedReview.value || !replyText.value.trim() || isSendingReply.value) return;
  isSendingReply.value = true;
  try {
    await axios.post(`${baseUrl()}/reviews/${selectedReview.value.id}/reply`, {
      body: replyText.value,
      publish: true,
    });
    selectedReview.value.reply = replyText.value;
    selectedReview.value.status = 'Replied';
    const inList = reviews.value.find(r => r.id === selectedReview.value.id);
    if (inList) { inList.reply = replyText.value; inList.status = 'Replied'; }
  } catch (err) {
    console.error('Failed to send reply', err);
  } finally {
    isSendingReply.value = false;
  }
}
</script>

<template>
  <div class="relative flex h-[calc(100vh-4rem)] w-full overflow-hidden bg-[#FAFAFA] dark:bg-background">
    <RequestReviewsModal v-model:open="isRequestModalOpen" />
    <ReviewWidgetModal v-model:open="isWidgetModalOpen" />

    <!-- Main Reviews Feed List -->
    <div class="flex-1 overflow-y-auto w-full hide-scrollbar flex flex-col transition-all duration-300" :class="selectedReview ? 'mr-[400px]' : ''">
      
      <!-- Page Header -->
      <div class="px-8 py-6 border-b border-border bg-card shrink-0 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div class="flex items-center gap-2.5">
            <h1 class="text-base font-medium tracking-tight text-foreground">Reviews</h1>
            <span class="inline-flex items-center rounded-md px-2 py-0.5 text-[11.5px] font-medium bg-primary/10 text-primary">
              {{ reviews.length }} Reviews
            </span>
          </div>
          <p class="text-[13.5px] text-muted-foreground mt-0.5">Monitor, manage and respond to customer reviews across all connected platforms.</p>
        </div>

        <div class="flex items-center gap-3 shrink-0">
          <button
            @click="isWidgetModalOpen = true"
            class="inline-flex items-center gap-2 h-9 px-3.5 rounded-lg border border-border bg-card text-[13.5px] font-medium text-foreground hover:bg-muted shadow-xs cursor-pointer"
          >
            <LayoutGrid class="size-4" /> Widget
          </button>
          <button
            @click="isRequestModalOpen = true"
            class="inline-flex items-center gap-2 h-9 px-3.5 rounded-lg bg-primary text-primary-foreground text-[13.5px] font-medium hover:bg-primary/90 shadow-xs cursor-pointer"
          >
            <Mail class="size-4" /> Request Reviews
          </button>
        </div>
      </div>

      <!-- Unified toolbar: select + search | sort / platform / filters / view / pagination -->
      <div class="px-8 py-2.5 border-b border-border/80 bg-card/70 shrink-0 flex items-center justify-between gap-4 overflow-x-auto hide-scrollbar">
        <!-- Left: select-all + selected count + search -->
        <div class="flex items-center gap-3 min-w-0">
          <Checkbox
            v-if="viewMode === 'list'"
            :model-value="isAllSelected"
            @update:model-value="toggleSelectAll"
            class="rounded-sm shrink-0"
          />
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

        <!-- Right: filter dropdowns, view switcher, pagination -->
        <div class="flex items-center gap-2 shrink-0">
          <!-- Sort Dropdown -->
          <div class="relative">
            <button
              @click="showSortDropdown = !showSortDropdown"
              class="inline-flex items-center gap-1.5 h-9 px-3 rounded-lg border border-border bg-card text-[13px] font-medium text-foreground hover:bg-muted shadow-xs cursor-pointer whitespace-nowrap"
            >
              <span>{{ sortOption }}</span>
              <ChevronDown class="size-3 opacity-50" />
            </button>
            <div v-if="showSortDropdown" class="absolute right-0 mt-1 w-44 rounded-lg border border-border bg-card p-1 shadow-lg z-30">
              <button
                v-for="opt in ['Newest First', 'Oldest First', 'Highest Rating', 'Lowest Rating']"
                :key="opt"
                @click="sortOption = opt; showSortDropdown = false"
                class="w-full text-left px-3 py-1.5 text-xs rounded hover:bg-muted cursor-pointer"
                :class="sortOption === opt ? 'text-primary font-semibold' : 'text-foreground'"
              >
                {{ opt }}
              </button>
            </div>
          </div>

          <!-- Platform Dropdown -->
          <div class="relative">
            <button
              @click="showPlatformDropdown = !showPlatformDropdown"
              class="inline-flex items-center gap-1.5 h-9 px-3 rounded-lg border border-border bg-card text-[13px] font-medium text-foreground hover:bg-muted shadow-xs cursor-pointer whitespace-nowrap"
            >
              <span>{{ selectedPlatform }}</span>
              <ChevronDown class="size-3 opacity-50" />
            </button>
            <div v-if="showPlatformDropdown" class="absolute right-0 mt-1 w-44 rounded-xl border border-border bg-card p-1.5 shadow-xl z-30 space-y-0.5">
              <button
                @click="selectedPlatform = 'All Platforms'; showPlatformDropdown = false"
                class="w-full text-left px-3 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground cursor-pointer flex items-center gap-2"
              >
                All Platforms
              </button>
              <button
                v-for="p in ['Google', 'Yelp', 'Facebook', 'Trustpilot']"
                :key="p"
                @click="selectedPlatform = p; showPlatformDropdown = false"
                class="w-full text-left px-3 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground cursor-pointer flex items-center gap-2"
              >
                <div v-html="platformIcons[p]" class="size-4 shrink-0 flex items-center justify-center"></div> {{ p }}
              </button>
            </div>
          </div>

          <!-- Filters Dropdown -->
          <div class="relative">
            <button
              @click="showFilterDropdown = !showFilterDropdown"
              class="inline-flex items-center gap-1.5 h-9 px-3 rounded-lg border border-border bg-card text-[13px] font-medium text-foreground hover:bg-muted shadow-xs cursor-pointer"
            >
              <Filter class="size-3.5" />
              <span>Filters</span>
            </button>
            <div v-if="showFilterDropdown" class="absolute right-0 mt-2 w-64 rounded-xl border border-border bg-card p-2 shadow-xl z-30 space-y-1">
              <div class="max-h-[300px] overflow-y-auto space-y-1">
                <div class="px-2 py-1 text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">Status</div>
                <button class="w-full text-left px-2 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground cursor-pointer">Needs Reply</button>
                <button class="w-full text-left px-2 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground cursor-pointer">Replied</button>
                <button class="w-full text-left px-2 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground cursor-pointer">Assigned To...</button>

                <div class="my-1 border-t border-border/80"></div>
                <div class="px-2 py-1 text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">Properties</div>
                <button class="w-full text-left px-2 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground flex items-center gap-2 cursor-pointer">
                  <Star class="size-4 text-[#FFB020]" /> Rating (1-5)
                </button>
                <button class="w-full text-left px-2 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground flex items-center gap-2 cursor-pointer">
                  <Calendar class="size-4 text-muted-foreground" /> Date Range
                </button>

                <div class="my-1 border-t border-border/80"></div>
                <div class="px-2 py-1 text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">Content</div>
                <button class="w-full text-left px-2 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground flex items-center gap-2 cursor-pointer">
                  <ImageIcon class="size-4" /> With Photos
                </button>
                <button class="w-full text-left px-2 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground flex items-center gap-2 cursor-pointer">
                  <FileText class="size-4" /> Has Attachments
                </button>
                <button class="w-full text-left px-2 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground flex items-center gap-2 cursor-pointer">
                  <Check class="size-4 text-emerald-600" /> Verified Purchase
                </button>
              </div>
            </div>
          </div>

          <div class="h-5 w-px bg-border/80 mx-1"></div>

          <!-- View switcher -->
          <div class="flex bg-muted/40 border border-border/80 rounded-lg p-0.5 shadow-xs">
            <button @click="viewMode = 'grid'" class="p-1.5 rounded-md transition-colors cursor-pointer" :class="viewMode === 'grid' ? 'bg-card text-foreground shadow-xs' : 'text-muted-foreground hover:text-foreground'" title="Grid view"><LayoutGrid class="size-3.5" /></button>
            <button @click="viewMode = 'list'" class="p-1.5 rounded-md transition-colors cursor-pointer" :class="viewMode === 'list' ? 'bg-card text-foreground shadow-xs' : 'text-muted-foreground hover:text-foreground'" title="List view"><List class="size-3.5" /></button>
            <button @click="viewMode = 'timeline'" class="p-1.5 rounded-md transition-colors cursor-pointer" :class="viewMode === 'timeline' ? 'bg-card text-foreground shadow-xs' : 'text-muted-foreground hover:text-foreground'" title="Timeline view"><Clock class="size-3.5" /></button>
          </div>

          <div class="h-5 w-px bg-border/80 mx-1"></div>

          <!-- Pagination info (client loads all reviews; arrows decorative) -->
          <div class="flex items-center gap-2">
            <span class="text-xs font-semibold text-foreground whitespace-nowrap">1-{{ filteredReviews.length }} of {{ reviews.length }}</span>
            <div class="flex items-center gap-1">
              <button class="inline-flex items-center justify-center size-8 rounded-lg bg-card border border-border/80 hover:bg-muted shadow-xs cursor-pointer text-muted-foreground"><ChevronDown class="size-3.5 rotate-90" /></button>
              <button class="inline-flex items-center justify-center size-8 rounded-lg bg-card border border-border/80 hover:bg-muted shadow-xs cursor-pointer text-muted-foreground"><ChevronDown class="size-3.5 -rotate-90" /></button>
            </div>
          </div>
        </div>
      </div>

      <!-- Feed Container -->
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
            :class="activeReviewMenuId === review.id ? 'z-30' : ''"
          >
            <!-- Timeline elements -->
            <div v-if="viewMode === 'timeline'" class="absolute -left-[38.5px] top-8 size-3.5 rounded-full bg-primary ring-4 ring-white dark:ring-[#FAFAFA] transition-colors z-10" :class="selectedReview?.id === review.id ? 'ring-primary/20 scale-125' : ''"></div>
            
            <div v-if="viewMode === 'timeline' && review.timelineDate" class="absolute -left-[145px] top-6 w-[90px] text-left z-10">
              <div class="font-bold text-foreground text-[13.5px]">{{ review.timelineDate.title }}</div>
              <div class="text-xs text-muted-foreground mt-0.5">{{ review.timelineDate.sub }}</div>
            </div>

            <!-- Review Card Row -->
            <div
              @click="openReviewDetail(review)"
              class="transition-all duration-300 cursor-pointer relative"
              :class="[
                activeReviewMenuId === review.id ? 'z-30 overflow-visible' : 'overflow-hidden',
                viewMode === 'list' ? 'px-8 py-5 flex items-center gap-6 hover:bg-muted/30' : 'bg-card border rounded-xl hover:shadow-md p-6 flex flex-col h-full',
                selectedReview?.id === review.id && viewMode === 'list' ? 'bg-primary/10/30 dark:bg-primary/10/10 border-l-[3px] border-l-primary' : viewMode === 'list' ? 'border-l-[3px] border-l-transparent' : '',
                selectedReview?.id === review.id && viewMode !== 'list' ? 'border-primary ring-1 ring-primary shadow-md scale-[1.02]' : viewMode !== 'list' ? 'border-border shadow-sm scale-100' : ''
              ]"
            >
              <!-- Grid Layout View -->
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
                  <span
                    v-if="review.status === 'Needs Reply' && review.aiDraft"
                    class="px-2.5 py-1 text-[10px] font-semibold bg-primary/10 border border-primary/20 text-primary dark:bg-primary/10 dark:border-primary/20 rounded-md inline-flex items-center gap-1"
                  >
                    <Sparkles class="size-3" /> Relay AI Draft Ready
                  </span>
                  <span
                    v-else-if="review.status === 'Needs Reply'"
                    class="px-2.5 py-1 text-[10px] font-semibold bg-purple-500/10 border border-purple-500/20 text-purple-600 dark:text-purple-400 rounded-md inline-flex items-center gap-1"
                  >
                    Reply <ArrowRight class="size-3" />
                  </span>
                  <span
                    v-else
                    class="px-2.5 py-1 text-[10px] font-semibold rounded-md shrink-0"
                    :class="getStatusClass(review.status)"
                  >
                    {{ review.status }}
                  </span>
                  <span class="text-[11px] text-muted-foreground">{{ review.date }}</span>
                </div>
              </div>

              <!-- List & Timeline Content View -->
              <div v-else class="flex w-full min-w-0" :class="viewMode === 'timeline' ? 'flex-row items-start gap-6' : 'items-center gap-6'">
                <!-- Checkbox -->
                <div v-if="viewMode === 'list'" class="flex justify-center shrink-0" @click.stop>
                  <Checkbox
                    class="rounded-sm"
                    :model-value="selectedReviews.includes(review.id)"
                    @update:model-value="(c) => c ? selectedReviews.push(review.id) : selectedReviews.splice(selectedReviews.indexOf(review.id), 1)"
                  />
                </div>
                
                <!-- Author & Rating Info -->
                <div class="w-[320px] shrink-0 flex items-center gap-4">
                  <div class="relative group/avatar cursor-pointer shrink-0">
                    <img :src="review.avatar" class="size-11 rounded-full object-cover shrink-0" />
                    <!-- Hover Popover Card -->
                    <div class="absolute left-0 bottom-full mb-2 hidden group-hover/avatar:block z-50 w-64 p-4 bg-popover border border-border rounded-xl shadow-xl animate-in fade-in zoom-in-95 duration-200 origin-bottom-left">
                      <div class="font-bold text-foreground mb-3 text-sm flex items-center gap-2">
                        <img :src="review.avatar" class="size-6 rounded-full object-cover" />
                        {{ review.author }}
                      </div>
                      <div class="space-y-2 text-[13px]">
                        <div class="flex justify-between items-center text-muted-foreground">
                          <span>Conversations</span>
                          <span class="font-semibold text-foreground">{{ review.history?.conversations || 0 }}</span>
                        </div>
                        <div class="flex justify-between items-center text-muted-foreground">
                          <span>Deals</span>
                          <span class="font-semibold text-foreground">{{ review.history?.deals || 0 }}</span>
                        </div>
                        <div class="flex justify-between items-center text-muted-foreground">
                          <span>Customer Since</span>
                          <span class="font-semibold text-foreground">{{ review.history?.memberSince || 'New' }}</span>
                        </div>
                        <div class="pt-2 mt-2 border-t border-border flex justify-between items-center">
                          <span class="font-medium text-muted-foreground">Lifetime Value</span>
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
                      <div class="flex items-center gap-2">
                        <div class="flex gap-0.5 text-[#FFB020]">
                          <Star v-for="i in 5" :key="i" class="size-[13px]" :class="i <= review.rating ? 'fill-[#FFB020]' : 'text-muted-foreground/30'" />
                        </div>
                        <div 
                          v-if="review.sentiment === 'Positive'" 
                          class="flex items-center gap-1 text-[10px] font-medium px-1.5 py-0.5 rounded-md bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"
                        >
                          <span>{{ review.sentiment }}</span>
                        </div>
                        <div 
                          v-else-if="review.sentiment" 
                          class="flex items-center gap-1 text-[10px] font-medium px-1.5 py-0.5 rounded-md bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400"
                        >
                          <span>{{ review.sentiment }}</span>
                        </div>
                      </div>
                    </div>
                    <div class="flex items-center gap-1.5 text-xs text-muted-foreground mt-0.5">
                      <div v-if="platformIcons[review.platform]" v-html="platformIcons[review.platform]" class="shrink-0 flex items-center justify-center"></div>
                      <span class="font-medium text-foreground/80">{{ review.platform }}</span>
                      <span class="opacity-50">&bull;</span>
                      <span class="truncate">{{ review.location }}</span>
                    </div>
                  </div>
                </div>
                
                <!-- Review Content -->
                <div class="flex-1 min-w-0 pr-8">
                  <p class="text-[13.5px] font-medium text-muted-foreground leading-relaxed line-clamp-2 pr-4">{{ review.content }}</p>
                </div>

                <!-- Actions & Status Badges -->
                <div class="flex items-center gap-3 shrink-0">
                  <button 
                    v-if="review.status === 'Needs Reply' && review.aiDraft"
                    class="h-8 px-3 text-xs font-semibold bg-primary/10 border border-primary/20 text-primary hover:bg-primary/20 rounded-lg inline-flex items-center gap-1.5 transition-colors cursor-pointer"
                    @click.stop="openReviewDetail(review)"
                  >
                    <Sparkles class="size-3.5" /> Relay AI Draft Ready
                  </button>

                  <button 
                    v-else-if="review.status === 'Needs Reply'"
                    class="h-8 px-3 text-xs font-semibold bg-primary/10 border border-primary/20 text-primary hover:bg-primary/20 rounded-lg inline-flex items-center gap-1.5 transition-colors cursor-pointer"
                    @click.stop="openReviewDetail(review)"
                  >
                    Reply <ArrowRight class="size-3.5" />
                  </button>
                  
                  <span 
                    v-else
                    class="px-3 py-1 text-xs font-semibold rounded-md shrink-0"
                    :class="getStatusClass(review.status)"
                  >
                    {{ review.status }}
                  </span>
                  
                  <!-- 3-Dots Action Menu -->
                  <div class="relative shrink-0" @click.stop>
                    <button 
                      class="p-1.5 text-muted-foreground hover:text-foreground rounded-lg hover:bg-muted shrink-0 cursor-pointer" 
                      @click="activeReviewMenuId = activeReviewMenuId === review.id ? null : review.id"
                    >
                      <MoreHorizontal class="size-5" />
                    </button>
                    
                    <div 
                      v-if="activeReviewMenuId === review.id" 
                      class="absolute right-0 mt-1 w-48 rounded-xl border border-border bg-card p-1 shadow-xl z-30 space-y-0.5 animate-in fade-in duration-150"
                    >
                      <button 
                        @click="openReviewDetail(review); activeReviewMenuId = null" 
                        class="w-full text-left px-3 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground flex items-center gap-2 cursor-pointer"
                      >
                        <MessageSquare class="size-4" /> View Details
                      </button>
                      <button 
                        @click="activeReviewMenuId = null" 
                        class="w-full text-left px-3 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground flex items-center gap-2 cursor-pointer"
                      >
                        <UserPlus class="size-4" /> Assign
                      </button>
                      <div class="my-1 border-t border-border/80"></div>
                      <button 
                        @click="review.status = 'Replied'; activeReviewMenuId = null" 
                        class="w-full text-left px-3 py-1.5 text-xs rounded-md hover:bg-muted font-medium text-foreground flex items-center gap-2 cursor-pointer"
                      >
                        <CheckSquare class="size-4 text-emerald-600" /> Mark Resolved
                      </button>
                      <button 
                        @click="reviews = reviews.filter(r => r.id !== review.id); activeReviewMenuId = null" 
                        class="w-full text-left px-3 py-1.5 text-xs rounded-md hover:bg-rose-500/10 text-rose-600 dark:text-rose-400 font-medium flex items-center gap-2 cursor-pointer"
                      >
                        <X class="size-4" /> Delete
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Empty State matching AGENTS.md rule 6 (text-[20px] font-[600]) & rule 31 (developer reset button) -->
        <div v-if="filteredReviews.length === 0" class="p-12 text-center text-muted-foreground flex flex-col items-center">
          <MessageSquare class="size-10 opacity-20 mb-3" />
          <h3 class="text-[20px] font-[600] text-foreground mb-1">No reviews found</h3>
          <p class="text-[13.5px] text-muted-foreground leading-relaxed mb-4">No customer reviews match your search filter.</p>
          <button @click="searchQuery = ''" class="px-4 py-2 rounded-lg border border-border bg-card text-[13.5px] font-medium text-foreground hover:bg-muted transition-colors border-input hover:border-transparent cursor-pointer">
            Reset Filters
          </button>
        </div>
      </div>
    </div>

    <!-- Review Details Right Drawer Panel (1:1 from reference design mockup) -->
    <div 
      class="fixed top-0 bottom-0 right-0 w-[400px] bg-card border-l border-border shadow-2xl transform transition-transform duration-300 ease-in-out z-50 flex flex-col"
      :class="selectedReview ? 'translate-x-0' : 'translate-x-full'"
    >
      <div v-if="selectedReview" class="flex-1 flex flex-col overflow-hidden">
        <!-- Header -->
        <div class="px-5 py-4 border-b border-border flex items-center justify-between bg-card shrink-0">
          <h2 class="text-[15px] font-semibold text-foreground">Review Details</h2>
          <button class="p-1 text-muted-foreground hover:text-foreground rounded-lg hover:bg-muted cursor-pointer" @click="closeReviewDetail">
            <X class="size-4" />
          </button>
        </div>

        <!-- Scrollable Body -->
        <div class="flex-1 overflow-y-auto p-5 space-y-6">
          <!-- Author Header -->
          <div>
            <div class="flex items-start justify-between mb-3">
              <div class="flex items-center gap-3">
                <img :src="selectedReview.avatar" class="size-10 rounded-full border border-border object-cover shrink-0" />
                <div>
                  <h3 class="font-bold text-sm text-foreground">{{ selectedReview.author }}</h3>
                  <div class="flex items-center gap-2 mt-0.5">
                    <span class="text-xs text-muted-foreground">{{ selectedReview.date }} on {{ selectedReview.platform }}</span>
                  </div>
                </div>
              </div>
              <div class="flex gap-0.5 text-[#FFB020] pt-1">
                <Star v-for="i in 5" :key="i" class="size-3.5" :class="i <= selectedReview.rating ? 'fill-[#FFB020]' : 'text-muted-foreground/30'" />
              </div>
            </div>
            <p class="text-sm text-foreground leading-relaxed bg-muted/30 p-4 rounded-xl border border-border/50 shadow-xs">
              {{ selectedReview.content }}
            </p>
          </div>

          <!-- Assignee & Status Selectors -->
          <div class="flex items-center gap-4 bg-muted/20 p-3.5 rounded-xl border border-border/50">
            <!-- Assignee Selector -->
            <div class="flex-1 relative">
              <label class="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider mb-1 block">ASSIGNEE</label>
              <button 
                @click="showAssigneeDropdown = !showAssigneeDropdown"
                class="w-full h-9 bg-card border border-border rounded-lg px-3 py-1.5 text-xs font-medium text-foreground flex items-center justify-between shadow-xs hover:bg-muted/50 transition-colors cursor-pointer"
              >
                <span class="truncate">{{ selectedReview.assignee || 'Unassigned' }}</span>
                <ChevronDown class="size-3.5 text-muted-foreground shrink-0 ml-1.5" />
              </button>
              
              <div 
                v-if="showAssigneeDropdown" 
                class="absolute left-0 right-0 mt-1 bg-card border border-border rounded-xl p-1 shadow-xl z-50 space-y-0.5 animate-in fade-in duration-150"
              >
                <button 
                  v-for="person in ['Unassigned', 'Jane Doe', 'John Smith', 'Sarah Jenkins']"
                  :key="person"
                  @click="selectedReview.assignee = person === 'Unassigned' ? null : person; showAssigneeDropdown = false"
                  class="w-full text-left px-3 py-1.5 text-xs rounded-md font-medium flex items-center justify-between cursor-pointer"
                  :class="(selectedReview.assignee === person || (!selectedReview.assignee && person === 'Unassigned')) ? 'bg-primary/10 text-primary font-semibold' : 'hover:bg-muted text-foreground'"
                >
                  <span>{{ person }}</span>
                  <Check v-if="(selectedReview.assignee === person || (!selectedReview.assignee && person === 'Unassigned'))" class="size-3.5" />
                </button>
              </div>
            </div>

            <!-- Status Selector -->
            <div class="flex-1 relative">
              <label class="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider mb-1 block">STATUS</label>
              <button 
                @click="showStatusDropdown = !showStatusDropdown"
                class="w-full h-9 bg-card border border-border rounded-lg px-3 py-1.5 text-xs font-medium text-foreground flex items-center justify-between shadow-xs hover:bg-muted/50 transition-colors cursor-pointer"
              >
                <span class="truncate">{{ selectedReview.status }}</span>
                <ChevronDown class="size-3.5 text-muted-foreground shrink-0 ml-1.5" />
              </button>
              
              <div 
                v-if="showStatusDropdown" 
                class="absolute left-0 right-0 mt-1 bg-card border border-border rounded-xl p-1 shadow-xl z-50 space-y-0.5 animate-in fade-in duration-150"
              >
                <button 
                  v-for="st in ['Needs Reply', 'Replied', 'Pending']"
                  :key="st"
                  @click="selectedReview.status = st; showStatusDropdown = false"
                  class="w-full text-left px-3 py-1.5 text-xs rounded-md font-medium flex items-center justify-between cursor-pointer"
                  :class="selectedReview.status === st ? 'bg-primary/10 text-primary font-semibold' : 'hover:bg-muted text-foreground'"
                >
                  <span>{{ st }}</span>
                  <Check v-if="selectedReview.status === st" class="size-3.5" />
                </button>
              </div>
            </div>
          </div>

          <!-- Public Reply Section -->
          <div>
            <h3 class="text-sm font-semibold text-foreground flex items-center gap-2 mb-3">
              <MessageCircle class="size-4 text-primary" /> Public Reply
            </h3>
            
            <div v-if="!selectedReview.reply" class="bg-primary/5 rounded-2xl p-4 border border-primary/20 mb-4 space-y-3">
              <div class="flex items-center gap-2 text-primary text-sm font-semibold">
                <Sparkles class="size-4" /> AI Suggestions
              </div>
              <div class="space-y-2">
                <button 
                  v-for="(sug, idx) in aiSuggestions" 
                  :key="idx"
                  @click="useAiSuggestion(sug)"
                  class="w-full text-left text-xs bg-card hover:bg-primary/10 text-muted-foreground hover:text-primary p-3 rounded-xl border border-border/70 shadow-xs transition-colors leading-relaxed cursor-pointer"
                >
                  {{ sug.replace('[Name]', selectedReview.author.split(' ')[0]) }}
                </button>
              </div>
            </div>

            <div class="relative">
              <textarea 
                v-model="replyText"
                class="w-full h-28 text-xs font-normal text-foreground bg-background border border-border rounded-2xl p-3.5 pb-11 focus:outline-none focus:ring-1 focus:ring-primary/40 resize-none placeholder:text-muted-foreground/60 shadow-xs leading-relaxed"
                placeholder="Write a response..."
              ></textarea>
              <div class="absolute bottom-2.5 left-3 right-3 flex justify-between items-center bg-background/80 backdrop-blur-xs pt-1">
                <div class="flex items-center gap-1">
                  <button class="p-1.5 text-muted-foreground hover:text-foreground rounded-lg hover:bg-muted cursor-pointer"><ImageIcon class="size-4" /></button>
                  <button class="p-1.5 text-primary hover:bg-primary/10 rounded-lg cursor-pointer" @click="useAiSuggestion(aiSuggestions[0])"><Sparkles class="size-4" /></button>
                </div>
                <button class="inline-flex items-center gap-1.5 bg-primary text-primary-foreground px-3.5 py-1.5 rounded-lg text-xs font-semibold hover:bg-primary/90 transition-colors shadow-sm cursor-pointer disabled:opacity-50" :disabled="isSendingReply || !replyText.trim() || replyText === selectedReview.reply" @click="sendReply">
                  {{ isSendingReply ? 'Sending…' : (selectedReview.reply ? 'Update' : 'Send') }} <Send class="size-3.5" />
                </button>
              </div>
            </div>
          </div>

          <!-- Internal Notes Section -->
          <div class="pt-4 border-t border-border border-dashed">
            <h3 class="text-sm font-semibold text-foreground flex items-center gap-2 mb-3">
              <FileText class="size-4 text-amber-500" /> Internal Notes
            </h3>
            
            <div class="space-y-3 mb-4">
              <div v-for="(note, idx) in selectedReview.notes || []" :key="idx" class="bg-amber-500/10 border border-amber-500/20 p-3 rounded-lg text-sm">
                <div class="flex justify-between items-center mb-1">
                  <span class="font-medium text-xs text-amber-600 dark:text-amber-400">{{ note.author }}</span>
                  <span class="text-[10px] text-muted-foreground uppercase">Today</span>
                </div>
                <p class="text-foreground leading-relaxed">{{ note.text }}</p>
              </div>
              <div v-if="!selectedReview.notes || selectedReview.notes.length === 0" class="text-xs text-muted-foreground italic py-2 text-center">
                No internal notes yet.
              </div>
            </div>

            <div class="relative">
              <input
                v-model="internalNote"
                @keyup.enter="addInternalNote"
                type="text"
                class="w-full text-xs bg-background border border-border rounded-xl px-3.5 py-2.5 pr-10 focus:outline-none shadow-xs"
                placeholder="Add a private note..."
              />
              <button @click="addInternalNote" class="absolute right-2 top-2 p-1 text-amber-500 hover:text-amber-600 rounded cursor-pointer">
                <Plus class="size-3.5" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Floating Bulk Actions Pill -->
    <div v-if="selectedReviews.length > 0" class="fixed bottom-10 left-1/2 -translate-x-1/2 z-50 flex items-center gap-2 p-2 bg-card/90 backdrop-blur-md border border-border rounded-full shadow-2xl animate-in slide-in-from-bottom-10 fade-in duration-300">
      <div class="flex items-center justify-center px-4 shrink-0 border-r border-border/50">
        <span class="inline-flex items-center justify-center min-w-5 h-5 px-1.5 rounded-md bg-primary text-primary-foreground text-xs font-semibold mr-2">{{ selectedReviews.length }}</span>
        <span class="text-sm font-semibold text-foreground">Selected</span>
      </div>

      <div class="flex items-center gap-1 px-2">
        <button class="inline-flex items-center gap-1.5 rounded-full h-8 px-3 hover:bg-muted text-sm font-medium text-foreground transition-colors cursor-pointer">
          <UserPlus class="size-4" /> Assign
        </button>
        <button class="inline-flex items-center gap-1.5 rounded-full h-8 px-3 hover:bg-primary/10 hover:text-primary text-sm font-medium text-foreground transition-colors cursor-pointer">
          <Sparkles class="size-4" /> Relay AI Reply
        </button>
        <button class="inline-flex items-center gap-1.5 rounded-full h-8 px-3 hover:bg-emerald-500/10 hover:text-emerald-600 text-sm font-medium text-foreground transition-colors cursor-pointer">
          <CheckSquare class="size-4" /> Mark Resolved
        </button>
        <button class="inline-flex items-center gap-1.5 rounded-full h-8 px-3 hover:bg-muted text-sm font-medium text-foreground transition-colors cursor-pointer">
          <CornerDownRight class="size-4" /> Export
        </button>
      </div>

      <div class="pl-2 border-l border-border/50 shrink-0">
        <button class="inline-flex items-center justify-center rounded-full size-8 text-rose-500 hover:text-rose-600 hover:bg-rose-500/10 transition-colors cursor-pointer" @click="selectedReviews = []">
          <X class="size-4" />
        </button>
      </div>
    </div>
  </div>
</template>
