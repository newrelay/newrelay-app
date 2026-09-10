<script setup>
import {
  RELAY_MODAL_HEADER_CLASS,
  RELAY_MODAL_HEADER_PLAIN_CLASS,
  RELAY_MODAL_TITLE_CLASS,
  RELAY_MODAL_DESCRIPTION_CLASS,
  RELAY_MODAL_CLOSE_BUTTON_CLASS,
} from './constants';

defineProps({
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  titleTag: {
    type: String,
    default: 'h2',
  },
  descriptionTag: {
    type: String,
    default: 'p',
  },
  showClose: {
    type: Boolean,
    default: true,
  },
  divided: {
    type: Boolean,
    default: true,
  },
});

defineEmits(['close']);
</script>

<template>
  <div
    :class="divided ? RELAY_MODAL_HEADER_CLASS : RELAY_MODAL_HEADER_PLAIN_CLASS"
  >
    <div class="min-w-0 flex-1">
      <slot name="title">
        <component :is="titleTag" v-if="title" :class="RELAY_MODAL_TITLE_CLASS">
          {{ title }}
        </component>
      </slot>
      <slot name="description">
        <component
          :is="descriptionTag"
          v-if="description"
          :class="RELAY_MODAL_DESCRIPTION_CLASS"
        >
          {{ description }}
        </component>
      </slot>
    </div>
    <button
      v-if="showClose"
      type="button"
      :class="
        divided
          ? RELAY_MODAL_CLOSE_BUTTON_CLASS
          : `${RELAY_MODAL_CLOSE_BUTTON_CLASS} rounded-full bg-muted/40 hover:bg-muted hover:text-foreground`
      "
      @click="$emit('close')"
    >
      <span class="i-lucide-x size-4" />
    </button>
  </div>
</template>
