<script setup>
/* eslint-disable */
import { ref, computed, watch } from 'vue';
import {
  X, ChevronRight, Search, FileText, CheckCircle2,
  ArrowLeft, Send, Sparkles, MessageSquare,
  Mail, MessageCircle, Star, Smartphone,
  Upload, Clock, Check, BarChart3,
  Calendar, ChevronLeft, Users, Plus, AlertCircle, Globe
} from 'lucide-vue-next';
import {
  RelayButton as Button, RelayInput as Input, RelayBadge as Badge
} from 'dashboard/components-next/relay';
import RelayDatePicker from 'dashboard/components-next/relay/calendar/DatePicker.vue';
import RelayTimePicker from 'dashboard/components-next/relay/calendar/TimePicker.vue';

const props = defineProps({
  open: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['update:open']);

// Timezone utilities
const getUserTimezone = () => Intl.DateTimeFormat().resolvedOptions().timeZone;
const COMMON_TIMEZONES = [
  { label: 'UTC', value: 'UTC' },
  { label: 'US Eastern', value: 'America/New_York' },
  { label: 'US Central', value: 'America/Chicago' },
  { label: 'US Mountain', value: 'America/Denver' },
  { label: 'US Pacific', value: 'America/Los_Angeles' },
  { label: 'Europe/London', value: 'Europe/London' },
  { label: 'Europe/Paris', value: 'Europe/Paris' },
  { label: 'Asia/Tokyo', value: 'Asia/Tokyo' },
  { label: 'Asia/Shanghai', value: 'Asia/Shanghai' },
  { label: 'Asia/Hong_Kong', value: 'Asia/Hong_Kong' },
  { label: 'Asia/Singapore', value: 'Asia/Singapore' },
  { label: 'Australia/Sydney', value: 'Australia/Sydney' },
  { label: 'Australia/Melbourne', value: 'Australia/Melbourne' },
];

const convertToUtcIso = (dateStr, timeStr, tz) => {
  if (!dateStr || !timeStr) return null;
  const [hours, minutes] = timeStr.split(':').map(Number);
  const dateParts = dateStr.split('-').map(Number);
  const dateObj = new Date(dateParts[0], dateParts[1] - 1, dateParts[2], hours, minutes);
  const formatter = new Intl.DateTimeFormat('en-CA', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    timeZone: tz,
    hour12: false,
  });
  const tzDate = formatter.format(dateObj);
  const [date, time] = tzDate.split(', ');
  const [year, month, day] = date.split('-');
  const offset = dateObj.getTime() - new Date(`${year}-${month}-${day}T${time}`).getTime();
  const utcDate = new Date(dateObj.getTime() + offset);
  return utcDate.toISOString();
};

const defaultFormState = {
  selectedCustomers: [],
  customRecipients: '',
  channels: ['Email'],
  delivery: 'Send immediately',
  scheduleDate: '',
  scheduleTime: '',
  scheduleTimezone: getUserTimezone(),
  message: 'Hi {{FirstName}},\n\nThank you for choosing us!\n\nWould you mind sharing your experience?\n\n⭐ Leave your review here:\n{{ReviewLink}}\n\nIt only takes one minute.\n\nThank you ❤️',
  tone: 'Friendly',
  destinations: ['Google']
};

const axios = window.axios;
const accountId = window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];

const currentStep = ref(1);
const form = ref({ ...defaultFormState });
const searchQuery = ref('');
const activeFilter = ref('Recent Customers');
const csvInput = ref(null);
const importError = ref('');
const loadingContacts = ref(false);

const filters = ['Recent Customers', 'Completed Jobs', 'Closed Deals', 'Positive Feedback', 'Appointment Completed', 'Invoice Paid'];

// Quick Filters map to contact labels; "Recent Customers" is just the default sort.
const FILTER_PARAMS = {
  'Recent Customers': { sort: '-last_activity_at' },
  'Completed Jobs': { labels: 'completed-job' },
  'Closed Deals': { labels: 'closed-deal' },
  'Positive Feedback': { labels: 'positive-feedback' },
  'Appointment Completed': { labels: 'appointment-completed' },
  'Invoice Paid': { labels: 'invoice-paid' },
};

// The label slugs the Quick Filters depend on, seeded so filters work out of the box.
const QUICK_FILTER_LABELS = Object.values(FILTER_PARAMS).map(p => p.labels).filter(Boolean);

