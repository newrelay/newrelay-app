<script setup>
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  inputPlaceholder: {
    type: String,
    default: '',
  },
  showClearFilter: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['remove']);

const value = defineModel({
  type: String,
  default: '',
});
</script>

<template>
  <div
    class="flex items-center justify-between h-10 min-h-[40px] sticky top-0 bg-secondary dark:bg-secondary z-10 gap-2 px-3 border-b rounded-t-xl border-border"
  >
    <div class="flex items-center w-full gap-2" @keyup.space.prevent>
      <Icon
        icon="i-lucide-search"
        class="text-muted-foreground size-4 flex-shrink-0"
      />
      <input
        v-model="value"
        :placeholder="inputPlaceholder"
        type="search"
        class="h-9 w-full focus:outline-none bg-transparent text-foreground placeholder:text-muted-foreground text-[14px]"
      />
    </div>
    <!-- Clear filter button -->
    <NextButton
      v-if="!modelValue && showClearFilter"
      faded
      xs
      class="flex-shrink-0"
      :label="$t('REPORT.FILTER_ACTIONS.CLEAR_FILTER')"
      @click="emit('remove')"
    />
  </div>
</template>
