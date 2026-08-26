<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import {
  Star, TrendingUp, MessageSquare, Bot, 
  ArrowRight, MessageCircle, Link, Mail, StarHalf, Share2, Info, Trophy,
  Check, Sparkles, ShieldCheck, Zap, QrCode, Lightbulb, ExternalLink,
  Plus, CheckCircle2, Sliders, Globe, RotateCcw, ThumbsUp, ChevronRight, ChevronDown
} from 'lucide-vue-next'
import { Button, Badge, StateBadge, DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem } from '@/components/ui'
import { BarChart } from '@/components/charts'
import PremiumEmptyState from '@/components/layout/PremiumEmptyState.vue'
import ShareReportModal from './components/ShareReportModal.vue'
import RequestReviewsModal from './components/RequestReviewsModal.vue'
import FeedbackBreakdownModal from './components/FeedbackBreakdownModal.vue'

const router = useRouter()

// View State: 'working' | 'onboarding' | 'empty'
const currentViewState = ref<'working' | 'onboarding' | 'empty'>('working')
const trendTimeframe = ref('Last 7 Months')

const isShareModalOpen = ref(false)
const isRequestModalOpen = ref(false)
const isFeedbackModalOpen = ref(false)

const chartLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul']
const chartSeries = [
  {
    name: 'Positive',
    data: [65, 59, 80, 81, 56, 55, 72]
  },
  {
    name: 'Negative/Neutral',
    data: [45, 40, 50, 60, 40, 42, 58]
  }
]

