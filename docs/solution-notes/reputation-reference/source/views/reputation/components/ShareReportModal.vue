<script setup lang="ts">
import { ref } from 'vue'
import { 
  X, ChevronRight, FileText, BarChart2, MessageSquare, Monitor, Sparkles,
  PenTool, Calendar, Link as LinkIcon, Download, Mail, CheckCircle2, 
  Copy, ArrowLeft, Image as ImageIcon, FileSpreadsheet, Send, File, Star, StarHalf, Users, Check
} from 'lucide-vue-next'
import { Button, Input, Checkbox, Badge } from '@/components/ui'
import { BarChart } from '@/components/charts'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  (e: 'update:open', value: boolean): void
}>()

const currentStep = ref(1)

const previewChartLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul']
const previewChartSeries = [
  { name: 'Positive', data: [65, 59, 80, 81, 56, 55, 72] },
  { name: 'Negative/Neutral', data: [45, 40, 50, 60, 40, 42, 58] }
]

// Form State
const defaultFormState = {
  reportType: 'Executive Summary',
  dateRange: 'Last 30 Days',
  recipients: ['Myself'],
  emails: '',
  logoName: '',
  
  sections: [] as string[],
  layout: 'Executive',
  
  exportFormat: 'PDF',
  shareMethod: 'Email',
  delivery: 'Send immediately',
  permissions: 'Anyone with link'
}

const form = ref({ ...defaultFormState })

const reportTypes = [
  { name: 'Executive Summary', icon: FileText, recommended: true },
  { name: 'Reputation Overview', icon: BarChart2 },
  { name: 'Reviews Report', icon: MessageSquare },
  { name: 'Listings Report', icon: Monitor },
  { name: 'AI Insights Report', icon: Sparkles },
  { name: 'Custom Report', icon: PenTool },
]

const dateRanges = ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'Custom']
const recipientOptions = ['Myself', 'Team Members', 'Client']
const sectionOptions = ['Reputation Score', 'Average Rating', 'Review Trend', 'Platform Breakdown', 'AI Insights', 'Recent Reviews', 'Unanswered Reviews', 'Listings Health', 'Team Performance']
const layoutOptions = ['Executive', 'Detailed', 'Landscape', 'Portrait']
const exportOptions = [{name: 'PDF', icon: File}, {name: 'PNG', icon: ImageIcon}, {name: 'CSV', icon: FileSpreadsheet}, {name: 'Excel', icon: FileSpreadsheet}]
const shareOptions = [{name: 'Email', icon: Mail}, {name: 'Copy Link', icon: LinkIcon}, {name: 'Slack', icon: MessageSquare}, {name: 'Microsoft Teams', icon: Users}] 

const fileInput = ref<HTMLInputElement | null>(null)

function triggerFileInput() {
  fileInput.value?.click()
}

function handleFileUpload(event: Event) {
  const target = event.target as HTMLInputElement
  if (target.files && target.files.length > 0) {
    form.value.logoName = target.files[0].name
  }
}

function toggleSelection(array: string[], item: string) {
  const index = array.indexOf(item)
  if (index === -1) array.push(item)
  else array.splice(index, 1)
}

function nextStep() {
  if (currentStep.value < 5) currentStep.value++
}

function prevStep() {
  if (currentStep.value > 1) currentStep.value--
}

function generateReport() {
  // Simulate API call
  setTimeout(() => {
    currentStep.value = 5
  }, 800)
}

