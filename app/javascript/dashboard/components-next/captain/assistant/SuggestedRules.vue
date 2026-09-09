<script setup>
import { useI18n } from 'vue-i18n';
import { RelayButton } from 'dashboard/components-next/relay';
import { RELAY_MODAL_CLOSE_BUTTON_CLASS } from 'dashboard/components-next/relay/modal/constants';

defineProps({
  title: {
    type: String,
    default: '',
  },
  items: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['add', 'close']);

const { t } = useI18n();

const onAddClick = () => {
  emit('add');
};

const onClickClose = () => {
  emit('close');
};
</script>

<template>
  <div
    class="relative flex w-full flex-col items-start space-y-4 rounded-2xl border border-border/70 bg-card p-5 shadow-xs"
  >
    <div
      class="flex w-full items-center justify-between gap-3 border-b border-border/40 pb-3"
    >
      <div class="flex items-center gap-3">
        <span class="text-[13.5px] font-semibold text-foreground">{{
          title
        }}</span>
        <RelayButton
          variant="link"
          size="sm"
          class="h-auto flex-shrink-0 !px-0 !text-[12.5px] font-medium text-primary"
          @click="onAddClick"
        >
          {{ t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.SUGGESTED.ADD') }}
        </RelayButton>
      </div>
      <button
        type="button"
        :class="RELAY_MODAL_CLOSE_BUTTON_CLASS"
        @click="onClickClose"
      >
        <span class="i-lucide-x size-4" />
      </button>
    </div>
    <div class="flex w-full flex-col items-start gap-3">
      <div
        v-for="item in items"
        :key="item.content || item.id || item.title"
        class="w-full"
      >
        <slot :item="item" />
      </div>
    </div>
  </div>
</template>
