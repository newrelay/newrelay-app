<script>
import {
  RELAY_MODAL_HEADER_CLASS,
  RELAY_MODAL_TITLE_CLASS,
  RELAY_MODAL_DESCRIPTION_CLASS,
} from 'dashboard/components-next/relay/modal/constants';

export default {
  props: {
    headerTitle: {
      type: String,
      default: '',
    },
    headerContent: {
      type: String,
      default: '',
    },
    headerContentValue: {
      type: String,
      default: '',
    },
    headerImage: {
      type: String,
      default: '',
    },
  },
  computed: {
    RELAY_MODAL_HEADER_CLASS: () => RELAY_MODAL_HEADER_CLASS,
    RELAY_MODAL_TITLE_CLASS: () => RELAY_MODAL_TITLE_CLASS,
    RELAY_MODAL_DESCRIPTION_CLASS: () => RELAY_MODAL_DESCRIPTION_CLASS,
  },
};
</script>

<!-- eslint-disable vue/no-unused-refs -->
<!-- Added ref for writing specs -->
<template>
  <div :class="RELAY_MODAL_HEADER_CLASS">
    <div class="min-w-0 flex-1">
      <img v-if="headerImage" :src="headerImage" alt="No image" />
      <h2 data-test-id="modal-header-title" :class="RELAY_MODAL_TITLE_CLASS">
        {{ headerTitle }}
      </h2>
      <p
        v-if="headerContent"
        data-test-id="modal-header-content"
        :class="RELAY_MODAL_DESCRIPTION_CLASS"
      >
        {{ headerContent }}
        <span
          v-if="headerContentValue"
          class="font-semibold text-muted-foreground"
        >
          {{ headerContentValue }}
        </span>
      </p>
      <slot />
    </div>
  </div>
</template>