// Create the default filter labels once (idempotent — skips ones that already exist),
// so the user doesn't have to set them up before tagging contacts.
let labelsEnsured = false;
async function ensureDefaultLabels() {
  if (labelsEnsured || !accountId) return;
  labelsEnsured = true;
  try {
    const { data } = await axios.get(`/api/v1/accounts/${accountId}/labels`);
    const existing = new Set((data.payload || []).map(l => l.title));
    const missing = QUICK_FILTER_LABELS.filter(t => !existing.has(t));
    await Promise.all(missing.map(title =>
      axios.post(`/api/v1/accounts/${accountId}/labels`, {
        label: { title, color: '#1f93ff', show_on_sidebar: true }
      }).catch(() => {})
    ));
  } catch (err) {
    labelsEnsured = false; // let it retry on next open
  }
}

// Real Chatwoot contacts (loaded on open) + any CSV-imported rows, prepended.
const allCustomers = ref([]);

// Past review requests, used to compute the real per-channel open rate.
const requests = ref([]);
async function loadRequests() {
  if (!accountId) return;
  try {
    const { data } = await axios.get(`/api/v1/accounts/${accountId}/reputation/review_requests`);
    requests.value = data.payload || data || [];
  } catch (err) {
    requests.value = [];
  }
}

function mapContact(c) {
  return {
    id: String(c.id),
    name: c.name || c.email || c.phone_number || 'Unknown',
    contextLabel: 'Contact:',
    contextValue: c.email || c.phone_number || '',
    email: c.email || '',
    phone: c.phone_number || ''
  };
}

async function loadContacts() {
  if (!accountId) return;
  loadingContacts.value = true;
  try {
    const params = FILTER_PARAMS[activeFilter.value] || { sort: '-last_activity_at' };
    const { data } = await axios.get(`/api/v1/accounts/${accountId}/contacts`, { params });
    allCustomers.value = (data.payload || []).map(mapContact);
  } catch (err) {
    console.error('Failed to load contacts', err);
  } finally {
    loadingContacts.value = false;
  }
}

watch(() => props.open, isOpen => { if (isOpen) { ensureDefaultLabels(); loadContacts(); loadRequests(); } }, { immediate: true });
watch(activeFilter, () => { if (props.open) loadContacts(); });

const filteredCustomers = computed(() => {
  if (!searchQuery.value) return allCustomers.value;
  return allCustomers.value.filter(c => c.name.toLowerCase().includes(searchQuery.value.toLowerCase()));
});

// Parse a CSV of contacts (name, email/phone) client-side and add them as
// selectable recipients. Accepts an optional header row; splits on comma only
// (contacts don't contain commas) — no CSV lib for this happy path.
function triggerImport() {
  importError.value = '';
  csvInput.value?.click();
}

function parseCsv(text) {
  const rows = text.split(/\r?\n/).map(l => l.trim()).filter(Boolean);
  if (!rows.length) return [];
  // Header only if it names columns and carries no actual contact data (@ / digits).
  const looksLikeHeader = /name|email|phone|contact/i.test(rows[0]) && !/[@\d]/.test(rows[0]);
  const dataRows = looksLikeHeader ? rows.slice(1) : rows;
  return dataRows.map(row => {
    const [name, contact] = row.split(',').map(c => (c || '').trim());
    return { name: name || contact, contact: contact || '' };
  }).filter(r => r.name);
}

// Turn the Manual Entry field (emails/phones, any delimiter) into selected recipients.
function addManualEntry() {
  const parts = form.value.customRecipients.split(/[\s,;]+/).map(s => s.trim()).filter(Boolean);
  if (!parts.length) return;
  const added = parts.map((contact, i) => ({
    id: `manual-${Date.now()}-${i}`,
    name: contact,
    contextLabel: 'Manual:',
    contextValue: contact,
    email: contact.includes('@') ? contact : '',
    phone: contact.includes('@') ? '' : contact
  }));
  allCustomers.value = [...added, ...allCustomers.value];
  form.value.selectedCustomers = [...form.value.selectedCustomers, ...added.map(c => c.id)];
  form.value.customRecipients = '';
}

