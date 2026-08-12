<script setup>
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';

defineProps({
  inbox: {
    type: Object,
    default: () => {},
  },
});
</script>

<template>
  <div :title="inbox.name" class="flex items-center gap-0.5 min-w-0">
    <ChannelIcon
      :inbox="inbox"
      class="size-4 flex-shrink-0 text-muted-foreground"
    />
    <span class="truncate text-body-main text-muted-foreground">
      {{ inbox.name }}
    </span>
  </div>
</template>
