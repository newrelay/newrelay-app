<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import instagramClient from 'dashboard/api/channel/instagramClient';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();

const hasError = ref(false);
const errorStateMessage = ref('');
const errorStateDescription = ref('');
const isRequestingAuthorization = ref(false);

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
        v-else
        class="flex w-full flex-col items-center justify-center rounded-xl border border-border bg-card px-8 py-10 text-center shadow-sm"
      >
        <h6 class="text-lg font-semibold text-foreground">
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
