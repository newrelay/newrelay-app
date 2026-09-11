<script setup>
import { computed, onBeforeUnmount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { VOICE_CALL_DIRECTION } from 'dashboard/components-next/message/constants';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  call: {
    type: Object,
    required: true,
  },
  callInfo: {
    type: Object,
    required: true,
  },
  state: {
    type: String,
    required: true,
  },
  duration: {
    type: String,
    default: '',
  },
  isMuted: {
    type: Boolean,
    default: false,
  },
  showMute: {
    type: Boolean,
    default: false,
  },
  widgetPos: {
    type: Object,
    default: () => ({ x: 0, y: 0 }),
  },
});

const emit = defineEmits([
  'accept',
  'reject',
  'end',
  'toggleMute',
  'goToConversation',
  'update:widgetPos',
]);

const { t } = useI18n();

const isOngoing = computed(() => props.state === VOICE_CALL_DIRECTION.ONGOING);
const isIncoming = computed(
  () => props.state === VOICE_CALL_DIRECTION.INCOMING
);

const isDragging = ref(false);
const dragOffset = ref({ x: 0, y: 0 });

const widgetStyle = computed(() => ({
  transform: `translate(${props.widgetPos.x}px, ${props.widgetPos.y}px)`,
}));

const onDrag = event => {
  emit('update:widgetPos', {
    x: event.clientX - dragOffset.value.x,
    y: event.clientY - dragOffset.value.y,
  });
};

const onDragEnd = () => {
  isDragging.value = false;
  document.removeEventListener('mousemove', onDrag);
  document.removeEventListener('mouseup', onDragEnd);
};

const onDragStart = event => {
  isDragging.value = true;
  dragOffset.value = {
    x: event.clientX - props.widgetPos.x,
    y: event.clientY - props.widgetPos.y,
  };
  document.addEventListener('mousemove', onDrag);
  document.addEventListener('mouseup', onDragEnd);
};

onBeforeUnmount(onDragEnd);
</script>

<template>
  <div
    class="fixed bottom-6 right-6 z-[300] w-[320px] animate-in slide-in-from-bottom-5 rounded-2xl border border-border bg-background p-4 shadow-xl duration-300"
    :class="isDragging ? 'cursor-grabbing' : ''"
    :style="widgetStyle"
  >
    <div
      class="mb-4 flex select-none items-center justify-between"
      :class="isOngoing ? 'cursor-grab' : ''"
      @mousedown="isOngoing ? onDragStart($event) : null"
    >
      <div class="flex items-center gap-2">
        <div
          class="flex size-8 items-center justify-center rounded-full bg-emerald-100 text-emerald-600 dark:bg-emerald-900/40 dark:text-emerald-400"
        >
          <span class="i-ri-phone-fill size-4" />
        </div>
        <span
          class="text-[10px] font-bold uppercase tracking-wider text-emerald-600 dark:text-emerald-400"
        >
          {{ t('CONVERSATION.VOICE_WIDGET.CALL_IN_PROGRESS') }}
        </span>
      </div>
      <span
        v-if="isOngoing"
        class="text-lg font-semibold tabular-nums text-foreground"
      >
        {{ duration }}
      </span>
      <span
        v-else-if="isIncoming"
        class="text-[10px] font-bold uppercase tracking-wider text-amber-500"
      >
        {{ t('CONVERSATION.VOICE_WIDGET.INCOMING_CALL') }}
      </span>
    </div>

    <div class="mb-4 flex items-center gap-3">
      <Avatar
        :src="callInfo.avatar"
        :name="callInfo.contactName"
        :size="40"
        rounded-full
      />
      <div class="min-w-0 flex-1">
        <p class="truncate text-[14px] font-semibold text-foreground">
          {{ callInfo.contactName }}
        </p>
        <p class="truncate text-[12px] text-muted-foreground">
          {{ callInfo.phoneNumber }}
        </p>
      </div>

      <div class="flex shrink-0 items-center gap-2">
        <button
          v-if="isIncoming"
          type="button"
          class="flex size-9 items-center justify-center rounded-lg bg-emerald-500 text-white transition-colors hover:bg-emerald-600"
          :aria-label="t('CONVERSATION.VOICE_WIDGET.ACCEPT_CALL')"
          @click="emit('accept')"
        >
          <span class="i-lucide-phone size-4" />
        </button>

        <button
          v-if="isOngoing && showMute"
          type="button"
          class="flex size-9 items-center justify-center rounded-lg bg-muted text-foreground transition-colors hover:bg-muted/80"
          :aria-label="
            isMuted
              ? t('CONVERSATION.VOICE_WIDGET.UNMUTE')
              : t('CONVERSATION.VOICE_WIDGET.MUTE')
          "
          @click="emit('toggleMute')"
        >
          <span
            class="size-4"
            :class="isMuted ? 'i-lucide-mic-off' : 'i-lucide-mic'"
          />
        </button>

        <button
          type="button"
          class="flex size-9 items-center justify-center rounded-lg bg-destructive text-white transition-colors hover:bg-destructive/90"
          :aria-label="
            isOngoing
              ? t('CONVERSATION.VOICE_WIDGET.END_CALL')
              : t('CONVERSATION.VOICE_WIDGET.DECLINE_CALL')
          "
          @click="isOngoing ? emit('end') : emit('reject')"
        >
          <span class="i-lucide-phone size-4 rotate-[135deg]" />
        </button>
      </div>
    </div>

    <template v-if="call?.conversationId">
      <div class="mb-3 h-px w-full bg-border/60" />
      <button
        type="button"
        class="group flex w-full items-center justify-between rounded-lg px-3 py-2 transition-colors hover:bg-muted/50"
        @click="emit('goToConversation')"
      >
        <span class="flex items-center gap-2 text-primary">
          <span class="i-lucide-message-square size-4" />
          <span class="text-[13px] font-medium">
            {{ t('CONVERSATION.VOICE_WIDGET.GO_TO_CONVERSATION') }}
          </span>
        </span>
        <span
          class="i-lucide-chevron-right size-4 text-muted-foreground transition-colors group-hover:text-foreground"
        />
      </button>
    </template>
  </div>
</template>
