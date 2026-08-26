<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { 
  X, ChevronRight, Search, FileText, CheckCircle2, 
  Copy, ArrowLeft, Send, Sparkles, MessageSquare, 
  Mail, MessageCircle, Star, Phone, Smartphone, 
  Upload, Clock, Check, BarChart3, Bot, Settings2,
  Calendar, ChevronLeft, Users, AlertCircle, AlertTriangle, ExternalLink,
  Signal, Wifi, MoreVertical, Paperclip, Smile, Mic, Trash2, Archive, Video, Info,
  LayoutTemplate, ChevronDown
} from 'lucide-vue-next'
import { 
  Button, Input, Checkbox, Badge,
  DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem
} from '@/components/ui'
import {
  type SmsTemplateItem,
  type EmailTemplateItem,
  type WhatsAppTemplateItem,
  defaultSmsTemplates,
  defaultEmailTemplates,
  defaultWhatsAppTemplates
} from '../data/outreachTemplates'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  (e: 'update:open', value: boolean): void
}>()

// Default State for Reset
const defaultFormState = {
  selectedCustomers: [] as string[],
  customRecipients: '',
  channels: ['Email'] as string[],
  delivery: 'Send immediately',
  scheduleDate: '',
  scheduleTime: '',
  scheduleTimezone: '',
  tone: 'Friendly',
  destination: 'Google'
}

const currentStep = ref(1)
const form = ref({ ...defaultFormState })
const searchQuery = ref('')
const activeFilter = ref('Recent Customers')
const previewChannel = ref<string>('Email')
const activeEditingChannel = ref<string>('Email')

// Templates State
const prebuiltSms = ref<SmsTemplateItem[]>([...defaultSmsTemplates])
const prebuiltEmail = ref<EmailTemplateItem[]>([...defaultEmailTemplates])
const prebuiltWhatsApp = ref<WhatsAppTemplateItem[]>([...defaultWhatsAppTemplates])

const selectedSmsTemplateId = ref('sms_post_visit')
const selectedEmailTemplateId = ref('email_standard_5star')
const selectedWhatsAppTemplateId = ref('wa_friendly_checkin')

// Channel-specific message state
const smsMessage = ref(defaultSmsTemplates[0].message)
const emailSubject = ref(defaultEmailTemplates[0].subject)
const emailBody = ref(defaultEmailTemplates[0].body)
const whatsappHeader = ref(defaultWhatsAppTemplates[0].headerText)
const whatsappBody = ref(defaultWhatsAppTemplates[0].bodyText)
const whatsappButton1 = ref(defaultWhatsAppTemplates[0].button1)
const whatsappButton2 = ref(defaultWhatsAppTemplates[0].button2)

const isAiEnhancing = ref(false)

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

// Template Selection Helper
const currentChannelTemplates = computed(() => {
  if (activeEditingChannel.value === 'SMS') return prebuiltSms.value
  if (activeEditingChannel.value === 'Email') return prebuiltEmail.value
  return prebuiltWhatsApp.value
})

const currentActiveTemplateId = computed(() => {
  if (activeEditingChannel.value === 'SMS') return selectedSmsTemplateId.value
  if (activeEditingChannel.value === 'Email') return selectedEmailTemplateId.value
  return selectedWhatsAppTemplateId.value
})

const currentActiveTemplateName = computed(() => {
  const list = currentChannelTemplates.value
  const found = list.find((t: any) => t.id === currentActiveTemplateId.value)
  return found ? found.name : 'Select a template...'
})

function selectTemplate(template: any, channel: string) {
  if (channel === 'SMS') {
    selectedSmsTemplateId.value = template.id
    smsMessage.value = template.message
  } else if (channel === 'Email') {
    selectedEmailTemplateId.value = template.id
    emailSubject.value = template.subject
    emailBody.value = template.body
  } else if (channel === 'WhatsApp') {
    selectedWhatsAppTemplateId.value = template.id
    whatsappHeader.value = template.headerText
    whatsappBody.value = template.bodyText
    whatsappButton1.value = template.button1
    whatsappButton2.value = template.button2
  }
}

