<script setup>
import { ref, computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store.js';

import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import PortalSwitcher from 'dashboard/components-next/HelpCenter/PortalSwitcher/PortalSwitcher.vue';
import CreatePortalDialog from 'dashboard/components-next/HelpCenter/PortalSwitcher/CreatePortalDialog.vue';

defineProps({
  currentPage: {
    type: Number,
    default: 1,
  },
  totalItems: {
    type: Number,
    default: 100,
  },
  itemsPerPage: {
    type: Number,
    default: 25,
  },
  showHeaderTitle: {
    type: Boolean,
    default: true,
  },
  showPaginationFooter: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['update:currentPage']);

const route = useRoute();

const createPortalDialogRef = ref(null);

const showPortalSwitcher = ref(false);

const portals = useMapGetter('portals/allPortals');

const currentPortalSlug = computed(() => route.params.portalSlug);

const activePortalName = computed(() => {
  return portals.value?.find(portal => portal.slug === currentPortalSlug.value)
    ?.name;
});

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};
const togglePortalSwitcher = () => {
  showPortalSwitcher.value = !showPortalSwitcher.value;
};
</script>

<template>
  <section
    class="relative flex h-full w-full flex-col overflow-hidden bg-muted/10 animate-in fade-in duration-300"
  >
    <div
      class="mx-auto flex h-full w-full max-w-7xl flex-col overflow-hidden p-4 pb-12 sm:p-8"
    >
      <div v-if="showHeaderTitle" class="mb-6 flex w-full flex-col gap-4">
        <div v-if="activePortalName" class="relative shrink-0 self-start">
          <OnClickOutside @trigger="showPortalSwitcher = false">
            <RelayButton
              variant="outline"
              class="h-9 px-3 text-[14px] font-medium"
              @click="togglePortalSwitcher"
            >
              {{ activePortalName }}
              <span
                class="i-lucide-chevron-down size-3.5 opacity-50"
                aria-hidden="true"
              />
            </RelayButton>

            <PortalSwitcher
              v-if="showPortalSwitcher"
              class="absolute ltr:left-0 rtl:right-0 top-11 z-50"
              @close="showPortalSwitcher = false"
              @create-portal="createPortalDialogRef.dialogRef.open()"
            />
          </OnClickOutside>
          <CreatePortalDialog ref="createPortalDialogRef" />
        </div>

        <div class="w-full min-w-0">
          <slot name="header-actions" />
        </div>
      </div>
      <div v-else class="shrink-0">
        <slot name="header-actions" />
      </div>

      <main class="min-h-0 flex-1 overflow-y-auto">
        <slot name="content" />
      </main>

      <footer v-if="showPaginationFooter" class="sticky bottom-0 z-10">
        <PaginationFooter
          :current-page="currentPage"
          :total-items="totalItems"
          :items-per-page="itemsPerPage"
          class="max-w-7xl"
          @update:current-page="updateCurrentPage"
        />
      </footer>
    </div>
    <!-- Do not remove this slot. It can be used to add dialogs. -->
    <slot />
  </section>
</template>
