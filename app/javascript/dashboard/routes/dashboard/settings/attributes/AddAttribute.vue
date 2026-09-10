<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { convertToAttributeSlug } from 'dashboard/helper/commons.js';
import { normalizeRegexPattern } from 'shared/helpers/Validators';
import { OnClickOutside } from '@vueuse/components';
import { ATTRIBUTE_TYPES } from './constants';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayCheckbox,
  RelayLabel,
  RelayModal,
} from 'dashboard/components-next/relay';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  selectedAttributeModelTab: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('attributes/getUIFlags');

const displayName = ref('');
const description = ref('');
const attributeModel = ref(props.selectedAttributeModelTab || 0);
const attributeType = ref(0);
const attributeKey = ref('');
const regexPattern = ref('');
const regexCue = ref('');
const regexEnabled = ref(false);
const values = ref([]);
const tagInputTouched = ref(false);
const showModelDropdown = ref(false);
const showTypeDropdown = ref(false);

const rules = {
  displayName: { required, minLength: minLength(1) },
  description: { required },
  attributeModel: { required },
  attributeType: { required },
  attributeKey: {
    required,
    isKey(value) {
      return !(value.indexOf(' ') >= 0);
    },
  },
};

const v$ = useVuelidate(rules, {
  displayName,
  description,
  attributeModel,
  attributeType,
  attributeKey,
});

const models = computed(() => [
  {
    id: 0,
    option: t('ATTRIBUTES_MGMT.ATTRIBUTE_MODELS.CONVERSATION'),
  },
  {
    id: 1,
    option: t('ATTRIBUTES_MGMT.ATTRIBUTE_MODELS.CONTACT'),
  },
]);

const types = computed(() =>
  ATTRIBUTE_TYPES.map(item => {
    const labels = {
      TEXT: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.TEXT'),
      NUMBER: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.NUMBER'),
      LINK: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.LINK'),
      DATE: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.DATE'),
      LIST: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.LIST'),
      CHECKBOX: t('ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.CHECKBOX'),
    };
    return {
      ...item,
      option: labels[item.key] || item.key,
    };
  })
);

const selectedModelLabel = computed(
  () =>
    models.value.find(item => item.id === attributeModel.value)?.option || ''
);

const selectedTypeLabel = computed(
  () => types.value.find(item => item.id === attributeType.value)?.option || ''
);

const isAttributeTypeList = computed(() => attributeType.value === 6);
const isAttributeTypeText = computed(() => attributeType.value === 0);
const isTagInputEmpty = computed(
  () => isAttributeTypeList.value && values.value.length === 0
);
const isTagInputInvalid = computed(
  () => tagInputTouched.value && isTagInputEmpty.value
);

const keyErrorMessage = computed(() => {
  if (!v$.value.attributeKey.isKey) {
    return t('ATTRIBUTES_MGMT.ADD.FORM.KEY.IN_VALID');
  }
  return t('ATTRIBUTES_MGMT.ADD.FORM.KEY.ERROR');
});

const isButtonDisabled = computed(
  () =>
    v$.value.displayName.$invalid ||
    v$.value.description.$invalid ||
    v$.value.attributeKey.$invalid ||
    uiFlags.value.isCreating ||
    isTagInputEmpty.value
);

const resetForm = () => {
  displayName.value = '';
  description.value = '';
  attributeModel.value = props.selectedAttributeModelTab || 0;
  attributeType.value = 0;
  attributeKey.value = '';
  regexPattern.value = '';
  regexCue.value = '';
  regexEnabled.value = false;
  values.value = [];
  tagInputTouched.value = false;
  showModelDropdown.value = false;
  showTypeDropdown.value = false;
  v$.value.$reset();
};

watch(
  () => props.show,
  newVal => {
    if (newVal) resetForm();
  }
);

watch(attributeType, () => {
  tagInputTouched.value = false;
  values.value = [];
});

watch(displayName, value => {
  attributeKey.value = convertToAttributeSlug(value);
});

const selectModel = id => {
  attributeModel.value = id;
  showModelDropdown.value = false;
};

const selectType = id => {
  attributeType.value = id;
  showTypeDropdown.value = false;
};

