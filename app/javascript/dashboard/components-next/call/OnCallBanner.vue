<script setup>
import { computed } from 'vue';
import { useCallActions } from 'dashboard/composables/useCallSession';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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

// Only surface the bar in the conversation the live call belongs to, and only
// while the immersive overlay is minimized (otherwise the overlay is showing).
const show = computed(
  () =>
    hasActiveCall.value &&
    !isCallOverlayExpanded.value &&
    String(activeCall.value?.conversationId) === String(props.conversationId)
);

const phone = computed(() => activeCall.value?.caller?.phone || '');

const handleEnd = () => {
  const call = activeCall.value;
  if (!call?.inboxId || !call?.callSid) return;
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
    class="flex justify-between items-center px-6 py-2.5 w-full border-b shadow-sm shrink-0 bg-success/5 border-success/20"
  >
    <button
      class="flex gap-3 items-center min-w-0"
      @click="setCallOverlayExpanded(true)"
    >
      <div
        class="flex justify-center items-center rounded-full size-7 bg-success/15 text-success shrink-0"
      >
        <Icon class="size-3.5" icon="i-ph-phone-fill" />
      </div>
      <div
        class="flex gap-2 items-center text-[13px] font-medium text-foreground"
      >
        <span>{{ $t('CONVERSATION.VOICE_WIDGET.ON_CALL') }} &bull;</span>
        <span class="font-semibold tabular-nums text-success">
          {{ formattedCallDuration }}
        </span>
        <span v-if="phone" class="hidden ml-1 text-muted-foreground sm:inline">
          | {{ phone }}
        </span>
      </div>
    </button>

    <div class="flex gap-2 items-center shrink-0">
      <button
        class="flex gap-1.5 items-center px-3 py-1.5 rounded-full text-[12px] font-medium transition-colors"
        :class="
          isMuted
            ? 'bg-warning/10 text-warning hover:bg-warning/20'
            : 'text-success hover:bg-success/10'
        "
        @click="toggleMute"
      >
        <Icon
          class="size-3.5"
          :icon="
            isMuted ? 'i-ph-microphone-slash-bold' : 'i-ph-microphone-bold'
          "
        />
        <span>
          {{
            isMuted
              ? $t('CONVERSATION.VOICE_WIDGET.UNMUTE')
              : $t('CONVERSATION.VOICE_WIDGET.MUTE')
          }}
        </span>
      </button>
      <button
        class="flex gap-1.5 items-center px-3 py-1.5 rounded-full border text-[12px] font-medium transition-colors bg-destructive/10 text-destructive border-destructive/20 hover:bg-destructive/20 hover:border-destructive/30"
        @click="handleEnd"
      >
        <Icon class="size-3.5 rotate-[135deg]" icon="i-ph-phone-bold" />
        <span>{{ $t('CONVERSATION.VOICE_WIDGET.END_CALL') }}</span>
      </button>
    </div>
  </div>
</template>
