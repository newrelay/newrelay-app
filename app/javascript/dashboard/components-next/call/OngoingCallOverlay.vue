<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { VOICE_CALL_DIRECTION } from 'dashboard/components-next/message/constants';
import CallOverlayAvatar from 'dashboard/components-next/call/CallOverlayAvatar.vue';
import CallQuickNoteWidget from 'dashboard/components-next/call/CallQuickNoteWidget.vue';

const props = defineProps({
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
  isSpeakerOn: {
    type: Boolean,
    default: false,
  },
  isNoteModalOpen: {
    type: Boolean,
    default: false,
  },
  noteText: {
    type: String,
    default: '',
  },
});

const emit = defineEmits([
  'end',
  'toggleMute',
  'toggleSpeaker',
  'triggerNote',
  'closeNote',
  'saveNote',
  'update:noteText',
  'minimize',
]);

const { t } = useI18n();

const isOngoing = computed(() => props.state === VOICE_CALL_DIRECTION.ONGOING);

const statusDotClass = computed(() =>
  isOngoing.value ? 'bg-emerald-500' : 'bg-amber-500'
);

const statusTextClass = computed(() =>
  isOngoing.value ? 'text-emerald-600 dark:text-emerald-400' : 'text-amber-500'
);

const statusLabel = computed(() => {
  if (isOngoing.value) return props.duration;
  return t('CONVERSATION.VOICE_WIDGET.RINGING');
});
</script>

