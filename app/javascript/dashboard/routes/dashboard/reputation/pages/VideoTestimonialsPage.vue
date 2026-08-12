<script setup>
import { ref, onMounted } from 'vue';

const axios = window.axios;
const accountId =
  window.__STORE__?.getters['auth/getCurrentAccount']?.id ||
  window.location.pathname.match(/accounts\/(\d+)/)?.[1];

const testimonials = ref([]);
const requests = ref([]);
const templates = ref([]);
const loading = ref(true);

const showModal = ref(false);
const sending = ref(false);
const selectedTemplate = ref(null);
const requestForm = ref({
  email: '',
  subject: '',
  body: '',
});

const fetchTestimonials = async () => {
  loading.value = true;
  try {
    const [testRes, reqRes, tempRes] = await Promise.all([
      axios.get(`/api/v1/accounts/${accountId}/reputation/video_testimonials`),
      axios.get(
        `/api/v1/accounts/${accountId}/reputation/video_testimonials/requests_index`
      ),
      axios
        .get(`/api/v1/accounts/${accountId}/reputation/templates`)
        .catch(() => ({ data: [] })),
    ]);
    testimonials.value = testRes.data;
    requests.value = reqRes.data;
    templates.value = tempRes.data.filter(
      t => t.active && t.template_type === 'video'
    );
  } catch (err) {
    console.error('Failed to load video testimonials', err);
  } finally {
    loading.value = false;
  }
};

const deleteTestimonial = async id => {
  if (!confirm('Are you sure you want to delete this video testimonial?'))
    return;
  try {
    await axios.delete(
      `/api/v1/accounts/${accountId}/reputation/video_testimonials/${id}`
    );
    testimonials.value = testimonials.value.filter(t => t.id !== id);
  } catch (err) {
    alert('Failed to delete testimonial');
  }
};

const openModal = async () => {
  showModal.value = true;
  try {
    const tempRes = await axios.get(
      `/api/v1/accounts/${accountId}/reputation/templates`
    );
    templates.value = tempRes.data.filter(
      t => t.active && t.template_type === 'video'
    );
  } catch (err) {
    console.error('Failed to load templates', err);
  }
};

const sendRequest = async () => {
  if (!requestForm.value.email) return;
  sending.value = true;

  const payload = {
    ...requestForm.value,
    template_id: selectedTemplate.value ? selectedTemplate.value.id : null,
  };

  try {
    await axios.post(
      `/api/v1/accounts/${accountId}/reputation/video_testimonials/dispatch_request`,
      payload
    );
    showModal.value = false;
    alert('Request sent successfully!');
    requestForm.value.email = '';
    requestForm.value.subject = '';
    requestForm.value.body = '';
    selectedTemplate.value = null;
    fetchTestimonials();
  } catch (err) {
    alert('Failed to send request');
  } finally {
    sending.value = false;
  }
};

const handleTemplateChange = () => {
  if (selectedTemplate.value) {
    requestForm.value.subject = selectedTemplate.value.subject || '';
    requestForm.value.body = selectedTemplate.value.body || '';
  }
};

const formatDate = timestamp => {
  return new Date(timestamp * 1000).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
};

const statusColor = s => {
  return (
    {
      sent: 'bg-blue-50 text-blue-700 dark:bg-blue-950/20 dark:text-blue-400 border border-blue-100 dark:border-blue-900/30',
      delivered:
        'bg-cyan-50 text-cyan-700 dark:bg-cyan-950/20 dark:text-cyan-400 border border-cyan-100 dark:border-cyan-900/30',
      clicked:
        'bg-amber-50 text-amber-700 dark:bg-amber-950/20 dark:text-amber-450 border border-amber-200/50 dark:border-amber-900/30',
      completed:
        'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/20 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900/30',
    }[s] || 'bg-slate-100 text-slate-650'
  );
};

onMounted(fetchTestimonials);
</script>