function insertVariable(variable: string) {
  if (activeEditingChannel.value === 'SMS') {
    smsMessage.value += ` ${variable}`
  } else if (activeEditingChannel.value === 'Email') {
    emailBody.value += ` ${variable}`
  } else if (activeEditingChannel.value === 'WhatsApp') {
    whatsappBody.value += ` ${variable}`
  }
}

function enhanceWithAi() {
  isAiEnhancing.value = true
  setTimeout(() => {
    if (activeEditingChannel.value === 'SMS') {
      smsMessage.value = 'Hi {{FirstName}}! We loved serving you at {{BusinessName}}. Could you share a quick 30-second review to help others find us? ⭐ {{ReviewLink}}'
    } else if (activeEditingChannel.value === 'Email') {
      emailSubject.value = '{{FirstName}}, how was your recent visit to {{BusinessName}}?'
      emailBody.value = 'Hi {{FirstName}},\n\nThank you for choosing {{BusinessName}}! Our team takes immense pride in delivering top-quality service. If you had a positive experience with {{EmployeeName}}, we would be thrilled if you left us a quick review.\n\n⭐ Leave your review here:\n{{ReviewLink}}\n\nIt only takes one minute.\n\nWarm regards,\nThe {{BusinessName}} Team'
    } else {
      whatsappHeader.value = 'Hi {{FirstName}} 👋'
      whatsappBody.value = 'Thank you for visiting {{BusinessName}} today! We hope everything went wonderfully. Tap below to share a quick 5-star review:\n\n{{ReviewLink}}'
    }
    isAiEnhancing.value = false
  }, 600)
}

function getChannelIcon(channel: string) {
  if (channel === 'WhatsApp') return MessageCircle
  if (channel === 'Email') return Mail
  return Smartphone
}

// Mock Data
const filters = ['Recent Customers', 'Completed Jobs', 'Closed Deals', 'Positive Feedback', 'Appointment Completed', 'Invoice Paid']

const allCustomers = [
  { id: '1', name: 'Sarah Johnson', email: 'sarah.j@gmail.com', phone: '+1 (555) 234-5678', contextLabel: 'Purchased:', contextValue: '2 days ago' },
  { id: '2', name: 'Michael Brown', email: '', phone: '+1 (555) 876-5432', contextLabel: 'Service Completed:', contextValue: 'Yesterday' },
  { id: '3', name: 'Emily Wilson', email: 'emily.wilson@outlook.com', phone: '+1 (555) 345-6789', contextLabel: 'Appointment:', contextValue: 'Today' },
  { id: '4', name: 'David Miller', email: 'david.m@yahoo.com', phone: '', contextLabel: 'Invoice Paid:', contextValue: 'Today' },
  { id: '5', name: 'Jessica Taylor', email: 'jessica.t@gmail.com', phone: '+1 (555) 456-7890', contextLabel: 'Purchased:', contextValue: '3 days ago' },
  { id: '6', name: 'Robert Anderson', email: '', phone: '+1 (555) 567-8901', contextLabel: 'Service Completed:', contextValue: 'Yesterday' },
  { id: '7', name: 'Amanda Thomas', email: 'amanda.t@hotmail.com', phone: '+1 (555) 678-9012', contextLabel: 'Appointment:', contextValue: 'Today' },
  { id: '8', name: 'James Jackson', email: 'james.j@gmail.com', phone: '', contextLabel: 'Invoice Paid:', contextValue: 'Yesterday' }
]

// Channel eligibility logic
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
  if (searchQuery.value) {
    list = list.filter(c => c.name.toLowerCase().includes(searchQuery.value.toLowerCase()))
  }
  return list
})

// Automatically sanitize selected customers when channel changes
watch(() => form.value.channels, () => {
  const validIds = new Set(eligibleCustomers.value.map(c => c.id))
  form.value.selectedCustomers = form.value.selectedCustomers.filter(id => validIds.has(id))
}, { deep: true })

// Formatted live previews
const formattedEmailSubject = computed(() => {
  return emailSubject.value
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'New Relay')
    .replaceAll('{{EmployeeName}}', 'Alex')
})

