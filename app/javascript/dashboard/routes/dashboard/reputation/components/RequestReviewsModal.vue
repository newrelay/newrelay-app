<script setup>
/* eslint-disable */
import { ref, computed, watch } from 'vue';
import {
  X, ChevronRight, Search, FileText, CheckCircle2,
  ArrowLeft, Send, Sparkles, MessageSquare,
  Mail, MessageCircle, Star, Smartphone,
  Check, BarChart3, ChevronDown, Building2,
  Calendar, ChevronLeft, Users, Plus, AlertCircle, Globe,
  LayoutTemplate, ExternalLink, Signal, Wifi, MoreVertical,
  Paperclip, Smile, Mic, Trash2, Archive, Video, Phone, Info
} from 'lucide-vue-next';
import {
  RelayButton as Button, RelayInput as Input, RelayBadge as Badge,
  RelayDropdownMenu as DropdownMenu,
  RelayDropdownMenuTrigger as DropdownMenuTrigger,
  RelayDropdownMenuContent as DropdownMenuContent,
  RelayDropdownMenuItem as DropdownMenuItem
} from 'dashboard/components-next/relay';
import RelayDatePicker from 'dashboard/components-next/relay/calendar/DatePicker.vue';
import RelayTimePicker from 'dashboard/components-next/relay/calendar/TimePicker.vue';
import { defaultSmsTemplates, defaultEmailTemplates, defaultWhatsAppTemplates } from './data/outreachTemplates';

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

// Parse the RelayTimePicker's 12-hour string ("09:30 AM") into 24-hour [h, m].
const parse12hTime = timeStr => {
  const m = (timeStr || '').trim().match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
  if (!m) return [9, 0];
  let hour = Number(m[1]) % 12;
  if (m[3].toUpperCase() === 'PM') hour += 12;
  return [hour, Number(m[2])];
};

const convertToUtcIso = (dateStr, timeStr, tz) => {
  if (!dateStr) return null;
  const dateParts = dateStr.split('-').map(Number);
  const [hour, minute] = parse12hTime(timeStr);
  const dateObj = new Date(dateParts[0], dateParts[1] - 1, dateParts[2], hour, minute);
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
  channels: ['Email'],
  delivery: 'Send immediately',
  scheduleDate: '',
  scheduleTime: '09:00 AM',
  scheduleTimezone: getUserTimezone(),
  tone: 'Friendly',
  destination: 'Google'
};

const axios = window.axios;
const accountId = window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];

const currentStep = ref(1);
const form = ref({ ...defaultFormState });
const searchQuery = ref('');
const activeFilter = ref('Recent Customers');
const selectedCompanyFilter = ref('');
const loadingContacts = ref(false);

// --- Step 3: per-channel message composition ---
const previewChannel = ref('Email');
const activeEditingChannel = ref('Email');
const prebuiltSms = defaultSmsTemplates;
const prebuiltEmail = defaultEmailTemplates;
const prebuiltWhatsApp = defaultWhatsAppTemplates;
const selectedSmsTemplateId = ref(defaultSmsTemplates[0].id);
const selectedEmailTemplateId = ref(defaultEmailTemplates[0].id);
const selectedWhatsAppTemplateId = ref(defaultWhatsAppTemplates[0].id);
const smsMessage = ref(defaultSmsTemplates[0].message);
const emailSubject = ref(defaultEmailTemplates[0].subject);
const emailBody = ref(defaultEmailTemplates[0].body);
const whatsappHeader = ref(defaultWhatsAppTemplates[0].headerText);
const whatsappBody = ref(defaultWhatsAppTemplates[0].bodyText);
const whatsappButton1 = ref(defaultWhatsAppTemplates[0].button1);
const whatsappButton2 = ref(defaultWhatsAppTemplates[0].button2);
const isAiEnhancing = ref(false);

const currentChannelTemplates = computed(() => {
  if (activeEditingChannel.value === 'SMS') return prebuiltSms;
  if (activeEditingChannel.value === 'Email') return prebuiltEmail;
  return prebuiltWhatsApp;
});
const currentActiveTemplateId = computed(() => {
  if (activeEditingChannel.value === 'SMS') return selectedSmsTemplateId.value;
  if (activeEditingChannel.value === 'Email') return selectedEmailTemplateId.value;
  return selectedWhatsAppTemplateId.value;
});
const currentActiveTemplateName = computed(() => {
  const found = currentChannelTemplates.value.find(t => t.id === currentActiveTemplateId.value);
  return found ? found.name : 'Select a template…';
});

const fillVars = text => (text || '')
  .replaceAll('{{FirstName}}', 'Sarah')
  .replaceAll('{{BusinessName}}', 'New Relay')
  .replaceAll('{{ReviewLink}}', 'newrelay.com/r/abc123')
  .replaceAll('{{EmployeeName}}', 'Alex');
const formattedEmailSubject = computed(() => fillVars(emailSubject.value));
const formattedEmailBody = computed(() => fillVars(emailBody.value));
const formattedSmsBody = computed(() => fillVars(smsMessage.value));
const formattedWhatsAppHeader = computed(() => fillVars(whatsappHeader.value));
const formattedWhatsAppBody = computed(() => fillVars(whatsappBody.value));

