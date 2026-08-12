<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Policy from 'dashboard/components/policy.vue';
import { SETTINGS_NAV_SECTIONS } from '../settings.navigation';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { accountScopedRoute } = useAccount();
const { shouldShow } = usePolicy();

const accountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const hasAdvancedAssignment = computed(() =>
  isFeatureEnabledonAccount.value(
    accountId.value,
    FEATURE_FLAGS.ADVANCED_ASSIGNMENT
  )
);

const findRouteMeta = routeName => {
  const match = router.getRoutes().find(r => r.name === routeName);
  return match?.meta || {};
};

const isItemAllowed = item => {
  if (item.requiresAdvancedAssignment && !hasAdvancedAssignment.value) {
    return false;
  }
  const meta = findRouteMeta(item.routeName);
  return shouldShow(meta.featureFlag, meta.permissions, meta.installationTypes);
};

const isItemActive = item => {
  if (route.name === item.routeName) return true;
  return Boolean(item.activeOn?.includes(route.name));
};

const sections = computed(() =>
  SETTINGS_NAV_SECTIONS.map(section => ({
    ...section,
    label: t(section.labelKey),
    items: section.items.filter(isItemAllowed).map(item => ({
      ...item,
      label: t(item.labelKey),
      to: accountScopedRoute(item.routeName),
      active: isItemActive(item),
      meta: findRouteMeta(item.routeName),
    })),
  })).filter(section => section.items.length > 0)
);

const openSectionKey = ref(null);

const syncOpenSection = () => {
  const activeSection = sections.value.find(section =>
    section.items.some(item => item.active)
  );
  openSectionKey.value = activeSection?.key ?? sections.value[0]?.key ?? null;
};

watch(sections, syncOpenSection, { immediate: true, deep: true });
watch(
  () => route.name,
  () => syncOpenSection()
);

const toggleSection = key => {
  openSectionKey.value = openSectionKey.value === key ? null : key;
};
</script>

<template>
  <nav
    class="w-full shrink-0 space-y-1 lg:sticky lg:top-8 lg:w-56"
    :aria-label="t('SIDEBAR.SETTINGS_NAV')"
  >
    <div
      v-for="section in sections"
      :key="section.key"
      class="mb-4 flex flex-col"
    >
      <button
        type="button"
        class="group mb-1 flex w-full items-center justify-between rounded-lg px-3 py-2 text-left text-sm font-medium text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
        @click="toggleSection(section.key)"
      >
        <span class="flex items-center gap-2">
          <Icon :icon="section.icon" class="size-4 shrink-0" />
          {{ section.label }}
        </span>
        <span
          class="size-4 shrink-0 opacity-50 transition-opacity group-hover:opacity-100"
          :class="
            openSectionKey === section.key
              ? 'i-lucide-chevron-down'
              : 'i-lucide-chevron-right'
          "
        />
      </button>

      <div
        v-show="openSectionKey === section.key"
        class="relative my-1 ml-5 flex flex-col space-y-1 border-l border-border pl-4"
      >
        <Policy
          v-for="item in section.items"
          :key="item.key"
          :permissions="item.meta.permissions || []"
          :feature-flag="item.meta.featureFlag || null"
          :installation-types="item.meta.installationTypes || null"
          as="div"
        >
          <router-link
            :to="item.to"
            class="relative flex items-center justify-between rounded-lg px-3 py-2 text-left text-sm font-medium transition-colors"
            :class="
              item.active
                ? 'bg-muted text-foreground'
                : 'text-muted-foreground hover:bg-muted/50 hover:text-foreground'
            "
          >
            <span
              v-if="item.active"
              class="bg-primary ring-background absolute top-1/2 size-2.5 -translate-y-1/2 rounded-full ring-4 ltr:-left-[21px] rtl:-right-[21px]"
            />
            {{ item.label }}
          </router-link>
        </Policy>
      </div>
    </div>
  </nav>
</template>
