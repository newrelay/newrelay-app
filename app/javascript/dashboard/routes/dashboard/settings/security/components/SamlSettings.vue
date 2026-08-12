<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import samlSettingsAPI from 'dashboard/api/samlSettings';

import {
  RelayButton,
  RelayInput,
  RelaySwitch,
} from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import SamlInfoSection from './SamlInfoSection.vue';
import SamlAttributeMap from './SamlAttributeMap.vue';

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();

const id = ref(null);
const fingerprint = ref('');
const spEntityId = ref('');
const isEnabled = ref(false);
const isSubmitting = ref(false);
const isLoading = ref(true);

const formState = reactive({
  ssoUrl: '',
  certificate: '',
  idpEntityId: '',
});

const validations = {
  ssoUrl: { required },
  certificate: { required },
  idpEntityId: { required },
};

const v$ = useVuelidate(validations, formState);

const hasFeature = computed(() => isCloudFeatureEnabled('saml'));

const showForm = computed(
  () => hasFeature.value && isEnabled.value && !isLoading.value
);

const ssoUrlError = computed(() =>
  v$.value.ssoUrl.$error
    ? t('SECURITY_SETTINGS.SAML.VALIDATION.SSO_URL_ERROR')
    : ''
);

const certificateError = computed(() =>
  v$.value.certificate.$error
    ? t('SECURITY_SETTINGS.SAML.VALIDATION.CERTIFICATE_ERROR')
    : ''
);

const idpEntityIdError = computed(() =>
  v$.value.idpEntityId.$error
    ? t('SECURITY_SETTINGS.SAML.VALIDATION.IDP_ENTITY_ID_ERROR')
    : ''
);

const loadSamlSettings = async () => {
  if (!hasFeature.value) return;

  try {
    isLoading.value = true;
    const response = await samlSettingsAPI.get();
    const settings = response.data;

    if (settings.sso_url) {
      id.value = settings.id;
      formState.ssoUrl = settings.sso_url;
      formState.certificate = settings.certificate || '';
      spEntityId.value = settings.sp_entity_id || '';
      formState.idpEntityId = settings.idp_entity_id || '';
      fingerprint.value = settings.fingerprint || '';
      isEnabled.value = formState.ssoUrl !== '';
    }
  } catch (error) {
    // If no settings exist (404), that's expected - just keep defaults
    if (error.response?.status !== 404) {
      useAlert(t('SECURITY_SETTINGS.SAML.API.ERROR_LOADING'));
    }
  } finally {
    isLoading.value = false;
  }
};

const saveSamlSettings = async settings => {
  try {
    isSubmitting.value = true;

    if (isEnabled.value && formState.ssoUrl) {
      let response;
      if (id.value) {
        response = await samlSettingsAPI.update(settings);
      } else {
        response = await samlSettingsAPI.create(settings);
      }

      if (response?.data) {
        id.value = response.data.id;
        fingerprint.value = response.data.fingerprint || '';
        spEntityId.value = response.data.sp_entity_id || '';
      }

      useAlert(t('SECURITY_SETTINGS.SAML.API.SUCCESS'));
    } else {
      await samlSettingsAPI.delete();
      useAlert(t('SECURITY_SETTINGS.SAML.API.DISABLED'));
    }
  } catch (error) {
    if (error.response?.data?.errors) {
      const errorMessages = error.response.data.errors;
      const firstError = Array.isArray(errorMessages)
        ? errorMessages[0]
        : errorMessages;
      useAlert(firstError);
    } else {
      useAlert(t('SECURITY_SETTINGS.SAML.API.ERROR'));
    }
    throw error;
  } finally {
    isSubmitting.value = false;
  }
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  const settings = {
    sso_url: formState.ssoUrl,
    certificate: formState.certificate,
    idp_entity_id: formState.idpEntityId,
    role_mappings: {},
  };

  await saveSamlSettings(settings);
};

const handleDisable = async () => {
  id.value = null;
  formState.ssoUrl = '';
  formState.certificate = '';
  spEntityId.value = '';
  formState.idpEntityId = '';
  fingerprint.value = '';

  await saveSamlSettings({});
};

const onEnabledChange = async enabled => {
  isEnabled.value = enabled;
  if (!enabled) {
    await handleDisable();
  }
};

