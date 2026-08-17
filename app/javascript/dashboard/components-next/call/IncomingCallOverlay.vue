<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  callInfo: {
    type: Object,
    required: true,
  },
});

defineEmits(['accept', 'reject', 'dismiss']);
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
      <!-- Dismiss (removes the notification without declining) -->
      <RelayTooltip :content="$t('CONVERSATION.VOICE_WIDGET.DISMISS_CALL')">
        <button
          class="flex absolute top-4 z-20 justify-center items-center rounded-full ltr:right-4 rtl:left-4 size-8 text-muted-foreground hover:bg-muted hover:text-foreground transition-colors"
          @click="$emit('dismiss')"
        >
          <Icon class="size-4" icon="i-ph-x-bold" />
        </button>
      </RelayTooltip>

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
              class="absolute inset-0 rounded-full opacity-40 scale-[2] bg-primary/10 animate-ping"
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
              class="capitalize text-3xl font-semibold tracking-tight sm:text-4xl text-foreground"
            >
              {{ callInfo.contactName }}
            </h2>
            <div class="flex gap-2 items-center">
              <span class="w-2 h-2 rounded-full bg-warning animate-pulse" />
              <span class="text-lg font-medium text-warning">
                {{ $t('CONVERSATION.VOICE_WIDGET.INCOMING_CALL_RINGING') }}
              </span>
            </div>
            <p v-if="callInfo.phoneNumber" class="mt-1 text-muted-foreground">
              {{ callInfo.phoneNumber }}
            </p>
          </div>
        </div>

        <!-- Background decoration -->
        <div
          class="absolute -bottom-20 rounded-full blur-3xl pointer-events-none ltr:-left-20 rtl:-right-20 size-64 bg-primary/5"
        />
      </div>

      <!-- Right: accept / decline -->
      <div
        class="flex flex-col justify-center items-center p-8 w-full border-t sm:w-[320px] sm:border-t-0 sm:border-l bg-background/50 border-border backdrop-blur-sm"
      >
        <div class="flex flex-col gap-8 items-center w-full max-w-[220px]">
          <span class="text-lg font-semibold text-foreground animate-pulse">
            {{ $t('CONVERSATION.VOICE_WIDGET.INCOMING_CALL') }}
          </span>
          <div class="flex gap-6 justify-between items-center px-2 w-full">
            <!-- Decline -->
            <button
              class="flex flex-col gap-3 items-center group"
              @click="$emit('reject')"
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
                {{ $t('CONVERSATION.VOICE_WIDGET.DECLINE_CALL') }}
              </span>
            </button>

            <!-- Accept -->
            <button
              class="flex flex-col gap-3 items-center group"
              @click="$emit('accept')"
            >
              <div
                class="flex justify-center items-center rounded-full shadow-lg transition-all size-16 bg-success ring-4 ring-success/20 group-hover:bg-success/90 group-hover:scale-105"
              >
                <Icon class="text-white size-7" icon="i-ph-phone-bold" />
              </div>
              <span class="text-sm font-medium text-success">
                {{ $t('CONVERSATION.VOICE_WIDGET.ACCEPT_CALL') }}
              </span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
