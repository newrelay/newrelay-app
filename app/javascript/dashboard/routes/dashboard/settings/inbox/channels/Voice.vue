<script setup>
import { reactive, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { isPhoneE164 } from 'shared/helpers/Validators';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import PageHeader from '../../SettingsSubPageHeader.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';

const INPUT_CLASS =
  'h-10 rounded-md border-border/80 bg-background px-4 text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30';

const PROVIDER_TYPES = {
  TWILIO: 'twilio',
  DYTE: 'dyte',
};

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();

const state = reactive({
  phoneNumber: '',
  accountSid: '',
  authToken: '',
  apiKeySid: '',
  apiKeySecret: '',
});

const uiFlags = useMapGetter('inboxes/getUIFlags');
const getIntegration = useMapGetter('integrations/getIntegration');
const dyteIntegration = computed(() => getIntegration.value('dyte'));
const isDyteConnected = computed(() => !!dyteIntegration.value.enabled);

onMounted(() => {
  store.dispatch('integrations/get');
});

const selectedProvider = computed(() => route.query.provider);
const showProviderSelection = computed(() => !selectedProvider.value);
const showConfiguration = computed(() => Boolean(selectedProvider.value));

const availableProviders = computed(() => [
  {
    key: PROVIDER_TYPES.TWILIO,
    title: t('INBOX_MGMT.ADD.VOICE.PROVIDERS.TWILIO'),
    description: t('INBOX_MGMT.ADD.VOICE.PROVIDERS.TWILIO_DESC'),
    icon: 'i-woot-twilio',
  },
  {
    key: PROVIDER_TYPES.DYTE,
    title: t('INBOX_MGMT.ADD.VOICE.PROVIDERS.DYTE'),
    description: t('INBOX_MGMT.ADD.VOICE.PROVIDERS.DYTE_DESC'),
    icon: 'i-lucide-video',
  },
]);

const selectProvider = providerValue => {
  router.push({
    name: route.name,
    params: route.params,
    query: { provider: providerValue },
  });
};

const goToDyteIntegration = () => {
  router.push({
    name: 'settings_applications_integration',
    params: { integration_id: 'dyte' },
  });
};

const validationRules = {
  phoneNumber: { required, isPhoneE164 },
  accountSid: { required },
  authToken: { required },
  apiKeySid: { required },
  apiKeySecret: { required },
};

const v$ = useVuelidate(validationRules, state);
const isSubmitDisabled = computed(() => v$.value.$invalid);

const formErrors = computed(() => ({
  phoneNumber: v$.value.phoneNumber?.$error
    ? t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.ERROR')
    : '',
  accountSid: v$.value.accountSid?.$error
    ? t('INBOX_MGMT.ADD.VOICE.TWILIO.ACCOUNT_SID.REQUIRED')
    : '',
  authToken: v$.value.authToken?.$error
    ? t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.REQUIRED')
    : '',
  apiKeySid: v$.value.apiKeySid?.$error
    ? t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.REQUIRED')
    : '',
  apiKeySecret: v$.value.apiKeySecret?.$error
    ? t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.REQUIRED')
    : '',
}));

function getProviderConfig() {
  const config = {
    account_sid: state.accountSid,
    auth_token: state.authToken,
    api_key_sid: state.apiKeySid,
    api_key_secret: state.apiKeySecret,
  };
  return config;
}

async function createChannel() {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  try {
    const channel = await store.dispatch('inboxes/createVoiceChannel', {
      name: `Voice (${state.phoneNumber})`,
      voice: {
        phone_number: state.phoneNumber,
        provider: 'twilio',
        provider_config: getProviderConfig(),
      },
    });

    router.replace({
      name: 'settings_inboxes_add_agents',
      params: { page: 'new', inbox_id: channel.id },
    });
  } catch (error) {
    useAlert(
      error.response?.data?.message ||
        t('INBOX_MGMT.ADD.VOICE.API.ERROR_MESSAGE')
    );
  }
}
</script>

<template>
  <div class="w-full max-w-2xl">
    <PageHeader
      :header-title="t('INBOX_MGMT.ADD.VOICE.TITLE')"
      :header-content="t('INBOX_MGMT.ADD.VOICE.DESC')"
    />

    <div v-if="showProviderSelection">
      <div class="mb-8 border-b border-border/40 pb-4 text-left">
        <h3 class="capitalize mb-1 text-base font-medium text-foreground">
          {{ t('INBOX_MGMT.ADD.VOICE.SELECT_PROVIDER.TITLE') }}
        </h3>
        <p class="text-[14px] leading-relaxed text-muted-foreground">
          {{ t('INBOX_MGMT.ADD.VOICE.SELECT_PROVIDER.DESCRIPTION') }}
        </p>
      </div>

      <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
        <ChannelSelector
          v-for="provider in availableProviders"
          :key="provider.key"
          :title="provider.title"
          :description="provider.description"
          :icon="provider.icon"
          @click="selectProvider(provider.key)"
        />
      </div>
    </div>

    <div v-else-if="showConfiguration">
      <div class="rounded-xl border border-border bg-card p-6 shadow-sm">
        <form
          v-if="selectedProvider === PROVIDER_TYPES.TWILIO"
          class="space-y-6"
          @submit.prevent="createChannel"
        >
          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] text-foreground font-[500]">
              {{ t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.LABEL') }}
            </label>
            <RelayInput
              v-model="state.phoneNumber"
              :placeholder="t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.PLACEHOLDER')"
              :class-name="INPUT_CLASS"
              @blur="v$.phoneNumber?.$touch"
            />
            <p
              v-if="formErrors.phoneNumber"
              class="text-[12.5px] text-destructive"
            >
              {{ formErrors.phoneNumber }}
            </p>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] text-foreground font-[500]">
              {{ t('INBOX_MGMT.ADD.VOICE.TWILIO.ACCOUNT_SID.LABEL') }}
            </label>
            <RelayInput
              v-model="state.accountSid"
              :placeholder="
                t('INBOX_MGMT.ADD.VOICE.TWILIO.ACCOUNT_SID.PLACEHOLDER')
              "
              :class-name="INPUT_CLASS"
              @blur="v$.accountSid?.$touch"
            />
            <p
              v-if="formErrors.accountSid"
              class="text-[12.5px] text-destructive"
            >
              {{ formErrors.accountSid }}
            </p>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] text-foreground font-[500]">
              {{ t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.LABEL') }}
            </label>
            <RelayInput
              v-model="state.authToken"
              type="password"
              :placeholder="
                t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.PLACEHOLDER')
              "
              :class-name="INPUT_CLASS"
              @blur="v$.authToken?.$touch"
            />
            <p
              v-if="formErrors.authToken"
              class="text-[12.5px] text-destructive"
            >
              {{ formErrors.authToken }}
            </p>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] text-foreground font-[500]">
              {{ t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.LABEL') }}
            </label>
            <RelayInput
              v-model="state.apiKeySid"
              :placeholder="
                t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.PLACEHOLDER')
              "
              :class-name="INPUT_CLASS"
              @blur="v$.apiKeySid?.$touch"
            />
            <p
              v-if="formErrors.apiKeySid"
              class="text-[12.5px] text-destructive"
            >
              {{ formErrors.apiKeySid }}
            </p>
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-[13.5px] text-foreground font-[500]">
              {{ t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.LABEL') }}
            </label>
            <RelayInput
              v-model="state.apiKeySecret"
              type="password"
              :placeholder="
                t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.PLACEHOLDER')
              "
              :class-name="INPUT_CLASS"
              @blur="v$.apiKeySecret?.$touch"
            />
            <p
              v-if="formErrors.apiKeySecret"
              class="text-[12.5px] text-destructive"
            >
              {{ formErrors.apiKeySecret }}
            </p>
          </div>

          <div class="pt-4">
            <RelayButton
              type="submit"
              class="shadow-sm"
              :disabled="isSubmitDisabled || uiFlags.isCreating"
            >
              {{ t('INBOX_MGMT.ADD.VOICE.SUBMIT_BUTTON') }}
            </RelayButton>
          </div>
        </form>

        <div
          v-else-if="selectedProvider === PROVIDER_TYPES.DYTE"
          class="flex flex-col gap-4"
        >
          <p class="text-[13.5px] text-muted-foreground">
            {{
              isDyteConnected
                ? t('INBOX_MGMT.ADD.VOICE.DYTE.CONNECTED_DESCRIPTION')
                : t('INBOX_MGMT.ADD.VOICE.DYTE.DESCRIPTION')
            }}
          </p>
          <div>
            <RelayButton variant="outline" @click="goToDyteIntegration">
              {{
                isDyteConnected
                  ? t('INBOX_MGMT.ADD.VOICE.DYTE.MANAGE_BUTTON')
                  : t('INBOX_MGMT.ADD.VOICE.DYTE.CONNECT_BUTTON')
              }}
            </RelayButton>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
