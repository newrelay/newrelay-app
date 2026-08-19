<script setup>
import { computed } from 'vue';
import { removeEmoji } from 'shared/helpers/emoji';

const props = defineProps({
  avatar: {
    type: String,
    default: '',
  },
  name: {
    type: String,
    default: '',
  },
});

const initials = computed(() => {
  if (!props.name) return '';
  const words = removeEmoji(props.name).split(/\s+/).filter(Boolean);
  if (!words.length) return '';
  return words.length === 1
    ? words[0].charAt(0).toUpperCase()
    : words
        .slice(0, 2)
        .map(word => word.charAt(0))
        .join('')
        .toUpperCase();
});

const avatarAlt = computed(() => props.name || 'Contact Avatar');
</script>

<template>
  <div class="relative">
    <div
      class="absolute inset-0 scale-150 animate-ping rounded-full bg-primary/20 opacity-60"
    />
    <div
      class="absolute inset-0 scale-[2] animate-ping rounded-full bg-primary/10 opacity-40"
    />
    <img
      v-if="avatar"
      :src="avatar"
      :alt="avatarAlt"
      class="relative z-10 size-24 rounded-full border-4 border-background object-cover shadow-lg sm:size-28"
    />
    <span
      v-else
      class="relative z-10 flex size-24 items-center justify-center rounded-full border-4 border-background bg-primary/10 text-xl font-semibold text-primary shadow-lg sm:size-28"
    >
      {{ initials }}
    </span>
    <div
      class="absolute bottom-1 z-20 flex size-6 items-center justify-center rounded-full border-[3px] border-background bg-emerald-500 ltr:right-1 rtl:left-1"
    >
      <span class="i-ri-phone-fill size-3 text-white" />
    </div>
  </div>
</template>
