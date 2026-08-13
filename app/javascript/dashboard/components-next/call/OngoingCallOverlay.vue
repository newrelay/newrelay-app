<script setup>
import { computed } from 'vue';
import { VOICE_CALL_DIRECTION } from 'dashboard/components-next/message/constants';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  callInfo: {
    type: Object,
    required: true,
  },
  // 'outgoing' (ringing) | 'ongoing' (connected)
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
  showGoToConversation: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['end', 'toggleMute', 'minimize', 'goToConversation']);

const isOngoing = computed(() => props.state === VOICE_CALL_DIRECTION.ONGOING);
</script>

<template>
  <div
    class="flex fixed inset-0 z-[400] justify-center items-center p-4 sm:p-8 bg-background/80 backdrop-blur-md"
  >
    <!-- Glow behind the card -->
    <div
      class="flex absolute inset-0 justify-center items-center pointer-events-none"
    >
      <div
        class="w-[60%] h-[60%] rounded-full blur-[100px] bg-primary/20 animate-pulse"
      />
    </div>

    <div
      class="flex relative z-10 flex-col w-full max-w-4xl min-h-[340px] rounded-3xl border shadow-2xl sm:flex-row sm:aspect-[2.2/1] bg-card border-border/80 ring-1 ring-border/50 overflow-hidden"
    >
      <!-- Minimize to the compact widget -->
      <button
        v-tooltip.bottom="$t('CONVERSATION.VOICE_WIDGET.MINIMIZE')"
        class="flex absolute top-4 z-20 justify-center items-center rounded-full ltr:right-4 rtl:left-4 size-8 text-muted-foreground hover:bg-muted hover:text-foreground transition-colors"
        @click="$emit('minimize')"
      >
        <Icon class="size-4" icon="i-ph-arrows-in-bold" />
      </button>

      <!-- Left: caller info -->
      <div
        class="flex overflow-hidden relative flex-col flex-1 justify-center items-center p-10 sm:items-start sm:p-14 bg-muted/10"
      >
        <div
          class="flex relative z-10 flex-col gap-6 items-center w-full sm:items-start"
        >
          <div class="relative">
            <div
              class="absolute inset-0 rounded-full opacity-60 scale-150 bg-primary/20 animate-ping"
            />
            <div
              class="relative z-10 rounded-full border-4 shadow-lg border-background"
            >
              <Avatar
                :src="callInfo.avatar"
                :name="callInfo.contactName"
                :size="112"
              />
            </div>
            <div
              class="flex absolute bottom-1 z-20 justify-center items-center rounded-full border-[3px] ltr:right-1 rtl:left-1 size-6 bg-success border-background"
            >
              <Icon class="size-3 text-white" icon="i-ph-phone-fill" />
            </div>
          </div>

          <div class="flex flex-col gap-2 items-center w-full sm:items-start">
            <h2
              class="text-3xl font-semibold tracking-tight sm:text-4xl text-foreground"
            >
              {{ callInfo.contactName }}
            </h2>
            <div class="flex gap-2 items-center">
              <span
                class="w-2 h-2 rounded-full animate-pulse"
                :class="isOngoing ? 'bg-success' : 'bg-warning'"
              />
              <span
                class="text-lg font-medium tabular-nums"
                :class="isOngoing ? 'text-success' : 'text-warning'"
              >
                {{
                  isOngoing ? duration : $t('CONVERSATION.VOICE_WIDGET.CALLING')
                }}
              </span>
            </div>
            <p v-if="callInfo.phoneNumber" class="mt-1 text-muted-foreground">
              {{ callInfo.phoneNumber }}
            </p>
          </div>
        </div>

        <!-- Go to conversation thread -->
        <button
          v-if="showGoToConversation"
          class="flex relative z-10 gap-1.5 items-center mt-8 text-sm font-medium transition-colors text-primary hover:text-primary/80"
          @click="$emit('goToConversation')"
        >
          <Icon class="size-4" icon="i-ph-chat-circle-text-bold" />
          {{ $t('CONVERSATION.VOICE_WIDGET.GO_TO_CONVERSATION') }}
          <Icon class="size-3.5" icon="i-ph-caret-right-bold" />
        </button>

        <!-- Background decoration -->
        <div
          class="absolute -bottom-20 rounded-full blur-3xl pointer-events-none ltr:-left-20 rtl:-right-20 size-64 bg-primary/5"
        />
      </div>

      <!-- Right: call controls -->
      <div
        class="flex flex-col justify-center items-center p-8 w-full border-t sm:w-[320px] sm:border-t-0 sm:border-l bg-background/50 border-border backdrop-blur-sm"
      >
        <!-- Mute (only once connected) -->
        <button
          v-if="showMute"
          class="flex flex-col gap-3 items-center group"
          @click="$emit('toggleMute')"
        >
          <div
            class="flex justify-center items-center rounded-full border transition-all size-14 group-hover:scale-105"
            :class="
              isMuted
                ? 'bg-warning/10 border-warning/20 text-warning'
                : 'bg-muted/60 border-border/50 text-foreground/80 group-hover:bg-muted group-hover:border-border group-hover:text-foreground'
            "
          >
            <Icon
              class="size-6"
              :icon="
                isMuted ? 'i-ph-microphone-slash-bold' : 'i-ph-microphone-bold'
              "
            />
          </div>
          <span
            class="text-xs font-medium transition-colors"
            :class="
              isMuted
                ? 'text-warning'
                : 'text-muted-foreground group-hover:text-foreground'
            "
          >
            {{
              isMuted
                ? $t('CONVERSATION.VOICE_WIDGET.UNMUTE')
                : $t('CONVERSATION.VOICE_WIDGET.MUTE')
            }}
          </span>
        </button>

        <!-- End Call -->
        <div
          class="flex justify-center w-full"
          :class="showMute ? 'mt-10 pt-8 border-t border-border/50' : ''"
        >
          <button
            class="flex flex-col gap-3 items-center group"
            @click="$emit('end')"
          >
            <div
              class="flex justify-center items-center rounded-full shadow-lg transition-all size-16 bg-destructive ring-4 ring-destructive/20 group-hover:bg-destructive/90 group-hover:scale-105"
            >
              <Icon
                class="text-white size-7 rotate-[135deg]"
                icon="i-ph-phone-bold"
              />
            </div>
            <span class="text-sm font-medium text-destructive">
              {{ $t('CONVERSATION.VOICE_WIDGET.END_CALL') }}
            </span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
