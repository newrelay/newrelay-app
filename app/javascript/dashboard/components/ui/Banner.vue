<!-- DEPRECIATED -->
<!-- TODO: Replace this banner component with NextBanner "app/javascript/dashboard/components-next/banner/Banner.vue" -->
<script>
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    bannerMessage: {
      type: String,
      default: '',
    },
    hrefLink: {
      type: String,
      default: '',
    },
    hrefLinkText: {
      type: String,
      default: '',
    },
    hasActionButton: {
      type: Boolean,
      default: false,
    },
    actionButtonVariant: {
      type: String,
      default: 'faded',
    },
    actionButtonLabel: {
      type: String,
      default: '',
    },
    actionButtonIcon: {
      type: String,
      default: 'i-lucide-arrow-right',
    },
    colorScheme: {
      type: String,
      default: '',
    },
    hasCloseButton: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['primaryAction', 'close'],
  computed: {
    bannerClasses() {
      const colorSchemes = {
        primary: 'bg-primary text-primary-foreground',
        secondary: 'bg-muted dark:bg-accent text-foreground',
        alert: 'bg-destructive/10 text-destructive',
        warning: 'bg-warning/20 text-warning',
        gray: 'text-muted-foreground',
      };
      return colorSchemes[this.colorScheme] || '';
    },
    linkClasses() {
      const colorSchemes = {
        secondary: 'text-foreground',
        alert: 'text-destructive',
        warning: 'text-warning',
      };
      return colorSchemes[this.colorScheme] || 'text-warning';
    },
    // TODO - Remove this method when we standardize
    // the button color and variant names
    getButtonColor() {
      const colorMap = {
        primary: 'blue',
        secondary: 'blue',
        alert: 'ruby',
        warning: 'amber',
      };

      return colorMap[this.colorScheme] || 'blue';
    },
  },
  methods: {
    onClick(e) {
      this.$emit('primaryAction', e);
    },
    onClickClose(e) {
      this.$emit('close', e);
    },
  },
};
</script>

<template>
  <div
    class="flex items-center justify-center h-12 gap-4 px-4 py-3 text-xs"
    :class="bannerClasses"
  >
    <span class="flex items-center">
      {{ bannerMessage }}
      <a
        v-if="hrefLink"
        :href="hrefLink"
        rel="noopener noreferrer nofollow"
        target="_blank"
        class="ml-1 underline text-xs"
        :class="linkClasses"
      >
        {{ hrefLinkText }}
      </a>
    </span>
    <div class="flex gap-1 right-3">
      <NextButton
        v-if="hasActionButton"
        xs
        :icon="actionButtonIcon"
        :variant="actionButtonVariant"
        :color="getButtonColor"
        :label="actionButtonLabel"
        @click="onClick"
      />
      <NextButton
        v-if="hasCloseButton"
        xs
        icon="i-lucide-circle-x"
        :color="getButtonColor"
        :label="$t('GENERAL_SETTINGS.DISMISS')"
        @click="onClickClose"
      />
    </div>
  </div>
</template>
