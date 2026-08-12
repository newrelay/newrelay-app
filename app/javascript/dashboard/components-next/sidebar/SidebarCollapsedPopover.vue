<script setup>
import { computed, ref, onMounted, nextTick } from 'vue';
import { useRouter } from 'vue-router';
import { useSidebarContext } from './provider';
import { useMapGetter } from 'dashboard/composables/store';
import Icon from 'next/icon/Icon.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import SidebarUnreadBadge from './SidebarUnreadBadge.vue';

const props = defineProps({
  label: { type: String, required: true },
  children: { type: Array, default: () => [] },
  activeChild: { type: Object, default: undefined },
  triggerRect: { type: Object, default: () => ({ top: 0, left: 0 }) },
});

const emit = defineEmits(['close', 'mouseenter', 'mouseleave']);

const router = useRouter();
const { isAllowed, sidebarWidth } = useSidebarContext();

const expandedSubGroup = ref(null);
const popoverRef = ref(null);
const topPosition = ref(0);
const isRTL = useMapGetter('accounts/isRTL');
const skipTransition = ref(true);

const childHasAccessibleRoute = child => {
  if (child.children?.length) {
    return child.children.some(childHasAccessibleRoute);
  }
  return Boolean(child.to && isAllowed(child.to));
};

const toggleSubGroup = name => {
  expandedSubGroup.value = expandedSubGroup.value === name ? null : name;
};

const navigateAndClose = to => {
  router.push(to);
  emit('close');
};

const isActive = child => props.activeChild?.name === child.name;

const getAccessibleSubChildren = children =>
  (children || []).filter(childHasAccessibleRoute);

const renderIcon = icon => ({
  component: typeof icon === 'object' ? icon : Icon,
  props: typeof icon === 'string' ? { icon } : null,
});

const transition = computed(() =>
  skipTransition.value
    ? {}
    : {
        enterActiveClass: 'transition-all duration-200 ease-out',
        enterFromClass: 'opacity-0 -translate-y-2 max-h-0',
        enterToClass: 'opacity-100 translate-y-0 max-h-96',
        leaveActiveClass: 'transition-all duration-150 ease-in',
        leaveFromClass: 'opacity-100 translate-y-0 max-h-96',
        leaveToClass: 'opacity-0 -translate-y-2 max-h-0',
      }
);

const accessibleChildren = computed(() =>
  props.children.filter(childHasAccessibleRoute)
);

const findParentOfActive = (items, activeName) => {
  const list = items || [];
  const direct = list.find(child =>
    child.children?.some(sub => sub.name === activeName)
  );
  if (direct) return direct.name;

  return list.reduce((found, child) => {
    if (found || !child.children?.length) return found;
    return findParentOfActive(child.children, activeName);
  }, null);
};

onMounted(async () => {
  await nextTick();

  // Auto-expand subgroup if active child is inside it (supports nested Conversations)
  if (props.activeChild) {
    const parentName = findParentOfActive(
      props.children,
      props.activeChild.name
    );
    if (parentName) {
      expandedSubGroup.value = parentName;
      await nextTick();
    }
  }

  if (!props.triggerRect) return;

  const viewportHeight = window.innerHeight;
  const popoverHeight = popoverRef.value?.offsetHeight || 300;
  const { top: triggerTop } = props.triggerRect;

  topPosition.value =
    triggerTop + popoverHeight > viewportHeight - 20
      ? Math.max(20, viewportHeight - popoverHeight - 20)
      : triggerTop;

  await nextTick();
  skipTransition.value = false;
});
</script>

