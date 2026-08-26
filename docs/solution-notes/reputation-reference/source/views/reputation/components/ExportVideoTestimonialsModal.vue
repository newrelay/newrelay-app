<script setup lang="ts">
import { ref } from 'vue'
import { 
  X, Download, Link as LinkIcon, CheckCircle2, ChevronDown, 
  Settings2, FileText, Check, LayoutTemplate, Copy
} from 'lucide-vue-next'
import { 
  Button, Input, Checkbox,
  DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem
} from '@/components/ui'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  (e: 'update:open', value: boolean): void
}>()

// Component State: 'config' | 'progress' | 'success'
const currentState = ref<'config' | 'progress' | 'success'>('config')

// Form State
const exportScope = ref('Selected Videos')
const resolution = ref('1080p')
const includeOptions = ref({
  originalVideo: true,
  transcript: true,
  aiSummary: false,
  reviewerName: true,
  rating: true,
  platform: false,
  date: true,
  tags: false,
  thumbnail: true
})
const brandingOptions = ref({
  watermark: false,
  companyLogo: true
})
const filename = ref('Video_Testimonials_July.zip')

const exportProgress = ref(0)
const copied = ref(false)

const startExport = () => {
  currentState.value = 'progress'
  exportProgress.value = 0
  
  const interval = setInterval(() => {
    exportProgress.value += Math.floor(Math.random() * 15) + 5
    if (exportProgress.value >= 100) {
      exportProgress.value = 100
      clearInterval(interval)
      setTimeout(() => {
        currentState.value = 'success'
      }, 500)
    }
  }, 400)
}

const resetAndClose = () => {
  emit('update:open', false)
  setTimeout(() => {
    currentState.value = 'config'
    exportProgress.value = 0
    copied.value = false
  }, 300)
}

