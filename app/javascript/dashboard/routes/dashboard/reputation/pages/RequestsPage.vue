<!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
<script setup>
/* eslint-disable */
import { ref, computed, onMounted, watch } from 'vue';
import {
  Send,
  Mail,
  MessageCircle,
  Search,
  Check,
  ChevronDown,
  ExternalLink,
  Star,
  AlertTriangle,
  Eye,
  Copy,
  Bot,
  CheckCheck,
  Smartphone,
  X,
  RotateCcw,
  Clock,
  Calendar,
} from 'lucide-vue-next';
import {
  RelayButton as Button,
  RelayInput as Input,
  RelayBadge as Badge,
  RelayDropdownMenu as DropdownMenu,
  RelayDropdownMenuTrigger as DropdownMenuTrigger,
  RelayDropdownMenuContent as DropdownMenuContent,
  RelayDropdownMenuItem as DropdownMenuItem,
} from 'dashboard/components-next/relay';
import { useAlert } from 'dashboard/composables';
import RequestReviewsModal from '../components/RequestReviewsModal.vue';

const axios = window.axios;
const accountId =
  window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];
const baseUrl = () => `/api/v1/accounts/${accountId}/reputation`;

const rawRequests = ref([]);
const loading = ref(true);
const isDemoLoaded = ref(true);
const isRequestModalOpen = ref(false);
const searchQuery = ref('');
const selectedChannel = ref('All Channels');
const selectedStatus = ref('All Statuses');
const selectedTimeframe = ref('Last 30 Days');
const selectedRequest = ref(null);
const resending = ref(false);

const TIMEFRAME_DAYS = {
  'Last 7 Days': 7,
  'Last 30 Days': 30,
  'Last 90 Days': 90,
};

const STATUS_LABEL = {
  scheduled: 'Scheduled',
  sent: 'Sent',
  delivered: 'Delivered',
  clicked: 'Opened',
  completed: 'Completed',
};

function initials(name) {
  const parts = String(name || 'C').trim().split(/\s+/).filter(Boolean);
  return ((parts[0]?.[0] || 'C') + (parts[1]?.[0] || '')).toUpperCase();
}

function formatSentAt(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  const now = new Date();
  const startToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startThat = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const days = Math.round((startToday - startThat) / 86400000);
  const time = d.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' });
  if (days === 0) return `Today, ${time}`;
  if (days === 1) return `Yesterday, ${time}`;
  if (days > 1 && days < 7) return `${days} days ago`;
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
}

function channelLabel(ch) {
  const c = String(ch || 'email').toLowerCase();
  if (c === 'sms') return 'SMS';
  if (c === 'whatsapp') return 'WhatsApp';
  return 'Email';
}

function buildHistory(r, channel) {
  const steps = [];
  if (r.completed_at) {
    steps.push({
      title: 'Review Submitted',
      time: formatSentAt(r.completed_at),
      icon: Star,
      description: 'Customer submitted a review from this invite.',
    });
  }
  if (r.clicked_at) {
    steps.push({
      title: 'Link Clicked',
      time: formatSentAt(r.clicked_at),
      icon: ExternalLink,
      description: 'Review link opened.',
    });
  }
  if (['delivered', 'clicked', 'completed'].includes(r.status)) {
    steps.push({
      title: `${channel} Delivered`,
      time: formatSentAt(r.created_at),
      icon: CheckCheck,
      description: 'Delivery confirmed.',
    });
  }
  if (r.status === 'scheduled') {
    steps.push({
      title: 'Scheduled',
      time: formatSentAt(r.scheduled_at || r.created_at),
      icon: Clock,
      description: 'Invite is queued to send.',
    });
  } else {
    steps.push({
      title: 'Request Dispatched',
      time: formatSentAt(r.created_at),
      icon: Send,
      description: r.reputation_template?.name || 'Manual send',
    });
  }
  return steps;
}

