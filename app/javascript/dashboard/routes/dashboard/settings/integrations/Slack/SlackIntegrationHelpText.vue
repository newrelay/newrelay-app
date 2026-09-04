<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

const props = defineProps({
  selectedChannelName: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const formattedHelpText = computed(() => {
  return formatMessage(
    t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.BODY', {
      selectedChannelName: props.selectedChannelName,
    }),
    false
  );
});
</script>

<template>
  <div
    class="w-full flex-1 rounded-xl border border-border/60 bg-card px-6 py-5 shadow-xs"
  >
    <div class="prose-lg max-w-5xl">
      <h5 class="text-base font-semibold tracking-tight text-foreground">
        {{ t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.TITLE') }}
      </h5>
      <div
        v-dompurify-html="formattedHelpText"
        class="text-[13.5px] text-muted-foreground"
      />
    </div>
  </div>
</template>
