<script setup>
import { reactive, onMounted } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import AuthIconCard from '../../../components/auth/AuthIconCard.vue';
import AuthInput from '../../../components/auth/AuthInput.vue';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { setNewPassword } from '../../../api/auth';

const props = defineProps({
  resetPasswordToken: { type: String, default: '' },
});

const { t } = useI18n();

const credentials = reactive({
  confirmPassword: '',
  password: '',
});
const newPasswordAPI = reactive({
  message: '',
  showLoading: false,
});

const rules = {
  credentials: {
    password: {
      required,
      minLength: minLength(6),
    },
    confirmPassword: {
      required,
      minLength: minLength(6),
      isEqPassword(value) {
        return value === credentials.password;
      },
    },
  },
};
const v$ = useVuelidate(rules, { credentials });

onMounted(() => {
  // If url opened without token, redirect to login
  if (!props.resetPasswordToken) {
    window.location = DEFAULT_REDIRECT_URL;
  }
});

const showAlertMessage = message => {
  // Reset loading, current selected agent
  newPasswordAPI.showLoading = false;
  useAlert(message);
};

const submitForm = () => {
  newPasswordAPI.showLoading = true;
  const payload = {
    confirmPassword: credentials.confirmPassword,
    password: credentials.password,
    resetPasswordToken: props.resetPasswordToken,
  };
  setNewPassword(payload)
    .then(() => {
      window.location = DEFAULT_REDIRECT_URL;
    })
    .catch(error => {
      showAlertMessage(
        error?.message || t('SET_NEW_PASSWORD.API.ERROR_MESSAGE')
      );
    });
};
</script>

<template>
  <AuthIconCard icon="i-lucide-lock-keyhole">
    <h1 class="text-[26px] font-bold text-foreground mb-8">
      {{ t('SET_NEW_PASSWORD.TITLE') }}
    </h1>

    <form class="w-full flex flex-col gap-5" @submit.prevent="submitForm">
      <AuthInput
        v-model="credentials.password"
        name="password"
        type="password"
        icon="i-lucide-lock"
        required
        :label="t('SET_NEW_PASSWORD.PASSWORD.LABEL')"
        :placeholder="t('SET_NEW_PASSWORD.PASSWORD.PLACEHOLDER')"
        :has-error="v$.credentials.password.$error"
        :error-message="t('SET_NEW_PASSWORD.PASSWORD.ERROR')"
        @blur="v$.credentials.password.$touch"
      />
      <AuthInput
        v-model="credentials.confirmPassword"
        name="confirm_password"
        type="password"
        icon="i-lucide-lock"
        required
        :label="t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.LABEL')"
        :placeholder="t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.PLACEHOLDER')"
        :has-error="v$.credentials.confirmPassword.$error"
        :error-message="t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.ERROR')"
        @blur="v$.credentials.confirmPassword.$touch"
      />
      <button
        type="submit"
        data-testid="submit_button"
        :disabled="
          v$.credentials.password.$invalid ||
          v$.credentials.confirmPassword.$invalid ||
          newPasswordAPI.showLoading
        "
        class="w-full h-11 mt-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-md hover:shadow-lg transition-all flex items-center justify-center gap-2 font-medium text-[15px] outline-none disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-primary disabled:hover:shadow-md"
      >
        <span
          v-if="newPasswordAPI.showLoading"
          class="i-lucide-loader-circle size-4 animate-spin"
        />
        {{ t('SET_NEW_PASSWORD.SUBMIT') }}
        <span
          v-if="!newPasswordAPI.showLoading"
          class="i-lucide-arrow-right size-4"
        />
      </button>
    </form>
  </AuthIconCard>
</template>
