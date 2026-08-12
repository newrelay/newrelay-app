<script setup>
import { computed, onMounted, onUnmounted, watch, ref } from 'vue';
import { useSidebarContext, usePopoverState } from './provider';
import { useRoute, useRouter } from 'vue-router';
import Policy from 'dashboard/components/policy.vue';
import Icon from 'next/icon/Icon.vue';
import SidebarGroupHeader from './SidebarGroupHeader.vue';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarSubGroup from './SidebarSubGroup.vue';
import SidebarCollapsibleSubItem from './SidebarCollapsibleSubItem.vue';
import SidebarGroupEmptyLeaf from './SidebarGroupEmptyLeaf.vue';
import SidebarCollapsedPopover from './SidebarCollapsedPopover.vue';

const props = defineProps({
  name: { type: String, required: true },
  label: { type: String, required: true },
  icon: { type: [String, Object, Function], default: null },
  to: { type: Object, default: null },
  activeOn: { type: Array, default: () => [] },
  children: { type: Array, default: undefined },
  getterKeys: { type: Object, default: () => ({}) },
  click: { type: Function, default: null },
  danger: { type: Boolean, default: false },
});

const flattenNavLeaves = items =>
  (items || []).flatMap(child =>
    child.children?.length ? flattenNavLeaves(child.children) : [child]
  );

const childHasAccessibleRoute = (child, allowed) => {
  if (child.children?.length) {
    return child.children.some(sub => childHasAccessibleRoute(sub, allowed));
  }
  return Boolean(child.to && allowed(child.to));
};

const {
  expandedItem,
  setExpandedItem,
  expandItem,
  resolvePath,
  resolvePermissions,
  resolveFeatureFlag,
  isAllowed,
  isCollapsed,
  isResizing,
} = useSidebarContext();

const {
  activePopover,
  setActivePopover,
  closeActivePopover,
  scheduleClose,
  cancelClose,
} = usePopoverState();

const navigableChildren = computed(() => flattenNavLeaves(props.children));

const route = useRoute();
const router = useRouter();
const isExpanded = computed(() => expandedItem.value === props.name);
const isExpandable = computed(() => props.children);
const hasChildren = computed(
  () => Array.isArray(props.children) && props.children.length > 0
);

// Use shared popover state - only one popover can be open at a time
const isPopoverOpen = computed(() => activePopover.value === props.name);
const triggerRef = ref(null);
const triggerRect = ref({ top: 0, left: 0, bottom: 0, right: 0 });

const openPopover = () => {
  if (triggerRef.value) {
    const rect = triggerRef.value.getBoundingClientRect();
    triggerRect.value = {
      top: rect.top,
      left: rect.left,
      bottom: rect.bottom,
      right: rect.right,
    };
  }
  setActivePopover(props.name);
};

const closePopover = () => {
  if (activePopover.value === props.name) {
    closeActivePopover();
  }
};

const handleMouseEnter = () => {
  if (!hasChildren.value || isResizing.value) return;
  cancelClose();
  openPopover();
};

const handleMouseLeave = () => {
  if (!hasChildren.value) return;
  scheduleClose(200);
};

const handlePopoverMouseEnter = () => {
  cancelClose();
};

const handlePopoverMouseLeave = () => {
  scheduleClose(100);
};

// Close popover when mouse leaves the window
const handleWindowBlur = () => {
  closeActivePopover();
};

const accessibleItems = computed(() => {
  if (!hasChildren.value) return [];
  return props.children.filter(child =>
    childHasAccessibleRoute(child, isAllowed)
  );
});

const hasAccessibleChildren = computed(() => {
  return accessibleItems.value.length > 0;
});

// First navigable leaf under the group (for collapsed-icon click)
const firstNavigableLeaf = computed(() => {
  return navigableChildren.value.find(child => child.to && isAllowed(child.to));
});

// Route names for the live location (leaf + parents). Portal/Captain links use
// navigationPath redirectors whose resolved path is NOT the real URL.
const activeRouteNames = computed(() => {
  const names = route.matched.map(record => record.name).filter(Boolean);
  if (route.name && !names.includes(route.name)) names.push(route.name);
  return names;
});

// accountId is always current-account scope; navigationPath is a redirector hint,
// not a live route param. Only keys like teamId / inbox_id discriminate leaves.
const NON_DISCRIMINATING_PARAMS = new Set(['navigationPath', 'accountId']);

const discriminatingParamKeys = (childParams = {}) =>
  Object.keys(childParams || {}).filter(
    key => !NON_DISCRIMINATING_PARAMS.has(key) && key in route.params
  );

const paramsMatchChild = child => {
  const keys = discriminatingParamKeys(child.to?.params);
  if (!keys.length) return true;
  return keys.every(
    key => String(child.to.params[key]) === String(route.params[key])
  );
};

const childMatchesRoute = child => {
  if (!child?.to) return false;

  const names = activeRouteNames.value;
  const navPath = child.to.params?.navigationPath;

  // Prefer route-name match (activeOn and/or navigationPath === live route name).
  // Portal Settings: activeOn/navPath both use portals_settings_index.
  const nameMatch =
    child.activeOn?.some(name => names.includes(name)) ||
    (navPath && names.includes(navPath));

  if (nameMatch) {
    return paramsMatchChild(child);
  }

  // Skip path match for redirector links — resolvePath is a fake URL segment
  if (navPath) return false;

  const childPath = resolvePath(child.to);
  return route.path === childPath || route.path.startsWith(`${childPath}/`);
};

