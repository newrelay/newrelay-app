<script setup>
import BaseCell from 'dashboard/components/table/BaseCell.vue';
import Avatar from 'next/avatar/Avatar.vue';
import { useMapGetter } from 'dashboard/composables/store';

defineProps({
  row: {
    type: Object,
    required: true,
  },
});

const isRTL = useMapGetter('accounts/isRTL');
</script>

<template>
  <BaseCell>
    <div
      class="flex items-center gap-3 text-left"
      :class="{ 'flex-row-reverse': isRTL }"
    >
      <Avatar
        :src="row.original.thumbnail"
        :name="row.original.agent"
        :status="row.original.status"
        :size="40"
        hide-offline-status
        rounded-full
      />
      <div class="flex flex-col min-w-0">
        <h6
          class="overflow-hidden text-[14px] font-medium m-0 leading-[1.3] text-foreground whitespace-nowrap text-ellipsis"
        >
          {{ row.original.agent }}
        </h6>
        <span class="text-[14px] text-muted-foreground">
          {{ row.original.email }}
        </span>
      </div>
    </div>
  </BaseCell>
</template>
