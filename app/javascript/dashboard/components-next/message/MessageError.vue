<script setup>
import { computed } from 'vue';
import Icon from 'next/icon/Icon.vue';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from './provider.js';
import { hasOneDayPassed } from 'shared/helpers/timeHelper';
import { ORIENTATION, MESSAGE_STATUS } from './constants';

defineProps({
  error: { type: String, required: true },
});

const emit = defineEmits(['retry']);

const { orientation, status, createdAt, content, attachments, isInboxView } =
  useMessageContext();

const { t } = useI18n();

const canRetry = computed(() => {
  const hasContent = content.value !== null;
  const hasAttachments = attachments.value && attachments.value.length > 0;
  return !hasOneDayPassed(createdAt.value) && (hasContent || hasAttachments);
});
</script>

<template>
  <div
    class="flex items-center gap-1.5 text-destructive"
    :class="isInboxView?.value ? 'gap-2 text-[13px]' : 'text-xs'"
  >
    <span>{{ t('CHAT_LIST.FAILED_TO_SEND') }}</span>
    <div class="relative group">
      <div
        class="grid cursor-pointer place-content-center"
        :class="
          isInboxView?.value
            ? 'size-[22px] rounded-full bg-destructive/10'
            : 'size-5 rounded-md bg-accent'
        "
      >
        <Icon
          icon="i-lucide-alert-triangle"
          class="text-destructive"
          :class="isInboxView?.value ? 'size-3' : 'size-[14px]'"
        />
      </div>
      <div
        class="absolute bg-accent px-4 py-3 border rounded-xl border-border text-foreground bottom-6 w-52 text-xs backdrop-blur-[100px] shadow-[0px_0px_24px_0px_rgba(0,0,0,0.12)] opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all break-all"
        :class="{
          'ltr:left-0 rtl:right-0': orientation === ORIENTATION.LEFT,
          'ltr:right-0 rtl:left-0': orientation === ORIENTATION.RIGHT,
        }"
      >
        {{ error }}
      </div>
    </div>
    <button
      v-if="canRetry"
      type="button"
      :disabled="status !== MESSAGE_STATUS.FAILED"
      class="grid cursor-pointer place-content-center transition-colors"
      :class="
        isInboxView?.value
          ? 'size-[22px] rounded-full bg-destructive/10 hover:bg-destructive/20'
          : 'size-5 rounded-md bg-accent'
      "
      @click="emit('retry')"
    >
      <Icon
        icon="i-lucide-refresh-ccw"
        class="text-destructive"
        :class="isInboxView?.value ? 'size-3' : 'size-[14px]'"
      />
    </button>
  </div>
</template>
