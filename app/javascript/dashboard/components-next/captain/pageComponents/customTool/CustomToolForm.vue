<script setup>
import { reactive, computed, ref, useTemplateRef, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, maxLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import CustomToolsAPI from 'dashboard/api/captain/customTools';

import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import ParamRow from './ParamRow.vue';
import AuthConfig from './AuthConfig.vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
  tool: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainCustomTools/getUIFlags'),
};

const initialState = {
  title: '',
  description: '',
  endpoint_url: '',
  http_method: 'GET',
  request_template: '',
  response_template: '',
  auth_type: 'none',
  auth_config: {},
  param_schema: [],
};

const state = reactive({ ...initialState });

// Populate form when in edit mode
watch(
  () => props.tool,
  newTool => {
    if (props.mode === 'edit' && newTool && newTool.id) {
      state.title = newTool.title || '';
      state.description = newTool.description || '';
      state.endpoint_url = newTool.endpoint_url || '';
      state.http_method = newTool.http_method || 'GET';
      state.request_template = newTool.request_template || '';
      state.response_template = newTool.response_template || '';
      state.auth_type = newTool.auth_type || 'none';
      state.auth_config = newTool.auth_config || {};
      state.param_schema = newTool.param_schema || [];
    }
  },
  { immediate: true }
);

const DEFAULT_PARAM = {
  name: '',
  type: 'string',
  description: '',
  required: false,
};

// OpenAI enforces a 64-char limit on function names. The backend slug is
// "custom_" (7 chars) + parameterized title, so cap the title conservatively.
const MAX_TOOL_NAME_LENGTH = 55;

const validationRules = {
  title: { required, maxLength: maxLength(MAX_TOOL_NAME_LENGTH) },
  endpoint_url: { required },
  http_method: { required },
  auth_type: { required },
};

const httpMethodOptions = computed(() => [
  { value: 'GET', label: 'GET' },
  { value: 'POST', label: 'POST' },
]);

const authTypeOptions = computed(() => [
  { value: 'none', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.NONE') },
  { value: 'bearer', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.BEARER') },
  { value: 'basic', label: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.BASIC') },
  {
    value: 'api_key',
    label: t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.API_KEY'),
  },
]);

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() =>
  props.mode === 'edit'
    ? formState.uiFlags.value.updatingItem
    : formState.uiFlags.value.creatingItem
);

const getErrorMessage = (field, errorKey) => {
  if (!v$.value[field].$error) return '';

  const failedRule = v$.value[field].$errors[0]?.$validator;
  if (failedRule === 'maxLength') {
    return t(`CAPTAIN.CUSTOM_TOOLS.FORM.${errorKey}.MAX_LENGTH_ERROR`, {
      max: MAX_TOOL_NAME_LENGTH,
    });
  }
  return t(`CAPTAIN.CUSTOM_TOOLS.FORM.${errorKey}.ERROR`);
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  endpoint_url: getErrorMessage('endpoint_url', 'ENDPOINT_URL'),
}));

const paramsRef = useTemplateRef('paramsRef');

const isParamsValid = () => {
  if (!paramsRef.value || paramsRef.value.length === 0) {
    return true;
  }
  return paramsRef.value.every(param => param.validate());
};

const removeParam = index => {
  state.param_schema.splice(index, 1);
};

const addParam = () => {
  state.param_schema.push({ ...DEFAULT_PARAM });
};

const handleCancel = () => emit('cancel');

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid || !isParamsValid()) {
    return;
  }

  emit('submit', state);
};

const isTesting = ref(false);
const testResult = ref(null);
const isTestDisabled = computed(
  () => state.endpoint_url.includes('{{') || !!state.request_template
);

const handleTest = async () => {
  if (!state.endpoint_url) return;

  isTesting.value = true;
  testResult.value = null;
  try {
    const { data } = await CustomToolsAPI.test(state);
    const isOk = data.status >= 200 && data.status < 300;
    testResult.value = { success: isOk, status: data.status };
  } catch (e) {
    const message =
      e.response?.data?.error || t('CAPTAIN.CUSTOM_TOOLS.TEST.ERROR');
    testResult.value = { success: false, message };
  } finally {
    isTesting.value = false;
  }
};
</script>

