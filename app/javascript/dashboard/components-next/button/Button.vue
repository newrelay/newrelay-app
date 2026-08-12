<script setup>
import { computed, useSlots, useAttrs } from 'vue';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  VARIANT_OPTIONS,
  COLOR_OPTIONS,
  JUSTIFY_OPTIONS,
  SIZE_OPTIONS,
  EXCLUDED_ATTRS,
} from './constants.js';

const props = defineProps({
  label: { type: [String, Number], default: '' },
  variant: {
    type: String,
    default: null,
    validator: value => VARIANT_OPTIONS.includes(value) || value === null,
  },
  color: {
    type: String,
    default: null,
    validator: value => COLOR_OPTIONS.includes(value) || value === null,
  },
  size: {
    type: String,
    default: null,
    validator: value => SIZE_OPTIONS.includes(value) || value === null,
  },
  justify: {
    type: String,
    default: null,
    validator: value => JUSTIFY_OPTIONS.includes(value) || value === null,
  },
  icon: { type: [String, Object, Function], default: '' },
  trailingIcon: { type: Boolean, default: false },
  isLoading: { type: Boolean, default: false },
  noAnimation: { type: Boolean, default: false },
});

const slots = useSlots();
const attrs = useAttrs();

defineOptions({
  inheritAttrs: false,
});

const filteredAttrs = computed(() => {
  const standardAttrs = {};

  Object.entries(attrs)
    .filter(([key]) => !EXCLUDED_ATTRS.includes(key))
    .forEach(([key, value]) => {
      standardAttrs[key] = value;
    });

  return standardAttrs;
});

const computedVariant = computed(() => {
  if (props.variant) return props.variant;
  // The useAttrs method returns attributes values an empty string (not boolean value as in props).
  if (attrs.solid || attrs.solid === '') return 'solid';
  if (attrs.outline || attrs.outline === '') return 'outline';
  if (attrs.faded || attrs.faded === '') return 'faded';
  if (attrs.link || attrs.link === '') return 'link';
  if (attrs.ghost || attrs.ghost === '') return 'ghost';
  return 'solid'; // Default variant
});

const computedColor = computed(() => {
  if (props.color) return props.color;
  if (attrs.blue || attrs.blue === '') return 'blue';
  if (attrs.ruby || attrs.ruby === '') return 'ruby';
  if (attrs.amber || attrs.amber === '') return 'amber';
  if (attrs.slate || attrs.slate === '') return 'slate';
  if (attrs.teal || attrs.teal === '') return 'teal';
  return 'blue'; // Default color
});

const computedSize = computed(() => {
  if (props.size) return props.size;
  if (attrs.xs || attrs.xs === '') return 'xs';
  if (attrs.sm || attrs.sm === '') return 'sm';
  if (attrs.md || attrs.md === '') return 'md';
  if (attrs.lg || attrs.lg === '') return 'lg';
  return 'md';
});

const computedJustify = computed(() => {
  if (props.justify) return props.justify;
  if (attrs.start || attrs.start === '') return 'start';
  if (attrs.center || attrs.center === '') return 'center';
  if (attrs.end || attrs.end === '') return 'end';

  return 'center';
});

