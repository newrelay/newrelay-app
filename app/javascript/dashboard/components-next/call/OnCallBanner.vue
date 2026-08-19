<script setup>
import { computed } from 'vue';
import { useCallActions } from 'dashboard/composables/useCallSession';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    default: null,
  },
});

const {
  activeCall,
  hasActiveCall,
  formattedCallDuration,
  isMuted,
  isCallOverlayExpanded,
  toggleMute,
  setCallOverlayExpanded,
  endCall,
} = useCallActions();

const { t } = useI18n();

const show = computed(
  () =>
    hasActiveCall.value &&
    !isCallOverlayExpanded.value &&
    String(activeCall.value?.conversationId) === String(props.conversationId)
);

const phone = computed(() => activeCall.value?.caller?.phone || '');

const handleEnd = () => {
  const call = activeCall.value;
  if (!call?.callSid) return;
  endCall({
    conversationId: call.conversationId,
    inboxId: call.inboxId,
    callSid: call.callSid,
  });
};
</script>

<template>
  <div
    v-if="show"
    class="flex w-full shrink-0 items-center justify-between border-b border-emerald-500/20 bg-emerald-500/5 px-6 py-2.5 shadow-sm"
  >
    <button
      type="button"
      class="flex min-w-0 items-center gap-3"
      @click="setCallOverlayExpanded(true)"
    >
      <div
        class="flex size-7 shrink-0 items-center justify-center rounded-full bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
      >
        <span class="i-lucide-phone size-3.5 fill-current" />
      </div>
      <div
        class="flex items-center gap-2 text-[13px] font-medium text-foreground"
      >
        <span>{{ t('CONVERSATION.VOICE_WIDGET.ON_CALL') }}</span>
        <span class="text-muted-foreground">{{
          t('CONVERSATION.VOICE_WIDGET.ON_CALL_SEPARATOR')
        }}</span>
        <span
          class="font-semibold tabular-nums text-emerald-600 dark:text-emerald-400"
        >
          {{ formattedCallDuration }}
        </span>
        <span v-if="phone" class="ml-1 hidden text-muted-foreground sm:inline">
          {{ t('CONVERSATION.VOICE_WIDGET.ON_CALL_PHONE_SEPARATOR') }}
          {{ phone }}
        </span>
      </div>
    </button>

    <div class="flex shrink-0 items-center gap-2">
      <button
        type="button"
        class="flex items-center gap-1.5 rounded-full px-3 py-1.5 text-[12px] font-medium transition-colors"
        :class="
          isMuted
            ? 'bg-amber-500/10 text-amber-500 hover:bg-amber-500/20'
            : 'text-emerald-600 hover:bg-emerald-500/10 dark:text-emerald-400'
        "
        @click="toggleMute"
      >
        <span
          class="size-3.5"
          :class="isMuted ? 'i-lucide-mic-off' : 'i-lucide-mic'"
        />
        <span>
          {{
            isMuted
              ? t('CONVERSATION.VOICE_WIDGET.UNMUTE')
              : t('CONVERSATION.VOICE_WIDGET.MUTE')
          }}
        </span>
      </button>
      <button
        type="button"
        class="flex items-center gap-1.5 rounded-full border border-destructive/20 bg-destructive/10 px-3 py-1.5 text-[12px] font-medium text-destructive transition-colors hover:border-destructive/30 hover:bg-destructive/20"
        @click="handleEnd"
      >
        <span class="i-lucide-phone size-3.5 rotate-[135deg]" />
        <span>{{ t('CONVERSATION.VOICE_WIDGET.END_CALL') }}</span>
      </button>
    </div>
  </div>
</template>
