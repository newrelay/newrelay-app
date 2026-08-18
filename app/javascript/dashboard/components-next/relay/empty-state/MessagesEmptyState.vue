<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    default: 'i-lucide-inbox',
  },
  showDevButton: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['devAction']);

const { t } = useI18n();

const emptyTitle = computed(
  () => props.title || t('CONVERSATION.NO_MESSAGE_1')
);
const emptyDescription = computed(() => {
  if (props.description !== undefined && props.description !== null) {
    return props.description;
  }
  return t('CONVERSATION.NO_MESSAGE_1_DESCRIPTION');
});
const showDescription = computed(() => Boolean(emptyDescription.value));
</script>

<template>
  <div
    class="relative flex h-full min-h-[400px] w-full flex-1 flex-col items-center justify-center overflow-hidden bg-background"
  >
    <div
      class="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_center,_var(--tw-gradient-stops))] from-primary/[0.04] via-background/50 to-background"
    />

    <div
      class="relative z-10 flex w-full max-w-md animate-in fade-in zoom-in-95 flex-col items-center duration-700"
    >
      <div class="relative mb-6 flex items-center justify-center">
        <div
          class="relative flex size-20 items-center justify-center rounded-xl border border-primary/20 bg-gradient-to-br from-primary/10 via-primary/5 to-transparent shadow-sm transition-transform duration-500"
        >
          <svg
            v-if="icon === 'i-lucide-inbox'"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="size-10 text-primary drop-shadow-sm"
            aria-hidden="true"
          >
            <polyline points="22 12 16 12 14 15 10 15 8 12 2 12" />
            <path
              d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"
            />
          </svg>
          <svg
            v-else-if="icon === 'i-lucide-rocket'"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="size-8 text-primary drop-shadow-sm"
            aria-hidden="true"
          >
            <path d="M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5" />
            <path
              d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09"
            />
            <path
              d="M9 12a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.4 22.4 0 0 1-4 2z"
            />
            <path d="M9 12H4s.55-3.03 2-4c1.62-1.08 5 .05 5 .05" />
          </svg>
          <span
            v-else
            :class="icon"
            class="size-10 text-primary drop-shadow-sm [&_svg]:stroke-[1.5]"
            aria-hidden="true"
          />
        </div>
      </div>

      <h2 class="mb-2.5 text-[20px] font-[600] tracking-tight text-foreground">
        {{ emptyTitle }}
      </h2>

      <p
        v-if="showDescription"
        class="mb-10 max-w-sm whitespace-pre-line text-center text-[14px] leading-relaxed text-muted-foreground"
      >
        {{ emptyDescription }}
      </p>
    </div>

    <button
      v-if="showDevButton"
      type="button"
      class="absolute bottom-8 z-20 flex items-center gap-2 rounded-md border border-dashed border-border px-4 py-2 text-[13px] text-muted-foreground shadow-sm transition-all hover:border-primary/50 hover:text-foreground"
      @click="$emit('devAction')"
    >
      <span class="i-lucide-sparkles size-3.5 text-primary" />
      {{ t('CHAT_LIST.EMPTY_STATE.DEV_MOCK_DATA') }}
    </button>
  </div>
</template>
