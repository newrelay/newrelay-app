<script setup>
import { isVNode, computed } from 'vue';
import { useRoute } from 'vue-router';
import Icon from 'next/icon/Icon.vue';
import Policy from 'dashboard/components/policy.vue';
import { useSidebarContext } from './provider';
import SidebarUnreadBadge from './SidebarUnreadBadge.vue';

const props = defineProps({
  label: { type: String, required: true },
  to: { type: [String, Object], default: null },
  icon: { type: [String, Object], default: null },
  active: { type: Boolean, default: false },
  activeOn: { type: Array, default: () => [] },
  component: { type: Function, default: null },
  badgeCount: { type: [Number, String], default: 0 },
  disabled: { type: Boolean, default: false },
  comingSoon: { type: Boolean, default: false },
});

const route = useRoute();
const { resolvePermissions, resolveFeatureFlag } = useSidebarContext();

const shouldRenderComponent = computed(() => {
  return typeof props.component === 'function' || isVNode(props.component);
});

// Parent passes `active` from activeChild selection; also match locally so
// portal/Captain redirector leaves (navigationPath) never miss highlight.
const isLeafActive = computed(() => {
  if (props.active) return true;

  const names = route.matched.map(record => record.name).filter(Boolean);
  if (route.name && !names.includes(route.name)) names.push(route.name);

  if (props.activeOn.some(name => names.includes(name))) return true;

  const navPath =
    props.to && typeof props.to === 'object'
      ? props.to.params?.navigationPath
      : null;
  return Boolean(navPath && names.includes(navPath));
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <li
    v-if="disabled"
    :title="label"
    class="group/menu-sub-item relative min-w-0"
  >
    <div
      class="flex h-8 min-w-0 -translate-x-px cursor-not-allowed items-center gap-3 overflow-hidden rounded-md px-2 text-sm text-muted-foreground/60"
    >
      <span
        v-if="icon"
        class="grid size-4 shrink-0 place-content-center text-muted-foreground/50"
      >
        <Icon :icon="icon" class="inline-block size-4" />
      </span>
      <div class="min-w-0 flex-1 truncate">{{ label }}</div>
      <span
        v-if="comingSoon"
        class="shrink-0 rounded-full bg-muted px-1.5 py-0.5 text-[10px] font-medium text-muted-foreground"
      >
        {{ $t('SIDEBAR.COMING_SOON') }}
      </span>
    </div>
  </li>
  <Policy
    v-else
    :permissions="resolvePermissions(to)"
    :feature-flag="resolveFeatureFlag(to)"
    as="li"
    class="group/menu-sub-item relative min-w-0"
  >
    <component
      :is="to ? 'router-link' : 'div'"
      :to="to"
      :title="label"
      active-class=""
      exact-active-class=""
      class="flex h-8 min-w-0 -translate-x-px items-center gap-3 overflow-hidden rounded-md px-2 text-sm outline-none transition-colors"
      :class="
        isLeafActive
          ? 'bg-sidebar-accent font-medium text-sidebar-primary hover:bg-sidebar-accent hover:text-sidebar-primary'
          : 'text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground'
      "
      :aria-current="isLeafActive ? 'page' : undefined"
    >
      <component
        :is="component"
        v-if="shouldRenderComponent"
        v-bind="{ label, icon, active: isLeafActive, badgeCount }"
      />
      <template v-else>
        <span
          v-if="icon"
          class="grid size-4 shrink-0 place-content-center"
          :class="
            isLeafActive ? 'text-sidebar-primary' : 'text-muted-foreground'
          "
        >
          <Icon :icon="icon" class="inline-block size-4" />
        </span>
        <div class="min-w-0 flex-1 truncate">{{ label }}</div>
        <SidebarUnreadBadge :count="badgeCount" />
      </template>
    </component>
  </Policy>
</template>
