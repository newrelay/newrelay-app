<script setup lang="ts">
import { ref } from 'vue'
import {
  Settings, Bell, Bot, Shield, Sliders, 
  Code, Copy, Check, Save, Sparkles, Star,
  AlertTriangle, Mail, Globe, MessageSquare, ExternalLink, ChevronDown
} from 'lucide-vue-next'
import { 
  Button, Input, Badge, Switch,
  DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem
} from '@/components/ui'
import PremiumEmptyState from '@/components/layout/PremiumEmptyState.vue'

// Dropdown label helpers
const toneLabels: Record<string, string> = {
  Friendly: 'Friendly & Enthusiastic',
  Professional: 'Professional & Courteous',
  Warm: 'Warm & Grateful',
  Concise: 'Concise & Direct'
}

const delayLabels: Record<string, string> = {
  '5_mins': '5 minutes',
  '15_mins': '15 minutes (Recommended)',
  '1_hour': '1 hour',
  immediate: 'Immediate'
}

const thresholdLabels: Record<string, string> = {
  '4': '4 Stars & Above (Allow 4 and 5 stars to public sites)',
  '5': '5 Stars Only (Strict 5-star gating)'
}

// State
const isDemoLoaded = ref(true)
const isSaved = ref(false)
const copiedSnippet = ref(false)

// Form Settings
const settings = ref({
  // Notifications
  notifyOnNegative: true,
  notifyOnNewReview: true,
  dailyDigest: true,
  alertEmail: 'operations@mycompany.com',
  alertThreshold: '3',

  // Review Gating
  enableSmartRouting: true,
  positiveThreshold: '4',
  negativeRedirectUrl: 'https://mycompany.com/support/contact',

  // Relay AI Auto-Responder
  aiAutoDraft: true,
  aiAutoPublish5Star: true,
  aiTone: 'Friendly',
  aiDelay: '15_mins',
  includeCustomerName: true,

  // Branding & URLs
  customDomain: 'reviews.mycompany.com',
  businessDisplayName: 'My Brand HQ',
  primaryDestination: 'google',
  secondaryDestination: 'facebook'
})

// Widget Embed Snippet
const widgetSnippet = `<script src="https://cdn.newrelay.com/widgets/reputation-badge.js" data-site-id="nr_847291" async><\/script>`

function handleSave() {
  isSaved.value = true
  setTimeout(() => {
    isSaved.value = false
  }, 2500)
}

function copyCode() {
  navigator.clipboard.writeText(widgetSnippet)
  copiedSnippet.value = true
  setTimeout(() => {
    copiedSnippet.value = false
  }, 2000)
}
</script>