<template>
  <div
    class="fixed inset-0 z-[400] flex animate-in fade-in items-center justify-center bg-background/80 p-4 backdrop-blur-md duration-300 sm:p-8"
    @click.self="emit('minimize')"
  >
    <div
      class="pointer-events-none absolute inset-0 flex items-center justify-center"
    >
      <div
        class="h-[60%] w-[60%] animate-pulse rounded-full bg-primary/20 blur-[100px]"
      />
    </div>

    <div
      class="relative z-10 flex aspect-auto min-h-[340px] w-full max-w-4xl animate-in zoom-in-95 flex-col overflow-hidden rounded-3xl bg-card shadow-2xl duration-300 sm:aspect-[2.2/1] sm:flex-row"
      @click.stop
    >
      <div
        class="relative flex flex-1 flex-col items-center justify-center overflow-hidden bg-muted/10 p-10 sm:items-start sm:p-14"
      >
        <div
          class="relative z-10 flex w-full flex-col items-center gap-6 sm:items-start"
        >
          <CallOverlayAvatar
            :avatar="callInfo.avatar"
            :name="callInfo.contactName"
          />

          <div class="flex w-full flex-col items-center gap-2 sm:items-start">
            <h2
              class="text-3xl font-semibold capitalize tracking-tight text-foreground sm:text-4xl"
            >
              {{ callInfo.contactName }}
            </h2>
            <div class="flex items-center gap-2">
              <span
                class="flex h-2 w-2 animate-pulse rounded-full"
                :class="statusDotClass"
              />
              <span
                class="text-lg font-medium tabular-nums"
                :class="statusTextClass"
              >
                {{ statusLabel }}
              </span>
            </div>
            <p
              v-if="callInfo.phoneNumber"
              class="mt-1 text-[15px] text-muted-foreground"
            >
              {{ callInfo.phoneNumber }}
            </p>
          </div>
        </div>

        <div
          class="pointer-events-none absolute -bottom-20 size-64 rounded-full bg-primary/5 blur-3xl ltr:-left-20 rtl:-right-20"
        />
      </div>

      <div
        class="flex w-full flex-col items-center justify-center border-t border-border bg-background/50 p-8 backdrop-blur-sm sm:w-[320px] sm:border-l sm:border-t-0"
      >
        <div class="grid w-full max-w-[200px] grid-cols-2 gap-6">
          <button
            type="button"
            class="group flex flex-col items-center gap-3"
            @click="emit('toggleMute')"
          >
            <div
              class="flex size-14 items-center justify-center rounded-full border transition-all group-hover:scale-105"
              :class="
                isMuted
                  ? 'border-amber-500/20 bg-amber-500/10 text-amber-500'
                  : 'border-border/50 bg-muted/60 text-foreground/80 group-hover:border-border group-hover:bg-muted group-hover:text-foreground'
              "
            >
              <span
                class="size-6"
                :class="isMuted ? 'i-lucide-mic-off' : 'i-lucide-mic'"
              />
            </div>
            <span
              class="text-xs font-medium"
              :class="
                isMuted
                  ? 'text-amber-500'
                  : 'text-muted-foreground group-hover:text-foreground'
              "
            >
              {{
                isMuted
                  ? t('CONVERSATION.VOICE_WIDGET.UNMUTE')
                  : t('CONVERSATION.VOICE_WIDGET.MUTE')
              }}
            </span>
          </button>

          <button
            type="button"
            class="group flex flex-col items-center gap-3"
            @click="emit('triggerNote')"
          >
            <div
              class="flex size-14 items-center justify-center rounded-full border border-border/50 bg-muted/60 text-foreground/80 transition-all group-hover:scale-105 group-hover:border-border group-hover:bg-muted group-hover:text-foreground"
            >
              <span class="i-lucide-sticky-note size-6" />
            </div>
            <span
              class="text-xs font-medium text-muted-foreground transition-colors group-hover:text-foreground"
            >
              {{ t('CONVERSATION.VOICE_WIDGET.NOTE') }}
            </span>
          </button>

          <button
            type="button"
            class="group flex flex-col items-center gap-3"
            @click="emit('toggleSpeaker')"
          >
            <div
              class="flex size-14 items-center justify-center rounded-full border transition-all group-hover:scale-105"
              :class="
                isSpeakerOn
                  ? 'border-primary/20 bg-primary/10 text-primary'
                  : 'border-border/50 bg-muted/60 text-foreground/80 group-hover:border-border group-hover:bg-muted group-hover:text-foreground'
              "
            >
              <span class="i-lucide-volume-2 size-6" />
            </div>
            <span
              class="text-xs font-medium"
              :class="
                isSpeakerOn
                  ? 'text-primary'
                  : 'text-muted-foreground group-hover:text-foreground'
              "
            >
              {{ t('CONVERSATION.VOICE_WIDGET.SPEAKER') }}
            </span>
          </button>

          <button type="button" class="group flex flex-col items-center gap-3">
            <div
              class="flex size-14 items-center justify-center rounded-full border border-border/50 bg-muted/60 text-foreground/80 transition-all group-hover:scale-105 group-hover:border-border group-hover:bg-muted group-hover:text-foreground"
            >
              <span
                class="i-lucide-user-plus size-6 text-foreground/80 group-hover:text-foreground"
              />
            </div>
            <span
              class="text-xs font-medium text-muted-foreground transition-colors group-hover:text-foreground"
            >
              {{ t('CONVERSATION.VOICE_WIDGET.ADD') }}
            </span>
          </button>
        </div>

        <div
          class="mt-10 flex w-full justify-center border-t border-border/50 pt-8"
        >
          <button
            type="button"
            class="group flex flex-col items-center gap-3"
            @click="emit('end')"
          >
            <div
              class="flex size-16 items-center justify-center rounded-full bg-destructive shadow-lg ring-4 ring-destructive/20 transition-all group-hover:scale-105 group-hover:bg-destructive/90"
            >
              <span class="i-lucide-phone size-7 rotate-[135deg] text-white" />
            </div>
          </button>
        </div>
      </div>

      <CallQuickNoteWidget
        :is-open="isNoteModalOpen"
        :note-text="noteText"
        @update:note-text="emit('update:noteText', $event)"
        @close="emit('closeNote')"
        @save="emit('saveNote')"
      />
    </div>
  </div>
</template>