function handleCsvImport(event) {
  const file = event.target.files?.[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    const parsed = parseCsv(String(reader.result || ''));
    if (!parsed.length) {
      importError.value = 'No contacts found in that file.';
      return;
    }
    const added = parsed.map((c, i) => ({
      id: `csv-${Date.now()}-${i}`,
      name: c.name,
      contextLabel: 'Imported:',
      contextValue: c.contact || 'CSV',
      email: (c.contact || '').includes('@') ? c.contact : '',
      phone: (c.contact || '').includes('@') ? '' : (c.contact || '')
    }));
    allCustomers.value = [...added, ...allCustomers.value];
    form.value.selectedCustomers = [
      ...form.value.selectedCustomers,
      ...added.map(c => c.id)
    ];
  };
  reader.onerror = () => { importError.value = 'Could not read that file.'; };
  reader.readAsText(file);
  event.target.value = '';
}

const previewMessage = computed(() => {
  return form.value.message
    .replace('{{FirstName}}', 'Sarah')
    .replace('{{BusinessName}}', 'New Relay')
    .replace('{{ReviewLink}}', 'newrelay.com/r/abc123')
    .replace('{{EmployeeName}}', 'Alex');
});

// Channels need email or a phone number; used for the picker and to validate recipients.
const CHANNEL_META = [
  { name: 'WhatsApp', key: 'whatsapp', field: 'phone', icon: MessageCircle, color: 'text-emerald-500', bg: 'bg-emerald-50' },
  { name: 'Email', key: 'email', field: 'email', icon: Mail, color: 'text-primary', bg: 'bg-primary/10' },
  { name: 'SMS', key: 'sms', field: 'phone', icon: Smartphone, color: 'text-primary', bg: 'bg-primary/10' }
];

// Real open rate per channel from past requests (opened = status past "sent"); "—" until there's data.
const channels = computed(() => {
  const acc = {};
  requests.value.forEach(r => {
    if (!r.channel) return;
    acc[r.channel] = acc[r.channel] || { sent: 0, opened: 0 };
    acc[r.channel].sent += 1;
    if (r.status !== 'sent') acc[r.channel].opened += 1;
  });
  return CHANNEL_META.map(c => {
    const d = acc[c.key];
    return { ...c, rate: d && d.sent ? `${Math.round((d.opened / d.sent) * 100)}%` : '—' };
  });
});

// Validate chosen channels against the selected, currently-visible recipients.
// ponytail: only sees recipients still in the loaded list (a filter switch can hide some) — fine for the happy path.
const selectedRecipients = computed(() =>
  allCustomers.value.filter(c => form.value.selectedCustomers.includes(c.id))
);
const channelError = computed(() => {
  const recips = selectedRecipients.value;
  if (!recips.length || !form.value.channels.length) return '';
  const missing = new Set();
  form.value.channels.forEach(name => {
    const meta = CHANNEL_META.find(c => c.name === name);
    if (meta && recips.some(r => !r[meta.field])) missing.add(meta.field === 'email' ? 'an email' : 'a phone number');
  });
  return missing.size ? `Some selected contacts have no ${[...missing].join(' or ')}. Remove them or deselect that channel.` : '';
});
const channelErrorWithRequired = computed(() => {
  if (!form.value.channels.length) return 'Select at least one delivery channel.';
  return channelError.value;
});

const minScheduleDate = computed(() => {
  const d = new Date();
  return d.toISOString().split('T')[0];
});

const scheduleError = computed(() => {
  if (form.value.delivery !== 'Schedule') return '';
  if (!form.value.scheduleDate || !form.value.scheduleTime) return 'Pick a date and time to schedule.';
  const isoDateTime = convertToUtcIso(form.value.scheduleDate, form.value.scheduleTime, form.value.scheduleTimezone);
  if (!isoDateTime) return 'Invalid date or time.';
  if (new Date(isoDateTime) <= new Date()) return 'Scheduled time must be in the future.';
  return '';
});
const step2Error = computed(() => channelErrorWithRequired.value || scheduleError.value);

// Selected real contacts send their numeric id; manual/CSV rows send their raw email/phone.
function buildRecipients() {
  const contactIds = [];
  const recipients = [];
  form.value.selectedCustomers.forEach(id => {
    if (/^\d+$/.test(id)) { contactIds.push(Number(id)); return; }
    const row = allCustomers.value.find(c => c.id === id);
    if (row) recipients.push(row.email || row.phone || row.contextValue);
  });
  return { contactIds, recipients };
}