const isActive = computed(() => {
  if (props.activeOn.some(name => activeRouteNames.value.includes(name))) {
    return true;
  }

  if (props.to) {
    return route.path === resolvePath(props.to);
  }

  return false;
});

// We could use the RouterLink isActive too, but our routes are not always
// nested correctly, so we need to check the active state ourselves
// TODO: Audit the routes and fix the nesting and remove this
const activeChild = computed(() => {
  const matches = navigableChildren.value.filter(childMatchesRoute);
  if (!matches.length) return undefined;

  // Prefer the most specific param match (e.g. segmentId / teamId)
  return [...matches].sort((a, b) => {
    return (
      discriminatingParamKeys(b.to?.params).length -
      discriminatingParamKeys(a.to?.params).length
    );
  })[0];
});

const hasActiveChild = computed(() => {
  return activeChild.value !== undefined;
});

// Parent header highlight + keep group open for group-level activeOn (e.g. Captain create)
const shouldHighlight = computed(() => isActive.value || hasActiveChild.value);

const handleCollapsedClick = () => {
  if (hasChildren.value && firstNavigableLeaf.value?.to) {
    router.push(firstNavigableLeaf.value.to);
  }
};

const handleLeafClick = () => {
  if (props.click) {
    props.click();
  }
};

const toggleTrigger = () => {
  if (props.click) {
    props.click();
    return;
  }
  // Match AppSidebar: accordion toggle only (no auto-navigate on expand)
  setExpandedItem(props.name);
};

onMounted(() => {
  window.addEventListener('blur', handleWindowBlur);
  document.addEventListener('mouseleave', handleWindowBlur);
});

onUnmounted(() => {
  window.removeEventListener('blur', handleWindowBlur);
  document.removeEventListener('mouseleave', handleWindowBlur);
});

// Force-expand on route changes (do not toggle) so active leaf stays visible
watch(
  () => [shouldHighlight.value, route.name, route.fullPath],
  () => {
    if (shouldHighlight.value) {
      expandItem(props.name);
    }
  },
  { immediate: true }
);
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Policy
    v-if="!hasChildren || hasAccessibleChildren"
    :permissions="resolvePermissions(to)"
    :feature-flag="resolveFeatureFlag(to)"
    as="li"
    class="grid gap-0 text-sm cursor-pointer select-none min-w-0"
  >
    <!-- Collapsed State -->
    <template v-if="isCollapsed">
      <div
        class="relative"
        @mouseenter="handleMouseEnter"
        @mouseleave="handleMouseLeave"
      >
        <component
          :is="to && !hasChildren ? 'router-link' : 'button'"
          ref="triggerRef"
          :to="to && !hasChildren ? to : undefined"
          type="button"
          class="peer/menu-button relative mx-auto flex size-10 items-center justify-center rounded-md p-2 transition-colors"
          :class="{
            'bg-sidebar-primary/10 font-medium text-sidebar-primary before:absolute before:inset-y-1.5 before:w-[3px] before:rounded-r-md before:bg-sidebar-primary ltr:before:-left-3 rtl:before:-right-3':
              shouldHighlight,
            'text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground':
              !shouldHighlight,
          }"
          :title="label"
          @click="hasChildren ? handleCollapsedClick() : handleLeafClick()"
        >
          <Icon
            v-if="icon"
            :icon="icon"
            class="size-5 shrink-0"
            :class="
              shouldHighlight ? 'text-sidebar-primary' : 'text-muted-foreground'
            "
          />
          <span class="sr-only">{{ label }}</span>
        </component>
        <SidebarCollapsedPopover
          v-if="hasChildren && isPopoverOpen"
          :label="label"
          :children="children"
          :active-child="activeChild"
          :trigger-rect="triggerRect"
          @close="closePopover"
          @mouseenter="handlePopoverMouseEnter"
          @mouseleave="handlePopoverMouseLeave"
        />
      </div>
    </template>
    <!-- Expanded State -->
    <template v-else>
      <SidebarGroupHeader
        :icon
        :name
        :label
        :to
        :danger="danger"
        :getter-keys="getterKeys"
        :is-active="isActive"
        :has-active-child="hasActiveChild"
        :expandable="hasChildren"
        :is-expanded="isExpanded"
        @toggle="toggleTrigger"
      />
      <div
        v-if="hasChildren"
        class="grid transition-[grid-template-rows] duration-200 ease-out"
        :class="isExpanded ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'"
      >
        <div class="overflow-hidden">
          <ul
            class="mx-3.5 flex min-w-0 list-none flex-col gap-1 border-l border-sidebar-border py-0.5 ltr:translate-x-px ltr:pl-5 ltr:pr-2 rtl:-translate-x-px rtl:pr-5 rtl:pl-2"
          >
            <template v-for="child in children" :key="child.name">
              <SidebarCollapsibleSubItem
                v-if="child.collapsible && child.children"
                :label="child.label"
                :children="child.children"
                :active-child="activeChild"
                :is-parent-expanded="isExpanded"
                :default-open="child.defaultOpen !== false"
              />
              <SidebarSubGroup
                v-else-if="child.children"
                :label="child.label"
                :icon="child.icon"
                :children="child.children"
                :is-expanded="isExpanded"
                :active-child="activeChild"
              />
              <SidebarGroupLeaf
                v-else-if="isAllowed(child.to)"
                v-bind="child"
                :active="activeChild?.name === child.name"
              />
            </template>
          </ul>
        </div>
      </div>
      <ul v-else-if="isExpandable && isExpanded">
        <SidebarGroupEmptyLeaf />
      </ul>
    </template>
  </Policy>
</template>