const handleCopyLink = () => {
  copied.value = true
  setTimeout(() => {
    copied.value = false
  }, 2000)
}
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6">
    <!-- Backdrop -->
    <div 
      class="absolute inset-0 bg-background/80 backdrop-blur-sm transition-opacity duration-300"
      @click="currentState === 'progress' ? null : resetAndClose()"
    ></div>

    <!-- Modal Content -->
    <div 
      class="relative w-full max-w-2xl bg-card border border-border shadow-2xl rounded-2xl overflow-hidden flex flex-col max-h-full animate-in zoom-in-95 fade-in duration-200"
    >
      <!-- Header -->
      <div class="px-6 py-5 border-b border-border flex items-center justify-between bg-muted/30 shrink-0">
        <div class="flex items-center gap-3">
          <div class="size-10 rounded-xl bg-primary/10 flex items-center justify-center border border-primary/20 text-primary">
            <Download class="size-5" v-if="currentState === 'config'" />
            <Settings2 class="size-5" v-else-if="currentState === 'progress'" />
            <CheckCircle2 class="size-5" v-else />
          </div>
          <div>
            <h2 class="text-lg font-bold text-foreground">
              {{ currentState === 'config' ? 'Export Testimonials' : currentState === 'progress' ? 'Exporting...' : 'Export Complete' }}
            </h2>
            <p class="text-sm text-muted-foreground font-medium">
              {{ currentState === 'config' ? 'Download testimonials for marketing or reporting.' : currentState === 'progress' ? 'Please wait while we package your files.' : 'Your download is ready.' }}
            </p>
          </div>
        </div>
        <button 
          v-if="currentState !== 'progress'"
          @click="resetAndClose"
          class="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:bg-muted transition-colors"
        >
          <X class="size-5" />
        </button>
      </div>

      <!-- Body: Config State -->
      <div v-if="currentState === 'config'" class="p-6 overflow-y-auto flex flex-col gap-8 custom-scrollbar">
        
        <!-- Export Scope -->
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground">Export</label>
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <label 
              class="flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-all duration-200"
              :class="exportScope === 'Selected Videos' ? 'border-primary bg-primary/5 ring-1 ring-primary/20' : 'border-border bg-card hover:bg-muted/50'"
            >
              <div class="size-4 rounded-full border flex items-center justify-center shrink-0 transition-colors"
                   :class="exportScope === 'Selected Videos' ? 'border-primary border-[4px]' : 'border-input'"></div>
              <span class="text-[13px] font-bold text-foreground">Selected Videos</span>
              <input type="radio" value="Selected Videos" v-model="exportScope" class="hidden" />
            </label>
            <label 
              class="flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-all duration-200"
              :class="exportScope === 'Filtered Results' ? 'border-primary bg-primary/5 ring-1 ring-primary/20' : 'border-border bg-card hover:bg-muted/50'"
            >
              <div class="size-4 rounded-full border flex items-center justify-center shrink-0 transition-colors"
                   :class="exportScope === 'Filtered Results' ? 'border-primary border-[4px]' : 'border-input'"></div>
              <span class="text-[13px] font-bold text-foreground">Filtered Results</span>
              <input type="radio" value="Filtered Results" v-model="exportScope" class="hidden" />
            </label>
            <label 
              class="flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-all duration-200"
              :class="exportScope === 'Entire Library' ? 'border-primary bg-primary/5 ring-1 ring-primary/20' : 'border-border bg-card hover:bg-muted/50'"
            >
              <div class="size-4 rounded-full border flex items-center justify-center shrink-0 transition-colors"
                   :class="exportScope === 'Entire Library' ? 'border-primary border-[4px]' : 'border-input'"></div>
              <span class="text-[13px] font-bold text-foreground">Entire Library</span>
              <input type="radio" value="Entire Library" v-model="exportScope" class="hidden" />
            </label>
          </div>
        </div>

        <!-- Include Metadata -->
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground flex items-center justify-between">
            Include
            <span class="text-xs text-muted-foreground font-medium">Select multiple</span>
          </label>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
            <label v-for="(value, key) in includeOptions" :key="key" class="flex items-center gap-3 p-3 border border-border rounded-xl bg-card cursor-pointer hover:bg-muted/50 transition-colors">
              <Checkbox :checked="value" @update:checked="includeOptions[key as keyof typeof includeOptions] = $event as boolean" class="shadow-none rounded-[4px]" />
              <div class="flex flex-col">
                <span class="text-[13px] font-bold text-foreground capitalize">{{ key.replace(/([A-Z])/g, ' $1').trim() }}</span>
              </div>
            </label>
          </div>
        </div>

        <!-- Settings Row: Resolution & Branding -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">Resolution</label>
            <DropdownMenu>
              <DropdownMenuTrigger as-child>
                <Button variant="outline" class="w-full h-10 px-4 justify-between text-[14px] font-normal shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30">
                  {{ resolution }}
                  <ChevronDown class="size-4 opacity-50" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent class="w-[280px]">
                <DropdownMenuItem @click="resolution = 'Original'">Original</DropdownMenuItem>
                <DropdownMenuItem @click="resolution = '1080p'">1080p</DropdownMenuItem>
                <DropdownMenuItem @click="resolution = '720p'">720p</DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] font-medium text-foreground">Branding</label>
            <div class="flex items-center gap-4 h-10">
              <label class="flex items-center gap-2 cursor-pointer">
                <Checkbox :checked="brandingOptions.watermark" @update:checked="brandingOptions.watermark = $event as boolean" />
                <span class="text-[13px] font-bold text-foreground">Watermark</span>
              </label>
              <label class="flex items-center gap-2 cursor-pointer">
                <Checkbox :checked="brandingOptions.companyLogo" @update:checked="brandingOptions.companyLogo = $event as boolean" />
                <span class="text-[13px] font-bold text-foreground">Company Logo</span>
              </label>
            </div>
          </div>
        </div>

        <!-- Filename -->
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground">Filename</label>
          <div class="relative">
            <FileText class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
            <Input 
              v-model="filename" 
              class="pl-9 h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
        </div>

      </div>

      <!-- Body: Progress State -->
      <div v-else-if="currentState === 'progress'" class="p-12 flex flex-col items-center justify-center gap-6 min-h-[300px]">
        <div class="flex flex-col items-center text-center gap-2">
          <div class="text-xl font-bold text-foreground">Preparing export...</div>
          <div class="text-sm font-medium text-muted-foreground">Gathering your selected videos and metadata.</div>
        </div>
        
        <div class="w-full max-w-md flex flex-col gap-2">
          <div class="flex justify-between text-[13px] font-bold">
            <span class="text-foreground">Progress</span>
            <span class="text-primary">{{ exportProgress }}%</span>
          </div>
          <div class="h-3 w-full bg-muted rounded-full overflow-hidden">
            <div 
              class="h-full bg-primary transition-all duration-300 ease-out"
              :style="{ width: `${exportProgress}%` }"
            ></div>
          </div>
        </div>
      </div>

      <!-- Body: Success State -->
      <div v-else class="p-12 flex flex-col items-center justify-center gap-6 min-h-[300px]">
        <div class="size-20 rounded-full bg-emerald-50 text-emerald-500 flex items-center justify-center border-4 border-emerald-100">
          <CheckCircle2 class="size-10" />
        </div>
        
        <div class="flex flex-col items-center text-center gap-2">
          <div class="text-xl font-bold text-foreground">Download Ready</div>
          <div class="text-sm font-medium text-muted-foreground">Your file <span class="font-bold text-foreground">{{ filename }}</span> is ready to download.</div>
        </div>
        
        <div class="flex flex-col w-full max-w-xs gap-3 mt-4">
          <Button class="font-semibold bg-primary hover:bg-primary/90 text-primary-foreground h-11 gap-2 shadow-sm">
            <Download class="size-4" /> Download ZIP
          </Button>
          <Button @click="handleCopyLink" variant="outline" class="font-semibold bg-white dark:bg-card h-11 gap-2 shadow-sm border-border">
            <Check v-if="copied" class="size-4 text-emerald-500" />
            <Copy v-else class="size-4" />
            {{ copied ? 'Copied!' : 'Copy Link' }}
          </Button>
        </div>
      </div>

      <!-- Footer (Only for Config State) -->
      <div v-if="currentState === 'config'" class="px-6 py-4 border-t border-border bg-muted/20 flex items-center justify-between shrink-0">
        <Button variant="ghost" class="font-semibold text-muted-foreground hover:text-foreground h-10 px-4" @click="resetAndClose">
          Cancel
        </Button>
        <Button class="font-semibold bg-primary hover:bg-primary/90 text-primary-foreground h-10 px-6 shadow-sm gap-2" @click="startExport">
          <Download class="size-4" /> Export
        </Button>
      </div>
    </div>
  </div>
</template>
