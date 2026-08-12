<script setup>
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';
import MacrosTableRow from './MacrosTableRow.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, onMounted, ref, watch, provide } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useRoute, useRouter } from 'vue-router';
import { MACRO_ACTION_TYPES } from './constants';
import { useMacros } from 'dashboard/composables/useMacros';
import actionQueryGenerator from 'dashboard/helper/actionQueryGenerator.js';
import MacroForm from './MacroForm.vue';
import { RelayConfirmModal } from 'dashboard/components-next/relay';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();
const route = useRoute();
const router = useRouter();
const { getMacroDropdownValues } = useMacros();

const showDeleteConfirmationPopup = ref(false);
const selectedMacro = ref({});
const searchQuery = ref('');

const isBuilderOpen = ref(false);
const macro = ref(null);
const mode = ref('CREATE');

const macroActionTypes = computed(() => {
  return MACRO_ACTION_TYPES.map(type => ({
    ...type,
    label: t(`MACROS.ACTIONS.${type.label}`),
  }));
});

provide('macroActionTypes', macroActionTypes);

const records = computed(() => getters['macros/getMacros'].value);
const uiFlags = computed(() => getters['macros/getUIFlags'].value);

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, ['name']);
});

const isPublicMacroReadOnly = computed(
  () => macro.value?.visibility === 'global' && !isAdmin.value
);

const deleteMessage = computed(() => ` ${selectedMacro.value.name}?`);

const fetchDropdownData = () => {
  store.dispatch('agents/get');
  store.dispatch('teams/get');
  store.dispatch('labels/get');
};

const formatMacro = macroData => {
  const formattedActions = macroData.actions.map(action => {
    let actionParams = [];
    if (action.action_params.length) {
      const inputType = macroActionTypes.value.find(
        item => item.key === action.action_name
      ).inputType;
      if (inputType === 'multi_select' || inputType === 'search_select') {
        actionParams = getMacroDropdownValues(action.action_name).filter(item =>
          [...action.action_params].includes(item.id)
        );
      } else if (inputType === 'team_message') {
        actionParams = {
          team_ids: getMacroDropdownValues(action.action_name).filter(item =>
            [...action.action_params[0].team_ids].includes(item.id)
          ),
          message: action.action_params[0].message,
        };
      } else actionParams = [...action.action_params];
    }
    return {
      ...action,
      action_params: actionParams,
    };
  });
  return {
    ...macroData,
    actions: formattedActions,
  };
};

const manifestMacro = async macroId => {
  await store.dispatch('macros/getSingleMacro', macroId);
  const singleMacro = store.getters['macros/getMacro'](macroId);
  if (singleMacro) {
    macro.value = formatMacro(singleMacro);
  }
};

const initNewMacro = () => {
  mode.value = 'CREATE';
  macro.value = {
    name: '',
    actions: [
      {
        action_name: 'assign_team',
        action_params: [],
      },
    ],
    visibility: isAdmin.value ? 'global' : 'personal',
  };
};

const checkRouteAndOpenBuilder = async () => {
  fetchDropdownData();
  if (route.name === 'macros_new') {
    initNewMacro();
    isBuilderOpen.value = true;
  } else if (route.name === 'macros_edit' && route.params.macroId) {
    mode.value = 'EDIT';
    isBuilderOpen.value = true;
    await manifestMacro(route.params.macroId);
  } else {
    isBuilderOpen.value = false;
    macro.value = null;
  }
};

const openNewMacroBuilder = () => {
  initNewMacro();
  isBuilderOpen.value = true;
  router.push({ name: 'macros_new' });
};

const openEditMacroBuilder = async macroId => {
  mode.value = 'EDIT';
  isBuilderOpen.value = true;
  router.push({ name: 'macros_edit', params: { macroId } });
  await manifestMacro(macroId);
};

watch(
  () => route.name,
  () => {
    checkRouteAndOpenBuilder();
  },
  { immediate: true }
);

watch(
  () => route.params.macroId,
  () => {
    checkRouteAndOpenBuilder();
  }
);

onMounted(() => {
  store.dispatch('macros/get');
});

