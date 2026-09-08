<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { cn } from '../utils/cn';
import {
  SIDEBAR_TREE_LIST_NESTED,
  SIDEBAR_TREE_INDENT,
  TREE_LEVEL,
  subLeafClasses,
  sectionHeaderClasses,
} from '../../sidebar/sidebarTree';
import SidebarTreeChrome from '../../sidebar/SidebarTreeChrome.vue';

const props = defineProps({
  brandName: { type: String, default: 'newrelay' },
  collapsed: { type: Boolean, default: false },
  sections: {
    type: Array,
    default: () => [],
  },
  activeHref: { type: String, default: '' },
});

const emit = defineEmits(['update:collapsed', 'navigate']);
const { t } = useI18n();

const openGroup = ref(null);

const isActive = href => href && props.activeHref === href;

const itemHasActiveChild = item => {
  if (isActive(item.href)) return true;
  return Boolean(item.children?.some(child => isActive(child.href)));
};

watch(
  () => [props.sections, props.activeHref],
  () => {
    const active = props.sections
      .flatMap(section => section.items || [])
      .find(item => itemHasActiveChild(item));
    openGroup.value = active?.title ?? null;
  },
  { immediate: true, deep: true }
);

const toggleGroup = title => {
  openGroup.value = openGroup.value === title ? null : title;
};

const onNavigate = href => {
  if (href) emit('navigate', href);
};

const widthClass = computed(() => (props.collapsed ? 'w-16' : 'w-60'));
</script>

<template>
  <aside
    :class="
      cn(
        'flex h-full flex-col border-r border-sidebar-border bg-sidebar text-sidebar-foreground transition-[width] duration-200 ease-linear',
        widthClass
      )
    "
  >
    <div
      :class="cn('flex flex-col gap-2 p-2 pb-6', collapsed && 'items-center')"
    >
      <div
        :class="
          cn(
            'flex h-12 w-full items-center gap-2 overflow-hidden rounded-md p-2 text-left text-sm',
            collapsed && 'justify-center p-1.5'
          )
        "
      >
        <span
          class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-sidebar-primary text-sm font-bold text-sidebar-primary-foreground"
        >
          {{ brandName.slice(0, 1).toUpperCase() }}
        </span>
        <div
          v-if="!collapsed"
          class="grid min-w-0 flex-1 text-left text-sm leading-tight"
        >
          <span class="truncate font-semibold text-sidebar-foreground">
            {{ brandName }}
          </span>
          <span class="truncate text-xs font-normal text-muted-foreground/60">
            {{ t('SIDEBAR.ENTERPRISE_EDITION') }}
          </span>
        </div>
      </div>
    </div>

    <nav class="flex min-h-0 flex-1 flex-col overflow-y-auto px-2 pt-0">
      <div
        v-for="(section, sectionIndex) in sections"
        :key="section.label || sectionIndex"
        :class="
          cn(
            'relative flex w-full min-w-0 flex-col p-2 pt-0',
            sectionIndex > 0 && 'mt-1'
          )
        "
      >
        <p
          v-if="section.label && !collapsed"
          class="mb-2 px-2 text-xs font-medium text-muted-foreground"
        >
          {{ section.label }}
        </p>

        <div class="flex w-full min-w-0 flex-col gap-0.5">
          <div v-for="item in section.items" :key="item.title" class="relative">
            <button
              type="button"
              :class="
                cn(
                  sectionHeaderClasses(itemHasActiveChild(item)),
                  collapsed && 'mx-auto size-9 justify-center p-0'
                )
              "
              @click="
                item.children?.length
                  ? toggleGroup(item.title)
                  : onNavigate(item.href)
              "
            >
              <span
                v-if="item.icon"
                :class="
                  cn(
                    item.icon,
                    'size-4 shrink-0',
                    itemHasActiveChild(item)
                      ? 'text-sidebar-primary'
                      : 'text-muted-foreground'
                  )
                "
              />
              <span v-if="!collapsed" class="min-w-0 flex-1 truncate">
                {{ item.title }}
              </span>
              <span
                v-if="!collapsed && item.children?.length"
                :class="
                  cn(
                    'i-lucide-chevron-right ml-auto size-4 shrink-0 text-muted-foreground transition-transform duration-200',
                    openGroup === item.title && 'rotate-90'
                  )
                "
              />
            </button>

            <ul
              v-if="
                !collapsed && item.children?.length && openGroup === item.title
              "
              :class="SIDEBAR_TREE_LIST_NESTED"
            >
              <li
                v-for="(child, index) in item.children"
                :key="child.href || child.title"
                class="relative min-w-0"
              >
                <SidebarTreeChrome
                  :level="TREE_LEVEL.LEAF"
                  :is-last="index === item.children.length - 1"
                />
                <div :class="SIDEBAR_TREE_INDENT">
                  <button
                    type="button"
                    :class="subLeafClasses(isActive(child.href))"
                    @click="onNavigate(child.href)"
                  >
                    <span class="truncate">{{ child.title }}</span>
                  </button>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </nav>

    <div v-if="collapsed" class="border-t border-sidebar-border p-2">
      <button
        type="button"
        class="inline-flex size-10 w-full items-center justify-center rounded-md text-muted-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
        @click="emit('update:collapsed', false)"
      >
        <span class="i-lucide-panel-left size-4" />
        <span class="sr-only">{{ t('SIDEBAR.EXPAND_SIDEBAR') }}</span>
      </button>
    </div>
  </aside>
</template>
