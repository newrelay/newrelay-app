<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { 
  X, ChevronRight, Search, FileText, CheckCircle2, 
  ArrowLeft, Send, Sparkles, MessageSquare, 
  Mail, MessageCircle, Star, Phone, Smartphone, 
  Upload, Clock, Check, BarChart3, Settings2,
  Calendar, ChevronLeft, Users, AlertCircle, ExternalLink,
  Signal, Wifi, MoreVertical, Paperclip, Smile, Mic, Trash2, Archive, Video, Info,
  LayoutTemplate, ChevronDown, MonitorPlay, VideoIcon, Building2
} from 'lucide-vue-next'
import { 
  Button, Input, Checkbox, Badge,
  DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem
} from '@/components/ui'
import {
  type VideoTemplateItem,
  defaultVideoTemplates,
  defaultSmsTemplates,
  defaultEmailTemplates,
  defaultWhatsAppTemplates
} from '../data/outreachTemplates'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  (e: 'update:open', value: boolean): void
  (e: 'submit', payload: any): void
}>()

// Default State for Reset
const defaultFormState = {
  selectedCustomers: [] as string[],
  customRecipients: '',
  channels: ['WhatsApp'] as string[],
  delivery: 'Send immediately',
  scheduleDate: '',
  scheduleTime: '',
  scheduleTimezone: '',
  videoTemplateId: 'video_standard_request',
  headline: defaultVideoTemplates[0].headline,
  promptMessage: defaultVideoTemplates[0].message,
  questions: defaultVideoTemplates[0].questions.join('\n'),
  buttonText: defaultVideoTemplates[0].buttonText,
  maxDuration: defaultVideoTemplates[0].maxDuration,
  // Channel-specific invite text
  emailSubject: '{{FirstName}}, will you share a quick 45s video review?',
  emailBody: 'Hi {{FirstName}},\n\nWe would love to feature your story! Could you take 45 seconds to record a short video testimonial for {{BusinessName}}?\n\nTap below to start recording in your browser (no app download needed):\n{{VideoLink}}\n\nThank you so much!',
  smsMessage: 'Hi {{FirstName}}! We would love your quick 30s video feedback for {{BusinessName}}. Tap here to record: {{VideoLink}}',
  whatsappHeader: 'Hi {{FirstName}} 🎥',
  whatsappBody: 'We value your experience with {{BusinessName}}! Would you share a quick video testimonial? Tap below to record directly from your phone:',
  whatsappButton1: '🎥 Record Video Review',
  whatsappButton2: '💬 Ask a Question',
  // AI options
  transcript: true,
  summarize: true,
  sentiment: true
}

const currentStep = ref(1)
const form = ref({ ...defaultFormState })
const searchQuery = ref('')
const activeFilter = ref('Recent Customers')
const previewMode = ref<'video_page' | 'invite_message'>('video_page')
const previewChannel = ref<string>('WhatsApp')
const activeEditingChannel = ref<string>('WhatsApp')
const isAiEnhancing = ref(false)

// Prebuilt Templates
const prebuiltVideoTemplates = ref<VideoTemplateItem[]>([...defaultVideoTemplates])

const currentActiveTemplate = computed(() => {
  return prebuiltVideoTemplates.value.find(t => t.id === form.value.videoTemplateId) || prebuiltVideoTemplates.value[0]
})

const durationOptions = [
  '30 Seconds',
  '45 Seconds',
  '60 Seconds (Recommended)',
  '90 Seconds',
  '2 Minutes'
]

// Keep activeEditingChannel and previewChannel in sync with selected channels
watch(() => form.value.channels, (channels) => {
  if (channels.length > 0) {
    if (!channels.includes(previewChannel.value)) {
      previewChannel.value = channels[0]
    }
    if (!channels.includes(activeEditingChannel.value)) {
      activeEditingChannel.value = channels[0]
    }
  }
}, { deep: true, immediate: true })

function selectVideoTemplate(template: VideoTemplateItem) {
  form.value.videoTemplateId = template.id
  form.value.headline = template.headline
  form.value.promptMessage = template.message
  form.value.questions = template.questions.join('\n')
  form.value.buttonText = template.buttonText
  form.value.maxDuration = template.maxDuration
}

function insertVariable(variable: string) {
  if (activeEditingChannel.value === 'SMS') {
    form.value.smsMessage += ` ${variable}`
  } else if (activeEditingChannel.value === 'Email') {
    form.value.emailBody += ` ${variable}`
  } else if (activeEditingChannel.value === 'WhatsApp') {
    form.value.whatsappBody += ` ${variable}`
  } else {
    form.value.promptMessage += ` ${variable}`
  }
}

function enhanceWithAi() {
  isAiEnhancing.value = true
  setTimeout(() => {
    form.value.headline = 'Share Your Journey with Apex Dental 🌟'
    form.value.promptMessage = 'Hi {{FirstName}}! Your experience with {{BusinessName}} inspires us. Would you take 45 seconds to record a short video review sharing how Dr. Alex & the team took care of you?'
    form.value.emailSubject = '{{FirstName}}, your story could inspire others at {{BusinessName}} 🌟'
    form.value.emailBody = 'Hi {{FirstName}},\n\nThank you for choosing {{BusinessName}}! We would be honored if you shared a quick 45-second video review about your experience with {{EmployeeName}}.\n\n🎥 Tap here to record directly in your browser:\n{{VideoLink}}\n\nIt takes less than a minute and requires no app downloads.\n\nWarm regards,\nThe {{BusinessName}} Care Team'
    form.value.smsMessage = 'Hi {{FirstName}}! We loved having you at {{BusinessName}}. Could you share a quick 45s video review with us? 🎥 {{VideoLink}}'
    form.value.whatsappBody = 'Hi {{FirstName}}! Thank you for choosing {{BusinessName}} today. We hope everything went wonderfully! Would you take 45 seconds to record a short video review?\n\n{{VideoLink}}'
    isAiEnhancing.value = false
  }, 600)
}

function getChannelIcon(channel: string) {
  if (channel === 'WhatsApp') return MessageCircle
  if (channel === 'Email') return Mail
  return Smartphone
}

// Mock Customers
const filters = ['Recent Customers', 'Completed Jobs', 'Closed Deals', 'VIP Clients', 'Appointment Completed', 'Invoice Paid']

