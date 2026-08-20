<script setup>
/* eslint-disable */
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
      sent: 'bg-blue-500/15 text-blue-600 dark:text-blue-400 border border-blue-500/20',
      delivered:
        'bg-cyan-500/15 text-cyan-600 dark:text-cyan-400 border border-cyan-500/20',
      clicked:
        'bg-amber-500/15 text-amber-600 dark:text-amber-400 border border-amber-500/20',
      completed:
        'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20',
    }[s] || 'bg-muted text-muted-foreground'
  );
};

onMounted(fetchTestimonials);
</script>

<template>
  <div class="p-6 max-w-7xl mx-auto space-y-6">
    <!-- eslint-disable -->
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-base font-medium tracking-tight text-foreground">
          Video Testimonials
        </h1>
        <p class="text-sm text-muted-foreground mt-1">
          Collect, watch and manage authentic video testimonials from your
          customers.
        </p>
      </div>

      <div class="flex items-center gap-3">
        <a
          :href="`/reputation/video/${accountId}/new`"
          target="_blank"
          class="inline-flex items-center gap-2 rounded-lg border border-border bg-card px-3.5 py-2 text-sm font-medium text-foreground shadow-sm hover:bg-muted/50 transition-colors"
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
        <button
          class="inline-flex items-center gap-2 rounded-lg bg-primary px-3.5 py-2 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors"
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
      </div>
    </div>

    <!-- Loading -->
    <div
      v-if="loading"
      class="flex items-center justify-center py-20 text-sm text-muted-foreground"
    >
      Loading video testimonials…
    </div>

    <!-- Empty State -->
    <div
      v-else-if="testimonials.length === 0"
      class="flex flex-col items-center justify-center py-20 bg-card border border-border rounded-xl shadow-sm"
    >
      <div class="p-3.5 rounded-full bg-primary/10 text-primary">
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
      <h3 class="text-[20px] font-[600] text-foreground mt-4">
        No video testimonials yet
      </h3>
      <p class="text-[13.5px] text-muted-foreground mt-1 max-w-sm text-center leading-relaxed mb-4">
        Share the submission form link with your customers to start collecting
        video testimonials.
      </p>
      <button @click="openModal" class="px-4 py-2 rounded-lg border border-border bg-card text-[13.5px] font-medium text-foreground hover:bg-muted transition-colors border-input hover:border-transparent cursor-pointer">
        + Request Video Testimonial
      </button>
    </div>

    <!-- Grid View -->
    <div
      v-else
      class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
    >
      <div
        v-for="t in testimonials"
        :key="t.id"
        class="bg-card border border-border rounded-xl shadow-sm overflow-hidden flex flex-col"
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
            class="w-full h-full flex flex-col items-center justify-center text-muted-foreground"
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
        <div class="p-5 flex-1 flex flex-col justify-between gap-4">
          <div>
            <h3 class="font-medium text-foreground text-sm line-clamp-2">
              "{{ t.title }}"
            </h3>
            <p class="text-xs text-muted-foreground mt-1">
              {{ t.email }}
            </p>
          </div>

          <div
            class="flex items-center justify-between pt-3 border-t border-border"
          >
            <span class="text-xs text-muted-foreground">{{
              formatDate(t.created_at)
            }}</span>
            <button
              class="text-xs font-medium text-destructive px-2 py-1 hover:bg-destructive/10 rounded-lg transition-colors"
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
      class="bg-card rounded-xl border border-border shadow-sm overflow-hidden mt-8"
    >
      <div class="px-6 py-4 border-b border-border">
        <h3 class="text-base font-medium text-foreground">
          Outbound Video Requests
        </h3>
      </div>

      <div
        v-if="requests.length === 0"
        class="flex flex-col items-center justify-center py-16 gap-2"
      >
        <div class="p-3 rounded-full bg-primary/10 text-primary">
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
        <p class="text-sm font-medium text-foreground">
          No video requests dispatched
        </p>
      </div>

      <div v-else class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr
              class="bg-muted/40 text-[11px] font-semibold text-muted-foreground uppercase tracking-wider"
            >
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
                    {{
                      req.contact?.phone_number ||
                      req.contact?.email ||
                      'No credentials'
                    }}
                  </span>
                </div>
              </td>
              <td class="px-6 py-4 text-muted-foreground">
                {{ req.reputation_template?.name || 'Custom' }}
              </td>
              <td class="px-6 py-4">
                <span
                  class="px-2 py-0.5 text-[10px] font-semibold rounded-lg uppercase bg-muted text-muted-foreground"
                >
                  {{ req.channel }}
                </span>
              </td>
              <td class="px-6 py-4">
                <span
                  class="px-2 py-0.5 text-[10px] font-semibold rounded-full uppercase"
                  :class="statusColor(req.status)"
                >
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

    <!-- Request Modal -->
    <div
      v-if="showModal"
      class="fixed inset-0 z-50 overflow-y-auto flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm transition-all"
    >
      <div
        class="relative w-full max-w-lg bg-card rounded-xl border border-border shadow-2xl p-6 space-y-5"
      >
        <div
          class="flex items-center justify-between border-b border-border pb-3"
        >
          <h3 class="text-base font-medium text-foreground">
            Send Video Testimonial Request
          </h3>
          <button
            class="p-1 rounded-lg hover:bg-muted text-muted-foreground"
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
            <label class="block text-sm font-medium text-foreground"
              >Customer Email</label>
            <input
              v-model="requestForm.email"
              type="email"
              placeholder="customer@example.com"
              class="w-full rounded-lg border border-border bg-background p-3 text-sm shadow-sm focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
            />
          </div>

          <div class="space-y-1.5">
            <label class="block text-sm font-medium text-foreground"
              >Message Template (Optional)</label>
            <select
              v-model="selectedTemplate"
              class="w-full rounded-lg border border-border bg-background p-3 text-sm shadow-sm focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
              @change="handleTemplateChange"
            >
              <option :value="null">Select a template to autofill...</option>
              <option v-for="t in templates" :key="t.id" :value="t">
                {{ t.name }}
              </option>
            </select>
          </div>

          <div class="space-y-1.5">
            <label class="block text-sm font-medium text-foreground"
              >Email Subject</label>
            <input
              v-model="requestForm.subject"
              type="text"
              class="w-full rounded-lg border border-border bg-background p-3 text-sm shadow-sm focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
            />
          </div>

          <div class="space-y-1.5">
            <label class="block text-sm font-medium text-foreground"
              >Message</label>
            <textarea
              v-model="requestForm.body"
              rows="5"
              class="w-full rounded-lg border border-border bg-background p-3 font-mono text-sm shadow-sm focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/30"
            />
            <p class="text-xs text-muted-foreground mt-1">
              Keep
              <code class="bg-muted px-1 rounded">{{ video_link }}</code>
              in the message, it will be replaced by the real link.
            </p>
          </div>
        </div>

        <div
          class="flex justify-end gap-2 pt-3 border-t border-border"
        >
          <button
            class="rounded-lg border border-border px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted/50 transition-colors"
            @click="showModal = false"
          >
            Cancel
          </button>
          <button
            class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-5 py-2 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90 transition-colors disabled:opacity-50"
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
