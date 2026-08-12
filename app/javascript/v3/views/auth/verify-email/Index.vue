<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import VueHcaptcha from '@hcaptcha/vue3-hcaptcha';
import AuthIconCard from '../../../components/auth/AuthIconCard.vue';
import { resendConfirmation } from '../../../api/auth';

const props = defineProps({
  email: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const router = useRouter();
const store = useStore();

if (!props.email) {
  router.push({ name: 'login' });
}

const globalConfig = computed(() => store.getters['globalConfig/get']);
const isResendingEmail = ref(false);
const hCaptcha = ref(null);
let captchaToken = '';

const performResend = async () => {
  isResendingEmail.value = true;
  try {
    await resendConfirmation({
      email: props.email,
      hCaptchaClientResponse: captchaToken,
    });
    useAlert(t('REGISTER.VERIFY_EMAIL.RESEND_SUCCESS'));
  } catch {
    useAlert(t('REGISTER.VERIFY_EMAIL.RESEND_ERROR'));
  } finally {
    isResendingEmail.value = false;
    captchaToken = '';
    if (globalConfig.value.hCaptchaSiteKey) {
      hCaptcha.value.reset();
    }
  }
};

const handleResendEmail = () => {
  if (isResendingEmail.value) return;
  if (globalConfig.value.hCaptchaSiteKey) {
    hCaptcha.value.execute();
  } else {
    performResend();
  }
};

const onCaptchaVerified = token => {
  captchaToken = token;
  performResend();
};

const onCaptchaError = () => {
  isResendingEmail.value = false;
  captchaToken = '';
  hCaptcha.value.reset();
};
</script>

<template>
  <AuthIconCard icon="i-lucide-mail-check">
    <h1 class="text-[26px] font-bold text-foreground mb-3">
      {{ t('REGISTER.VERIFY_EMAIL.TITLE') }}
    </h1>
    <p
      class="text-[14px] text-muted-foreground mb-8 px-2 leading-relaxed w-full"
    >
      {{ t('REGISTER.VERIFY_EMAIL.DESCRIPTION', { email }) }}
    </p>

    <div class="w-full">
      <VueHcaptcha
        v-if="globalConfig.hCaptchaSiteKey"
        ref="hCaptcha"
        size="invisible"
        :sitekey="globalConfig.hCaptchaSiteKey"
        @verify="onCaptchaVerified"
        @error="onCaptchaError"
        @expired="onCaptchaError"
        @challenge-expired="onCaptchaError"
        @closed="onCaptchaError"
      />
      <button
        type="button"
        data-testid="resend_email_button"
        :disabled="isResendingEmail"
        class="w-full h-11 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-md hover:shadow-lg transition-all flex items-center justify-center gap-2 font-medium text-[15px] outline-none disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-primary disabled:hover:shadow-md"
        @click="handleResendEmail"
      >
        <span
          v-if="isResendingEmail"
          class="i-lucide-loader-circle size-4 animate-spin"
        />
        {{ t('REGISTER.VERIFY_EMAIL.RESEND') }}
      </button>
    </div>
  </AuthIconCard>
</template>
