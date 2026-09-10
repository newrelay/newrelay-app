<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, url } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import {
  RelayButton,
  RelayInput,
  RELAY_MODAL_INPUT_CLASS,
} from 'dashboard/components-next/relay';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  mode: {
    type: String,
    default: 'create',
  },
  selectedAppData: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();
const dialogRef = ref(null);
const isLoading = ref(false);

const app = ref({
  title: '',
  content: {
    type: 'frame',
    url: '',
  },
});

const rules = {
  app: {
    title: { required },
    content: {
      type: { required },
      url: { required, url },
    },
  },
};

const v$ = useVuelidate(rules, { app });

const header = computed(() =>
  t(`INTEGRATION_SETTINGS.DASHBOARD_APPS.${props.mode}.HEADER`)
);

const submitButtonLabel = computed(() =>
  t(`INTEGRATION_SETTINGS.DASHBOARD_APPS.${props.mode}.FORM_SUBMIT`)
);

const resetForm = () => {
  app.value = {
    title: '',
    content: { type: 'frame', url: '' },
  };
  v$.value.$reset();
};

const closeModal = () => {
  resetForm();
  dialogRef.value?.close();
  emit('close');
};

watch(
  () => props.show,
  async visible => {
    if (visible) {
      if (props.mode === 'UPDATE' && props.selectedAppData) {
        app.value = {
          title: props.selectedAppData.title,
          content: { ...props.selectedAppData.content[0] },
        };
      } else {
        resetForm();
      }
      await Promise.resolve();
      dialogRef.value?.open();
    }
  },
  { immediate: true }
);

const submit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  const action = props.mode.toLowerCase();
  const payload = {
    title: app.value.title,
    content: [app.value.content],
  };

  if (action === 'update') {
    payload.id = props.selectedAppData.id;
  }

  try {
    isLoading.value = true;
    await store.dispatch(`dashboardApps/${action}`, payload);
    useAlert(
      t(`INTEGRATION_SETTINGS.DASHBOARD_APPS.${props.mode}.API_SUCCESS`)
    );
    closeModal();
  } catch (err) {
    useAlert(t(`INTEGRATION_SETTINGS.DASHBOARD_APPS.${props.mode}.API_ERROR`));
  } finally {
    isLoading.value = false;
  }
};
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="header"
    :description="t('INTEGRATION_SETTINGS.DASHBOARD_APPS.DESCRIPTION')"
    width="lg"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="closeModal"
  >
    <form class="flex flex-col gap-5" @submit.prevent="submit">
      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] text-foreground font-[500]">
          {{ t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.TITLE_LABEL') }}
        </label>
        <RelayInput
          v-model="app.title"
          data-testid="app-title"
          :placeholder="
            t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.TITLE_PLACEHOLDER')
          "
          :class-name="RELAY_MODAL_INPUT_CLASS"
          @blur="v$.app.title.$touch()"
        />
        <p v-if="v$.app.title.$error" class="text-[12.5px] text-destructive">
          {{ t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.TITLE_ERROR') }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] text-foreground font-[500]">
          {{ t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.URL_LABEL') }}
        </label>
        <RelayInput
          v-model="app.content.url"
          data-testid="app-url"
          :placeholder="
            t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.URL_PLACEHOLDER')
          "
          :class-name="RELAY_MODAL_INPUT_CLASS"
          @blur="v$.app.content.url.$touch()"
        />
        <p
          v-if="v$.app.content.url.$error"
          class="text-[12.5px] text-destructive"
        >
          {{ t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.URL_ERROR') }}
        </p>
      </div>

      <div
        class="mt-2 flex items-center justify-end gap-3 border-t border-border/40 pt-5"
      >
        <RelayButton
          type="button"
          variant="outline"
          size="lg"
          @click="closeModal"
        >
          {{ t('INTEGRATION_SETTINGS.DASHBOARD_APPS.CREATE.FORM_CANCEL') }}
        </RelayButton>
        <RelayButton
          type="submit"
          size="lg"
          :disabled="v$.$invalid || isLoading"
        >
          {{ submitButtonLabel }}
        </RelayButton>
      </div>
    </form>
  </Dialog>
</template>
