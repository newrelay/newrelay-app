<script setup lang="ts">
import { ref, computed } from 'vue'
import {
  Send, Mail, MessageSquare, MessageCircle, Smartphone, 
  Search, Filter, Plus, RefreshCw, CheckCircle2, Clock, 
  ArrowUpRight, Users, Play, Pause, MoreHorizontal, Check, 
  ChevronRight, ChevronDown, ChevronLeft, Sparkles, ExternalLink, Calendar, Star,
  TrendingUp, AlertCircle, Eye, QrCode,
  Copy, Link, Shield, ShieldAlert, Bot, Sliders, Download,
  Layers, CheckCheck, HelpCircle, Phone, ArrowRight, X,
  Trash2, UserX, AlertTriangle, FileText, Printer, Share2,
  Signal, Wifi, Archive, MoreVertical, Video, Smile, Paperclip, Mic, Info,
  LayoutTemplate, Bookmark
} from 'lucide-vue-next'
import { 
  Button, Input, Badge, Switch,
  DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator
} from '@/components/ui'
import PremiumEmptyState from '@/components/layout/PremiumEmptyState.vue'
import RequestReviewsModal from './components/RequestReviewsModal.vue'

// Dropdown label helpers
const destinationLabels: Record<string, string> = {
  google: 'Google Business Profile (Direct Review Pop-up)',
  smart: 'Smart Multi-Platform Landing Page (Google, Yelp, Facebook)',
  yelp: 'Yelp Business Page',
  trustpilot: 'Trustpilot Verified Portal'
}

const aiFollowUpLabels: Record<string, string> = {
  '24_hours': '24 hours later',
  '48_hours': '48 hours later (Recommended)',
  '72_hours': '72 hours later'
}

// State
const isDemoLoaded = ref(true)
const isRequestModalOpen = ref(false)
const activeTab = ref<'channels' | 'qr_link' | 'ai_outreach' | 'spam_shield'>('channels')

// Link & Copy State
const reviewUrl = ref('https://relay.to/r/apex-dental')
const isLinkCopied = ref(false)
const selectedDestination = ref('google')
const customSlug = ref('apex-dental')

// Channel Templates State
const selectedChannel = ref<'sms' | 'email' | 'whatsapp' | 'video'>('sms')
const previewDevice = ref<'mobile' | 'email'>('mobile')
const isTestSent = ref(false)
const isAiEnhancing = ref(false)
const availableTags = ['{{FirstName}}', '{{BusinessName}}', '{{ReviewLink}}', '{{EmployeeName}}']

import {
  type SmsTemplateItem,
  type EmailTemplateItem,
  type WhatsAppTemplateItem,
  type VideoTemplateItem,
  defaultSmsTemplates,
  defaultEmailTemplates,
  defaultWhatsAppTemplates,
  defaultVideoTemplates
} from './data/outreachTemplates'

export type { SmsTemplateItem, EmailTemplateItem, WhatsAppTemplateItem, VideoTemplateItem }

// 1. Prebuilt SMS Templates
const prebuiltSmsTemplates = ref<SmsTemplateItem[]>([...defaultSmsTemplates])

// 2. Prebuilt Email Templates
const prebuiltEmailTemplates = ref<EmailTemplateItem[]>([...defaultEmailTemplates])

// 3. Prebuilt WhatsApp Templates
const prebuiltWhatsAppTemplates = ref<WhatsAppTemplateItem[]>([...defaultWhatsAppTemplates])

// 4. Prebuilt Video Testimonial Templates
const prebuiltVideoTemplates = ref<VideoTemplateItem[]>([...defaultVideoTemplates])

const selectedSmsTemplateId = ref('sms_post_visit')
const selectedEmailTemplateId = ref('email_standard_5star')
const selectedWhatsAppTemplateId = ref('wa_friendly_checkin')
const selectedVideoTemplateId = ref('video_standard_request')

const currentActiveTemplate = computed(() => {
  if (selectedChannel.value === 'sms') {
    return prebuiltSmsTemplates.value.find(t => t.id === selectedSmsTemplateId.value) || prebuiltSmsTemplates.value[0]
  } else if (selectedChannel.value === 'email') {
    return prebuiltEmailTemplates.value.find(t => t.id === selectedEmailTemplateId.value) || prebuiltEmailTemplates.value[0]
  } else if (selectedChannel.value === 'whatsapp') {
    return prebuiltWhatsAppTemplates.value.find(t => t.id === selectedWhatsAppTemplateId.value) || prebuiltWhatsAppTemplates.value[0]
  } else {
    return prebuiltVideoTemplates.value.find(t => t.id === selectedVideoTemplateId.value) || prebuiltVideoTemplates.value[0]
  }
})

const currentChannelTemplatesList = computed(() => {
  if (selectedChannel.value === 'sms') return prebuiltSmsTemplates.value
  if (selectedChannel.value === 'email') return prebuiltEmailTemplates.value
  if (selectedChannel.value === 'whatsapp') return prebuiltWhatsAppTemplates.value
  return prebuiltVideoTemplates.value
})

const currentActiveTemplateId = computed(() => {
  if (selectedChannel.value === 'sms') return selectedSmsTemplateId.value
  if (selectedChannel.value === 'email') return selectedEmailTemplateId.value
  if (selectedChannel.value === 'whatsapp') return selectedWhatsAppTemplateId.value
  return selectedVideoTemplateId.value
})

const isCreateTemplateModalOpen = ref(false)
const newTemplateForm = ref({
  channel: 'sms' as 'sms' | 'email' | 'whatsapp' | 'video',
  name: '',
  // SMS fields
  smsMessage: '',
  smsAutoDelay: '2 hours post-visit',
  // Email fields
  emailSubject: '',
  emailPreheader: '',
  emailHeading: 'Thank you for your visit, {{FirstName}}!',
  emailBody: '',
  emailButtonText: 'Rate Us on Google ★★★★★',
  emailAutoDelay: '4 hours post-service (Recommended)',
  // WhatsApp fields
  waHeader: 'Hi {{FirstName}} 👋',
  waBody: '',
  waButton1: '⭐ Leave a 5★ Review',
  waButton2: '💬 Talk with Support',
  waAutoDelay: 'Immediately post-visit',
  // Video fields
  videoHeadline: 'Share Your Story with {{BusinessName}}',
  videoMessage: '',
  videoQuestions: '1. What problem did you want to solve?\n2. How did we help you?\n3. Would you recommend us to others?',
  videoButtonText: 'Record Video Testimonial 🎥',
  videoMaxDuration: '60 Seconds (Recommended)',
  videoAutoDelay: '2 hours post-visit'
})

const applyTemplate = (template: any, channel?: 'sms' | 'email' | 'whatsapp' | 'video') => {
  const targetChannel = channel || selectedChannel.value
  if (targetChannel === 'sms') {
    selectedSmsTemplateId.value = template.id
    smsTemplate.value.message = template.message
    smsTemplate.value.autoDelay = template.autoDelay
  } else if (targetChannel === 'email') {
    selectedEmailTemplateId.value = template.id
    emailTemplate.value.subject = template.subject
    emailTemplate.value.preheader = template.preheader
    emailTemplate.value.heading = template.heading || emailTemplate.value.heading
    emailTemplate.value.body = template.body
    emailTemplate.value.buttonText = template.buttonText
    emailTemplate.value.autoDelay = template.autoDelay
  } else if (targetChannel === 'whatsapp') {
    selectedWhatsAppTemplateId.value = template.id
    whatsappTemplate.value.headerText = template.headerText
    whatsappTemplate.value.bodyText = template.bodyText
    whatsappTemplate.value.button1 = template.button1
    whatsappTemplate.value.button2 = template.button2
    whatsappTemplate.value.autoDelay = template.autoDelay
  } else if (targetChannel === 'video') {
    selectedVideoTemplateId.value = template.id
    videoTemplate.value.headline = template.headline
    videoTemplate.value.message = template.message
    videoTemplate.value.questions = Array.isArray(template.questions) ? template.questions.join('\n') : template.questions
    videoTemplate.value.buttonText = template.buttonText
    videoTemplate.value.maxDuration = template.maxDuration
    videoTemplate.value.autoDelay = template.autoDelay
  }
}

const openCreateTemplateModal = (channel?: 'sms' | 'email' | 'whatsapp' | 'video') => {
  const target = channel || selectedChannel.value
  newTemplateForm.value = {
    channel: target,
    name: '',
    smsMessage: smsTemplate.value.message || 'Hi {{FirstName}}, thank you for choosing {{BusinessName}}! Would you mind sharing your experience? ⭐ Leave a quick review here: {{ReviewLink}}',
    smsAutoDelay: smsTemplate.value.autoDelay || '2 hours post-visit',
    emailSubject: emailTemplate.value.subject || 'How was your experience with {{BusinessName}}?',
    emailPreheader: emailTemplate.value.preheader || 'We value your feedback. Take 30 seconds to rate us.',
    emailHeading: emailTemplate.value.heading || 'Thank you for your visit, {{FirstName}}!',
    emailBody: emailTemplate.value.body || 'We strive to provide the best service possible. Could you take a moment to leave us an honest review on Google?',
    emailButtonText: emailTemplate.value.buttonText || 'Rate Us on Google ★★★★★',
    emailAutoDelay: emailTemplate.value.autoDelay || '4 hours post-service (Recommended)',
    waHeader: whatsappTemplate.value.headerText || 'Hi {{FirstName}} 👋',
    waBody: whatsappTemplate.value.bodyText || 'Thank you for visiting {{BusinessName}} today! We would love to hear your feedback. Tap below to share a quick 5-star review.',
    waButton1: whatsappTemplate.value.button1 || '⭐ Leave a 5★ Review',
    waButton2: whatsappTemplate.value.button2 || '💬 Talk with Support',
    waAutoDelay: whatsappTemplate.value.autoDelay || 'Immediately post-visit',
    videoHeadline: videoTemplate.value.headline || 'Share Your Story with {{BusinessName}}',
    videoMessage: videoTemplate.value.message || 'Hi {{FirstName}}, could you take 45 seconds to record a quick video review sharing your experience?',
    videoQuestions: videoTemplate.value.questions || '1. What problem did you have?\n2. How did we help you?\n3. Would you recommend us?',
    videoButtonText: videoTemplate.value.buttonText || 'Record Video Testimonial 🎥',
    videoMaxDuration: videoTemplate.value.maxDuration || '60 Seconds (Recommended)',
    videoAutoDelay: videoTemplate.value.autoDelay || '2 hours post-visit'
  }
  isCreateTemplateModalOpen.value = true
}