const recentReviews = [
  { id: 1, author: 'Sarah Jenkins', avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704d', platform: 'Google', rating: 5, date: '2 days ago', content: 'Absolutely incredible service! The team was super responsive and helped me resolve my issue within minutes. Highly recommended to anyone looking for a solid solution.' },
  { id: 2, author: 'Michael Chang', avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704e', platform: 'Yelp', rating: 4, date: '4 days ago', content: 'Good overall experience, but the onboarding process could be a little smoother. The product itself is fantastic though and the support team is great.' },
  { id: 3, author: 'Emily Rodriguez', avatar: 'https://i.pravatar.cc/150?u=a042581f4e29026704f', platform: 'Facebook', rating: 5, date: '1 week ago', content: 'We\'ve been using this for 3 months now and it has completely transformed how we handle our customer engagement. The AI features are a game changer.' },
]

const platforms = [
  { name: 'Google', rating: 4.8, total: 452, trend: 'up', svgIcon: '<svg viewBox="0 0 24 24" width="20" height="20" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>' },
  { name: 'Facebook', rating: 4.9, total: 312, trend: 'up', svgIcon: '<svg viewBox="0 0 24 24" width="20" height="20" xmlns="http://www.w3.org/2000/svg"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" fill="#1877F2"/></svg>' },
  { name: 'Yelp', rating: 4.3, total: 128, trend: 'down', svgIcon: '<svg viewBox="0 0 24 24" width="20" height="20" xmlns="http://www.w3.org/2000/svg" fill="#E00707"><path d="M12.271 8.782c-.549-3.804-.822-5.72-.822-5.748 0-.888-.622-1.641-1.537-1.887A2.34 2.34 0 0 0 7.3 2.52L3.473 7.337a2.01 2.01 0 0 0-.302 1.895c.28.72.934 1.218 1.695 1.282l5.894.488c1.038.087 1.871-.767 1.511-2.22zm-8.245 6.253l5.374 2.186c1.004.409 2.084-.332 2.084-1.41V11.38c0-1.088-1.096-1.83-2.104-1.41l-5.374 2.185a1.85 1.85 0 0 0-1.148 1.44 1.855 1.855 0 0 0 1.168 1.44zm6.406 5.978l-3.218-4.874a1.796 1.796 0 0 0-2.97-.095 1.855 1.855 0 0 0-.17 1.98l2.28 4.374a2.316 2.316 0 0 0 2.492 1.208 2.302 2.302 0 0 0 1.586-2.593zm9.56-10.826a2.31 2.31 0 0 0-1.92-1.435l-5.916-.489a1.796 1.796 0 0 0-1.493 2.874l3.42 4.96a1.803 1.803 0 0 0 2.8.217l3.477-4.046a2.02 2.02 0 0 0 .368-.654 2.004 2.004 0 0 0-.736-1.427zm-2.278 7.916l-2.277-4.373a1.804 1.804 0 0 0-3.124.149 1.789 1.789 0 0 0 .057 1.695l3.218 4.874a2.305 2.305 0 0 0 2.534.938 2.316 2.316 0 0 0 1.57-2.593 2.31 2.31 0 0 0-1.978-0.69z"/></svg>' },
  { name: 'Trustpilot', rating: 4.6, total: 204, trend: 'up', svgIcon: '<svg viewBox="0 0 24 24" width="20" height="20" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" fill="#00B67A" rx="2" ry="2"/><path d="M12 4l2.5 5.2 5.7.8-4.1 4 1 5.7-5.1-2.7-5.1 2.7 1-5.7-4.1-4 5.7-.8L12 4z" fill="#FFF"/></svg>' },
]

// Empty state integrations for display
const emptyStateIntegrations = [
  { name: 'Google', icon: Globe, color: 'text-primary' },
  { name: 'Facebook', icon: MessageSquare, color: 'text-primary' },
  { name: 'Yelp', icon: Star, color: 'text-primary' },
  { name: 'Trustpilot', icon: ShieldCheck, color: 'text-primary' },
  { name: 'TripAdvisor', icon: Trophy, color: 'text-primary' }
]

function handleShareReport() {
  isShareModalOpen.value = true
}

function handleRequestReviews() {
  isRequestModalOpen.value = true
}

function navigateToIntegrations() {
  router.push('/reputation/integrations')
}
</script>

<template>
  <div class="flex-1 overflow-y-auto w-full hide-scrollbar bg-[#FAFAFA] dark:bg-background p-6 lg:p-8 relative">
    <ShareReportModal v-model:open="isShareModalOpen" />
    <RequestReviewsModal v-model:open="isRequestModalOpen" />
    <FeedbackBreakdownModal v-model:open="isFeedbackModalOpen" />
    
    <!-- 1. WORKING STATE VIEW -->
    <div v-if="currentViewState === 'working'" class="max-w-7xl mx-auto space-y-6 animate-in fade-in duration-300">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div>
          <h1 class="text-base font-medium tracking-tight text-foreground">Overview</h1>
          <p class="text-sm text-muted-foreground mt-1">Monitor and manage your brand's online presence across all platforms.</p>
        </div>
        <div class="flex items-center gap-3">
          <Button variant="outline" class="gap-2 shadow-sm bg-white dark:bg-card border border-border hover:border-transparent" @click="handleShareReport">
            <Share2 class="size-4" />
            Share Report
          </Button>
          <Button class="gap-2 shadow-sm" @click="handleRequestReviews">
            <Mail class="size-4" />
            Request Reviews
          </Button>
        </div>
      </div>

      <!-- Section 1: Top Summary Metrics -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Reputation Score -->
        <div class="bg-card rounded-xl border border-border shadow-sm p-5 relative overflow-hidden group hover:border-primary/50 transition-colors">
          <div class="flex justify-between items-start mb-4">
            <div>
              <p class="text-sm font-medium text-muted-foreground mb-1">Reputation Score</p>
              <h3 class="text-3xl font-bold text-foreground">85<span class="text-lg text-muted-foreground font-normal">/100</span></h3>
            </div>
            <div class="p-2.5 bg-primary/10 dark:bg-primary/10 rounded-lg text-primary dark:text-primary">
              <Trophy class="size-5" />
            </div>
          </div>
          <div class="flex items-center text-sm font-medium text-emerald-600 dark:text-emerald-400 gap-1">
            <TrendingUp class="size-3.5" />
            <span>+3 pts</span>
            <span class="text-muted-foreground font-normal ml-1">from last month</span>
          </div>
        </div>

        <!-- Average Rating -->
        <div class="bg-card rounded-xl border border-border shadow-sm p-5 relative overflow-hidden group hover:border-primary/50 transition-colors">
          <div class="flex justify-between items-start mb-4">
            <div>
              <p class="text-sm font-medium text-muted-foreground mb-1">Average Rating</p>
              <div class="flex items-baseline gap-2">
                <h3 class="text-3xl font-bold text-foreground">4.7</h3>
                <div class="flex gap-0.5 text-amber-500">
                  <Star class="size-4 fill-amber-500" />
                  <Star class="size-4 fill-amber-500" />
                  <Star class="size-4 fill-amber-500" />
                  <Star class="size-4 fill-amber-500" />
                  <StarHalf class="size-4 fill-amber-500" />
                </div>
              </div>
            </div>
            <div class="p-2.5 bg-primary/10 rounded-lg text-primary">
              <Star class="size-5" />
            </div>
          </div>
          <div class="flex items-center text-sm font-medium text-emerald-600 dark:text-emerald-400 gap-1">
            <TrendingUp class="size-3.5" />
            <span>+0.2</span>
            <span class="text-muted-foreground font-normal ml-1">from last month</span>
          </div>
        </div>

        <!-- Total Reviews -->
        <div class="bg-card rounded-xl border border-border shadow-sm p-5 relative overflow-hidden group hover:border-primary/50 transition-colors">
          <div class="flex justify-between items-start mb-4">
            <div>
              <p class="text-sm font-medium text-muted-foreground mb-1">Total Reviews</p>
              <h3 class="text-3xl font-bold text-foreground">1,096</h3>
            </div>
            <div class="p-2.5 bg-primary/10 rounded-lg text-primary">
              <MessageCircle class="size-5" />
            </div>
          </div>
          <div class="flex items-center text-sm font-medium text-emerald-600 dark:text-emerald-400 gap-1">
            <TrendingUp class="size-3.5" />
            <span>+12%</span>
            <span class="text-muted-foreground font-normal ml-1">vs last period</span>
          </div>
        </div>

        <!-- Overall Feedback -->
        <div 
          class="bg-card rounded-xl border border-border shadow-sm p-5 relative overflow-hidden group hover:border-primary/50 transition-colors cursor-pointer"
          @click="isFeedbackModalOpen = true"
        >
          <div class="flex justify-between items-start mb-4">
            <div>
              <p class="text-sm font-medium text-muted-foreground mb-1">Overall Feedback</p>
              <div class="flex items-baseline gap-1.5">
                <h3 class="text-3xl font-bold text-foreground">94%</h3>
                <span class="text-base text-emerald-600 dark:text-emerald-400 font-semibold">Positive</span>
              </div>
            </div>
            <div class="p-2.5 bg-primary/10 rounded-lg text-primary">
              <ThumbsUp class="size-5" />
            </div>
          </div>
          <div class="flex items-center justify-between">
            <div class="flex items-center text-sm font-medium text-emerald-600 dark:text-emerald-400 gap-1">
              <TrendingUp class="size-3.5" />
              <span>+4%</span>
              <span class="text-muted-foreground font-normal ml-1">vs last month</span>
            </div>
            <span class="text-[11.5px] font-medium text-primary hover:underline flex items-center gap-0.5">
              View breakdown <ChevronRight class="size-3" />
            </span>
          </div>
        </div>
      </div>

      <!-- Section 2: Charts & Insights -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Review Trend (Left - 2/3 width) -->
        <div class="bg-card rounded-xl border border-border shadow-sm p-6 lg:col-span-2 flex flex-col">
          <div class="flex justify-between items-center mb-6">
            <div>
              <h3 class="text-base font-semibold text-foreground">Review Trend</h3>
              <p class="text-sm text-muted-foreground">Volume of new reviews over the last 7 months</p>
            </div>
            <DropdownMenu>
              <DropdownMenuTrigger as-child>
                <button type="button" class="h-8 px-2.5 text-[12.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center gap-1.5 shadow-2xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none cursor-pointer">
                  <span>{{ trendTimeframe }}</span>
                  <ChevronDown class="size-3 opacity-50 shrink-0" />
                </button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" class="w-36">
                <DropdownMenuItem @click="trendTimeframe = 'Last 7 Months'">Last 7 Months</DropdownMenuItem>
                <DropdownMenuItem @click="trendTimeframe = 'This Year'">This Year</DropdownMenuItem>
                <DropdownMenuItem @click="trendTimeframe = 'All Time'">All Time</DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
          <div class="h-[250px] w-full mt-auto relative">
            <BarChart :labels="chartLabels" :series="chartSeries" :height="250" :show-y-ticks="false" />
          </div>
        </div>

        <!-- AI Insights (Right - 1/3 width) -->
        <div class="bg-card rounded-xl border border-border shadow-sm p-0 flex flex-col overflow-hidden relative">
          <div class="h-1 w-full bg-primary"></div>
          
          <div class="p-6 flex-1 flex flex-col">
            <div class="flex items-center gap-2 mb-5">
              <div class="p-1.5 bg-primary/10 text-primary rounded-md">
                <Bot class="size-4" />
              </div>
              <h3 class="text-base font-semibold text-foreground">Relay AI Insights</h3>
            </div>
            
            <div class="space-y-4 flex-1">
              <div class="flex gap-3 items-start">
                <div class="mt-0.5 size-2 rounded-full bg-emerald-500 shrink-0"></div>
                <div>
                  <p class="text-sm font-medium text-foreground">Support speed mentioned</p>
                  <p class="text-xs text-muted-foreground mt-0.5">"Fast customer service" appeared in 24% of positive reviews this week.</p>
                </div>
              </div>
              
              <div class="flex gap-3 items-start">
                <div class="mt-0.5 size-2 rounded-full bg-amber-500 shrink-0"></div>
                <div>
                  <p class="text-sm font-medium text-foreground">Action required</p>
                  <p class="text-xs text-muted-foreground mt-0.5">3 recent negative reviews on Yelp have not been responded to.</p>
                </div>
              </div>

              <div class="flex gap-3 items-start">
                <div class="mt-0.5 size-2 rounded-full bg-primary shrink-0"></div>
                <div>
                  <p class="text-sm font-medium text-foreground">Platform growth</p>
                  <p class="text-xs text-muted-foreground mt-0.5">Google reviews are up 15% compared to the previous period.</p>
                </div>
              </div>
            </div>

            <Button variant="outline" class="w-full mt-6 gap-2 bg-primary/5 text-primary border border-primary/20 hover:border-transparent hover:bg-primary/10" @click="handleRequestReviews">
              <Bot class="size-4" /> Generate Review Replies
            </Button>
          </div>
        </div>
      </div>

      <!-- Section 3: Platform Ratings & Quick Actions -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Platform Breakdown -->
        <div class="bg-card rounded-xl border border-border shadow-sm p-6">
          <div class="flex items-center gap-2 mb-6">
            <h3 class="text-base font-semibold text-foreground">Platform Breakdown</h3>
            <Info class="size-4 text-muted-foreground" />
          </div>
          
          <div class="w-full">
            <div class="grid grid-cols-12 gap-2 text-xs font-medium text-muted-foreground mb-4">
              <div class="col-span-3">Platform</div>
              <div class="col-span-4 text-center">Rating</div>
              <div class="col-span-2 text-center">Reviews</div>
              <div class="col-span-3 text-right">Trend</div>
            </div>
            
            <div class="space-y-6">
              <div v-for="platform in platforms" :key="platform.name" class="grid grid-cols-12 gap-2 items-center text-sm">
                <div class="col-span-3 flex items-center gap-2">
                  <div v-html="platform.svgIcon" class="shrink-0 flex items-center justify-center"></div>
                  <span class="font-medium text-foreground">{{ platform.name }}</span>
                </div>
                
                <div class="col-span-4 flex items-center justify-center gap-1.5">
                  <span class="font-bold text-foreground">{{ platform.rating }}</span>
                  <div class="flex gap-0.5 text-amber-500">
                    <Star v-for="i in 5" :key="i" class="size-3.5 fill-amber-500 text-amber-500" />
                  </div>
                </div>
                
                <div class="col-span-2 text-center text-muted-foreground font-medium">
                  {{ platform.total }}
                </div>
                
                <div class="col-span-3 flex justify-end">
                  <svg v-if="platform.trend === 'up'" viewBox="0 0 40 15" class="w-10 h-4 stroke-emerald-500 fill-none" stroke-width="2" stroke-linecap="round"><path d="M0,10 L10,12 L20,5 L30,7 L40,0"></path></svg>
                  <svg v-if="platform.trend === 'down'" viewBox="0 0 40 15" class="w-10 h-4 stroke-destructive fill-none" stroke-width="2" stroke-linecap="round"><path d="M0,5 L10,7 L20,12 L30,10 L40,15"></path></svg>
                </div>
              </div>
            </div>
          </div>
          
          <div class="mt-8">
            <button @click="navigateToIntegrations" class="text-sm font-medium text-primary flex items-center gap-1 hover:underline">
              View all platforms <ArrowRight class="size-3.5" />
            </button>
          </div>
        </div>

        <!-- Quick Actions -->
        <div class="bg-card rounded-xl border border-border shadow-sm p-6">
          <h3 class="text-base font-semibold text-foreground mb-1">Quick Actions</h3>
          <p class="text-sm text-muted-foreground mb-6">Manage your reputation workflow.</p>
          
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <button class="flex items-center gap-3 p-4 border border-border rounded-lg hover:bg-muted/50 transition-colors text-left group" @click="handleRequestReviews">
              <div class="p-2 bg-primary/10 dark:bg-primary/10 text-primary rounded-lg group-hover:scale-110 transition-transform">
                <Mail class="size-5" />
              </div>
              <div>
                <p class="font-medium text-sm text-foreground">Request Reviews</p>
                <p class="text-xs text-muted-foreground">Send email/SMS</p>
              </div>
            </button>
            <button class="flex items-center gap-3 p-4 border border-border rounded-lg hover:bg-muted/50 transition-colors text-left group" @click="router.push('/reviews')">
              <div class="p-2 bg-primary/10 text-primary rounded-lg group-hover:scale-110 transition-transform">
                <MessageSquare class="size-5" />
              </div>
              <div>
                <p class="font-medium text-sm text-foreground">Respond to Feedback</p>
                <p class="text-xs text-muted-foreground">3 pending items</p>
              </div>
            </button>
            <button class="flex items-center gap-3 p-4 border border-border rounded-lg hover:bg-muted/50 transition-colors text-left group" @click="router.push('/reputation/settings')">
              <div class="p-2 bg-primary/10 text-primary rounded-lg group-hover:scale-110 transition-transform">
                <Bot class="size-5" />
              </div>
              <div>
                <p class="font-medium text-sm text-foreground">Automate Replies</p>
                <p class="text-xs text-muted-foreground">Configure AI settings</p>
              </div>
            </button>
            <button class="flex items-center gap-3 p-4 border border-border rounded-lg hover:bg-muted/50 transition-colors text-left group" @click="navigateToIntegrations">
              <div class="p-2 bg-primary/10 text-primary rounded-lg group-hover:scale-110 transition-transform">
                <Link class="size-5" />
              </div>
              <div>
                <p class="font-medium text-sm text-foreground">Connect Platform</p>
                <p class="text-xs text-muted-foreground">Add new integration</p>
              </div>
            </button>
          </div>
        </div>
      </div>

      <!-- Section 4: Recent Reviews -->
      <div class="bg-card rounded-xl border border-border shadow-sm overflow-hidden mb-8">
        <div class="p-6 border-b border-border flex justify-between items-center bg-muted/20">
          <div>
            <h3 class="text-base font-semibold text-foreground">Recent Reviews</h3>
            <p class="text-sm text-muted-foreground">Latest customer feedback across platforms.</p>
          </div>
          <Button variant="ghost" class="text-sm font-medium gap-1 text-primary border border-border hover:border-transparent" @click="router.push('/reviews')">
            View All <ArrowRight class="size-4" />
          </Button>
        </div>
        
        <div class="divide-y divide-border">
          <div v-for="review in recentReviews" :key="review.id" class="p-6 hover:bg-muted/30 transition-colors flex flex-col sm:flex-row gap-5">
            <div class="flex-shrink-0">
              <img :src="review.avatar" alt="Avatar" class="size-10 rounded-full border border-border" />
            </div>
            
            <div class="flex-1">
              <div class="flex flex-col sm:flex-row sm:justify-between sm:items-start gap-2 mb-2">
                <div>
                  <h4 class="font-medium text-sm text-foreground">{{ review.author }}</h4>
                  <div class="flex items-center gap-2 mt-1">
                    <div class="flex gap-0.5 text-amber-500">
                      <Star v-for="i in 5" :key="i" class="size-3.5" :class="i <= review.rating ? 'fill-amber-500' : 'text-muted-foreground/30'" />
                    </div>
                    <span class="text-xs text-muted-foreground flex items-center gap-1">
                      on <span class="font-medium text-foreground">{{ review.platform }}</span> • {{ review.date }}
                    </span>
                  </div>
                </div>
                <Button variant="outline" size="sm" class="h-8 gap-1.5 text-xs font-medium border border-border hover:border-transparent" @click="router.push('/reviews')">
                  <MessageSquare class="size-3.5" />
                  Reply
                </Button>
              </div>
              <p class="text-sm text-muted-foreground leading-relaxed">{{ review.content }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 2. ONBOARDING STATE VIEW -->
    <div v-else-if="currentViewState === 'onboarding'" class="flex-1 flex flex-col items-center justify-center text-center max-w-2xl mx-auto w-full animate-in fade-in zoom-in-95 duration-500 my-auto py-8">
      
      <!-- Icon badge -->
      <div class="size-16 rounded-full bg-primary/10 flex items-center justify-center mb-6 ring-8 ring-primary/5">
        <Star class="size-8 text-primary" />
      </div>

      <!-- Heading & Description -->
      <h2 class="text-base font-medium tracking-tight text-foreground mb-2">Connect a Review Platform to Start Monitoring</h2>
      <p class="text-muted-foreground mb-8 text-sm max-w-lg">
        Stop switching between review sites. Connect your Google, Yelp, and Facebook profiles and let Relay AI monitor ratings and draft replies automatically.
      </p>

      <!-- Getting Started Progress -->
      <div class="w-full max-w-3xl bg-card/50 border border-border/50 rounded-xl p-5 mb-8 text-left shadow-sm backdrop-blur-sm relative overflow-hidden mx-auto">
        <!-- Decorative background gradient -->
        <div class="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full blur-2xl -translate-y-1/2 translate-x-1/4"></div>
        
        <h3 class="text-sm font-semibold text-foreground mb-4 flex items-center justify-between">
          Getting Started 
          <span class="text-[10px] font-medium text-primary bg-primary/10 px-2 py-0.5 rounded-full tracking-wide uppercase">Step 3 of 4</span>
        </h3>
        <div class="flex flex-col relative ml-1">
          <!-- Connecting line -->
          <div class="absolute left-[11px] top-3 bottom-3 w-px bg-border z-0"></div>
          
          <!-- Step 1 -->
          <div class="flex items-center gap-4 py-2.5 z-10">
            <div class="size-[22px] rounded-full bg-primary flex items-center justify-center shrink-0 ring-4 ring-card">
              <Check class="size-3 text-primary-foreground" />
            </div>
            <span class="text-sm font-medium text-muted-foreground line-through">Create Workspace</span>
          </div>
          
          <!-- Step 2 -->
          <div class="flex items-center gap-4 py-2.5 z-10">
            <div class="size-[22px] rounded-full bg-primary flex items-center justify-center shrink-0 ring-4 ring-card">
              <Check class="size-3 text-primary-foreground" />
            </div>
            <span class="text-sm font-medium text-muted-foreground line-through">Import Contacts</span>
          </div>

          <!-- Step 3 (Active) -->
          <div class="flex items-center gap-4 py-2.5 z-10">
            <div class="size-[22px] rounded-full border-2 border-primary bg-card flex items-center justify-center shrink-0 ring-4 ring-card shadow-sm shadow-primary/20">
              <div class="size-1.5 rounded-full bg-primary animate-pulse"></div>
            </div>
            <span class="text-sm font-semibold text-foreground">Connect Review Platform</span>
          </div>

          <!-- Step 4 -->
          <div class="flex items-center gap-4 py-2.5 z-10 opacity-60 hover:opacity-100 transition-opacity">
            <div class="size-[22px] rounded-full border-2 border-muted-foreground/30 bg-card flex items-center justify-center shrink-0 ring-4 ring-card transition-colors">
            </div>
            <span class="text-sm font-medium text-foreground transition-colors">First Review Received</span>
          </div>
        </div>
      </div>

      <!-- Integration Cards (2x2 Grid) -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 w-full mb-8 text-left">
        <!-- Google Business -->
        <div class="group flex items-center gap-4 p-3 border border-border/60 bg-card rounded-xl shadow-sm hover:border-border transition-all">
          <div class="size-10 rounded-lg bg-muted/30 border border-border flex items-center justify-center shrink-0 p-2">
            <svg viewBox="0 0 24 24" class="size-5" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>
          </div>
          <div class="flex flex-col flex-1 min-w-0">
            <span class="font-semibold text-sm text-foreground truncate">Google Business</span>
            <span class="text-[13px] text-muted-foreground truncate mt-0.5">Maps & Search ratings</span>
          </div>
          <Button variant="outline" size="sm" class="h-8 px-4 text-[13px] font-medium bg-background shadow-xs shrink-0 border border-border hover:border-transparent" @click="navigateToIntegrations">Connect</Button>
        </div>

        <!-- Yelp for Business -->
        <div class="group flex items-center gap-4 p-3 border border-border/60 bg-card rounded-xl shadow-sm hover:border-border transition-all">
          <div class="size-10 rounded-lg bg-muted/30 border border-border flex items-center justify-center shrink-0 p-2">
            <svg viewBox="0 0 24 24" class="size-5" xmlns="http://www.w3.org/2000/svg" fill="#E00707"><path d="M12.271 8.782c-.549-3.804-.822-5.72-.822-5.748 0-.888-.622-1.641-1.537-1.887A2.34 2.34 0 0 0 7.3 2.52L3.473 7.337a2.01 2.01 0 0 0-.302 1.895c.28.72.934 1.218 1.695 1.282l5.894.488c1.038.087 1.871-.767 1.511-2.22zm-8.245 6.253l5.374 2.186c1.004.409 2.084-.332 2.084-1.41V11.38c0-1.088-1.096-1.83-2.104-1.41l-5.374 2.185a1.85 1.85 0 0 0-1.148 1.44 1.855 1.855 0 0 0 1.168 1.44zm6.406 5.978l-3.218-4.874a1.796 1.796 0 0 0-2.97-.095 1.855 1.855 0 0 0-.17 1.98l2.28 4.374a2.316 2.316 0 0 0 2.492 1.208 2.302 2.302 0 0 0 1.586-2.593zm9.56-10.826a2.31 2.31 0 0 0-1.92-1.435l-5.916-.489a1.796 1.796 0 0 0-1.493 2.874l3.42 4.96a1.803 1.803 0 0 0 2.8.217l3.477-4.046a2.02 2.02 0 0 0 .368-.654 2.004 2.004 0 0 0-.736-1.427zm-2.278 7.916l-2.277-4.373a1.804 1.804 0 0 0-3.124.149 1.789 1.789 0 0 0 .057 1.695l3.218 4.874a2.305 2.305 0 0 0 2.534.938 2.316 2.316 0 0 0 1.57-2.593 2.31 2.31 0 0 0-1.978-0.69z"/></svg>
          </div>
          <div class="flex flex-col flex-1 min-w-0">
            <span class="font-semibold text-sm text-foreground truncate">Yelp for Business</span>
            <span class="text-[13px] text-muted-foreground truncate mt-0.5">Local customer reviews</span>
          </div>
          <Button variant="outline" size="sm" class="h-8 px-4 text-[13px] font-medium bg-background shadow-xs shrink-0 border border-border hover:border-transparent" @click="navigateToIntegrations">Connect</Button>
        </div>

        <!-- Facebook Pages -->
        <div class="group flex items-center gap-4 p-3 border border-border/60 bg-card rounded-xl shadow-sm hover:border-border transition-all">
          <div class="size-10 rounded-lg bg-muted/30 border border-border flex items-center justify-center shrink-0 p-2">
            <svg viewBox="0 0 24 24" class="size-5" xmlns="http://www.w3.org/2000/svg"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" fill="#1877F2"/></svg>
          </div>
          <div class="flex flex-col flex-1 min-w-0">
            <span class="font-semibold text-sm text-foreground truncate">Facebook Pages</span>
            <span class="text-[13px] text-muted-foreground truncate mt-0.5">Page recommendations</span>
          </div>
          <Button variant="outline" size="sm" class="h-8 px-4 text-[13px] font-medium bg-background shadow-xs shrink-0 border border-border hover:border-transparent" @click="navigateToIntegrations">Connect</Button>
        </div>

        <!-- Trustpilot -->
        <div class="group flex items-center gap-4 p-3 border border-border/60 bg-card rounded-xl shadow-sm hover:border-border transition-all">
          <div class="size-10 rounded-lg bg-muted/30 border border-border flex items-center justify-center shrink-0 p-2">
            <svg viewBox="0 0 24 24" class="size-5" xmlns="http://www.w3.org/2000/svg"><rect width="24" height="24" fill="#00B67A" rx="2" ry="2"/><path d="M12 4l2.5 5.2 5.7.8-4.1 4 1 5.7-5.1-2.7-5.1 2.7 1-5.7-4.1-4 5.7-.8L12 4z" fill="#FFF"/></svg>
          </div>
          <div class="flex flex-col flex-1 min-w-0">
            <span class="font-semibold text-sm text-foreground truncate">Trustpilot</span>
            <span class="text-[13px] text-muted-foreground truncate mt-0.5">Verified review ratings</span>
          </div>
          <Button variant="outline" size="sm" class="h-8 px-4 text-[13px] font-medium bg-background shadow-xs shrink-0 border border-border hover:border-transparent" @click="navigateToIntegrations">Connect</Button>
        </div>
      </div>

      <!-- Supported Channels Pill -->
      <div class="flex items-center gap-5 px-5 py-2.5 bg-card rounded-full border border-border/50 shadow-xs opacity-80 mb-8">
        <span class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider mr-1">Supported Channels:</span>
        <div class="flex items-center gap-1.5">
          <Star class="size-4 text-amber-500" />
          <span class="text-[13px] font-medium text-foreground">TripAdvisor</span>
        </div>
        <div class="flex items-center gap-1.5">
          <Globe class="size-4 text-primary" />
          <span class="text-[13px] font-medium text-foreground">Apple Maps</span>
        </div>
        <div class="flex items-center gap-1.5 hidden sm:flex">
          <ShieldCheck class="size-4 text-primary" />
          <span class="text-[13px] font-medium text-foreground">BBB</span>
        </div>
      </div>

      <!-- Footer Action Controls -->
      <div class="flex flex-col sm:flex-row items-center gap-4">
        <button class="text-sm font-medium text-primary hover:underline flex items-center gap-1.5 transition-colors" @click="navigateToIntegrations">
          <Lightbulb class="size-4" />
          Learn how Reputation works
        </button>

        <Button variant="ghost" class="border border-border hover:border-transparent shadow-xs gap-2 text-[13px]" @click="currentViewState = 'working'">
          Explore Demo Dashboard
        </Button>

        <Button variant="ghost" class="border border-border hover:border-transparent shadow-xs gap-2 text-[13px]" @click="currentViewState = 'empty'">
          Toggle empty states
        </Button>
      </div>
    </div>

    <!-- 3. EMPTY STATE VIEW -->
    <div v-else-if="currentViewState === 'empty'" class="flex flex-col min-h-[calc(100vh-10rem)] w-full justify-center py-8">
      <PremiumEmptyState
        :icon="Trophy"
        title="No Reputation Data Yet"
        description="Your review channels are connected, but there are no reviews or ratings recorded yet. Send your first review outreach campaign or connect additional platforms to begin tracking reputation metrics."
        primaryAction="Request Reviews"
        secondaryAction="Connect Platforms"
        integrationsTitle="Supported Review Platforms"
        :integrations="emptyStateIntegrations"
        demoAction="Load Demo Dashboard"
        demoLink="Need help collecting reviews?"
        @primary-click="handleRequestReviews"
        @secondary-click="navigateToIntegrations"
        @demo-click="currentViewState = 'working'"
      />

      <!-- Developer button at bottom of empty state to toggle mock data -->
      <div class="mt-8 pt-4 border-t border-border flex items-center justify-center gap-3">
        <Button 
          variant="outline" 
          size="sm" 
          class="border border-border hover:border-transparent text-[12.5px] text-muted-foreground"
          @click="currentViewState = 'working'"
        >
          Developer Preview: Load Demo Data
        </Button>
        <Button 
          variant="ghost" 
          size="sm" 
          class="border border-border hover:border-transparent text-[12.5px] text-muted-foreground"
          @click="currentViewState = 'onboarding'"
        >
          Preview Onboarding State
        </Button>
      </div>
    </div>

    <!-- Floating Developer State Switcher Toolbar -->
    <div class="fixed bottom-5 right-6 z-40 flex items-center gap-1.5 p-1.5 bg-card/95 backdrop-blur-md border border-border rounded-full shadow-lg">
      <span class="text-[11px] font-medium text-muted-foreground px-2">State:</span>
      <button
        v-for="s in [
          { id: 'working', label: 'Working' },
          { id: 'onboarding', label: 'Onboarding' },
          { id: 'empty', label: 'Empty' }
        ]"
        :key="s.id"
        @click="currentViewState = (s.id as any)"
        :class="[
          'px-3 py-1 text-[12px] font-medium rounded-full transition-colors',
          currentViewState === s.id
            ? 'bg-primary text-primary-foreground shadow-xs'
            : 'text-muted-foreground hover:text-foreground hover:bg-muted/60'
        ]"
      >
        {{ s.label }}
      </button>
    </div>
  </div>
</template>
