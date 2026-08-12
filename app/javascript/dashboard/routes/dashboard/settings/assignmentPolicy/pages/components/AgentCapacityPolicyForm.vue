<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import ExclusionRules from 'dashboard/components-next/AssignmentPolicy/components/ExclusionRules.vue';
import InboxCapacityLimits from 'dashboard/components-next/AssignmentPolicy/components/InboxCapacityLimits.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'next/avatar/Avatar.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';

const props = defineProps({
  initialData: {
    type: Object,
    default: () => ({
      name: '',
      description: '',
      enabled: false,
      exclusionRules: {
        excludedLabels: [],
        excludeOlderThanHours: null,
      },
      inboxCapacityLimits: [],
    }),
  },
  mode: {
    type: String,
    required: true,
    validator: value => ['CREATE', 'EDIT'].includes(value),
  },
  policyUsers: {
    type: Array,
    default: () => [],
  },
  agentList: {
    type: Array,
    default: () => [],
  },
  labelList: {
    type: Array,
    default: () => [],
  },
  inboxList: {
    type: Array,
    default: () => [],
  },
  showUserSection: {
    type: Boolean,
    default: false,
  },
  showInboxLimitSection: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  isUsersLoading: {
    type: Boolean,
    default: false,
  },
  isInboxesLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'submit',
  'cancel',
  'addUser',
  'deleteUser',
  'deleteInboxLimit',
  'addInboxLimit',
  'updateInboxLimit',
]);

const { t } = useI18n();

const BASE_KEY = 'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY';

const state = reactive({
  name: '',
  description: '',
  exclusionRules: {
    excludedLabels: [],
    excludeOlderThanHours: null,
  },
  inboxCapacityLimits: [],
});

const nameTouched = ref(false);
const showAgentDropdown = ref(false);
const agentSearch = ref('');

const isNameValid = computed(() => state.name.trim().length > 0);

const buttonLabel = computed(() =>
  t(`${BASE_KEY}.${props.mode.toUpperCase()}.${props.mode}_BUTTON`)
);

const filteredAgents = computed(() => {
  const query = agentSearch.value.trim().toLowerCase();
  if (!query) return props.agentList;
  return props.agentList.filter(
    agent =>
      agent.name?.toLowerCase().includes(query) ||
      agent.email?.toLowerCase().includes(query)
  );
});

const handleDeleteInboxLimit = id => {
  emit('deleteInboxLimit', id);
};

const handleAddInboxLimit = limit => {
  emit('addInboxLimit', limit);
};

const handleLimitChange = limit => {
  emit('updateInboxLimit', limit);
};

const handleAddAgent = agent => {
  emit('addUser', agent);
  showAgentDropdown.value = false;
  agentSearch.value = '';
};

const closeAgentDropdown = () => {
  showAgentDropdown.value = false;
};

const resetForm = () => {
  Object.assign(state, {
    name: '',
    description: '',
    exclusionRules: {
      excludedLabels: [],
      excludeOlderThanHours: null,
    },
    inboxCapacityLimits: [],
  });
  nameTouched.value = false;
};

const handleSubmit = () => {
  nameTouched.value = true;
  if (!isNameValid.value) return;
  emit('submit', { ...state });
};

watch(
  () => props.initialData,
  newData => {
    Object.assign(state, newData);
  },
  { immediate: true, deep: true }
);

defineExpose({
  resetForm,
});
</script>

