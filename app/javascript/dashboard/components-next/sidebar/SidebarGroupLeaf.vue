<script setup>
import { isVNode, computed } from 'vue';
import { useRoute } from 'vue-router';
import Icon from 'next/icon/Icon.vue';
import Policy from 'dashboard/components/policy.vue';
import { useSidebarContext } from './provider';
import SidebarUnreadBadge from './SidebarUnreadBadge.vue';
import SidebarTreeChrome from './SidebarTreeChrome.vue';
import {
  SIDEBAR_TREE_INDENT,
  isDotOnlyDepth,
  treeButtonClasses,
  treeButtonLevel,
  treeItemWrapperClass,
  treeRowClass,
  shouldConnectBranchDown,
} from './sidebarTree';

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
  depth: { type: Number, default: 1 },
  isLast: { type: Boolean, default: false },
});

const route = useRoute();
const { resolvePermissions, resolveFeatureFlag } = useSidebarContext();

const shouldRenderComponent = computed(() => {
  return typeof props.component === 'function' || isVNode(props.component);
});

const dotOnly = computed(() => isDotOnlyDepth(props.depth));

const buttonLevel = computed(() =>
  treeButtonLevel({
    depth: props.depth,
    isLeaf: dotOnly.value,
    collapsible: false,
  })
);

const rowClass = computed(() =>
  treeRowClass(buttonLevel.value, { dotOnly: dotOnly.value })
);

const connectDown = computed(() =>
  !dotOnly.value &&
  shouldConnectBranchDown({ isLast: props.isLast, depth: props.depth })
);

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

const showLeadingIcon = computed(
  () => Boolean(props.icon) && !dotOnly.value && !shouldRenderComponent.value
);
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <li
    v-if="disabled"
    :title="label"
    :class="treeItemWrapperClass(buttonLevel)"
  >
    <div :class="rowClass">
      <SidebarTreeChrome
        :mode="dotOnly ? 'dot' : 'branch'"
        :connect-down="connectDown"
      />
      <div :class="SIDEBAR_TREE_INDENT">
        <div
          :class="[
            treeButtonClasses(buttonLevel, false),
            'cursor-not-allowed text-muted-foreground/60',
          ]"
        >
          <span
            v-if="showLeadingIcon"
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
      </div>
    </div>
  </li>
  <Policy
    v-else
    :permissions="resolvePermissions(to)"
    :feature-flag="resolveFeatureFlag(to)"
    as="li"
    :class="treeItemWrapperClass(buttonLevel)"
  >
    <div :class="rowClass">
      <SidebarTreeChrome
        :mode="dotOnly ? 'dot' : 'branch'"
        :connect-down="connectDown"
      />
      <div :class="SIDEBAR_TREE_INDENT">
        <component
          :is="to ? 'router-link' : 'div'"
          :to="to"
          :title="label"
          active-class=""
          exact-active-class=""
          :class="treeButtonClasses(buttonLevel, isLeafActive)"
          :aria-current="isLeafActive ? 'page' : undefined"
        >
          <component
            :is="component"
            v-if="shouldRenderComponent"
            v-bind="{ label, icon, active: isLeafActive, badgeCount }"
          />
          <template v-else>
            <span
              v-if="showLeadingIcon"
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
      </div>
    </div>
  </Policy>
</template>