const allCustomers = [
  { id: '1', name: 'Sarah Johnson', email: 'sarah.j@gmail.com', phone: '+1 (555) 234-5678', company: 'Acme Inc.', contextLabel: 'Service:', contextValue: 'Dental Cleaning · Yesterday' },
  { id: '2', name: 'Michael Brown', email: '', phone: '+1 (555) 876-5432', company: 'Acme Inc.', contextLabel: 'Visit:', contextValue: 'Implants Check · 2 days ago' },
  { id: '3', name: 'Emily Wilson', email: 'emily.wilson@outlook.com', phone: '+1 (555) 345-6789', company: 'Global Tech', contextLabel: 'Appointment:', contextValue: 'Orthodontics · Today' },
  { id: '4', name: 'David Miller', email: 'david.m@yahoo.com', phone: '', company: 'Global Tech', contextLabel: 'Service:', contextValue: 'Teeth Whitening · 3 days ago' },
  { id: '5', name: 'Jessica Taylor', email: 'jessica.t@gmail.com', phone: '+1 (555) 456-7890', company: 'Stark Industries', contextLabel: 'Visit:', contextValue: 'Annual Checkup · Yesterday' },
  { id: '6', name: 'Robert Anderson', email: '', phone: '+1 (555) 567-8901', company: 'Stark Industries', contextLabel: 'Service:', contextValue: 'Root Canal · 2 days ago' },
  { id: '7', name: 'Amanda Thomas', email: 'amanda.t@hotmail.com', phone: '+1 (555) 678-9012', company: 'Wayne Enterprises', contextLabel: 'Appointment:', contextValue: 'Invisalign Prep · Today' },
  { id: '8', name: 'James Jackson', email: 'james.j@gmail.com', phone: '', company: 'Wayne Enterprises', contextLabel: 'Visit:', contextValue: 'Emergency Care · Yesterday' }
]

const selectedCompanyFilter = ref<string | null>(null)
const companyList = ['Acme Inc.', 'Global Tech', 'Stark Industries', 'Wayne Enterprises']

function isCustomerEligible(customer: typeof allCustomers[0]) {
  if (!form.value.channels.length) return true
  const hasEmail = Boolean(customer.email && customer.email.trim())
  const hasPhone = Boolean(customer.phone && customer.phone.trim())
  const requiresEmail = form.value.channels.includes('Email')
  const requiresPhone = form.value.channels.includes('SMS') || form.value.channels.includes('WhatsApp')
  
  if (requiresEmail && !requiresPhone) return hasEmail
  if (requiresPhone && !requiresEmail) return hasPhone
  if (requiresEmail && requiresPhone) return hasEmail || hasPhone
  return true
}

const eligibleCustomers = computed(() => {
  return allCustomers.filter(c => isCustomerEligible(c))
})

const excludedCount = computed(() => {
  return allCustomers.length - eligibleCustomers.value.length
})

const channelRequirementText = computed(() => {
  const requiresEmail = form.value.channels.includes('Email')
  const requiresPhone = form.value.channels.includes('SMS') || form.value.channels.includes('WhatsApp')
  if (requiresEmail && !requiresPhone) return 'email address'
  if (requiresPhone && !requiresEmail) return 'phone number'
  return 'valid email or phone number'
})

const filteredCustomers = computed(() => {
  let list = eligibleCustomers.value
  if (selectedCompanyFilter.value) {
    list = list.filter(c => c.company === selectedCompanyFilter.value)
  }
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    list = list.filter(c => c.name.toLowerCase().includes(q) || (c.company && c.company.toLowerCase().includes(q)))
  }
  return list
})

// Automatically sanitize selected customers when channel changes
watch(() => form.value.channels, () => {
  const validIds = new Set(eligibleCustomers.value.map(c => c.id))
  form.value.selectedCustomers = form.value.selectedCustomers.filter(id => validIds.has(id))
}, { deep: true })

// Live Formatted Previews
const formattedHeadline = computed(() => {
  return form.value.headline
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'Apex Dental')
    .replaceAll('{{EmployeeName}}', 'Dr. Alex')
})

const formattedPromptMessage = computed(() => {
  return form.value.promptMessage
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'Apex Dental')
    .replaceAll('{{EmployeeName}}', 'Dr. Alex')
    .replaceAll('{{VideoLink}}', 'relay.to/v/apex-dental')
})

const parsedQuestions = computed(() => {
  return form.value.questions
    .split('\n')
    .map(q => q.trim())
    .filter(Boolean)
})

const formattedEmailSubject = computed(() => {
  return form.value.emailSubject
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'Apex Dental')
    .replaceAll('{{EmployeeName}}', 'Dr. Alex')
})

const formattedEmailBody = computed(() => {
  return form.value.emailBody
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'Apex Dental')
    .replaceAll('{{VideoLink}}', 'relay.to/v/apex-dental')
    .replaceAll('{{EmployeeName}}', 'Dr. Alex')
})

const formattedSmsBody = computed(() => {
  return form.value.smsMessage
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'Apex Dental')
    .replaceAll('{{VideoLink}}', 'relay.to/v/apex-dental')
    .replaceAll('{{EmployeeName}}', 'Dr. Alex')
})

const formattedWhatsAppHeader = computed(() => {
  return form.value.whatsappHeader
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'Apex Dental')
})

const formattedWhatsAppBody = computed(() => {
  return form.value.whatsappBody
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'Apex Dental')
    .replaceAll('{{VideoLink}}', 'relay.to/v/apex-dental')
    .replaceAll('{{EmployeeName}}', 'Dr. Alex')
})

const channels = [
  { name: 'WhatsApp', icon: MessageCircle, rate: '98%', color: 'text-primary', bg: 'bg-primary/10' },
  { name: 'Email', icon: Mail, rate: '92%', color: 'text-primary', bg: 'bg-primary/10' },
  { name: 'SMS', icon: Smartphone, rate: '96%', color: 'text-primary', bg: 'bg-primary/10' }
]

function toggleSelection(array: string[], item: string) {
  const index = array.indexOf(item)
  if (index === -1) array.push(item)
  else array.splice(index, 1)
}

function selectAllCustomers() {
  if (form.value.selectedCustomers.length === filteredCustomers.value.length) {
    form.value.selectedCustomers = []
  } else {
    form.value.selectedCustomers = filteredCustomers.value.map(c => c.id)
  }
}

function nextStep() {
  if (currentStep.value < 5) currentStep.value++
}

function prevStep() {
  if (currentStep.value > 1) currentStep.value--
}

function generateReport() {
  emit('submit', {
    customers: form.value.selectedCustomers,
    channels: form.value.channels,
    templateId: form.value.videoTemplateId,
    headline: form.value.headline,
    prompt: form.value.promptMessage,
    questions: parsedQuestions.value,
    maxDuration: form.value.maxDuration,
    delivery: form.value.delivery,
    aiOptions: {
      transcript: form.value.transcript,
      summarize: form.value.summarize,
      sentiment: form.value.sentiment
    }
  })
  setTimeout(() => {
    currentStep.value = 5
  }, 700)
}

