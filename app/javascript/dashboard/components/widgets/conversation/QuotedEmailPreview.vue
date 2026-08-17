<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';
import { computed, ref } from 'vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  quotedEmailText: {
    type: String,
    required: true,
  },
  previewText: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['toggle']);

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const isExpanded = ref(false);

const formattedQuotedEmailText = computed(() => {
  if (!props.quotedEmailText) {
    return '';
  }
  return formatMessage(props.quotedEmailText, false, false, true);
});

const toggleExpand = () => {
  isExpanded.value = !isExpanded.value;
};
</script>

<template>
  <div class="mt-2">
    <div
      class="relative rounded-md px-3 py-2 text-xs text-foreground bg-muted dark:bg-accent"
    >
      <div class="absolute top-2 right-2 z-10 flex items-center gap-1">
        <RelayTooltip
          :content="
            isExpanded
              ? t('CONVERSATION.REPLYBOX.QUOTED_REPLY.COLLAPSE')
              : t('CONVERSATION.REPLYBOX.QUOTED_REPLY.EXPAND')
          "
        >
          <NextButton
            ghost
            slate
            xs
            :icon="isExpanded ? 'i-lucide-minimize' : 'i-lucide-maximize'"
            @click="toggleExpand"
          />
        </RelayTooltip>
        <RelayTooltip
          :content="t('CONVERSATION.REPLYBOX.QUOTED_REPLY.REMOVE_PREVIEW')"
        >
          <NextButton
            ghost
            slate
            xs
            icon="i-lucide-x"
            @click="emit('toggle')"
          />
        </RelayTooltip>
      </div>
      <div
        v-dompurify-html="formattedQuotedEmailText"
        class="w-full max-w-none break-words prose prose-sm dark:prose-invert cursor-pointer ltr:pr-8 rtl:pl-8"
        :class="{
          'line-clamp-1': !isExpanded,
          'max-h-60 overflow-y-auto': isExpanded,
        }"
        :title="previewText"
        @click="toggleExpand"
      />
    </div>
  </div>
</template>
