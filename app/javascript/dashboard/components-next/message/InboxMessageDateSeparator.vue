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
  <div class="my-2 flex items-center justify-center">
    <div class="flex w-[40%] items-center gap-3">
      <div class="flex-1 border-t border-border" />
      <span
        class="shrink-0 select-none text-[12px] font-medium text-muted-foreground"
      >
        {{ label }}
      </span>
      <div class="flex-1 border-t border-border" />
    </div>
  </div>
</template>
