<script setup>
/* eslint-disable */
import { ref } from 'vue';
import { 
  X, ChevronRight, FileText, BarChart2, MessageSquare, Monitor, Sparkles,
  PenTool, Calendar, Link as LinkIcon, Download, Mail, CheckCircle2, 
  Copy, ArrowLeft, Image as ImageIcon, FileSpreadsheet, Send, File as FileIcon, Star, StarHalf, Users, Check,
  Search, FilePlus2
} from 'lucide-vue-next';
import { 
  RelayButton as Button, RelayInput as Input, RelayBadge as Badge
} from 'dashboard/components-next/relay';

const props = defineProps({
  open: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['update:open']);

const currentStep = ref(1);

// Form State matching reference
const defaultFormState = {
  reportType: 'Executive Summary',
  dateRange: 'Last 30 Days',
  recipients: ['Myself'],
  emails: '',
  logoName: '',
  sections: ['Reputation Score', 'Average Rating', 'Review Trend', 'Platform Breakdown', 'AI Insights'],
  layout: 'Executive',
  exportFormat: 'PDF',
  shareMethod: 'Email',
  delivery: 'Send immediately',
  permissions: 'Anyone with link'
};

const form = ref({ ...defaultFormState });

const reportTypes = [
  { name: 'Executive Summary', icon: FileText, recommended: true },
  { name: 'Reputation Overview', icon: BarChart2 },
  { name: 'Reviews Report', icon: MessageSquare },
  { name: 'Listings Report', icon: Monitor },
  { name: 'AI Insights Report', icon: Sparkles },
  { name: 'Custom Report', icon: PenTool },
];

const dateRanges = ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'Custom'];
const recipientOptions = ['Myself', 'Team Members', 'Client'];
const sectionOptions = ['Reputation Score', 'Average Rating', 'Review Trend', 'Platform Breakdown', 'AI Insights', 'Recent Reviews', 'Unanswered Reviews', 'Listings Health', 'Team Performance'];
const layoutOptions = ['Executive', 'Detailed', 'Landscape', 'Portrait'];

const fileInput = ref(null);
const copied = ref(false);
const generating = ref(false);
const shareUrl = ref('');

const axios = window.axios;
const accountId =
  window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];

function triggerFileInput() {
  fileInput.value?.click();
}

function handleFileUpload(event) {
  const target = event.target;
  if (target.files && target.files.length > 0) {
    form.value.logoName = target.files[0].name;
  }
}

function toggleSelection(array, item) {
  const index = array.indexOf(item);
  if (index === -1) array.push(item);
  else array.splice(index, 1);
}

function nextStep() {
  if (currentStep.value < 5) currentStep.value++;
}

function prevStep() {
  if (currentStep.value > 1) currentStep.value--;
}

async function generateReport() {
  generating.value = true;
  try {
    const { data } = await axios.post(
      `/api/v1/accounts/${accountId}/reputation/reports`,
      {
        report_type: form.value.reportType,
        date_range: form.value.dateRange,
        layout: form.value.layout,
        sections: form.value.sections,
      }
    );
    shareUrl.value = data.share_url;
  } catch (err) {
    console.error('Failed to generate report', err);
  } finally {
    generating.value = false;
    currentStep.value = 5;
  }
}

function openReport() {
  if (shareUrl.value) window.open(shareUrl.value, '_blank', 'noopener');
}

function copyShareLink() {
  if (!shareUrl.value) return;
  navigator.clipboard?.writeText(shareUrl.value);
  copied.value = true;
  setTimeout(() => {
    copied.value = false;
  }, 2000);
}