<template>
  <form
    class="flex flex-col px-4 -mx-4 gap-4 max-h-[calc(100vh-200px)] overflow-y-scroll"
    @submit.prevent="handleSubmit"
  >
    <div class="flex flex-col gap-2">
      <RelayLabel html-for="captain-tool-title">
        {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.TITLE.LABEL') }}
      </RelayLabel>
      <RelayInput
        id="captain-tool-title"
        v-model="state.title"
        :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.TITLE.PLACEHOLDER')"
      />
      <p v-if="formErrors.title" class="text-xs text-n-ruby-11">
        {{ formErrors.title }}
      </p>
    </div>

    <TextArea
      v-model="state.description"
      :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.DESCRIPTION.LABEL')"
      :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.DESCRIPTION.PLACEHOLDER')"
      :rows="2"
    />

    <div class="flex gap-2">
      <div class="flex w-28 flex-col gap-2">
        <RelayLabel>
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.HTTP_METHOD.LABEL') }}
        </RelayLabel>
        <ComboBox
          v-model="state.http_method"
          :options="httpMethodOptions"
          class="[&>div>button]:bg-n-alpha-black2 [&_li]:font-mono [&_button]:font-mono [&>div>button]:outline-offset-[-1px]"
        />
      </div>
      <div class="flex flex-1 flex-col gap-2">
        <RelayLabel html-for="captain-tool-endpoint-url">
          {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.ENDPOINT_URL.LABEL') }}
        </RelayLabel>
        <RelayInput
          id="captain-tool-endpoint-url"
          v-model="state.endpoint_url"
          :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.ENDPOINT_URL.PLACEHOLDER')"
        />
        <p v-if="formErrors.endpoint_url" class="text-xs text-n-ruby-11">
          {{ formErrors.endpoint_url }}
        </p>
      </div>
    </div>

    <div class="flex flex-col gap-2">
      <RelayLabel>
        {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPE.LABEL') }}
      </RelayLabel>
      <ComboBox
        v-model="state.auth_type"
        :options="authTypeOptions"
        class="[&>div>button]:bg-n-alpha-black2"
      />
    </div>

    <AuthConfig
      v-model:auth-config="state.auth_config"
      :auth-type="state.auth_type"
    />

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAMETERS.LABEL') }}
      </label>
      <p class="text-xs text-n-slate-11 -mt-1">
        {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.PARAMETERS.HELP_TEXT') }}
      </p>
      <ul v-if="state.param_schema.length > 0" class="grid gap-2 list-none">
        <ParamRow
          v-for="(param, index) in state.param_schema"
          :key="index"
          ref="paramsRef"
          v-model:name="param.name"
          v-model:type="param.type"
          v-model:description="param.description"
          v-model:required="param.required"
          @remove="removeParam(index)"
        />
      </ul>
      <RelayButton
        type="button"
        variant="ghost"
        size="sm"
        class="text-n-brand hover:bg-transparent hover:text-n-brand/80"
        @click="addParam"
      >
        <span class="i-lucide-plus size-4" />
        {{ t('CAPTAIN.CUSTOM_TOOLS.FORM.ADD_PARAMETER') }}
      </RelayButton>
    </div>

    <TextArea
      v-if="state.http_method === 'POST'"
      v-model="state.request_template"
      :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.REQUEST_TEMPLATE.LABEL')"
      :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.REQUEST_TEMPLATE.PLACEHOLDER')"
      :rows="4"
      class="[&_textarea]:font-mono"
    />

    <TextArea
      v-model="state.response_template"
      :label="t('CAPTAIN.CUSTOM_TOOLS.FORM.RESPONSE_TEMPLATE.LABEL')"
      :placeholder="
        t('CAPTAIN.CUSTOM_TOOLS.FORM.RESPONSE_TEMPLATE.PLACEHOLDER')
      "
      :rows="4"
      class="[&_textarea]:font-mono"
    />

    <div class="flex flex-col gap-2">
      <RelayButton
        type="button"
        variant="outline"
        class="w-full"
        :disabled="isTesting || !state.endpoint_url || isTestDisabled"
        @click="handleTest"
      >
        <span
          v-if="isTesting"
          class="i-lucide-loader-circle size-4 animate-spin"
        />
        <span v-else class="i-lucide-play size-3.5" />
        {{ t('CAPTAIN.CUSTOM_TOOLS.TEST.BUTTON') }}
      </RelayButton>
      <p v-if="isTestDisabled" class="text-xs text-n-slate-11">
        {{ t('CAPTAIN.CUSTOM_TOOLS.TEST.DISABLED_HINT') }}
      </p>
      <div
        v-if="testResult"
        class="flex items-center gap-2 rounded-lg px-3 py-2 text-xs"
        :class="
          testResult.success
            ? 'bg-n-teal-2 text-n-teal-11'
            : 'bg-n-ruby-2 text-n-ruby-11'
        "
      >
        <span
          :class="
            testResult.success ? 'i-lucide-check-circle' : 'i-lucide-x-circle'
          "
          class="size-3.5 shrink-0"
        />
        {{
          testResult.status
            ? t('CAPTAIN.CUSTOM_TOOLS.TEST.SUCCESS', {
                status: testResult.status,
              })
            : testResult.message
        }}
      </div>
    </div>

    <div class="flex w-full items-center justify-between gap-3">
      <RelayButton
        type="button"
        variant="secondary"
        class="w-full"
        @click="handleCancel"
      >
        {{ t('CAPTAIN.FORM.CANCEL') }}
      </RelayButton>
      <RelayButton type="submit" class="w-full" :disabled="isLoading">
        <span
          v-if="isLoading"
          class="i-lucide-loader-circle size-4 animate-spin"
        />
        {{ t(mode === 'edit' ? 'CAPTAIN.FORM.EDIT' : 'CAPTAIN.FORM.CREATE') }}
      </RelayButton>
    </div>
  </form>
</template>
