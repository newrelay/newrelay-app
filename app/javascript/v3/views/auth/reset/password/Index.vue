<script setup>
import { reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { required, minLength, email } from '@vuelidate/validators';
import { useBranding } from 'shared/composables/useBranding';
import AuthIconCard from '../../../../components/auth/AuthIconCard.vue';
import AuthInput from '../../../../components/auth/AuthInput.vue';
import { resetPassword } from '../../../../api/auth';

const { t } = useI18n();
const { replaceInstallationName } = useBranding();

const credentials = reactive({ email: '' });
const resetPasswordApi = reactive({
  message: '',
  showLoading: false,
});

const rules = {
  credentials: {
    email: {
      required,
      email,
      minLength: minLength(4),
    },
  },
};
const v$ = useVuelidate(rules, { credentials });

const showAlertMessage = message => {
  // Reset loading, current selected agent
  resetPasswordApi.showLoading = false;
  useAlert(message);
};

const submit = () => {
  resetPasswordApi.showLoading = true;
  resetPassword(credentials)
    .then(res => {
      let successMessage = t('RESET_PASSWORD.API.SUCCESS_MESSAGE');
      if (res.data && res.data.message) {
        successMessage = res.data.message;
      }
      showAlertMessage(successMessage);
    })
    .catch(error => {
      let errorMessage = t('RESET_PASSWORD.API.ERROR_MESSAGE');
      if (error?.response?.data?.message) {
        errorMessage = error.response.data.message;
      }
      showAlertMessage(errorMessage);
    });
};
</script>

<template>
  <AuthIconCard icon="i-lucide-key-round">
    <h1 class="text-[26px] font-bold text-foreground mb-3">
      {{ t('RESET_PASSWORD.TITLE') }}
    </h1>
    <p
      class="text-[14px] text-muted-foreground mb-8 px-2 leading-relaxed w-full"
    >
      {{ replaceInstallationName(t('RESET_PASSWORD.DESCRIPTION')) }}
    </p>

    <form class="w-full flex flex-col gap-5" @submit.prevent="submit">
      <AuthInput
        v-model="credentials.email"
        name="email_address"
        type="email"
        icon="i-lucide-mail"
        required
        :placeholder="t('RESET_PASSWORD.EMAIL.PLACEHOLDER')"
        :has-error="v$.credentials.email.$error"
        :error-message="t('RESET_PASSWORD.EMAIL.ERROR')"
        @input="v$.credentials.email.$touch"
      />
      <button
        type="submit"
        data-testid="submit_button"
        :disabled="
          v$.credentials.email.$invalid || resetPasswordApi.showLoading
        "
        class="w-full h-11 mt-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-md hover:shadow-lg transition-all flex items-center justify-center gap-2 font-medium text-[15px] outline-none disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-primary disabled:hover:shadow-md"
      >
        <span
          v-if="resetPasswordApi.showLoading"
          class="i-lucide-loader-circle size-4 animate-spin"
        />
        {{ t('RESET_PASSWORD.SUBMIT') }}
        <span
          v-if="!resetPasswordApi.showLoading"
          class="i-lucide-arrow-right size-4"
        />
      </button>
    </form>

    <p class="text-center text-[14px] text-muted-foreground mt-8">
      {{ t('RESET_PASSWORD.GO_BACK_TO_LOGIN') }}
      <router-link
        to="/app/login"
        class="text-primary font-medium hover:underline"
      >
        {{ t('COMMON.CLICK_HERE') }}.
      </router-link>
    </p>
  </AuthIconCard>
</template>
