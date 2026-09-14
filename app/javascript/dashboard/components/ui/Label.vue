<script>
import { getContrastingTextColor } from '@chatwoot/utils';

export default {
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      default: '',
    },
    href: {
      type: String,
      default: '',
    },
    bgColor: {
      type: String,
      default: '',
    },
    small: {
      type: Boolean,
      default: false,
    },
    showClose: {
      type: Boolean,
      default: false,
    },
    icon: {
      type: String,
      default: '',
    },
    color: {
      type: String,
      default: '',
    },
    colorScheme: {
      type: String,
      default: '',
    },
    variant: {
      type: String,
      default: '',
    },
  },
  emits: ['remove'],
  computed: {
    textColor() {
      if (this.variant === 'smooth') return '';
      if (this.variant === 'dashed') return '';
      return this.color || getContrastingTextColor(this.bgColor);
    },
    labelClass() {
      return `label ${this.colorScheme} ${this.variant} ${
        this.small ? 'small' : ''
      }`;
    },
    labelStyle() {
      if (this.bgColor) {
        return {
          background: this.bgColor,
          color: this.textColor,
          border: `1px solid ${this.bgColor}`,
        };
      }
      return {};
    },
    anchorStyle() {
      if (this.bgColor) {
        return { color: this.textColor };
      }
      return {};
    },
  },
  methods: {
    onClick() {
      this.$emit('remove', this.title);
    },
  },
};
</script>

<template>
  <div
    class="inline-flex ltr:mr-1 rtl:ml-1 mb-1"
    :class="labelClass"
    :style="labelStyle"
    :title="description"
  >
    <span v-if="icon" class="label-action--button">
      <fluent-icon :icon="icon" size="12" class="label--icon cursor-pointer" />
    </span>
    <span
      v-if="['smooth', 'dashed'].includes(variant) && title && !icon"
      :style="{ background: color }"
      class="label-color-dot flex-shrink-0"
    />
    <span v-if="!href" class="whitespace-nowrap text-ellipsis overflow-hidden">
      {{ title }}
    </span>
    <a v-else :href="href" :style="anchorStyle">{{ title }}</a>
    <button
      v-if="showClose"
      class="label-close--button p-0"
      :style="{ color: textColor }"
      @click="onClick"
    >
      <fluent-icon icon="dismiss" size="12" class="close--icon" />
    </button>
  </div>
</template>

<style scoped lang="scss">
.label {
  @apply items-center font-medium text-xs rounded-[4px] gap-1 p-1 bg-muted text-foreground border border-solid border-border h-6;

  &.small {
    @apply text-xs py-0.5 px-1 leading-tight h-5;
  }

  &.small .label--icon,
  &.small .close--icon {
    @apply text-[0.5rem];
  }

  a {
    @apply text-xs;
    &:hover {
      @apply underline;
    }
  }

  /* Color Schemes */
  &.primary {
    @apply bg-primary/20 text-primary border border-solid border-primary/40;

    a {
      @apply text-primary;
    }
    .label-color-dot {
      @apply bg-primary;
    }
  }
  &.secondary {
    @apply bg-accent text-foreground border border-solid border-border;

    a {
      @apply text-foreground;
    }
    .label-color-dot {
      @apply bg-muted-foreground;
    }
  }
  &.success {
    @apply bg-success/20 text-success border border-solid border-success/40;

    a {
      @apply text-success;
    }
    .label-color-dot {
      @apply bg-success;
    }
  }
  &.alert {
    @apply bg-destructive/20 text-destructive border border-solid border-destructive/40;

    a {
      @apply text-destructive;
    }
    .label-color-dot {
      @apply bg-destructive;
    }
  }
  &.warning {
    @apply bg-warning/20 text-warning border border-solid border-warning/40;

    a {
      @apply text-warning;
    }
    .label-color-dot {
      @apply bg-warning;
    }
  }

  &.smooth {
    @apply bg-transparent text-muted-foreground dark:text-foreground border border-solid border-border;
  }

  &.dashed {
    @apply bg-transparent text-muted-foreground dark:text-foreground border border-dashed border-border;
  }
}

.label-close--button {
  @apply text-muted-foreground -mb-0.5 rounded-sm cursor-pointer flex items-center justify-center hover:bg-accent;

  svg {
    @apply text-muted-foreground;
  }
}

.label-action--button {
  @apply flex mr-1;
}

.label-color-dot {
  @apply inline-block w-3 h-3 rounded-sm shadow-sm;
}
.label.small .label-color-dot {
  @apply w-2 h-2 rounded-sm shadow-sm;
}
</style>