const isCreateTemplateValid = computed(() => {
  if (!newTemplateForm.value.name.trim()) return false
  if (newTemplateForm.value.channel === 'sms') {
    return !!newTemplateForm.value.smsMessage.trim()
  } else if (newTemplateForm.value.channel === 'email') {
    return !!newTemplateForm.value.emailSubject.trim() && !!newTemplateForm.value.emailBody.trim()
  } else if (newTemplateForm.value.channel === 'whatsapp') {
    return !!newTemplateForm.value.waHeader.trim() && !!newTemplateForm.value.waBody.trim() && !!newTemplateForm.value.waButton1.trim()
  } else {
    return !!newTemplateForm.value.videoHeadline.trim() && !!newTemplateForm.value.videoMessage.trim()
  }
})

const handleCreateTemplate = () => {
  if (!isCreateTemplateValid.value) return
  const chan = newTemplateForm.value.channel
  const customId = `${chan}_custom_${Date.now()}`

  if (chan === 'sms') {
    const newTpl: SmsTemplateItem = {
      id: customId,
      name: newTemplateForm.value.name.trim(),
      message: newTemplateForm.value.smsMessage.trim(),
      autoDelay: newTemplateForm.value.smsAutoDelay,
      isCustom: true
    }
    prebuiltSmsTemplates.value.unshift(newTpl)
    selectedChannel.value = 'sms'
    applyTemplate(newTpl, 'sms')
  } else if (chan === 'email') {
    const newTpl: EmailTemplateItem = {
      id: customId,
      name: newTemplateForm.value.name.trim(),
      subject: newTemplateForm.value.emailSubject.trim(),
      preheader: newTemplateForm.value.emailPreheader.trim(),
      heading: newTemplateForm.value.emailHeading.trim(),
      body: newTemplateForm.value.emailBody.trim(),
      buttonText: newTemplateForm.value.emailButtonText.trim(),
      autoDelay: newTemplateForm.value.emailAutoDelay,
      isCustom: true
    }
    prebuiltEmailTemplates.value.unshift(newTpl)
    selectedChannel.value = 'email'
    applyTemplate(newTpl, 'email')
  } else if (chan === 'whatsapp') {
    const newTpl: WhatsAppTemplateItem = {
      id: customId,
      name: newTemplateForm.value.name.trim(),
      headerText: newTemplateForm.value.waHeader.trim(),
      bodyText: newTemplateForm.value.waBody.trim(),
      button1: newTemplateForm.value.waButton1.trim(),
      button2: newTemplateForm.value.waButton2.trim(),
      autoDelay: newTemplateForm.value.waAutoDelay,
      isCustom: true
    }
    prebuiltWhatsAppTemplates.value.unshift(newTpl)
    selectedChannel.value = 'whatsapp'
    applyTemplate(newTpl, 'whatsapp')
  } else if (chan === 'video') {
    const newTpl: VideoTemplateItem = {
      id: customId,
      name: newTemplateForm.value.name.trim(),
      headline: newTemplateForm.value.videoHeadline.trim(),
      message: newTemplateForm.value.videoMessage.trim(),
      questions: newTemplateForm.value.videoQuestions.split('\n').filter(Boolean),
      buttonText: newTemplateForm.value.videoButtonText.trim(),
      maxDuration: newTemplateForm.value.videoMaxDuration,
      autoDelay: newTemplateForm.value.videoAutoDelay,
      isCustom: true
    }
    prebuiltVideoTemplates.value.unshift(newTpl)
    selectedChannel.value = 'video'
    applyTemplate(newTpl, 'video')
  }
  isCreateTemplateModalOpen.value = false
}

const smsTemplate = ref({
  message: prebuiltSmsTemplates.value[0].message,
  autoDelay: prebuiltSmsTemplates.value[0].autoDelay,
  senderNumber: '+1 (555) 019-2830 (Verified 10DLC)',
  active: true
})

const emailTemplate = ref({
  subject: prebuiltEmailTemplates.value[0].subject,
  preheader: prebuiltEmailTemplates.value[0].preheader,
  heading: prebuiltEmailTemplates.value[0].heading,
  body: prebuiltEmailTemplates.value[0].body,
  buttonText: prebuiltEmailTemplates.value[0].buttonText,
  autoDelay: prebuiltEmailTemplates.value[0].autoDelay,
  active: true
})

const whatsappTemplate = ref({
  headerText: prebuiltWhatsAppTemplates.value[0].headerText,
  bodyText: prebuiltWhatsAppTemplates.value[0].bodyText,
  button1: prebuiltWhatsAppTemplates.value[0].button1,
  button2: prebuiltWhatsAppTemplates.value[0].button2,
  autoDelay: prebuiltWhatsAppTemplates.value[0].autoDelay,
  active: true
})

const videoTemplate = ref({
  headline: prebuiltVideoTemplates.value[0].headline,
  message: prebuiltVideoTemplates.value[0].message,
  questions: prebuiltVideoTemplates.value[0].questions.join('\n'),
  buttonText: prebuiltVideoTemplates.value[0].buttonText,
  maxDuration: prebuiltVideoTemplates.value[0].maxDuration,
  autoDelay: prebuiltVideoTemplates.value[0].autoDelay,
  active: true
})

const durationOptions = [
  '30 Seconds',
  '45 Seconds',
  '60 Seconds (Recommended)',
  '90 Seconds',
  '2 Minutes'
]

const formattedSmsPreview = computed(() => {
  return smsTemplate.value.message
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'Apex Dental')
    .replaceAll('{{ReviewLink}}', 'relay.to/r/apex-dental')
    .replaceAll('{{EmployeeName}}', 'Dr. Alex')
})

const formattedWhatsAppHeader = computed(() => {
  return whatsappTemplate.value.headerText
    .replaceAll('{{FirstName}}', 'Sarah')
})

const formattedWhatsAppPreview = computed(() => {
  return whatsappTemplate.value.bodyText
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'Apex Dental')
    .replaceAll('{{ReviewLink}}', 'relay.to/r/apex-dental')
    .replaceAll('{{EmployeeName}}', 'Dr. Alex')
})

const formattedVideoHeadline = computed(() => {
  return videoTemplate.value.headline
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'Apex Dental')
    .replaceAll('{{EmployeeName}}', 'Dr. Alex')
})

const formattedVideoPrompt = computed(() => {
  return videoTemplate.value.message
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'Apex Dental')
    .replaceAll('{{ReviewLink}}', 'relay.to/r/apex-dental')
    .replaceAll('{{EmployeeName}}', 'Dr. Alex')
})

const parsedVideoQuestions = computed(() => {
  return videoTemplate.value.questions
    .split('\n')
    .map(q => q.trim())
    .filter(Boolean)
})

// Reviews QR State
const qrFrame = ref<'badge' | 'stars' | 'simple'>('badge')
const qrTitle = ref('Scan to Rate Us on Google')
const qrSubtitle = ref('Takes only 30 seconds!')
const includeLogo = ref(true)
const isQrDownloaded = ref(false)

const selectQrFrame = (frame: 'badge' | 'stars' | 'simple') => {
  qrFrame.value = frame
  if (frame === 'badge') {
    qrTitle.value = 'Scan to Rate Us on Google'
    qrSubtitle.value = 'Takes only 30 seconds!'
  } else if (frame === 'stars') {
    qrTitle.value = 'How Was Your Visit?'
    qrSubtitle.value = 'We appreciate your feedback!'
  } else if (frame === 'simple') {
    qrTitle.value = 'Scan with Camera'
    qrSubtitle.value = ''
  }
}

// Relay AI Reviews State
const aiSettings = ref({
  enableAutoReply: false,
  minRating: '4_stars',
  customInstructions: 'Thank customers for their feedback, address any concerns politely, and offer support contact.'
})

const ratingOptions = [
  { value: '5_stars', label: '5 Stars only' },
  { value: '4_stars', label: '4 Stars & above' },
  { value: '3_stars', label: '3 Stars & above' },
  { value: 'all', label: 'All reviews (1-5 Stars)' }
]

const isAiSaved = ref(false)
const saveAiConfig = () => {
  isAiSaved.value = true
  setTimeout(() => {
    isAiSaved.value = false
  }, 2000)
}

// Spam Reviews Filters State
const spamSettings = ref({
  autoFlagRating: '3_stars_below',
  blocklistKeywords: ''
})

const autoFlagOptions = [
  { value: '3_stars_below', label: '3 Stars & below' },
  { value: '2_stars_below', label: '2 Stars & below' },
  { value: '1_star_only', label: '1 Star only' },
  { value: 'disabled', label: 'Disabled (Flag none)' }
]

const isSpamSaved = ref(false)
const saveSpamConfig = () => {
  isSpamSaved.value = true
  setTimeout(() => {
    isSpamSaved.value = false
  }, 2000)
}

// Actions
function copyReviewLink() {
  navigator.clipboard.writeText(reviewUrl.value)
  isLinkCopied.value = true
  setTimeout(() => {
    isLinkCopied.value = false
  }, 2200)
}

function insertTagIntoCurrentTemplate(tag: string) {
  if (selectedChannel.value === 'sms') {
    smsTemplate.value.message += ` ${tag}`
  } else if (selectedChannel.value === 'email') {
    emailTemplate.value.body += ` ${tag}`
  } else if (selectedChannel.value === 'whatsapp') {
    whatsappTemplate.value.bodyText += ` ${tag}`
  } else {
    videoTemplate.value.message += ` ${tag}`
  }
}

function insertTagIntoModal(tag: string) {
  if (newTemplateForm.value.channel === 'sms') {
    newTemplateForm.value.smsMessage += ` ${tag}`
  } else if (newTemplateForm.value.channel === 'email') {
    newTemplateForm.value.emailBody += ` ${tag}`
  } else if (newTemplateForm.value.channel === 'whatsapp') {
    newTemplateForm.value.waBody += ` ${tag}`
  } else {
    newTemplateForm.value.videoMessage += ` ${tag}`
  }
}

function enhanceWithAi() {
  isAiEnhancing.value = true
  setTimeout(() => {
    if (selectedChannel.value === 'sms') {
      smsTemplate.value.message = 'Hi {{FirstName}}! We loved taking care of you at {{BusinessName}}. Could you share a quick 30-second review to help others find us? ⭐ {{ReviewLink}}'
    } else if (selectedChannel.value === 'email') {
      emailTemplate.value.subject = '{{FirstName}}, how was your recent visit to {{BusinessName}}?'
      emailTemplate.value.body = 'Thank you for placing your trust in {{BusinessName}}. Our team strives for excellence every day. If you had a positive experience with {{EmployeeName}}, we would be thrilled if you left us a 5-star review.'
    } else if (selectedChannel.value === 'whatsapp') {
      whatsappTemplate.value.bodyText = 'Hi {{FirstName}}! Thank you for choosing {{BusinessName}} today. We hope everything went wonderfully! Would you take a quick second to leave us a rating?'
    } else {
      videoTemplate.value.headline = 'Share Your Experience with Apex Dental 🌟'
      videoTemplate.value.message = 'Hi {{FirstName}}! Your journey with {{BusinessName}} inspires us. Would you take 45 seconds to record a short video review sharing how Dr. Alex & the team took care of you?'
    }
    isAiEnhancing.value = false
  }, 700)
}