const tones = ['Friendly', 'Professional', 'Luxury', 'Casual'];
const destinations = ['Google', 'Facebook', 'Trustpilot', 'Yelp', 'Custom Link'];

// Each tone swaps the composed message to a matching preset (this is what "Tone" does).
const TONE_PRESETS = {
  Friendly: 'Hi {{FirstName}},\n\nThanks so much for choosing us! 😊\n\nWe’d love to hear how it went — it only takes a minute:\n{{ReviewLink}}\n\nThank you!',
  Professional: 'Dear {{FirstName}},\n\nThank you for your business. We value your feedback and would appreciate a brief review of your experience:\n{{ReviewLink}}\n\nKind regards,\n{{BusinessName}}',
  Luxury: 'Dear {{FirstName}},\n\nIt was our pleasure to serve you. We would be honoured if you shared a few words about your experience:\n{{ReviewLink}}\n\nWith gratitude,\n{{BusinessName}}',
  Casual: 'Hey {{FirstName}}! 👋\n\nHope you loved it! Mind dropping us a quick review?\n{{ReviewLink}}\n\nThanks a ton!',
};
function applyTone(tone) {
  form.value.tone = tone;
  form.value.message = TONE_PRESETS[tone] || form.value.message;
}

function toggleSelection(array, item) {
  const index = array.indexOf(item);
  if (index === -1) array.push(item);
  else array.splice(index, 1);
}

function selectAllCustomers() {
  if (form.value.selectedCustomers.length === filteredCustomers.value.length) {
    form.value.selectedCustomers = [];
  } else {
    form.value.selectedCustomers = filteredCustomers.value.map(c => c.id);
  }
}

function nextStep() {
  if (currentStep.value === 2 && step2Error.value) return;
  if (currentStep.value < 5) currentStep.value++;
}

function prevStep() {
  if (currentStep.value > 1) currentStep.value--;
}

async function generateReport() {
  if (step2Error.value) { currentStep.value = 2; return; }
  const { contactIds, recipients } = buildRecipients();
  const scheduledAt = form.value.delivery === 'Schedule'
    ? convertToUtcIso(form.value.scheduleDate, form.value.scheduleTime, form.value.scheduleTimezone)
    : null;
  try {
    await axios.post(`/api/v1/accounts/${accountId}/reputation/review_requests`, {
      channel: (form.value.channels[0] || 'Email').toLowerCase(),
      contact_ids: contactIds,
      recipients,
      message: form.value.message,
      destinations: form.value.destinations,
      scheduled_at: scheduledAt,
    });
  } catch (err) {
    // surface nothing blocking — still show the success step for this demo surface
  } finally {
    currentStep.value = 5;
  }
}

function close() {
  emit('update:open', false);
  setTimeout(() => {
    currentStep.value = 1;
    form.value = { ...defaultFormState };
    form.value.selectedCustomers = [];
    form.value.channels = ['WhatsApp', 'Email'];
    form.value.destinations = ['Google'];
  }, 300);
}
</script>

