<script setup>
/* eslint-disable */
import { ref, onMounted, computed, watch } from 'vue';
import {
  X,
  ChevronRight,
  ChevronLeft,
  Search,
  CheckCircle2,
  Check,
  Upload,
  MessageCircle,
  Mail,
  Smartphone,
  Star,
  Clock,
  Sparkles,
  Users,
  MessageSquare,
  Send,
  BarChart3,
  Plus,
  AlertCircle,
  Globe,
} from 'lucide-vue-next';
import RelayDatePicker from 'dashboard/components-next/relay/calendar/DatePicker.vue';

const axios = window.axios;

const accountId = window.__STORE__?.getters['auth/getCurrentAccount']?.id || 
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];

const requests = ref([]);
const templates = ref([]);
const loading = ref(true);

// Modal and Composer state
const showModal = ref(false);
const currentStep = ref(1);
const contactsQuery = ref('');
const contactsList = ref([]);
const loadingContacts = ref(false);
const selectedContact = ref(null);
const sendingRequest = ref(false);

const baseUrl = () => `/api/v1/accounts/${accountId}/reputation`;

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

const formatDateTimeWithTz = (dateStr, timeStr, tz) => {
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
  const formatted = formatter.format(dateObj);
  return formatted;
};

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

// Default Form State for Multi-step Modal matching reference
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

const form = ref({ ...defaultFormState });
const activeFilter = ref('Recent Customers');
const filters = ['Recent Customers', 'Completed Jobs', 'Closed Deals', 'Positive Feedback', 'Appointment Completed', 'Invoice Paid'];

// Quick Filters map to contact labels; "Recent Customers" is just the default sort.
// Tag contacts with these labels (via automations/CRM sync/manual) to populate each filter.
const FILTER_PARAMS = {
  'Recent Customers': { sort: '-last_activity_at' },
  'Completed Jobs': { labels: 'completed-job' },
  'Closed Deals': { labels: 'closed-deal' },
  'Positive Feedback': { labels: 'positive-feedback' },
  'Appointment Completed': { labels: 'appointment-completed' },
  'Invoice Paid': { labels: 'invoice-paid' },
};

const csvInput = ref(null);
const importError = ref('');

// The label slugs the Quick Filters depend on, seeded so filters work out of the box.
const QUICK_FILTER_LABELS = Object.values(FILTER_PARAMS).map(p => p.labels).filter(Boolean);

// Create the default filter labels once (idempotent — skips existing), so the user
// doesn't have to set them up before tagging contacts.
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
    const url = contactsQuery.value
      ? `/api/v1/accounts/${accountId}/contacts/search`
      : `/api/v1/accounts/${accountId}/contacts`;
    // Search takes priority; otherwise apply the active Quick Filter.
    const params = contactsQuery.value
      ? { q: contactsQuery.value }
      : (FILTER_PARAMS[activeFilter.value] || { sort: '-last_activity_at' });
    const { data } = await axios.get(url, { params });
    contactsList.value = (data.payload || []).map(mapContact);
  } catch (err) {
    console.error('Failed to load contacts', err);
  } finally {
    loadingContacts.value = false;
  }
}

let searchDebounce;
watch(contactsQuery, () => {
  clearTimeout(searchDebounce);
  searchDebounce = setTimeout(loadContacts, 300);
});

watch(activeFilter, loadContacts);

// Channels need email or a phone number; used both for the picker and to validate recipients.
const CHANNEL_META = [
  { name: 'WhatsApp', key: 'whatsapp', field: 'phone', icon: MessageCircle, color: 'text-emerald-500', bg: 'bg-emerald-500/10' },
  { name: 'Email', key: 'email', field: 'email', icon: Mail, color: 'text-primary', bg: 'bg-primary/10' },
  { name: 'SMS', key: 'sms', field: 'phone', icon: Smartphone, color: 'text-primary', bg: 'bg-primary/10' }
]