function sendTestMessage() {
  isTestSent.value = true
  setTimeout(() => {
    isTestSent.value = false
  }, 2500)
}

function downloadQrCode(format: string) {
  isQrDownloaded.value = true
  setTimeout(() => {
    isQrDownloaded.value = false
  }, 2500)
}
</script>

<template>
  <div class="flex-1 overflow-y-auto w-full hide-scrollbar bg-background p-6 lg:p-8">
    <RequestReviewsModal v-model:open="isRequestModalOpen" />

    <!-- Populated State -->
    <div v-if="isDemoLoaded" class="max-w-7xl mx-auto space-y-7">
      
      <!-- Standard Page Header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2">
        <div>
          <h1 class="text-base font-medium tracking-tight text-foreground">Configuration</h1>
          <p class="text-sm text-muted-foreground mt-1">Collect verified 5-star customer reviews across Google, Yelp, and Facebook via automated multi-channel sequences.</p>
        </div>
        <div class="flex items-center gap-3 shrink-0">
          <Button 
            variant="outline" 
            class="border border-border hover:border-transparent text-[13px] text-muted-foreground bg-white dark:bg-card shadow-2xs"
            @click="isDemoLoaded = false"
          >
            Preview Empty State
          </Button>
        </div>
      </div>

      <!-- Navigation Tabs (Clean Minimal Underline Tabs) -->
      <div class="border-b border-border/80 flex items-center gap-7 overflow-x-auto hide-scrollbar [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        <button 
          class="pb-3 text-[14px] font-medium transition-all whitespace-nowrap border-b-2 -mb-px cursor-pointer"
          :class="activeTab === 'channels' 
            ? 'border-primary text-primary font-semibold' 
            : 'border-transparent text-muted-foreground hover:text-foreground'"
          @click="activeTab = 'channels'"
        >
          Channels & Templates
        </button>

        <button 
          class="pb-3 text-[14px] font-medium transition-all whitespace-nowrap border-b-2 -mb-px cursor-pointer"
          :class="activeTab === 'qr_link' 
            ? 'border-primary text-primary font-semibold' 
            : 'border-transparent text-muted-foreground hover:text-foreground'"
          @click="activeTab = 'qr_link'"
        >
          Review Link & QR Hub
        </button>

        <button 
          class="pb-3 text-[14px] font-medium transition-all whitespace-nowrap border-b-2 -mb-px cursor-pointer"
          :class="activeTab === 'ai_outreach' 
            ? 'border-primary text-primary font-semibold' 
            : 'border-transparent text-muted-foreground hover:text-foreground'"
          @click="activeTab = 'ai_outreach'"
        >
          Relay AI Automations
        </button>

        <button 
          class="pb-3 text-[14px] font-medium transition-all whitespace-nowrap border-b-2 -mb-px cursor-pointer"
          :class="activeTab === 'spam_shield' 
            ? 'border-primary text-primary font-semibold' 
            : 'border-transparent text-muted-foreground hover:text-foreground'"
          @click="activeTab = 'spam_shield'"
        >
          Spam & Protection Shield
        </button>
      </div>

      <!-- ==================== TAB 1: CHANNELS & TEMPLATES ==================== -->
      <div v-if="activeTab === 'channels'" class="space-y-6 pt-1">
        <!-- Template Editor & Live Preview Grid -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          <!-- Left: Template Editor (8 Cols) -->
          <div class="lg:col-span-8 bg-card rounded-xl border border-border p-7 shadow-xs space-y-6">
            
            <!-- Editor Header with Channel Selector -->
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-border">
              <div>
                <h2 class="text-[15px] font-semibold text-foreground">
                  {{ selectedChannel === 'sms' ? 'SMS Request Template' : selectedChannel === 'email' ? 'Email Request Template' : selectedChannel === 'whatsapp' ? 'WhatsApp Business Template' : 'Video Testimonial Template' }}
                </h2>
                <p class="text-[12.5px] text-muted-foreground mt-0.5">
                  {{ selectedChannel === 'video' ? 'Customize the video testimonial prompts, questions, and recording interface.' : 'Customize the automated message sent to your customers.' }}
                </p>
              </div>

              <!-- Channel Selector Pills (Matching Tone Pills) -->
              <div class="flex items-center gap-1.5 shrink-0 flex-wrap">
                <button
                  type="button"
                  @click="selectedChannel = 'sms'"
                  class="px-3 py-1.5 rounded-lg border text-xs text-center cursor-pointer transition-colors flex items-center justify-center gap-1.5"
                  :class="selectedChannel === 'sms' 
                    ? 'bg-primary/10 border-primary text-primary font-semibold' 
                    : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                >
                  <Smartphone class="size-3.5" />
                  <span>SMS</span>
                </button>

                <button
                  type="button"
                  @click="selectedChannel = 'email'"
                  class="px-3 py-1.5 rounded-lg border text-xs text-center cursor-pointer transition-colors flex items-center justify-center gap-1.5"
                  :class="selectedChannel === 'email' 
                    ? 'bg-primary/10 border-primary text-primary font-semibold' 
                    : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                >
                  <Mail class="size-3.5" />
                  <span>Email</span>
                </button>

                <button
                  type="button"
                  @click="selectedChannel = 'whatsapp'"
                  class="px-3 py-1.5 rounded-lg border text-xs text-center cursor-pointer transition-colors flex items-center justify-center gap-1.5"
                  :class="selectedChannel === 'whatsapp' 
                    ? 'bg-primary/10 border-primary text-primary font-semibold' 
                    : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                >
                  <MessageCircle class="size-3.5" />
                  <span>WhatsApp</span>
                </button>

                <button
                  type="button"
                  @click="selectedChannel = 'video'"
                  class="px-3 py-1.5 rounded-lg border text-xs text-center cursor-pointer transition-colors flex items-center justify-center gap-1.5"
                  :class="selectedChannel === 'video' 
                    ? 'bg-primary/10 border-primary text-primary font-semibold' 
                    : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                >
                  <Video class="size-3.5" />
                  <span>Video Testimonial</span>
                </button>
              </div>
            </div>

            <!-- Clean & Simple Template Selection & Creation (Available on SMS, Email, WhatsApp, and Video) -->
            <div class="grid grid-cols-1 sm:grid-cols-12 gap-3.5 items-end">
              <div class="sm:col-span-8 flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ selectedChannel === 'sms' ? 'SMS Template' : selectedChannel === 'email' ? 'Email Template' : selectedChannel === 'whatsapp' ? 'WhatsApp Template' : 'Video Testimonial Template' }}
                </label>
                <DropdownMenu>
                  <DropdownMenuTrigger as-child>
                    <button type="button" class="h-9 px-3 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between shadow-2xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none w-full text-left cursor-pointer">
                      <span class="truncate">{{ currentActiveTemplate?.name || 'Select a template...' }}</span>
                      <ChevronDown class="size-3.5 opacity-50 ml-2 shrink-0" />
                    </button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent class="w-[340px]" align="start">
                    <DropdownMenuItem 
                      v-for="t in currentChannelTemplatesList" 
                      :key="t.id"
                      @click="applyTemplate(t)"
                      class="flex items-center justify-between py-2 cursor-pointer"
                    >
                      <span class="text-[13px]">{{ t.name }}</span>
                      <Check v-if="currentActiveTemplateId === t.id" class="size-3.5 text-primary shrink-0" />
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>

              <div class="sm:col-span-4">
                <Button 
                  variant="outline" 
                  size="sm" 
                  class="h-9 w-full text-[13px] gap-1.5 border border-border hover:border-transparent"
                  @click="openCreateTemplateModal(selectedChannel)"
                >
                  <Plus class="size-3.5" />
                  New Template
                </Button>
              </div>
            </div>

            <!-- SMS Fields -->
            <template v-if="selectedChannel === 'sms'">
              <div class="flex flex-col gap-2">
                <div class="flex items-center justify-between">
                  <label class="text-[13.5px] font-medium text-foreground">SMS Message Content</label>
                  <span class="text-[11.5px] text-muted-foreground font-mono">{{ smsTemplate.message.length }} / 160 characters (1 SMS)</span>
                </div>
                <textarea 
                  v-model="smsTemplate.message"
                  rows="4"
                  class="w-full text-[14px] p-3 rounded-lg border border-border bg-background text-foreground shadow-xs focus:ring-1 focus:ring-primary/30 outline-none leading-relaxed resize-none"
                ></textarea>

                <!-- Dynamic Variables Helper Tags Beneath Message Content -->
                <div class="flex items-center gap-2 flex-wrap pt-1">
                  <span class="text-[12.5px] text-muted-foreground font-medium">Insert tag:</span>
                  <div class="flex items-center gap-1.5 flex-wrap">
                    <button 
                      v-for="tag in availableTags" 
                      :key="tag"
                      type="button"
                      class="px-2.5 py-1 bg-muted/60 hover:bg-muted text-[11.5px] font-mono rounded-md text-foreground transition-colors border border-border/50 cursor-pointer"
                      @click="insertTagIntoCurrentTemplate(tag)"
                    >
                      {{ tag }}
                    </button>
                  </div>
                </div>
              </div>
            </template>

            <!-- Email Fields -->
            <template v-else-if="selectedChannel === 'email'">
              <div class="space-y-4">
                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">Email Subject Line</label>
                  <Input v-model="emailTemplate.subject" class="h-9 text-[14px]" />
                </div>

                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">Preheader Text</label>
                  <Input v-model="emailTemplate.preheader" class="h-9 text-[14px]" />
                </div>

                <div class="flex flex-col gap-2">
                  <label class="text-[13.5px] font-medium text-foreground">Email Body Copy</label>
                  <textarea 
                    v-model="emailTemplate.body"
                    rows="3"
                    class="w-full text-[14px] p-3 rounded-lg border border-border bg-background text-foreground shadow-xs focus:ring-1 focus:ring-primary/30 outline-none leading-relaxed resize-none"
                  ></textarea>

                  <!-- Dynamic Variables Helper Tags Beneath Email Body -->
                  <div class="flex items-center gap-2 flex-wrap pt-1">
                    <span class="text-[12.5px] text-muted-foreground font-medium">Insert tag:</span>
                    <div class="flex items-center gap-1.5 flex-wrap">
                      <button 
                        v-for="tag in availableTags" 
                        :key="tag"
                        type="button"
                        class="px-2.5 py-1 bg-muted/60 hover:bg-muted text-[11.5px] font-mono rounded-md text-foreground transition-colors border border-border/50 cursor-pointer"
                        @click="insertTagIntoCurrentTemplate(tag)"
                      >
                        {{ tag }}
                      </button>
                    </div>
                  </div>
                </div>

                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">Primary Rating Button Text</label>
                  <Input v-model="emailTemplate.buttonText" class="h-9 text-[14px]" />
                </div>
              </div>
            </template>

            <!-- WhatsApp Fields -->
            <template v-else-if="selectedChannel === 'whatsapp'">
              <div class="space-y-4">
                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">WhatsApp Header Greeting</label>
                  <Input v-model="whatsappTemplate.headerText" class="h-9 text-[14px]" />
                </div>

                <div class="flex flex-col gap-2">
                  <label class="text-[13.5px] font-medium text-foreground">Body Content</label>
                  <textarea 
                    v-model="whatsappTemplate.bodyText"
                    rows="3"
                    class="w-full text-[14px] p-3 rounded-lg border border-border bg-background text-foreground shadow-xs focus:ring-1 focus:ring-primary/30 outline-none leading-relaxed resize-none"
                  ></textarea>

                  <!-- Dynamic Variables Helper Tags Beneath WhatsApp Body -->
                  <div class="flex items-center gap-2 flex-wrap pt-1">
                    <span class="text-[12.5px] text-muted-foreground font-medium">Insert tag:</span>
                    <div class="flex items-center gap-1.5 flex-wrap">
                      <button 
                        v-for="tag in availableTags" 
                        :key="tag"
                        type="button"
                        class="px-2.5 py-1 bg-muted/60 hover:bg-muted text-[11.5px] font-mono rounded-md text-foreground transition-colors border border-border/50 cursor-pointer"
                        @click="insertTagIntoCurrentTemplate(tag)"
                      >
                        {{ tag }}
                      </button>
                    </div>
                  </div>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div class="flex flex-col gap-1.5">
                    <label class="text-[13.5px] font-medium text-foreground">Primary CTA Button</label>
                    <Input v-model="whatsappTemplate.button1" class="h-9 text-[14px]" />
                  </div>
                  <div class="flex flex-col gap-1.5">
                    <label class="text-[13.5px] font-medium text-foreground">Secondary Button</label>
                    <Input v-model="whatsappTemplate.button2" class="h-9 text-[14px]" />
                  </div>
                </div>
              </div>
            </template>

            <!-- Video Testimonial Fields -->
            <template v-else>
              <div class="space-y-4">
                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">Recording Page Headline</label>
                  <Input v-model="videoTemplate.headline" class="h-9 text-[14px]" />
                </div>

                <div class="flex flex-col gap-2">
                  <div class="flex items-center justify-between">
                    <label class="text-[13.5px] font-medium text-foreground">Prompt & Invitation Message</label>
                    <Button 
                      variant="outline" 
                      size="sm" 
                      class="h-7 gap-1.5 bg-primary/5 text-primary border border-primary/20 hover:border-transparent hover:bg-primary/10 text-xs"
                      @click="enhanceWithAi"
                      :disabled="isAiEnhancing"
                    >
                      <Sparkles class="size-3.5" :class="isAiEnhancing ? 'animate-spin' : ''" />
                      {{ isAiEnhancing ? 'Enhancing...' : 'Improve with Relay AI' }}
                    </Button>
                  </div>
                  <textarea 
                    v-model="videoTemplate.message"
                    rows="3"
                    class="w-full text-[14px] p-3 rounded-lg border border-border bg-background text-foreground shadow-xs focus:ring-1 focus:ring-primary/30 outline-none leading-relaxed resize-none"
                  ></textarea>

                  <!-- Dynamic Variables Helper Tags Beneath Video Prompt -->
                  <div class="flex items-center gap-2 flex-wrap pt-1">
                    <span class="text-[12.5px] text-muted-foreground font-medium">Insert tag:</span>
                    <div class="flex items-center gap-1.5 flex-wrap">
                      <button 
                        v-for="tag in availableTags" 
                        :key="tag"
                        type="button"
                        class="px-2.5 py-1 bg-muted/60 hover:bg-muted text-[11.5px] font-mono rounded-md text-foreground transition-colors border border-border/50 cursor-pointer"
                        @click="insertTagIntoCurrentTemplate(tag)"
                      >
                        {{ tag }}
                      </button>
                    </div>
                  </div>
                </div>

                <div class="flex flex-col gap-2">
                  <div class="flex items-center justify-between">
                    <label class="text-[13.5px] font-medium text-foreground">Guiding Questions for Customers</label>
                    <span class="text-[11.5px] text-muted-foreground font-medium">One question per line</span>
                  </div>
                  <textarea 
                    v-model="videoTemplate.questions"
                    rows="3"
                    class="w-full text-[14px] p-3 rounded-lg border border-border bg-background text-foreground shadow-xs focus:ring-1 focus:ring-primary/30 outline-none leading-relaxed resize-none font-mono text-[12.5px]"
                    placeholder="1. What problem did you want to solve?&#10;2. How did we help you?&#10;3. Would you recommend us?"
                  ></textarea>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div class="flex flex-col gap-1.5">
                    <label class="text-[13.5px] font-medium text-foreground">Primary Recording Button Text</label>
                    <Input v-model="videoTemplate.buttonText" class="h-9 text-[14px]" />
                  </div>
                  <div class="flex flex-col gap-1.5">
                    <label class="text-[13.5px] font-medium text-foreground">Max Video Duration</label>
                    <DropdownMenu>
                      <DropdownMenuTrigger as-child>
                        <button type="button" class="h-9 px-3 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between shadow-2xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none w-full text-left cursor-pointer">
                          <span class="truncate">{{ videoTemplate.maxDuration }}</span>
                          <ChevronDown class="size-3.5 opacity-50 ml-2 shrink-0" />
                        </button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent class="w-[240px]" align="start">
                        <DropdownMenuItem v-for="d in durationOptions" :key="d" @click="videoTemplate.maxDuration = d" class="cursor-pointer">
                          {{ d }}
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                </div>
              </div>
            </template>

            <!-- Bottom Actions -->
            <div class="pt-5 border-t border-border flex items-center justify-end">
              <Button class="text-[13px] gap-1.5" @click="sendTestMessage">
                <Check class="size-3.5" />
                Save Template Changes
              </Button>
            </div>
          </div>

          <!-- Right: Live Customer Phone Mockup Preview (4 Cols - snug & constricted) -->
          <div class="lg:col-span-4 bg-slate-100/70 dark:bg-slate-900/40 backdrop-blur-xl rounded-xl border border-border p-4 sm:p-5 shadow-xs flex flex-col items-center justify-center relative overflow-hidden min-h-[520px]">
            <!-- Subtle decorative ambient glow orbs behind the phone -->
            <div class="absolute -top-12 -right-12 size-48 rounded-full bg-primary/10 blur-3xl pointer-events-none"></div>
            <div class="absolute -bottom-12 -left-12 size-48 rounded-full bg-primary/10 blur-3xl pointer-events-none"></div>

            <!-- Authentic Borderless Mobile Frame (Matching Reference 2) -->
            <div class="w-[260px] sm:w-[272px] h-[460px] bg-white/95 dark:bg-card/95 backdrop-blur-md rounded-[30px] shadow-[0_20px_60px_-15px_rgba(0,0,0,0.12)] dark:shadow-[0_25px_60px_-15px_rgba(0,0,0,0.7)] border border-slate-200/80 dark:border-slate-800/80 flex flex-col overflow-hidden relative z-10">
              
              <!-- Top Status Bar -->
              <div class="pt-3 px-4 pb-1 flex items-center justify-between text-[10.5px] font-medium text-foreground/80 shrink-0 select-none">
                <span class="font-semibold text-foreground">9:41</span>
                <div class="flex items-center gap-1 text-foreground/70">
                  <Signal class="size-2.5" />
                  <Wifi class="size-2.5" />
                  <div class="w-4 h-2 rounded-[2px] border border-foreground/70 p-0.5 flex items-center">
                    <div class="h-full w-2 bg-foreground/80 rounded-[1px]"></div>
                  </div>
                </div>
              </div>

              <!-- ============================================== -->
              <!-- 1. EMAIL CLIENT INTERFACE -->
              <!-- ============================================== -->
              <div v-if="selectedChannel === 'email'" class="flex-1 flex flex-col overflow-hidden">
                <!-- Email App Header Bar -->
                <div class="px-3.5 py-2 flex items-center justify-between border-b border-border/40 shrink-0 bg-muted/20">
                  <div class="flex items-center gap-2">
                    <ChevronLeft class="size-4 text-primary shrink-0" />
                    <span class="text-xs font-semibold text-foreground">Inbox</span>
                  </div>
                  <div class="flex items-center gap-2 text-muted-foreground">
                    <Archive class="size-3.5" />
                    <Trash2 class="size-3.5" />
                    <MoreVertical class="size-3.5" />
                  </div>
                </div>

                <!-- Email Content Area -->
                <div class="flex-1 overflow-y-auto p-3 space-y-2.5 hide-scrollbar bg-slate-50/60 dark:bg-slate-900/30">
                  <!-- Email Header Info -->
                  <div class="space-y-1 pb-2 border-b border-border/40">
                    <div class="text-[12px] font-bold text-foreground leading-tight">
                      {{ emailTemplate.subject }}
                    </div>
                    <div class="flex items-center justify-between pt-1">
                      <div class="flex items-center gap-2 min-w-0">
                        <div class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[10px] shrink-0">
                          NR
                        </div>
                        <div class="min-w-0">
                          <div class="text-[11px] font-semibold text-foreground truncate">Apex Dental</div>
                          <div class="text-[9px] text-muted-foreground truncate">to sarah.j@gmail.com</div>
                        </div>
                      </div>
                      <span class="text-[9px] text-muted-foreground shrink-0">9:41 AM</span>
                    </div>
                  </div>

                  <!-- Email Body Card -->
                  <div class="p-3 bg-white dark:bg-card border border-border/60 rounded-2xl shadow-xs space-y-3">
                    <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap text-foreground font-normal">
                      {{ emailTemplate.body }}
                    </div>

                    <!-- Direct Review Destination CTA Button -->
                    <div class="pt-1">
                      <div class="p-2.5 rounded-xl bg-primary/10 border border-primary/20 text-center space-y-2">
                        <div class="text-[11px] font-semibold text-primary">
                          Rate on Google
                        </div>
                        <div class="flex justify-center gap-1 text-amber-500">
                          <Star v-for="s in 5" :key="s" class="size-3.5 fill-amber-500 text-amber-500" />
                        </div>
                        <div class="w-full py-1.5 rounded-lg bg-primary text-primary-foreground text-[10.5px] font-semibold flex items-center justify-center gap-1 shadow-xs">
                          <span>{{ emailTemplate.buttonText }}</span>
                          <ExternalLink class="size-2.5" />
                        </div>
                      </div>
                    </div>

                    <div class="text-[8.5px] text-center text-muted-foreground border-t border-border/40 pt-2">
                      Apex Dental Clinic · Unsubscribe
                    </div>
                  </div>
                </div>
              </div>

              <!-- ============================================== -->
              <!-- 2. WHATSAPP CHAT INTERFACE -->
              <!-- ============================================== -->
              <div v-else-if="selectedChannel === 'whatsapp'" class="flex-1 flex flex-col overflow-hidden">
                <!-- WhatsApp Top Header -->
                <div class="px-3 py-2 bg-emerald-600 dark:bg-emerald-700 text-white flex items-center justify-between shrink-0 shadow-xs">
                  <div class="flex items-center gap-2 min-w-0">
                    <ChevronLeft class="size-4 shrink-0" />
                    <div class="size-7 rounded-full bg-white/20 text-white flex items-center justify-center font-bold text-[10.5px] shrink-0 border border-white/30">
                      NR
                    </div>
                    <div class="min-w-0">
                      <div class="flex items-center gap-1">
                        <span class="text-xs font-semibold truncate text-white">Apex Dental</span>
                        <CheckCircle2 class="size-3 text-emerald-200 shrink-0" />
                      </div>
                      <span class="text-[9px] text-emerald-100 block truncate">Official Business Account</span>
                    </div>
                  </div>
                  <div class="flex items-center gap-2.5 text-white/90">
                    <Video class="size-3.5" />
                    <Phone class="size-3.5" />
                    <MoreVertical class="size-3.5" />
                  </div>
                </div>

                <!-- WhatsApp Chat Message Body -->
                <div class="flex-1 overflow-y-auto p-3 space-y-2.5 bg-[#ECE5DD]/40 dark:bg-slate-900/60 hide-scrollbar">
                  <div class="flex justify-center">
                    <span class="text-[9px] bg-white/80 dark:bg-slate-800 text-muted-foreground px-2 py-0.5 rounded-md shadow-2xs font-medium">Today</span>
                  </div>

                  <!-- WhatsApp Chat Bubble -->
                  <div class="space-y-1 max-w-[94%]">
                    <div class="bg-white dark:bg-slate-800 text-foreground rounded-2xl rounded-tl-xs p-3 shadow-xs border border-border/40 text-xs space-y-2">
                      <div class="font-medium text-[11.5px] text-foreground">{{ formattedWhatsAppHeader }}</div>
                      <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap text-foreground font-normal">
                        {{ formattedWhatsAppPreview }}
                      </div>

                      <!-- Rich Link Preview -->
                      <div class="p-2 bg-emerald-500/10 border border-emerald-500/20 rounded-xl space-y-1">
                        <div class="flex items-center justify-between gap-1">
                          <span class="text-[10px] font-semibold text-foreground truncate">Rate on Google</span>
                          <div class="flex gap-0.5 text-amber-500 shrink-0">
                            <Star v-for="s in 5" :key="s" class="size-2 fill-amber-500 text-amber-500" />
                          </div>
                        </div>
                        <div class="text-[9px] font-mono text-emerald-600 dark:text-emerald-400 flex items-center gap-1 truncate">
                          <span>relay.to/r/apex-dental</span>
                          <ExternalLink class="size-2 shrink-0" />
                        </div>
                      </div>

                      <div class="flex items-center justify-end gap-1 text-[8.5px] text-muted-foreground">
                        <span>9:41 AM</span>
                        <span class="text-sky-500 font-bold">✓✓</span>
                      </div>
                    </div>

                    <!-- Interactive Quick Action Buttons -->
                    <div class="flex flex-col gap-1 pt-1">
                      <div class="py-1.5 px-3 bg-white dark:bg-slate-800 border border-border/60 text-primary font-medium text-center text-[11px] rounded-xl shadow-2xs">
                        {{ whatsappTemplate.button1 }}
                      </div>
                      <div class="py-1.5 px-3 bg-white dark:bg-slate-800 border border-border/60 text-muted-foreground text-center text-[11px] rounded-xl shadow-2xs">
                        {{ whatsappTemplate.button2 }}
                      </div>
                    </div>
                  </div>
                </div>

                <!-- WhatsApp Bottom Input Bar -->
                <div class="p-2 bg-white dark:bg-slate-800 border-t border-border/40 flex items-center gap-1.5 shrink-0">
                  <Smile class="size-4 text-muted-foreground shrink-0" />
                  <div class="flex-1 h-6 bg-muted/60 rounded-full px-2.5 text-[9.5px] text-muted-foreground flex items-center truncate">
                    Message
                  </div>
                  <Paperclip class="size-3.5 text-muted-foreground shrink-0" />
                  <div class="size-6 rounded-full bg-emerald-600 text-white flex items-center justify-center shrink-0 shadow-xs">
                    <Mic class="size-2.5" />
                  </div>
                </div>
              </div>

              <!-- ============================================== -->
              <!-- 3. SMS / iMESSAGE INTERFACE -->
              <!-- ============================================== -->
              <div v-else-if="selectedChannel === 'sms'" class="flex-1 flex flex-col overflow-hidden">
                <!-- SMS / iMessage Header -->
                <div class="px-3.5 py-2 flex items-center justify-between border-b border-border/40 shrink-0 bg-muted/20">
                  <div class="flex items-center gap-1 text-primary">
                    <ChevronLeft class="size-4 shrink-0" />
                    <span class="text-[11px] font-medium">Messages</span>
                  </div>
                  <div class="flex flex-col items-center">
                    <div class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[9px]">
                      NR
                    </div>
                    <span class="text-[9.5px] font-semibold text-foreground">Apex Dental</span>
                  </div>
                  <Info class="size-3.5 text-primary shrink-0" />
                </div>

                <!-- SMS Messages Area -->
                <div class="flex-1 overflow-y-auto p-3 space-y-2.5 bg-slate-50/50 dark:bg-slate-900/40 hide-scrollbar">
                  <div class="text-[9.5px] text-center text-muted-foreground font-medium">Text Message · Today 9:41 AM</div>
                  
                  <!-- Chat Bubble -->
                  <div class="space-y-1 max-w-[94%]">
                    <div class="bg-primary text-primary-foreground rounded-2xl rounded-tl-xs p-3 shadow-xs text-xs space-y-2">
                      <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap font-normal">
                        {{ formattedSmsPreview }}
                      </div>

                      <!-- Rich Link Preview in SMS -->
                      <div class="p-2 bg-white/15 backdrop-blur-sm border border-white/20 rounded-xl space-y-1 text-primary-foreground">
                        <div class="flex items-center justify-between gap-1">
                          <span class="text-[10px] font-semibold truncate">Apex Dental · Reviews</span>
                          <div class="flex gap-0.5 text-amber-300 shrink-0">
                            <Star v-for="s in 5" :key="s" class="size-2 fill-amber-300 text-amber-300" />
                          </div>
                        </div>
                        <div class="text-[9px] font-mono opacity-90 flex items-center gap-1 truncate">
                          <span>relay.to/r/apex-dental</span>
                          <ExternalLink class="size-2 shrink-0" />
                        </div>
                      </div>

                      <div class="flex items-center justify-end text-[8.5px] opacity-80">
                        <span>Delivered</span>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- SMS Bottom Input Bar -->
                <div class="p-2 bg-white dark:bg-card border-t border-border/40 flex items-center gap-1.5 shrink-0">
                  <div class="size-6 rounded-full bg-muted flex items-center justify-center text-muted-foreground text-xs font-bold shrink-0">
                    +
                  </div>
                  <div class="flex-1 h-6 bg-muted/50 rounded-full px-3 text-[9.5px] text-muted-foreground flex items-center truncate border border-border/40">
                    iMessage
                  </div>
                  <div class="size-6 rounded-full bg-primary text-primary-foreground flex items-center justify-center shrink-0">
                    <ArrowUpRight class="size-3" />
                  </div>
                </div>
              </div>

              <!-- ============================================== -->
              <!-- 4. VIDEO TESTIMONIAL RECORDING INTERFACE -->
              <!-- ============================================== -->
              <div v-else class="flex-1 flex flex-col overflow-hidden">
                <!-- Video App Header Bar -->
                <div class="px-3.5 py-2 flex items-center justify-between border-b border-border/40 shrink-0 bg-muted/20">
                  <div class="flex items-center gap-1.5 min-w-0">
                    <div class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[9px] shrink-0">
                      AD
                    </div>
                    <span class="text-[11px] font-semibold text-foreground truncate">Apex Dental · Video Reviews</span>
                  </div>
                  <div class="flex items-center gap-1 text-[10px] text-muted-foreground font-mono">
                    <Clock class="size-3 text-primary" /> {{ videoTemplate.maxDuration.split(' ')[0] }}s
                  </div>
                </div>

                <!-- Video Content Area -->
                <div class="flex-1 overflow-y-auto p-3 space-y-2.5 hide-scrollbar bg-slate-50/60 dark:bg-slate-900/40">
                  <!-- Video Request Card -->
                  <div class="p-3 bg-white dark:bg-card border border-border/60 rounded-2xl shadow-xs space-y-2.5">
                    <div class="text-[12px] font-bold text-foreground leading-tight">
                      {{ formattedVideoHeadline }}
                    </div>
                    <div class="text-[11px] leading-relaxed text-muted-foreground font-normal whitespace-pre-wrap">
                      {{ formattedVideoPrompt }}
                    </div>

                    <!-- Guiding Prompts Card -->
                    <div class="p-2.5 bg-primary/5 border border-primary/15 rounded-xl space-y-1.5">
                      <div class="text-[10.5px] font-semibold text-primary flex items-center gap-1">
                        <Sparkles class="size-3" /> Guiding Questions:
                      </div>
                      <ul class="text-[10px] text-muted-foreground space-y-1 pl-1">
                        <li v-for="(q, idx) in parsedVideoQuestions" :key="idx" class="flex items-start gap-1">
                          <span class="text-primary font-bold shrink-0">•</span>
                          <span>{{ q }}</span>
                        </li>
                      </ul>
                    </div>

                    <!-- Camera Viewfinder Mockup Card -->
                    <div class="relative h-24 rounded-xl bg-slate-950 border border-slate-800 overflow-hidden flex flex-col items-center justify-center text-center p-2">
                      <div class="relative z-10 flex flex-col items-center gap-1">
                        <div class="size-7 rounded-full bg-white/10 flex items-center justify-center border border-white/20 text-white">
                          <Video class="size-3.5" />
                        </div>
                        <span class="text-[9.5px] font-medium text-white/90">Camera Ready</span>
                        <span class="text-[8.5px] text-white/60 font-mono">00:00 / {{ videoTemplate.maxDuration.split(' ')[0] }}s</span>
                      </div>
                    </div>

                    <!-- Primary Recording CTA Button -->
                    <div class="pt-0.5">
                      <div class="w-full py-2 rounded-xl bg-primary text-primary-foreground text-[10.5px] font-semibold flex items-center justify-center gap-1.5 shadow-xs cursor-pointer hover:bg-primary/90 transition-all">
                        <div class="size-2 rounded-full bg-red-400 animate-pulse"></div>
                        <span>{{ videoTemplate.buttonText }}</span>
                      </div>
                      <div class="text-[8.5px] text-center text-muted-foreground pt-1.5">
                        Instant browser recording · No app required
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Caption below phone -->
            <p class="text-[11.5px] text-muted-foreground text-center mt-3.5 z-10">
              {{ selectedChannel === 'email' ? 'Email Outreach Preview' : selectedChannel === 'whatsapp' ? 'WhatsApp Outreach Preview' : selectedChannel === 'sms' ? 'SMS Outreach Preview' : 'Video Testimonial Preview' }}
            </p>
          </div>
        </div>
      </div>

      <!-- ==================== TAB 2: REVIEW LINK & QR HUB ==================== -->
      <div v-else-if="activeTab === 'qr_link'" class="space-y-6 pt-1">
        
        <!-- 1. Review Shortlink & Smart Routing Card -->
        <div class="bg-card rounded-xl border border-border p-6 sm:p-7 shadow-xs space-y-5">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-3.5 border-b border-border">
            <div>
              <h2 class="text-[15px] font-semibold text-foreground">Review Shortlink & Routing</h2>
              <p class="text-[12.5px] text-muted-foreground mt-0.5">Customize your permanent review shortlink and primary destination platform.</p>
            </div>
            <div class="flex items-center gap-2">
              <Badge variant="secondary" class="text-[11px] font-medium">SSL Encrypted</Badge>
              <Badge variant="secondary" class="text-[11px] font-medium text-emerald-600 bg-emerald-500/10">Active</Badge>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-12 gap-5 items-end">
            <!-- Custom Link Slug -->
            <div class="md:col-span-7 flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Custom Link Slug</label>
              <div class="flex items-center">
                <span class="h-9 inline-flex items-center px-3 bg-muted/50 text-muted-foreground border border-r-0 border-border rounded-l-md text-[13px] font-mono select-none">
                  https://relay.to/r/
                </span>
                <Input 
                  v-model="customSlug" 
                  class="h-9 rounded-l-none rounded-r-none text-[13.5px] font-mono border-border focus-visible:ring-1" 
                />
                <Button 
                  variant="outline" 
                  class="h-9 px-3.5 rounded-l-none border border-border hover:border-transparent text-[13px] gap-1.5 bg-background shrink-0"
                  @click="copyReviewLink"
                >
                  <Check v-if="isLinkCopied" class="size-3.5 text-emerald-500" />
                  <Copy v-else class="size-3.5 text-muted-foreground" />
                  {{ isLinkCopied ? 'Copied' : 'Copy' }}
                </Button>
              </div>
            </div>

            <!-- Review Destination -->
            <div class="md:col-span-5 flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">Review Destination</label>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <button type="button" class="h-9 px-3 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between shadow-2xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none w-full text-left cursor-pointer">
                    <span class="truncate">{{ destinationLabels[selectedDestination] || selectedDestination }}</span>
                    <ChevronDown class="size-3.5 opacity-50 ml-2 shrink-0" />
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="w-[360px]" align="end">
                  <DropdownMenuItem @click="selectedDestination = 'google'">Google Business Profile (Direct Pop-up)</DropdownMenuItem>
                  <DropdownMenuItem @click="selectedDestination = 'smart'">Smart Multi-Platform Landing Page</DropdownMenuItem>
                  <DropdownMenuItem @click="selectedDestination = 'yelp'">Yelp Business Page</DropdownMenuItem>
                  <DropdownMenuItem @click="selectedDestination = 'trustpilot'">Trustpilot Verified Portal</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>
        </div>

        <!-- 2. QR Code Stand Customizer & Preview Grid -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          
          <!-- Left: QR Customizer (8 Cols) -->
          <div class="lg:col-span-8 bg-card rounded-xl border border-border p-7 shadow-xs space-y-6">
            <div class="pb-3.5 border-b border-border">
              <h2 class="text-[15px] font-semibold text-foreground">Printable QR Stand Customizer</h2>
              <p class="text-[12.5px] text-muted-foreground mt-0.5">Customize table-tent signage, call-to-action text, and branding for in-person review collection.</p>
            </div>

            <!-- Frame Style Visual Preview Cards -->
            <div class="flex flex-col gap-2">
              <label class="text-[13.5px] font-medium text-foreground">Frame Style</label>
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <!-- Tile 1: Google Badge -->
                <button
                  type="button"
                  @click="selectQrFrame('badge')"
                  class="flex flex-col items-center justify-center p-3.5 rounded-xl border transition-all text-center group cursor-pointer"
                  :class="qrFrame === 'badge' 
                    ? 'border-primary bg-primary/5 ring-1 ring-primary/30 shadow-2xs' 
                    : 'border-border/80 bg-background hover:border-border hover:bg-muted/30'"
                >
                  <div class="h-8 w-full flex items-center justify-center mb-1.5">
                    <div class="px-2 py-0.5 rounded-full bg-muted/80 border border-border/80 flex items-center gap-1 shadow-2xs">
                      <Star class="size-2.5 text-amber-500 fill-amber-500" />
                      <span class="text-[9.5px] font-semibold text-foreground">Google 5.0</span>
                    </div>
                  </div>
                  <span class="text-[13px] font-medium text-foreground">Google Badge</span>
                  <span class="text-[11px] text-muted-foreground mt-0.5">Verified review pill</span>
                </button>

                <!-- Tile 2: 5-Star Header -->
                <button
                  type="button"
                  @click="selectQrFrame('stars')"
                  class="flex flex-col items-center justify-center p-3.5 rounded-xl border transition-all text-center group cursor-pointer"
                  :class="qrFrame === 'stars' 
                    ? 'border-primary bg-primary/5 ring-1 ring-primary/30 shadow-2xs' 
                    : 'border-border/80 bg-background hover:border-border hover:bg-muted/30'"
                >
                  <div class="h-8 w-full flex items-center justify-center mb-1.5">
                    <div class="flex items-center gap-0.5 text-amber-500">
                      <Star v-for="s in 5" :key="s" class="size-3 fill-amber-500" />
                    </div>
                  </div>
                  <span class="text-[13px] font-medium text-foreground">5-Star Header</span>
                  <span class="text-[11px] text-muted-foreground mt-0.5">Classic gold stars</span>
                </button>

                <!-- Tile 3: Minimalist QR -->
                <button
                  type="button"
                  @click="selectQrFrame('simple')"
                  class="flex flex-col items-center justify-center p-3.5 rounded-xl border transition-all text-center group cursor-pointer"
                  :class="qrFrame === 'simple' 
                    ? 'border-primary bg-primary/5 ring-1 ring-primary/30 shadow-2xs' 
                    : 'border-border/80 bg-background hover:border-border hover:bg-muted/30'"
                >
                  <div class="h-8 w-full flex items-center justify-center mb-1.5">
                    <QrCode class="size-5 text-muted-foreground group-hover:text-foreground transition-colors" />
                  </div>
                  <span class="text-[13px] font-medium text-foreground">Minimalist QR</span>
                  <span class="text-[11px] text-muted-foreground mt-0.5">Clean stand with URL</span>
                </button>
              </div>
            </div>

            <!-- Text Inputs -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">QR Call-To-Action Text</label>
                <Input v-model="qrTitle" class="h-9 text-[14px]" />
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">Sub-text</label>
                <Input v-model="qrSubtitle" class="h-9 text-[14px]" />
              </div>
            </div>

            <!-- Center Logo Badge Toggle -->
            <div class="flex items-center justify-between p-4 bg-muted/20 rounded-xl border border-border/80">
              <div>
                <div class="text-[13.5px] font-medium text-foreground">Center Brand Icon</div>
                <div class="text-[12.5px] text-muted-foreground mt-0.5">Embed your company brand icon in the center of the QR matrix</div>
              </div>
              <Switch v-model="includeLogo" />
            </div>
          </div>

          <!-- Right: Live Stand Mockup & Download Actions (4 Cols) -->
          <div class="lg:col-span-4 bg-slate-100/70 dark:bg-slate-900/40 backdrop-blur-xl rounded-xl border border-border p-5 shadow-xs flex flex-col items-center space-y-4 relative overflow-hidden min-h-[460px]">
            <!-- Ambient Glow -->
            <div class="absolute -top-12 -right-12 size-48 rounded-full bg-primary/10 blur-3xl pointer-events-none"></div>
            <div class="absolute -bottom-12 -left-12 size-48 rounded-full bg-primary/10 blur-3xl pointer-events-none"></div>

            <div class="w-full flex items-center justify-between pb-3 border-b border-border/80 z-10">
              <span class="text-[13px] font-medium text-foreground">Stand Mockup</span>
              <Badge variant="secondary" class="text-[11px] font-medium">300 DPI Vector</Badge>
            </div>

            <!-- Sleek Stand Preview Card -->
            <div class="w-full max-w-[240px] bg-white dark:bg-card border border-slate-200/90 dark:border-slate-800 rounded-2xl p-5 shadow-md flex flex-col items-center text-center space-y-3.5 z-10">
              
              <!-- 1. Google Badge Style Preview -->
              <div v-if="qrFrame === 'badge'" class="space-y-1.5 w-full flex flex-col items-center">
                <div class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-muted/80 border border-border/80 text-[10.5px] font-semibold text-foreground">
                  <Star class="size-3 text-amber-500 fill-amber-500" />
                  <span>Rated 5.0 on Google</span>
                </div>
                <div class="text-[13px] font-bold text-foreground leading-tight">{{ qrTitle }}</div>
                <div v-if="qrSubtitle" class="text-[11px] text-muted-foreground">{{ qrSubtitle }}</div>
              </div>

              <!-- 2. 5-Star Header Style Preview -->
              <div v-else-if="qrFrame === 'stars'" class="space-y-1 w-full flex flex-col items-center">
                <div class="flex items-center justify-center gap-1 text-amber-500">
                  <Star v-for="s in 5" :key="s" class="size-3.5 fill-amber-500" />
                </div>
                <div class="text-[13px] font-bold text-foreground leading-tight">{{ qrTitle }}</div>
                <div v-if="qrSubtitle" class="text-[11px] text-muted-foreground">{{ qrSubtitle }}</div>
              </div>

              <!-- 3. Minimalist Style Preview -->
              <div v-else class="space-y-0.5 w-full flex flex-col items-center pt-0.5">
                <div class="text-[12.5px] font-semibold text-foreground leading-tight">{{ qrTitle }}</div>
                <div v-if="qrSubtitle" class="text-[10.5px] text-muted-foreground">{{ qrSubtitle }}</div>
              </div>

              <!-- Mock SVG QR Code -->
              <div class="size-36 bg-white p-2.5 rounded-xl border border-slate-200 shadow-2xs flex items-center justify-center relative">
                <svg viewBox="0 0 100 100" class="size-full text-slate-900 fill-current">
                  <!-- Outer corners -->
                  <path d="M5 5h30v30H5V5zm5 5v20h20V10H10z"/>
                  <path d="M15 15h10v10H15V15z"/>
                  <path d="M65 5h30v30H65V5zm5 5v20h20V10H70z"/>
                  <path d="M75 15h10v10H75V15z"/>
                  <path d="M5 65h30v30H5V65zm5 5v20h20V70H10z"/>
                  <path d="M15 75h10v10H15V75z"/>
                  <!-- Inner noise blocks -->
                  <path d="M45 10h10v10H45zm0 20h10v10H45zm15 15h10v10H60zm-20 0h10v10H40zm25 15h10v10H65zm15 0h10v10H80zm-40 20h10v10H40zm20 0h10v10H60zm20 0h10v10H80zm0-40h10v10H80zm-35 20h10v10H45z"/>
                </svg>
                <!-- Center Logo -->
                <div v-if="includeLogo" class="absolute size-7 rounded-full bg-primary text-primary-foreground flex items-center justify-center shadow-md">
                  <Star class="size-3.5 fill-current" />
                </div>
              </div>

              <div class="text-[11px] font-mono text-muted-foreground truncate w-full">
                relay.to/r/{{ customSlug }}
              </div>
            </div>

            <!-- Download Actions -->
            <div class="w-full space-y-2 pt-1 z-10">
              <div class="grid grid-cols-2 gap-2">
                <Button 
                  variant="outline" 
                  size="sm"
                  class="h-8.5 border border-border hover:border-transparent text-[12px] font-medium gap-1.5 bg-background shadow-2xs"
                  @click="downloadQrCode('png')"
                >
                  <Download class="size-3.5 text-primary" />
                  PNG
                </Button>
                <Button 
                  variant="outline" 
                  size="sm"
                  class="h-8.5 border border-border hover:border-transparent text-[12px] font-medium gap-1.5 bg-background shadow-2xs"
                  @click="downloadQrCode('svg')"
                >
                  <Download class="size-3.5 text-primary" />
                  SVG
                </Button>
              </div>

              <Button 
                size="sm"
                class="w-full h-8.5 gap-1.5 text-[12.5px] font-medium shadow-2xs"
                @click="downloadQrCode('pdf')"
              >
                <Printer class="size-3.5" />
                Print Signage (PDF)
              </Button>
            </div>
          </div>
        </div>
      </div>

      <!-- ==================== TAB 3: RELAY AI AUTOMATIONS ==================== -->
      <div v-else-if="activeTab === 'ai_outreach'" class="space-y-6 pt-1">
        <div class="bg-card rounded-xl border border-border p-7 shadow-xs space-y-6">
          
          <!-- 1. Enable Auto-Reply with Relay AI Banner -->
          <div class="flex items-center justify-between p-5 bg-muted/20 rounded-xl border border-border/80">
            <div class="space-y-1">
              <h3 class="text-[14.5px] font-semibold text-foreground">Enable Auto-Reply with Relay AI</h3>
              <p class="text-[13px] text-muted-foreground">Instantly draft and publish responses based on customer reviews</p>
            </div>
            <Switch v-model="aiSettings.enableAutoReply" />
          </div>

          <!-- 2. Minimum Rating To Auto-Reply -->
          <div class="flex flex-col gap-2">
            <label class="text-[11.5px] font-semibold uppercase tracking-wider text-muted-foreground">
              MINIMUM RATING TO AUTO-REPLY
            </label>
            <DropdownMenu>
              <DropdownMenuTrigger as-child>
                <button 
                  type="button" 
                  class="h-10 px-3.5 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between shadow-2xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none w-full text-left cursor-pointer"
                >
                  <span>{{ ratingOptions.find(o => o.value === aiSettings.minRating)?.label || '4 Stars & above' }}</span>
                  <ChevronDown class="size-4 opacity-50 ml-2 shrink-0" />
                </button>
              </DropdownMenuTrigger>
              <DropdownMenuContent class="w-[360px]" align="start">
                <DropdownMenuItem 
                  v-for="opt in ratingOptions" 
                  :key="opt.value" 
                  @click="aiSettings.minRating = opt.value"
                >
                  {{ opt.label }}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>

          <!-- 3. Custom AI Instructions -->
          <div class="flex flex-col gap-2">
            <label class="text-[11.5px] font-semibold uppercase tracking-wider text-muted-foreground">
              CUSTOM AI INSTRUCTIONS
            </label>
            <textarea
              v-model="aiSettings.customInstructions"
              rows="3"
              placeholder="Thank customers for their feedback, address any concerns politely, and offer support contact."
              class="w-full rounded-md border border-border/80 bg-background px-3.5 py-3 text-[14px] text-foreground shadow-2xs placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 resize-y min-h-[90px]"
            ></textarea>
          </div>

          <!-- 4. Bottom Action Bar -->
          <div class="flex items-center justify-end pt-4 border-t border-border">
            <Button 
              size="default" 
              class="h-9 px-5 text-[13.5px] font-medium shadow-2xs gap-1.5"
              @click="saveAiConfig"
            >
              <Check v-if="isAiSaved" class="size-4" />
              <span>{{ isAiSaved ? 'Saved Successfully' : 'Save AI Config' }}</span>
            </Button>
          </div>

        </div>
      </div>

      <!-- ==================== TAB 4: SPAM & PROTECTION SHIELD ==================== -->
      <div v-else-if="activeTab === 'spam_shield'" class="space-y-6 pt-1">
        <div class="bg-card rounded-xl border border-border p-7 shadow-xs space-y-6">
          
          <!-- 1. Header -->
          <div class="space-y-1 pb-2 border-b border-border">
            <h2 class="text-base font-semibold text-foreground">Spam Reviews Filters</h2>
            <p class="text-[13px] text-muted-foreground">Automatically identify and isolate low rating or fake feedback</p>
          </div>

          <!-- 2. Auto-Flag Ratings Under -->
          <div class="flex flex-col gap-2">
            <label class="text-[11.5px] font-semibold uppercase tracking-wider text-muted-foreground">
              AUTO-FLAG RATINGS UNDER
            </label>
            <DropdownMenu>
              <DropdownMenuTrigger as-child>
                <button 
                  type="button" 
                  class="h-10 px-3.5 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between shadow-2xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none w-full text-left cursor-pointer"
                >
                  <span>{{ autoFlagOptions.find(o => o.value === spamSettings.autoFlagRating)?.label || '3 Stars & below' }}</span>
                  <ChevronDown class="size-4 opacity-50 ml-2 shrink-0" />
                </button>
              </DropdownMenuTrigger>
              <DropdownMenuContent class="w-[360px]" align="start">
                <DropdownMenuItem 
                  v-for="opt in autoFlagOptions" 
                  :key="opt.value" 
                  @click="spamSettings.autoFlagRating = opt.value"
                >
                  {{ opt.label }}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
            <p class="text-[12.5px] text-muted-foreground mt-0.5">
              Flagged reviews will be marked as isolated and pending manual validation before public publishing.
            </p>
          </div>

          <!-- 3. Blocklist Keywords -->
          <div class="flex flex-col gap-2">
            <label class="text-[11.5px] font-semibold uppercase tracking-wider text-muted-foreground">
              BLOCKLIST KEYWORDS
            </label>
            <Input
              v-model="spamSettings.blocklistKeywords"
              placeholder=""
              class="h-10 text-[14px]"
            />
            <p class="text-[12.5px] text-muted-foreground mt-0.5">
              Comma-separated list of terms. Reviews containing these keywords are auto-marked as spam.
            </p>
          </div>

          <!-- 4. Bottom Action Bar -->
          <div class="flex items-center justify-end pt-4 border-t border-border">
            <Button 
              size="default" 
              class="h-9 px-5 text-[13.5px] font-medium shadow-2xs gap-1.5"
              @click="saveSpamConfig"
            >
              <Check v-if="isSpamSaved" class="size-4" />
              <span>{{ isSpamSaved ? 'Saved Successfully' : 'Save Spam Config' }}</span>
            </Button>
          </div>

        </div>
      </div>
    </div>

    <!-- Empty State View -->
    <div v-else class="flex flex-col min-h-[calc(100vh-10rem)] w-full">
      <PremiumEmptyState
        :icon="Send"
        title="No Configurations Found"
        description="Generate 5-star reviews across Google, Yelp, and Facebook with automated SMS, Email, WhatsApp, and printable QR codes powered by Relay AI."
        primaryAction="Create Configuration"
        secondaryAction="Learn About Configuration"
        @primary-click="isRequestModalOpen = true"
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

    <!-- ==================== CREATE NEW OUTREACH TEMPLATE MODAL (MULTI-CHANNEL) ==================== -->
    <div 
      v-if="isCreateTemplateModalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/80 backdrop-blur-sm animate-in fade-in-0"
      @click.self="isCreateTemplateModalOpen = false"
    >
      <div class="bg-card border border-border w-full max-w-lg rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh] animate-in zoom-in-95">
        <!-- Modal Header -->
        <div class="px-6 py-4 border-b border-border flex items-center justify-between shrink-0">
          <div>
            <h3 class="text-[16px] font-semibold text-foreground">Create New Outreach Template</h3>
            <p class="text-[12.5px] text-muted-foreground mt-0.5">Design a custom message template for review outreach.</p>
          </div>
          <Button 
            variant="ghost" 
            size="sm" 
            class="h-8 w-8 p-0 rounded-full border border-border hover:border-transparent" 
            @click="isCreateTemplateModalOpen = false"
          >
            <X class="size-4" />
          </Button>
        </div>

        <!-- Modal Form Body -->
        <div class="p-6 space-y-5 overflow-y-auto hide-scrollbar flex-1">
          <!-- Target Channel Pills (Matching Tone Pills) -->
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">Target Channel</label>
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
              <button
                type="button"
                @click="newTemplateForm.channel = 'sms'"
                class="px-2.5 py-2 rounded-lg border text-xs text-center cursor-pointer transition-colors flex items-center justify-center gap-1.5"
                :class="newTemplateForm.channel === 'sms' 
                  ? 'bg-primary/10 border-primary text-primary font-semibold' 
                  : 'bg-card border-border hover:bg-muted text-muted-foreground'"
              >
                <MessageSquare class="size-3.5" />
                SMS
              </button>
              <button
                type="button"
                @click="newTemplateForm.channel = 'email'"
                class="px-2.5 py-2 rounded-lg border text-xs text-center cursor-pointer transition-colors flex items-center justify-center gap-1.5"
                :class="newTemplateForm.channel === 'email' 
                  ? 'bg-primary/10 border-primary text-primary font-semibold' 
                  : 'bg-card border-border hover:bg-muted text-muted-foreground'"
              >
                <Mail class="size-3.5" />
                Email
              </button>
              <button
                type="button"
                @click="newTemplateForm.channel = 'whatsapp'"
                class="px-2.5 py-2 rounded-lg border text-xs text-center cursor-pointer transition-colors flex items-center justify-center gap-1.5"
                :class="newTemplateForm.channel === 'whatsapp' 
                  ? 'bg-primary/10 border-primary text-primary font-semibold' 
                  : 'bg-card border-border hover:bg-muted text-muted-foreground'"
              >
                <MessageCircle class="size-3.5" />
                WhatsApp
              </button>
              <button
                type="button"
                @click="newTemplateForm.channel = 'video'"
                class="px-2.5 py-2 rounded-lg border text-xs text-center cursor-pointer transition-colors flex items-center justify-center gap-1.5"
                :class="newTemplateForm.channel === 'video' 
                  ? 'bg-primary/10 border-primary text-primary font-semibold' 
                  : 'bg-card border-border hover:bg-muted text-muted-foreground'"
              >
                <Video class="size-3.5" />
                Video
              </button>
            </div>
          </div>

          <!-- Common: Template Name -->
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">Template Name</label>
            <Input 
              v-model="newTemplateForm.name" 
              :placeholder="newTemplateForm.channel === 'sms' ? 'e.g. VIP Client 5-Star Prompt' : newTemplateForm.channel === 'email' ? 'e.g. Elegant Post-Service Follow-up' : newTemplateForm.channel === 'whatsapp' ? 'e.g. Quick WhatsApp 1-Tap Feedback' : 'e.g. Customer Experience Video'" 
              class="h-9 text-[14px]"
            />
          </div>

          <!-- ==================== SMS FORM FIELDS ==================== -->
          <template v-if="newTemplateForm.channel === 'sms'">
            <div class="flex flex-col gap-2">
              <div class="flex items-center justify-between">
                <label class="text-[13.5px] font-medium text-foreground">SMS Message Content</label>
                <span class="text-[11.5px] text-muted-foreground font-mono">{{ newTemplateForm.smsMessage.length }} / 160 chars</span>
              </div>
              <textarea 
                v-model="newTemplateForm.smsMessage"
                rows="4"
                placeholder="Type your SMS message here..."
                class="w-full text-[14px] p-3 rounded-lg border border-border bg-background text-foreground shadow-xs focus:ring-1 focus:ring-primary/30 outline-none leading-relaxed resize-none"
              ></textarea>
              
              <!-- Quick Tag Buttons Beneath Content -->
              <div class="flex items-center gap-2 flex-wrap pt-0.5">
                <span class="text-[12px] text-muted-foreground font-medium">Insert tag:</span>
                <div class="flex items-center gap-1.5 flex-wrap">
                  <button 
                    v-for="tag in availableTags" 
                    :key="tag"
                    type="button"
                    class="px-2 py-0.5 bg-muted/60 hover:bg-muted text-[11px] font-mono rounded text-foreground border border-border/50 cursor-pointer"
                    @click="insertTagIntoModal(tag)"
                  >
                    {{ tag }}
                  </button>
                </div>
              </div>
            </div>
          </template>

          <!-- ==================== EMAIL FORM FIELDS ==================== -->
          <template v-else-if="newTemplateForm.channel === 'email'">
            <div class="space-y-4">
              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">Email Subject Line</label>
                <Input v-model="newTemplateForm.emailSubject" placeholder="How was your experience with {{BusinessName}}?" class="h-9 text-[14px]" />
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">Preheader Text</label>
                <Input v-model="newTemplateForm.emailPreheader" placeholder="We value your feedback. Take 30 seconds to rate us." class="h-9 text-[14px]" />
              </div>

              <div class="flex flex-col gap-2">
                <label class="text-[13.5px] font-medium text-foreground">Email Body Copy</label>
                <textarea 
                  v-model="newTemplateForm.emailBody"
                  rows="3"
                  placeholder="Write your email body copy..."
                  class="w-full text-[14px] p-3 rounded-lg border border-border bg-background text-foreground shadow-xs focus:ring-1 focus:ring-primary/30 outline-none leading-relaxed resize-none"
                ></textarea>
                
                <!-- Quick Tag Buttons -->
                <div class="flex items-center gap-2 flex-wrap pt-0.5">
                  <span class="text-[12px] text-muted-foreground font-medium">Insert tag:</span>
                  <div class="flex items-center gap-1.5 flex-wrap">
                    <button 
                      v-for="tag in availableTags" 
                      :key="tag"
                      type="button"
                      class="px-2 py-0.5 bg-muted/60 hover:bg-muted text-[11px] font-mono rounded text-foreground border border-border/50 cursor-pointer"
                      @click="insertTagIntoModal(tag)"
                    >
                      {{ tag }}
                    </button>
                  </div>
                </div>
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">Rating Button Text</label>
                <Input v-model="newTemplateForm.emailButtonText" placeholder="Rate Us on Google ★★★★★" class="h-9 text-[14px]" />
              </div>
            </div>
          </template>

          <!-- ==================== WHATSAPP FORM FIELDS ==================== -->
          <template v-else-if="newTemplateForm.channel === 'whatsapp'">
            <div class="space-y-4">
              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">WhatsApp Header Greeting</label>
                <Input v-model="newTemplateForm.waHeader" placeholder="Hi {{FirstName}} 👋" class="h-9 text-[14px]" />
              </div>

              <div class="flex flex-col gap-2">
                <label class="text-[13.5px] font-medium text-foreground">Body Content</label>
                <textarea 
                  v-model="newTemplateForm.waBody"
                  rows="3"
                  placeholder="Write your WhatsApp message body..."
                  class="w-full text-[14px] p-3 rounded-lg border border-border bg-background text-foreground shadow-xs focus:ring-1 focus:ring-primary/30 outline-none leading-relaxed resize-none"
                ></textarea>
                
                <!-- Quick Tag Buttons -->
                <div class="flex items-center gap-2 flex-wrap pt-0.5">
                  <span class="text-[12px] text-muted-foreground font-medium">Insert tag:</span>
                  <div class="flex items-center gap-1.5 flex-wrap">
                    <button 
                      v-for="tag in availableTags" 
                      :key="tag"
                      type="button"
                      class="px-2 py-0.5 bg-muted/60 hover:bg-muted text-[11px] font-mono rounded text-foreground border border-border/50 cursor-pointer"
                      @click="insertTagIntoModal(tag)"
                    >
                      {{ tag }}
                    </button>
                  </div>
                </div>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">Primary CTA Button</label>
                  <Input v-model="newTemplateForm.waButton1" placeholder="⭐ Leave a 5★ Review" class="h-9 text-[14px]" />
                </div>
                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">Secondary Button</label>
                  <Input v-model="newTemplateForm.waButton2" placeholder="💬 Talk with Support" class="h-9 text-[14px]" />
                </div>
              </div>
            </div>
          </template>

          <!-- ==================== VIDEO TESTIMONIAL FORM FIELDS ==================== -->
          <template v-else>
            <div class="space-y-4">
              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">Recording Page Headline</label>
                <Input v-model="newTemplateForm.videoHeadline" placeholder="Share Your Story with {{BusinessName}}" class="h-9 text-[14px]" />
              </div>

              <div class="flex flex-col gap-2">
                <label class="text-[13.5px] font-medium text-foreground">Prompt Message</label>
                <textarea 
                  v-model="newTemplateForm.videoMessage"
                  rows="3"
                  placeholder="Hi {{FirstName}}, could you record a quick video review sharing your experience?"
                  class="w-full text-[14px] p-3 rounded-lg border border-border bg-background text-foreground shadow-xs focus:ring-1 focus:ring-primary/30 outline-none leading-relaxed resize-none"
                ></textarea>
                
                <!-- Quick Tag Buttons -->
                <div class="flex items-center gap-2 flex-wrap pt-0.5">
                  <span class="text-[12px] text-muted-foreground font-medium">Insert tag:</span>
                  <div class="flex items-center gap-1.5 flex-wrap">
                    <button 
                      v-for="tag in availableTags" 
                      :key="tag"
                      type="button"
                      class="px-2 py-0.5 bg-muted/60 hover:bg-muted text-[11px] font-mono rounded text-foreground border border-border/50 cursor-pointer"
                      @click="insertTagIntoModal(tag)"
                    >
                      {{ tag }}
                    </button>
                  </div>
                </div>
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">Guiding Questions (One per line)</label>
                <textarea 
                  v-model="newTemplateForm.videoQuestions"
                  rows="3"
                  placeholder="1. What problem did you want to solve?&#10;2. How did we help you?&#10;3. Would you recommend us?"
                  class="w-full text-[14px] p-3 rounded-lg border border-border bg-background text-foreground shadow-xs focus:ring-1 focus:ring-primary/30 outline-none leading-relaxed resize-none font-mono text-[12.5px]"
                ></textarea>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">Recording Button Text</label>
                  <Input v-model="newTemplateForm.videoButtonText" placeholder="Record Video Testimonial 🎥" class="h-9 text-[14px]" />
                </div>
                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">Max Duration</label>
                  <DropdownMenu>
                    <DropdownMenuTrigger as-child>
                      <button type="button" class="h-9 px-3 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between shadow-2xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none w-full text-left cursor-pointer">
                        <span class="truncate">{{ newTemplateForm.videoMaxDuration }}</span>
                        <ChevronDown class="size-3.5 opacity-50 ml-2 shrink-0" />
                      </button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent class="w-[220px]" align="start">
                      <DropdownMenuItem v-for="d in durationOptions" :key="d" @click="newTemplateForm.videoMaxDuration = d" class="cursor-pointer">
                        {{ d }}
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </div>
            </div>
          </template>
        </div>

        <!-- Modal Footer -->
        <div class="px-6 py-3.5 border-t border-border bg-muted/20 flex items-center justify-end gap-2 shrink-0">
          <Button 
            variant="ghost" 
            size="sm" 
            class="border border-border hover:border-transparent text-[13px]" 
            @click="isCreateTemplateModalOpen = false"
          >
            Cancel
          </Button>
          <Button 
            size="sm" 
            class="text-[13px] gap-1.5" 
            :disabled="!isCreateTemplateValid"
            @click="handleCreateTemplate"
          >
            <Check class="size-3.5" />
            Create Template
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>
