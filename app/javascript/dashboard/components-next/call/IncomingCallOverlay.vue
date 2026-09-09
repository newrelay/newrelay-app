<script setup>
import CallOverlayAvatar from 'dashboard/components-next/call/CallOverlayAvatar.vue';

defineProps({
  callInfo: {
    type: Object,
    required: true,
  },
});

defineEmits(['accept', 'reject', 'minimize']);
</script>

<template>
  <div
    class="fixed inset-0 z-[400] flex animate-in fade-in items-center justify-center bg-background/80 p-4 backdrop-blur-[8px] duration-300 sm:p-8"
    @click.self="$emit('minimize')"
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
                class="flex h-2 w-2 animate-pulse rounded-full bg-amber-500"
              />
              <span class="text-lg font-medium text-amber-500">
                {{ $t('CONVERSATION.VOICE_WIDGET.INCOMING_CALL_RINGING') }}
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
        <div class="flex w-full max-w-[220px] flex-col items-center gap-8">
          <span class="animate-pulse text-lg font-semibold text-foreground">
            {{ $t('CONVERSATION.VOICE_WIDGET.INCOMING_CALL') }}
          </span>
          <div class="flex w-full items-center justify-between gap-6 px-2">
            <button
              type="button"
              class="group flex flex-col items-center gap-3"
              @click="$emit('reject')"
            >
              <div
                class="flex size-16 items-center justify-center rounded-full bg-destructive shadow-lg ring-4 ring-destructive/20 transition-all group-hover:scale-105 group-hover:bg-destructive/90"
              >
                <span
                  class="i-lucide-phone size-7 rotate-[135deg] text-white"
                />
              </div>
              <span class="text-[13px] font-medium text-destructive">
                {{ $t('CONVERSATION.VOICE_WIDGET.DECLINE_CALL') }}
              </span>
            </button>

            <button
              type="button"
              class="group flex flex-col items-center gap-3"
              @click="$emit('accept')"
            >
              <div
                class="flex size-16 items-center justify-center rounded-full bg-emerald-500 shadow-lg ring-4 ring-emerald-500/20 transition-all group-hover:scale-105 group-hover:bg-emerald-600"
              >
                <span class="i-lucide-phone size-7 text-white" />
              </div>
              <span class="text-[13px] font-medium text-emerald-600">
                {{ $t('CONVERSATION.VOICE_WIDGET.ACCEPT_CALL') }}
              </span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
