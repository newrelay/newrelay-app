<script setup>
/* eslint-disable */
import { ref, computed, watch } from 'vue';
import { RelayInput as Input, RelayCheckbox as Checkbox } from 'dashboard/components-next/relay';
import {
  X, Search, MessageSquare, Mail, Smartphone,
  Check, ChevronDown, MonitorPlay,
  Clock, Bell, Sparkles, LayoutTemplate, Link as LinkIcon
} from 'lucide-vue-next';

const props = defineProps({
  open: { type: Boolean, default: false }
});

const emit = defineEmits(['update:open', 'submit']);

const axios = window.axios;
const accountId = window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];

// State
const searchQuery = ref('');
const selectedCustomers = ref([]);
const selectedDelivery = ref(['Email']);
const selectedTemplate = ref('Customer Testimonial Request');
const selectedLandingPage = ref('Default Video Collection Page');
const selectedExpiration = ref('30 Days');
const selectedReminder = ref('1 Reminder');
const sending = ref(false);

const showTemplateDropdown = ref(false);
const showLandingPageDropdown = ref(false);
const showExpirationDropdown = ref(false);
const showReminderDropdown = ref(false);

// NOTE: template/landing/expiration/reminder/AI options are UI-only (no backend
// until Phase 3). Only the customer list + send path below are wired.
const aiOptions = ref({
  transcript: true,
  summarize: true,
  sentiment: false,
  reply: false
});

// Real Chatwoot contacts, loaded when the modal opens.
const allCustomers = ref([]);
const loadingContacts = ref(false);

function mapContact(c) {
  return {
    id: String(c.id),
    name: c.name || c.email || c.phone_number || 'Unknown',
    email: c.email || '',
    phone: c.phone_number || ''
  };
}

async function loadContacts() {
  if (!accountId) return;
  loadingContacts.value = true;
  try {
    const { data } = await axios.get(`/api/v1/accounts/${accountId}/contacts`, { params: { sort: '-last_activity_at' } });
    allCustomers.value = (data.payload || []).map(mapContact);
  } catch (err) {
    console.error('Failed to load contacts', err);
  } finally {
    loadingContacts.value = false;
  }
}

watch(() => props.open, isOpen => { if (isOpen) loadContacts(); }, { immediate: true });

const filteredCustomers = computed(() => {
  if (!searchQuery.value) return allCustomers.value;
  return allCustomers.value.filter(c => c.name.toLowerCase().includes(searchQuery.value.toLowerCase()));
});

const toggleCustomer = (id) => {
  if (selectedCustomers.value.includes(id)) {
    selectedCustomers.value = selectedCustomers.value.filter(c => c !== id);
  } else {
    selectedCustomers.value.push(id);
  }
};

const toggleDelivery = (method) => {
  if (selectedDelivery.value.includes(method)) {
    selectedDelivery.value = selectedDelivery.value.filter(m => m !== method);
  } else {
    selectedDelivery.value.push(method);
  }
};