const formattedEmailBody = computed(() => {
  return emailBody.value
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'New Relay')
    .replaceAll('{{ReviewLink}}', 'newrelay.com/r/abc123')
    .replaceAll('{{EmployeeName}}', 'Alex')
})

const formattedSmsBody = computed(() => {
  return smsMessage.value
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'New Relay')
    .replaceAll('{{ReviewLink}}', 'newrelay.com/r/abc123')
    .replaceAll('{{EmployeeName}}', 'Alex')
})

const formattedWhatsAppHeader = computed(() => {
  return whatsappHeader.value
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'New Relay')
})

const formattedWhatsAppBody = computed(() => {
  return whatsappBody.value
    .replaceAll('{{FirstName}}', 'Sarah')
    .replaceAll('{{BusinessName}}', 'New Relay')
    .replaceAll('{{ReviewLink}}', 'newrelay.com/r/abc123')
    .replaceAll('{{EmployeeName}}', 'Alex')
})

const channels = [
  { name: 'WhatsApp', icon: MessageCircle, rate: '98%', color: 'text-primary', bg: 'bg-primary/10' },
  { name: 'Email', icon: Mail, rate: '92%', color: 'text-primary', bg: 'bg-primary/10' },
  { name: 'SMS', icon: Smartphone, rate: '96%', color: 'text-primary', bg: 'bg-primary/10' }
]

const tones = ['Friendly', 'Professional', 'Luxury', 'Casual']
const destinations = ['Google', 'Facebook', 'Trustpilot', 'Yelp', 'Custom Link']

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
  setTimeout(() => {
    currentStep.value = 5
  }, 800)
}