function mapRequest(r) {
  const channel = channelLabel(r.channel);
  const ts = r.status === 'scheduled' && r.scheduled_at ? r.scheduled_at : r.created_at;
  const destList = Array.isArray(r.destinations) ? r.destinations.filter(Boolean) : [];
  return {
    id: r.id,
    displayId: `REQ-${r.id}`,
    customerName: r.contact?.name || 'Customer',
    customerEmail: r.contact?.email || '',
    customerPhone: r.contact?.phone_number || '',
    initials: initials(r.contact?.name || 'Customer'),
    channel,
    channelRaw: String(r.channel || 'email').toLowerCase(),
    status: STATUS_LABEL[r.status] || r.status,
    rawStatus: r.status,
    sentAt: formatSentAt(ts),
    sentAtTs: ts ? new Date(ts).getTime() : 0,
    trigger: r.reputation_template?.name || 'Manual Send',
    destinations: destList,
    destination: destList[0] || '',
    messageBody: r.message || '',
    token: r.token,
    contactId: r.contact?.id,
    history: buildHistory(r, channel),
  };
}

async function loadData() {
  loading.value = true;
  try {
    const { data } = await axios.get(`${baseUrl()}/review_requests`);
    rawRequests.value = Array.isArray(data) ? data : [];
  } catch (err) {
    console.error('Failed to load review requests data', err);
    rawRequests.value = [];
  } finally {
    loading.value = false;
  }
}

onMounted(loadData);

watch(isRequestModalOpen, (open, wasOpen) => {
  if (wasOpen && !open) loadData();
});

const requests = computed(() => rawRequests.value.map(mapRequest));

const periodRequests = computed(() => {
  const days = TIMEFRAME_DAYS[selectedTimeframe.value];
  if (!days) return requests.value;
  const cutoff = Date.now() - days * 86400000;
  return requests.value.filter(r => r.sentAtTs >= cutoff);
});

const filteredRequests = computed(() => {
  const q = searchQuery.value.trim().toLowerCase();
  return periodRequests.value.filter(req => {
    const matchesSearch =
      !q ||
      req.customerName.toLowerCase().includes(q) ||
      req.customerEmail.toLowerCase().includes(q) ||
      req.customerPhone.toLowerCase().includes(q) ||
      req.displayId.toLowerCase().includes(q) ||
      String(req.id).includes(q) ||
      req.trigger.toLowerCase().includes(q);
    const matchesChannel =
      selectedChannel.value === 'All Channels' || req.channel === selectedChannel.value;
    const matchesStatus =
      selectedStatus.value === 'All Statuses' || req.status === selectedStatus.value;
    return matchesSearch && matchesChannel && matchesStatus;
  });
});

const stats = computed(() => {
  const rows = periodRequests.value;
  const dispatched = rows.filter(r => r.rawStatus !== 'scheduled');
  const delivered = dispatched.filter(r =>
    ['delivered', 'clicked', 'completed'].includes(r.rawStatus)
  );
  const clicked = dispatched.filter(r => ['clicked', 'completed'].includes(r.rawStatus));
  const completed = dispatched.filter(r => r.rawStatus === 'completed');
  const sentCount = dispatched.length;
  const deliveryRate = sentCount ? Math.round((delivered.length / sentCount) * 1000) / 10 : null;
  const clickRate = sentCount ? Math.round((clicked.length / sentCount) * 1000) / 10 : null;
  const conversionRate = sentCount ? Math.round((completed.length / sentCount) * 10) / 10 : null;
  return {
    totalSent: sentCount,
    totalSentLabel: sentCount.toLocaleString(),
    deliveryRate: deliveryRate == null ? '—' : `${deliveryRate}%`,
    deliveredCount: delivered.length,
    clickRate: clickRate == null ? '—' : `${clickRate}%`,
    clickedCount: clicked.length,
    converted: completed.length,
    convertedLabel: completed.length.toLocaleString(),
    conversionRate: conversionRate == null ? '—' : `${conversionRate}%`,
  };
});