<template>
  <div class="flex-1 overflow-y-auto w-full hide-scrollbar bg-background p-6 lg:p-8">
    <!-- Populated State -->
    <div v-if="isDemoLoaded" class="max-w-5xl mx-auto space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-border/60">
        <div>
          <h1 class="text-base font-medium tracking-tight text-foreground">Reputation Settings</h1>
          <p class="text-[13.5px] text-muted-foreground mt-0.5">Manage review gating, Relay AI auto-responder policies, alerts, and website embed widgets.</p>
        </div>
        <div class="flex items-center gap-3">
          <Button 
            variant="outline" 
            class="gap-2 border border-border hover:border-transparent text-[13.5px]" 
            @click="isDemoLoaded = false"
          >
            Preview Empty State
          </Button>
          <Button class="gap-2 shadow-xs text-[13.5px]" @click="handleSave">
            <Check v-if="isSaved" class="size-4 text-emerald-500" />
            <Save v-else class="size-4" />
            {{ isSaved ? 'Saved!' : 'Save Changes' }}
          </Button>
        </div>
      </div>

      <!-- Settings Sections -->
      <div class="space-y-6">
        <!-- Section 1: Relay AI Auto-Responder -->
        <div class="bg-card rounded-xl border border-border p-6 shadow-xs space-y-5">
          <div class="flex items-start justify-between gap-3 border-b border-border pb-4">
            <div class="flex items-center gap-3">
              <div class="p-2 rounded-lg bg-primary/10 text-primary">
                <Bot class="size-5" />
              </div>
              <div>
                <h2 class="text-[15px] font-semibold text-foreground">Relay AI Auto-Responder</h2>
                <p class="text-[13px] text-muted-foreground">Automate instant personalized replies to customer reviews across connected platforms.</p>
              </div>
            </div>
            <Badge variant="outline" class="text-[11px] gap-1 py-0.5 border-primary/30 text-primary">
              <Sparkles class="size-3" />
              Relay AI Powered
            </Badge>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-5 text-[13.5px]">
            <div class="flex items-center justify-between p-4 rounded-lg bg-muted/40 border border-border">
              <div>
                <div class="font-medium text-foreground">Auto-Draft Smart Replies</div>
                <div class="text-[12px] text-muted-foreground">Pre-generate suggested responses for agent review</div>
              </div>
              <Switch v-model:checked="settings.aiAutoDraft" />
            </div>

            <div class="flex items-center justify-between p-4 rounded-lg bg-muted/40 border border-border">
              <div>
                <div class="font-medium text-foreground">Auto-Publish for 5-Star Reviews</div>
                <div class="text-[12px] text-muted-foreground">Instantly post verified grateful replies to glowing reviews</div>
              </div>
              <Switch v-model:checked="settings.aiAutoPublish5Star" />
            </div>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">AI Response Tone</label>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <button type="button" class="h-9 px-3 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between shadow-2xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none w-full text-left cursor-pointer">
                    <span class="truncate">{{ toneLabels[settings.aiTone] || settings.aiTone }}</span>
                    <ChevronDown class="size-3.5 opacity-50 ml-2 shrink-0" />
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="w-[280px]" align="start">
                  <DropdownMenuItem @click="settings.aiTone = 'Friendly'">Friendly & Enthusiastic</DropdownMenuItem>
                  <DropdownMenuItem @click="settings.aiTone = 'Professional'">Professional & Courteous</DropdownMenuItem>
                  <DropdownMenuItem @click="settings.aiTone = 'Warm'">Warm & Grateful</DropdownMenuItem>
                  <DropdownMenuItem @click="settings.aiTone = 'Concise'">Concise & Direct</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Natural Response Delay</label>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <button type="button" class="h-9 px-3 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between shadow-2xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none w-full text-left cursor-pointer">
                    <span class="truncate">{{ delayLabels[settings.aiDelay] || settings.aiDelay }}</span>
                    <ChevronDown class="size-3.5 opacity-50 ml-2 shrink-0" />
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="w-[280px]" align="start">
                  <DropdownMenuItem @click="settings.aiDelay = '5_mins'">5 minutes</DropdownMenuItem>
                  <DropdownMenuItem @click="settings.aiDelay = '15_mins'">15 minutes (Recommended)</DropdownMenuItem>
                  <DropdownMenuItem @click="settings.aiDelay = '1_hour'">1 hour</DropdownMenuItem>
                  <DropdownMenuItem @click="settings.aiDelay = 'immediate'">Immediate</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>
        </div>

        <!-- Section 2: Smart Review Gating & Sentiment Routing -->
        <div class="bg-card rounded-xl border border-border p-6 shadow-xs space-y-5">
          <div class="flex items-center gap-3 border-b border-border pb-4">
            <div class="p-2 rounded-lg bg-primary/10 text-primary">
              <Shield class="size-5" />
            </div>
            <div>
              <h2 class="text-[15px] font-semibold text-foreground">Smart Review Gating & Sentiment Routing</h2>
              <p class="text-[13px] text-muted-foreground">Protect brand reputation by directing unhappy customers to an internal private feedback channel.</p>
            </div>
          </div>

          <div class="flex items-center justify-between p-4 rounded-lg bg-muted/40 border border-border">
            <div>
              <div class="font-medium text-foreground">Enable Smart Sentiment Filtering</div>
              <div class="text-[12px] text-muted-foreground">Redirect scores below the threshold to a private support resolution ticket instead of public sites</div>
            </div>
            <Switch v-model:checked="settings.enableSmartRouting" />
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Public Review Threshold</label>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <button type="button" class="h-9 px-3 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between shadow-2xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none w-full text-left cursor-pointer">
                    <span class="truncate">{{ thresholdLabels[settings.positiveThreshold] || settings.positiveThreshold }}</span>
                    <ChevronDown class="size-3.5 opacity-50 ml-2 shrink-0" />
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="w-[360px]" align="start">
                  <DropdownMenuItem @click="settings.positiveThreshold = '4'">4 Stars & Above (Allow 4 and 5 stars to public sites)</DropdownMenuItem>
                  <DropdownMenuItem @click="settings.positiveThreshold = '5'">5 Stars Only (Strict 5-star gating)</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Private Resolution Form URL</label>
              <Input 
                v-model="settings.negativeRedirectUrl"
                placeholder="https://mycompany.com/feedback"
                class="h-9 text-[14px]"
              />
            </div>
          </div>
        </div>

        <!-- Section 3: Notification Alerts -->
        <div class="bg-card rounded-xl border border-border p-6 shadow-xs space-y-5">
          <div class="flex items-center gap-3 border-b border-border pb-4">
            <div class="p-2 rounded-lg bg-primary/10 text-primary">
              <Bell class="size-5" />
            </div>
            <div>
              <h2 class="text-[15px] font-semibold text-foreground">Notification & Alert Preferences</h2>
              <p class="text-[13px] text-muted-foreground">Stay informed whenever new customer reviews or critical negative feedback are submitted.</p>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="flex items-center justify-between p-3.5 rounded-lg bg-muted/40 border border-border">
              <div>
                <div class="font-medium text-[13.5px] text-foreground">Immediate Negative Review Alert</div>
                <div class="text-[12px] text-muted-foreground">Alert assigned team when rating is ≤ 3 stars</div>
              </div>
              <Switch v-model:checked="settings.notifyOnNegative" />
            </div>

            <div class="flex items-center justify-between p-3.5 rounded-lg bg-muted/40 border border-border">
              <div>
                <div class="font-medium text-[13.5px] text-foreground">Daily Performance Digest</div>
                <div class="text-[12px] text-muted-foreground">Receive daily summary of new reviews & sentiment</div>
              </div>
              <Switch v-model:checked="settings.dailyDigest" />
            </div>
          </div>

          <div class="flex flex-col sm:flex-row gap-4 pt-1">
            <div class="flex-1 flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Alert Notification Email</label>
              <Input 
                v-model="settings.alertEmail"
                type="email"
                class="h-9 text-[14px]"
              />
            </div>
          </div>
        </div>

        <!-- Section 4: Website Rating Badge & Widgets -->
        <div class="bg-card rounded-xl border border-border p-6 shadow-xs space-y-4">
          <div class="flex items-center justify-between border-b border-border pb-4">
            <div class="flex items-center gap-3">
              <div class="p-2 rounded-lg bg-primary/10 text-primary">
                <Code class="size-5" />
              </div>
              <div>
                <h2 class="text-[15px] font-semibold text-foreground">Website Trust Badge Embed</h2>
                <p class="text-[13px] text-muted-foreground">Embed a live synchronized rating badge on your website header or footer.</p>
              </div>
            </div>
            <Button 
              variant="outline" 
              size="sm" 
              class="border border-border hover:border-transparent gap-1.5 text-[12.5px]"
              @click="copyCode"
            >
              <Check v-if="copiedSnippet" class="size-3.5 text-emerald-500" />
              <Copy v-else class="size-3.5" />
              {{ copiedSnippet ? 'Copied Snippet' : 'Copy Code' }}
            </Button>
          </div>

          <div class="p-3 bg-muted rounded-lg font-mono text-[12.5px] text-foreground overflow-x-auto select-all">
            {{ widgetSnippet }}
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State View -->
    <div v-else class="flex flex-col min-h-[calc(100vh-10rem)] w-full">
      <PremiumEmptyState
        :icon="Settings"
        title="No Reputation Settings Configured"
        description="Configure your review preferences, Relay AI auto-responder policies, alerts, and website embed widgets."
        primaryAction="Initialize Default Settings"
        secondaryAction="View Documentation"
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
  </div>
</template>