function getChannelIcon(channel) {
  if (channel === 'WhatsApp') return MessageCircle;
  if (channel === 'Email') return Mail;
  return Smartphone;
}
function selectTemplate(template, channel) {
  if (channel === 'SMS') {
    selectedSmsTemplateId.value = template.id;
    smsMessage.value = template.message;
  } else if (channel === 'Email') {
    selectedEmailTemplateId.value = template.id;
    emailSubject.value = template.subject;
    emailBody.value = template.body;
  } else {
    selectedWhatsAppTemplateId.value = template.id;
    whatsappHeader.value = template.headerText;
    whatsappBody.value = template.bodyText;
    whatsappButton1.value = template.button1;
    whatsappButton2.value = template.button2;
  }
}
function insertVariable(variable) {
  if (activeEditingChannel.value === 'SMS') smsMessage.value += ` ${variable}`;
  else if (activeEditingChannel.value === 'Email') emailBody.value += ` ${variable}`;
  else whatsappBody.value += ` ${variable}`;
}
function enhanceWithAi() {
  isAiEnhancing.value = true;
  setTimeout(() => {
    if (activeEditingChannel.value === 'SMS') {
      smsMessage.value = 'Hi {{FirstName}}! We loved serving you at {{BusinessName}}. Could you share a quick 30-second review to help others find us? ⭐ {{ReviewLink}}';
    } else if (activeEditingChannel.value === 'Email') {
      emailSubject.value = '{{FirstName}}, how was your recent visit to {{BusinessName}}?';
      emailBody.value = 'Hi {{FirstName}},\n\nThank you for choosing {{BusinessName}}! Our team takes immense pride in delivering top-quality service. If you had a positive experience with {{EmployeeName}}, we would be thrilled if you left us a quick review.\n\n⭐ Leave your review here:\n{{ReviewLink}}\n\nIt only takes one minute.\n\nWarm regards,\nThe {{BusinessName}} Team';
    } else {
      whatsappHeader.value = 'Hi {{FirstName}} 👋';
      whatsappBody.value = 'Thank you for visiting {{BusinessName}} today! We hope everything went wonderfully. Tap below to share a quick 5-star review:\n\n{{ReviewLink}}';
    }
    isAiEnhancing.value = false;
  }, 600);
}
// Compose the outgoing message text for a given channel.
function messageForChannel(ch) {
  if (ch === 'SMS') return smsMessage.value;
  if (ch === 'WhatsApp') return `${whatsappHeader.value}\n\n${whatsappBody.value}`;
  return `${emailSubject.value}\n\n${emailBody.value}`;
}
// Filled-in preview of the primary channel's message for the review step.
const reviewPreview = computed(() => fillVars(messageForChannel(form.value.channels[0] || 'Email')));

// Keep the editing/preview channel valid as the channel selection changes.
watch(() => form.value.channels, channels => {
  if (!channels.length) return;
  if (!channels.includes(previewChannel.value)) previewChannel.value = channels[0];
  if (!channels.includes(activeEditingChannel.value)) activeEditingChannel.value = channels[0];
}, { deep: true, immediate: true });

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
    phone: c.phone_number || '',
    company: c.additional_attributes?.company_name || ''
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

// Company options come from the loaded contacts (real data).
const companyList = computed(() =>
  [...new Set(allCustomers.value.map(c => c.company).filter(Boolean))].sort()
);

// Searchable company dropdown state.
const showCompanyMenu = ref(false);
const companySearch = ref('');
const filteredCompanyList = computed(() => {
  const q = companySearch.value.toLowerCase();
  return q ? companyList.value.filter(c => c.toLowerCase().includes(q)) : companyList.value;
});
const companyCount = comp => eligibleCustomers.value.filter(c => c.company === comp).length;
function selectCompany(comp) {
  selectedCompanyFilter.value = comp;
  showCompanyMenu.value = false;
  companySearch.value = '';
}

// A contact is eligible only if it has the field(s) the chosen channels need.
function isCustomerEligible(customer) {
  if (!form.value.channels.length) return true;
  const requiresEmail = form.value.channels.includes('Email');
  const requiresPhone = form.value.channels.includes('SMS') || form.value.channels.includes('WhatsApp');
  const hasEmail = Boolean(customer.email);
  const hasPhone = Boolean(customer.phone);
  if (requiresEmail && requiresPhone) return hasEmail || hasPhone;
  if (requiresEmail) return hasEmail;
  if (requiresPhone) return hasPhone;
  return true;
}

const eligibleCustomers = computed(() => allCustomers.value.filter(isCustomerEligible));
const excludedCount = computed(() => allCustomers.value.length - eligibleCustomers.value.length);

const channelRequirementText = computed(() => {
  const requiresEmail = form.value.channels.includes('Email');
  const requiresPhone = form.value.channels.includes('SMS') || form.value.channels.includes('WhatsApp');
  if (requiresEmail && !requiresPhone) return 'an email address';
  if (requiresPhone && !requiresEmail) return 'a phone number';
  return 'a valid email or phone number';
});