const showPopulated = computed(
  () => isDemoLoaded.value && (requests.value.length > 0 || loading.value)
);

function statusBadgeClass(status) {
  return {
    Completed: 'bg-success/15 text-success border-transparent',
    Opened: 'bg-primary/10 text-primary border-transparent',
    Clicked: 'bg-primary/10 text-primary border-transparent',
    Delivered: 'bg-muted text-muted-foreground border-transparent',
    Sent: 'bg-muted text-muted-foreground border-transparent',
    Scheduled: 'bg-warning/15 text-warning border-transparent',
    'Follow-up Sent': 'bg-warning/15 text-warning border-transparent',
    Failed: 'bg-destructive/10 text-destructive border-transparent',
  }[status] || 'bg-muted text-muted-foreground border-transparent';
}

function toggleDemo() {
  isDemoLoaded.value = !isDemoLoaded.value;
  if (!isDemoLoaded.value) selectedRequest.value = null;
}

async function copyReviewLink(req) {
  if (!req?.token) {
    useAlert('No review link is available for this request.');
    return;
  }
  try {
    await navigator.clipboard.writeText(`${window.location.origin}/r/${req.token}`);
    useAlert('Direct review link copied to clipboard');
  } catch (err) {
    useAlert('Could not copy the review link.');
  }
}

async function resendRequest(req) {
  if (!req?.contactId) {
    useAlert('This request has no contact to resend to.');
    return;
  }
  resending.value = true;
  try {
    await axios.post(`${baseUrl()}/review_requests`, {
      channel: req.channelRaw,
      contact_ids: [req.contactId],
      message: req.messageBody || undefined,
      destinations: req.destinations?.length ? req.destinations : undefined,
    });
    useAlert(`Review request resent to ${req.customerName} via ${req.channel}`);
    selectedRequest.value = null;
    await loadData();
  } catch (err) {
    useAlert('Could not resend this request.');
  } finally {
    resending.value = false;
  }
}
</script>

