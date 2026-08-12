<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { picoSearch } from '@scmmishra/pico-search';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  inboxList: {
    type: Array,
    default: () => [],
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['delete', 'add', 'update']);

const inboxCapacityLimits = defineModel('inboxCapacityLimits', {
  type: Array,
  default: () => [],
});

const { t } = useI18n();

const BASE_KEY = 'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY';
const DEFAULT_CONVERSATION_LIMIT = 10;
const MIN_CONVERSATION_LIMIT = 0;
const MAX_CONVERSATION_LIMIT = 100000;

const showInboxDropdown = ref(false);
const inboxSearch = ref('');

const selectedInboxIds = computed(
  () => new Set(inboxCapacityLimits.value.map(limit => limit.inboxId))
);

const availableInboxes = computed(() =>
  props.inboxList.filter(
    inbox => inbox && !selectedInboxIds.value.has(inbox.id)
  )
);

const filteredInboxes = computed(() => {
  if (!inboxSearch.value) return availableInboxes.value;
  return picoSearch(availableInboxes.value, inboxSearch.value.toLowerCase(), [
    'name',
  ]);
});

const isLimitValid = limit => {
  return (
    Number.isInteger(limit.conversationLimit) &&
    limit.conversationLimit >= MIN_CONVERSATION_LIMIT &&
    limit.conversationLimit <= MAX_CONVERSATION_LIMIT
  );
};

const inboxMap = computed(
  () => new Map(props.inboxList.map(inbox => [inbox.id, inbox]))
);

const handleAddInbox = inbox => {
  emit('add', {
    inboxId: inbox.id,
    conversationLimit: DEFAULT_CONVERSATION_LIMIT,
  });
  showInboxDropdown.value = false;
  inboxSearch.value = '';
};

const handleRemoveLimit = limitId => {
  emit('delete', limitId);
};

const handleLimitChange = limit => {
  if (isLimitValid(limit)) {
    emit('update', limit);
  }
};

const getInboxName = inboxId => {
  return inboxMap.value.get(inboxId)?.name || '';
};

const closeInboxDropdown = () => {
  showInboxDropdown.value = false;
};
</script>

<template>
  <div class="space-y-2 border-t border-border/40 pt-2">
    <label class="block text-[13.5px] font-medium text-foreground">
      {{ t(`${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.LABEL`) }}
    </label>

    <div v-if="isFetching" class="py-3 text-[13px] text-muted-foreground">
      {{ t(`${BASE_KEY}.INDEX.LOADING`) }}
    </div>

    <div
      v-else-if="inboxCapacityLimits.length"
      class="mb-2 flex flex-col gap-2"
    >
      <div
        v-for="(limit, index) in inboxCapacityLimits"
        :key="limit.id || `temp-${index}`"
        class="flex flex-wrap items-center gap-2"
      >
        <span
          class="inline-flex items-center gap-1.5 rounded-md border border-border/60 bg-accent px-2.5 py-1 text-[12px] font-medium text-foreground"
        >
          {{ getInboxName(limit.inboxId) }}
          <button
            type="button"
            class="text-muted-foreground hover:text-destructive"
            @click="handleRemoveLimit(limit.id)"
          >
            <Icon icon="i-lucide-x" class="size-3.5" />
          </button>
        </span>
        <div class="flex items-center gap-2">
          <label class="whitespace-nowrap text-[12px] text-muted-foreground">
            {{
              t(`${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.FIELD.MAX_CONVERSATIONS`)
            }}
          </label>
          <input
            v-model.number="limit.conversationLimit"
            type="number"
            :min="MIN_CONVERSATION_LIMIT"
            :max="MAX_CONVERSATION_LIMIT"
            :placeholder="
              t(`${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.FIELD.SET_LIMIT`)
            "
            class="h-8 w-24 rounded-md border border-border/80 bg-background px-2 text-[13px] text-foreground shadow-sm outline-none placeholder:text-muted-foreground focus:ring-1 focus:ring-primary/30"
            :class="{
              'border-destructive text-destructive': !isLimitValid(limit),
            }"
            @blur="handleLimitChange(limit)"
          />
        </div>
      </div>
    </div>

    <div v-on-click-outside="closeInboxDropdown" class="relative">
      <RelayButton
        type="button"
        variant="outline"
        class="h-9 w-full justify-start border-border/80 bg-background text-[13px] font-medium text-muted-foreground shadow-sm hover:bg-muted/50"
        @click="showInboxDropdown = !showInboxDropdown"
      >
        <Icon icon="i-lucide-plus" class="size-3.5" />
        {{ t(`${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.ADD_BUTTON`) }}
      </RelayButton>
      <div
        v-if="showInboxDropdown"
        class="absolute left-0 right-0 top-full z-50 mt-1 overflow-hidden rounded-md border border-border/60 bg-card shadow-lg"
      >
        <div class="relative border-b border-border/40 p-2">
          <Icon
            icon="i-lucide-search"
            class="absolute left-4 top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground"
          />
          <input
            v-model="inboxSearch"
            type="text"
            class="w-full rounded-md bg-muted/50 py-1.5 pl-8 pr-3 text-[13px] text-foreground outline-none placeholder:text-muted-foreground"
            :placeholder="
              t(`${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.FIELD.SELECT_INBOX`)
            "
          />
        </div>
        <ul class="max-h-40 overflow-y-auto p-1">
          <li
            v-for="inbox in filteredInboxes"
            :key="inbox.id"
            class="flex cursor-pointer items-center justify-between rounded-sm px-3 py-2 text-[13px] text-foreground hover:bg-accent"
            @click="handleAddInbox(inbox)"
          >
            <span class="flex items-center gap-2 truncate">
              <Icon
                v-if="inbox.icon"
                :icon="inbox.icon"
                class="size-3.5 shrink-0 text-muted-foreground"
              />
              {{ inbox.name }}
            </span>
          </li>
          <li
            v-if="!filteredInboxes.length"
            class="px-3 py-2 text-[13px] text-muted-foreground"
          >
            {{ t(`${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.EMPTY_STATE`) }}
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
