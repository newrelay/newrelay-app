<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { getRegexp, normalizeRegexPattern } from 'shared/helpers/Validators';
import { ATTRIBUTE_TYPES } from './constants';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayButton,
  RelayInput,
  RelayCheckbox,
} from 'dashboard/components-next/relay';

const props = defineProps({
  selectedAttribute: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('attributes/getUIFlags');

const displayName = ref('');
const description = ref('');
const attributeType = ref(0);
const regexPattern = ref('');
const regexCue = ref('');
const regexEnabled = ref(false);
const attributeKey = ref('');
const values = ref([]);
const tagInputTouched = ref(false);

const rules = {
  displayName: { required },
  attributeType: { required },
  description: { required, minLength: minLength(1) },
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
  attributeType,
  attributeKey,
});

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
    isTagInputEmpty.value ||
    uiFlags.value.isUpdating
);

const pageTitle = computed(
  () =>
    `${t('ATTRIBUTES_MGMT.EDIT.TITLE')} - ${
      props.selectedAttribute.attribute_display_name || ''
    }`
);

const setFormValues = () => {
  const pattern = props.selectedAttribute.regex_pattern
    ? getRegexp(props.selectedAttribute.regex_pattern).toString()
    : null;
  const typeId = types.value.find(
    item =>
      item.key.toLowerCase() === props.selectedAttribute.attribute_display_type
  )?.id;

  displayName.value = props.selectedAttribute.attribute_display_name;
  description.value = props.selectedAttribute.attribute_description;
  attributeType.value = typeId ?? 0;
  attributeKey.value = props.selectedAttribute.attribute_key;
  regexPattern.value = pattern || '';
  regexCue.value = props.selectedAttribute.regex_cue || '';
  regexEnabled.value = pattern != null;
  values.value = [...(props.selectedAttribute.attribute_values || [])];
};

const onClose = () => emit('close');

const editAttributes = async () => {
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
    await store.dispatch('attributes/update', {
      id: props.selectedAttribute.id,
      attribute_description: description.value,
      attribute_display_name: displayName.value,
      attribute_values: values.value,
      regex_pattern: normalizeRegexPattern(pattern || null),
      regex_cue: cue || null,
    });
    useAlert(t('ATTRIBUTES_MGMT.EDIT.API.SUCCESS_MESSAGE'));
    onClose();
  } catch (error) {
    useAlert(error?.message || t('ATTRIBUTES_MGMT.EDIT.API.ERROR_MESSAGE'));
  }
};

onMounted(setFormValues);
</script>