<template>
  <div class="relative flex h-[calc(100vh-4rem)] min-h-0 w-full overflow-hidden bg-background">
    <RequestReviewsModal v-model:open="isRequestModalOpen" />

    <div
      class="flex-1 overflow-y-auto w-full flex flex-col transition-all duration-300 hide-scrollbar"
      :class="selectedRequest ? 'mr-[420px]' : ''"
    >
      <div class="px-8 pt-8 pb-4 shrink-0 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div class="flex items-center gap-2.5">
            <h1 class="text-base font-medium tracking-tight text-foreground">Review Requests</h1>
            <span class="inline-flex items-center rounded-md px-2 py-0.5 text-[11.5px] font-medium bg-primary/10 text-primary">
              {{ stats.totalSentLabel }} Sent
            </span>
          </div>
          <p class="text-[13.5px] text-muted-foreground mt-1 leading-relaxed">
            Monitor, track delivery and automate customer review invites across SMS, Email, and WhatsApp.
          </p>
        </div>
        <div class="flex items-center gap-3">
          <Button class="gap-2 shadow-xs text-[13.5px] h-9 px-4" @click="isRequestModalOpen = true">
            <Send class="size-4" />
            Send Request
          </Button>
        </div>
      </div>

      <div v-if="loading" class="flex flex-col items-center justify-center py-20 space-y-4">
        <div class="size-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
        <p class="text-sm font-medium text-muted-foreground">Loading requests feed...</p>
      </div>

      <template v-else-if="showPopulated">
        <div class="px-8 pb-12 space-y-7">
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            <div class="bg-card rounded-xl border border-border shadow-sm p-5 relative overflow-hidden">
              <div class="flex justify-between items-start mb-4">
                <div>
                  <p class="text-sm font-medium text-muted-foreground mb-1">Total Requests Sent</p>
                  <h3 class="text-3xl font-bold text-foreground">{{ stats.totalSentLabel }}</h3>
                </div>
                <div class="p-2.5 bg-primary/10 rounded-lg text-primary">
                  <Send class="size-5" />
                </div>
              </div>
              <p class="text-sm text-muted-foreground">
                {{ selectedTimeframe === 'All Time' ? 'All dispatched invites' : selectedTimeframe }}
              </p>
            </div>

            <div class="bg-card rounded-xl border border-border shadow-sm p-5 relative overflow-hidden">
              <div class="flex justify-between items-start mb-4">
                <div>
                  <p class="text-sm font-medium text-muted-foreground mb-1">Delivery Success</p>
                  <h3 class="text-3xl font-bold text-foreground">{{ stats.deliveryRate }}</h3>
                </div>
                <div class="p-2.5 bg-primary/10 rounded-lg text-primary">
                  <CheckCheck class="size-5" />
                </div>
              </div>
              <p class="text-sm text-muted-foreground">
                {{ stats.deliveredCount.toLocaleString() }} delivered
              </p>
            </div>

            <div class="bg-card rounded-xl border border-border shadow-sm p-5 relative overflow-hidden">
              <div class="flex justify-between items-start mb-4">
                <div>
                  <p class="text-sm font-medium text-muted-foreground mb-1">Link Click Rate</p>
                  <h3 class="text-3xl font-bold text-foreground">{{ stats.clickRate }}</h3>
                </div>
                <div class="p-2.5 bg-primary/10 rounded-lg text-primary">
                  <ExternalLink class="size-5" />
                </div>
              </div>
              <p class="text-sm text-muted-foreground">
                {{ stats.clickedCount.toLocaleString() }} viewed link
              </p>
            </div>

            <div class="bg-card rounded-xl border border-border shadow-sm p-5 relative overflow-hidden">
              <div class="flex justify-between items-start mb-4">
                <div>
                  <p class="text-sm font-medium text-muted-foreground mb-1">Reviews Generated</p>
                  <h3 class="text-3xl font-bold text-foreground">{{ stats.convertedLabel }}</h3>
                </div>
                <div class="p-2.5 bg-primary/10 rounded-lg text-primary">
                  <Star class="size-5" />
                </div>
              </div>
              <p class="text-sm text-muted-foreground">
                {{ stats.conversionRate }} conversion rate
              </p>
            </div>
          </div>

          <div class="space-y-4">
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div class="flex items-center gap-3 flex-1 max-w-md">
                <div class="relative w-full">
                  <Search class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
                  <Input
                    v-model="searchQuery"
                    type="text"
                    placeholder="Search by customer name, phone, email, or ID..."
                    class-name="w-full pl-9 h-9 text-[13.5px] bg-background border-border/80 rounded-lg shadow-sm"
                  />
                </div>
              </div>

              <div class="flex items-center gap-2.5 flex-wrap">
                <DropdownMenu>
                  <DropdownMenuTrigger as-child>
                    <Button
                      variant="outline"
                      class="h-9 gap-1.5 border border-border hover:border-transparent text-[13px] font-medium bg-card px-3 rounded-lg shadow-xs"
                    >
                      <span>{{ selectedChannel }}</span>
                      <ChevronDown class="size-3.5 opacity-60 ml-0.5" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end" class="w-44">
                    <DropdownMenuItem @click="selectedChannel = 'All Channels'">All Channels</DropdownMenuItem>
                    <DropdownMenuItem @click="selectedChannel = 'SMS'">SMS</DropdownMenuItem>
                    <DropdownMenuItem @click="selectedChannel = 'Email'">Email</DropdownMenuItem>
                    <DropdownMenuItem @click="selectedChannel = 'WhatsApp'">WhatsApp</DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>

                <DropdownMenu>
                  <DropdownMenuTrigger as-child>
                    <Button
                      variant="outline"
                      class="h-9 gap-1.5 border border-border hover:border-transparent text-[13px] font-medium bg-card px-3 rounded-lg shadow-xs"
                    >
                      <span>{{ selectedStatus }}</span>
                      <ChevronDown class="size-3.5 opacity-60 ml-0.5" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end" class="w-48">
                    <DropdownMenuItem @click="selectedStatus = 'All Statuses'">All Statuses</DropdownMenuItem>
                    <DropdownMenuItem @click="selectedStatus = 'Completed'">Completed</DropdownMenuItem>
                    <DropdownMenuItem @click="selectedStatus = 'Opened'">Opened</DropdownMenuItem>
                    <DropdownMenuItem @click="selectedStatus = 'Delivered'">Delivered</DropdownMenuItem>
                    <DropdownMenuItem @click="selectedStatus = 'Sent'">Sent</DropdownMenuItem>
                    <DropdownMenuItem @click="selectedStatus = 'Scheduled'">Scheduled</DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>

                <DropdownMenu>
                  <DropdownMenuTrigger as-child>
                    <Button
                      variant="outline"
                      class="h-9 gap-1.5 border border-border hover:border-transparent text-[13px] font-medium bg-card px-3 rounded-lg shadow-xs"
                    >
                      <Calendar class="size-3.5 text-muted-foreground" />
                      <span>{{ selectedTimeframe }}</span>
                      <ChevronDown class="size-3.5 opacity-60 ml-0.5" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end" class="w-44">
                    <DropdownMenuItem @click="selectedTimeframe = 'Last 7 Days'">Last 7 Days</DropdownMenuItem>
                    <DropdownMenuItem @click="selectedTimeframe = 'Last 30 Days'">Last 30 Days</DropdownMenuItem>
                    <DropdownMenuItem @click="selectedTimeframe = 'Last 90 Days'">Last 90 Days</DropdownMenuItem>
                    <DropdownMenuItem @click="selectedTimeframe = 'All Time'">All Time</DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            </div>

            <div class="rounded-xl border border-border/50 bg-card shadow-sm overflow-hidden">
              <table class="w-full text-sm text-left border-collapse">
                <thead class="bg-muted/30 border-b border-border/50">
                  <tr>
                    <th class="px-6 py-3.5 text-[14px] font-medium text-muted-foreground whitespace-nowrap">Recipient & Customer</th>
                    <th class="px-6 py-3.5 text-[14px] font-medium text-muted-foreground whitespace-nowrap">Channel & Trigger</th>
                    <th class="px-6 py-3.5 text-[14px] font-medium text-muted-foreground whitespace-nowrap">Status</th>
                    <th class="px-6 py-3.5 text-[14px] font-medium text-muted-foreground whitespace-nowrap text-right">Sent Timestamp</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-border/40">
                  <tr v-if="filteredRequests.length === 0">
                    <td colspan="4" class="px-6 py-12 text-center text-muted-foreground text-[13.5px]">
                      No review requests found matching your filters.
                    </td>
                  </tr>
                  <tr
                    v-for="req in filteredRequests"
                    :key="req.id"
                    role="button"
                    tabindex="0"
                    class="group hover:bg-muted/30 transition-colors cursor-pointer"
                    :class="selectedRequest?.id === req.id ? 'bg-primary/5 dark:bg-primary/10' : ''"
                    @click="selectedRequest = req"
                    @keydown.enter.prevent="selectedRequest = req"
                  >
                    <td class="px-6 py-4 align-middle">
                      <div class="flex items-center gap-3 min-w-0">
                        <div class="size-9 rounded-full bg-primary/10 text-primary text-[12px] font-semibold flex items-center justify-center shrink-0 ring-1 ring-border/50">
                          {{ req.initials }}
                        </div>
                        <div class="min-w-0 flex-1">
                          <div class="flex items-center gap-2">
                            <span class="text-[14px] font-medium text-foreground truncate group-hover:text-primary transition-colors">{{ req.customerName }}</span>
                            <span class="text-[11px] text-muted-foreground font-mono">{{ req.displayId }}</span>
                          </div>
                          <div class="text-[12.5px] text-muted-foreground truncate">{{ req.customerPhone || req.customerEmail }}</div>
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4 align-middle">
                      <div class="flex flex-col gap-1">
                        <div class="flex items-center gap-1.5">
                          <Badge
                            variant="outline"
                            class="text-[11px] font-medium gap-1 px-1.5 py-0.5 rounded-md"
                            :class="{
                              'bg-primary/10 text-primary border-primary/20': req.channel === 'SMS',
                              'bg-muted text-foreground border-border': req.channel === 'Email',
                              'bg-success/10 text-success border-success/20': req.channel === 'WhatsApp',
                            }"
                          >
                            <Smartphone v-if="req.channel === 'SMS'" class="size-3" />
                            <Mail v-else-if="req.channel === 'Email'" class="size-3" />
                            <MessageCircle v-else class="size-3" />
                            {{ req.channel }}
                          </Badge>
                        </div>
                        <span class="text-[12px] text-muted-foreground truncate">{{ req.trigger }}</span>
                      </div>
                    </td>
                    <td class="px-6 py-4 align-middle">
                      <div>
                        <div class="flex items-center gap-2">
                          <span
                            class="inline-flex items-center rounded-full px-2.5 py-0.5 text-[11.5px] font-medium"
                            :class="statusBadgeClass(req.status)"
                          >
                            <Star v-if="req.status === 'Completed'" class="size-3 mr-1 fill-current" />
                            <Eye v-else-if="req.status === 'Opened'" class="size-3 mr-1" />
                            <Bot v-else-if="req.status === 'Follow-up Sent'" class="size-3 mr-1" />
                            <Clock v-else-if="req.status === 'Scheduled'" class="size-3 mr-1" />
                            <Check v-else-if="req.status === 'Delivered' || req.status === 'Sent'" class="size-3 mr-1" />
                            <AlertTriangle v-else-if="req.status === 'Failed'" class="size-3 mr-1" />
                            {{ req.status }}
                          </span>
                        </div>
                        <div v-if="req.status === 'Completed' && req.destination" class="text-[11px] font-medium text-muted-foreground mt-1">
                          on {{ req.destination }}
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4 align-middle text-right text-[13px] text-muted-foreground whitespace-nowrap">
                      {{ req.sentAt }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </template>

      <template v-else>
        <div class="flex-1 flex flex-col justify-center items-center py-16 px-8">
          <div class="flex flex-col items-center text-center max-w-md">
            <div class="size-16 rounded-full bg-primary/10 text-primary flex items-center justify-center mb-4">
              <Send class="size-6" />
            </div>
            <h2 class="text-[20px] font-[600] text-foreground">No Review Requests Yet</h2>
            <p class="text-[13.5px] text-muted-foreground mt-2 leading-relaxed">
              Start requesting customer reviews or send tailored invites via SMS, Email, and WhatsApp in seconds.
            </p>
            <Button class="mt-6 gap-2 shadow-xs text-[13.5px] h-9 px-4" @click="isRequestModalOpen = true">
              <Send class="size-4" />
              Send Your First Request
            </Button>
          </div>
        </div>
      </template>

      <div class="mt-auto border-t border-border/80 bg-muted/20 px-8 py-3 flex items-center justify-between">
        <span class="text-[12px] text-muted-foreground">Preview State Mode (Developer Control)</span>
        <Button
          variant="outline"
          size="sm"
          class="h-7 text-[12px] font-medium border border-border hover:border-transparent bg-card"
          @click="toggleDemo"
        >
          Toggle to {{ isDemoLoaded ? 'Empty State' : 'Populated Data' }}
        </Button>
      </div>
    </div>

    <div
      v-if="selectedRequest"
      class="fixed inset-y-0 right-0 top-16 w-[420px] bg-card border-l border-border shadow-xl z-40 flex flex-col animate-in slide-in-from-right duration-200"
    >
      <div class="p-5 border-b border-border flex items-center justify-between">
        <div>
          <div class="flex items-center gap-2">
            <h3 class="text-[15px] font-semibold text-foreground">Request Details</h3>
            <span class="text-[11.5px] font-mono text-muted-foreground">{{ selectedRequest.displayId }}</span>
          </div>
          <p class="text-[12px] text-muted-foreground mt-0.5">Full delivery and interaction timeline</p>
        </div>
        <button
          class="p-1.5 rounded-lg text-muted-foreground hover:text-foreground hover:bg-muted transition-colors"
          @click="selectedRequest = null"
        >
          <X class="size-4" />
        </button>
      </div>

      <div class="flex-1 overflow-y-auto p-5 space-y-6">
        <div class="rounded-xl border border-border bg-muted/20 p-4">
          <div class="flex items-center gap-3">
            <div class="size-10 rounded-full bg-primary/10 text-primary text-[12px] font-semibold flex items-center justify-center border border-border">
              {{ selectedRequest.initials }}
            </div>
            <div class="min-w-0 flex-1">
              <h4 class="text-[14px] font-semibold text-foreground">{{ selectedRequest.customerName }}</h4>
              <p v-if="selectedRequest.customerPhone" class="text-[12.5px] text-muted-foreground">{{ selectedRequest.customerPhone }}</p>
              <p v-if="selectedRequest.customerEmail" class="text-[12px] text-muted-foreground">{{ selectedRequest.customerEmail }}</p>
            </div>
            <span
              class="inline-flex items-center rounded-full px-2.5 py-0.5 text-[11px] font-medium"
              :class="selectedRequest.status === 'Completed' ? 'bg-success/15 text-success' : 'bg-primary/10 text-primary'"
            >
              {{ selectedRequest.status }}
            </span>
          </div>
        </div>

        <div class="space-y-2">
          <div class="flex items-center justify-between">
            <span class="text-[13px] font-medium text-foreground">Message Dispatched</span>
            <Badge variant="outline" class="text-[11px]">{{ selectedRequest.channel }}</Badge>
          </div>
          <div class="p-3.5 rounded-xl border border-border bg-background text-[13px] text-foreground leading-relaxed whitespace-pre-wrap">
            {{ selectedRequest.messageBody || 'No message stored for this request.' }}
          </div>
        </div>

        <div class="space-y-3">
          <span class="text-[13px] font-medium text-foreground">Delivery Journey</span>
          <div class="space-y-4 pl-1">
            <div
              v-for="(step, idx) in selectedRequest.history"
              :key="idx"
              class="relative flex items-start gap-3"
            >
              <div
                v-if="idx !== selectedRequest.history.length - 1"
                class="absolute left-3.5 top-6 bottom-0 w-px bg-border"
              />
              <div class="size-7 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0 z-10">
                <component :is="step.icon" class="size-3.5" />
              </div>
              <div class="flex-1 min-w-0 pt-0.5">
                <div class="flex items-center justify-between gap-2">
                  <h5 class="text-[13px] font-medium text-foreground">{{ step.title }}</h5>
                  <span class="text-[11px] text-muted-foreground">{{ step.time }}</span>
                </div>
                <p class="text-[12px] text-muted-foreground mt-0.5">{{ step.description }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="p-4 border-t border-border bg-card flex items-center justify-between gap-3">
        <Button
          variant="outline"
          class="flex-1 border border-border hover:border-transparent text-[13px]"
          :disabled="resending"
          @click="resendRequest(selectedRequest)"
        >
          <RotateCcw class="size-3.5 mr-2" />
          Resend Request
        </Button>
        <Button class="flex-1 text-[13px]" @click="copyReviewLink(selectedRequest)">
          <Copy class="size-3.5 mr-2" />
          Copy Link
        </Button>
      </div>
    </div>
  </div>
</template>