const addAttributes = async () => {
  v$.value.$touch();
  if (v$.value.$invalid || isTagInputEmpty.value) {
    if (isAttributeTypeList.value) tagInputTouched.value = true;
    return;
  }

  let pattern = regexPattern.value;
  let cue = regexCue.value;
  if (!regexEnabled.value) {
    pattern = null;
    cue = null;
  }

  try {
    await store.dispatch('attributes/create', {
      attribute_display_name: displayName.value,
      attribute_description: description.value,
      attribute_model: attributeModel.value,
      attribute_display_type: attributeType.value,
      attribute_key: attributeKey.value,
      attribute_values: values.value,
      regex_pattern: normalizeRegexPattern(pattern || null),
      regex_cue: cue || null,
    });
    useAlert(t('ATTRIBUTES_MGMT.ADD.API.SUCCESS_MESSAGE'));
    emit('close');
  } catch (error) {
    useAlert(error?.message || t('ATTRIBUTES_MGMT.ADD.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <RelayModal
    :show="show"
    :title="t('ATTRIBUTES_MGMT.ADD.TITLE')"
    size="md"
    flush
    @close="emit('close')"
  >
    <form @submit.prevent="addAttributes">
      <div
        class="max-h-[60vh] space-y-5 overflow-y-auto px-7 pb-2 custom-scrollbar"
      >
        <!-- Applies to -->
        <div class="flex flex-col gap-2.5">
          <RelayLabel class="text-[13.5px] font-medium text-foreground">
            {{ t('ATTRIBUTES_MGMT.ADD.FORM.MODEL.LABEL') }}
          </RelayLabel>
          <OnClickOutside @trigger="showModelDropdown = false">
            <div class="relative">
              <button
                type="button"
                class="flex h-11 w-full items-center justify-between rounded-xl border border-border/60 bg-background px-4 text-left text-[14px] text-foreground shadow-xs outline-none transition-colors focus:ring-1 focus:ring-primary/30"
                @click="showModelDropdown = !showModelDropdown"
              >
                {{ selectedModelLabel }}
                <Icon
                  icon="i-lucide-chevron-down"
                  class="size-4 text-muted-foreground"
                />
              </button>
              <div
                v-if="showModelDropdown"
                class="absolute left-0 top-full z-50 mt-1 w-full overflow-hidden rounded-xl border border-border/60 bg-card py-1 shadow-lg"
              >
                <button
                  v-for="model in models"
                  :key="model.id"
                  type="button"
                  class="w-full px-4 py-2 text-left text-[13.5px] transition-colors"
                  :class="
                    attributeModel === model.id
                      ? 'bg-primary text-primary-foreground'
                      : 'text-foreground hover:bg-muted'
                  "
                  @click="selectModel(model.id)"
                >
                  {{ model.option }}
                </button>
              </div>
            </div>
          </OnClickOutside>
        </div>

        <!-- Display Name -->
        <div class="flex flex-col gap-2.5">
          <RelayLabel class="text-[13.5px] font-medium text-foreground">
            {{ t('ATTRIBUTES_MGMT.ADD.FORM.NAME.LABEL') }}
          </RelayLabel>
          <input
            v-model="displayName"
            type="text"
            :placeholder="t('ATTRIBUTES_MGMT.ADD.FORM.NAME.PLACEHOLDER')"
            class="flex h-11 w-full rounded-xl border border-border/60 bg-muted/20 px-4 text-[14px] text-foreground shadow-xs transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
            @blur="v$.displayName.$touch()"
          />
          <p
            v-if="v$.displayName.$error"
            class="text-[12.5px] text-destructive"
          >
            {{ t('ATTRIBUTES_MGMT.ADD.FORM.NAME.ERROR') }}
          </p>
        </div>

        <!-- Key -->
        <div class="flex flex-col gap-2.5">
          <RelayLabel class="text-[13.5px] font-medium text-foreground">
            {{ t('ATTRIBUTES_MGMT.ADD.FORM.KEY.LABEL') }}
          </RelayLabel>
          <input
            v-model="attributeKey"
            type="text"
            :placeholder="t('ATTRIBUTES_MGMT.ADD.FORM.KEY.PLACEHOLDER')"
            class="flex h-11 w-full rounded-xl border border-border/60 bg-muted/20 px-4 text-[14px] text-foreground shadow-xs transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
            @blur="v$.attributeKey.$touch()"
          />
          <p
            v-if="v$.attributeKey.$error"
            class="text-[12.5px] text-destructive"
          >
            {{ keyErrorMessage }}
          </p>
        </div>

        <!-- Description -->
        <div class="flex flex-col gap-2.5">
          <RelayLabel class="text-[13.5px] font-medium text-foreground">
            {{ t('ATTRIBUTES_MGMT.ADD.FORM.DESC.LABEL') }}
          </RelayLabel>
          <textarea
            v-model="description"
            rows="3"
            :placeholder="t('ATTRIBUTES_MGMT.ADD.FORM.DESC.PLACEHOLDER')"
            class="min-h-[90px] w-full resize-y rounded-xl border border-border/60 bg-muted/20 p-4 text-[14px] text-foreground shadow-xs outline-none transition-colors placeholder:text-muted-foreground focus-visible:ring-1 focus-visible:ring-primary/30"
            @blur="v$.description.$touch()"
          />
          <p
            v-if="v$.description.$error"
            class="text-[12.5px] text-destructive"
          >
            {{ t('ATTRIBUTES_MGMT.ADD.FORM.DESC.ERROR') }}
          </p>
        </div>

        <!-- Type -->
        <div class="flex flex-col gap-2.5">
          <RelayLabel class="text-[13.5px] font-medium text-foreground">
            {{ t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LABEL') }}
          </RelayLabel>
          <OnClickOutside @trigger="showTypeDropdown = false">
            <div class="relative">
              <button
                type="button"
                class="flex h-11 w-full items-center justify-between rounded-xl border border-border/60 bg-background px-4 text-left text-[14px] text-foreground shadow-xs outline-none transition-colors focus:ring-1 focus:ring-primary/30"
                @click="showTypeDropdown = !showTypeDropdown"
              >
                {{ selectedTypeLabel }}
                <Icon
                  icon="i-lucide-chevron-down"
                  class="size-4 text-muted-foreground"
                />
              </button>
              <div
                v-if="showTypeDropdown"
                class="absolute left-0 top-full z-50 mt-1 max-h-48 w-full overflow-y-auto rounded-xl border border-border/60 bg-card py-1 shadow-lg"
              >
                <button
                  v-for="type in types"
                  :key="type.id"
                  type="button"
                  class="w-full px-4 py-2 text-left text-[13.5px] transition-colors"
                  :class="
                    attributeType === type.id
                      ? 'bg-primary text-primary-foreground'
                      : 'text-foreground hover:bg-muted'
                  "
                  @click="selectType(type.id)"
                >
                  {{ type.option }}
                </button>
              </div>
            </div>
          </OnClickOutside>
        </div>

        <!-- List Options (if LIST type) -->
        <div v-if="isAttributeTypeList" class="flex flex-col gap-2.5">
          <RelayLabel class="text-[13.5px] font-medium text-foreground">
            {{ t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.LABEL') }}
          </RelayLabel>
          <div
            class="rounded-xl border px-3 py-2"
            :class="
              isTagInputInvalid ? 'border-destructive' : 'border-border/60'
            "
          >
            <TagInput
              v-model="values"
              :placeholder="t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.PLACEHOLDER')"
              allow-create
              @blur="tagInputTouched = true"
            />
          </div>
          <p v-if="isTagInputInvalid" class="text-[12.5px] text-destructive">
            {{ t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.ERROR') }}
          </p>
        </div>

        <!-- Regex Validation (if TEXT type) -->
        <div v-if="isAttributeTypeText" class="flex items-center gap-3 pt-2">
          <RelayCheckbox v-model="regexEnabled" />
          <span class="text-[13.5px] font-medium text-foreground">
            {{ t('ATTRIBUTES_MGMT.ADD.FORM.ENABLE_REGEX.LABEL') }}
          </span>
        </div>

        <!-- Regex Pattern (if enabled) -->
        <div
          v-if="isAttributeTypeText && regexEnabled"
          class="flex flex-col gap-2.5"
        >
          <RelayLabel class="text-[13.5px] font-medium text-foreground">
            {{ t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_PATTERN.LABEL') }}
          </RelayLabel>
          <input
            v-model="regexPattern"
            type="text"
            :placeholder="
              t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_PATTERN.PLACEHOLDER')
            "
            class="flex h-11 w-full rounded-xl border border-border/60 bg-muted/20 px-4 text-[14px] text-foreground shadow-xs transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
          />
        </div>

        <!-- Regex Cue (if enabled) -->
        <div
          v-if="isAttributeTypeText && regexEnabled"
          class="flex flex-col gap-2.5"
        >
          <RelayLabel class="text-[13.5px] font-medium text-foreground">
            {{ t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_CUE.LABEL') }}
          </RelayLabel>
          <input
            v-model="regexCue"
            type="text"
            :placeholder="t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_CUE.PLACEHOLDER')"
            class="flex h-11 w-full rounded-xl border border-border/60 bg-muted/20 px-4 text-[14px] text-foreground shadow-xs transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
          />
        </div>
      </div>

      <!-- Footer Actions -->
      <div
        class="flex items-center justify-end gap-3 border-t border-border/40 bg-background/50 px-7 py-6"
      >
        <button
          type="button"
          class="text-muted-foreground hover:text-foreground font-medium text-[13.5px] px-4 py-2 rounded-lg transition-colors bg-muted/50 hover:bg-muted"
          @click="emit('close')"
        >
          {{ t('ATTRIBUTES_MGMT.ADD.CANCEL_BUTTON_TEXT') }}
        </button>
        <button
          type="submit"
          class="inline-flex items-center justify-center gap-2 whitespace-nowrap transition-colors focus-visible:outline-hidden focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 py-2.5 rounded-xl h-10 px-6 text-[13.5px] font-medium bg-primary text-primary-foreground hover:bg-primary/90 shadow-sm"
          :disabled="isButtonDisabled"
        >
          {{ t('ATTRIBUTES_MGMT.ADD.SUBMIT') }}
        </button>
      </div>
    </form>
  </RelayModal>
</template>