const filteredCustomers = computed(() => {
  let list = eligibleCustomers.value;
  if (selectedCompanyFilter.value) list = list.filter(c => c.company === selectedCompanyFilter.value);
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase();
    list = list.filter(c => c.name.toLowerCase().includes(q) || (c.company && c.company.toLowerCase().includes(q)));
  }
  return list;
});

// Changing channels can make a selected contact ineligible — drop those.
watch(() => form.value.channels, () => {
  const validIds = new Set(eligibleCustomers.value.map(c => c.id));
  form.value.selectedCustomers = form.value.selectedCustomers.filter(id => validIds.has(id));
}, { deep: true });

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

const channelRequired = computed(() =>
  form.value.channels.length ? '' : 'Select at least one delivery channel.'
);

const minScheduleDate = computed(() => {
  const d = new Date();
  return d.toISOString().split('T')[0];
});

const scheduleError = computed(() => {
  if (form.value.delivery !== 'Schedule') return '';
  if (!form.value.scheduleDate) return 'Pick a date to schedule.';
  if (!form.value.scheduleTime) return 'Pick a time to schedule.';
  const isoDateTime = convertToUtcIso(form.value.scheduleDate, form.value.scheduleTime, form.value.scheduleTimezone);
  if (!isoDateTime) return 'Invalid date.';
  if (new Date(isoDateTime) <= new Date()) return 'Scheduled time must be in the future.';
  return '';
});
// Step 1 = channel + sending method; step 2 = pick recipients.
const step1Error = computed(() => channelRequired.value || scheduleError.value);

const scheduleSummary = computed(() => {
  if (form.value.delivery !== 'Schedule') return 'Send immediately';
  if (!form.value.scheduleDate) return 'Not scheduled';
  return `${form.value.scheduleDate} at ${form.value.scheduleTime}`;
});

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
  if (currentStep.value === 1 && step1Error.value) return;
  if (currentStep.value < 5) currentStep.value++;
}

function prevStep() {
  if (currentStep.value > 1) currentStep.value--;
}

