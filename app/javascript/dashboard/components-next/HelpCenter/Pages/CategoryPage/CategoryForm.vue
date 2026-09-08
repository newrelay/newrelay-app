<script setup>
import {
  reactive,
  ref,
  watch,
  computed,
  defineAsyncComponent,
  onMounted,
} from 'vue';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { convertToCategorySlug } from 'dashboard/helper/commons.js';

import {
  RelayInput,
  RelayTextarea,
  RelayButton,
  RelayLabel,
} from 'dashboard/components-next/relay';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  selectedCategory: {
    type: Object,
    default: () => ({}),
  },
  activeLocaleCode: {
    type: String,
    default: '',
  },
  showActionButtons: {
    type: Boolean,
    default: true,
  },
  portalName: {
    type: String,
    default: '',
  },
  activeLocaleName: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['submit', 'cancel']);

const EmojiInput = defineAsyncComponent(
  () => import('shared/components/emoji/EmojiInput.vue')
);

const { t } = useI18n();
const route = useRoute();
const getters = useStoreGetters();

const isCreating = useMapGetter('categories/isCreating');

const isUpdatingCategory = computed(() => {
  const id = props.selectedCategory?.id;
  if (id) return getters['categories/uiFlags'].value(id)?.isUpdating;

  return false;
});

const isEmojiPickerOpen = ref(false);

const state = reactive({
  id: '',
  name: '',
  icon: '',
  slug: '',
  description: '',
  locale: '',
});

const isEditMode = computed(() => props.mode === 'edit');

const rules = {
  name: { required, minLength: minLength(1) },
  slug: { required },
};

const v$ = useVuelidate(rules, state);

const isSubmitDisabled = computed(() => v$.value.$invalid);

const nameError = computed(() =>
  v$.value.name.$error
    ? t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.NAME.ERROR')
    : ''
);

const slugError = computed(() =>
  v$.value.slug.$error
    ? t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.SLUG.ERROR')
    : ''
);

const slugHelpText = computed(() => {
  const { portalSlug, locale } = route.params;
  return t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.SLUG.HELP_TEXT', {
    portalSlug,
    localeCode: locale,
    categorySlug: state.slug,
  });
});

const onClickInsertEmoji = emoji => {
  state.icon = emoji;
  isEmojiPickerOpen.value = false;
};

const handleSubmit = async () => {
  const isFormCorrect = await v$.value.$validate();
  if (!isFormCorrect) return;

  emit('submit', { ...state });
};

const handleCancel = () => {
  emit('cancel');
};

watch(
  () => state.name,
  () => {
    if (!isEditMode.value) {
      state.slug = convertToCategorySlug(state.name);
    }
  }
);

watch(
  () => props.selectedCategory,
  newCategory => {
    if (props.mode === 'edit' && newCategory) {
      const { id, name, icon, slug, description } = newCategory;
      Object.assign(state, { id, name, icon, slug, description });
    }
  },
  { immediate: true }
);

onMounted(() => {
  if (props.mode === 'create') {
    state.locale = props.activeLocaleCode;
  }
});

defineExpose({ state, isSubmitDisabled, handleSubmit });
</script>

<template>
  <div class="flex flex-col gap-4">
    <div
      class="flex items-center justify-between p-3 rounded-lg border border-border/40 bg-card"
    >
      <div class="flex flex-col gap-1">
        <span class="text-[12px] font-medium text-muted-foreground">
          {{ t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.PORTAL') }}
        </span>
        <span class="text-[14px] text-foreground font-medium">
          {{ portalName }}
        </span>
      </div>
      <div class="h-8 w-px bg-border/40" />
      <div class="flex flex-col gap-1 text-right">
        <span class="text-[12px] font-medium text-muted-foreground">
          {{ t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.LOCALE') }}
        </span>
        <span
          :title="`${activeLocaleName} (${activeLocaleCode})`"
          class="text-[14px] text-foreground font-medium line-clamp-1"
        >
          {{ `${activeLocaleName} (${activeLocaleCode})` }}
        </span>
      </div>
    </div>
    <div class="flex flex-col gap-4">
      <div class="flex flex-col gap-1.5">
        <RelayLabel>
          {{ t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.NAME.LABEL') }}
        </RelayLabel>
        <div class="relative">
          <OnClickOutside @trigger="isEmojiPickerOpen = false">
            <button
              type="button"
              class="absolute inset-y-[1px] ltr:left-[1px] rtl:right-[1px] z-10 w-9 flex items-center justify-center rounded-md ltr:rounded-r-none rtl:rounded-l-none border-0 bg-transparent text-muted-foreground hover:text-foreground hover:bg-accent focus:outline-none"
              @click="isEmojiPickerOpen = !isEmojiPickerOpen"
            >
              <span v-if="!state.icon" class="i-lucide-smile-plus size-4" />
              <span v-else class="text-base leading-none">{{
                state.icon
              }}</span>
            </button>
            <EmojiInput
              v-if="isEmojiPickerOpen"
              class="left-0 top-11"
              show-remove-button
              :on-click="onClickInsertEmoji"
            />
          </OnClickOutside>
          <RelayInput
            v-model="state.name"
            :placeholder="
              t(
                'HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.NAME.PLACEHOLDER'
              )
            "
            class-name="ltr:pl-10 rtl:pr-10"
          />
        </div>
        <p v-if="nameError" class="text-xs text-destructive">
          {{ nameError }}
        </p>
      </div>
      <div class="flex flex-col gap-1.5">
        <RelayLabel>
          {{ t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.SLUG.LABEL') }}
        </RelayLabel>
        <RelayInput
          v-model="state.slug"
          :placeholder="
            t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.SLUG.PLACEHOLDER')
          "
          :disabled="isEditMode"
        />
        <p
          class="text-xs"
          :class="slugError ? 'text-destructive' : 'text-muted-foreground'"
        >
          {{ slugError || slugHelpText }}
        </p>
      </div>
      <div class="flex flex-col gap-1.5">
        <RelayLabel>
          {{
            t(
              'HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.DESCRIPTION.LABEL'
            )
          }}
        </RelayLabel>
        <RelayTextarea
          v-model="state.description"
          :placeholder="
            t(
              'HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.FORM.DESCRIPTION.PLACEHOLDER'
            )
          "
        />
      </div>
      <div
        v-if="showActionButtons"
        class="flex items-center justify-between w-full gap-3"
      >
        <RelayButton variant="outline" class="w-full" @click="handleCancel">
          {{ t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.BUTTONS.CANCEL') }}
        </RelayButton>
        <RelayButton
          class="w-full"
          :disabled="isSubmitDisabled || isCreating || isUpdatingCategory"
          @click="handleSubmit"
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
</template>