<template>
  <form class="flex w-full flex-col" @submit.prevent="handleSubmit">
    <div class="flex-1 space-y-6 overflow-y-auto p-5">
      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="capacity-policy-name"
          class="text-[13.5px] font-medium text-foreground"
        >
          {{ t(`${BASE_KEY}.FORM.NAME.LABEL`) }}
        </RelayLabel>
        <RelayInput
          id="capacity-policy-name"
          v-model="state.name"
          type="text"
          :placeholder="t(`${BASE_KEY}.FORM.NAME.PLACEHOLDER`)"
          class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
          @blur="nameTouched = true"
        />
        <p v-if="nameTouched && !isNameValid" class="text-xs text-destructive">
          {{ t(`${BASE_KEY}.FORM.NAME.ERROR`) }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="capacity-policy-description"
          class="text-[13.5px] font-medium text-foreground"
        >
          {{ t(`${BASE_KEY}.FORM.DESCRIPTION.LABEL`) }}
          <span class="font-normal text-muted-foreground">
            {{ t(`${BASE_KEY}.FORM.DESCRIPTION.OPTIONAL`) }}
          </span>
        </RelayLabel>
        <RelayInput
          id="capacity-policy-description"
          v-model="state.description"
          type="text"
          :placeholder="t(`${BASE_KEY}.FORM.DESCRIPTION.PLACEHOLDER`)"
          class-name="h-10 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
        />
      </div>

      <ExclusionRules
        v-model:excluded-labels="state.exclusionRules.excludedLabels"
        v-model:exclude-older-than-minutes="
          state.exclusionRules.excludeOlderThanHours
        "
        :tags-list="labelList"
      />

      <InboxCapacityLimits
        v-if="showInboxLimitSection"
        v-model:inbox-capacity-limits="state.inboxCapacityLimits"
        :inbox-list="inboxList"
        :is-fetching="isInboxesLoading"
        @delete="handleDeleteInboxLimit"
        @add="handleAddInboxLimit"
        @update="handleLimitChange"
      />

      <div
        v-if="showUserSection"
        class="space-y-2 border-t border-border/40 pt-2"
      >
        <label class="block text-[13.5px] font-medium text-foreground">
          {{ t(`${BASE_KEY}.FORM.USERS.LABEL`) }}
        </label>

        <div
          v-if="isUsersLoading"
          class="py-3 text-[13px] text-muted-foreground"
        >
          {{ t(`${BASE_KEY}.INDEX.LOADING`) }}
        </div>

        <div v-else-if="policyUsers.length" class="mb-2 flex flex-wrap gap-2">
          <span
            v-for="agent in policyUsers"
            :key="agent.id"
            class="inline-flex items-center gap-1.5 rounded-md border border-border/60 bg-accent py-1 pl-1 pr-2.5 text-[12px] font-medium text-foreground"
          >
            <Avatar
              :title="agent.name"
              :src="agent.avatarUrl"
              :name="agent.name"
              :size="20"
              rounded-full
            />
            {{ agent.name }}
            <button
              type="button"
              class="ml-1 text-muted-foreground hover:text-destructive"
              @click="emit('deleteUser', agent.id)"
            >
              <Icon icon="i-lucide-x" class="size-3.5" />
            </button>
          </span>
        </div>

        <div v-on-click-outside="closeAgentDropdown" class="relative">
          <RelayButton
            type="button"
            variant="outline"
            class="h-9 w-full justify-start border-border/80 bg-background text-[13px] font-medium text-muted-foreground shadow-sm hover:bg-muted/50"
            @click="showAgentDropdown = !showAgentDropdown"
          >
            <Icon icon="i-lucide-plus" class="size-3.5" />
            {{ t(`${BASE_KEY}.FORM.USERS.ADD_BUTTON`) }}
          </RelayButton>
          <div
            v-if="showAgentDropdown"
            class="absolute bottom-full left-0 right-0 z-50 mb-1 overflow-hidden rounded-md border border-border/60 bg-card shadow-lg"
          >
            <div class="relative border-b border-border/40 p-2">
              <Icon
                icon="i-lucide-search"
                class="absolute left-4 top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground"
              />
              <input
                v-model="agentSearch"
                type="text"
                class="w-full rounded-md bg-muted/50 py-1.5 pl-8 pr-3 text-[13px] text-foreground outline-none placeholder:text-muted-foreground"
                :placeholder="
                  t(`${BASE_KEY}.FORM.USERS.DROPDOWN.SEARCH_PLACEHOLDER`)
                "
              />
            </div>
            <ul class="max-h-40 overflow-y-auto p-1">
              <li
                v-for="agent in filteredAgents"
                :key="agent.id"
                class="flex cursor-pointer items-center gap-3 rounded-sm px-3 py-2 text-[13px] text-foreground hover:bg-accent"
                @click="handleAddAgent(agent)"
              >
                <Avatar
                  :title="agent.name"
                  :src="agent.avatarUrl"
                  :name="agent.name"
                  :size="24"
                  rounded-full
                />
                <div class="min-w-0 flex-1">
                  <p class="truncate font-medium">{{ agent.name }}</p>
                  <p
                    v-if="agent.email"
                    class="truncate text-[11px] text-muted-foreground"
                  >
                    {{ agent.email }}
                  </p>
                </div>
              </li>
              <li
                v-if="!filteredAgents.length"
                class="px-3 py-2 text-[13px] text-muted-foreground"
              >
                {{ t(`${BASE_KEY}.FORM.USERS.EMPTY_STATE`) }}
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>

    <div
      class="flex justify-end gap-3 border-t border-border/40 bg-background/50 p-5"
    >
      <RelayButton type="button" variant="outline" @click="emit('cancel')">
        {{ t(`${BASE_KEY}.FORM.CANCEL_BUTTON`) }}
      </RelayButton>
      <RelayButton type="submit" :disabled="!isNameValid || isLoading">
        {{ buttonLabel }}
      </RelayButton>
    </div>
  </form>
</template>
