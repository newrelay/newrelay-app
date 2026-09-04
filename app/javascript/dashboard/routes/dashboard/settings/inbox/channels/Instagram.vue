<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { extractResponseMessage } from 'shared/helpers/CustomErrors';
import instagramClient from 'dashboard/api/channel/instagramClient';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const { accountId } = useAccount();

const isMock = computed(() => !!window.newrelayConfig?.commentAutomationMock);

const hasError = ref(false);
const errorStateMessage = ref('');
const errorStateDescription = ref('');
const isRequestingAuthorization = ref(false);

const connectUrl = ref('https://www.instagram.com/p/mock-summer-sale/');
const connectName = ref('Instagram Shop');
const connectSaving = ref(false);
const connectError = ref('');

const canConnect = computed(
  () =>
    connectUrl.value.trim() && connectName.value.trim() && !connectSaving.value
);

onMounted(() => {
  const urlParams = new URLSearchParams(window.location.search);
  //  TODO: Handle error type
  // const errorType = urlParams.get('error_type');
  const errorCode = urlParams.get('code');
  const errorMessage = urlParams.get('error_message');

  if (errorMessage) {
    hasError.value = true;
    if (errorCode === '400') {
      errorStateMessage.value = errorMessage;
      errorStateDescription.value = t('INBOX_MGMT.ADD.INSTAGRAM.ERROR_AUTH');
    } else {
      errorStateMessage.value = t('INBOX_MGMT.ADD.INSTAGRAM.ERROR_MESSAGE');
      errorStateDescription.value = errorMessage;
    }
  }
  // User need to remove the error params from the url to avoid the error to be shown again after page reload, so that user can try again
  const cleanURL = window.location.pathname;
  window.history.replaceState({}, document.title, cleanURL);
});

const requestAuthorization = async () => {
  isRequestingAuthorization.value = true;
  const response = await instagramClient.generateAuthorization();
  const {
    data: { url },
  } = response;

  window.location.href = url;
};

const submitMockConnect = async () => {
  if (!canConnect.value) return;
  connectSaving.value = true;
  connectError.value = '';
  try {
    const { data } = await window.axios.post(
      `/api/v1/accounts/${accountId.value}/comment_automation/mock_connection`,
      { url: connectUrl.value.trim(), name: connectName.value.trim() }
    );
    await store.dispatch('inboxes/get');
    useAlert(t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_SUCCESS'));
    router.replace({
      name: 'settings_inboxes_add_agents',
      params: {
        page: 'new',
        inbox_id: data.id,
        accountId: accountId.value,
      },
    });
  } catch (error) {
    connectError.value =
      extractResponseMessage(error) ||
      t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_TITLE');
  } finally {
    connectSaving.value = false;
  }
};
</script>

<template>
  <div class="w-full max-w-2xl">
    <div class="flex flex-col items-center justify-start text-center">
      <div v-if="hasError" class="mx-auto max-w-lg text-center">
        <h5 class="text-base font-semibold text-foreground">
          {{ errorStateMessage }}
        </h5>
        <p
          v-if="errorStateDescription"
          v-dompurify-html="errorStateDescription"
          class="mt-2 text-[13px] text-muted-foreground"
        />
      </div>
      <div
        v-else-if="isMock"
        class="flex w-full flex-col items-stretch rounded-xl border border-border bg-card px-8 py-10 text-left shadow-sm"
      >
        <h6 class="text-base font-semibold text-foreground text-center">
          {{ t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_TITLE') }}
        </h6>
        <p
          class="py-6 text-[13px] leading-relaxed text-muted-foreground text-center"
        >
          {{ t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_DESC') }}
        </p>
        <div class="flex flex-col gap-4">
          <div class="flex flex-col gap-1.5">
            <RelayLabel>
              {{ t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_URL') }}
            </RelayLabel>
            <RelayInput
              v-model="connectUrl"
              :placeholder="
                t(
                  'AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_URL_PLACEHOLDER'
                )
              "
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <RelayLabel>
              {{ t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_NAME') }}
            </RelayLabel>
            <RelayInput
              v-model="connectName"
              :placeholder="
                t(
                  'AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_NAME_PLACEHOLDER'
                )
              "
            />
          </div>
          <p v-if="connectError" class="text-[13px] text-destructive">
            {{ connectError }}
          </p>
          <div class="flex justify-end pt-2">
            <RelayButton :disabled="!canConnect" @click="submitMockConnect">
              {{
                connectSaving
                  ? t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECTING')
                  : t('AUTORESPONDER.SETTINGS.CHANNELS.MOCK_CONNECT_SUBMIT')
              }}
            </RelayButton>
          </div>
        </div>
      </div>
      <div
        v-else
        class="flex w-full flex-col items-center justify-center rounded-xl border border-border bg-card px-8 py-10 text-center shadow-sm"
      >
        <h6 class="text-base font-semibold text-foreground">
          {{ $t('INBOX_MGMT.ADD.INSTAGRAM.CONNECT_YOUR_INSTAGRAM_PROFILE') }}
        </h6>
        <p class="py-6 text-[13px] leading-relaxed text-muted-foreground">
          {{ $t('INBOX_MGMT.ADD.INSTAGRAM.HELP') }}
        </p>
        <Button
          class="text-white !rounded-full !px-6 bg-gradient-to-r from-[#833AB4] via-[#FD1D1D] to-[#FCAF45]"
          lg
          icon="i-ri-instagram-line"
          :disabled="isRequestingAuthorization"
          :is-loading="isRequestingAuthorization"
          :label="$t('INBOX_MGMT.ADD.INSTAGRAM.CONTINUE_WITH_INSTAGRAM')"
          @click="requestAuthorization()"
        />
      </div>
    </div>
  </div>
</template>
