<!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
<script setup>
/* eslint-disable */
import { ref, computed, onMounted } from 'vue';
import { Users, Plus, X } from 'lucide-vue-next';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAlert } from 'dashboard/composables';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  listingId: { type: [String, Number], required: true },
  accountId: { type: [String, Number], required: true },
});

const { isAdmin } = useAdmin();
const axios = window.axios;
const members = ref([]);
const agents = ref([]);
const loading = ref(true);
const busyId = ref(null);

const membersUrl = computed(
  () =>
    `/api/v1/accounts/${props.accountId}/reputation/listings/${props.listingId}/members`
);

const availableAgents = computed(() => {
  const taken = new Set(members.value.map(m => m.id));
  return agents.value.filter(a => !taken.has(a.id));
});

const load = async () => {
  loading.value = true;
  try {
    const requests = [axios.get(membersUrl.value)];
    if (isAdmin.value) {
      requests.push(axios.get(`/api/v1/accounts/${props.accountId}/agents`));
    }
    const [memberRes, agentRes] = await Promise.all(requests);
    members.value = memberRes.data || [];
    agents.value = agentRes?.data || [];
  } catch (error) {
    useAlert(error?.response?.data?.error || 'Could not load listing members');
  } finally {
    loading.value = false;
  }
};

const addMember = async userId => {
  busyId.value = userId;
  try {
    await axios.post(membersUrl.value, { user_id: userId });
    await load();
  } catch (error) {
    useAlert(error?.response?.data?.error || 'Could not add member');
  } finally {
    busyId.value = null;
  }
};

const removeMember = async userId => {
  busyId.value = userId;
  try {
    await axios.delete(`${membersUrl.value}/${userId}`);
    await load();
  } catch (error) {
    useAlert(error?.response?.data?.error || 'Could not remove member');
  } finally {
    busyId.value = null;
  }
};

onMounted(load);
</script>

<template>
  <div class="flex flex-col gap-6 pb-12">
    <div>
      <h2 class="text-base font-semibold text-foreground flex items-center gap-2">
        <Users class="size-5 text-primary" />
        Team
      </h2>
      <p class="text-[13px] text-muted-foreground mt-1">
        People assigned to this listing. They only see this business in Reputation.
      </p>
    </div>

    <div
      v-if="loading"
      class="bg-card border border-border rounded-xl p-10 text-center text-sm text-muted-foreground"
    >
      Loading members…
    </div>

    <div
      v-else-if="!members.length"
      class="bg-card border border-dashed border-border rounded-xl p-10 text-center"
    >
      <Users class="size-8 mx-auto text-muted-foreground mb-3" />
      <p class="text-base font-medium text-foreground">No one assigned yet</p>
      <p class="text-sm text-muted-foreground mt-1">
        An administrator can add a teammate below.
      </p>
    </div>

    <div v-else class="bg-card border border-border rounded-xl divide-y divide-border">
      <div
        v-for="member in members"
        :key="member.id"
        class="flex items-center justify-between gap-3 px-5 py-3"
      >
        <div class="min-w-0">
          <p class="text-[14px] font-medium text-foreground truncate">
            {{ member.available_name || member.name }}
          </p>
          <p class="text-[12px] text-muted-foreground truncate">{{ member.email }}</p>
        </div>
        <RelayButton
          v-if="isAdmin"
          variant="ghost"
          class="border border-border hover:border-transparent h-8 px-2"
          :disabled="busyId === member.id"
          @click="removeMember(member.id)"
        >
          <X class="size-4" />
        </RelayButton>
      </div>
    </div>

    <div v-if="isAdmin && availableAgents.length" class="flex flex-col gap-3">
      <p class="text-[13.5px] font-medium text-foreground">Add teammate</p>
      <div class="flex flex-col gap-2">
        <button
          v-for="agent in availableAgents"
          :key="agent.id"
          type="button"
          class="flex items-center justify-between gap-3 px-4 py-2.5 rounded-md border border-border bg-card text-left hover:bg-accent hover:text-accent-foreground"
          :disabled="busyId === agent.id"
          @click="addMember(agent.id)"
        >
          <span class="text-[13.5px] font-medium truncate">{{
            agent.available_name || agent.name
          }}</span>
          <Plus class="size-4 shrink-0" />
        </button>
      </div>
    </div>
  </div>
</template>
