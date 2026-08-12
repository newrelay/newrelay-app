<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import CategoryForm from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryForm.vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'edit',
    validator: value => ['edit', 'create'].includes(value),
  },
  selectedCategory: {
    type: Object,
    default: () => ({}),
  },
  portalName: {
    type: String,
    default: '',
  },
  activeLocaleName: {
    type: String,
    default: '',
  },
  activeLocaleCode: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();
const route = useRoute();

const isOpen = ref(false);
const categoryFormRef = ref(null);
const isUpdating = ref(false);

const isInvalidForm = computed(() => {
  if (!categoryFormRef.value) return false;
  const { isSubmitDisabled } = categoryFormRef.value;
  return isSubmitDisabled;
});

const handleClose = () => {
  isOpen.value = false;
  emit('close');
};

const handleCategory = () => {
  if (!categoryFormRef.value) return;
  categoryFormRef.value.handleSubmit();
};

const handleFormSubmit = async state => {
  const { id, name, slug, icon, description, locale } = state;
  const categoryData = { name, icon, slug, description };

  if (props.mode === 'create') {
    categoryData.locale = locale;
  } else {
    categoryData.id = id;
  }

  try {
    isUpdating.value = true;
    const action = props.mode === 'edit' ? 'update' : 'create';
    const payload = {
      portalSlug: route.params.portalSlug,
      categoryObj: categoryData,
    };

    if (action === 'update') {
      payload.categoryId = id;
    }

    await store.dispatch(`categories/${action}`, payload);

    const successMessage = t(
      `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.${props.mode.toUpperCase()}.API.SUCCESS_MESSAGE`
    );
    useAlert(successMessage);

    const trackEvent =
      props.mode === 'edit'
        ? PORTALS_EVENTS.EDIT_CATEGORY
        : PORTALS_EVENTS.CREATE_CATEGORY;
    useTrack(
      trackEvent,
      props.mode === 'create'
        ? { hasDescription: Boolean(description) }
        : undefined
    );

    handleClose();
  } catch (error) {
    const errorMessage =
      error?.message ||
      t(
        `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.${props.mode.toUpperCase()}.API.ERROR_MESSAGE`
      );
    useAlert(errorMessage);
  } finally {
    isUpdating.value = false;
  }
};

onMounted(() => {
  isOpen.value = true;
});
</script>

<template>
  <TeleportWithDirection to="body">
    <div
      v-if="isOpen"
      class="fixed inset-0 z-[100] flex items-center justify-center bg-n-alpha-black1 p-4 backdrop-blur-sm duration-200 animate-in fade-in"
      @click="handleClose"
    >
      <div
        class="flex w-full max-w-lg flex-col overflow-hidden rounded-xl border border-border bg-background shadow-2xl duration-200 animate-in zoom-in-95"
        @click.stop
      >
        <div
          class="flex items-center justify-between border-b border-border/40 bg-muted/20 p-5"
        >
          <h2 class="text-lg font-semibold tracking-tight text-foreground">
            {{
              t(
                `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.${mode.toUpperCase()}`
              )
            }}
          </h2>
          <button
            class="rounded-md p-1 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
            @click="handleClose"
          >
            <span class="i-lucide-x size-5" aria-hidden="true" />
          </button>
        </div>

        <div class="flex-1 overflow-y-auto p-5">
          <p
            v-if="mode === 'edit'"
            class="mb-6 text-[13.5px] text-muted-foreground"
          >
            {{
              t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.DESCRIPTION')
            }}
          </p>

          <CategoryForm
            ref="categoryFormRef"
            :mode="mode"
            :selected-category="selectedCategory"
            :active-locale-code="activeLocaleCode"
            :portal-name="portalName"
            :active-locale-name="activeLocaleName"
            :show-action-buttons="false"
            @submit="handleFormSubmit"
          />
        </div>

        <div
          class="flex items-center justify-end gap-3 border-t border-border/40 bg-muted/20 p-5"
        >
          <RelayButton
            variant="outline"
            class="h-9 px-5 text-[13px]"
            @click="handleClose"
          >
            {{ t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.BUTTONS.CANCEL') }}
          </RelayButton>
          <RelayButton
            class="h-9 border-0 px-5 text-[13px] shadow-sm"
            :disabled="isUpdating || isInvalidForm"
            :is-loading="isUpdating"
            @click="handleCategory"
          >
            {{
              t(
                `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.BUTTONS.${mode.toUpperCase()}`
              )
            }}
          </RelayButton>
        </div>
      </div>
    </div>
  </TeleportWithDirection>
</template>