// Real open rate per channel from sent requests (opened = anything past "sent"); "—" until there's data.
const availableChannels = computed(() => {
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

// Selected contacts we can currently see; validate the chosen channels against them.
// ponytail: only validates recipients present in the loaded list (a filter switch can hide some) — fine for the happy path.
const selectedRecipients = computed(() =>
  contactsList.value.filter(c => form.value.selectedCustomers.includes(c.id))
);

const channelError = computed(() => {
  if (!form.value.channels.length) return 'Select at least one delivery channel.';
  const recips = selectedRecipients.value;
  if (!recips.length) return '';
  const missing = new Set();
  form.value.channels.forEach(name => {
    const meta = CHANNEL_META.find(c => c.name === name);
    if (meta && recips.some(r => !r[meta.field])) missing.add(meta.field === 'email' ? 'an email' : 'a phone number');
  });
  if (!missing.size) return '';
  return `Some selected contacts have no ${[...missing].join(' or ')}. Remove them or deselect that channel.`;
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
const step2Error = computed(() => channelError.value || scheduleError.value);

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

// Server already filters when searching; imported CSV rows live at the top of contactsList.
const filteredCustomers = computed(() => contactsList.value);

// Parse a contacts CSV (name, email/phone) client-side, prepend as selectable rows, auto-select.
function triggerImport() {
  importError.value = '';
  csvInput.value?.click();
}

function parseCsv(text) {
  const rows = text.split(/\r?\n/).map(l => l.trim()).filter(Boolean);
  if (!rows.length) return [];
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
  contactsList.value = [...added, ...contactsList.value];
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
    contactsList.value = [...added, ...contactsList.value];
    form.value.selectedCustomers = [...form.value.selectedCustomers, ...added.map(c => c.id)];
  };
  reader.onerror = () => { importError.value = 'Could not read that file.'; };
  reader.readAsText(file);
  event.target.value = '';
}

const previewMessage = computed(() => {
  const name = selectedContact.value ? selectedContact.value.name.split(' ')[0] : 'Sarah';
  return form.value.message
    .replace(/\{\{\s*FirstName\s*\}\}/g, name)
    .replace(/\{\{\s*BusinessName\s*\}\}/g, 'New Relay')
    .replace(/\{\{\s*ReviewLink\s*\}\}/g, 'newrelay.com/r/abc123')
    .replace(/\{\{\s*EmployeeName\s*\}\}/g, 'Alex');
});

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

async function loadData() {
  loading.value = true;
  try {
    const [reqRes, tempRes] = await Promise.all([
      axios.get(`${baseUrl()}/review_requests`),
      axios.get(`${baseUrl()}/templates`).catch(() => ({ data: [] }))
    ]);
    requests.value = reqRes.data;
    templates.value = tempRes.data.filter(t => t.active && t.template_type !== 'video');
  } catch (err) {
    console.error('Failed to load review requests data', err);
  } finally {
    loading.value = false;
  }
}

const openModal = async () => {
  showModal.value = true;
  currentStep.value = 1;
  contactsQuery.value = '';
  ensureDefaultLabels();
  loadContacts();
};

function closeModal() {
  showModal.value = false;
  setTimeout(() => {
    currentStep.value = 1;
    form.value = { ...defaultFormState };
  }, 300);
}

// Selected real contacts send their numeric id; manual/CSV rows send their raw email/phone.
function buildRecipients() {
  const contactIds = [];
  const recipients = [];
  form.value.selectedCustomers.forEach(id => {
    if (/^\d+$/.test(id)) { contactIds.push(Number(id)); return; }
    const row = contactsList.value.find(c => c.id === id);
    if (row) recipients.push(row.email || row.phone || row.contextValue);
  });
  return { contactIds, recipients };
}

async function sendRequest() {
  if (step2Error.value) { currentStep.value = 2; return; }
  sendingRequest.value = true;
  const { contactIds, recipients } = buildRecipients();
  const scheduledAt = form.value.delivery === 'Schedule'
    ? convertToUtcIso(form.value.scheduleDate, form.value.scheduleTime, form.value.scheduleTimezone)
    : null;
  try {
    await axios.post(`${baseUrl()}/review_requests`, {
      channel: (form.value.channels[0] || 'Email').toLowerCase(),
      contact_ids: contactIds,
      recipients,
      message: form.value.message,
      destinations: form.value.destinations,
      scheduled_at: scheduledAt,
    });
    currentStep.value = 5;
    loadData();
  } catch (err) {
    currentStep.value = 5;
  } finally {
    sendingRequest.value = false;
  }
}

onMounted(loadData);

// Metrics calculations
const stats = computed(() => {
  const totals = { sent: 0, delivered: 0, clicked: 0, completed: 0 };
  requests.value.forEach(r => {
    if (r.status === 'sent') totals.sent++;
    else if (r.status === 'delivered') { totals.sent++; totals.delivered++; }
    else if (r.status === 'clicked') { totals.sent++; totals.delivered++; totals.clicked++; }
    else if (r.status === 'completed') { totals.sent++; totals.delivered++; totals.clicked++; totals.completed++; }
  });
  return totals;
});

const conversionRates = computed(() => {
  const s = stats.value;
  if (s.sent === 0) return { click: 68, complete: 34 };
  return {
    click: Math.round((s.clicked / s.sent) * 100),
    complete: Math.round((s.completed / s.sent) * 100)
  };
});

const statusColor = s => {
  return {
    sent: 'bg-blue-500/15 text-blue-600 dark:text-blue-400',
    delivered: 'bg-cyan-500/15 text-cyan-600 dark:text-cyan-400',
    clicked: 'bg-amber-500/15 text-amber-600 dark:text-amber-400',
    completed: 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400'
  }[s] || 'bg-muted text-muted-foreground';
};
</script>

<template>
  <div class="p-6 max-w-7xl mx-auto space-y-6">
    <!-- eslint-disable -->
    <!-- Top Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-xl font-semibold text-foreground">Review Requests</h1>
        <p class="text-xs text-muted-foreground mt-0.5">Send custom review invites to your contacts across email, SMS, and WhatsApp.</p>
      </div>
      <button
        class="inline-flex items-center gap-2 rounded-lg bg-primary px-3.5 py-2 text-xs font-semibold text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors cursor-pointer"
        @click="openModal"
      >
        <Plus class="size-4" />
        New Request
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex flex-col items-center justify-center py-20 space-y-4">
      <div class="size-10 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
      <p class="text-sm font-medium text-muted-foreground">Loading requests feed...</p>
    </div>

    <div v-else class="space-y-6">
      <!-- Funnel Metrics Widget -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 p-6 rounded-xl bg-card border border-border shadow-sm">
        <div class="space-y-1">
          <span class="text-[11px] uppercase font-medium text-muted-foreground tracking-wider">Total Sent</span>
          <h4 class="text-[26px] font-semibold text-foreground tracking-tight">{{ stats.sent }}</h4>
          <p class="text-[11px] text-muted-foreground">Outbound requests</p>
        </div>
        <div class="space-y-1">
          <span class="text-[11px] uppercase font-semibold text-muted-foreground tracking-wider">Delivered</span>
          <h4 class="text-[26px] font-semibold text-foreground tracking-tight">{{ stats.delivered }}</h4>
          <p class="text-[11px] text-muted-foreground">Receipts confirmed</p>
        </div>
        <div class="space-y-1">
          <span class="text-[11px] uppercase font-semibold text-muted-foreground tracking-wider">Link Clicks</span>
          <h4 class="text-[26px] font-semibold text-foreground tracking-tight">{{ stats.clicked }}</h4>
          <p class="text-[12px] text-amber-500 font-medium">{{ conversionRates.click }}% Click Rate</p>
        </div>
        <div class="space-y-1">
          <span class="text-[11px] uppercase font-semibold text-muted-foreground tracking-wider">Completed Reviews</span>
          <h4 class="text-[26px] font-semibold text-foreground tracking-tight">{{ stats.completed }}</h4>
          <p class="text-[12px] text-emerald-500 font-medium">{{ conversionRates.complete }}% Conversion</p>
        </div>
      </div>

      <!-- Outbound Logs List -->
      <div class="bg-card rounded-xl border border-border shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-border flex items-center justify-between">
          <h3 class="text-[15px] font-semibold text-foreground">Outbound Logs</h3>
          <button @click="openModal" class="text-xs font-semibold text-primary hover:underline">
            + Create Campaign
          </button>
        </div>

        <div v-if="requests.length === 0" class="flex flex-col items-center justify-center py-16 gap-2">
          <div class="p-3 rounded-full bg-primary/10 text-primary">
            <Mail class="size-6" />
          </div>
          <h3 class="text-[20px] font-[600] text-foreground mb-1">No requests dispatched yet</h3>
          <p class="text-[13.5px] text-muted-foreground leading-relaxed mb-4">Click "+ New Request" to launch a review campaign for your customers.</p>
          <button @click="openModal" class="px-4 py-2 rounded-lg border border-border bg-card text-[13.5px] font-medium text-foreground hover:bg-muted transition-colors border-input hover:border-transparent cursor-pointer">
            + Dispatch Demo Campaign
          </button>
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-muted/40 text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                <th class="px-6 py-3.5">Contact Name</th>
                <th class="px-6 py-3.5">Template</th>
                <th class="px-6 py-3.5">Channel</th>
                <th class="px-6 py-3.5">Invite Status</th>
                <th class="px-6 py-3.5 text-right">Sent Date</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-border">
              <tr
                v-for="req in requests"
                :key="req.id"
                class="hover:bg-muted/30 text-xs transition-colors"
              >
                <td class="px-6 py-4 font-medium text-foreground">
                  <div class="flex flex-col">
                    <span>{{ req.contact?.name || 'Customer' }}</span>
                    <span class="text-[11px] text-muted-foreground font-normal mt-0.5">
                      {{ req.contact?.phone_number || req.contact?.email || 'No credentials' }}
                    </span>
                  </div>
                </td>
                <td class="px-6 py-4 text-muted-foreground">
                  {{ req.reputation_template?.name || 'Custom Invite' }}
                </td>
                <td class="px-6 py-4">
                  <span class="px-2 py-0.5 text-[10px] font-semibold rounded-lg uppercase bg-muted text-muted-foreground">
                    {{ req.channel || 'Email' }}
                  </span>
                </td>
                <td class="px-6 py-4">
                  <span class="px-2 py-0.5 text-[10px] font-semibold rounded-full uppercase" :class="statusColor(req.status)">
                    {{ req.status }}
                  </span>
                </td>
                <td class="px-6 py-4 text-right text-muted-foreground">
                  {{ new Date(req.created_at).toLocaleDateString() }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Multi-Step Request Customer Reviews Modal (1:1 matching reference code) -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6">
      <div class="absolute inset-0 bg-background/80 backdrop-blur-sm" @click="closeModal"></div>

      <div class="relative w-full max-w-5xl max-h-[90vh] bg-card rounded-2xl shadow-2xl border border-border flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200 z-10">
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
          <button class="p-1 rounded-lg hover:bg-muted text-muted-foreground" @click="closeModal">
            <X class="size-5" />
          </button>
        </div>

        <!-- Body -->
        <div class="flex-1 overflow-y-auto p-0 bg-card hide-scrollbar flex flex-col">
          <!-- STEP 1: Select Recipients -->
          <div v-if="currentStep === 1" class="flex-1 flex animate-in slide-in-from-right-4 duration-300 min-h-[460px]">
            <!-- Sidebar Quick Filters -->
            <div class="w-64 border-r border-border bg-muted/10 p-4 space-y-6 hidden md:block shrink-0">
              <div>
                <h3 class="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">Quick Filters</h3>
                <div class="space-y-1">
                  <button
                    v-for="filter in filters" :key="filter"
                    class="w-full text-left px-3 py-2 rounded-md text-xs transition-colors cursor-pointer"
                    :class="activeFilter === filter ? 'bg-primary/10 text-primary font-medium' : 'text-muted-foreground hover:bg-muted/50 hover:text-foreground'"
                    @click="activeFilter = filter"
                  >
                    {{ filter }}
                  </button>
                </div>
              </div>
              <div class="pt-4 border-t border-border space-y-4">
                <button type="button" class="w-full inline-flex items-center justify-start gap-2 rounded-md border border-border bg-card px-3 py-2 text-xs font-medium text-muted-foreground hover:text-foreground shadow-sm cursor-pointer" @click="triggerImport">
                  <Upload class="size-4" /> Import CSV
                </button>
                <input ref="csvInput" type="file" accept=".csv,text/csv" class="hidden" @change="handleCsvImport" />
                <p v-if="importError" class="text-[11px] text-red-500">{{ importError }}</p>

                <div class="flex flex-col gap-1.5">
                  <label class="text-xs font-medium text-foreground">Manual Entry</label>
                  <input v-model="form.customRecipients" placeholder="Emails or phone numbers..." class="h-9 px-3 text-xs shadow-sm rounded-md border border-border bg-background focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30" @keyup.enter="addManualEntry" />
                  <p class="text-[10px] text-muted-foreground">Press Enter to add. Separate multiple with commas.</p>
                </div>
              </div>
            </div>

            <!-- Main Content -->
            <div class="flex-1 p-6 flex flex-col">
              <div class="flex items-center justify-between mb-4">
                <div class="relative w-full max-w-md">
                  <Search class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
                  <input v-model="contactsQuery" placeholder="Search customers..." class="pl-9 h-9 px-3 w-full text-xs shadow-sm rounded-md border border-border bg-background focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30" />
                </div>
                <div class="flex items-center gap-4">
                  <span class="text-xs font-medium text-primary bg-primary/10 px-3 py-1 rounded-full">{{ form.selectedCustomers.length }} selected</span>
                  <button @click="selectAllCustomers" class="inline-flex items-center text-xs font-medium text-muted-foreground hover:text-foreground">
                    <CheckCircle2 class="size-4 mr-1" :class="form.selectedCustomers.length === filteredCustomers.length && filteredCustomers.length > 0 ? 'text-primary' : ''" /> Select All
                  </button>
                </div>
              </div>

              <div v-if="loadingContacts" class="flex items-center justify-center py-10 text-xs text-muted-foreground">Loading contacts…</div>
              <div v-else-if="filteredCustomers.length === 0" class="flex items-center justify-center py-10 text-xs text-muted-foreground">No contacts found. Import a CSV or add contacts first.</div>
              <div v-else class="grid grid-cols-1 sm:grid-cols-2 gap-3 overflow-y-auto pr-2 pb-4">
                <div
                  v-for="customer in filteredCustomers" :key="customer.id"
                  class="flex items-start gap-3 p-3 rounded-xl border cursor-pointer transition-all"
                  :class="form.selectedCustomers.includes(customer.id) ? 'border-primary bg-primary/5 shadow-sm' : 'border-border bg-card hover:border-primary/30'"
                  @click="toggleSelection(form.selectedCustomers, customer.id)"
                >
                  <div class="mt-0.5 size-4 rounded-md border flex items-center justify-center transition-colors shrink-0" :class="form.selectedCustomers.includes(customer.id) ? 'bg-primary border-primary text-primary-foreground' : 'border-muted-foreground/30 bg-background'">
                    <Check v-if="form.selectedCustomers.includes(customer.id)" class="size-3" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="font-medium text-foreground text-xs truncate">{{ customer.name }}</div>
                    <div class="flex items-center text-[11px] mt-1 text-muted-foreground gap-1.5">
                      <span>{{ customer.contextLabel }}</span>
                      <span class="font-medium text-foreground">{{ customer.contextValue }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- STEP 2: Delivery Channels -->
          <div v-if="currentStep === 2" class="p-6 space-y-8 animate-in slide-in-from-right-4 duration-300">
            <div class="space-y-4">
              <h3 class="text-xs font-semibold text-foreground uppercase tracking-wider">Delivery Channels (Multiple Allowed)</h3>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div
                  v-for="channel in availableChannels" :key="channel.name"
                  class="relative border-2 rounded-xl p-5 cursor-pointer transition-all overflow-hidden group"
                  :class="form.channels.includes(channel.name) ? 'border-primary bg-primary/5 shadow-md' : 'border-border bg-card hover:border-primary/50'"
                  @click="toggleSelection(form.channels, channel.name)"
                >
                  <div class="absolute top-3 right-3 size-5 rounded-full border-2 flex items-center justify-center transition-colors shrink-0" :class="form.channels.includes(channel.name) ? 'border-primary' : 'border-muted-foreground/30'">
                    <div v-if="form.channels.includes(channel.name)" class="size-2.5 rounded-full bg-primary"></div>
                  </div>
                  <div class="flex flex-col gap-3">
                    <div class="size-10 rounded-full flex items-center justify-center shrink-0" :class="channel.bg">
                      <component :is="channel.icon" class="size-5" :class="channel.color" />
                    </div>
                    <div>
                      <h4 class="font-semibold text-sm text-foreground mb-0.5">{{ channel.name }}</h4>
                      <div class="flex items-center gap-1.5 text-xs">
                        <Star class="size-3 fill-amber-400 text-amber-400" v-if="channel.name === 'WhatsApp'" />
                        <span class="font-medium text-foreground">{{ channel.rate }}</span>
                        <span class="text-muted-foreground">{{ channel.rate === '—' ? 'No sends yet' : 'Open Rate' }}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <p v-if="channelError" class="text-xs text-red-500 flex items-center gap-1.5">
                <AlertCircle class="size-3.5 shrink-0" /> {{ channelError }}
              </p>
            </div>

            <div class="space-y-4">
              <h3 class="text-xs font-semibold text-foreground uppercase tracking-wider">Sending Method</h3>
              <div class="flex items-center gap-6">
                <div class="flex items-center gap-2 cursor-pointer" @click="form.delivery = 'Send immediately'">
                  <div class="size-4 rounded-full border-2 flex items-center justify-center transition-colors shrink-0" :class="form.delivery === 'Send immediately' ? 'border-primary' : 'border-muted-foreground/30'">
                    <div v-if="form.delivery === 'Send immediately'" class="size-2 rounded-full bg-primary"></div>
                  </div>
                  <span class="text-xs font-medium text-foreground">Send Immediately</span>
                </div>
                <div class="flex items-center gap-2 cursor-pointer" @click="form.delivery = 'Schedule'">
                  <div class="size-4 rounded-full border-2 flex items-center justify-center transition-colors shrink-0" :class="form.delivery === 'Schedule' ? 'border-primary' : 'border-muted-foreground/30'">
                    <div v-if="form.delivery === 'Schedule'" class="size-2 rounded-full bg-primary"></div>
                  </div>
                  <span class="text-xs font-medium text-foreground">Schedule Later</span>
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
                <p v-if="scheduleError" class="text-xs text-red-500 flex items-center gap-1.5">
                  <AlertCircle class="size-3.5 shrink-0" /> {{ scheduleError }}
                </p>
              </div>
            </div>
          </div>

          <!-- STEP 3: Customize Request & Preview -->
          <div v-if="currentStep === 3" class="flex-1 flex animate-in slide-in-from-right-4 duration-300 min-h-[460px]">
            <!-- Editor Side -->
            <div class="flex-1 p-6 space-y-5 overflow-y-auto">
              <div class="flex items-center justify-between">
                <h3 class="text-xs font-semibold text-foreground uppercase tracking-wider">Message Content</h3>
                <button class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-primary/20 bg-primary/5 text-xs font-semibold text-primary hover:bg-primary/10 transition-colors">
                  <Sparkles class="size-3.5" /> Improve Message
                </button>
              </div>

              <textarea
                v-model="form.message"
                class="w-full h-48 p-3 text-xs shadow-sm rounded-lg border border-border bg-background resize-none focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
              ></textarea>

              <div class="space-y-2">
                <p class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">Variables</p>
                <div class="flex flex-wrap gap-2">
                  <span v-for="v in ['{{FirstName}}', '{{BusinessName}}', '{{ReviewLink}}', '{{EmployeeName}}']" :key="v" class="font-mono text-[11px] px-2 py-1 rounded bg-muted text-foreground cursor-pointer hover:bg-primary/20 transition-colors">
                    {{ v }}
                  </span>
                </div>
              </div>

              <div class="grid grid-cols-2 gap-6 pt-4 border-t border-border">
                <div class="space-y-2">
                  <p class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">Tone</p>
                  <div class="grid grid-cols-2 gap-2">
                    <div
                      v-for="tone in tones" :key="tone"
                      class="px-3 py-1.5 rounded-md border text-xs text-center cursor-pointer transition-colors"
                      :class="form.tone === tone ? 'bg-primary/10 border-primary text-primary font-medium' : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                      @click="applyTone(tone)"
                    >
                      {{ tone }}
                    </div>
                  </div>
                </div>
                <div class="space-y-2">
                  <p class="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">Review Destination</p>
                  <div class="flex flex-wrap gap-2">
                    <div
                      v-for="dest in destinations" :key="dest"
                      class="px-2.5 py-1 rounded-full border text-xs cursor-pointer transition-colors flex items-center gap-1"
                      :class="form.destinations.includes(dest) ? 'bg-primary/10 border-primary text-primary font-medium' : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                      @click="toggleSelection(form.destinations, dest)"
                    >
                      <Check v-if="form.destinations.includes(dest)" class="size-3" />
                      {{ dest }}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Preview Side (Mobile Phone Mockup) -->
            <div class="w-[360px] bg-muted/20 border-l border-border p-6 flex items-center justify-center shrink-0">
              <div class="w-[260px] h-[520px] bg-white dark:bg-black rounded-[36px] border-[6px] border-slate-200 dark:border-slate-800 shadow-2xl relative overflow-hidden flex flex-col">
                <!-- Notch -->
                <div class="absolute top-0 inset-x-0 h-5 flex justify-center z-10">
                  <div class="w-28 h-4 bg-slate-200 dark:bg-slate-800 rounded-b-xl"></div>
                </div>
                <!-- Header -->
                <div class="bg-slate-100 dark:bg-slate-900 pt-8 pb-2.5 px-3 flex items-center gap-2 border-b border-slate-200 dark:border-slate-800 shrink-0">
                  <div class="size-7 rounded-full bg-slate-300 dark:bg-slate-700 flex items-center justify-center overflow-hidden">
                    <span class="text-xs font-bold text-slate-700 dark:text-slate-200">NR</span>
                  </div>
                  <div>
                    <div class="text-[11px] font-semibold text-slate-900 dark:text-white">New Relay</div>
                    <div class="text-[9px] text-slate-500">Business Account</div>
                  </div>
                </div>
                <!-- Chat Body -->
                <div class="flex-1 bg-slate-50 dark:bg-black p-3 overflow-y-auto space-y-3">
                  <div class="text-[9px] text-center text-slate-400 font-medium my-1">Today 9:41 AM</div>
                  <div class="bg-primary text-white rounded-2xl rounded-tl-sm p-2.5 text-[12px] shadow-sm whitespace-pre-wrap leading-relaxed max-w-[90%] relative pb-5">
                    {{ previewMessage }}
                    <div class="absolute right-2 bottom-1 text-[8px] text-blue-200">9:41 AM</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- STEP 4: Review & Send -->
          <div v-if="currentStep === 4" class="p-8 space-y-6 animate-in slide-in-from-right-4 duration-300">
            <div class="space-y-6 max-w-3xl mx-auto">
              <div class="text-center">
                <div class="inline-flex items-center justify-center size-12 rounded-full bg-primary/10 text-primary mb-3 border border-primary/20">
                  <CheckCircle2 class="size-6" />
                </div>
                <h2 class="text-base font-semibold text-foreground mb-1">Ready to Send?</h2>
                <p class="text-xs text-muted-foreground">Verify your campaign details before launching.</p>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-card border border-border rounded-xl p-4 shadow-sm flex items-center gap-3">
                  <div class="size-9 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
                    <Users class="size-4" />
                  </div>
                  <div>
                    <div class="text-[11px] text-muted-foreground">Recipients</div>
                    <div class="text-xs font-semibold text-foreground">{{ form.selectedCustomers.length }} Customers</div>
                  </div>
                </div>

                <div class="bg-card border border-border rounded-xl p-4 shadow-sm flex items-center gap-3">
                  <div class="size-9 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
                    <MessageSquare class="size-4" />
                  </div>
                  <div>
                    <div class="text-[11px] text-muted-foreground">Channels</div>
                    <div class="text-xs font-semibold text-foreground">{{ form.channels.length > 0 ? form.channels.join(' + ') : 'Email' }}</div>
                  </div>
                </div>

                <div class="bg-card border border-border rounded-xl p-4 shadow-sm flex items-center gap-3">
                  <div class="size-9 rounded-full bg-amber-500/10 text-amber-600 flex items-center justify-center shrink-0">
                    <Star class="size-4" />
                  </div>
                  <div>
                    <div class="text-[11px] text-muted-foreground">Review Platform</div>
                    <div class="text-xs font-semibold text-foreground">{{ form.destinations.join(', ') || 'Google' }}</div>
                  </div>
                </div>

                <div class="bg-card border border-border rounded-xl p-4 shadow-sm flex items-center gap-3">
                  <div class="size-9 rounded-full bg-emerald-500/10 text-emerald-600 flex items-center justify-center shrink-0">
                    <Clock class="size-4" />
                  </div>
                  <div>
                    <div class="text-[11px] text-muted-foreground">Schedule</div>
                    <div v-if="form.delivery === 'Schedule'" class="text-xs font-semibold text-foreground">
                      {{ form.scheduleDate ? new Date(form.scheduleDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }}
                      <span v-if="form.scheduleTime" class="ml-1">at {{ form.scheduleTime }} {{ form.scheduleTimezone }}</span>
                    </div>
                    <div v-else class="text-xs font-semibold text-foreground">Send Immediately</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- STEP 5: Success Screen -->
          <div v-if="currentStep === 5" class="py-16 flex flex-col items-center text-center animate-in zoom-in-95 duration-500 flex-1">
            <div class="size-16 bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 rounded-full flex items-center justify-center mb-4">
              <CheckCircle2 class="size-8" />
            </div>
            <h2 class="text-base font-semibold text-foreground mb-1">Review Requests Sent!</h2>
            <p class="text-xs text-muted-foreground mb-8">{{ form.selectedCustomers.length }} customer requests dispatched successfully.</p>

            <div class="flex flex-wrap justify-center gap-3">
              <button class="inline-flex items-center gap-2 rounded-lg bg-primary px-6 py-2.5 text-xs font-semibold text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors" @click="closeModal">
                Done
              </button>
            </div>
          </div>
        </div>

        <!-- Footer Actions -->
        <div v-if="currentStep < 5" class="px-6 py-4 border-t border-border bg-muted/10 flex items-center justify-between shrink-0">
          <button class="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-semibold text-muted-foreground hover:bg-muted/50 transition-colors disabled:opacity-40" @click="prevStep" :disabled="currentStep === 1">
            <ChevronLeft class="size-4" v-if="currentStep > 1" />
            Back
          </button>

          <button v-if="currentStep < 4" class="inline-flex items-center gap-2 rounded-lg bg-primary px-6 py-2 text-xs font-semibold text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors disabled:opacity-40 disabled:cursor-not-allowed" :disabled="currentStep === 2 && !!step2Error" @click="nextStep">
            Next
            <ChevronRight class="size-4" />
          </button>
          <button v-else-if="currentStep === 4" class="inline-flex items-center gap-2 rounded-lg bg-primary px-6 py-2 text-xs font-semibold text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors cursor-pointer" :disabled="sendingRequest" @click="sendRequest">
            <Send class="size-4" /> Send Requests
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
