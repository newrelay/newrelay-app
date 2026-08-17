<script>
import { RelayTooltip } from 'dashboard/components-next/relay';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    RelayTooltip,
    NextButton,
  },
  props: {
    isOnExpandedLayout: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['toggle'],
  methods: {
    toggle() {
      this.$emit('toggle');
    },
  },
};
</script>

<template>
  <RelayTooltip :content="$t('CONVERSATION.SWITCH_VIEW_LAYOUT')" side="left">
    <NextButton
      :icon="
        isOnExpandedLayout
          ? 'i-lucide-arrow-left-to-line'
          : 'i-lucide-arrow-right-to-line'
      "
      slate
      xs
      faded
      class="flex-shrink-0 rtl:rotate-180 ltr:rotate-0 md:inline-flex hidden"
      @click="toggle"
    />
  </RelayTooltip>
</template>