<template>
  <div class="-m-6 flex max-h-[90vh] flex-col">
    <div
      class="flex shrink-0 items-center justify-between border-b border-border/40 bg-background/50 p-5"
    >
      <h3 class="text-[16px] font-semibold text-foreground">
        {{ pageTitle }}
      </h3>
      <button
        type="button"
        class="text-muted-foreground transition-colors hover:text-foreground"
        @click="onClose"
      >
        <Icon icon="i-lucide-x" class="size-5" />
      </button>
    </div>

    <div class="space-y-5 overflow-y-auto p-6">
      <div class="flex flex-col gap-2.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ t('ATTRIBUTES_MGMT.ADD.FORM.NAME.LABEL') }}
        </label>
        <RelayInput
          v-model="displayName"
          type="text"
          :placeholder="t('ATTRIBUTES_MGMT.ADD.FORM.NAME.PLACEHOLDER')"
          class-name="h-10 rounded-md border-border/80 bg-background text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30"
          @blur="v$.displayName.$touch()"
        />
        <p v-if="v$.displayName.$error" class="text-[12.5px] text-destructive">
          {{ t('ATTRIBUTES_MGMT.ADD.FORM.NAME.ERROR') }}
        </p>
      </div>

      <div class="flex flex-col gap-2.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ t('ATTRIBUTES_MGMT.ADD.FORM.KEY.LABEL') }}
        </label>
        <RelayInput
          v-model="attributeKey"
          type="text"
          disabled
          :placeholder="t('ATTRIBUTES_MGMT.ADD.FORM.KEY.PLACEHOLDER')"
          class-name="h-10 rounded-md border-border/80 bg-background text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30"
        />
        <p v-if="v$.attributeKey.$error" class="text-[12.5px] text-destructive">
          {{ keyErrorMessage }}
        </p>
      </div>

      <div class="flex flex-col gap-2.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ t('ATTRIBUTES_MGMT.ADD.FORM.DESC.LABEL') }}
        </label>
        <textarea
          v-model="description"
          rows="5"
          :placeholder="t('ATTRIBUTES_MGMT.ADD.FORM.DESC.PLACEHOLDER')"
          class="min-h-[80px] w-full resize-y rounded-md border border-border/80 bg-background p-3 text-[14px] text-foreground shadow-sm outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
          @blur="v$.description.$touch()"
        />
        <p v-if="v$.description.$error" class="text-[12.5px] text-destructive">
          {{ t('ATTRIBUTES_MGMT.ADD.FORM.DESC.ERROR') }}
        </p>
      </div>

      <div class="flex flex-col gap-2.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LABEL') }}
        </label>
        <div
          class="flex h-10 w-full items-center justify-between rounded-md border border-border/80 bg-muted/40 px-3 text-left text-[14px] text-muted-foreground shadow-sm"
        >
          {{ selectedTypeLabel }}
        </div>
      </div>

      <div v-if="isAttributeTypeList" class="flex flex-col gap-2.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ t('ATTRIBUTES_MGMT.EDIT.TYPE.LIST.LABEL') }}
        </label>
        <div
          class="rounded-md border px-3 py-2"
          :class="isTagInputInvalid ? 'border-destructive' : 'border-border/80'"
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

      <div v-if="isAttributeTypeText" class="flex items-center gap-3 pt-2">
        <RelayCheckbox v-model="regexEnabled" />
        <span class="text-[13.5px] font-medium text-foreground">
          {{ t('ATTRIBUTES_MGMT.ADD.FORM.ENABLE_REGEX.LABEL') }}
        </span>
      </div>

      <div
        v-if="isAttributeTypeText && regexEnabled"
        class="flex flex-col gap-2.5"
      >
        <label class="text-[13.5px] font-medium text-foreground">
          {{ t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_PATTERN.LABEL') }}
        </label>
        <RelayInput
          v-model="regexPattern"
          type="text"
          :placeholder="t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_PATTERN.PLACEHOLDER')"
          class-name="h-10 rounded-md border-border/80 bg-background text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30"
        />
      </div>

      <div
        v-if="isAttributeTypeText && regexEnabled"
        class="flex flex-col gap-2.5"
      >
        <label class="text-[13.5px] font-medium text-foreground">
          {{ t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_CUE.LABEL') }}
        </label>
        <RelayInput
          v-model="regexCue"
          type="text"
          :placeholder="t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_CUE.PLACEHOLDER')"
          class-name="h-10 rounded-md border-border/80 bg-background text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30"
        />
      </div>
    </div>

    <div
      class="flex shrink-0 justify-end gap-3 border-t border-border/40 bg-background/50 p-5"
    >
      <RelayButton
        type="button"
        variant="outline"
        class="border-border bg-muted hover:bg-muted/80"
        @click="onClose"
      >
        {{ t('ATTRIBUTES_MGMT.ADD.CANCEL_BUTTON_TEXT') }}
      </RelayButton>
      <RelayButton
        type="button"
        class="px-5"
        :disabled="isButtonDisabled"
        @click="editAttributes"
      >
        {{ t('ATTRIBUTES_MGMT.EDIT.UPDATE_BUTTON_TEXT') }}
      </RelayButton>
    </div>
  </div>
</template>
