<script setup>
import { useRouter } from 'vue-router';

const router = useRouter();

const openProfileSettings = () => {
  return router.push({ name: 'profile_settings_index' });
};
</script>

<template>
  <div
    class="flex items-center gap-1.5 border-t border-warning/20 bg-warning/10 px-3 py-1.5 text-[12px] text-warning"
  >
    <span class="i-lucide-circle-alert size-3.5 shrink-0" />
    <span>
      {{ $t('CONVERSATION.FOOTER.MESSAGE_SIGNATURE_NOT_CONFIGURED') }}
      <button
        type="button"
        class="font-medium underline hover:text-warning/80"
        @click="openProfileSettings"
      >
        {{ $t('CONVERSATION.FOOTER.CLICK_HERE') }}
      </button>
    </span>
  </div>
</template>