function close() {
  emit('update:open', false)
  setTimeout(() => {
    currentStep.value = 1
    form.value = { ...defaultFormState }
    form.value.selectedCustomers = []
    form.value.channels = ['WhatsApp']
  }, 300)
}
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6">
    <div class="absolute inset-0 bg-background/80 backdrop-blur-sm" @click="close"></div>
    
    <div class="relative w-full max-w-5xl max-h-[90vh] bg-card rounded-2xl shadow-2xl border border-border flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200">
      
      <!-- Header -->
      <div v-if="currentStep < 5" class="px-6 py-4 border-b border-border flex items-center justify-between bg-muted/30">
        <div>
          <h2 class="text-base font-semibold text-foreground">Request Video Testimonials</h2>
          <div class="flex items-center gap-2 mt-1.5 text-xs font-medium">
            <span :class="currentStep >= 1 ? 'text-primary font-semibold' : 'text-muted-foreground'">1. Channel</span>
            <ChevronRight class="size-3.5 text-muted-foreground/50" />
            <span :class="currentStep >= 2 ? 'text-primary font-semibold' : 'text-muted-foreground'">2. Recipients</span>
            <ChevronRight class="size-3.5 text-muted-foreground/50" />
            <span :class="currentStep >= 3 ? 'text-primary font-semibold' : 'text-muted-foreground'">3. Video Template</span>
            <ChevronRight class="size-3.5 text-muted-foreground/50" />
            <span :class="currentStep >= 4 ? 'text-primary font-semibold' : 'text-muted-foreground'">4. Review</span>
          </div>
        </div>
        <Button variant="ghost" size="icon" class="text-muted-foreground border border-border hover:border-transparent" @click="close">
          <X class="size-5" />
        </Button>
      </div>
      
      <!-- Body -->
      <div class="flex-1 overflow-y-auto p-0 bg-card hide-scrollbar flex flex-col">
        
        <!-- STEP 1: Choose Delivery Channel & Sending Method -->
        <div v-if="currentStep === 1" class="p-6 sm:p-8 space-y-8 animate-in slide-in-from-right-4 duration-300">
          <div class="space-y-4">
            <div>
              <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Select Delivery Channels</h3>
              <p class="text-[13px] text-muted-foreground mt-0.5">Customers will receive a direct link to record their video testimonial right from their browser or phone.</p>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div 
                v-for="channel in channels" :key="channel.name"
                class="relative border-2 rounded-xl p-5 cursor-pointer transition-all overflow-hidden group"
                :class="form.channels.includes(channel.name) ? 'border-primary bg-primary/5 shadow-sm' : 'border-border bg-card hover:border-primary/50'"
                @click="form.channels = [channel.name]"
              >
                <div class="absolute top-3 right-3 size-5 rounded-full border-2 flex items-center justify-center transition-colors shrink-0" :class="form.channels.includes(channel.name) ? 'border-primary' : 'border-muted-foreground/30'">
                  <div v-if="form.channels.includes(channel.name)" class="size-2.5 rounded-full bg-primary"></div>
                </div>
                <div class="flex flex-col gap-4">
                  <div class="size-12 rounded-full flex items-center justify-center" :class="channel.bg">
                    <component :is="channel.icon" class="size-6" :class="channel.color" />
                  </div>
                  <div>
                    <h4 class="font-semibold text-[15px] text-foreground mb-1">{{ channel.name }}</h4>
                    <div class="flex items-center gap-1.5 text-xs">
                      <Star class="size-3.5 fill-amber-400 text-amber-400" v-if="channel.name === 'WhatsApp'" />
                      <span class="font-medium text-foreground">{{ channel.rate }}</span>
                      <span class="text-muted-foreground">Open Rate</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Sending Method -->
          <div class="space-y-4 pt-4 border-t border-border">
            <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Sending Method</h3>
            <div class="flex items-center gap-6">
              <div class="flex items-center gap-2 cursor-pointer" @click="form.delivery = 'Send immediately'">
                <div class="size-4 rounded-full border-2 flex items-center justify-center transition-colors shrink-0" :class="form.delivery === 'Send immediately' ? 'border-primary' : 'border-muted-foreground/30'">
                  <div v-if="form.delivery === 'Send immediately'" class="size-2 rounded-full bg-primary"></div>
                </div>
                <span class="text-sm font-medium text-foreground">Send Immediately</span>
              </div>
              <div class="flex items-center gap-2 cursor-pointer" @click="form.delivery = 'Schedule'">
                <div class="size-4 rounded-full border-2 flex items-center justify-center transition-colors shrink-0" :class="form.delivery === 'Schedule' ? 'border-primary' : 'border-muted-foreground/30'">
                  <div v-if="form.delivery === 'Schedule'" class="size-2 rounded-full bg-primary"></div>
                </div>
                <span class="text-sm font-medium text-foreground">Schedule Later</span>
              </div>
            </div>
            
            <div v-if="form.delivery === 'Schedule'" class="grid grid-cols-1 sm:grid-cols-3 gap-3 p-4 bg-muted/30 rounded-xl border border-border animate-in fade-in slide-in-from-top-2 max-w-2xl">
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <Button variant="outline" class="w-full h-10 px-4 justify-start text-left text-[14px] font-normal shadow-sm rounded-md border-border/80 bg-background hover:bg-muted/50 focus-visible:ring-1 focus-visible:ring-primary/30" :class="!form.scheduleDate ? 'text-muted-foreground' : ''">
                    <Calendar class="mr-2 size-4 text-muted-foreground" />
                    {{ form.scheduleDate || 'Select date' }}
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="w-auto p-4" align="start">
                  <div class="flex items-center justify-between mb-4">
                    <Button variant="ghost" size="icon" class="h-7 w-7 border"><ChevronLeft class="h-4 w-4" /></Button>
                    <div class="text-sm font-semibold">August 2026</div>
                    <Button variant="ghost" size="icon" class="h-7 w-7 border"><ChevronRight class="h-4 w-4" /></Button>
                  </div>
                  <div class="grid grid-cols-7 gap-1 text-center text-[10px] font-semibold text-muted-foreground mb-2">
                    <div>MO</div><div>TU</div><div>WE</div><div>TH</div><div>FR</div><div>SA</div><div>SU</div>
                  </div>
                  <div class="grid grid-cols-7 gap-1 text-sm">
                    <div v-for="d in 31" :key="d" 
                         class="h-8 w-8 flex items-center justify-center rounded-md cursor-pointer transition-colors"
                         :class="form.scheduleDate === `2026-08-${d.toString().padStart(2, '0')}` ? 'bg-primary text-primary-foreground font-medium shadow-sm' : 'text-foreground hover:bg-muted/70'"
                         @click="form.scheduleDate = `2026-08-${d.toString().padStart(2, '0')}`">
                      {{ d }}
                    </div>
                  </div>
                </DropdownMenuContent>
              </DropdownMenu>

              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <Button variant="outline" class="w-full h-10 px-4 justify-start text-left text-[14px] font-normal shadow-sm rounded-md border-border/80 bg-background hover:bg-muted/50 focus-visible:ring-1 focus-visible:ring-primary/30" :class="!form.scheduleTime ? 'text-muted-foreground' : ''">
                    <Clock class="mr-2 size-4 text-muted-foreground" />
                    {{ form.scheduleTime || 'Select time' }}
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="w-48 max-h-[280px] overflow-y-auto" align="start">
                  <DropdownMenuItem v-for="time in ['09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM', '01:00 PM', '01:30 PM', '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM', '04:00 PM', '04:30 PM', '05:00 PM']" :key="time" @click="form.scheduleTime = time" class="cursor-pointer">
                    {{ time }}
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>

              <Input placeholder="Timezone" v-model="form.scheduleTimezone" class="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30" />
            </div>
          </div>
        </div>

        <!-- STEP 2: Select Recipients -->
        <div v-if="currentStep === 2" class="flex-1 flex animate-in slide-in-from-right-4 duration-300 min-h-[500px]">
          <!-- Sidebar Filters -->
          <div class="w-64 border-r border-border bg-muted/10 p-4 space-y-6 hidden md:block shrink-0 overflow-y-auto">
            <!-- Quick Filters -->
            <div>
              <h3 class="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">Quick Filters</h3>
              <div class="space-y-1">
                <button 
                  v-for="filter in filters" :key="filter"
                  class="w-full text-left px-3 py-2 rounded-md text-sm transition-colors cursor-pointer"
                  :class="activeFilter === filter && !selectedCompanyFilter ? 'bg-primary/10 text-primary font-medium' : 'text-muted-foreground hover:bg-muted/50 hover:text-foreground'"
                  @click="activeFilter = filter; selectedCompanyFilter = null"
                >
                  {{ filter }}
                </button>

                <!-- Company dropdown inside Quick Filters -->
                <DropdownMenu>
                  <DropdownMenuTrigger as-child>
                    <button 
                      class="w-full text-left px-3 py-2 rounded-md text-sm transition-colors flex items-center justify-between cursor-pointer group"
                      :class="selectedCompanyFilter ? 'bg-primary/10 text-primary font-medium' : 'text-muted-foreground hover:bg-muted/50 hover:text-foreground'"
                    >
                      <div class="flex items-center gap-2 min-w-0 truncate">
                        <span class="truncate">{{ selectedCompanyFilter ? selectedCompanyFilter : 'Company' }}</span>
                      </div>
                      <ChevronDown class="size-3.5 shrink-0 opacity-60 group-hover:opacity-100 transition-transform" />
                    </button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="start" class="w-56 p-1.5 shadow-lg border border-border bg-popover z-50">
                    <DropdownMenuItem 
                      @click="selectedCompanyFilter = null; activeFilter = 'Recent Customers'"
                      class="flex items-center justify-between px-2.5 py-1.5 text-xs rounded-md cursor-pointer hover:bg-muted/80"
                      :class="!selectedCompanyFilter ? 'bg-primary/10 text-primary font-medium' : ''"
                    >
                      <span>All Companies</span>
                      <Check v-if="!selectedCompanyFilter" class="size-3 text-primary" />
                    </DropdownMenuItem>
                    <DropdownMenuItem 
                      v-for="comp in companyList" 
                      :key="comp"
                      @click="selectedCompanyFilter = comp; activeFilter = ''"
                      class="flex items-center justify-between px-2.5 py-1.5 text-xs rounded-md cursor-pointer hover:bg-muted/80"
                      :class="selectedCompanyFilter === comp ? 'bg-primary/10 text-primary font-medium' : ''"
                    >
                      <div class="flex items-center gap-2 truncate">
                        <Building2 class="size-3.5 opacity-70 shrink-0" />
                        <span class="truncate">{{ comp }}</span>
                      </div>
                      <span class="text-[10.5px] px-1.5 py-0.5 rounded-full bg-muted text-muted-foreground font-medium">
                        {{ eligibleCustomers.filter(c => c.company === comp).length }}
                      </span>
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            </div>
          </div>
          
          <!-- Main Content -->
          <div class="flex-1 p-6 flex flex-col">
            <!-- Shortlist Alert Banner -->
            <div v-if="excludedCount > 0" class="flex items-center gap-2.5 p-3 mb-4 bg-destructive/10 border border-destructive/20 rounded-xl text-destructive text-[13px] animate-in fade-in">
              <AlertCircle class="size-4 shrink-0" />
              <span>
                <strong class="font-semibold">{{ excludedCount }} contact{{ excludedCount > 1 ? 's' : '' }}</strong> without a {{ channelRequirementText }} {{ excludedCount > 1 ? 'have' : 'has' }} been automatically filtered from <strong class="font-semibold">{{ form.channels.join(' + ') }}</strong> video outreach.
              </span>
            </div>

            <div class="flex items-center justify-between mb-4">
              <div class="relative w-full max-w-md">
                <Search class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
                <Input v-model="searchQuery" placeholder="Search shortlisted customers..." class="pl-9 pr-4 h-10 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30" />
              </div>
              <div class="flex items-center gap-4">
                <span class="text-sm font-medium text-primary bg-primary/10 px-3 py-1 rounded-full">{{ form.selectedCustomers.length }} selected</span>
                <Button variant="ghost" size="sm" @click="selectAllCustomers" class="text-muted-foreground border border-border hover:border-transparent">
                  <CheckCircle2 class="size-4 mr-2" :class="form.selectedCustomers.length === filteredCustomers.length && filteredCustomers.length > 0 ? 'text-primary' : ''" /> Select All
                </Button>
              </div>
            </div>
            
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 overflow-y-auto pr-2 pb-4">
              <div 
                v-for="customer in filteredCustomers" :key="customer.id"
                class="flex items-start gap-3 p-3.5 rounded-xl border cursor-pointer transition-all"
                :class="form.selectedCustomers.includes(customer.id) ? 'border-primary bg-primary/5 shadow-xs' : 'border-border bg-card hover:border-primary/30'"
                @click="toggleSelection(form.selectedCustomers, customer.id)"
              >
                <div class="mt-0.5 size-4 rounded-md border flex items-center justify-center transition-colors shrink-0" :class="form.selectedCustomers.includes(customer.id) ? 'bg-primary border-primary text-primary-foreground' : 'border-muted-foreground/30 bg-background'">
                  <Check v-if="form.selectedCustomers.includes(customer.id)" class="size-3" />
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex items-center justify-between gap-2">
                    <div class="font-medium text-foreground text-sm truncate">{{ customer.name }}</div>
                    <span v-if="customer.company" class="text-[10.5px] px-1.5 py-0.5 rounded bg-muted text-muted-foreground shrink-0 font-medium flex items-center gap-1">
                      <Building2 class="size-2.5 opacity-70" />
                      {{ customer.company }}
                    </span>
                  </div>
                  
                  <div class="flex items-center gap-1.5 text-xs text-muted-foreground mt-0.5">
                    <Mail v-if="form.channels.includes('Email') && customer.email" class="size-3 text-primary shrink-0" />
                    <Phone v-else-if="customer.phone" class="size-3 text-primary shrink-0" />
                    <span class="truncate">{{ form.channels.includes('Email') && customer.email ? customer.email : customer.phone }}</span>
                  </div>

                  <div class="flex items-center text-xs mt-1.5 text-muted-foreground gap-1.5">
                    <span>{{ customer.contextLabel }}</span>
                    <span class="font-medium text-foreground">{{ customer.contextValue }}</span>
                  </div>
                </div>
              </div>

              <div v-if="filteredCustomers.length === 0" class="col-span-2 py-12 text-center text-muted-foreground text-sm">
                No matching customers found with valid contact details for {{ form.channels.join(', ') }}.
              </div>
            </div>
          </div>
        </div>

        <!-- STEP 3: Customize Video Template & Live Mobile Preview -->
        <div v-if="currentStep === 3" class="flex-1 flex flex-col lg:flex-row animate-in slide-in-from-right-4 duration-300 min-h-[500px] overflow-hidden">
          <!-- Editor Side -->
          <div class="flex-1 p-5 sm:p-6 space-y-5 overflow-y-auto">
            
            <!-- Channel Switcher Tabs (If multiple channels chosen in Step 1) -->
            <div v-if="form.channels.length > 1" class="flex items-center justify-between gap-3 pb-3 border-b border-border">
              <span class="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Configure Channel Invite:</span>
              <div class="flex items-center gap-1.5">
                <button
                  v-for="ch in form.channels"
                  :key="ch"
                  type="button"
                  @click="activeEditingChannel = ch; previewChannel = ch"
                  class="px-3 py-1.5 rounded-lg border text-xs font-medium cursor-pointer transition-colors flex items-center gap-1.5"
                  :class="activeEditingChannel === ch 
                    ? 'bg-primary/10 border-primary text-primary font-semibold' 
                    : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                >
                  <component :is="getChannelIcon(ch)" class="size-3.5" />
                  <span>{{ ch }}</span>
                </button>
              </div>
            </div>

            <!-- Pre-built Video Template Selector Dropdown -->
            <div class="bg-muted/20 border border-border rounded-xl p-4 space-y-2">
              <div class="flex items-center justify-between">
                <label class="text-[13.5px] font-medium text-foreground flex items-center gap-1.5">
                  <LayoutTemplate class="size-4 text-primary" />
                  Select Pre-built Video Testimonial Template
                </label>
                <Badge variant="outline" class="text-[11px] font-normal text-muted-foreground py-0.5">
                  {{ prebuiltVideoTemplates.length }} templates available
                </Badge>
              </div>

              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <button 
                    type="button" 
                    class="h-9.5 px-3 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between shadow-2xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none w-full text-left cursor-pointer transition-all"
                  >
                    <div class="flex items-center gap-2.5 truncate">
                      <div class="size-2 rounded-full bg-primary shrink-0"></div>
                      <span class="truncate font-medium">{{ currentActiveTemplate.name }}</span>
                    </div>
                    <ChevronDown class="size-3.5 opacity-50 ml-2 shrink-0" />
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="w-[380px] max-h-[320px] overflow-y-auto" align="start">
                  <DropdownMenuItem 
                    v-for="t in prebuiltVideoTemplates" 
                    :key="t.id"
                    @click="selectVideoTemplate(t)"
                    class="flex items-center justify-between py-2.5 px-3 cursor-pointer"
                  >
                    <div class="flex flex-col gap-0.5 min-w-0 pr-2">
                      <span class="text-[13px] font-medium text-foreground truncate">{{ t.name }}</span>
                      <span class="text-[11px] text-muted-foreground truncate">{{ t.maxDuration }} · {{ t.autoDelay }}</span>
                    </div>
                    <Check v-if="form.videoTemplateId === t.id" class="size-4 text-primary shrink-0" />
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

            <!-- Video Recording Page Headline & Duration -->
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div class="sm:col-span-2 flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">Video Recording Page Headline</label>
                <Input v-model="form.headline" class="h-9 text-[14px]" />
              </div>
              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">Max Duration</label>
                <DropdownMenu>
                  <DropdownMenuTrigger as-child>
                    <button type="button" class="h-9 px-3 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between shadow-2xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none w-full text-left cursor-pointer">
                      <span class="truncate">{{ form.maxDuration }}</span>
                      <ChevronDown class="size-3.5 opacity-50 ml-2 shrink-0" />
                    </button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent class="w-[240px]" align="end">
                    <DropdownMenuItem v-for="d in durationOptions" :key="d" @click="form.maxDuration = d" class="cursor-pointer">
                      {{ d }}
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            </div>

            <!-- Video Prompt Message -->
            <div class="flex flex-col gap-2">
              <div class="flex items-center justify-between">
                <label class="text-[13.5px] font-medium text-foreground">Video Prompt & Customer Greeting</label>
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
                v-model="form.promptMessage"
                rows="3"
                class="w-full text-[13.5px] p-3.5 shadow-xs rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"
              ></textarea>
            </div>

            <!-- Guiding Questions for Customers while recording -->
            <div class="flex flex-col gap-1.5">
              <div class="flex items-center justify-between">
                <label class="text-[13.5px] font-medium text-foreground">Guiding Questions (Shown on screen while recording)</label>
                <span class="text-[11px] text-muted-foreground font-medium">One question per line</span>
              </div>
              <textarea 
                v-model="form.questions"
                rows="3"
                class="w-full text-[13px] font-mono p-3 shadow-xs rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"
                placeholder="1. What problem did you want to solve?&#10;2. How did we help you?&#10;3. Would you recommend us?"
              ></textarea>
            </div>

            <!-- Variables & Recording Button Label -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div class="space-y-2">
                <p class="text-[11px] font-medium text-muted-foreground uppercase tracking-wider">Insert Dynamic Variables</p>
                <div class="flex flex-wrap gap-1.5">
                  <Badge 
                    v-for="v in ['{{FirstName}}', '{{BusinessName}}', '{{EmployeeName}}', '{{VideoLink}}']" 
                    :key="v" 
                    variant="secondary" 
                    class="font-mono text-[11px] cursor-pointer hover:bg-primary/20 transition-colors"
                    @click="insertVariable(v)"
                  >
                    {{ v }}
                  </Badge>
                </div>
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">Primary Recording Button Text</label>
                <Input v-model="form.buttonText" class="h-9 text-[14px]" />
              </div>
            </div>

            <!-- AI Processing Options -->
            <div class="pt-4 border-t border-border space-y-2.5">
              <div class="flex items-center gap-2">
                <Sparkles class="size-4 text-primary" />
                <span class="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Relay AI Video Processing Options</span>
              </div>
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <label class="flex items-center gap-2.5 p-3 border border-border rounded-xl bg-card cursor-pointer hover:bg-muted/40 transition-colors">
                  <Checkbox :checked="form.transcript" @update:checked="form.transcript = $event as boolean" class="shadow-none rounded-[4px]" />
                  <div class="flex flex-col">
                    <span class="text-[12.5px] font-semibold text-foreground">Auto-Transcript</span>
                    <span class="text-[11px] text-muted-foreground">Extract captions</span>
                  </div>
                </label>
                <label class="flex items-center gap-2.5 p-3 border border-border rounded-xl bg-card cursor-pointer hover:bg-muted/40 transition-colors">
                  <Checkbox :checked="form.summarize" @update:checked="form.summarize = $event as boolean" class="shadow-none rounded-[4px]" />
                  <div class="flex flex-col">
                    <span class="text-[12.5px] font-semibold text-foreground">AI Summary</span>
                    <span class="text-[11px] text-muted-foreground">Generate key bullet</span>
                  </div>
                </label>
                <label class="flex items-center gap-2.5 p-3 border border-border rounded-xl bg-card cursor-pointer hover:bg-muted/40 transition-colors">
                  <Checkbox :checked="form.sentiment" @update:checked="form.sentiment = $event as boolean" class="shadow-none rounded-[4px]" />
                  <div class="flex flex-col">
                    <span class="text-[12.5px] font-semibold text-foreground">Sentiment Score</span>
                    <span class="text-[11px] text-muted-foreground">Detect tone & quality</span>
                  </div>
                </label>
              </div>
            </div>

          </div>
          
          <!-- Preview Side (Dynamic Phone Interface with Toggle between Recording Screen and Invite Message) -->
          <div class="w-full lg:w-[325px] xl:w-[345px] bg-slate-100/70 dark:bg-slate-900/40 backdrop-blur-xl border-t lg:border-t-0 lg:border-l border-border p-4 sm:p-5 flex flex-col items-center justify-center shrink-0 overflow-hidden relative">
            <!-- Subtle ambient glow circles -->
            <div class="absolute -top-12 -right-12 size-48 rounded-full bg-primary/10 blur-3xl pointer-events-none"></div>
            <div class="absolute -bottom-12 -left-12 size-48 rounded-full bg-primary/10 blur-3xl pointer-events-none"></div>
            
            <!-- Preview Mode Switcher (Recording Screen vs Invite Message) -->
            <div class="flex items-center gap-1 bg-white/80 dark:bg-card/80 backdrop-blur-md p-1 rounded-xl mb-3 border border-border/80 shadow-xs z-20">
              <button
                type="button"
                @click="previewMode = 'video_page'"
                class="px-2.5 py-1 text-[11px] font-semibold rounded-lg transition-all cursor-pointer"
                :class="previewMode === 'video_page' ? 'bg-primary text-primary-foreground shadow-xs' : 'text-muted-foreground hover:text-foreground'"
              >
                🎥 Video Page
              </button>
              <button
                type="button"
                @click="previewMode = 'invite_message'"
                class="px-2.5 py-1 text-[11px] font-semibold rounded-lg transition-all cursor-pointer"
                :class="previewMode === 'invite_message' ? 'bg-primary text-primary-foreground shadow-xs' : 'text-muted-foreground hover:text-foreground'"
              >
                💬 {{ previewChannel }} Invite
              </button>
            </div>

            <!-- Clean Borderless Mobile Frame -->
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
              <!-- 1. VIDEO TESTIMONIAL RECORDING SCREEN PREVIEW -->
              <!-- ============================================== -->
              <div v-if="previewMode === 'video_page'" class="flex-1 flex flex-col overflow-hidden">
                <!-- Video App Header Bar -->
                <div class="px-3.5 py-2 flex items-center justify-between border-b border-border/40 shrink-0 bg-muted/20">
                  <div class="flex items-center gap-1.5 min-w-0">
                    <div class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[9px] shrink-0">
                      AD
                    </div>
                    <span class="text-[11px] font-semibold text-foreground truncate">Apex Dental · Video Reviews</span>
                  </div>
                  <div class="flex items-center gap-1 text-[10px] text-muted-foreground font-mono">
                    <Clock class="size-3 text-primary" /> {{ form.maxDuration.split(' ')[0] }}s
                  </div>
                </div>

                <!-- Video Content Area -->
                <div class="flex-1 overflow-y-auto p-3 space-y-2.5 hide-scrollbar bg-slate-50/60 dark:bg-slate-900/40">
                  <!-- Video Request Card -->
                  <div class="p-3 bg-white dark:bg-card border border-border/60 rounded-2xl shadow-xs space-y-2.5">
                    <div class="text-[12px] font-bold text-foreground leading-tight">
                      {{ formattedHeadline }}
                    </div>
                    <div class="text-[11px] leading-relaxed text-muted-foreground font-normal whitespace-pre-wrap">
                      {{ formattedPromptMessage }}
                    </div>

                    <!-- Guiding Prompts Card -->
                    <div v-if="parsedQuestions.length" class="p-2.5 bg-primary/5 border border-primary/15 rounded-xl space-y-1.5">
                      <div class="text-[10.5px] font-semibold text-primary flex items-center gap-1">
                        <Sparkles class="size-3" /> Guiding Questions:
                      </div>
                      <ul class="text-[10px] text-muted-foreground space-y-1 pl-1">
                        <li v-for="(q, idx) in parsedQuestions" :key="idx" class="flex items-start gap-1">
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
                        <span class="text-[8.5px] text-white/60 font-mono">00:00 / {{ form.maxDuration.split(' ')[0] }}s</span>
                      </div>
                    </div>

                    <!-- Primary Recording CTA Button -->
                    <div class="pt-0.5">
                      <div class="w-full py-2 rounded-xl bg-primary text-primary-foreground text-[10.5px] font-semibold flex items-center justify-center gap-1.5 shadow-xs cursor-pointer hover:bg-primary/90 transition-all">
                        <div class="size-2 rounded-full bg-red-400 animate-pulse"></div>
                        <span>{{ form.buttonText }}</span>
                      </div>
                      <div class="text-[8.5px] text-center text-muted-foreground pt-1.5">
                        Instant browser recording · No app required
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- ============================================== -->
              <!-- 2. INVITE MESSAGE PREVIEWS (Email / WhatsApp / SMS) -->
              <!-- ============================================== -->
              <div v-else class="flex-1 flex flex-col overflow-hidden">
                <!-- EMAIL PREVIEW -->
                <div v-if="previewChannel === 'Email'" class="flex-1 flex flex-col overflow-hidden">
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
                  <div class="flex-1 overflow-y-auto p-3 space-y-2.5 hide-scrollbar bg-slate-50/60 dark:bg-slate-900/30">
                    <div class="space-y-1 pb-2 border-b border-border/40">
                      <div class="text-[12px] font-bold text-foreground leading-tight">{{ formattedEmailSubject }}</div>
                      <div class="flex items-center justify-between pt-1">
                        <div class="flex items-center gap-2 min-w-0">
                          <div class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[10px] shrink-0">AD</div>
                          <div class="min-w-0">
                            <div class="text-[11px] font-semibold text-foreground truncate">Apex Dental</div>
                            <div class="text-[9px] text-muted-foreground truncate">to sarah.j@gmail.com</div>
                          </div>
                        </div>
                        <span class="text-[9px] text-muted-foreground shrink-0">9:41 AM</span>
                      </div>
                    </div>
                    <div class="p-3 bg-white dark:bg-card border border-border/60 rounded-2xl shadow-xs space-y-3">
                      <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap text-foreground font-normal">
                        {{ formattedEmailBody }}
                      </div>
                      <div class="pt-1">
                        <div class="p-2.5 rounded-xl bg-primary/10 border border-primary/20 text-center space-y-2">
                          <div class="text-[11px] font-semibold text-primary">Record Video Review</div>
                          <div class="w-full py-1.5 rounded-lg bg-primary text-primary-foreground text-[10.5px] font-semibold flex items-center justify-center gap-1 shadow-xs">
                            <Video class="size-3" />
                            <span>{{ form.buttonText }}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- WHATSAPP PREVIEW -->
                <div v-else-if="previewChannel === 'WhatsApp'" class="flex-1 flex flex-col overflow-hidden">
                  <div class="px-3 py-2 bg-emerald-600 dark:bg-emerald-700 text-white flex items-center justify-between shrink-0 shadow-xs">
                    <div class="flex items-center gap-2 min-w-0">
                      <ChevronLeft class="size-4 shrink-0" />
                      <div class="size-7 rounded-full bg-white/20 text-white flex items-center justify-center font-bold text-[10.5px] shrink-0 border border-white/30">AD</div>
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
                  <div class="flex-1 overflow-y-auto p-3 space-y-2.5 bg-[#ECE5DD]/40 dark:bg-slate-900/60 hide-scrollbar">
                    <div class="space-y-1.5 max-w-[94%]">
                      <div class="bg-white dark:bg-slate-800 text-foreground rounded-2xl rounded-tl-xs p-3 shadow-xs border border-border/40 text-xs space-y-2">
                        <div class="text-[12px] font-semibold text-foreground">{{ formattedWhatsAppHeader }}</div>
                        <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap text-foreground font-normal">{{ formattedWhatsAppBody }}</div>
                        <div class="p-2 bg-emerald-500/10 border border-emerald-500/20 rounded-xl space-y-1">
                          <div class="text-[10px] font-semibold text-foreground truncate">🎥 Video Review Link</div>
                          <div class="text-[9px] font-mono text-emerald-600 dark:text-emerald-400 flex items-center gap-1 truncate">
                            <span>relay.to/v/apex-dental</span>
                            <ExternalLink class="size-2 shrink-0" />
                          </div>
                        </div>
                        <div class="flex items-center justify-end gap-1 text-[8.5px] text-muted-foreground">
                          <span>9:41 AM</span>
                          <span class="text-sky-500 font-bold">✓✓</span>
                        </div>
                      </div>
                      <div class="space-y-1">
                        <div class="w-full py-1.5 rounded-xl bg-white dark:bg-slate-800 border border-border/60 text-[10.5px] font-semibold text-emerald-600 dark:text-emerald-400 text-center shadow-xs">
                          {{ form.whatsappButton1 }}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- SMS PREVIEW -->
                <div v-else class="flex-1 flex flex-col overflow-hidden">
                  <div class="px-3.5 py-2 flex items-center justify-between border-b border-border/40 shrink-0 bg-muted/20">
                    <div class="flex items-center gap-1 text-primary">
                      <ChevronLeft class="size-4 shrink-0" />
                      <span class="text-[11px] font-medium">Messages</span>
                    </div>
                    <div class="flex flex-col items-center">
                      <div class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[9px]">AD</div>
                      <span class="text-[9.5px] font-semibold text-foreground">Apex Dental</span>
                    </div>
                    <Info class="size-3.5 text-primary shrink-0" />
                  </div>
                  <div class="flex-1 overflow-y-auto p-3 space-y-2.5 bg-slate-50/50 dark:bg-slate-900/40 hide-scrollbar">
                    <div class="text-[9.5px] text-center text-muted-foreground font-medium">Text Message · Today 9:41 AM</div>
                    <div class="space-y-1 max-w-[94%]">
                      <div class="bg-primary text-primary-foreground rounded-2xl rounded-tl-xs p-3 shadow-xs text-xs space-y-2">
                        <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap font-normal">{{ formattedSmsBody }}</div>
                        <div class="p-2 bg-white/15 backdrop-blur-sm border border-white/20 rounded-xl space-y-1 text-primary-foreground">
                          <div class="flex items-center justify-between gap-1">
                            <span class="text-[10px] font-semibold truncate">Apex Dental · Video Record</span>
                            <Video class="size-3" />
                          </div>
                          <div class="text-[9px] font-mono opacity-90 truncate">relay.to/v/apex-dental</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

            </div>

            <div class="text-center mt-2.5">
              <span class="text-[11px] text-muted-foreground font-medium">
                {{ previewMode === 'video_page' ? 'Video Testimonial Recording Screen' : `${previewChannel} Invite Preview` }}
              </span>
            </div>

          </div>
        </div>

        <!-- STEP 4: Review & Send -->
        <div v-if="currentStep === 4" class="p-8 space-y-8 animate-in slide-in-from-right-4 duration-300">
          <div class="space-y-8 max-w-4xl mx-auto">
            
            <div class="text-center">
              <div class="inline-flex items-center justify-center size-12 rounded-full bg-primary/10 text-primary mb-4 border border-primary/20">
                <CheckCircle2 class="size-6" />
              </div>
              <h2 class="text-base font-medium text-foreground mb-2">Ready to Launch Video Request?</h2>
              <p class="text-muted-foreground text-sm">Verify your video campaign settings and targeted recipients.</p>
            </div>
            
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 items-stretch">
              <!-- Left Column: Settings Cards -->
              <div class="flex flex-col gap-4">
                <!-- Channels Card -->
                <div class="bg-card border border-border rounded-xl p-5 shadow-xs flex items-center gap-4 transition-all">
                  <div class="size-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0 border border-primary/20">
                    <MessageSquare class="size-4 text-primary" />
                  </div>
                  <div>
                    <div class="text-xs text-muted-foreground mb-0.5">Delivery Channels</div>
                    <div class="text-sm font-medium text-foreground">
                      {{ form.channels.length > 0 ? form.channels.join(' + ') : 'None Selected' }}
                    </div>
                  </div>
                </div>

                <!-- Recipients Card -->
                <div class="bg-card border border-border rounded-xl p-5 shadow-xs flex items-center gap-4 transition-all">
                  <div class="size-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0 border border-primary/20">
                    <Users class="size-4 text-primary" />
                  </div>
                  <div>
                    <div class="text-xs text-muted-foreground mb-0.5">Recipients</div>
                    <div class="text-sm font-medium text-foreground">
                      {{ form.selectedCustomers.length }} Shortlisted Customers
                    </div>
                  </div>
                </div>

                <!-- Video Template & Duration Card -->
                <div class="bg-card border border-border rounded-xl p-5 shadow-xs flex items-center gap-4 transition-all">
                  <div class="size-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0 border border-primary/20">
                    <Video class="size-4 text-primary" />
                  </div>
                  <div>
                    <div class="text-xs text-muted-foreground mb-0.5">Template & Duration</div>
                    <div class="text-sm font-medium text-foreground">
                      {{ currentActiveTemplate.name }} ({{ form.maxDuration }})
                    </div>
                  </div>
                </div>

                <!-- Schedule Card -->
                <div class="bg-card border border-border rounded-xl p-5 shadow-xs flex items-center gap-4 transition-all">
                  <div class="size-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0 border border-primary/20">
                    <Clock class="size-4 text-primary" />
                  </div>
                  <div>
                    <div class="text-xs text-muted-foreground mb-0.5">Schedule</div>
                    <div class="text-sm font-medium text-foreground">
                      {{ form.delivery === 'Schedule' ? `${form.scheduleDate} at ${form.scheduleTime}` : 'Send Immediately' }}
                    </div>
                  </div>
                </div>
              </div>
              
              <!-- Right Column: Video Prompt & Summary Box -->
              <div class="bg-muted/20 border border-border rounded-xl overflow-hidden shadow-xs h-full flex flex-col">
                <div class="bg-muted/40 border-b border-border px-4 py-3 flex items-center justify-between shrink-0">
                  <div class="flex items-center gap-2">
                    <MonitorPlay class="size-4 text-primary" />
                    <span class="text-sm font-medium text-foreground">Video Request Summary</span>
                  </div>
                  <Badge variant="outline" class="text-[11px] font-normal text-muted-foreground">
                    {{ form.channels.join(' + ') }}
                  </Badge>
                </div>
                <div class="p-5 flex-1 overflow-y-auto space-y-4">
                  <div class="space-y-1.5">
                    <div class="text-xs font-semibold text-primary flex items-center gap-1.5">
                      <Sparkles class="size-3.5" /> Recording Page Headline & Prompt
                    </div>
                    <div class="bg-card border border-border rounded-xl p-3.5 text-[13px] shadow-xs leading-relaxed space-y-2">
                      <div class="font-semibold text-foreground border-b border-border/60 pb-1">{{ formattedHeadline }}</div>
                      <div class="text-muted-foreground">{{ formattedPromptMessage }}</div>
                      <div v-if="parsedQuestions.length" class="pt-1 text-[12px] space-y-1">
                        <span class="font-medium text-foreground block">Guiding Prompts:</span>
                        <div v-for="(q, idx) in parsedQuestions" :key="idx" class="text-muted-foreground flex items-center gap-1.5">
                          <span class="size-1.5 rounded-full bg-primary"></span>
                          <span>{{ q }}</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="space-y-1.5">
                    <div class="text-xs font-semibold text-primary flex items-center gap-1.5">
                      <Settings2 class="size-3.5" /> Relay AI Video Processing Enabled
                    </div>
                    <div class="flex flex-wrap gap-1.5">
                      <Badge v-if="form.transcript" variant="secondary" class="text-xs">✓ Auto-Transcript</Badge>
                      <Badge v-if="form.summarize" variant="secondary" class="text-xs">✓ AI Summary</Badge>
                      <Badge v-if="form.sentiment" variant="secondary" class="text-xs">✓ Sentiment Analysis</Badge>
                    </div>
                  </div>
                </div>
              </div>
            </div>

          </div>
        </div>
        
        <!-- STEP 5: Success Screen -->
        <div v-if="currentStep === 5" class="py-16 flex flex-col items-center text-center animate-in zoom-in-95 duration-500 flex-1">
          <div class="size-20 bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 rounded-full flex items-center justify-center mb-6">
            <CheckCircle2 class="size-10" />
          </div>
          <h2 class="text-base font-medium text-foreground mb-2">Video Testimonial Requests Dispatched!</h2>
          <p class="text-muted-foreground mb-10 text-sm">{{ form.selectedCustomers.length }} customers shortlisted across {{ form.channels.join(' + ') }}</p>
          
          <div class="flex items-center justify-center gap-8 mb-10">
            <div class="text-center" v-for="channel in form.channels" :key="channel">
              <div class="size-12 rounded-full bg-muted/50 flex items-center justify-center mx-auto mb-2 border border-border">
                <MessageCircle class="size-5 text-primary" v-if="channel === 'WhatsApp'" />
                <Mail class="size-5 text-primary" v-if="channel === 'Email'" />
                <Smartphone class="size-5 text-primary" v-if="channel === 'SMS'" />
              </div>
              <div class="font-bold text-xl text-foreground">{{ form.selectedCustomers.length }}</div>
              <div class="text-xs text-muted-foreground">{{ channel }}</div>
            </div>
          </div>
          
          <div class="flex flex-wrap justify-center gap-3">
            <Button class="gap-2 px-8 h-11"><BarChart3 class="size-4" /> View Video Queue</Button>
            <Button variant="outline" class="gap-2 px-8 h-11 border border-border hover:border-transparent" @click="close">Done</Button>
            <Button variant="ghost" class="gap-2 px-6 h-11 text-muted-foreground border border-border hover:border-transparent" @click="currentStep = 1">Send Another</Button>
          </div>
        </div>

      </div>
      
      <!-- Footer Actions -->
      <div v-if="currentStep < 5" class="px-6 py-4 border-t border-border bg-muted/10 flex items-center justify-between shrink-0">
        <Button variant="ghost" class="text-muted-foreground border border-border hover:border-transparent" @click="prevStep" :disabled="currentStep === 1">
          <ArrowLeft class="size-4 mr-2" v-if="currentStep > 1" />
          Back
        </Button>
        <Button 
          v-if="currentStep < 4" 
          class="gap-2 px-8" 
          @click="nextStep" 
          :disabled="(currentStep === 1 && form.channels.length === 0) || (currentStep === 2 && form.selectedCustomers.length === 0)"
        >
          Next
          <ChevronRight class="size-4" />
        </Button>
        <Button v-else-if="currentStep === 4" class="gap-2 px-8 bg-primary hover:bg-primary text-white" @click="generateReport">
          <Send class="size-4 mr-1" /> Send Video Requests
        </Button>
      </div>

    </div>
  </div>
</template>
