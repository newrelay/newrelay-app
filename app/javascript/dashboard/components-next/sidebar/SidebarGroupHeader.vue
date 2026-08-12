<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  to: { type: [Object, String], default: '' },
  label: { type: String, default: '' },
  icon: { type: [String, Object], default: '' },
  expandable: { type: Boolean, default: false },
  isExpanded: { type: Boolean, default: false },
  isActive: { type: Boolean, default: false },
  hasActiveChild: { type: Boolean, default: false },
  danger: { type: Boolean, default: false },
  getterKeys: { type: Object, default: () => ({}) },
});

const emit = defineEmits(['toggle']);

const showBadge = useMapGetter(props.getterKeys.badge);
const dynamicCount = useMapGetter(props.getterKeys.count);
const count = computed(() =>
  dynamicCount.value > 99 ? '99+' : dynamicCount.value
);

const isHighlighted = computed(() => props.isActive || props.hasActiveChild);
</script>

<template>
  <component
    :is="to ? 'router-link' : 'button'"
    class="group peer/menu-button relative flex min-w-0 w-full items-center gap-3 rounded-md p-2 py-2 text-left text-sm outline-none transition-colors"
    role="button"
    draggable="false"
    :to="to || undefined"
    :type="to ? undefined : 'button'"
    :title="label"
    :class="
      danger
        ? 'text-sidebar-foreground hover:bg-red-500/10 hover:text-destructive'
        : isHighlighted
          ? 'bg-sidebar-primary/10 font-medium text-sidebar-primary hover:bg-sidebar-primary/15'
          : 'text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground'
    "
    @click.stop="emit('toggle')"
  >
    <span
      v-if="isHighlighted"
      class="pointer-events-none absolute inset-y-1.5 w-[3px] rounded-r-md bg-sidebar-primary ltr:-left-2 rtl:-right-2 rtl:rounded-l-md rtl:rounded-r-none"
      aria-hidden="true"
    />
    <div v-if="icon" class="relative flex shrink-0 items-center">
      <Icon
        :icon="icon"
        class="size-4 shrink-0"
        :class="
          danger
            ? 'text-muted-foreground group-hover:text-destructive'
            : isHighlighted
              ? 'text-sidebar-primary'
              : 'text-muted-foreground'
        "
      />
      <span
        v-if="showBadge"
        class="absolute -top-px size-2 rounded-full border border-sidebar bg-sidebar-primary ltr:-right-px rtl:-left-px"
      />
    </div>
    <div
      class="flex min-w-0 flex-1 items-center gap-1.5 [&>span:last-child]:truncate"
    >
      <span class="truncate">
        {{ label }}
      </span>
      <span
        v-if="dynamicCount && !expandable"
        class="flex-shrink-0 rounded-md px-1 text-center text-xs font-medium leading-5 outline outline-1 capitalize"
        :class="{
          'text-sidebar-primary outline-sidebar-primary/30': isHighlighted,
          'text-muted-foreground outline-sidebar-border': !isHighlighted,
        }"
      >
        {{ count }}
      </span>
    </div>
    <span
      v-if="expandable"
      class="i-lucide-chevron-right ml-auto size-4 shrink-0 text-muted-foreground transition-transform duration-200"
      :class="[{ 'rotate-90': isExpanded }]"
      @click.stop="emit('toggle')"
    />
  </component>
</template>
