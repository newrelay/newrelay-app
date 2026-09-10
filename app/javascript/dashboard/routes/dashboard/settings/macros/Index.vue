<script setup>
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';
import MacrosTableRow from './MacrosTableRow.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, onMounted, ref, watch, provide } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useRoute, useRouter } from 'vue-router';
import { MACRO_ACTION_TYPES } from './constants';
import { useMacros } from 'dashboard/composables/useMacros';
import actionQueryGenerator from 'dashboard/helper/actionQueryGenerator.js';
import MacroForm from './MacroForm.vue';
import {
  RelayButton,
  RelayConfirmModal,
  RelayInput,
  RELAY_MODAL_OVERLAY_BLUR_CLASS,
} from 'dashboard/components-next/relay';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

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
    <template #body>
      <div
        class="mb-8 overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
      >
        <div
          class="flex flex-col justify-between gap-4 border-b border-border/40 p-4 sm:flex-row sm:items-center sm:p-6"
        >
          <div>
            <h3 class="text-base font-medium text-foreground">
              {{ $t('MACROS.HEADER') }}
            </h3>
            <p class="mt-1 max-w-3xl text-sm text-muted-foreground">
              {{ $t('MACROS.DESCRIPTION') }}
            </p>
          </div>
          <RelayButton
            class="h-9 shrink-0 px-4 text-[13px] font-medium shadow-sm"
            @click="openNewMacroBuilder"
          >
            {{ $t('MACROS.HEADER_BTN_TXT') }}
          </RelayButton>
        </div>

        <div class="space-y-6 p-4 sm:p-6">
          <div
            class="flex items-center justify-between rounded-xl border border-border/60 bg-card p-2 shadow-xs"
          >
            <div class="relative w-full max-w-md">
              <Icon
                icon="i-lucide-search"
                class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
              />
              <RelayInput
                v-model="searchQuery"
                type="search"
                :placeholder="$t('MACROS.SEARCH_PLACEHOLDER')"
                class-name="h-9 w-full border-border/40 bg-background/50 pl-9 text-[13.5px] shadow-none focus-visible:bg-background focus-visible:ring-1 focus-visible:ring-primary/20"
              />
            </div>
            <div
              class="shrink-0 border-l border-border/40 px-4 text-[13px] font-medium text-muted-foreground"
            >
              {{ $t('MACROS.COUNT', { n: filteredRecords.length }) }}
            </div>
          </div>

          <div
            class="overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs"
          >
            <div
              v-if="searchQuery && !filteredRecords.length"
              class="flex flex-col items-center justify-center p-16 text-center"
            >
              <p class="text-sm text-muted-foreground">
                {{ $t('MACROS.NO_RESULTS') }}
              </p>
            </div>

            <div
              v-else-if="!records.length"
              class="flex flex-col items-center justify-center p-16 text-center"
            >
              <div
                class="mb-5 flex size-14 items-center justify-center rounded-full bg-muted"
              >
                <Icon
                  icon="i-lucide-wand-2"
                  class="size-6 text-muted-foreground"
                />
              </div>
              <h3 class="text-[20px] font-[600] text-foreground">
                {{ $t('MACROS.LIST.404') }}
              </h3>
            </div>

            <div v-else class="min-w-full">
              <div
                class="grid grid-cols-[1.5fr_1fr_1fr_1fr_100px] items-center border-b border-border/40 bg-muted/30 px-6 py-3.5"
              >
                <div class="text-[14px] font-medium text-muted-foreground">
                  {{ $t('MACROS.LIST.TABLE_HEADER.NAME') }}
                </div>
                <div class="text-[14px] font-medium text-muted-foreground">
                  {{ $t('MACROS.LIST.TABLE_HEADER.CREATED BY') }}
                </div>
                <div class="text-[14px] font-medium text-muted-foreground">
                  {{ $t('MACROS.LIST.TABLE_HEADER.LAST_UPDATED_BY') }}
                </div>
                <div class="text-[14px] font-medium text-muted-foreground">
                  {{ $t('MACROS.LIST.TABLE_HEADER.VISIBILITY') }}
                </div>
                <div
                  class="text-right text-[14px] font-medium text-muted-foreground"
                >
                  {{ $t('MACROS.LIST.TABLE_HEADER.ACTIONS') }}
                </div>
              </div>

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
        </div>
      </div>

      <RelayConfirmModal
        :show="showDeleteConfirmationPopup"
        :title="$t('MACROS.DELETE.CONFIRM.TITLE')"
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
        class="fixed inset-0 z-[101] flex items-center justify-center p-4 sm:p-6 animate-in fade-in duration-200"
      >
        <div
          class="absolute inset-0 bg-background/80"
          :class="RELAY_MODAL_OVERLAY_BLUR_CLASS"
          @click="closeBuilder"
        />
        <div
          class="relative flex h-[92vh] w-full max-w-7xl overflow-hidden rounded-2xl border border-border/60 bg-background shadow-2xl animate-in zoom-in-95 duration-200"
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
          <div
            v-else
            class="flex flex-1 flex-col items-center justify-center gap-3 text-muted-foreground"
          >
            <Spinner :size="28" class="text-primary" />
            <p class="text-sm">{{ t('MACROS.EDITOR.LOADING') }}</p>
          </div>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