function close() {
  emit('update:open', false);
  setTimeout(() => {
    currentStep.value = 1;
    form.value = { ...defaultFormState };
    shareUrl.value = '';
  }, 300);
}
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6">
    <!-- Backdrop -->
    <div class="absolute inset-0 bg-background/80 backdrop-blur-xs" @click="close"></div>
    
    <!-- Modal -->
    <div class="relative w-full max-w-4xl max-h-[90vh] bg-card rounded-2xl shadow-2xl border border-border flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200">
      
      <!-- Header -->
      <div v-if="currentStep < 5" class="px-6 py-4 border-b border-border flex items-center justify-between bg-muted/30 shrink-0">
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
        <button class="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:bg-muted cursor-pointer transition-colors" @click="close">
          <X class="size-5" />
        </button>
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
                :class="form.reportType === type.name ? 'border-primary bg-primary/5 shadow-xs' : 'border-border hover:border-primary/50 hover:bg-muted/30'"
                @click="form.reportType = type.name"
              >
                <div class="flex items-center justify-between">
                  <div class="p-2 rounded-lg" :class="form.reportType === type.name ? 'bg-primary/10 text-primary' : 'bg-muted text-muted-foreground'">
                    <component :is="type.icon" class="size-5" />
                  </div>
                  <Badge v-if="type.recommended" class="bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 border-0 flex gap-1 items-center font-semibold text-[10px]">
                    <Star class="size-3 fill-amber-500 text-amber-500" /> Recommended
                  </Badge>
                </div>
                <span class="font-semibold text-foreground text-sm">{{ type.name }}</span>
              </div>
            </div>
          </div>
          
          <div class="space-y-4">
            <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Date Range</h3>
            <div class="flex flex-wrap gap-2">
              <button 
                v-for="range in dateRanges" 
                :key="range"
                class="px-4 py-2 rounded-full text-xs font-semibold transition-colors border cursor-pointer"
                :class="form.dateRange === range ? 'bg-primary text-primary-foreground border-primary shadow-xs' : 'bg-background border-border text-muted-foreground hover:bg-muted'"
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
                class="px-4 py-2 rounded-full text-xs font-semibold transition-colors border cursor-pointer"
                :class="form.recipients.includes(recipient) ? 'bg-primary text-primary-foreground border-primary shadow-xs' : 'bg-background border-border text-muted-foreground hover:bg-muted'"
                @click="toggleSelection(form.recipients, recipient)"
              >
                {{ recipient }}
              </button>
            </div>
            <Input v-model="form.emails" placeholder="Enter Email(s) separated by commas" class="max-w-md h-10 px-4 text-[14px] shadow-xs rounded-md border-border/80 bg-background" />
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
                <button 
                  class="w-full h-10 px-4 text-xs font-semibold justify-start shadow-xs rounded-md border inline-flex items-center cursor-pointer transition-colors"
                  :class="form.logoName ? 'text-foreground border-primary bg-primary/5' : 'text-muted-foreground border-border bg-card hover:bg-muted'" 
                  @click="triggerFileInput"
                >
                  <ImageIcon class="size-4 mr-2" v-if="!form.logoName" />
                  <Check class="size-4 mr-2 text-primary" v-else />
                  {{ form.logoName || 'Upload Company Logo' }}
                </button>
                <Input placeholder="Brand Color (HEX)" class="h-10 px-4 text-[14px] shadow-xs rounded-md border-border/80 bg-background" />
                <Input placeholder="Custom Title (Optional)" class="h-10 px-4 text-[14px] shadow-xs rounded-md border-border/80 bg-background" />
                <Input placeholder="Footer Message (Optional)" class="h-10 px-4 text-[14px] shadow-xs rounded-md border-border/80 bg-background" />
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
              <button class="h-8 text-xs font-semibold px-3 border border-border bg-card hover:bg-muted text-foreground rounded-lg inline-flex items-center gap-1.5 cursor-pointer"><Search class="size-3" /> Zoom</button>
              <button class="h-8 text-xs font-semibold px-3 border border-border bg-card hover:bg-muted text-foreground rounded-lg inline-flex items-center gap-1.5 cursor-pointer"><PenTool class="size-3" /> Edit</button>
              <button class="h-8 text-xs font-semibold px-3 border border-border bg-card hover:bg-muted text-foreground rounded-lg inline-flex items-center gap-1.5 cursor-pointer"><Download class="size-3" /> Download</button>
            </div>
          </div>
          
          <!-- Mock Report Preview UI -->
          <div class="w-full aspect-[1/1.2] max-h-[480px] overflow-y-auto bg-white dark:bg-card rounded-xl border border-border p-8 hide-scrollbar">
            <div class="max-w-2xl mx-auto space-y-8">
              <!-- Report Header -->
              <div class="border-b border-border pb-6">
                <div class="flex items-center justify-between mb-6">
                  <div class="text-xl font-bold tracking-tight text-foreground">New Relay</div>
                  <div class="text-sm font-medium text-muted-foreground">July 2026</div>
                </div>
                <h1 class="text-3xl font-bold text-foreground">Reputation Report</h1>
                <p class="text-muted-foreground mt-2">Executive Summary</p>
              </div>
              
              <!-- Report KPI Cards -->
              <div class="grid grid-cols-2 gap-4">
                <div class="p-4 rounded-xl border border-border bg-muted/20">
                  <div class="text-sm text-muted-foreground mb-2">Average Rating</div>
                  <div class="flex items-center gap-3">
                    <span class="text-3xl font-bold text-foreground">4.7</span>
                    <div class="flex text-amber-400">
                      <Star class="size-4 fill-amber-400 text-amber-400" /><Star class="size-4 fill-amber-400 text-amber-400" /><Star class="size-4 fill-amber-400 text-amber-400" /><Star class="size-4 fill-amber-400 text-amber-400" /><StarHalf class="size-4 fill-amber-400 text-amber-400" />
                    </div>
                  </div>
                </div>
                <div class="p-4 rounded-xl border border-border bg-muted/20">
                  <div class="text-sm text-muted-foreground mb-2">Total Reviews</div>
                  <div class="text-3xl font-bold text-foreground">1,096</div>
                </div>
              </div>
              
              <div class="p-4 rounded-xl bg-primary/10 border border-primary/20 text-primary">
                <div class="text-sm font-medium mb-1">AI Sentiment</div>
                <div class="text-2xl font-bold">92% Positive</div>
              </div>
              
              <!-- Report Mock Sections -->
              <div class="space-y-6">
                <div class="h-32 rounded-lg bg-muted/30 border border-border flex items-center justify-center text-muted-foreground text-sm font-medium">Review Trend Chart</div>
                <div class="h-32 rounded-lg bg-muted/30 border border-border flex items-center justify-center text-muted-foreground text-sm font-medium">Platform Ratings</div>
                <div class="h-48 rounded-lg bg-muted/30 border border-border flex items-center justify-center text-muted-foreground text-sm font-medium">Recent Reviews</div>
                <div class="h-40 rounded-lg bg-muted/30 border border-border flex items-center justify-center text-muted-foreground text-sm font-medium">AI Insights</div>
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
          <div class="size-20 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 rounded-full flex items-center justify-center mb-6">
            <CheckCircle2 class="size-10" />
          </div>
          <h2 class="text-base font-semibold text-foreground mb-2">Report Generated Successfully</h2>
          <p class="text-muted-foreground mb-8 text-sm">{{ form.reportType }}</p>
          
          <div class="bg-muted/30 border border-border rounded-xl p-6 text-sm text-left grid grid-cols-3 gap-6 w-full max-w-md mb-8">
            <div>
              <p class="text-muted-foreground text-xs mb-1">Shared with</p>
              <p class="font-semibold text-foreground truncate">john@company.com</p>
            </div>
            <div>
              <p class="text-muted-foreground text-xs mb-1">Downloaded</p>
              <p class="font-semibold text-foreground">2 times</p>
            </div>
            <div>
              <p class="text-muted-foreground text-xs mb-1">Expires</p>
              <p class="font-semibold text-foreground">30 days</p>
            </div>
          </div>
          
          <div class="flex flex-wrap justify-center gap-3">
            <button :disabled="!shareUrl" class="h-11 px-6 text-sm font-semibold bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-xs cursor-pointer inline-flex items-center gap-2 disabled:opacity-50" @click="openReport">
              <FileText class="size-4" /> Open Report
            </button>
            <button @click="copyShareLink" class="h-11 px-6 text-sm font-semibold bg-card border border-border hover:bg-muted text-foreground rounded-lg shadow-xs cursor-pointer inline-flex items-center gap-2">
              <Check v-if="copied" class="size-4 text-emerald-600" />
              <Copy v-else class="size-4" />
              {{ copied ? 'Copied' : 'Copy Link' }}
            </button>
            <button class="h-11 px-6 text-sm font-semibold bg-card border border-border hover:bg-muted text-foreground rounded-lg shadow-xs cursor-pointer inline-flex items-center gap-2">
              <Download class="size-4" /> Download PDF
            </button>
          </div>

          <div class="mt-8 max-w-md w-full bg-primary/5 border border-primary/20 rounded-xl p-5 text-left animate-in fade-in slide-in-from-bottom-4 duration-500 delay-300 fill-mode-both">
            <div class="flex items-center gap-2 mb-2 text-primary font-semibold text-sm">
              <span class="text-base">🤖</span> Relay AI Recommendation
            </div>
            <p class="text-sm text-primary/80 mb-4 leading-relaxed">
              Your client receives this report every month. Would you like to automate this report?
            </p>
            <button class="w-full bg-primary hover:bg-primary/90 text-primary-foreground font-semibold text-xs shadow-xs h-10 rounded-lg cursor-pointer">
              Create Monthly Report Automation
            </button>
          </div>

        </div>

      </div>
      
      <!-- Footer Actions -->
      <div v-if="currentStep < 5" class="px-6 py-4 border-t border-border bg-muted/10 flex items-center justify-between shrink-0">
        <button class="h-9 px-4 text-xs font-semibold text-muted-foreground hover:text-foreground cursor-pointer disabled:opacity-40" @click="prevStep" :disabled="currentStep === 1">
          Back
        </button>
        <button v-if="currentStep < 4" class="h-9 px-6 text-xs font-semibold bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-xs cursor-pointer inline-flex items-center gap-2" @click="nextStep">
          {{ currentStep === 1 ? 'Customize' : currentStep === 2 ? 'Preview' : 'Share / Export' }}
          <ChevronRight class="size-4" />
        </button>
        <button v-else-if="currentStep === 4" class="h-9 px-8 text-xs font-semibold bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-xs cursor-pointer" @click="generateReport">
          Generate Report
        </button>
      </div>

    </div>
  </div>
</template>
