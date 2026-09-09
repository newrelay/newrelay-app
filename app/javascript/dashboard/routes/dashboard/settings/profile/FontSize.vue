<script setup>
import { computed } from 'vue';
import { RELAY_FORM_LABEL_CLASS } from 'dashboard/components-next/relay/form/constants';
import { useFontSize } from 'dashboard/composables/useFontSize';
import SiteLanguageSelect from '../account/components/SiteLanguageSelect.vue';

const props = defineProps({
  value: {
    type: String,
    default: 'default',
  },
  label: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['change']);

const { fontSizeOptions } = useFontSize();

const selectedValue = computed({
  get: () => props.value,
  set: value => {
    emit('change', value);
  },
});
</script>

<template>
  <div
    class="flex items-center justify-between gap-4 py-2 border-b border-border/40 pb-6"
  >
    <div class="flex flex-col min-w-0">
      <label :class="RELAY_FORM_LABEL_CLASS">
        {{ label }}
      </label>
      <p class="text-[13px] text-muted-foreground mt-0.5">
        {{ description }}
      </p>
    </div>
    <div class="w-32 shrink-0">
      <SiteLanguageSelect
        v-model="selectedValue"
        :options="fontSizeOptions"
        :show-search="false"
      />
    </div>
  </div>
</template>