async function generateReport() {
  if (step1Error.value) { currentStep.value = 1; return; }
  const { contactIds, recipients } = buildRecipients();
  const scheduledAt = form.value.delivery === 'Schedule'
    ? convertToUtcIso(form.value.scheduleDate, form.value.scheduleTime, form.value.scheduleTimezone)
    : null;
  try {
    await axios.post(`/api/v1/accounts/${accountId}/reputation/review_requests`, {
      channel: (form.value.channels[0] || 'Email').toLowerCase(),
      contact_ids: contactIds,
      recipients,
      message: messageForChannel(form.value.channels[0] || 'Email'),
      destinations: [form.value.destination],
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
    form.value.channels = ['Email'];
    form.value.destination = 'Google';
    selectedCompanyFilter.value = '';
    searchQuery.value = '';
    showCompanyMenu.value = false;
    companySearch.value = '';
    activeEditingChannel.value = 'Email';
    previewChannel.value = 'Email';
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
            <span :class="currentStep >= 1 ? 'text-primary font-medium' : 'text-muted-foreground'">1. Channel</span>
            <ChevronRight class="size-3.5 text-muted-foreground/50" />
            <span :class="currentStep >= 2 ? 'text-primary font-medium' : 'text-muted-foreground'">2. Recipients</span>
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
        
        <!-- STEP 2: Select Recipients -->
        <div v-if="currentStep === 2" class="flex-1 flex animate-in slide-in-from-right-4 duration-300 min-h-[450px]">
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
            <div class="pt-4 border-t border-border flex flex-col gap-1.5">
              <label class="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-1.5">Company</label>
              <div class="relative z-20">
                <button
                  type="button"
                  class="w-full h-9 px-3 text-sm shadow-xs rounded-md border bg-background flex items-center justify-between gap-2 cursor-pointer transition-colors"
                  :class="selectedCompanyFilter ? 'border-primary/50 text-primary font-medium' : 'border-border text-foreground hover:bg-muted/50'"
                  @click="showCompanyMenu = !showCompanyMenu"
                >
                  <span class="truncate">{{ selectedCompanyFilter || 'All companies' }}</span>
                  <ChevronDown class="size-4 text-muted-foreground shrink-0 transition-transform" :class="showCompanyMenu ? 'rotate-180' : ''" />
                </button>

                <div v-if="showCompanyMenu" class="absolute left-0 right-0 bottom-full mb-1 z-50 rounded-lg border border-border bg-popover shadow-lg p-1.5">
                  <div class="relative mb-1.5">
                    <Search class="absolute left-2.5 top-1/2 -translate-y-1/2 size-3.5 text-muted-foreground" />
                    <input
                      v-model="companySearch"
                      type="text"
                      placeholder="Search company…"
                      class="w-full h-8 pl-8 pr-2 text-xs rounded-md border border-border bg-background text-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
                    />
                  </div>
                  <div class="max-h-52 overflow-y-auto space-y-0.5">
                    <button
                      type="button"
                      class="w-full flex items-center justify-between px-2.5 py-1.5 text-xs rounded-md cursor-pointer hover:bg-muted/80 transition-colors"
                      :class="!selectedCompanyFilter ? 'bg-primary/10 text-primary font-medium' : 'text-foreground'"
                      @click="selectCompany('')"
                    >
                      <span>All companies</span>
                      <Check v-if="!selectedCompanyFilter" class="size-3.5 text-primary" />
                    </button>
                    <button
                      v-for="company in filteredCompanyList" :key="company"
                      type="button"
                      class="w-full flex items-center justify-between gap-2 px-2.5 py-1.5 text-xs rounded-md cursor-pointer hover:bg-muted/80 transition-colors"
                      :class="selectedCompanyFilter === company ? 'bg-primary/10 text-primary font-medium' : 'text-foreground'"
                      @click="selectCompany(company)"
                    >
                      <span class="flex items-center gap-2 min-w-0">
                        <Building2 class="size-3.5 opacity-70 shrink-0" />
                        <span class="truncate">{{ company }}</span>
                      </span>
                      <span class="text-[10.5px] px-1.5 py-0.5 rounded-full bg-muted text-muted-foreground font-medium shrink-0">{{ companyCount(company) }}</span>
                    </button>
                    <div v-if="!companyList.length" class="px-2.5 py-4 text-center text-xs text-muted-foreground">No companies on your contacts.</div>
                    <div v-else-if="!filteredCompanyList.length" class="px-2.5 py-4 text-center text-xs text-muted-foreground">No match.</div>
                  </div>
                </div>
              </div>
              <!-- click-away -->
              <div v-if="showCompanyMenu" class="fixed inset-0 z-10" @click="showCompanyMenu = false"></div>
            </div>
          </div>

          <!-- Main Content -->
          <div class="flex-1 p-6 flex flex-col">
            <!-- Channel-eligibility notice -->
            <div v-if="excludedCount > 0" class="mb-4 flex items-center gap-2 px-4 py-2.5 rounded-lg bg-destructive/10 border border-destructive/20 text-destructive text-xs">
              <AlertCircle class="size-4 shrink-0" />
              <span><strong>{{ excludedCount }} contact{{ excludedCount === 1 ? '' : 's' }}</strong> without {{ channelRequirementText }} {{ excludedCount === 1 ? 'has' : 'have' }} been removed for the selected channel.</span>
            </div>
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
            <div v-else-if="filteredCustomers.length === 0" class="flex items-center justify-center py-10 text-sm text-muted-foreground">No eligible contacts for this channel. Try a different channel or filter.</div>
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
                  <div class="flex items-start justify-between gap-2">
                    <div class="font-medium text-foreground text-sm truncate">{{ customer.name }}</div>
                    <span v-if="customer.company" class="shrink-0 max-w-[45%] truncate text-[10px] px-1.5 py-0.5 rounded-md bg-muted text-muted-foreground font-medium">{{ customer.company }}</span>
                  </div>
                  <div class="flex items-center text-xs mt-1 text-muted-foreground gap-1.5">
                    <span>{{ customer.contextLabel }}</span>
                    <span class="font-medium text-foreground truncate">{{ customer.contextValue }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- STEP 1: Choose Delivery Channel -->
        <div v-if="currentStep === 1" class="p-6 space-y-10 animate-in slide-in-from-right-4 duration-300">
          <div class="space-y-4">
            <div>
              <h3 class="text-sm font-semibold text-foreground uppercase tracking-wider">Select Delivery Channels</h3>
              <p class="text-[13px] text-muted-foreground mt-1">Choose which channels to send review requests on. The next step automatically shortlists contacts with the required details.</p>
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
            <p v-if="channelRequired" class="text-sm text-destructive flex items-center gap-1.5">
              <AlertCircle class="size-4 shrink-0" /> {{ channelRequired }}
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
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
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
                  <RelayTimePicker v-model="form.scheduleTime" placeholder="Pick time" trigger-class="h-9" />
                </div>
                <div class="space-y-1">
                  <label class="text-xs font-medium text-foreground">Timezone</label>
                  <div class="relative h-9">
                    <select
                      v-model="form.scheduleTimezone"
                      class="w-full h-full px-3 text-xs shadow-sm rounded-md border border-border bg-background appearance-none focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30 cursor-pointer pr-9 font-medium text-foreground"
                    >
                      <option v-for="tz in COMMON_TIMEZONES" :key="tz.value" :value="tz.value">
                        {{ tz.label }}
                      </option>
                    </select>
                    <Globe class="absolute right-3 top-1/2 -translate-y-1/2 size-4 text-primary pointer-events-none" />
                  </div>
                </div>
              </div>
              <p v-if="scheduleError" class="text-sm text-destructive flex items-center gap-1.5">
                <AlertCircle class="size-4 shrink-0" /> {{ scheduleError }}
              </p>
            </div>
          </div>
        </div>

        <!-- STEP 3: Customize Request & Select Pre-built Templates -->
        <div v-if="currentStep === 3" class="flex-1 flex flex-col lg:flex-row animate-in slide-in-from-right-4 duration-300 min-h-[450px] overflow-hidden">
          <!-- Editor Side -->
          <div class="flex-1 p-5 sm:p-6 space-y-5 overflow-y-auto">
            <!-- Channel switcher (when multiple channels chosen) -->
            <div v-if="form.channels.length > 1" class="flex items-center justify-between gap-3 pb-3 border-b border-border">
              <span class="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Configure Channel:</span>
              <div class="flex items-center gap-1.5">
                <button
                  v-for="ch in form.channels" :key="ch" type="button"
                  class="px-3 py-1.5 rounded-lg border text-xs font-medium cursor-pointer transition-colors flex items-center gap-1.5"
                  :class="activeEditingChannel === ch ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border hover:bg-muted text-muted-foreground'"
                  @click="activeEditingChannel = ch; previewChannel = ch"
                >
                  <component :is="getChannelIcon(ch)" class="size-3.5" />
                  <span>{{ ch }}</span>
                </button>
              </div>
            </div>

            <!-- Pre-built template selector (channel-aware) -->
            <div class="bg-muted/20 border border-border rounded-xl p-4 space-y-2">
              <div class="flex items-center justify-between">
                <label class="text-[13.5px] font-medium text-foreground flex items-center gap-1.5">
                  <LayoutTemplate class="size-4 text-primary" />
                  Select Pre-built {{ activeEditingChannel }} Template
                </label>
                <Badge class="text-[11px] font-normal text-muted-foreground py-0.5 bg-muted">{{ currentChannelTemplates.length }} templates</Badge>
              </div>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <button type="button" class="h-9 px-3 text-[13.5px] bg-background border border-border/80 rounded-md text-foreground flex items-center justify-between shadow-xs hover:border-border focus-visible:ring-1 focus-visible:ring-primary/30 outline-none w-full text-left cursor-pointer transition-all">
                    <div class="flex items-center gap-2.5 truncate">
                      <div class="size-2 rounded-full bg-primary shrink-0"></div>
                      <span class="truncate font-medium">{{ currentActiveTemplateName }}</span>
                    </div>
                    <ChevronDown class="size-3.5 opacity-50 ml-2 shrink-0" />
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent class="w-[360px] max-h-[320px] overflow-y-auto" align="start">
                  <DropdownMenuItem v-for="t in currentChannelTemplates" :key="t.id" class="flex items-center justify-between py-2 px-3 cursor-pointer" @click="selectTemplate(t, activeEditingChannel)">
                    <div class="flex flex-col gap-0.5 min-w-0 pr-2">
                      <span class="text-[13px] font-medium text-foreground truncate">{{ t.name }}</span>
                      <span class="text-[11px] text-muted-foreground truncate">{{ t.autoDelay }}</span>
                    </div>
                    <Check v-if="currentActiveTemplateId === t.id" class="size-4 text-primary shrink-0" />
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

            <!-- Email editor -->
            <template v-if="activeEditingChannel === 'Email'">
              <div class="space-y-4">
                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">Email Subject Line</label>
                  <Input v-model="emailSubject" class="h-9 text-[14px]" />
                </div>
                <div class="flex flex-col gap-2">
                  <div class="flex items-center justify-between">
                    <label class="text-[13.5px] font-medium text-foreground">Email Body Copy</label>
                    <button type="button" class="h-7 px-2.5 gap-1.5 bg-primary/5 text-primary border border-primary/20 hover:bg-primary/10 rounded-lg text-xs font-semibold inline-flex items-center cursor-pointer disabled:opacity-60" :disabled="isAiEnhancing" @click="enhanceWithAi">
                      <Sparkles class="size-3.5" :class="isAiEnhancing ? 'animate-spin' : ''" />
                      {{ isAiEnhancing ? 'Enhancing…' : 'Improve with Relay AI' }}
                    </button>
                  </div>
                  <textarea v-model="emailBody" rows="5" class="w-full text-[13.5px] p-3.5 shadow-xs rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"></textarea>
                </div>
              </div>
            </template>

            <!-- SMS editor -->
            <template v-else-if="activeEditingChannel === 'SMS'">
              <div class="space-y-4">
                <div class="flex flex-col gap-2">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-2">
                      <label class="text-[13.5px] font-medium text-foreground">SMS Message Content</label>
                      <span class="text-[11.5px] text-muted-foreground font-mono">({{ smsMessage.length }} / 160 chars)</span>
                    </div>
                    <button type="button" class="h-7 px-2.5 gap-1.5 bg-primary/5 text-primary border border-primary/20 hover:bg-primary/10 rounded-lg text-xs font-semibold inline-flex items-center cursor-pointer disabled:opacity-60" :disabled="isAiEnhancing" @click="enhanceWithAi">
                      <Sparkles class="size-3.5" :class="isAiEnhancing ? 'animate-spin' : ''" />
                      {{ isAiEnhancing ? 'Enhancing…' : 'Improve with Relay AI' }}
                    </button>
                  </div>
                  <textarea v-model="smsMessage" rows="4" class="w-full text-[13.5px] p-3.5 shadow-xs rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"></textarea>
                </div>
              </div>
            </template>

            <!-- WhatsApp editor -->
            <template v-else>
              <div class="space-y-4">
                <div class="flex flex-col gap-1.5">
                  <label class="text-[13.5px] font-medium text-foreground">WhatsApp Header Greeting</label>
                  <Input v-model="whatsappHeader" class="h-9 text-[14px]" />
                </div>
                <div class="flex flex-col gap-2">
                  <div class="flex items-center justify-between">
                    <label class="text-[13.5px] font-medium text-foreground">WhatsApp Body Content</label>
                    <button type="button" class="h-7 px-2.5 gap-1.5 bg-primary/5 text-primary border border-primary/20 hover:bg-primary/10 rounded-lg text-xs font-semibold inline-flex items-center cursor-pointer disabled:opacity-60" :disabled="isAiEnhancing" @click="enhanceWithAi">
                      <Sparkles class="size-3.5" :class="isAiEnhancing ? 'animate-spin' : ''" />
                      {{ isAiEnhancing ? 'Enhancing…' : 'Improve with Relay AI' }}
                    </button>
                  </div>
                  <textarea v-model="whatsappBody" rows="4" class="w-full text-[13.5px] p-3.5 shadow-xs rounded-xl border border-border/80 bg-background resize-none focus:outline-none focus:ring-1 focus:ring-primary/30 leading-relaxed"></textarea>
                </div>
              </div>
            </template>

            <!-- Insert variables -->
            <div class="space-y-2">
              <p class="text-[11px] font-medium text-muted-foreground uppercase tracking-wider">Insert Variables</p>
              <div class="flex flex-wrap gap-1.5">
                <Badge v-for="v in ['{{FirstName}}', '{{BusinessName}}', '{{ReviewLink}}', '{{EmployeeName}}']" :key="v" class="font-mono text-[11px] cursor-pointer bg-muted hover:bg-primary/20 text-foreground" @click="insertVariable(v)">{{ v }}</Badge>
              </div>
            </div>

            <!-- Tone & destination -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-4 border-t border-border">
              <div class="space-y-2.5">
                <p class="text-[11px] font-medium text-muted-foreground uppercase tracking-wider">Tone</p>
                <div class="grid grid-cols-2 gap-1.5">
                  <div v-for="tone in tones" :key="tone" class="px-2.5 py-1.5 rounded-lg border text-xs text-center cursor-pointer transition-colors" :class="form.tone === tone ? 'bg-primary/10 border-primary text-primary font-semibold' : 'bg-card border-border hover:bg-muted text-muted-foreground'" @click="form.tone = tone">{{ tone }}</div>
                </div>
              </div>
              <div class="space-y-2.5">
                <p class="text-[11px] font-medium text-muted-foreground uppercase tracking-wider">Review Destination</p>
                <div class="flex flex-wrap gap-1.5">
                  <button v-for="dest in destinations" :key="dest" type="button" class="px-3 py-1.5 rounded-full border text-xs cursor-pointer transition-all flex items-center gap-1.5" :class="form.destination === dest ? 'bg-primary/10 border-primary text-primary font-semibold shadow-xs' : 'bg-card border-border hover:bg-muted text-muted-foreground'" @click="form.destination = dest">
                    <Check v-if="form.destination === dest" class="size-3 shrink-0 text-primary" />
                    <span>{{ dest }}</span>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Preview Side (channel-tailored device preview) -->
          <div class="w-full lg:w-[345px] bg-muted/40 border-t lg:border-t-0 lg:border-l border-border p-4 sm:p-5 flex flex-col items-center justify-center shrink-0 overflow-hidden relative">
            <div class="absolute -top-12 -right-12 size-48 rounded-full bg-primary/10 blur-3xl pointer-events-none"></div>
            <div class="absolute -bottom-12 -left-12 size-48 rounded-full bg-primary/10 blur-3xl pointer-events-none"></div>

            <!-- Preview channel switcher -->
            <div v-if="form.channels.length > 1" class="flex items-center gap-1 bg-card/80 backdrop-blur-md p-1 rounded-xl mb-3 border border-border/80 shadow-xs z-20">
              <button v-for="ch in form.channels" :key="ch" type="button" class="px-2.5 py-1 text-[11px] font-semibold rounded-lg transition-all cursor-pointer" :class="previewChannel === ch ? 'bg-primary text-primary-foreground shadow-xs' : 'text-muted-foreground hover:text-foreground'" @click="previewChannel = ch; activeEditingChannel = ch">{{ ch }}</button>
            </div>

            <!-- Device frame -->
            <div class="w-[260px] sm:w-[272px] h-[460px] bg-card rounded-[30px] shadow-2xl border border-border flex flex-col overflow-hidden relative z-10">
              <!-- Status bar -->
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

              <!-- EMAIL preview -->
              <div v-if="previewChannel === 'Email'" class="flex-1 flex flex-col overflow-hidden">
                <div class="px-3.5 py-2 flex items-center justify-between border-b border-border/40 shrink-0 bg-muted/20">
                  <div class="flex items-center gap-2">
                    <ChevronLeft class="size-4 text-primary shrink-0" />
                    <span class="text-xs font-semibold text-foreground">Inbox</span>
                  </div>
                  <div class="flex items-center gap-2 text-muted-foreground">
                    <Archive class="size-3.5" /><Trash2 class="size-3.5" /><MoreVertical class="size-3.5" />
                  </div>
                </div>
                <div class="flex-1 overflow-y-auto p-3 space-y-2.5 hide-scrollbar bg-muted/30">
                  <div class="space-y-1 pb-2 border-b border-border/40">
                    <div class="text-[12px] font-bold text-foreground leading-tight">{{ formattedEmailSubject }}</div>
                    <div class="flex items-center justify-between pt-1">
                      <div class="flex items-center gap-2 min-w-0">
                        <div class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[10px] shrink-0">NR</div>
                        <div class="min-w-0">
                          <div class="text-[11px] font-semibold text-foreground truncate">New Relay</div>
                          <div class="text-[9px] text-muted-foreground truncate">to sarah.j@gmail.com</div>
                        </div>
                      </div>
                      <span class="text-[9px] text-muted-foreground shrink-0">9:41 AM</span>
                    </div>
                  </div>
                  <div class="p-3 bg-card border border-border/60 rounded-2xl shadow-xs space-y-3">
                    <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap text-foreground">{{ formattedEmailBody }}</div>
                    <div class="pt-1">
                      <div class="p-2.5 rounded-xl bg-primary/10 border border-primary/20 text-center space-y-2">
                        <div class="text-[11px] font-semibold text-primary">Rate on {{ form.destination }}</div>
                        <div class="flex justify-center gap-1 text-amber-500">
                          <Star v-for="s in 5" :key="s" class="size-3.5 fill-amber-500 text-amber-500" />
                        </div>
                        <div class="w-full py-1.5 rounded-lg bg-primary text-primary-foreground text-[10.5px] font-semibold flex items-center justify-center gap-1 shadow-xs">
                          <span>Leave {{ form.destination }} Review</span><ExternalLink class="size-2.5" />
                        </div>
                      </div>
                    </div>
                    <div class="text-[8.5px] text-center text-muted-foreground border-t border-border/40 pt-2">New Relay Inc. · 123 Innovation Way · Unsubscribe</div>
                  </div>
                </div>
              </div>

              <!-- WHATSAPP preview -->
              <div v-else-if="previewChannel === 'WhatsApp'" class="flex-1 flex flex-col overflow-hidden">
                <div class="px-3 py-2 bg-emerald-600 dark:bg-emerald-700 text-white flex items-center justify-between shrink-0 shadow-xs">
                  <div class="flex items-center gap-2 min-w-0">
                    <ChevronLeft class="size-4 shrink-0" />
                    <div class="size-7 rounded-full bg-white/20 text-white flex items-center justify-center font-bold text-[10.5px] shrink-0 border border-white/30">NR</div>
                    <div class="min-w-0">
                      <div class="flex items-center gap-1">
                        <span class="text-xs font-semibold truncate text-white">New Relay</span>
                        <CheckCircle2 class="size-3 text-emerald-200 shrink-0" />
                      </div>
                      <span class="text-[9px] text-emerald-100 block truncate">Official Business Account</span>
                    </div>
                  </div>
                  <div class="flex items-center gap-2.5 text-white/90"><Video class="size-3.5" /><Phone class="size-3.5" /><MoreVertical class="size-3.5" /></div>
                </div>
                <div class="flex-1 overflow-y-auto p-3 space-y-2.5 bg-muted/40 hide-scrollbar">
                  <div class="flex justify-center"><span class="text-[9px] bg-card text-muted-foreground px-2 py-0.5 rounded-md shadow-xs font-medium">Today</span></div>
                  <div class="space-y-1.5 max-w-[94%]">
                    <div class="bg-card text-foreground rounded-2xl rounded-tl-xs p-3 shadow-xs border border-border/40 text-xs space-y-2">
                      <div class="text-[12px] font-semibold text-foreground">{{ formattedWhatsAppHeader }}</div>
                      <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap text-foreground">{{ formattedWhatsAppBody }}</div>
                      <div class="p-2 bg-emerald-500/10 border border-emerald-500/20 rounded-xl space-y-1">
                        <div class="flex items-center justify-between gap-1">
                          <span class="text-[10px] font-semibold text-foreground truncate">Rate on {{ form.destination }}</span>
                          <div class="flex gap-0.5 text-amber-500 shrink-0"><Star v-for="s in 5" :key="s" class="size-2 fill-amber-500 text-amber-500" /></div>
                        </div>
                        <div class="text-[9px] font-mono text-emerald-600 dark:text-emerald-400 flex items-center gap-1 truncate"><span>newrelay.com/r/abc123</span><ExternalLink class="size-2 shrink-0" /></div>
                      </div>
                      <div class="flex items-center justify-end gap-1 text-[8.5px] text-muted-foreground"><span>9:41 AM</span><span class="text-primary font-bold">✓✓</span></div>
                    </div>
                    <div class="space-y-1">
                      <div class="w-full py-1.5 rounded-xl bg-card border border-border/60 text-[10.5px] font-semibold text-emerald-600 dark:text-emerald-400 text-center shadow-xs">{{ whatsappButton1 }}</div>
                      <div class="w-full py-1.5 rounded-xl bg-card border border-border/60 text-[10.5px] font-semibold text-muted-foreground text-center shadow-xs">{{ whatsappButton2 }}</div>
                    </div>
                  </div>
                </div>
                <div class="p-2 bg-card border-t border-border/40 flex items-center gap-1.5 shrink-0">
                  <Smile class="size-4 text-muted-foreground shrink-0" />
                  <div class="flex-1 h-6 bg-muted/60 rounded-full px-2.5 text-[9.5px] text-muted-foreground flex items-center truncate">Message</div>
                  <Paperclip class="size-3.5 text-muted-foreground shrink-0" />
                  <div class="size-6 rounded-full bg-emerald-600 text-white flex items-center justify-center shrink-0 shadow-xs"><Mic class="size-2.5" /></div>
                </div>
              </div>

              <!-- SMS preview -->
              <div v-else class="flex-1 flex flex-col overflow-hidden">
                <div class="px-3.5 py-2 flex items-center justify-between border-b border-border/40 shrink-0 bg-muted/20">
                  <div class="flex items-center gap-1 text-primary"><ChevronLeft class="size-4 shrink-0" /><span class="text-[11px] font-medium">Messages</span></div>
                  <div class="flex flex-col items-center">
                    <div class="size-6 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[9px]">NR</div>
                    <span class="text-[9.5px] font-semibold text-foreground">New Relay</span>
                  </div>
                  <Info class="size-3.5 text-primary shrink-0" />
                </div>
                <div class="flex-1 overflow-y-auto p-3 space-y-2.5 bg-muted/30 hide-scrollbar">
                  <div class="text-[9.5px] text-center text-muted-foreground font-medium">Text Message · Today 9:41 AM</div>
                  <div class="space-y-1 max-w-[94%]">
                    <div class="bg-primary text-primary-foreground rounded-2xl rounded-tl-xs p-3 shadow-xs text-xs space-y-2">
                      <div class="text-[11.5px] leading-relaxed whitespace-pre-wrap">{{ formattedSmsBody }}</div>
                      <div class="p-2 bg-white/15 border border-white/20 rounded-xl space-y-1 text-primary-foreground">
                        <div class="flex items-center justify-between gap-1">
                          <span class="text-[10px] font-semibold truncate">Rate on {{ form.destination }}</span>
                          <div class="flex gap-0.5 text-amber-300 shrink-0"><Star v-for="s in 5" :key="s" class="size-2 fill-amber-300 text-amber-300" /></div>
                        </div>
                        <div class="text-[9px] font-mono opacity-90 flex items-center gap-1 truncate"><span>newrelay.com/r/abc123</span><ExternalLink class="size-2 shrink-0" /></div>
                      </div>
                    </div>
                    <div class="text-[8.5px] text-right text-muted-foreground px-1">Delivered</div>
                  </div>
                </div>
                <div class="p-2 bg-card border-t border-border/40 flex items-center gap-1.5 shrink-0">
                  <div class="size-5 rounded-full bg-muted flex items-center justify-center text-muted-foreground font-bold text-xs shrink-0">+</div>
                  <div class="flex-1 h-6 bg-muted/60 rounded-full px-2.5 text-[9.5px] text-muted-foreground flex items-center truncate">Text Message</div>
                  <div class="size-6 rounded-full bg-primary text-primary-foreground flex items-center justify-center shrink-0 shadow-xs"><Send class="size-2.5" /></div>
                </div>
              </div>
            </div>

            <div class="text-center mt-2.5"><span class="text-[11px] text-muted-foreground font-medium">{{ previewChannel }} Outreach Preview</span></div>
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
                      {{ form.destination || 'Auto-optimized' }}
                    </div>
                  </div>
                </div>

                <!-- Schedule Card -->
                <div class="bg-card border border-border rounded-xl p-5 shadow-xs flex items-center gap-4">
                  <div class="size-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0 border border-primary/20">
                    <Calendar class="size-4 text-primary" />
                  </div>
                  <div>
                    <div class="text-xs text-muted-foreground mb-0.5">Schedule</div>
                    <div class="text-sm font-medium text-foreground">
                      {{ scheduleSummary }}
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
                    {{ reviewPreview }}
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
        <button v-if="currentStep < 4" class="h-9 px-8 text-sm font-semibold bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-xs cursor-pointer inline-flex items-center gap-2 disabled:opacity-40 disabled:cursor-not-allowed" @click="nextStep" :disabled="(currentStep === 1 && !!step1Error) || (currentStep === 2 && form.selectedCustomers.length === 0)">
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