<template>
  <TeleportWithDirection>
    <div
      ref="popoverRef"
      class="fixed z-[100] min-w-[200px] max-w-[280px]"
      :style="{
        [isRTL ? 'right' : 'left']: `${sidebarWidth + 8}px`,
        top: `${topPosition}px`,
      }"
      @mouseenter="emit('mouseenter')"
      @mouseleave="emit('mouseleave')"
    >
      <div
        class="w-48 rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md outline-none"
      >
        <div class="px-2 py-1.5 text-sm font-semibold">
          {{ label }}
        </div>
        <div class="my-1 -mx-1 h-px bg-border" />
        <ul
          class="m-0 max-h-[400px] list-none overflow-y-auto p-0 no-scrollbar"
        >
          <template v-for="child in accessibleChildren" :key="child.name">
            <!-- SubGroup / collapsible with children -->
            <li v-if="child.children" class="py-0.5">
              <template v-if="child.collapsible">
                <!-- NewRelay: Conversations as section label + nested links -->
                <div
                  class="px-2 pt-2 pb-0.5 text-[11px] font-semibold uppercase tracking-wide text-muted-foreground"
                >
                  {{ child.label }}
                </div>
                <ul class="m-0 list-none p-0">
                  <template
                    v-for="sub in getAccessibleSubChildren(child.children)"
                    :key="sub.name"
                  >
                    <li v-if="sub.children" class="py-0.5">
                      <button
                        type="button"
                        class="relative flex w-full cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-left text-sm outline-none transition-colors hover:bg-accent hover:text-accent-foreground rtl:text-right"
                        @click="toggleSubGroup(sub.name)"
                      >
                        <Icon
                          v-if="sub.icon"
                          :icon="sub.icon"
                          class="mr-2 size-4 flex-shrink-0 text-muted-foreground"
                        />
                        <span class="flex-1 truncate">{{ sub.label }}</span>
                        <span
                          class="size-3 transition-transform i-lucide-chevron-down"
                          :class="{
                            'rotate-180': expandedSubGroup === sub.name,
                          }"
                        />
                      </button>
                      <Transition v-bind="transition">
                        <ul
                          v-if="expandedSubGroup === sub.name"
                          class="mt-1 m-0 list-none overflow-hidden p-0 ltr:pl-3 rtl:pr-3"
                        >
                          <li
                            v-for="leaf in getAccessibleSubChildren(
                              sub.children
                            )"
                            :key="leaf.name"
                            class="py-0.5"
                          >
                            <button
                              type="button"
                              class="relative flex w-full cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-left text-sm outline-none transition-colors hover:bg-accent hover:text-accent-foreground rtl:text-right"
                              :class="{
                                'bg-sidebar-accent font-medium text-sidebar-primary':
                                  isActive(leaf),
                              }"
                              @click="navigateAndClose(leaf.to)"
                            >
                              <component
                                :is="renderIcon(leaf.icon).component"
                                v-if="leaf.icon"
                                v-bind="renderIcon(leaf.icon).props"
                                class="mr-2 size-4 flex-shrink-0"
                                :class="
                                  isActive(leaf)
                                    ? 'text-sidebar-primary'
                                    : 'text-muted-foreground'
                                "
                              />
                              <span class="flex-1 truncate">{{
                                leaf.label
                              }}</span>
                              <SidebarUnreadBadge :count="leaf.badgeCount" />
                            </button>
                          </li>
                        </ul>
                      </Transition>
                    </li>
                    <li v-else class="py-0.5">
                      <button
                        type="button"
                        class="relative flex w-full cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-left text-sm outline-none transition-colors hover:bg-accent hover:text-accent-foreground rtl:text-right"
                        :class="{
                          'bg-sidebar-accent font-medium text-sidebar-primary':
                            isActive(sub),
                        }"
                        @click="navigateAndClose(sub.to)"
                      >
                        <component
                          :is="renderIcon(sub.icon).component"
                          v-if="sub.icon"
                          v-bind="renderIcon(sub.icon).props"
                          class="mr-2 size-4 flex-shrink-0"
                          :class="
                            isActive(sub)
                              ? 'text-sidebar-primary'
                              : 'text-muted-foreground'
                          "
                        />
                        <span class="flex-1 truncate">{{ sub.label }}</span>
                        <SidebarUnreadBadge :count="sub.badgeCount" />
                      </button>
                    </li>
                  </template>
                </ul>
              </template>
              <template v-else>
                <button
                  type="button"
                  class="relative flex w-full cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-left text-sm outline-none transition-colors hover:bg-accent hover:text-accent-foreground rtl:text-right"
                  @click="toggleSubGroup(child.name)"
                >
                  <Icon
                    v-if="child.icon"
                    :icon="child.icon"
                    class="mr-2 size-4 flex-shrink-0 text-muted-foreground"
                  />
                  <span class="flex-1 truncate">{{ child.label }}</span>
                  <span
                    class="size-3 transition-transform i-lucide-chevron-down"
                    :class="{
                      'rotate-180': expandedSubGroup === child.name,
                    }"
                  />
                </button>
                <Transition v-bind="transition">
                  <ul
                    v-if="expandedSubGroup === child.name"
                    class="mt-1 m-0 list-none overflow-hidden p-0 ltr:pl-3 rtl:pr-3"
                  >
                    <li
                      v-for="subChild in getAccessibleSubChildren(
                        child.children
                      )"
                      :key="subChild.name"
                      class="py-0.5"
                    >
                      <button
                        type="button"
                        class="relative flex w-full cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-left text-sm outline-none transition-colors hover:bg-accent hover:text-accent-foreground rtl:text-right"
                        :class="{
                          'bg-sidebar-accent font-medium text-sidebar-primary':
                            isActive(subChild),
                        }"
                        @click="navigateAndClose(subChild.to)"
                      >
                        <component
                          :is="renderIcon(subChild.icon).component"
                          v-if="subChild.icon"
                          v-bind="renderIcon(subChild.icon).props"
                          class="mr-2 size-4 flex-shrink-0"
                          :class="
                            isActive(subChild)
                              ? 'text-sidebar-primary'
                              : 'text-muted-foreground'
                          "
                        />
                        <span class="flex-1 truncate">{{
                          subChild.label
                        }}</span>
                        <SidebarUnreadBadge :count="subChild.badgeCount" />
                      </button>
                    </li>
                  </ul>
                </Transition>
              </template>
            </li>
            <!-- Direct child item -->
            <li v-else class="py-0.5">
              <button
                type="button"
                class="relative flex w-full cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-left text-sm outline-none transition-colors hover:bg-accent hover:text-accent-foreground rtl:text-right"
                :class="{
                  'bg-sidebar-accent font-medium text-sidebar-primary':
                    isActive(child),
                }"
                @click="navigateAndClose(child.to)"
              >
                <component
                  :is="renderIcon(child.icon).component"
                  v-if="child.icon"
                  v-bind="renderIcon(child.icon).props"
                  class="mr-2 size-4 flex-shrink-0"
                  :class="
                    isActive(child)
                      ? 'text-sidebar-primary'
                      : 'text-muted-foreground'
                  "
                />
                <span class="flex-1 truncate">{{ child.label }}</span>
                <SidebarUnreadBadge :count="child.badgeCount" />
              </button>
            </li>
          </template>
        </ul>
      </div>
    </div>
  </TeleportWithDirection>
</template>
