<script setup>
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, ref, watch } from 'vue';
import { picoSearch } from '@scmmishra/pico-search';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

const PER_PAGE_OPTIONS = [5, 10, 20, 50];

const store = useStore();
const router = useRouter();
const { t } = useI18n();
const getters = useStoreGetters();
const { isAdmin } = useAdmin();

const loading = ref({});
const searchQuery = ref('');
const teamsViewType = ref('list');
const currentPage = ref(1);
const itemsPerPage = ref(10);
const openMenuId = ref(null);
const showPerPageMenu = ref(false);

const teamsList = useMapGetter('teams/getTeams');

const filteredTeamsList = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return teamsList.value;
  return picoSearch(teamsList.value, query, ['name', 'description']);
});

const totalItems = computed(() => filteredTeamsList.value.length);

const totalPages = computed(() =>
  Math.max(1, Math.ceil(totalItems.value / itemsPerPage.value))
);

const startItem = computed(() => {
  if (!totalItems.value) return 0;
  return (currentPage.value - 1) * itemsPerPage.value + 1;
});

const endItem = computed(() =>
  Math.min(currentPage.value * itemsPerPage.value, totalItems.value)
);

const paginatedTeams = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage.value;
  return filteredTeamsList.value.slice(start, start + itemsPerPage.value);
});

const pageNumbers = computed(() =>
  Array.from({ length: totalPages.value }, (_, i) => i + 1)
);

const uiFlags = computed(() => getters['teams/getUIFlags'].value);

watch([searchQuery, itemsPerPage], () => {
  currentPage.value = 1;
});

watch(totalPages, pages => {
  if (currentPage.value > pages) currentPage.value = pages;
});

