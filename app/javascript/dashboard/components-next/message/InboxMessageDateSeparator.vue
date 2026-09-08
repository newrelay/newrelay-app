<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import isToday from 'date-fns/isToday';
import isYesterday from 'date-fns/isYesterday';

const props = defineProps({
  timestamp: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();

const label = computed(() => {
  const date = fromUnixTime(props.timestamp);

  if (isToday(date)) {
    return t('CONVERSATION.DATE_SEPARATOR.TODAY');
  }

  if (isYesterday(date)) {
    return t('CONVERSATION.DATE_SEPARATOR.YESTERDAY');
  }

  return format(date, 'MMM d, yyyy');
});
</script>

<template>
  <div class="relative my-2 flex items-center justify-center">
    <div class="absolute inset-0 flex items-center">
      <div class="w-full border-t border-border" />
    </div>
    <span
      class="relative bg-muted/10 px-4 text-[13px] font-medium text-muted-foreground dark:bg-background"
    >
      {{ label }}
    </span>
  </div>
</template>
