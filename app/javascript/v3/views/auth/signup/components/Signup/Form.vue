<script setup>
import { ref, computed, reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import VueHcaptcha from '@hcaptcha/vue3-hcaptcha';
import AuthInput from '../../../../../components/auth/AuthInput.vue';
import PasswordRequirements from './PasswordRequirements.vue';
import { isValidPassword } from 'shared/helpers/Validators';
import GoogleOAuthButton from '../../../../../components/GoogleOauth/Button.vue';
import { register } from '../../../../../api/auth';
import * as CompanyEmailValidator from 'company-email-validator';

const MIN_PASSWORD_LENGTH = 6;

const store = useStore();
const { t } = useI18n();
const router = useRouter();

const hCaptcha = ref(null);
const isPasswordFocused = ref(false);
const isSignupInProgress = ref(false);

const credentials = reactive({
  fullName: '',
  accountName: '',
  email: '',
  password: '',
  termsAccepted: false,
  hCaptchaClientResponse: '',
});

const rules = {
  credentials: {
    fullName: {
      required,
      minLength: minLength(2),
    },
    email: {
      required,
      email,
      businessEmailValidator(value) {
        return CompanyEmailValidator.isCompanyEmail(value);
      },
    },
    password: {
      required,
      isValidPassword,
      minLength: minLength(MIN_PASSWORD_LENGTH),
    },
    termsAccepted: {
      mustBeTrue(value) {
        return value === true;
      },
    },
  },
};

const v$ = useVuelidate(rules, { credentials });

const globalConfig = computed(() => store.getters['globalConfig/get']);

const termsLink = computed(() =>
  t('REGISTER.TERMS_ACCEPT')
    .replace('https://www.newrelay.com/terms', globalConfig.value.termsURL)
    .replace(
      'https://www.newrelay.com/privacy-policy',
      globalConfig.value.privacyURL
    )
);

const allowedLoginMethods = computed(
  () => window.chatwootConfig.allowedLoginMethods || ['email']
);

const showGoogleOAuth = computed(
  () =>
    allowedLoginMethods.value.includes('google_oauth') &&
    Boolean(window.chatwootConfig.googleOAuthClientId)
);

const showSamlLogin = computed(() =>
  allowedLoginMethods.value.includes('saml')
);

const showSocialLogin = computed(
  () => showGoogleOAuth.value || showSamlLogin.value
);

const isFormValid = computed(() => !v$.value.$invalid);

const performRegistration = async () => {
  isSignupInProgress.value = true;
  try {
    await register(credentials);
    router.push({
      name: 'auth_verify_email',
      state: { email: credentials.email },
    });
  } catch (error) {
    const errorMessage = error?.message || t('REGISTER.API.ERROR_MESSAGE');
    if (globalConfig.value.hCaptchaSiteKey) {
      hCaptcha.value.reset();
      credentials.hCaptchaClientResponse = '';
    }
    useAlert(errorMessage);
  } finally {
    isSignupInProgress.value = false;
  }
};

const submit = () => {
  if (isSignupInProgress.value) return;
  v$.value.$touch();
  if (v$.value.$invalid) return;
  isSignupInProgress.value = true;
  if (globalConfig.value.hCaptchaSiteKey) {
    hCaptcha.value.execute();
  } else {
    performRegistration();
  }
};

const onRecaptchaVerified = token => {
  credentials.hCaptchaClientResponse = token;
  performRegistration();
};

const onCaptchaError = () => {
  isSignupInProgress.value = false;
  credentials.hCaptchaClientResponse = '';
  hCaptcha.value.reset();
};
</script>

<template>
  <div class="flex-1">
    <div v-if="showSocialLogin" class="flex flex-col gap-3 mb-6">
      <GoogleOAuthButton v-if="showGoogleOAuth">
        {{ t('REGISTER.OAUTH.GOOGLE_SIGNUP') }}
      </GoogleOAuthButton>
      <router-link
        v-if="showSamlLogin"
        to="/app/login/sso"
        class="w-full h-11 bg-background border border-border rounded-lg shadow-sm flex items-center justify-center gap-3 hover:bg-muted/50 transition-colors text-[14px] font-medium text-foreground outline-none"
      >
        <span class="i-lucide-lock size-[18px] text-muted-foreground" />
        {{ t('REGISTER.OAUTH.SSO_SIGNUP') }}
      </router-link>
    </div>
    <div v-if="showSocialLogin" class="flex items-center gap-4 mb-6">
      <div class="h-px bg-border flex-1" />
      <span
        class="text-[12px] font-medium text-muted-foreground uppercase tracking-wide"
      >
        {{ t('COMMON.OR') }}
      </span>
      <div class="h-px bg-border flex-1" />
    </div>

    <form class="flex flex-col gap-4" @submit.prevent="submit">
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <AuthInput
          v-model="credentials.fullName"
          type="text"
          name="full_name"
          size="md"
          icon="i-lucide-user"
          required
          :label="t('REGISTER.FULL_NAME.LABEL')"
          :placeholder="t('REGISTER.FULL_NAME.PLACEHOLDER')"
          :has-error="v$.credentials.fullName.$error"
          :error-message="t('REGISTER.FULL_NAME.ERROR')"
          @blur="v$.credentials.fullName.$touch"
        />
        <AuthInput
          v-model="credentials.accountName"
          type="text"
          name="company_name"
          size="md"
          icon="i-lucide-building"
          :label="t('REGISTER.COMPANY_NAME.LABEL')"
          :placeholder="t('REGISTER.COMPANY_NAME.PLACEHOLDER')"
        />
      </div>
      <AuthInput
        v-model="credentials.email"
        type="email"
        name="email_address"
        size="md"
        icon="i-lucide-mail"
        required
        :label="t('REGISTER.EMAIL.LABEL')"
        :placeholder="t('REGISTER.EMAIL.PLACEHOLDER')"
        :has-error="v$.credentials.email.$error"
        :error-message="t('REGISTER.EMAIL.ERROR')"
        @blur="v$.credentials.email.$touch"
      />
      <div class="relative">
        <AuthInput
          v-model="credentials.password"
          type="password"
          name="password"
          size="md"
          icon="i-lucide-lock"
          required
          :label="t('REGISTER.PASSWORD.LABEL')"
          :placeholder="t('REGISTER.PASSWORD.PLACEHOLDER')"
          :has-error="v$.credentials.password.$error"
          @focus="isPasswordFocused = true"
          @blur="
            isPasswordFocused = false;
            v$.credentials.password.$touch();
          "
        />
        <Transition
          enter-active-class="transition duration-200 ease-out origin-top"
          enter-from-class="opacity-0 scale-95 -translate-y-1"
          enter-to-class="opacity-100 scale-100 translate-y-0"
          leave-active-class="transition duration-150 ease-in origin-top"
          leave-from-class="opacity-100 scale-100 translate-y-0"
          leave-to-class="opacity-0 scale-95 -translate-y-1"
        >
          <PasswordRequirements
            v-if="isPasswordFocused"
            :password="credentials.password"
          />
        </Transition>
      </div>

      <div class="flex items-start gap-2.5 mt-1">
        <div class="flex items-center h-5">
          <input
            id="terms"
            v-model="credentials.termsAccepted"
            type="checkbox"
            class="size-4 rounded border-border text-primary focus:ring-primary"
            @change="v$.credentials.termsAccepted.$touch"
          />
        </div>
        <label
          for="terms"
          class="text-[13px] text-muted-foreground leading-tight cursor-pointer [&>a]:text-primary [&>a]:hover:underline"
          v-html="termsLink"
        />
      </div>
      <p
        v-if="v$.credentials.termsAccepted.$error"
        class="text-[13px] text-destructive -mt-2"
      >
        {{ t('REGISTER.TERMS_ERROR') }}
      </p>

      <VueHcaptcha
        v-if="globalConfig.hCaptchaSiteKey"
        ref="hCaptcha"
        size="invisible"
        :sitekey="globalConfig.hCaptchaSiteKey"
        @verify="onRecaptchaVerified"
        @error="onCaptchaError"
        @expired="onCaptchaError"
        @challenge-expired="onCaptchaError"
        @closed="onCaptchaError"
      />
      <button
        type="submit"
        data-testid="submit_button"
        :disabled="isSignupInProgress || !isFormValid"
        class="w-full h-11 mt-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-md hover:shadow-lg transition-all flex items-center justify-center gap-2 font-medium text-[15px] outline-none disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-primary disabled:hover:shadow-md"
      >
        <span
          v-if="isSignupInProgress"
          class="i-lucide-loader-circle size-4 animate-spin"
        />
        {{ t('REGISTER.SUBMIT') }}
        <span v-if="!isSignupInProgress" class="i-lucide-arrow-right size-4" />
      </button>
    </form>
  </div>
</template>