function close() {
  emit('update:open', false)
  setTimeout(() => {
    currentStep.value = 1
    form.value = { ...defaultFormState }
  }, 300)
}
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6">
    <!-- Backdrop -->
    <div class="absolute inset-0 bg-background/80 backdrop-blur-sm" @click="close"></div>
    
    <!-- Modal -->
    <div class="relative w-full max-w-4xl max-h-[90vh] bg-card rounded-2xl shadow-2xl border border-border flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200">
      
      <!-- Header -->
      <div v-if="currentStep < 5" class="px-6 py-4 border-b border-border flex items-center justify-between bg-muted/30">
        <div>
          <h2 class="text-xl font-semibold text-foreground">Share Reputation Report</h2>
          <div class="flex items-center gap-2 mt-1.5 text-sm">
            <span :class="currentStep >= 1 ? 'text-primary font-medium' : 'text-muted-foreground'">1. Choose</span>
            <ChevronRight class="size-3.5 text-muted-foreground/50" />
            <span :class="currentStep >= 2 ? 'text-primary font-medium' : 'text-muted-foreground'">2. Customize</span>
            <ChevronRight class="size-3.5 text-muted-foreground/50" />
            <span :class="currentStep >= 3 ? 'text-primary font-medium' : 'text-muted-foreground'">3. Preview</span>
            <ChevronRight class="size-3.5 text-muted-foreground/50" />
            <span :class="currentStep >= 4 ? 'text-primary font-medium' : 'text-muted-foreground'">4. Share</span>
          </div>
        </div>
        <Button variant="ghost" size="icon" class="text-muted-foreground" @click="close">
          <X class="size-5" />
        </Button>
      </div>
      
      <!-- Body -->
      <div class="flex-1 overflow-y-auto p-6 bg-card hide-scrollbar">
        
        <!-- STEP 1: Choose Report -->
        <div v-if="currentStep === 1" class="space-y-8 animate-in slide-in-from-right-4 duration-300">
          
          <div class="space-y-4">
            <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Report Type</h3>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
              <div 
                v-for="type in reportTypes" 
                :key="type.name"
                class="relative border rounded-xl p-4 cursor-pointer transition-all flex flex-col gap-3"
                :class="form.reportType === type.name ? 'border-primary bg-primary/5 shadow-sm' : 'border-border hover:border-primary/50 hover:bg-muted/30'"
                @click="form.reportType = type.name"
              >
                <div class="flex items-center justify-between">
                  <div class="p-2 rounded-lg" :class="form.reportType === type.name ? 'bg-primary/10 text-primary' : 'bg-muted text-muted-foreground'">
                    <component :is="type.icon" class="size-5" />
                  </div>
                  <Badge v-if="type.recommended" variant="secondary" class="bg-amber-100 text-amber-700 dark:bg-amber-500/20 dark:text-amber-400 border-0 flex gap-1 items-center">
                    <Star class="size-3 fill-amber-500" /> Recommended
                  </Badge>
                </div>
                <span class="font-medium text-foreground text-sm">{{ type.name }}</span>
              </div>
            </div>
          </div>
          
          <div class="space-y-4">
            <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Date Range</h3>
            <div class="flex flex-wrap gap-2">
              <button 
                v-for="range in dateRanges" 
                :key="range"
                class="px-4 py-2 rounded-full text-sm font-medium transition-colors border"
                :class="form.dateRange === range ? 'bg-primary text-primary-foreground border-primary shadow-sm' : 'bg-background border-border text-muted-foreground hover:bg-muted'"
                @click="form.dateRange = range"
              >
                {{ range }}
              </button>
            </div>
          </div>
          
          <div class="space-y-4">
            <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Recipients</h3>
            <div class="flex flex-wrap gap-2 mb-3">
              <button 
                v-for="recipient in recipientOptions" 
                :key="recipient"
                class="px-4 py-2 rounded-full text-sm font-medium transition-colors border"
                :class="form.recipients.includes(recipient) ? 'bg-primary text-primary-foreground border-primary shadow-sm' : 'bg-background border-border text-muted-foreground hover:bg-muted'"
                @click="toggleSelection(form.recipients, recipient)"
              >
                {{ recipient }}
              </button>
            </div>
            <Input v-model="form.emails" placeholder="Enter Email(s) separated by commas" class="max-w-md h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30" />
          </div>
          
        </div>

        <!-- STEP 2: Customize -->
        <div v-if="currentStep === 2" class="space-y-8 animate-in slide-in-from-right-4 duration-300">
          <div class="space-y-4">
            <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Include Sections</h3>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              <div 
                v-for="section in sectionOptions" 
                :key="section"
                class="flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors"
                :class="form.sections.includes(section) ? 'border-primary bg-primary/5' : 'border-border bg-card hover:border-primary/50'"
                @click="toggleSelection(form.sections, section)"
              >
                <div class="size-4 rounded-full border-2 flex items-center justify-center transition-colors shrink-0" :class="form.sections.includes(section) ? 'border-primary bg-transparent' : 'border-muted-foreground/30 bg-transparent'">
                  <div v-if="form.sections.includes(section)" class="size-2 rounded-full bg-primary"></div>
                </div>
                <span class="text-sm font-medium text-foreground">{{ section }}</span>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div class="space-y-4">
              <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Branding</h3>
              <div class="space-y-3">
                <input type="file" ref="fileInput" class="hidden" accept="image/*" @change="handleFileUpload" />
                <Button 
                  variant="outline" 
                  class="w-full h-10 px-4 text-[14px] justify-start shadow-sm rounded-md focus-visible:ring-1 focus-visible:ring-primary/30"
                  :class="form.logoName ? 'text-foreground border-primary bg-primary/5' : 'text-muted-foreground'" 
                  @click="triggerFileInput"
                >
                  <ImageIcon class="size-4 mr-2" v-if="!form.logoName" />
                  <Check class="size-4 mr-2 text-primary" v-else />
                  {{ form.logoName || 'Upload Company Logo' }}
                </Button>
                <Input placeholder="Brand Color (HEX)" class="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30" />
                <Input placeholder="Custom Title (Optional)" class="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30" />
                <Input placeholder="Footer Message (Optional)" class="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30" />
              </div>
            </div>
            <div class="space-y-4">
              <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Layout</h3>
              <div class="space-y-3">
                <div 
                  v-for="layout in layoutOptions" 
                  :key="layout"
                  class="flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors"
                  :class="form.layout === layout ? 'border-primary bg-primary/5' : 'border-border hover:border-primary/50 bg-card'"
                  @click="form.layout = layout"
                >
                  <div class="size-4 rounded-full border-2 flex items-center justify-center" :class="form.layout === layout ? 'border-primary' : 'border-muted-foreground/30'">
                    <div v-if="form.layout === layout" class="size-2 rounded-full bg-primary"></div>
                  </div>
                  <span class="text-sm font-medium text-foreground">{{ layout }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- STEP 3: Preview -->
        <div v-if="currentStep === 3" class="animate-in slide-in-from-right-4 duration-300">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Preview Report</h3>
            <div class="flex gap-2">
              <Button variant="outline" size="sm" class="h-8 text-xs gap-1.5"><Search class="size-3" /> Zoom</Button>
              <Button variant="outline" size="sm" class="h-8 text-xs gap-1.5"><PenTool class="size-3" /> Edit</Button>
              <Button variant="outline" size="sm" class="h-8 text-xs gap-1.5"><Download class="size-3" /> Download</Button>
            </div>
          </div>
          
          <!-- Mock Report Preview UI -->
          <div class="w-full aspect-[1/1.2] max-h-[500px] overflow-y-auto bg-white dark:bg-[#1A1A1A] rounded-xl border border-border shadow-inner p-8">
            <div class="max-w-2xl mx-auto space-y-8">
              <!-- Report Header -->
              <div class="border-b pb-6">
                <div class="flex items-center justify-between mb-6">
                  <div class="text-xl font-bold tracking-tight text-slate-900 dark:text-white">NewRelay</div>
                  <div class="text-sm font-medium text-slate-500">July 2026</div>
                </div>
                <h1 class="text-3xl font-bold text-slate-900 dark:text-white">Reputation Report</h1>
                <p class="text-slate-500 mt-2">Executive Summary</p>
              </div>
              
              <!-- Report KPI Cards -->
              <div class="grid grid-cols-2 gap-4">
                <div class="p-4 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900/50">
                  <div class="text-sm text-slate-500 mb-2">Average Rating</div>
                  <div class="flex items-center gap-3">
                    <span class="text-3xl font-bold text-slate-900 dark:text-white">4.7</span>
                    <div class="flex text-amber-400">
                      <Star class="size-4 fill-amber-400" /><Star class="size-4 fill-amber-400" /><Star class="size-4 fill-amber-400" /><Star class="size-4 fill-amber-400" /><StarHalf class="size-4 fill-amber-400" />
                    </div>
                  </div>
                </div>
                <div class="p-4 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900/50">
                  <div class="text-sm text-slate-500 mb-2">Total Reviews</div>
                  <div class="text-3xl font-bold text-slate-900 dark:text-white">1,096</div>
                </div>
              </div>
              
              <div class="p-4 rounded-xl bg-primary/10 border border-primary/20 text-primary">
                <div class="text-sm font-medium mb-1">AI Sentiment</div>
                <div class="text-2xl font-bold">92% Positive</div>
              </div>
              
              <!-- Report Mock Sections -->
              <div class="space-y-6">
                <div class="rounded-xl border border-border bg-card p-4">
                  <div class="text-xs font-semibold text-foreground mb-3">Review Trend</div>
                  <BarChart :labels="previewChartLabels" :series="previewChartSeries" :height="130" :show-y-ticks="false" />
                </div>
                <div class="h-32 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 flex items-center justify-center text-slate-400 text-sm">Platform Ratings</div>
                <div class="h-48 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 flex items-center justify-center text-slate-400 text-sm">Recent Reviews</div>
                <div class="h-40 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 flex items-center justify-center text-slate-400 text-sm">AI Insights</div>
              </div>
            </div>
          </div>
        </div>

        <!-- STEP 4: Share / Export -->
        <div v-if="currentStep === 4" class="space-y-8 animate-in slide-in-from-right-4 duration-300">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div class="space-y-6">
              <div class="space-y-4">
                <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Export Format</h3>
                <div class="grid grid-cols-2 gap-3">
                  <div 
                    v-for="format in ['PDF', 'PNG', 'CSV', 'Excel']" 
                    :key="format"
                    class="flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors"
                    :class="form.exportFormat === format ? 'border-primary bg-primary/5' : 'border-border hover:border-primary/50 bg-card'"
                    @click="form.exportFormat = format"
                  >
                    <div class="size-4 rounded-full border-2 flex items-center justify-center" :class="form.exportFormat === format ? 'border-primary' : 'border-muted-foreground/30'">
                      <div v-if="form.exportFormat === format" class="size-2 rounded-full bg-primary"></div>
                    </div>
                    <span class="text-sm font-medium text-foreground">{{ format }}</span>
                  </div>
                </div>
              </div>
              
              <div class="space-y-4">
                <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Share Via</h3>
                <div class="grid grid-cols-2 gap-3">
                  <div 
                    v-for="method in ['Email', 'Copy Link', 'Slack', 'Microsoft Teams']" 
                    :key="method"
                    class="flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors"
                    :class="form.shareMethod === method ? 'border-primary bg-primary/5' : 'border-border hover:border-primary/50 bg-card'"
                    @click="form.shareMethod = method"
                  >
                    <div class="size-4 rounded-full border-2 flex items-center justify-center" :class="form.shareMethod === method ? 'border-primary' : 'border-muted-foreground/30'">
                      <div v-if="form.shareMethod === method" class="size-2 rounded-full bg-primary"></div>
                    </div>
                    <span class="text-sm font-medium text-foreground">{{ method }}</span>
                  </div>
                </div>
              </div>
            </div>
            
            <div class="space-y-6">
              <div class="space-y-4">
                <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Delivery</h3>
                <div class="flex items-center gap-4">
                  <div class="flex items-center gap-2 cursor-pointer" @click="form.delivery = 'Send immediately'">
                    <div class="size-4 rounded-full border-2 flex items-center justify-center transition-colors shrink-0" :class="form.delivery === 'Send immediately' ? 'border-primary' : 'border-muted-foreground/30'">
                      <div v-if="form.delivery === 'Send immediately'" class="size-2 rounded-full bg-primary"></div>
                    </div>
                    <span class="text-sm font-medium text-foreground">Send immediately</span>
                  </div>
                  <div class="flex items-center gap-2 cursor-pointer" @click="form.delivery = 'Schedule'">
                    <div class="size-4 rounded-full border-2 flex items-center justify-center transition-colors shrink-0" :class="form.delivery === 'Schedule' ? 'border-primary' : 'border-muted-foreground/30'">
                      <div v-if="form.delivery === 'Schedule'" class="size-2 rounded-full bg-primary"></div>
                    </div>
                    <span class="text-sm font-medium text-foreground">Schedule</span>
                  </div>
                </div>
                
                <div v-if="form.delivery === 'Schedule'" class="grid grid-cols-2 gap-3 p-4 bg-muted/30 rounded-xl border border-border animate-in fade-in slide-in-from-top-2">
                  <Input type="date" class="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30" />
                  <Input type="time" class="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30" />
                  <Input placeholder="Timezone" class="col-span-2 h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30" />
                </div>
              </div>
              
              <div class="space-y-4">
                <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Permissions</h3>
                <div class="space-y-3">
                  <div 
                    v-for="perm in ['Anyone with link', 'Password Protected', 'Internal Only']" 
                    :key="perm"
                    class="flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors"
                    :class="form.permissions === perm ? 'border-primary bg-primary/5' : 'border-border hover:border-primary/50 bg-card'"
                    @click="form.permissions = perm"
                  >
                    <div class="size-4 rounded-full border-2 flex items-center justify-center" :class="form.permissions === perm ? 'border-primary' : 'border-muted-foreground/30'">
                      <div v-if="form.permissions === perm" class="size-2 rounded-full bg-primary"></div>
                    </div>
                    <span class="text-sm font-medium text-foreground">{{ perm }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <!-- STEP 5: Success Screen -->
        <div v-if="currentStep === 5" class="py-12 flex flex-col items-center text-center animate-in zoom-in-95 duration-500">
          <div class="size-20 bg-emerald-100 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 rounded-full flex items-center justify-center mb-6">
            <CheckCircle2 class="size-10" />
          </div>
          <h2 class="text-base font-medium text-foreground mb-2">Report Generated Successfully</h2>
          <p class="text-muted-foreground mb-8 text-lg">{{ form.reportType }}</p>
          
          <div class="bg-muted/30 border border-border rounded-xl p-6 text-sm text-left grid grid-cols-3 gap-6 w-full max-w-md mb-8">
            <div>
              <p class="text-muted-foreground mb-1">Shared with</p>
              <p class="font-medium text-foreground truncate">john@company.com</p>
            </div>
            <div>
              <p class="text-muted-foreground mb-1">Downloaded</p>
              <p class="font-medium text-foreground">2 times</p>
            </div>
            <div>
              <p class="text-muted-foreground mb-1">Expires</p>
              <p class="font-medium text-foreground">30 days</p>
            </div>
          </div>
          
          <div class="flex flex-wrap justify-center gap-3">
            <Button class="gap-2 px-6 h-11"><FileText class="size-4" /> Open Report</Button>
            <Button variant="outline" class="gap-2 px-6 h-11"><Copy class="size-4" /> Copy Link</Button>
            <Button variant="outline" class="gap-2 px-6 h-11"><Download class="size-4" /> Download PDF</Button>
            <Button variant="ghost" class="gap-2 px-6 h-11 text-muted-foreground" @click="currentStep = 1"><FilePlus2 class="size-4" /> Send Another</Button>
          </div>

          <div class="mt-8 max-w-md w-full bg-primary/5 border border-primary/20 rounded-xl p-5 text-left animate-in fade-in slide-in-from-bottom-4 duration-500 delay-300 fill-mode-both">
            <div class="flex items-center gap-2 mb-2 text-primary font-semibold text-sm">
              <span class="text-base">🤖</span> AI Recommendation
            </div>
            <p class="text-sm text-primary/80 mb-4 leading-relaxed">
              Your client receives this report every month. Would you like to automate this report?
            </p>
            <Button class="w-full bg-primary hover:bg-primary/90 text-primary-foreground shadow-sm h-10">
              Create Monthly Report Automation
            </Button>
          </div>

        </div>

      </div>
      
      <!-- Footer Actions -->
      <div v-if="currentStep < 5" class="px-6 py-4 border-t border-border bg-muted/10 flex items-center justify-between shrink-0">
        <Button variant="ghost" class="text-muted-foreground" @click="prevStep" :disabled="currentStep === 1">
          <ArrowLeft class="size-4 mr-2" v-if="currentStep > 1" />
          Back
        </Button>
        <Button v-if="currentStep < 4" class="gap-2 px-6" @click="nextStep">
          {{ currentStep === 1 ? 'Customize' : currentStep === 2 ? 'Preview' : 'Share / Export' }}
          <ChevronRight class="size-4" />
        </Button>
        <Button v-else-if="currentStep === 4" class="gap-2 px-8 bg-primary hover:bg-primary/90 text-primary-foreground" @click="generateReport">
          Generate Report
        </Button>
      </div>

    </div>
  </div>
</template>