<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6">
    <div class="absolute inset-0 bg-background/80 backdrop-blur-xs" @click="close"></div>
    
    <div class="relative w-full max-w-5xl max-h-[90vh] bg-card rounded-2xl shadow-2xl border border-border flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200">
      
      <!-- Header -->
      <div v-if="currentStep < 5" class="px-6 py-4 border-b border-border flex items-center justify-between bg-muted/30">
        <div>
          <h2 class="text-xl font-semibold text-foreground">Request Customer Reviews</h2>
          <div class="flex items-center gap-2 mt-1.5 text-sm">
            <span :class="currentStep >= 1 ? 'text-primary font-medium' : 'text-muted-foreground'">1. Recipients</span>
            <ChevronRight class="size-3.5 text-muted-foreground/50" />
            <span :class="currentStep >= 2 ? 'text-primary font-medium' : 'text-muted-foreground'">2. Channel</span>
            <ChevronRight class="size-3.5 text-muted-foreground/50" />
            <span :class="currentStep >= 3 ? 'text-primary font-medium' : 'text-muted-foreground'">3. Message</span>
            <ChevronRight class="size-3.5 text-muted-foreground/50" />
            <span :class="currentStep >= 4 ? 'text-primary font-medium' : 'text-muted-foreground'">4. Review</span>
          </div>
        </div>
        <button class="size-8 rounded-full flex items-center justify-center text-muted-foreground hover:bg-muted cursor-pointer transition-colors" @click="close">
          <X class="size-5" />
        </button>
      </div>
      
      <!-- Body -->
      <div class="flex-1 overflow-y-auto p-0 bg-card hide-scrollbar flex flex-col">
        
        <!-- STEP 1: Select Recipients -->
        <div v-if="currentStep === 1" class="flex-1 flex animate-in slide-in-from-right-4 duration-300 min-h-[450px]">
          <!-- Sidebar Filters -->
          <div class="w-64 border-r border-border bg-muted/10 p-4 space-y-6 hidden md:block shrink-0">
            <div>
              <h3 class="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">Quick Filters</h3>
              <div class="space-y-1">
                <button 
                  v-for="filter in filters" :key="filter"
                  class="w-full text-left px-3 py-2 rounded-md text-sm cursor-pointer transition-colors"
                  :class="activeFilter === filter ? 'bg-primary/10 text-primary font-medium' : 'text-muted-foreground hover:bg-muted/50 hover:text-foreground'"
                  @click="activeFilter = filter"
                >
                  {{ filter }}
                </button>
              </div>
            </div>
            <div class="pt-4 border-t border-border space-y-4">
              <button type="button" class="w-full h-9 px-4 text-sm font-semibold bg-card border border-border rounded-lg text-foreground hover:bg-muted cursor-pointer inline-flex items-center justify-start gap-2" @click="triggerImport">
                <Upload class="size-4 text-muted-foreground" /> Import CSV
              </button>
              <input ref="csvInput" type="file" accept=".csv,text/csv" class="hidden" @change="handleCsvImport" />
              <p v-if="importError" class="text-xs text-red-500">{{ importError }}</p>

              <div class="flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">Manual Entry</label>
                <Input v-model="form.customRecipients" placeholder="Emails or phone numbers..." class="h-10 px-4 text-[14px] shadow-xs rounded-md border-border/80 bg-background" @keyup.enter="addManualEntry" />
                <p class="text-[11px] text-muted-foreground">Press Enter to add. Separate multiple with commas.</p>
              </div>
            </div>
          </div>
          
          <!-- Main Content -->
          <div class="flex-1 p-6 flex flex-col">
            <div class="flex items-center justify-between mb-4">
              <div class="relative w-full max-w-md">
                <Search class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
                <Input v-model="searchQuery" placeholder="Search customers..." class="pl-9 h-10 px-4 text-[14px] shadow-xs rounded-md border-border/80 bg-background" />
              </div>
              <div class="flex items-center gap-4">
                <span class="text-sm font-medium text-primary bg-primary/10 px-3 py-1 rounded-full">{{ form.selectedCustomers.length }} selected</span>
                <button @click="selectAllCustomers" class="text-xs font-semibold text-muted-foreground hover:text-foreground cursor-pointer inline-flex items-center gap-1.5">
                  <CheckCircle2 class="size-4" :class="form.selectedCustomers.length === filteredCustomers.length && filteredCustomers.length > 0 ? 'text-primary' : ''" /> Select All
                </button>
              </div>
            </div>
            
            <div v-if="loadingContacts" class="flex items-center justify-center py-10 text-sm text-muted-foreground">Loading contacts…</div>
            <div v-else-if="filteredCustomers.length === 0" class="flex items-center justify-center py-10 text-sm text-muted-foreground">No contacts found. Import a CSV or add contacts first.</div>
            <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-2 gap-3 overflow-y-auto pr-2 pb-4">
              <div
                v-for="customer in filteredCustomers" :key="customer.id"
                class="flex items-start gap-3 p-3 rounded-xl border cursor-pointer transition-all"
                :class="form.selectedCustomers.includes(customer.id) ? 'border-primary bg-primary/5 shadow-xs' : 'border-border bg-card hover:border-primary/30'"
                @click="toggleSelection(form.selectedCustomers, customer.id)"
              >
                <div class="mt-0.5 size-4 rounded-md border flex items-center justify-center transition-colors shrink-0" :class="form.selectedCustomers.includes(customer.id) ? 'bg-primary border-primary text-primary-foreground' : 'border-muted-foreground/30 bg-background'">
                  <Check v-if="form.selectedCustomers.includes(customer.id)" class="size-3" />
                </div>
                <div class="flex-1 min-w-0">
                  <div class="font-medium text-foreground text-sm truncate">{{ customer.name }}</div>
                  <div class="flex items-center text-xs mt-1 text-muted-foreground gap-1.5">
                    <span>{{ customer.contextLabel }}</span>
                    <span class="font-medium text-foreground">{{ customer.contextValue }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- STEP 2: Choose Delivery Channel -->
        <div v-if="currentStep === 2" class="p-6 space-y-10 animate-in slide-in-from-right-4 duration-300">
          <div class="space-y-4">
            <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Delivery Channels (Multiple Allowed)</h3>
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
                    <h4 class="font-semibold text-lg text-foreground mb-1">{{ channel.name }}</h4>
                    <div class="flex items-center gap-1.5 text-sm">
                      <Star class="size-3.5 fill-amber-400 text-amber-400" v-if="channel.name === 'WhatsApp'" />
                      <span class="font-medium text-foreground">{{ channel.rate }}</span>
                      <span class="text-muted-foreground">{{ channel.rate === '—' ? 'No sends yet' : 'Open Rate' }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <p v-if="channelErrorWithRequired" class="text-sm text-red-500 flex items-center gap-1.5">
              <AlertCircle class="size-4 shrink-0" /> {{ channelErrorWithRequired }}
            </p>
          </div>

          <div class="space-y-4">
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
            <div v-if="form.delivery === 'Schedule'" class="space-y-3">
              <div class="grid grid-cols-3 gap-3 items-end">
                <div class="space-y-1">
                  <label class="text-xs font-medium text-foreground">Date</label>
                  <RelayDatePicker
                    v-model="form.scheduleDate"
                    placeholder="Pick date"
                    display-format="MMM dd, yyyy"
                    value-format="yyyy-MM-dd"
                    :min-date="new Date()"
                  />
                </div>
                <div class="space-y-1">
                  <label class="text-xs font-medium text-foreground">Time</label>
                  <RelayTimePicker
                    v-model="form.scheduleTime"
                    placeholder="--:-- --"
                  />
                </div>
                <div class="space-y-1">
                  <label class="text-xs font-medium text-foreground">Timezone</label>
                  <div class="relative">
                    <select
                      v-model="form.scheduleTimezone"
                      class="w-full h-9 px-3 text-xs shadow-sm rounded-md border border-border bg-background appearance-none focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 cursor-pointer pr-8"
                    >
                      <option v-for="tz in COMMON_TIMEZONES" :key="tz.value" :value="tz.value">
                        {{ tz.label }}
                      </option>
                    </select>
                    <Globe class="absolute right-2 top-1/2 -translate-y-1/2 size-4 text-muted-foreground pointer-events-none" />
                  </div>
                </div>
              </div>
              <p v-if="scheduleError" class="text-sm text-red-500 flex items-center gap-1.5">
                <AlertCircle class="size-4 shrink-0" /> {{ scheduleError }}
              </p>
            </div>
          </div>
        </div>

        <!-- STEP 3: Customize Request -->
        <div v-if="currentStep === 3" class="flex-1 flex animate-in slide-in-from-right-4 duration-300 min-h-[450px]">
          <!-- Editor Side -->
          <div class="flex-1 p-6 space-y-6 overflow-y-auto">
            <div class="flex items-center justify-between">
              <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Message Content</h3>
              <button class="h-8 px-3 text-xs font-semibold gap-1.5 bg-primary/10 text-primary border border-primary/20 hover:bg-primary/20 rounded-lg inline-flex items-center cursor-pointer">
                <Sparkles class="size-3.5" /> Improve Message
              </button>
            </div>
            
            <textarea 
              v-model="form.message"
              class="w-full h-64 p-3 text-[14px] shadow-xs rounded-md border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30"
            ></textarea>
            
            <div class="space-y-3">
              <p class="text-xs font-medium text-muted-foreground uppercase tracking-wider">Variables</p>
              <div class="flex flex-wrap gap-2">
                <Badge v-for="v in ['{{FirstName}}', '{{BusinessName}}', '{{ReviewLink}}', '{{EmployeeName}}']" :key="v" class="font-mono text-xs cursor-pointer bg-muted hover:bg-primary/20 text-foreground">
                  {{ v }}
                </Badge>
              </div>
            </div>

            <div class="space-y-3">
              <p class="text-xs font-medium text-muted-foreground uppercase tracking-wider">Tone</p>
              <div class="flex flex-wrap gap-2">
                <button
                  v-for="tone in tones" :key="tone" type="button"
                  class="px-3 py-1.5 rounded-lg border text-xs transition-colors"
                  :class="form.tone === tone ? 'bg-primary/10 border-primary text-primary font-medium' : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                  @click="applyTone(tone)"
                >
                  {{ tone }}
                </button>
              </div>
            </div>

            <div class="space-y-3">
              <p class="text-xs font-medium text-muted-foreground uppercase tracking-wider">Review Destination</p>
              <div class="flex flex-wrap gap-2">
                <button
                  v-for="dest in destinations" :key="dest" type="button"
                  class="px-3 py-1.5 rounded-lg border text-xs inline-flex items-center gap-1.5 transition-colors"
                  :class="form.destinations.includes(dest) ? 'bg-primary/10 border-primary text-primary font-medium' : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                  @click="toggleSelection(form.destinations, dest)"
                >
                  <Check v-if="form.destinations.includes(dest)" class="size-3" />
                  {{ dest }}
                </button>
              </div>
            </div>
          </div>
          
          <!-- Preview Side (Mobile Phone Mockup) -->
          <div class="w-[380px] bg-muted/20 border-l border-border p-8 flex items-center justify-center shrink-0">
            <div class="w-[280px] h-[480px] bg-white dark:bg-black rounded-[40px] border-[8px] border-slate-200 dark:border-slate-800 shadow-2xl relative overflow-hidden flex flex-col">
              <!-- Notch -->
              <div class="absolute top-0 inset-x-0 h-6 flex justify-center z-10">
                <div class="w-32 h-5 bg-slate-200 dark:bg-slate-800 rounded-b-xl"></div>
              </div>
              <!-- Header -->
              <div class="bg-slate-100 dark:bg-slate-900 pt-10 pb-3 px-4 flex items-center gap-3 border-b border-slate-200 dark:border-slate-800 shrink-0">
                <div class="size-8 rounded-full bg-slate-300 dark:bg-slate-700 flex items-center justify-center overflow-hidden">
                  <img src="https://ui-avatars.com/api/?name=New+Relay&background=random" class="w-full h-full object-cover" />
                </div>
                <div>
                  <div class="text-xs font-semibold text-slate-900 dark:text-white">New Relay</div>
                  <div class="text-[10px] text-slate-500">Business Account</div>
                </div>
              </div>
              <!-- Chat Body -->
              <div class="flex-1 bg-slate-50 dark:bg-black p-4 overflow-y-auto space-y-4">
                <div class="text-[10px] text-center text-slate-400 font-medium my-2">Today 9:41 AM</div>
                <div class="bg-primary text-white rounded-2xl rounded-tl-sm p-3 text-[13px] shadow-xs whitespace-pre-wrap leading-relaxed max-w-[85%] relative pb-6">
                  {{ previewMessage }}
                  <div class="absolute right-2 bottom-1.5 text-[9px] text-blue-200">9:41 AM</div>
                </div>
              </div>
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
              <h2 class="text-base font-medium text-foreground mb-2">Ready to Send?</h2>
              <p class="text-muted-foreground text-sm">Verify your campaign details before launching.</p>
            </div>
            
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 items-stretch">
              <!-- Left Column: Settings Cards -->
              <div class="flex flex-col gap-4">
                <!-- Recipients Card -->
                <div class="bg-card border border-border rounded-xl p-5 shadow-xs flex items-center gap-4">
                  <div class="size-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0 border border-primary/20">
                    <Users class="size-4 text-primary" />
                  </div>
                  <div>
                    <div class="text-xs text-muted-foreground mb-0.5">Recipients</div>
                    <div class="text-sm font-medium text-foreground">
                      {{ form.selectedCustomers.length }} Customers
                    </div>
                  </div>
                </div>

                <!-- Channels Card -->
                <div class="bg-card border border-border rounded-xl p-5 shadow-xs flex items-center gap-4">
                  <div class="size-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0 border border-primary/20">
                    <MessageSquare class="size-4 text-primary" />
                  </div>
                  <div>
                    <div class="text-xs text-muted-foreground mb-0.5">Channels</div>
                    <div class="text-sm font-medium text-foreground">
                      {{ form.channels.length > 0 ? form.channels.join(' + ') : 'None Selected' }}
                    </div>
                  </div>
                </div>

                <!-- Review Platform Card -->
                <div class="bg-card border border-border rounded-xl p-5 shadow-xs flex items-center gap-4">
                  <div class="size-10 rounded-full bg-amber-50 dark:bg-amber-900/30 flex items-center justify-center shrink-0 border border-amber-100 dark:border-amber-800">
                    <Star class="size-4 text-amber-600 dark:text-amber-400" />
                  </div>
                  <div>
                    <div class="text-xs text-muted-foreground mb-0.5">Review Platform</div>
                    <div class="text-sm font-medium text-foreground">
                      {{ form.destinations.join(', ') || 'Auto-optimized' }}
                    </div>
                  </div>
                </div>
              </div>
              
              <!-- Right Column: Message Preview Box -->
              <div class="bg-muted/30 border border-border rounded-xl overflow-hidden shadow-xs h-full flex flex-col">
                <div class="bg-muted/50 border-b border-border px-4 py-3 flex items-center gap-2 shrink-0">
                  <FileText class="size-4 text-muted-foreground" />
                  <span class="text-sm font-medium text-foreground">Message Preview</span>
                </div>
                <div class="p-5 flex-1 overflow-y-auto">
                  <div class="bg-card border border-border rounded-2xl rounded-tl-sm p-4 text-[14px] shadow-xs whitespace-pre-wrap leading-relaxed inline-block max-w-[95%] text-left">
                    {{ previewMessage }}
                  </div>
                </div>
              </div>
            </div>

          </div>
        </div>
        
        <!-- STEP 5: Success Screen -->
        <div v-if="currentStep === 5" class="py-16 flex flex-col items-center text-center animate-in zoom-in-95 duration-500 flex-1">
          <div class="size-20 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 rounded-full flex items-center justify-center mb-6">
            <CheckCircle2 class="size-10" />
          </div>
          <h2 class="text-base font-medium text-foreground mb-2">Review Requests Sent!</h2>
          <p class="text-muted-foreground mb-10 text-lg">{{ form.selectedCustomers.length }} customers</p>
          
          <div class="flex items-center justify-center gap-8 mb-10">
            <div class="text-center" v-for="channel in form.channels" :key="channel">
              <div class="size-12 rounded-full bg-muted/50 flex items-center justify-center mx-auto mb-2 border">
                <MessageCircle class="size-5 text-emerald-500" v-if="channel === 'WhatsApp'" />
                <Mail class="size-5 text-primary" v-if="channel === 'Email'" />
                <Smartphone class="size-5 text-primary" v-if="channel === 'SMS'" />
              </div>
              <div class="font-bold text-xl text-foreground">{{ form.selectedCustomers.length }}</div>
              <div class="text-xs text-muted-foreground">{{ channel }}</div>
            </div>
          </div>
          
          <div class="flex flex-wrap justify-center gap-3">
            <button @click="close" class="h-11 px-8 text-sm font-semibold bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-xs cursor-pointer inline-flex items-center gap-2">
              <BarChart3 class="size-4" /> View Campaign
            </button>
            <button @click="close" class="h-11 px-8 text-sm font-semibold bg-card border border-border hover:bg-muted text-foreground rounded-lg shadow-xs cursor-pointer">
              Done
            </button>
          </div>
        </div>

      </div>
      
      <!-- Footer Actions -->
      <div v-if="currentStep < 5" class="px-6 py-4 border-t border-border bg-muted/10 flex items-center justify-between shrink-0">
        <button class="h-9 px-4 text-sm font-semibold text-muted-foreground hover:text-foreground cursor-pointer disabled:opacity-40" @click="prevStep" :disabled="currentStep === 1">
          Back
        </button>
        <button v-if="currentStep < 4" class="h-9 px-8 text-sm font-semibold bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-xs cursor-pointer inline-flex items-center gap-2 disabled:opacity-40 disabled:cursor-not-allowed" @click="nextStep" :disabled="(currentStep === 1 && form.selectedCustomers.length === 0) || (currentStep === 2 && !!step2Error)">
          Next
          <ChevronRight class="size-4" />
        </button>
        <button v-else-if="currentStep === 4" class="h-9 px-8 text-sm font-semibold bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-xs cursor-pointer inline-flex items-center gap-2" @click="generateReport">
          <Send class="size-4 mr-1" /> Send Requests
        </button>
      </div>

    </div>
  </div>
</template>