const deleteTeam = async ({ id }) => {
  try {
    loading.value[id] = true;
    await store.dispatch('teams/delete', id);
    useAlert(t('TEAMS_SETTINGS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('TEAMS_SETTINGS.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
  }
};

const showDeletePopup = ref(false);
const selectedTeam = ref({});

const openDelete = team => {
  openMenuId.value = null;
  showDeletePopup.value = true;
  selectedTeam.value = team;
};

const closeDelete = () => {
  showDeletePopup.value = false;
  selectedTeam.value = {};
};

const confirmDeletion = () => {
  deleteTeam(selectedTeam.value);
  closeDelete();
};

const openCreateTeam = () => {
  router.push({ name: 'settings_teams_new' });
};

const openTeamView = team => {
  router.push({
    name: 'settings_teams_edit',
    params: { teamId: team.id },
  });
};

const toggleMenu = teamId => {
  openMenuId.value = openMenuId.value === teamId ? null : teamId;
};

const closeMenu = teamId => {
  if (openMenuId.value === teamId) openMenuId.value = null;
};

const closePerPageMenu = () => {
  showPerPageMenu.value = false;
};

const menuItems = computed(() => [
  {
    label: t('TEAMS_SETTINGS.LIST.EDIT_TEAM'),
    action: 'edit',
    value: 'edit',
    icon: 'i-lucide-pencil',
  },
  {
    label: t('TEAMS_SETTINGS.DELETE.BUTTON_TEXT'),
    action: 'delete',
    value: 'delete',
    icon: 'i-lucide-trash-2',
  },
]);

const handleMenuAction = (team, { action }) => {
  openMenuId.value = null;
  if (action === 'edit') {
    openTeamView(team);
    return;
  }
  if (action === 'delete') {
    openDelete(team);
  }
};

const setPage = page => {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page;
  }
};

const setPerPage = size => {
  itemsPerPage.value = size;
  showPerPageMenu.value = false;
};

const deleteConfirmText = computed(
  () => `${t('TEAMS_SETTINGS.DELETE.CONFIRM.YES')} ${selectedTeam.value.name}`
);

const deleteRejectText = computed(() => t('TEAMS_SETTINGS.DELETE.CONFIRM.NO'));

const confirmDeleteTitle = computed(() =>
  t('TEAMS_SETTINGS.DELETE.CONFIRM.TITLE', {
    teamName: selectedTeam.value.name,
  })
);

const confirmPlaceHolderText = computed(() =>
  t('TEAMS_SETTINGS.DELETE.CONFIRM.PLACE_HOLDER', {
    teamName: selectedTeam.value.name,
  })
);
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('TEAMS_SETTINGS.LOADING')"
    :no-records-found="false"
  >
    <template #body>
      <div class="space-y-6">
        <!-- Toolbar: search left, Create Team + view toggles right -->
        <div
          class="flex flex-col items-center justify-between gap-4 lg:flex-row"
        >
          <div class="relative w-full sm:w-64">
            <Icon
              icon="i-lucide-search"
              class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
            />
            <RelayInput
              v-model="searchQuery"
              type="search"
              :placeholder="$t('TEAMS_SETTINGS.SEARCH_PLACEHOLDER')"
              class-name="h-9 bg-background pl-9 shadow-none"
            />
          </div>

          <div class="flex w-full items-center gap-3 lg:w-auto">
            <RelayButton
              v-if="isAdmin"
              class="h-9 w-full whitespace-nowrap shadow-sm lg:w-auto"
              @click="openCreateTeam"
            >
              {{ $t('TEAMS_SETTINGS.NEW_TEAM') }}
            </RelayButton>
            <div
              class="hidden h-9 shrink-0 items-center overflow-hidden rounded-md border border-border/80 bg-background shadow-xs lg:flex"
            >
              <button
                type="button"
                class="flex h-full items-center justify-center border-r border-border/40 px-3 transition-colors"
                :class="[
                  teamsViewType === 'grid'
                    ? 'bg-primary/5 text-primary'
                    : 'bg-muted/50 text-muted-foreground hover:bg-muted',
                ]"
                :aria-label="$t('TEAMS_SETTINGS.VIEW.GRID')"
                @click="teamsViewType = 'grid'"
              >
                <Icon icon="i-lucide-layout-grid" class="size-4" />
              </button>
              <button
                type="button"
                class="flex h-full items-center justify-center px-3 transition-colors"
                :class="[
                  teamsViewType === 'list'
                    ? 'bg-primary/5 text-primary'
                    : 'text-muted-foreground hover:bg-muted',
                ]"
                :aria-label="$t('TEAMS_SETTINGS.VIEW.LIST')"
                @click="teamsViewType = 'list'"
              >
                <Icon icon="i-lucide-list" class="size-4" />
              </button>
            </div>
          </div>
        </div>

        <!-- Empty states -->
        <div
          v-if="!filteredTeamsList.length"
          class="rounded-xl border border-border/60 bg-card shadow-xs"
        >
          <div
            v-if="searchQuery"
            class="px-6 py-16 text-center text-sm text-muted-foreground"
          >
            {{ $t('TEAMS_SETTINGS.NO_RESULTS') }}
          </div>
          <div
            v-else
            class="flex flex-col items-center justify-center px-6 py-16"
          >
            <div
              class="mb-5 flex size-16 items-center justify-center rounded-full border border-border bg-muted/50"
            >
              <Icon
                icon="i-lucide-users-round"
                class="size-7 text-muted-foreground/70"
              />
            </div>
            <h3 class="mb-1.5 text-base font-semibold text-foreground">
              {{ $t('TEAMS_SETTINGS.LIST.EMPTY_TITLE') }}
            </h3>
            <p
              class="mb-6 max-w-sm text-center text-[13.5px] leading-relaxed text-muted-foreground"
            >
              {{ $t('TEAMS_SETTINGS.LIST.EMPTY_DESC') }}
            </p>
            <RelayButton
              v-if="isAdmin"
              class="h-9 shadow-sm"
              @click="openCreateTeam"
            >
              <Icon icon="i-lucide-plus" class="size-4" />
              {{ $t('TEAMS_SETTINGS.NEW_TEAM') }}
            </RelayButton>
          </div>
        </div>

        <!-- Teams list / grid -->
        <template v-else>
          <div
            :class="
              teamsViewType === 'grid'
                ? 'grid grid-cols-1 gap-5 md:grid-cols-2 lg:grid-cols-3'
                : 'flex flex-col gap-3'
            "
          >
            <div
              v-for="team in paginatedTeams"
              :key="team.id"
              class="group flex rounded-xl border border-border/80 bg-card p-5 shadow-xs transition-colors hover:border-border"
              :class="[
                teamsViewType === 'grid'
                  ? 'h-full flex-col gap-5'
                  : 'flex-col gap-6 lg:flex-row lg:items-center',
              ]"
            >
              <div
                class="flex gap-4"
                :class="[
                  teamsViewType === 'grid'
                    ? 'w-full flex-col items-start'
                    : 'flex-row items-start lg:flex-[1.5]',
                ]"
              >
                <div
                  class="flex size-12 shrink-0 items-center justify-center rounded-xl bg-primary/10"
                >
                  <Icon
                    icon="i-lucide-users-round"
                    class="size-6 text-primary"
                  />
                </div>
                <div class="min-w-0">
                  <div class="mb-1 flex items-center gap-2">
                    <h3 class="text-[16px] font-semibold text-foreground">
                      {{ team.name }}
                    </h3>
                  </div>
                  <p
                    v-if="team.description"
                    class="pr-4 text-[13px] leading-relaxed text-muted-foreground"
                  >
                    {{ team.description }}
                  </p>
                </div>
              </div>

              <div
                class="flex shrink-0 items-center gap-3"
                :class="[
                  teamsViewType === 'grid'
                    ? 'mt-auto justify-between border-t border-border/40 pt-4'
                    : 'justify-end lg:ml-auto',
                ]"
              >
                <RelayButton
                  v-if="isAdmin"
                  variant="outline"
                  class="h-9 border-border/80 bg-background px-4 text-[13px] font-medium shadow-xs"
                  @click="openTeamView(team)"
                >
                  {{ $t('TEAMS_SETTINGS.LIST.VIEW_TEAM') }}
                </RelayButton>

                <div
                  v-if="isAdmin"
                  v-on-clickaway="() => closeMenu(team.id)"
                  class="relative"
                >
                  <RelayButton
                    variant="outline"
                    size="icon"
                    class="size-9 border-border/80 bg-background p-0 text-muted-foreground shadow-xs hover:bg-muted hover:text-foreground"
                    :disabled="loading[team.id]"
                    @click="toggleMenu(team.id)"
                  >
                    <Icon icon="i-lucide-ellipsis-vertical" class="size-4" />
                  </RelayButton>
                  <DropdownMenu
                    v-if="openMenuId === team.id"
                    :menu-items="menuItems"
                    class="top-full mt-1 ltr:right-0 rtl:left-0"
                    @action="handleMenuAction(team, $event)"
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- Pagination footer -->
          <div class="mt-4 flex items-center justify-between pt-4">
            <div class="text-[13px] font-medium text-muted-foreground">
              {{
                $t('TEAMS_SETTINGS.PAGINATION.SHOWING', {
                  startItem,
                  endItem,
                  totalItems,
                })
              }}
            </div>
            <div class="flex items-center gap-4">
              <div class="flex items-center gap-1.5">
                <RelayButton
                  variant="outline"
                  size="icon"
                  class="size-8 border-border/80 bg-background p-0 shadow-xs"
                  :disabled="currentPage <= 1"
                  @click="setPage(currentPage - 1)"
                >
                  <Icon
                    icon="i-lucide-chevron-left"
                    class="size-4 text-muted-foreground"
                  />
                </RelayButton>
                <RelayButton
                  v-for="page in pageNumbers"
                  :key="page"
                  variant="outline"
                  size="icon"
                  class="size-8 border-border/80 bg-background p-0 font-medium shadow-xs"
                  :class="[
                    page === currentPage
                      ? 'border-primary text-primary hover:bg-primary/5'
                      : 'text-foreground hover:bg-muted/50',
                  ]"
                  @click="setPage(page)"
                >
                  {{ page }}
                </RelayButton>
                <RelayButton
                  variant="outline"
                  size="icon"
                  class="size-8 border-border/80 bg-background p-0 shadow-xs"
                  :disabled="currentPage >= totalPages"
                  @click="setPage(currentPage + 1)"
                >
                  <Icon
                    icon="i-lucide-chevron-right"
                    class="size-4 text-muted-foreground"
                  />
                </RelayButton>
              </div>

              <div v-on-clickaway="closePerPageMenu" class="relative">
                <RelayButton
                  variant="outline"
                  class="h-8 w-[95px] justify-between border-border/80 bg-background px-3 text-[12px] font-medium shadow-xs"
                  @click="showPerPageMenu = !showPerPageMenu"
                >
                  {{
                    $t('TEAMS_SETTINGS.PAGINATION.PER_PAGE', {
                      size: itemsPerPage,
                    })
                  }}
                  <Icon
                    icon="i-lucide-chevron-down"
                    class="size-3.5 opacity-50"
                  />
                </RelayButton>
                <div
                  v-if="showPerPageMenu"
                  class="absolute bottom-full right-0 z-50 mb-1 min-w-full overflow-hidden rounded-md border border-border bg-card py-1 shadow-md"
                >
                  <button
                    v-for="size in PER_PAGE_OPTIONS"
                    :key="size"
                    type="button"
                    class="flex w-full px-3 py-1.5 text-left text-[12px] font-medium text-foreground hover:bg-muted"
                    :class="{
                      'bg-primary/5 text-primary': size === itemsPerPage,
                    }"
                    @click="setPerPage(size)"
                  >
                    {{ $t('TEAMS_SETTINGS.PAGINATION.PER_PAGE', { size }) }}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>
    </template>

    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="confirmDeleteTitle"
      :message="$t('TEAMS_SETTINGS.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedTeam.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      @on-confirm="confirmDeletion"
      @on-close="closeDelete"
    />
  </SettingsLayout>
</template>
