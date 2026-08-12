<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { buildPortalURL } from 'dashboard/helper/portalHelper';

import { RelayButton } from 'dashboard/components-next/relay';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const emit = defineEmits(['close', 'createPortal']);

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const DEFAULT_ROUTE = 'portals_articles_index';
const CATEGORY_ROUTE = 'portals_categories_index';
const CATEGORY_SUB_ROUTES = [
  'portals_categories_articles_index',
  'portals_categories_articles_new',
  'portals_categories_articles_edit',
];

const portals = useMapGetter('portals/allPortals');

const currentPortalSlug = computed(() => route.params.portalSlug);

const portalLink = computed(() => {
  return buildPortalURL(currentPortalSlug.value);
});

const isPortalActive = portal => {
  return portal.slug === currentPortalSlug.value;
};

const getPortalThumbnailSrc = portal => {
  return portal?.logo?.file_url || '';
};

const fetchPortalAndItsCategories = async (slug, locale) => {
  await store.dispatch('portals/switchPortal', true);
  await store.dispatch('portals/index');
  const selectedPortalParam = {
    portalSlug: slug,
    locale,
  };
  await store.dispatch('portals/show', selectedPortalParam);
  await store.dispatch('categories/index', selectedPortalParam);
  await store.dispatch('agents/get');
  await store.dispatch('portals/switchPortal', false);
};

const handlePortalChange = async portal => {
  if (isPortalActive(portal)) return;
  const {
    slug,
    meta: { default_locale: defaultLocale },
  } = portal;
  emit('close');
  await fetchPortalAndItsCategories(slug, defaultLocale);
  const targetRouteName = CATEGORY_SUB_ROUTES.includes(route.name)
    ? CATEGORY_ROUTE
    : route.name || DEFAULT_ROUTE;
  router.push({
    name: targetRouteName,
    params: {
      portalSlug: slug,
      locale: defaultLocale,
    },
  });
};

const openCreatePortalDialog = () => {
  emit('createPortal');
  emit('close');
};

const onClickPreviewPortal = () => {
  window.open(portalLink.value, '_blank');
};

const redirectToPortalHomePage = () => {
  router.push({
    name: 'portals_index',
    params: {
      navigationPath: DEFAULT_ROUTE,
    },
  });
};
</script>

<template>
  <div
    class="absolute z-50 flex w-[280px] flex-col gap-1.5 rounded-xl border border-border bg-background p-1.5 shadow-md"
  >
    <div
      class="mb-1.5 flex items-center justify-between gap-3 border-b border-border/40 px-2 pb-2.5 pt-2"
    >
      <div class="flex min-w-0 flex-col gap-1">
        <div class="flex items-center gap-1.5">
          <button
            type="button"
            class="truncate text-[14px] font-semibold leading-none text-foreground hover:underline"
            @click="redirectToPortalHomePage"
          >
            {{ t('HELP_CENTER.PORTAL_SWITCHER.PORTALS') }}
          </button>
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-6 text-muted-foreground"
            @click="onClickPreviewPortal"
          >
            <span class="i-lucide-arrow-up-right size-3.5" aria-hidden="true" />
          </RelayButton>
        </div>
        <p class="text-[12px] leading-none text-muted-foreground">
          {{ t('HELP_CENTER.PORTAL_SWITCHER.CREATE_PORTAL') }}
        </p>
      </div>
      <RelayButton
        variant="outline"
        size="sm"
        class="h-7 shrink-0 px-2.5 text-[12px]"
        @click="openCreatePortalDialog"
      >
        <span class="i-lucide-plus size-3.5" aria-hidden="true" />
        {{ t('HELP_CENTER.PORTAL_SWITCHER.NEW_PORTAL') }}
      </RelayButton>
    </div>
    <div v-if="portals.length > 0" class="flex flex-col gap-0.5">
      <button
        v-for="(portal, index) in portals"
        :key="index"
        type="button"
        class="flex cursor-pointer items-center rounded-md px-2 py-2 text-left transition-colors hover:bg-muted"
        @click="handlePortalChange(portal)"
      >
        <Avatar
          v-if="portal"
          :name="portal.name"
          :src="getPortalThumbnailSrc(portal)"
          :size="28"
          icon-name="i-lucide-layout-grid"
          class="mr-3 shrink-0"
        />
        <div
          v-else
          class="mr-3 flex size-7 shrink-0 items-center justify-center rounded bg-primary/10"
        >
          <span class="i-lucide-layout-grid size-4 text-primary" />
        </div>
        <span class="truncate text-[13px] font-semibold text-foreground">
          {{ portal.name || '' }}
        </span>
        <span
          v-if="portal.custom_domain"
          class="ml-2 truncate text-[13px] text-muted-foreground"
        >
          {{ portal.custom_domain }}
        </span>
        <span
          v-if="isPortalActive(portal)"
          class="i-lucide-check ml-auto size-4 shrink-0 text-primary"
          aria-hidden="true"
        />
      </button>
    </div>
  </div>
</template>