function close() {
  emit('update:open', false)
  setTimeout(() => {
    currentStep.value = 1
    form.value = { ...defaultFormState }
    form.value.selectedCustomers = []
    form.value.channels = ['Email']
    form.value.destination = 'Google'
    selectedSmsTemplateId.value = 'sms_post_visit'
    selectedEmailTemplateId.value = 'email_standard_5star'
    selectedWhatsAppTemplateId.value = 'wa_friendly_checkin'
    smsMessage.value = defaultSmsTemplates[0].message
    emailSubject.value = defaultEmailTemplates[0].subject
    emailBody.value = defaultEmailTemplates[0].body
    whatsappHeader.value = defaultWhatsAppTemplates[0].headerText
    whatsappBody.value = defaultWhatsAppTemplates[0].bodyText
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
          <h2 class="text-base font-semibold text-foreground">Request Customer Reviews</h2>
          <div class="flex items-center gap-2 mt-1.5 text-xs font-medium">
            <span :class="currentStep >= 1 ? 'text-primary font-semibold' : 'text-muted-foreground'">1. Channel</span>
            <ChevronRight class="size-3.5 text-muted-foreground/50" />
            <span :class="currentStep >= 2 ? 'text-primary font-semibold' : 'text-muted-foreground'">2. Recipients</span>
            <ChevronRight class="size-3.5 text-muted-foreground/50" />
            <span :class="currentStep >= 3 ? 'text-primary font-semibold' : 'text-muted-foreground'">3. Message</span>
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
              <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Select Delivery Channels (Multiple Allowed)</h3>
              <p class="text-[13px] text-muted-foreground mt-0.5">Choose which channels you will use to send review requests. Next step will automatically shortlist contacts with valid details.</p>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div 
                v-for="channel in channels" :key="channel.name"
                class="relative border-2 rounded-xl p-5 cursor-pointer transition-all overflow-hidden group"
                :class="form.channels.includes(channel.name) ? 'border-primary bg-primary/5 shadow-sm' : 'border-border bg-card hover:border-primary/50'"
                @click="toggleSelection(form.channels, channel.name)"
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
          <div class="w-64 border-r border-border bg-muted/10 p-4 space-y-6 hidden md:block shrink-0">
            <div>
              <h3 class="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">Quick Filters</h3>
              <div class="space-y-1">
                <button 
                  v-for="filter in filters" :key="filter"
                  class="w-full text-left px-3 py-2 rounded-md text-sm transition-colors"
                  :class="activeFilter === filter ? 'bg-primary/10 text-primary font-medium' : 'text-muted-foreground hover:bg-muted/50 hover:text-foreground'"
                  @click="activeFilter = filter"
                >
                  {{ filter }}
                </button>
              </div>
            </div>
            <div class="pt-4 border-t border-border space-y-4">
              <Button variant="outline" class="w-full justify-start text-muted-foreground text-sm border border-border hover:border-transparent">
                <Upload class="size-4 mr-2" /> Import CSV
              </Button>
              
              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">Manual Entry</label>
                <Input v-model="form.customRecipients" placeholder="Emails or phone numbers..." class="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30" />
              </div>
            </div>
          </div>
          
          <!-- Main Content -->
          <div class="flex-1 p-6 flex flex-col">
            <!-- Red Shortlist Alert Banner -->
            <div v-if="excludedCount > 0" class="flex items-center gap-2.5 p-3 mb-4 bg-destructive/10 border border-destructive/20 rounded-xl text-destructive text-[13px] animate-in fade-in">
              <AlertCircle class="size-4 shrink-0" />
              <span>
                <strong class="font-semibold">{{ excludedCount }} contact{{ excludedCount > 1 ? 's' : '' }}</strong> without a {{ channelRequirementText }} {{ excludedCount > 1 ? 'have' : 'has' }} been automatically removed from this list for <strong class="font-semibold">{{ form.channels.join(' + ') }}</strong> outreach.
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
                  <div class="font-medium text-foreground text-sm truncate">{{ customer.name }}</div>
                  
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

        <!-- STEP 3: Customize Request & Select Pre-built Templates -->
        <div v-if="currentStep === 3" class="flex-1 flex flex-col lg:flex-row animate-in slide-in-from-right-4 duration-300 min-h-[500px] overflow-hidden">
          <!-- Editor Side -->
          <div class="flex-1 p-5 sm:p-6 space-y-5 overflow-y-auto">
            
            <!-- Channel Switcher Tabs (If multiple channels chosen in Step 1) -->
            <div v-if="form.channels.length > 1" class="flex items-center justify-between gap-3 pb-3 border-b border-border">
              <span class="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Configure Channel:</span>
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

            <!-- Pre-built Template Selector Dropdown (Channel-Aware) -->
            <div class="bg-muted/20 border border-border rounded-xl p-4 space-y-2">
              <div class="flex items-center justify-between">
                <label class="text-[13.5px] font-medium text-foreground flex items-center gap-1.5">
                  <LayoutTemplate class="size-4 text-primary" />
                  Select Pre-built {{ activeEditingChannel }} Template
                </label>
                <Badge variant="outline" class="text-[11px] font-normal text-muted-foreground py-0.5">
                  {{ currentChannelTemplates.length }} templates available
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
                      <span class="truncate font-medium">{{ currentActiveTemplateName }}</span>
                    </div>
                    <ChevronDown class="size-3.5 opacity-50 ml-2 shrink-0" />
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="w-[380px] max-h-[320px] overflow-y-auto" align="start">
                  <DropdownMenuItem 
                    v-for="t in currentChannelTemplates" 
                    :key="t.id"
                    @click="selectTemplate(t, activeEditingChannel)"
                    class="flex items-center justify-between py-2.5 px-3 cursor-pointer"
                  >
                    <div class="flex flex-col gap-0.5 min-w-0 pr-2">
                      <span class="text-[13px] font-medium text-foreground truncate">{{ t.name }}</span>
                      <span class="text-[11px] text-muted-foreground truncate">{{ t.autoDelay }}</span>
                    </div>
                    <Check v-if="currentActiveTemplateId === t.id" class="size-4 text-primary shrink-0" />
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

            <!-- EMAIL CHANNEL EDITOR -->
            <template v-if="activeEditingChannel === 'Email'">
              <div class="space-y-4">
                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">Email Subject Line</label>
                  <Input v-model="emailSubject" class="h-9 text-[14px]" />
                </div>

                <div class="flex flex-col gap-2">
                  <div class="flex items-center justify-between">
                    <label class="text-[13.5px] font-medium text-foreground">Email Body Copy</label>
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
                    v-model="emailBody"
                    rows="5"
                    class="w-full text-[13.5px] p-3.5 shadow-xs rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"
                  ></textarea>
                </div>
              </div>
            </template>

            <!-- SMS CHANNEL EDITOR -->
            <template v-else-if="activeEditingChannel === 'SMS'">
              <div class="space-y-4">
                <div class="flex flex-col gap-2">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-2">
                      <label class="text-[13.5px] font-medium text-foreground">SMS Message Content</label>
                      <span class="text-[11.5px] text-muted-foreground font-mono">({{ smsMessage.length }} / 160 chars)</span>
                    </div>
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
                    v-model="smsMessage"
                    rows="4"
                    class="w-full text-[13.5px] p-3.5 shadow-xs rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"
                  ></textarea>
                </div>
              </div>
            </template>

            <!-- WHATSAPP CHANNEL EDITOR -->
            <template v-else>
              <div class="space-y-4">
                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">WhatsApp Header Greeting</label>
                  <Input v-model="whatsappHeader" class="h-9 text-[14px]" />
                </div>

                <div class="flex flex-col gap-2">
                  <div class="flex items-center justify-between">
                    <label class="text-[13.5px] font-medium text-foreground">WhatsApp Body Content</label>
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
                    v-model="whatsappBody"
                    rows="4"
                    class="w-full text-[13.5px] p-3.5 shadow-xs rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"
                  ></textarea>
                </div>
              </div>
            </template>
            
            <!-- Insert Dynamic Variables -->
            <div class="space-y-2">
              <p class="text-[11px] font-medium text-muted-foreground uppercase tracking-wider">Insert Variables</p>
              <div class="flex flex-wrap gap-1.5">
                <Badge 
                  v-for="v in ['{{FirstName}}', '{{BusinessName}}', '{{ReviewLink}}', '{{EmployeeName}}']" 
                  :key="v" 
                  variant="secondary" 
                  class="font-mono text-[11px] cursor-pointer hover:bg-primary/20 transition-colors"
                  @click="insertVariable(v)"
                >
                  {{ v }}
                </Badge>
              </div>
            </div>

            <!-- Tone & Destination Selector -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-4 border-t border-border">
              <!-- Tone Selector -->
              <div class="space-y-2.5">
                <p class="text-[11px] font-medium text-muted-foreground uppercase tracking-wider">Tone</p>
                <div class="grid grid-cols-2 gap-1.5">
                  <div 
                    v-for="tone in tones" :key="tone"
                    class="px-2.5 py-1.5 rounded-lg border text-xs text-center cursor-pointer transition-colors"
                    :class="form.tone === tone ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                    @click="form.tone = tone"
                  >
                    {{ tone }}
                  </div>
                </div>
              </div>

              <!-- Review Destination -->
              <div class="space-y-2.5">
                <p class="text-[11px] font-medium text-muted-foreground uppercase tracking-wider">Review Destination</p>
                <div class="flex flex-wrap gap-1.5">
                  <button 
                    v-for="dest in destinations" 
                    :key="dest"
                    type="button"
                    class="px-3 py-1.5 rounded-full border text-xs cursor-pointer transition-all flex items-center gap-1.5"
                    :class="form.destination === dest 
                      ? 'bg-primary/10 border-primary text-primary font-semibold shadow-2xs' 
                      : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                    @click="form.destination = dest"
                  >
                    <Check v-if="form.destination === dest" class="size-3 shrink-0 text-primary" />
                    <span>{{ dest }}</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Preview Side (Dynamic Native Phone Interface tailored to selected channel) -->
          <div class="w-full lg:w-[325px] xl:w-[345px] bg-slate-100/70 dark:bg-slate-900/40 backdrop-blur-xl border-t lg:border-t-0 lg:border-l border-border p-4 sm:p-5 flex flex-col items-center justify-center shrink-0 overflow-hidden relative">
            <!-- Subtle decorative ambient glow circles -->
            <div class="absolute -top-12 -right-12 size-48 rounded-full bg-primary/10 blur-3xl pointer-events-none"></div>
            <div class="absolute -bottom-12 -left-12 size-48 rounded-full bg-primary/10 blur-3xl pointer-events-none"></div>
            
            <!-- Channel Switcher on Preview (If multiple selected) -->
            <div v-if="form.channels.length > 1" class="flex items-center gap-1 bg-white/80 dark:bg-card/80 backdrop-blur-md p-1 rounded-xl mb-3 border border-border/80 shadow-xs z-20">
              <button
                v-for="ch in form.channels"
                :key="ch"
                @click="previewChannel = ch; activeEditingChannel = ch"
                type="button"
                :class="[
                  'px-2.5 py-1 text-[11px] font-semibold rounded-lg transition-all cursor-pointer',
                  previewChannel === ch 
                    ? 'bg-primary text-primary-foreground shadow-xs' 
                    : 'text-muted-foreground hover:text-foreground'
                ]"
              >
                {{ ch }}
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
              <!-- 1. EMAIL CLIENT INTERFACE -->
              <!-- ============================================== -->
              <div v-if="previewChannel === 'Email'" class="flex-1 flex flex-col overflow-hidden">
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
                      {{ formattedEmailSubject }}
                    </div>
                    <div class="flex items-center justify-between pt-1">
                      <div class="flex items-center gap-2 min-w-0">
                        <div class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[10px] shrink-0">
                          NR
                        </div>
                        <div class="min-w-0">
                          <div class="text-[11px] font-semibold text-foreground truncate">New Relay</div>
                          <div class="text-[9px] text-muted-foreground truncate">to sarah.j@gmail.com</div>
                        </div>
                      </div>
                      <span class="text-[9px] text-muted-foreground shrink-0">9:41 AM</span>
                    </div>
                  </div>

                  <!-- Email Body Card -->
                  <div class="p-3 bg-white dark:bg-card border border-border/60 rounded-2xl shadow-xs space-y-3">
                    <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap text-foreground font-normal">
                      {{ formattedEmailBody }}
                    </div>

                    <!-- Direct Review Destination CTA Button -->
                    <div class="pt-1">
                      <div class="p-2.5 rounded-xl bg-primary/10 border border-primary/20 text-center space-y-2">
                        <div class="text-[11px] font-semibold text-primary">
                          Rate on {{ form.destination }}
                        </div>
                        <div class="flex justify-center gap-1 text-amber-500">
                          <Star v-for="s in 5" :key="s" class="size-3.5 fill-amber-500 text-amber-500" />
                        </div>
                        <div class="w-full py-1.5 rounded-lg bg-primary text-primary-foreground text-[10.5px] font-semibold flex items-center justify-center gap-1 shadow-xs">
                          <span>Leave {{ form.destination }} Review</span>
                          <ExternalLink class="size-2.5" />
                        </div>
                      </div>
                    </div>

                    <div class="text-[8.5px] text-center text-muted-foreground border-t border-border/40 pt-2">
                      New Relay Inc. · 123 Innovation Way · Unsubscribe
                    </div>
                  </div>
                </div>
              </div>

              <!-- ============================================== -->
              <!-- 2. WHATSAPP CHAT INTERFACE -->
              <!-- ============================================== -->
              <div v-else-if="previewChannel === 'WhatsApp'" class="flex-1 flex flex-col overflow-hidden">
                <!-- WhatsApp Top Header -->
                <div class="px-3 py-2 bg-emerald-600 dark:bg-emerald-700 text-white flex items-center justify-between shrink-0 shadow-xs">
                  <div class="flex items-center gap-2 min-w-0">
                    <ChevronLeft class="size-4 shrink-0" />
                    <div class="size-7 rounded-full bg-white/20 text-white flex items-center justify-center font-bold text-[10.5px] shrink-0 border border-white/30">
                      NR
                    </div>
                    <div class="min-w-0">
                      <div class="flex items-center gap-1">
                        <span class="text-xs font-semibold truncate text-white">New Relay</span>
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
                  <div class="space-y-1.5 max-w-[94%]">
                    <div class="bg-white dark:bg-slate-800 text-foreground rounded-2xl rounded-tl-xs p-3 shadow-xs border border-border/40 text-xs space-y-2">
                      <div class="text-[12px] font-semibold text-foreground">
                        {{ formattedWhatsAppHeader }}
                      </div>
                      <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap text-foreground font-normal">
                        {{ formattedWhatsAppBody }}
                      </div>

                      <!-- Rich Link Preview -->
                      <div class="p-2 bg-emerald-500/10 border border-emerald-500/20 rounded-xl space-y-1">
                        <div class="flex items-center justify-between gap-1">
                          <span class="text-[10px] font-semibold text-foreground truncate">Rate on {{ form.destination }}</span>
                          <div class="flex gap-0.5 text-amber-500 shrink-0">
                            <Star v-for="s in 5" :key="s" class="size-2 fill-amber-500 text-amber-500" />
                          </div>
                        </div>
                        <div class="text-[9px] font-mono text-emerald-600 dark:text-emerald-400 flex items-center gap-1 truncate">
                          <span>newrelay.com/r/abc123</span>
                          <ExternalLink class="size-2 shrink-0" />
                        </div>
                      </div>

                      <div class="flex items-center justify-end gap-1 text-[8.5px] text-muted-foreground">
                        <span>9:41 AM</span>
                        <span class="text-sky-500 font-bold">✓✓</span>
                      </div>
                    </div>

                    <!-- Quick Action Buttons -->
                    <div class="space-y-1">
                      <div class="w-full py-1.5 rounded-xl bg-white dark:bg-slate-800 border border-border/60 text-[10.5px] font-semibold text-emerald-600 dark:text-emerald-400 text-center shadow-xs">
                        {{ whatsappButton1 }}
                      </div>
                      <div class="w-full py-1.5 rounded-xl bg-white dark:bg-slate-800 border border-border/60 text-[10.5px] font-semibold text-muted-foreground text-center shadow-xs">
                        {{ whatsappButton2 }}
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
              <div v-else class="flex-1 flex flex-col overflow-hidden">
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
                    <span class="text-[9.5px] font-semibold text-foreground">New Relay</span>
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
                        {{ formattedSmsBody }}
                      </div>

                      <!-- Rich Link Preview in SMS -->
                      <div class="p-2 bg-white/15 backdrop-blur-sm border border-white/20 rounded-xl space-y-1 text-primary-foreground">
                        <div class="flex items-center justify-between gap-1">
                          <span class="text-[10px] font-semibold truncate">Rate on {{ form.destination }}</span>
                          <div class="flex gap-0.5 text-amber-300 shrink-0">
                            <Star v-for="s in 5" :key="s" class="size-2 fill-amber-300 text-amber-300" />
                          </div>
                        </div>
                        <div class="text-[9px] font-mono opacity-90 flex items-center gap-1 truncate">
                          <span>newrelay.com/r/abc123</span>
                          <ExternalLink class="size-2 shrink-0" />
                        </div>
                      </div>
                    </div>

                    <div class="text-[8.5px] text-right text-muted-foreground px-1">
                      Delivered
                    </div>
                  </div>
                </div>

                <!-- SMS Bottom Bar -->
                <div class="p-2 bg-white dark:bg-card border-t border-border/40 flex items-center gap-1.5 shrink-0">
                  <div class="size-5 rounded-full bg-muted flex items-center justify-center text-muted-foreground font-bold text-xs shrink-0">+</div>
                  <div class="flex-1 h-6 bg-muted/60 rounded-full px-2.5 text-[9.5px] text-muted-foreground flex items-center truncate">
                    Text Message
                  </div>
                  <div class="size-6 rounded-full bg-primary text-primary-foreground flex items-center justify-center shrink-0 shadow-xs">
                    <Send class="size-2.5" />
                  </div>
                </div>
              </div>

            </div>

            <div class="text-center mt-2.5">
              <span class="text-[11px] text-muted-foreground font-medium">{{ previewChannel }} Outreach Preview</span>
            </div>

          </div>
        </div>

        <!-- STEP 4: Review & Send -->
        <div v-if="currentStep === 4" class="p-8 space-y-8 animate-in slide-in-from-right-4 duration-300">
          <div class="space-y-8 max-w-4xl mx-auto">
            
            <div class="text-center">
              <div class="inline-flex items-center justify-center size-12 rounded-full bg-primary/10 dark:bg-primary/10 text-primary dark:text-primary mb-4 border border-primary/20 dark:border-primary/20">
                <CheckCircle2 class="size-6" />
              </div>
              <h2 class="text-base font-medium text-foreground mb-2">Ready to Send?</h2>
              <p class="text-muted-foreground text-sm">Verify your campaign details before launching.</p>
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

                <!-- Review Platform Card -->
                <div class="bg-card border border-border rounded-xl p-5 shadow-xs flex items-center gap-4 transition-all">
                  <div class="size-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0 border border-primary/20">
                    <Star class="size-4 text-primary" />
                  </div>
                  <div>
                    <div class="text-xs text-muted-foreground mb-0.5">Review Platform</div>
                    <div class="text-sm font-medium text-foreground">
                      {{ form.destination || 'Google' }}
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
              
              <!-- Right Column: Message Preview Box -->
              <div class="bg-muted/20 border border-border rounded-xl overflow-hidden shadow-xs h-full flex flex-col">
                <div class="bg-muted/40 border-b border-border px-4 py-3 flex items-center justify-between shrink-0">
                  <div class="flex items-center gap-2">
                    <FileText class="size-4 text-muted-foreground" />
                    <span class="text-sm font-medium text-foreground">Message Summary</span>
                  </div>
                  <Badge variant="outline" class="text-[11px] font-normal text-muted-foreground">
                    {{ form.channels.join(' + ') }}
                  </Badge>
                </div>
                <div class="p-5 flex-1 overflow-y-auto space-y-4">
                  <div v-if="form.channels.includes('Email')" class="space-y-1.5">
                    <div class="text-xs font-semibold text-primary flex items-center gap-1.5">
                      <Mail class="size-3.5" /> Email Content
                    </div>
                    <div class="bg-card border border-border rounded-xl p-3.5 text-[13px] shadow-xs whitespace-pre-wrap leading-relaxed">
                      <div class="font-semibold text-foreground pb-1.5 mb-1.5 border-b border-border/60">{{ formattedEmailSubject }}</div>
                      {{ formattedEmailBody }}
                    </div>
                  </div>

                  <div v-if="form.channels.includes('SMS')" class="space-y-1.5">
                    <div class="text-xs font-semibold text-primary flex items-center gap-1.5">
                      <Smartphone class="size-3.5" /> SMS Content
                    </div>
                    <div class="bg-card border border-border rounded-xl p-3.5 text-[13px] shadow-xs whitespace-pre-wrap leading-relaxed">
                      {{ formattedSmsBody }}
                    </div>
                  </div>

                  <div v-if="form.channels.includes('WhatsApp')" class="space-y-1.5">
                    <div class="text-xs font-semibold text-primary flex items-center gap-1.5">
                      <MessageCircle class="size-3.5" /> WhatsApp Content
                    </div>
                    <div class="bg-card border border-border rounded-xl p-3.5 text-[13px] shadow-xs whitespace-pre-wrap leading-relaxed">
                      <div class="font-semibold text-foreground pb-1 mb-1">{{ formattedWhatsAppHeader }}</div>
                      {{ formattedWhatsAppBody }}
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
          <h2 class="text-base font-medium text-foreground mb-2">Review Requests Sent!</h2>
          <p class="text-muted-foreground mb-10 text-sm">{{ form.selectedCustomers.length }} customers</p>
          
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
            <Button class="gap-2 px-8 h-11"><BarChart3 class="size-4" /> View Campaign</Button>
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
          :disabled="(currentStep === 1 && form.channels.length === 0) || (currentStep === 2 && form.selectedCustomers.length === 0 && !form.customRecipients)"
        >
          Next
          <ChevronRight class="size-4" />
        </Button>
        <Button v-else-if="currentStep === 4" class="gap-2 px-8 bg-primary hover:bg-primary text-white" @click="generateReport">
          <Send class="size-4 mr-1" /> Send Requests
        </Button>
      </div>

    </div>
  </div>
</template>
