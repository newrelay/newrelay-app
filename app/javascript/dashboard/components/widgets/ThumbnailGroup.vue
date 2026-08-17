<script setup>
import { computed } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import { RelayTooltip } from 'dashboard/components-next/relay';

const props = defineProps({
  usersList: {
    type: Array,
    default: () => [],
  },
  size: {
    type: Number,
    default: 24,
  },
  showMoreThumbnailsCount: {
    type: Boolean,
    default: false,
  },
  moreThumbnailsText: {
    type: String,
    default: '',
  },
  gap: {
    type: String,
    default: 'normal',
    validator(value) {
      // The value must match one of these strings
      return ['normal', 'tight'].includes(value);
    },
  },
});

const gapClass = computed(() => {
  if (props.gap === 'tight') {
    return 'ltr:[&:not(:first-child)]:-ml-2 rtl:[&:not(:first-child)]:-mr-2';
  }
  return 'ltr:[&:not(:first-child)]:-ml-1 rtl:[&:not(:first-child)]:-mr-1';
});

const moreThumbnailsClass = computed(() => {
  if (props.gap === 'tight') {
    return 'ltr:-ml-2 rtl:-mr-2';
  }
  return 'ltr:-ml-1 rtl:-mr-1';
});
</script>

<template>
  <div class="flex">
    <RelayTooltip v-for="user in usersList" :key="user.id" :content="user.name">
      <Avatar
        :title="user.name"
        :src="user.thumbnail"
        :name="user.name"
        :size="size"
        class="[&>span]:outline [&>span]:outline-1 [&>span]:outline-background [&>span]:shadow"
        :class="gapClass"
        rounded-full
      />
    </RelayTooltip>
    <span
      v-if="showMoreThumbnailsCount"
      class="text-muted-foreground bg-muted outline outline-1 outline-background text-xs font-medium rounded-full px-2 inline-flex items-center shadow relative"
      :class="moreThumbnailsClass"
    >
      {{ moreThumbnailsText }}
    </span>
  </div>
</template>