const STYLE_CONFIG = {
  colors: {
    blue: {
      solid:
        'bg-primary text-white hover:enabled:brightness-110 focus-visible:brightness-110 outline-transparent',
      faded:
        'bg-primary/10 text-primary hover:enabled:bg-primary/20 focus-visible:bg-primary/20 outline-transparent',
      outline: 'text-primary outline-primary',
      ghost:
        'text-primary hover:enabled:bg-accent focus-visible:bg-accent outline-transparent',
      link: 'text-primary hover:enabled:underline focus-visible:underline outline-transparent',
    },
    ruby: {
      solid:
        'bg-destructive text-white hover:enabled:bg-destructive focus-visible:bg-destructive outline-transparent',
      faded:
        'bg-destructive/10 text-destructive hover:enabled:bg-destructive/20 focus-visible:bg-destructive/20 outline-transparent',
      outline:
        'text-destructive hover:enabled:bg-destructive/10 focus-visible:bg-destructive/10 outline-destructive',
      ghost:
        'text-destructive hover:enabled:bg-accent focus-visible:bg-accent outline-transparent',
      link: 'text-destructive dark:text-destructive hover:enabled:underline focus-visible:underline outline-transparent',
    },
    amber: {
      solid:
        'bg-warning text-white hover:enabled:bg-warning focus-visible:bg-warning outline-transparent',
      faded:
        'bg-warning/10 text-foreground hover:enabled:bg-warning/20 focus-visible:bg-warning/20 outline-transparent',
      outline:
        'text-warning hover:enabled:bg-warning/10 focus-visible:bg-warning/10 outline-warning',
      link: 'text-warning hover:enabled:underline focus-visible:underline outline-transparent',
      ghost:
        'text-warning hover:enabled:bg-accent focus-visible:bg-accent outline-transparent',
    },
    slate: {
      solid:
        'bg-primary dark:hover:enabled:bg-secondary dark:focus-visible:bg-secondary hover:enabled:bg-accent focus-visible:bg-accent text-foreground outline-card',
      faded:
        'bg-muted-foreground/10 text-foreground hover:enabled:bg-muted-foreground/20 focus-visible:bg-muted-foreground/20 outline-transparent',
      outline:
        'text-muted-foreground outline-border hover:enabled:bg-muted-foreground/10 focus-visible:bg-muted-foreground/10',
      link: 'text-muted-foreground hover:enabled:text-foreground focus-visible:text-foreground hover:enabled:underline focus-visible:underline outline-transparent',
      ghost:
        'text-foreground hover:enabled:bg-accent focus-visible:bg-accent outline-transparent',
    },
    teal: {
      solid:
        'bg-success text-white hover:enabled:bg-success focus-visible:bg-success outline-transparent',
      faded:
        'bg-success/10 text-success hover:enabled:bg-success/20 focus-visible:bg-success/20 outline-transparent',
      outline:
        'text-success hover:enabled:bg-success/10 focus-visible:bg-success/10 outline-success',
      link: 'text-success hover:enabled:underline focus-visible:underline outline-transparent',
      ghost:
        'text-success hover:enabled:bg-accent focus-visible:bg-accent outline-transparent',
    },
  },
  sizes: {
    regular: {
      xs: 'h-6 px-2',
      sm: 'h-8 px-3',
      md: 'h-10 px-4',
      lg: 'h-12 px-5',
    },
    iconOnly: {
      xs: 'h-6 w-6 p-0',
      sm: 'h-8 w-8 p-0',
      md: 'h-10 w-10 p-0',
      lg: 'h-12 w-12 p-0',
    },
    link: {
      xs: 'p-0',
      sm: 'p-0',
      md: 'p-0',
      lg: 'p-0',
    },
  },
  fontSize: {
    xs: 'text-xs',
    sm: 'text-sm',
    md: 'text-sm font-medium',
    lg: 'text-base',
  },
  clickAnimation: {
    xs: 'active:enabled:scale-[0.97]',
    sm: 'active:enabled:scale-[0.97]',
    md: 'active:enabled:scale-[0.98]',
    lg: 'active:enabled:scale-[0.98]',
  },
  justify: {
    start: 'justify-start',
    center: 'justify-center',
    end: 'justify-end',
  },
  base: 'inline-flex items-center min-w-0 gap-2 transition-all duration-100 ease-out border-0 rounded-lg outline-1 outline disabled:opacity-50',
};

const variantClasses = computed(() => {
  const variantMap = {
    ghost: `${STYLE_CONFIG.colors[computedColor.value].ghost}`,
    link: `${STYLE_CONFIG.colors[computedColor.value].link} p-0 font-medium underline-offset-2`,
    outline: STYLE_CONFIG.colors[computedColor.value].outline,
    faded: STYLE_CONFIG.colors[computedColor.value].faded,
    solid: STYLE_CONFIG.colors[computedColor.value].solid,
  };

  return variantMap[computedVariant.value];
});

const isIconOnly = computed(() => !props.label && !slots.default);
const isLink = computed(() => computedVariant.value === 'link');

const buttonClasses = computed(() => {
  const sizeConfig = isIconOnly.value ? 'iconOnly' : 'regular';
  const classes = [
    variantClasses.value,
    computedVariant.value !== 'link' &&
      STYLE_CONFIG.sizes[sizeConfig][computedSize.value],
  ].filter(Boolean);

  return classes.join(' ');
});

const linkButtonClasses = computed(() => {
  const classes = [
    variantClasses.value,
    STYLE_CONFIG.sizes.link[computedSize.value],
  ].filter(Boolean);

  return classes.join(' ');
});

const animationClasses = computed(() => {
  return props.noAnimation
    ? ''
    : STYLE_CONFIG.clickAnimation[computedSize.value];
});
</script>

<template>
  <button
    v-bind="filteredAttrs"
    :class="{
      [STYLE_CONFIG.base]: true,
      [isLink ? linkButtonClasses : buttonClasses]: true,
      [STYLE_CONFIG.fontSize[computedSize]]: true,
      [animationClasses]: true,
      [STYLE_CONFIG.justify[computedJustify]]: true,
      'flex-row-reverse': trailingIcon && !isIconOnly,
    }"
  >
    <slot v-if="(icon || $slots.icon) && !isLoading" name="icon">
      <Icon :icon="icon" class="flex-shrink-0" />
    </slot>

    <Spinner v-if="isLoading" class="!w-5 !h-5 flex-shrink-0" />

    <slot v-if="label || $slots.default" name="default">
      <span v-if="label" class="min-w-0 truncate">{{ label }}</span>
    </slot>
  </button>
</template>
