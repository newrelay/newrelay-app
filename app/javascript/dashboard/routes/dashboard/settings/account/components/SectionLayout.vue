<script setup>
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  title: { type: String, required: true },
  description: { type: String, required: true },
  withBorder: { type: Boolean, default: false },
  hideContent: { type: Boolean, default: false },
  beta: { type: Boolean, default: false },
  asCard: { type: Boolean, default: false },
  icon: { type: String, default: '' },
  inlineHeader: { type: Boolean, default: false },
});
const { t } = useI18n();
</script>

<template>
  <section
    class="grid grid-cols-1 gap-5"
    :class="{
      'border-t border-border pt-8': withBorder && !asCard,
      'overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs':
        asCard,
      'pb-8': !hideContent && !asCard,
    }"
  >
    <header
      :class="{
        'border-b border-border/40 p-4 sm:p-6': asCard && !inlineHeader,
        'p-4 sm:p-6': asCard && inlineHeader,
        'flex flex-col justify-between gap-6 md:flex-row md:items-center':
          inlineHeader,
        'flex gap-4': !!icon && !inlineHeader,
        'flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between':
          !icon && !inlineHeader,
      }"
    >
      <div
        v-if="icon"
        class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10"
      >
        <Icon :icon="icon" class="size-5 text-primary" />
      </div>
      <div
        v-if="
          title || beta || $slots.title || description || $slots.description
        "
        class="min-w-0 flex-1"
      >
        <h4
          v-if="title || beta || $slots.title"
          class="flex items-center gap-2 text-base font-semibold text-foreground"
        >
          <slot name="title">{{ title }}</slot>
          <div
            v-if="beta"
            v-tooltip.top="t('GENERAL.BETA_DESCRIPTION')"
            class="rounded-lg border border-primary/30 px-1 py-0.5 text-xs uppercase leading-none text-primary"
          >
            {{ t('GENERAL.BETA') }}
          </div>
        </h4>
        <p
          v-if="description || $slots.description"
          class="mt-1 text-sm leading-relaxed text-muted-foreground"
        >
          <slot name="description">{{ description }}</slot>
        </p>
      </div>
      <div class="flex shrink-0 items-center gap-3">
        <slot name="headerActions" />
      </div>
    </header>
    <div
      class="text-foreground transition-[max-height] duration-300 ease-in-out"
      :class="{
        'max-h-0 overflow-hidden': hideContent,
        'max-h-screen': !hideContent,
        'p-4 sm:p-6': asCard && !hideContent && !inlineHeader,
        hidden: inlineHeader && hideContent,
      }"
    >
      <slot />
    </div>
  </section>
</template>