// Fire one video-request email per selected contact (backend picks a video template).
// dispatch_request is email-only for now; SMS/WhatsApp toggles are Phase 3.
const handleSubmit = async () => {
  if (sending.value || selectedCustomers.value.length === 0) return;
  sending.value = true;
  const emails = selectedCustomers.value
    .map(id => allCustomers.value.find(c => c.id === id)?.email)
    .filter(Boolean);
  try {
    await Promise.all(emails.map(email =>
      axios.post(`/api/v1/accounts/${accountId}/reputation/video_testimonials/dispatch_request`, { email })
    ));
    emit('submit', { count: emails.length });
    emit('update:open', false);
    selectedCustomers.value = [];
    selectedDelivery.value = ['Email'];
    searchQuery.value = '';
  } catch (err) {
    console.error('Failed to send video request', err);
  } finally {
    sending.value = false;
  }
};
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6">
    <!-- Backdrop -->
    <div 
      class="absolute inset-0 bg-background/80 backdrop-blur-sm transition-opacity duration-300"
      @click="emit('update:open', false)"
    ></div>

    <!-- Modal Content -->
    <div 
      class="relative w-full max-w-2xl bg-card border border-border shadow-2xl rounded-2xl overflow-hidden flex flex-col max-h-full animate-in zoom-in-95 fade-in duration-200"
    >
      <!-- Header -->
      <div class="px-6 py-5 border-b border-border flex items-center justify-between bg-muted/30 shrink-0">
        <div class="flex items-center gap-3">
          <div class="size-10 rounded-xl bg-primary/10 flex items-center justify-center border border-primary/20 text-primary">
            <MonitorPlay class="size-5" />
          </div>
          <div>
            <h2 class="text-lg font-bold text-foreground">Request Video Testimonial</h2>
            <p class="text-sm text-muted-foreground font-medium">Send a request to a customer asking them to record a video.</p>
          </div>
        </div>
        <button 
          @click="emit('update:open', false)"
          class="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:bg-muted transition-colors cursor-pointer"
        >
          <X class="size-5" />
        </button>
      </div>

      <!-- Body -->
      <div class="p-6 overflow-y-auto flex flex-col gap-8 custom-scrollbar">
        
        <!-- 1. Customer Selection -->
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground flex items-center justify-between">
            Who do you want to request from?
            <button class="h-6 px-2 text-primary font-bold text-[12px] hover:bg-primary/10 rounded cursor-pointer">+ Add Customer</button>
          </label>
          <div class="relative">
            <Search class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
            <Input 
              v-model="searchQuery" 
              placeholder="Search Customer..." 
              class="pl-9 h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
            />
          </div>
          
          <div class="flex flex-col gap-2 mt-1 max-h-[140px] overflow-y-auto p-1 hide-scrollbar">
            <div v-if="loadingContacts" class="flex items-center justify-center py-6 text-sm text-muted-foreground">Loading contacts…</div>
            <div v-else-if="filteredCustomers.length === 0" class="flex items-center justify-center py-6 text-sm text-muted-foreground">No contacts found. Add contacts first.</div>
            <div
              v-for="customer in filteredCustomers" :key="customer.id"
              @click="toggleCustomer(customer.id)"
              class="flex items-center justify-between p-3 rounded-xl border cursor-pointer transition-all duration-200"
              :class="selectedCustomers.includes(customer.id) ? 'border-primary bg-primary/5 ring-1 ring-primary/20' : 'border-border bg-card hover:bg-muted/50'"
            >
              <div class="flex items-center gap-3">
                <div class="size-8 rounded-full bg-muted flex items-center justify-center text-xs font-bold text-muted-foreground">
                  {{ customer.name.split(' ').map(n => n[0]).join('') }}
                </div>
                <div class="flex flex-col">
                  <span class="text-[14px] font-bold text-foreground">{{ customer.name }}</span>
                </div>
              </div>
              <div class="size-5 rounded-full border flex items-center justify-center transition-colors"
                   :class="selectedCustomers.includes(customer.id) ? 'bg-primary border-primary text-primary-foreground' : 'border-input'">
                <Check class="size-3" v-if="selectedCustomers.includes(customer.id)" />
              </div>
            </div>
          </div>
        </div>

        <!-- 2. Delivery Method -->
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground flex items-center justify-between">
            Delivery Method
            <span class="text-xs text-muted-foreground font-medium">Select multiple</span>
          </label>
          <div class="grid grid-cols-3 gap-3">
            <div 
              @click="toggleDelivery('SMS')"
              class="flex flex-col items-center gap-2 p-3 rounded-xl border cursor-pointer transition-all duration-200 text-center relative"
              :class="selectedDelivery.includes('SMS') ? 'border-primary bg-primary/5 text-primary ring-1 ring-primary/20' : 'border-border bg-card hover:bg-muted/50 text-muted-foreground'"
            >
              <MessageSquare class="size-5 mb-1" />
              <span class="text-[13px] font-bold">SMS</span>
              <div class="absolute top-2 right-2">
                <div class="size-4 rounded-full border flex items-center justify-center bg-card"
                     :class="selectedDelivery.includes('SMS') ? 'border-primary text-primary' : 'border-input text-transparent'">
                  <Check class="size-2.5" />
                </div>
              </div>
            </div>
            
            <div 
              @click="toggleDelivery('Email')"
              class="flex flex-col items-center gap-2 p-3 rounded-xl border cursor-pointer transition-all duration-200 text-center relative"
              :class="selectedDelivery.includes('Email') ? 'border-primary bg-primary/5 text-primary ring-1 ring-primary/20' : 'border-border bg-card hover:bg-muted/50 text-muted-foreground'"
            >
              <Mail class="size-5 mb-1" />
              <span class="text-[13px] font-bold">Email</span>
              <div class="absolute top-2 right-2">
                <div class="size-4 rounded-full border flex items-center justify-center bg-card"
                     :class="selectedDelivery.includes('Email') ? 'border-primary text-primary' : 'border-input text-transparent'">
                  <Check class="size-2.5" />
                </div>
              </div>
            </div>

            <div 
              @click="toggleDelivery('WhatsApp')"
              class="flex flex-col items-center gap-2 p-3 rounded-xl border cursor-pointer transition-all duration-200 text-center relative"
              :class="selectedDelivery.includes('WhatsApp') ? 'border-primary bg-primary/5 text-primary ring-1 ring-primary/20' : 'border-border bg-card hover:bg-muted/50 text-muted-foreground'"
            >
              <Smartphone class="size-5 mb-1" />
              <span class="text-[13px] font-bold">WhatsApp</span>
              <div class="absolute top-2 right-2">
                <div class="size-4 rounded-full border flex items-center justify-center bg-card"
                     :class="selectedDelivery.includes('WhatsApp') ? 'border-primary text-primary' : 'border-input text-transparent'">
                  <Check class="size-2.5" />
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 3. Template & Landing Page -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
          <div class="flex flex-col gap-1.5 relative">
            <label class="text-[13.5px] font-medium text-foreground">Template</label>
            <button 
              @click="showTemplateDropdown = !showTemplateDropdown"
              class="w-full h-10 px-4 flex items-center justify-between text-[14px] font-normal shadow-sm rounded-md border border-border bg-background cursor-pointer"
            >
              <div class="flex items-center gap-2">
                <LayoutTemplate class="size-4 text-muted-foreground" />
                {{ selectedTemplate }}
              </div>
              <ChevronDown class="size-4 opacity-50" />
            </button>
            <div 
              v-if="showTemplateDropdown"
              class="absolute left-0 right-0 top-full mt-1 bg-card border border-border rounded-xl p-1 shadow-xl z-50 space-y-0.5"
            >
              <button 
                v-for="tmpl in ['Customer Testimonial Request', 'Post-Purchase Video', 'Service Follow-up']"
                :key="tmpl"
                @click="selectedTemplate = tmpl; showTemplateDropdown = false"
                class="w-full text-left px-3 py-2 text-xs rounded-md font-medium hover:bg-muted text-foreground cursor-pointer"
              >
                {{ tmpl }}
              </button>
            </div>

            <div class="mt-1 p-3 bg-muted/40 rounded-lg border border-border text-[12px] text-muted-foreground font-medium leading-relaxed">
              "Hi there! We'd love to hear about your experience. Could you take a minute to record a quick video testimonial for us?"
            </div>
          </div>

          <div class="flex flex-col gap-1.5 relative">
            <label class="text-[13.5px] font-medium text-foreground flex items-center justify-between">
              Landing Page
              <span class="text-[11px] font-bold text-primary cursor-pointer hover:underline">Create New</span>
            </label>
            <button 
              @click="showLandingPageDropdown = !showLandingPageDropdown"
              class="w-full h-10 px-4 flex items-center justify-between text-[14px] font-normal shadow-sm rounded-md border border-border bg-background cursor-pointer"
            >
              <div class="flex items-center gap-2 truncate">
                <LinkIcon class="size-4 text-muted-foreground shrink-0" />
                <span class="truncate">{{ selectedLandingPage }}</span>
              </div>
              <ChevronDown class="size-4 opacity-50 shrink-0" />
            </button>
            <div 
              v-if="showLandingPageDropdown"
              class="absolute left-0 right-0 top-16 bg-card border border-border rounded-xl p-1 shadow-xl z-50 space-y-0.5"
            >
              <button 
                v-for="lp in ['Default Video Collection Page', 'VIP Customer Page']"
                :key="lp"
                @click="selectedLandingPage = lp; showLandingPageDropdown = false"
                class="w-full text-left px-3 py-2 text-xs rounded-md font-medium hover:bg-muted text-foreground cursor-pointer"
              >
                {{ lp }}
              </button>
            </div>
          </div>
        </div>

        <!-- 4. Settings Row -->
        <div class="grid grid-cols-2 gap-6 p-4 rounded-xl border border-border bg-muted/20">
          <div class="flex flex-col gap-1.5 relative">
            <label class="text-[13.5px] font-medium text-foreground flex items-center gap-2">
              <Clock class="size-4 text-muted-foreground" /> Expiration
            </label>
            <button 
              @click="showExpirationDropdown = !showExpirationDropdown"
              class="w-full h-10 px-4 flex items-center justify-between text-[14px] font-normal shadow-sm rounded-md border border-border bg-background cursor-pointer"
            >
              {{ selectedExpiration }}
              <ChevronDown class="size-4 opacity-50" />
            </button>
            <div 
              v-if="showExpirationDropdown"
              class="absolute left-0 right-0 top-full mt-1 bg-card border border-border rounded-xl p-1 shadow-xl z-50 space-y-0.5"
            >
              <button 
                v-for="exp in ['No Expiration', '7 Days', '14 Days', '30 Days']"
                :key="exp"
                @click="selectedExpiration = exp; showExpirationDropdown = false"
                class="w-full text-left px-3 py-2 text-xs rounded-md font-medium hover:bg-muted text-foreground cursor-pointer"
              >
                {{ exp }}
              </button>
            </div>
          </div>

          <div class="flex flex-col gap-1.5 relative">
            <label class="text-[13.5px] font-medium text-foreground flex items-center gap-2">
              <Bell class="size-4 text-muted-foreground" /> Reminder
            </label>
            <button 
              @click="showReminderDropdown = !showReminderDropdown"
              class="w-full h-10 px-4 flex items-center justify-between text-[14px] font-normal shadow-sm rounded-md border border-border bg-background cursor-pointer"
            >
              {{ selectedReminder }}
              <ChevronDown class="size-4 opacity-50" />
            </button>
            <div 
              v-if="showReminderDropdown"
              class="absolute left-0 right-0 top-full mt-1 bg-card border border-border rounded-xl p-1 shadow-xl z-50 space-y-0.5"
            >
              <button 
                v-for="rem in ['No Reminder', '1 Reminder', '2 Reminders']"
                :key="rem"
                @click="selectedReminder = rem; showReminderDropdown = false"
                class="w-full text-left px-3 py-2 text-xs rounded-md font-medium hover:bg-muted text-foreground cursor-pointer"
              >
                {{ rem }}
              </button>
            </div>
          </div>
        </div>

        <!-- 5. AI Options -->
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground flex items-center gap-2">
            <Sparkles class="size-4 text-primary" /> AI Processing Options
          </label>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <label class="flex items-center gap-3 p-3 border border-border rounded-lg bg-card cursor-pointer hover:bg-muted/50 transition-colors">
              <Checkbox :model-value="aiOptions.transcript" @update:model-value="aiOptions.transcript = $event" class="rounded-sm" />
              <div class="flex flex-col">
                <span class="text-[13px] font-bold text-foreground">Generate transcript</span>
                <span class="text-[11px] text-muted-foreground font-medium">Auto-caption the video</span>
              </div>
            </label>
            
            <label class="flex items-center gap-3 p-3 border border-border rounded-lg bg-card cursor-pointer hover:bg-muted/50 transition-colors">
              <Checkbox :model-value="aiOptions.summarize" @update:model-value="aiOptions.summarize = $event" class="rounded-sm" />
              <div class="flex flex-col">
                <span class="text-[13px] font-bold text-foreground">Auto summarize</span>
                <span class="text-[11px] text-muted-foreground font-medium">Extract key topics</span>
              </div>
            </label>

            <label class="flex items-center gap-3 p-3 border border-border rounded-lg bg-card cursor-pointer hover:bg-muted/50 transition-colors">
              <Checkbox :model-value="aiOptions.sentiment" @update:model-value="aiOptions.sentiment = $event" class="rounded-sm" />
              <div class="flex flex-col">
                <span class="text-[13px] font-bold text-foreground">Detect sentiment</span>
                <span class="text-[11px] text-muted-foreground font-medium">Analyze emotion in video</span>
              </div>
            </label>

            <label class="flex items-center gap-3 p-3 border border-border rounded-lg bg-card cursor-pointer hover:bg-muted/50 transition-colors">
              <Checkbox :model-value="aiOptions.reply" @update:model-value="aiOptions.reply = $event" class="rounded-sm" />
              <div class="flex flex-col">
                <span class="text-[13px] font-bold text-foreground">Auto suggest reply</span>
                <span class="text-[11px] text-muted-foreground font-medium">Draft a thank you message</span>
              </div>
            </label>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="px-6 py-4 border-t border-border bg-muted/20 flex items-center justify-between shrink-0">
        <button class="font-semibold text-muted-foreground hover:text-foreground h-10 px-4 cursor-pointer" @click="emit('update:open', false)">
          Cancel
        </button>
        <div class="flex items-center gap-3">
          <button class="font-semibold bg-card border border-border h-10 px-6 shadow-sm rounded-lg text-foreground hover:bg-muted cursor-pointer">
            Preview
          </button>
          <button class="font-semibold bg-primary hover:bg-primary/90 text-primary-foreground h-10 px-6 shadow-sm rounded-lg cursor-pointer disabled:opacity-50" @click="handleSubmit" :disabled="sending || selectedCustomers.length === 0 || selectedDelivery.length === 0">
            {{ sending ? 'Sending…' : 'Send Request' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
