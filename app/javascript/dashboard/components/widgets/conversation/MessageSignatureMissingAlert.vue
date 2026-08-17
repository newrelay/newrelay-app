<script setup>
import { useRouter } from 'vue-router';

defineProps({
  variant: {
    type: String,
    default: 'default',
    validator: value => ['default', 'inbox'].includes(value),
  },
});

const router = useRouter();

const openProfileSettings = () => {
  return router.push({ name: 'profile_settings_index' });
};
</script>

<template>
  <div
    v-if="variant === 'inbox'"
    class="flex items-center gap-1.5 border-t border-amber-500/20 bg-amber-500/10 px-3 py-1.5 text-[12px] text-amber-600"
  >
    <span class="i-lucide-circle-alert size-3.5 shrink-0" />
    <span>
      {{ $t('CONVERSATION.FOOTER.MESSAGE_SIGNATURE_NOT_CONFIGURED') }}
      <button
        type="button"
        class="font-medium underline hover:text-amber-700"
        @click="openProfileSettings"
      >
        {{ $t('CONVERSATION.FOOTER.CLICK_HERE') }}
      </button>
    </span>
  </div>
  <div
    v-else
    class="my-0 flex max-h-[8vh] items-baseline justify-between overflow-auto rounded-sm border border-dashed border-border px-1 hover:bg-background"
  >
    <p class="!m-0 w-fit">
      {{ $t('CONVERSATION.FOOTER.MESSAGE_SIGNATURE_NOT_CONFIGURED') }}
      <button
        type="button"
        class="text-primary underline hover:text-primary/80"
        @click="openProfileSettings"
      >
        {{ $t('CONVERSATION.FOOTER.CLICK_HERE') }}
      </button>
    </p>
  </div>
</template>
