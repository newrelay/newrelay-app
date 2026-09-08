<script setup>
import { useI18n } from 'vue-i18n';
import { computed, ref } from 'vue';
import LinkIssue from './LinkIssue.vue';
import CreateIssue from './CreateIssue.vue';

const props = defineProps({
  accountId: {
    type: [Number, String],
    required: true,
  },
  conversation: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();

const selectedTabIndex = ref(0);

const title = computed(() => {
  const { meta: { sender: { name = null } = {} } = {} } = props.conversation;
  return t('INTEGRATION_SETTINGS.LINEAR.LINK.LINK_TITLE', {
    conversationId: props.conversation.id,
    name,
  });
});

const tabs = ref([
  {
    key: 0,
    name: t('INTEGRATION_SETTINGS.LINEAR.CREATE'),
  },
  {
    key: 1,
    name: t('INTEGRATION_SETTINGS.LINEAR.LINK.TITLE'),
  },
]);
const onClose = () => {
  emit('close');
};

const onClickTabChange = index => {
  selectedTabIndex.value = index;
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex gap-6 border-b border-border" role="tablist">
      <button
        v-for="(tab, index) in tabs"
        :key="tab.key"
        type="button"
        role="tab"
        :aria-selected="selectedTabIndex === index"
        class="relative -mb-px px-1 pb-2.5 text-sm font-medium transition-colors"
        :class="
          selectedTabIndex === index
            ? 'text-foreground'
            : 'text-muted-foreground hover:text-foreground'
        "
        @click="onClickTabChange(index)"
      >
        {{ tab.name }}
        <span
          v-if="selectedTabIndex === index"
          class="absolute inset-x-0 bottom-0 h-0.5 bg-primary"
          aria-hidden="true"
        />
      </button>
    </div>
    <CreateIssue
      v-if="selectedTabIndex === 0"
      :account-id="accountId"
      :conversation-id="conversation.id"
      :title="title"
      @close="onClose"
    />
    <LinkIssue
      v-else
      :conversation-id="conversation.id"
      :title="title"
      @close="onClose"
    />
  </div>
</template>