<template>
  <div class="p-6 max-w-7xl mx-auto space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h2
          class="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight"
        >
          Video Testimonials
        </h2>
        <p class="text-xs text-slate-400 mt-0.5">
          Watch and manage the video testimonials submitted by your customers.
        </p>
      </div>

      <div class="flex gap-2">
        <button
          class="px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-1.5"
          @click="openModal"
        >
          <svg
            class="size-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M12 4v16m8-8H4"
            />
          </svg>
          Send Request
        </button>
        <a
          :href="`/reputation/video/${accountId}/new`"
          target="_blank"
          class="px-4 py-2 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-750 text-slate-700 dark:text-slate-200 rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-1.5"
        >
          <svg
            class="size-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
            />
          </svg>
          Open Form
        </a>
      </div>
    </div>

    <!-- Empty State -->
    <div
      v-if="!loading && testimonials.length === 0"
      class="flex flex-col items-center justify-center py-20 bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 rounded-2xl"
    >
      <div
        class="p-3.5 rounded-full bg-slate-100 dark:bg-slate-850 text-slate-400"
      >
        <svg
          class="size-7"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="1.5"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
          />
        </svg>
      </div>
      <h3 class="font-extrabold text-slate-800 dark:text-slate-200 mt-4">
        No video testimonials yet
      </h3>
      <p class="text-xs text-slate-400 mt-1 max-w-sm text-center">
        Share the submission form link with your customers to start collecting
        video testimonials.
      </p>
    </div>

    <!-- Grid View -->
    <div
      v-else-if="!loading && testimonials.length > 0"
      class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
    >
      <div
        v-for="t in testimonials"
        :key="t.id"
        class="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-850 rounded-2xl shadow-sm overflow-hidden flex flex-col group"
      >
        <!-- Video Player -->
        <div class="aspect-video bg-black relative">
          <video
            v-if="t.video_url"
            :src="t.video_url"
            controls
            preload="metadata"
            class="w-full h-full object-cover"
          />
          <div
            v-else
            class="w-full h-full flex flex-col items-center justify-center text-slate-500"
          >
            <svg
              class="size-8 mb-2 opacity-50"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="1.5"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"
              />
            </svg>
            <span class="text-xs font-medium">Video missing</span>
          </div>
        </div>

        <!-- Details -->
        <div class="p-4 flex-1 flex flex-col justify-between space-y-4">
          <div>
            <h3
              class="font-extrabold text-slate-800 dark:text-slate-100 text-sm line-clamp-2"
            >
              "{{ t.title }}"
            </h3>
            <p class="text-[11px] text-slate-500 font-medium mt-1">
              {{ t.email }}
            </p>
          </div>

          <div
            class="flex items-center justify-between pt-3 border-t border-slate-100 dark:border-slate-800"
          >
            <span class="text-[10px] text-slate-400 font-medium">{{
              formatDate(t.created_at)
            }}</span>
            <button
              class="text-[10px] uppercase font-bold tracking-wider text-red-500 hover:text-red-600 px-2 py-1 hover:bg-red-50 dark:hover:bg-red-900/30 rounded-lg transition-colors"
              @click="deleteTestimonial(t.id)"
            >
              Delete
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Outbound Logs -->
    <div
      v-if="!loading"
      class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-850 shadow-sm overflow-hidden mt-8"
    >
      <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-850">
        <h3 class="font-extrabold text-slate-900 dark:text-white text-sm">
          Outbound Video Requests
        </h3>
      </div>

      <div
        v-if="requests.length === 0"
        class="flex flex-col items-center justify-center py-16 space-y-2"
      >
        <div
          class="p-3 rounded-full bg-slate-100 dark:bg-slate-850 text-slate-400"
        >
          <svg
            class="size-6"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
            />
          </svg>
        </div>
        <p class="text-sm font-bold text-slate-700 dark:text-slate-355">
          No video requests dispatched
        </p>
      </div>

      <table v-else class="w-full text-left border-collapse">
        <thead>
          <tr
            class="bg-slate-50 dark:bg-slate-800/40 text-[10px] font-extrabold text-slate-400 uppercase tracking-wider"
          >
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
                  {{
                    req.contact?.phone_number ||
                    req.contact?.email ||
                    'No credentials'
                  }}
                </span>
              </div>
            </td>
            <td class="px-6 py-4 text-slate-600 dark:text-slate-350">
              {{ req.reputation_template?.name || 'Custom' }}
            </td>
            <td class="px-6 py-4">
              <span
                class="px-2 py-0.5 text-[10px] font-bold rounded-lg uppercase bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300"
              >
                {{ req.channel }}
              </span>
            </td>
            <td class="px-6 py-4">
              <span
                class="px-2 py-0.5 text-[10px] font-bold rounded-full uppercase"
                :class="statusColor(req.status)"
              >
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

    <!-- Request Modal -->
    <div
      v-if="showModal"
      class="fixed inset-0 z-50 overflow-y-auto flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm transition-all"
    >
      <div
        class="relative w-full max-w-lg bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-2xl p-6 space-y-5"
      >
        <div
          class="flex items-center justify-between border-b border-slate-100 dark:border-slate-850 pb-3"
        >
          <h3 class="text-base font-extrabold text-slate-950 dark:text-white">
            Send Video Testimonial Request
          </h3>
          <button
            class="p-1 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-850 text-slate-400"
            @click="showModal = false"
          >
            <svg
              class="size-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <div class="space-y-4">
          <div class="space-y-1.5">
            <label
              class="block text-xs font-bold text-slate-450 uppercase tracking-wider"
              >Customer Email</label>
            <input
              v-model="requestForm.email"
              type="email"
              placeholder="customer@example.com"
              class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-850 p-3 focus:outline-none focus:ring-2 focus:ring-woot-500"
            />
          </div>

          <div class="space-y-1.5">
            <label
              class="block text-xs font-bold text-slate-450 uppercase tracking-wider"
              >Message Template (Optional)</label>
            <select
              v-model="selectedTemplate"
              class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-850 p-3 focus:outline-none focus:ring-2 focus:ring-woot-500"
              @change="handleTemplateChange"
            >
              <option :value="null">Select a template to autofill...</option>
              <option v-for="t in templates" :key="t.id" :value="t">
                {{ t.name }}
              </option>
            </select>
          </div>

          <div class="space-y-1.5">
            <label
              class="block text-xs font-bold text-slate-450 uppercase tracking-wider"
              >Email Subject</label>
            <input
              v-model="requestForm.subject"
              type="text"
              class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-850 p-3 focus:outline-none focus:ring-2 focus:ring-woot-500"
            />
          </div>

          <div class="space-y-1.5">
            <label
              class="block text-xs font-bold text-slate-450 uppercase tracking-wider"
              >Message</label>
            <textarea
              v-model="requestForm.body"
              rows="5"
              class="w-full text-xs rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-850 p-3 focus:outline-none focus:ring-2 focus:ring-woot-500 font-mono"
            />
            <p class="text-[10px] text-slate-400 mt-1">
              Keep
              <code class="bg-slate-100 dark:bg-slate-800 px-1 rounded">{{
                video_link
              }}</code>
              in the message, it will be replaced by the real link.
            </p>
          </div>
        </div>

        <div
          class="flex justify-end gap-2 pt-3 border-t border-slate-100 dark:border-slate-850"
        >
          <button
            class="px-4 py-2 text-xs font-bold text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-850 rounded-xl border border-slate-200 dark:border-slate-800"
            @click="showModal = false"
          >
            Cancel
          </button>
          <button
            class="px-5 py-2 text-xs font-bold bg-woot-500 hover:bg-woot-600 text-white rounded-xl shadow-sm transition-colors flex items-center gap-1.5"
            :disabled="!requestForm.email || sending"
            @click="sendRequest"
          >
            <svg
              v-if="sending"
              class="size-3.5 animate-spin"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              stroke-width="2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 1121.21 7.89M9 11l3-3 3 3m0 0l-3 3-3-3"
              />
            </svg>
            Send Request
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
