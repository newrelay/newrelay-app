<script setup>
/* eslint-disable */
import { ref, onMounted, computed, watch } from 'vue';
const axios = window.axios;

const accountId = window.__STORE__?.getters['auth/getCurrentAccount']?.id || 
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];

const requests = ref([]);
const templates = ref([]);
const loading = ref(true);

// Modal and Composer state
const showModal = ref(false);
const contactsQuery = ref('');
const contactsList = ref([]);
const loadingContacts = ref(false);
const selectedContact = ref(null);
const selectedTemplateId = ref('');
const sendingRequest = ref(false);

const baseUrl = () => `/api/v1/accounts/${accountId}/reputation`;

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

// Contacts autocomplete lookup
async function searchContacts() {
  if (contactsQuery.value.trim().length < 2) {
    contactsList.value = [];
    return;
  }
  loadingContacts.value = true;
  try {
    const { data } = await axios.get(`/api/v1/accounts/${accountId}/contacts/search`, {
      params: { q: contactsQuery.value }
    });
    // The search endpoint might return different formats, let's normalize
    contactsList.value = data.payload || data || [];
  } catch (err) {
    contactsList.value = [];
  } finally {
    loadingContacts.value = false;
  }
}

const openModal = async () => {
  showModal.value = true;
  try {
    const tempRes = await axios.get(`${baseUrl()}/templates`);
    templates.value = tempRes.data.filter(t => t.active && t.template_type !== 'video');
  } catch (err) {
    console.error('Failed to load templates', err);
  }
};

watch(contactsQuery, (newVal) => {
  if (selectedContact.value && newVal !== selectedContact.value.name) {
    selectedContact.value = null;
  }
  if (selectedContact.value) return;
  searchContacts();
});

function selectContact(contact) {
  selectedContact.value = contact;
  contactsQuery.value = contact.name;
  contactsList.value = [];
}

async function sendRequest() {
  if (!selectedContact.value && (!contactsQuery.value || !contactsQuery.value.includes('@'))) {
    alert("Please select a recipient contact, or type a valid email address.");
    return;
  }
  if (!selectedTemplateId.value) {
    alert("Please select an invite template.");
    return;
  }
  
  sendingRequest.value = true;
  try {
    const payload = { template_id: selectedTemplateId.value };
    if (selectedContact.value) {
      payload.contact_id = selectedContact.value.id;
    } else {
      payload.email = contactsQuery.value.trim();
    }
    
    await axios.post(`${baseUrl()}/review_requests`, payload);
    // Reset composer state
    showModal.value = false;
    selectedContact.value = null;
    selectedTemplateId.value = '';
    contactsQuery.value = '';
    loadData();
  } catch (err) {
    alert('Failed to dispatch review request. Make sure contact has email/phone depending on channel.');
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
  if (s.sent === 0) return { click: 0, complete: 0 };
  return {
    click: Math.round((s.clicked / s.sent) * 100),
    complete: Math.round((s.completed / s.sent) * 100)
  };
});

const previewBody = computed(() => {
  if (!selectedTemplateId.value) return '';
  const template = templates.value.find(t => t.id == selectedTemplateId.value);
  if (!template) return '';
  
  let body = template.body || '';
  const name = selectedContact.value ? selectedContact.value.name : 'Customer';
  body = body.replace(/\{\{\s*contact\.name\s*\}\}/g, name);
  body = body.replace(/\{\{\s*review_link\s*\}\}/g, `${window.location.origin}/r/example-token`);
  return body;
});

const getSelectedTemplateSubject = computed(() => {
  const template = templates.value.find(t => t.id == selectedTemplateId.value);
  return template ? template.subject : '';
});

const statusColor = s => {
  return {
    sent: 'bg-blue-50 text-blue-700 dark:bg-blue-950/20 dark:text-blue-400 border border-blue-100 dark:border-blue-900/30',
    delivered: 'bg-cyan-50 text-cyan-700 dark:bg-cyan-950/20 dark:text-cyan-400 border border-cyan-100 dark:border-cyan-900/30',
    clicked: 'bg-amber-50 text-amber-700 dark:bg-amber-950/20 dark:text-amber-450 border border-amber-200/50 dark:border-amber-900/30',
    completed: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/20 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900/30'
  }[s] || 'bg-slate-100 text-slate-650';
};
</script>