onMounted(() => {
  loadSamlSettings();
});
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col justify-between gap-8 md:flex-row md:items-start">
      <div class="max-w-xl">
        <div class="mb-2 flex items-center gap-2">
          <h3 class="text-[15px] font-medium text-foreground">
            {{ t('SECURITY_SETTINGS.SAML.TITLE') }}
          </h3>
          <span
            v-tooltip.top="t('GENERAL.BETA_DESCRIPTION')"
            class="rounded-full border border-primary/20 px-2 py-0.5 text-[10px] font-medium uppercase tracking-wider text-primary"
          >
            {{ t('GENERAL.BETA') }}
          </span>
        </div>
        <p class="text-[13px] leading-relaxed text-muted-foreground">
          {{ t('SECURITY_SETTINGS.SAML.NOTE') }}
        </p>
      </div>
      <div class="shrink-0 pt-0.5">
        <RelaySwitch
          :model-value="isEnabled"
          :disabled="isLoading || !hasFeature"
          @update:model-value="onEnabledChange"
        />
      </div>
    </div>

    <div v-if="showForm" class="space-y-6">
      <SamlInfoSection :fingerprint="fingerprint" :sp-entity-id="spEntityId">
        <template #footer>
          <SamlAttributeMap />
        </template>
      </SamlInfoSection>

      <form class="space-y-6" @submit.prevent="handleSubmit">
        <div class="flex flex-col gap-1.5">
          <label class="text-[13px] font-semibold text-foreground" for="ssoUrl">
            {{ t('SECURITY_SETTINGS.SAML.SSO_URL.LABEL') }}
          </label>
          <RelayInput
            id="ssoUrl"
            v-model="formState.ssoUrl"
            type="url"
            :placeholder="t('SECURITY_SETTINGS.SAML.SSO_URL.PLACEHOLDER')"
            class-name="h-[38px] rounded-lg border-border/80 bg-background text-[13px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30"
          />
          <p v-if="ssoUrlError" class="text-[12.5px] text-destructive">
            {{ ssoUrlError }}
          </p>
          <p v-else class="text-[12.5px] text-muted-foreground">
            {{ t('SECURITY_SETTINGS.SAML.SSO_URL.HELP') }}
          </p>
        </div>

        <div class="flex flex-col gap-1.5">
          <label
            class="text-[13px] font-semibold text-foreground"
            for="idpEntityId"
          >
            {{ t('SECURITY_SETTINGS.SAML.IDP_ENTITY_ID.LABEL') }}
          </label>
          <RelayInput
            id="idpEntityId"
            v-model="formState.idpEntityId"
            :placeholder="t('SECURITY_SETTINGS.SAML.IDP_ENTITY_ID.PLACEHOLDER')"
            class-name="h-[38px] rounded-lg border-border/80 bg-background text-[13px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30"
          />
          <p v-if="idpEntityIdError" class="text-[12.5px] text-destructive">
            {{ idpEntityIdError }}
          </p>
          <p v-else class="text-[12.5px] text-muted-foreground">
            {{ t('SECURITY_SETTINGS.SAML.IDP_ENTITY_ID.HELP') }}
          </p>
        </div>

        <div class="flex flex-col gap-1.5">
          <label
            class="text-[13px] font-semibold text-foreground"
            for="certificate"
          >
            {{ t('SECURITY_SETTINGS.SAML.CERTIFICATE.LABEL') }}
          </label>
          <textarea
            id="certificate"
            v-model="formState.certificate"
            rows="4"
            class="h-24 w-full resize-none rounded-lg border border-border/80 bg-background p-3 font-mono text-[13px] text-foreground shadow-sm placeholder:text-muted-foreground focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
            :placeholder="t('SECURITY_SETTINGS.SAML.CERTIFICATE.PLACEHOLDER')"
          />
          <p v-if="certificateError" class="text-[12.5px] text-destructive">
            {{ certificateError }}
          </p>
          <p v-else class="text-[12.5px] text-muted-foreground">
            {{ t('SECURITY_SETTINGS.SAML.CERTIFICATE.HELP') }}
          </p>
        </div>

        <div class="pt-2">
          <RelayButton
            type="submit"
            class="h-9 px-5 font-medium shadow-sm"
            :disabled="isSubmitting"
          >
            <Icon
              v-if="isSubmitting"
              icon="i-lucide-loader-2"
              class="size-4 animate-spin"
            />
            {{ t('SECURITY_SETTINGS.SAML.UPDATE_BUTTON') }}
          </RelayButton>
        </div>
      </form>
    </div>
  </div>
</template>