const deleteMacro = async id => {
  try {
    await store.dispatch('macros/delete', id);
    useAlert(t('MACROS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('MACROS.DELETE.API.ERROR_MESSAGE'));
  }
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  selectedMacro.value = response;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const confirmDeletion = () => {
  closeDeletePopup();
  deleteMacro(selectedMacro.value.id);
};

const closeBuilder = () => {
  router.push({ name: 'macros_wrapper' });
};

const saveMacro = async macroData => {
  if (isPublicMacroReadOnly.value) return;

  try {
    const action = mode.value === 'EDIT' ? 'macros/update' : 'macros/create';
    const successMessage =
      mode.value === 'EDIT'
        ? t('MACROS.EDIT.API.SUCCESS_MESSAGE')
        : t('MACROS.ADD.API.SUCCESS_MESSAGE');
    let serializedMacro = JSON.parse(JSON.stringify(macroData));
    serializedMacro.actions = actionQueryGenerator(serializedMacro.actions);
    await store.dispatch(action, serializedMacro);
    useAlert(successMessage);
    closeBuilder();
  } catch (error) {
    useAlert(t('MACROS.ERROR'));
  }
};
</script>

<template>
  <SettingsLayout
    :no-records-message="$t('MACROS.LIST.404')"
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('MACROS.LOADING')"
    feature-name="macros"
  >
    <template #header>
      <div
        class="pb-6 border-b border-border/40 flex flex-col sm:flex-row sm:items-center justify-between gap-4"
      >
        <div>
          <h3 class="text-base font-semibold text-foreground">
            {{ $t('MACROS.HEADER') }}
          </h3>
          <p class="text-sm text-muted-foreground mt-1 max-w-3xl">
            {{ $t('MACROS.DESCRIPTION') }}
          </p>
        </div>
        <Button
          class="shrink-0 h-9 px-4 font-medium shadow-sm bg-primary hover:bg-primary/90 text-primary-foreground border-0 text-[13px]"
          @click="openNewMacroBuilder"
        >
          {{ $t('MACROS.HEADER_BTN_TXT') }}
        </Button>
      </div>
    </template>
    <template #body>
      <!-- Toolbar -->
      <div
        class="flex items-center justify-between bg-card border border-border/60 p-2 rounded-xl shadow-sm mb-6 mt-4"
      >
        <div class="relative w-full max-w-md">
          <span
            class="i-lucide-search size-4 absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground block"
          />
          <input
            v-model="searchQuery"
            :placeholder="$t('MACROS.SEARCH_PLACEHOLDER')"
            class="pl-9 bg-background/50 border border-border/40 focus:border-border/80 shadow-none h-9 w-full text-[13.5px] rounded-lg outline-none focus-visible:ring-1 focus-visible:ring-primary/20 focus-visible:bg-background"
          />
        </div>
        <div
          class="px-4 text-[13px] font-medium text-muted-foreground shrink-0 border-l border-border/40"
        >
          {{ filteredRecords.length }}
          {{
            $t('MACROS.COUNT', { n: filteredRecords.length })
              .replace(/[0-9]/g, '')
              .trim()
          }}
        </div>
      </div>

      <!-- List View Table -->
      <div
        class="bg-card border border-border/60 rounded-xl shadow-sm overflow-hidden"
      >
        <div
          v-if="filteredRecords.length === 0"
          class="p-16 text-center flex flex-col items-center justify-center"
        >
          <div
            class="size-14 rounded-full bg-muted flex items-center justify-center mb-5"
          >
            <span class="i-lucide-wand-2 size-6 text-muted-foreground block" />
          </div>
          <h3 class="text-base font-medium text-foreground">
            {{ $t('MACROS.NO_RESULTS') }}
          </h3>
          <p class="text-[13.5px] text-muted-foreground mt-1">
            {{ $t('MACROS.LIST.404') }}
          </p>
        </div>

        <div v-else class="min-w-full">
          <!-- Table Header -->
          <div
            class="grid grid-cols-[1.5fr_1fr_1fr_1fr_100px] items-center px-6 py-3.5 border-b border-border/40 bg-muted/30"
          >
            <div
              class="text-[12px] font-medium text-muted-foreground uppercase tracking-wider"
            >
              {{ $t('MACROS.LIST.TABLE_HEADER.NAME') }}
            </div>
            <div
              class="text-[12px] font-medium text-muted-foreground uppercase tracking-wider"
            >
              {{ $t('MACROS.LIST.TABLE_HEADER.CREATED BY') }}
            </div>
            <div
              class="text-[12px] font-medium text-muted-foreground uppercase tracking-wider"
            >
              {{ $t('MACROS.LIST.TABLE_HEADER.LAST_UPDATED_BY') }}
            </div>
            <div
              class="text-[12px] font-medium text-muted-foreground uppercase tracking-wider"
            >
              {{ $t('MACROS.LIST.TABLE_HEADER.VISIBILITY') }}
            </div>
            <div
              class="text-[12px] font-medium text-muted-foreground uppercase tracking-wider text-right"
            >
              {{ $t('MACROS.LIST.TABLE_HEADER.ACTIONS') }}
            </div>
          </div>

          <!-- Table Body -->
          <div class="divide-y divide-border/40">
            <MacrosTableRow
              v-for="macroRecord in filteredRecords"
              :key="macroRecord.id"
              :macro="macroRecord"
              :can-manage-public-macros="isAdmin"
              @edit="openEditMacroBuilder"
              @delete="openDeletePopup(macroRecord)"
            />
          </div>
        </div>
      </div>

      <RelayConfirmModal
        :show="showDeleteConfirmationPopup"
        :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
        :message="$t('MACROS.DELETE.CONFIRM.MESSAGE')"
        :message-value="deleteMessage"
        :confirm-text="$t('MACROS.DELETE.CONFIRM.YES')"
        :cancel-text="$t('MACROS.DELETE.CONFIRM.NO')"
        @close="closeDeletePopup"
        @confirm="confirmDeletion"
      />

      <!-- ==============================================
           MODAL: BUILDER (Fullscreen Overlay)
      =============================================== -->
      <div
        v-if="isBuilderOpen"
        class="fixed inset-0 z-[101] flex items-center justify-center p-4 sm:p-6 sm:p-8 animate-in fade-in duration-200"
      >
        <div
          class="absolute inset-0 bg-black/40 backdrop-blur-sm"
          @click="closeBuilder"
        />
        <div
          class="relative w-full h-full bg-background border border-border/60 rounded-2xl shadow-2xl flex overflow-hidden animate-in zoom-in-95 duration-200"
        >
          <MacroForm
            v-if="macro && !uiFlags.isFetchingItem"
            :macro-data="macro"
            :can-manage-public-macros="isAdmin"
            :read-only="isPublicMacroReadOnly"
            @update:macro-data="macro = $event"
            @submit="saveMacro"
            @close="closeBuilder"
          />
          <woot-loading-state v-else :message="t('MACROS.EDITOR.LOADING')" />
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