<template>
  <div class="p-6 max-w-7xl mx-auto space-y-6">
    <!-- eslint-disable -->
    <!-- Top Header -->
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight">Review Requests</h2>
        <p class="text-xs text-slate-400 mt-0.5">Send custom reviews invites to your contacts</p>
      </div>
      <button
        class="px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-1.5"
        @click="openModal"
      >
        <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" /></svg>
        New Request
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex flex-col items-center justify-center py-20 space-y-4">
      <div class="size-10 border-4 border-woot-500 border-t-transparent rounded-full animate-spin"></div>
      <p class="text-sm font-medium text-slate-500 dark:text-slate-400">Loading requests feed...</p>
    </div>

    <div v-else class="space-y-6">
      <!-- Funnel Metrics Widget -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 p-6 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 shadow-sm">
        <div class="space-y-1">
          <span class="text-[10px] uppercase font-bold text-slate-400">Total Sent</span>
          <h4 class="text-2xl font-extrabold text-slate-900 dark:text-white">{{ stats.sent }}</h4>
          <p class="text-[10px] text-slate-500">Outbound requests</p>
        </div>
        <div class="space-y-1">
          <span class="text-[10px] uppercase font-bold text-slate-400">Delivered</span>
          <h4 class="text-2xl font-extrabold text-slate-900 dark:text-white">{{ stats.delivered }}</h4>
          <p class="text-[10px] text-slate-500">Receipts confirmed</p>
        </div>
        <div class="space-y-1">
          <span class="text-[10px] uppercase font-bold text-slate-400">Link Clicks</span>
          <h4 class="text-2xl font-extrabold text-slate-900 dark:text-white">{{ stats.clicked }}</h4>
          <p class="text-[10px] text-amber-500 font-bold">{{ conversionRates.click }}% Click Rate</p>
        </div>
        <div class="space-y-1">
          <span class="text-[10px] uppercase font-bold text-slate-400">Completed Reviews</span>
          <h4 class="text-2xl font-extrabold text-slate-900 dark:text-white">{{ stats.completed }}</h4>
          <p class="text-[10px] text-emerald-500 font-bold">{{ conversionRates.complete }}% Conversion</p>
        </div>
      </div>

      <!-- Logs List -->
      <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-850 shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-850">
          <h3 class="font-extrabold text-slate-900 dark:text-white text-sm">Outbound Logs</h3>
        </div>

        <div v-if="requests.length === 0" class="flex flex-col items-center justify-center py-16 space-y-2">
          <div class="p-3 rounded-full bg-slate-100 dark:bg-slate-850 text-slate-400">
            <svg class="size-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
          </div>
          <p class="text-sm font-bold text-slate-700 dark:text-slate-355">No requests dispatched</p>
          <p class="text-xs text-slate-400">Click the "+ New Request" button to invite contacts.</p>
        </div>

        <table v-else class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-slate-50 dark:bg-slate-800/40 text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">
              <th class="px-6 py-3.5">Contact Name</th>
              <th class="px-6 py-3.5">Template</th>
              <th class="px-6 py-3.5">Channel</th>
              <th class="px-6 py-3.5">Invite Status</th>
              <th class="px-6 py-3.5 text-right">Sent Date</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 dark:divide-slate-850">
            <tr
              v-for="req in requests"
              :key="req.id"
              class="hover:bg-slate-50/50 dark:hover:bg-slate-850/30 text-xs transition-colors"
            >
              <td class="px-6 py-4 font-bold text-slate-800 dark:text-slate-200">
                <div class="flex flex-col">
                  <span>{{ req.contact?.name || 'Customer' }}</span>
                  <span class="text-[10px] text-slate-400 font-normal mt-0.5">
                    {{ req.contact?.phone_number || req.contact?.email || 'No credentials' }}
                  </span>
                </div>
              </td>
              <td class="px-6 py-4 text-slate-600 dark:text-slate-350">
                {{ req.reputation_template?.name || 'Custom' }}
              </td>
              <td class="px-6 py-4">
                <span class="px-2 py-0.5 text-[10px] font-bold rounded-lg uppercase bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                  {{ req.channel }}
                </span>
              </td>
              <td class="px-6 py-4">
                <span class="px-2 py-0.5 text-[10px] font-bold rounded-full uppercase" :class="statusColor(req.status)">
                  {{ req.status }}
                </span>
              </td>
              <td class="px-6 py-4 text-right text-slate-400">
                {{ new Date(req.created_at).toLocaleDateString() }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Review Invite Modal -->
    <div 
      v-if="showModal" 
      class="fixed inset-0 z-50 overflow-y-auto flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm transition-all"
    >
      <div class="relative w-full max-w-lg bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-2xl p-6 space-y-5 flex flex-col justify-between">
        <div class="flex items-center justify-between border-b border-slate-100 dark:border-slate-850 pb-3">
          <h3 class="text-base font-extrabold text-slate-950 dark:text-white">Create Review Invitation</h3>
          <button 
            class="p-1 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-850 text-slate-400"
            @click="showModal = false"
          >
            <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>

        <div class="space-y-4 overflow-y-auto max-h-[350px]">
          <!-- Contact Search Form -->
          <div class="space-y-1.5 relative">
            <label class="block text-xs font-bold text-slate-450 uppercase tracking-wider">Recipient Contact</label>
            <input
              v-model="contactsQuery"
              type="text"
              placeholder="Search contact name..."
              class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-850 p-3 focus:outline-none focus:ring-2 focus:ring-woot-500"
            />
            
            <div v-if="loadingContacts" class="absolute right-3 top-9">
              <div class="size-4 border-2 border-woot-500 border-t-transparent rounded-full animate-spin"></div>
            </div>

            <!-- Contacts Dropdown Result -->
            <ul v-if="contactsList.length > 0" class="absolute left-0 right-0 z-10 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl mt-1 shadow-lg max-h-40 overflow-y-auto divide-y divide-slate-100 dark:divide-slate-850">
              <li
                v-for="c in contactsList"
                :key="c.id"
                class="px-4 py-2.5 hover:bg-slate-50 dark:hover:bg-slate-850 cursor-pointer text-xs flex flex-col"
                @click="selectContact(c)"
              >
                <span class="font-bold text-slate-800 dark:text-slate-200">{{ c.name }}</span>
                <span class="text-[10px] text-slate-400 mt-0.5">{{ c.phone_number || c.email || 'No phone/email' }}</span>
              </li>
            </ul>
          </div>

          <!-- Template Select Dropdown -->
          <div class="space-y-1.5">
            <label class="block text-xs font-bold text-slate-450 uppercase tracking-wider">Invite Template</label>
            <select
              v-model="selectedTemplateId"
              class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-850 p-3 focus:outline-none focus:ring-2 focus:ring-woot-500"
            >
              <option value="">Select template...</option>
              <option v-for="t in templates" :key="t.id" :value="t.id">{{ t.name }} ({{ t.channel }})</option>
            </select>
          </div>

          <!-- Message Body Preview -->
          <div v-if="selectedTemplateId" class="p-4 bg-slate-50 dark:bg-slate-850 rounded-xl border border-slate-150 dark:border-slate-800/80 space-y-2">
            <label class="block text-[10px] font-bold text-slate-400 uppercase tracking-wider">Dynamic Preview</label>
            <div v-if="getSelectedTemplateSubject" class="text-xs font-bold text-slate-800 dark:text-slate-200">
              Subject: {{ getSelectedTemplateSubject }}
            </div>
            <p class="text-xs text-slate-650 dark:text-slate-300 leading-relaxed italic whitespace-pre-wrap">
              "{{ previewBody }}"
            </p>
          </div>
        </div>

        <div class="flex justify-end gap-2 pt-3 border-t border-slate-100 dark:border-slate-850">
          <button
            class="px-4 py-2 text-xs font-bold text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-850 rounded-xl border border-slate-200 dark:border-slate-800"
            @click="showModal = false"
          >
            Cancel
          </button>
          <button
            class="px-5 py-2 text-xs font-bold bg-woot-500 hover:bg-woot-600 text-white rounded-xl shadow-sm transition-colors flex items-center gap-1.5"
            :class="{'opacity-50 cursor-not-allowed': sendingRequest}"
            :disabled="sendingRequest"
            @click="sendRequest"
          >
            <svg v-if="sendingRequest" class="size-3.5 animate-spin" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 1121.21 7.89M9 11l3-3 3 3m0 0l-3 3-3-3" /></svg>
            Send Invite
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
