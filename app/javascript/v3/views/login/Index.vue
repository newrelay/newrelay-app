<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { login } from '../../api/auth';
import { useAlert } from 'dashboard/composables';
import { required, email as emailValidator } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { SESSION_STORAGE_KEYS } from 'dashboard/constants/sessionStorage';
import SessionStorage from 'shared/helpers/sessionStorage';

// components
import AuthShell from '../../components/auth/AuthShell.vue';
import MarketingPanel from '../../components/auth/MarketingPanel.vue';
import AuthInput from '../../components/auth/AuthInput.vue';
import Spinner from 'shared/components/Spinner.vue';
import MfaVerification from 'dashboard/components/auth/MfaVerification.vue';
import { formatInstallationDisplayName } from 'shared/helpers/installationNameHelper';

const props = defineProps({
  ssoAuthToken: { type: String, default: '' },
  ssoAccountId: { type: String, default: '' },
  ssoConversationId: { type: String, default: '' },
  email: { type: String, default: '' },
  authError: { type: String, default: '' },
});

const ERROR_MESSAGES = {
  'no-account-found': 'LOGIN.OAUTH.NO_ACCOUNT_FOUND',
  'business-account-only': 'LOGIN.OAUTH.BUSINESS_ACCOUNTS_ONLY',
  'saml-authentication-failed': 'LOGIN.SAML.API.ERROR_MESSAGE',
  'saml-not-enabled': 'LOGIN.SAML.API.ERROR_MESSAGE',
};

const IMPERSONATION_URL_SEARCH_KEY = 'impersonation';
const USER_NOT_CONFIRMED_ERROR_CODE = 'user_not_confirmed';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const credentials = reactive({
  email: '',
  password: '',
});
const loginApi = reactive({
  message: '',
  showLoading: false,
  hasErrored: false,
});
const mfaRequired = ref(false);
const mfaToken = ref(null);

const rules = {
  credentials: {
    password: { required },
    email: { required, email: emailValidator },
  },
};
const v$ = useVuelidate(rules, { credentials });

const globalConfig = computed(() => store.getters['globalConfig/get']);
const installationDisplayName = computed(() =>
  formatInstallationDisplayName(globalConfig.value.installationName)
);
const allowedLoginMethods = computed(
  () => window.chatwootConfig.allowedLoginMethods || ['email']
);
const showSamlLogin = computed(() =>
  allowedLoginMethods.value.includes('saml')
);
const getTranslatedMessage = key => {
  // Avoid dynamic key warning by handling each case explicitly
  switch (key) {
    case 'LOGIN.OAUTH.NO_ACCOUNT_FOUND':
      return t('LOGIN.OAUTH.NO_ACCOUNT_FOUND');
    case 'LOGIN.OAUTH.BUSINESS_ACCOUNTS_ONLY':
      return t('LOGIN.OAUTH.BUSINESS_ACCOUNTS_ONLY');
    case 'LOGIN.API.UNAUTH':
    default:
      return t('LOGIN.API.UNAUTH');
  }
};

// TODO: Remove this when Safari gets wider support
// Ref: https://caniuse.com/requestidlecallback
const requestIdleCallbackPolyfill = callback => {
  if (window.requestIdleCallback) {
    window.requestIdleCallback(callback);
  } else {
    // Fallback for safari: a delay of 0 runs the callback asynchronously
    // in the next available event loop iteration, like requestIdleCallback
    setTimeout(callback, 0);
  }
};

const showInlineError = message => {
  loginApi.showLoading = false;
  loginApi.hasErrored = true;
  loginApi.message = message;
};

const handleImpersonation = () => {
  // Detects impersonation mode via URL and sets a session flag to prevent user settings changes during impersonation.
  const urlParams = new URLSearchParams(window.location.search);
  const impersonation = urlParams.get(IMPERSONATION_URL_SEARCH_KEY);
  if (impersonation) {
    SessionStorage.set(SESSION_STORAGE_KEYS.IMPERSONATION_USER, true);
  }
};

const submitLogin = () => {
  loginApi.hasErrored = false;
  loginApi.showLoading = true;

  const loginCredentials = {
    email: props.email ? decodeURIComponent(props.email) : credentials.email,
    password: credentials.password,
    sso_auth_token: props.ssoAuthToken,
    ssoAccountId: props.ssoAccountId,
    ssoConversationId: props.ssoConversationId,
  };

  login(loginCredentials)
    .then(result => {
      // Check if MFA is required
      if (result?.mfaRequired) {
        loginApi.showLoading = false;
        mfaRequired.value = true;
        mfaToken.value = result.mfaToken;
        return;
      }

      handleImpersonation();
      loginApi.showLoading = false;
      useAlert(t('LOGIN.API.SUCCESS_MESSAGE'));
    })
    .catch(response => {
      if (response?.errorCode === USER_NOT_CONFIRMED_ERROR_CODE) {
        loginApi.showLoading = false;
        router.push({
          name: 'auth_verify_email',
          state: { email: loginCredentials.email },
        });
        return;
      }

      // Reset URL Params if the authentication is invalid
      if (props.email) {
        window.location = '/app/login';
      }
      showInlineError(response?.message || t('LOGIN.API.UNAUTH'));
    });
};

const submitFormLogin = () => {
  v$.value.credentials.email.$touch();
  if (v$.value.credentials.email.$invalid && !props.email) {
    return;
  }

  submitLogin();
};

const handleMfaVerified = () => {
  // MFA verification successful, continue with login
  handleImpersonation();
  window.location = '/app';
};

const handleMfaCancel = () => {
  // User cancelled MFA, reset state
  mfaRequired.value = false;
  mfaToken.value = null;
  credentials.password = '';
};

onMounted(() => {
  if (props.ssoAuthToken) {
    submitLogin();
  }
  if (props.authError) {
    const messageKey = ERROR_MESSAGES[props.authError] ?? 'LOGIN.API.UNAUTH';
    useAlert(getTranslatedMessage(messageKey));
    // wait for idle state
    requestIdleCallbackPolyfill(() => {
      // Remove the error query param from the url
      const { query } = route;
      router.replace({ query: { ...query, error: undefined } });
    });
  }
});
</script>

<template>
  <AuthShell>
    <!-- MFA Verification -->
    <MfaVerification
      v-if="mfaRequired"
      :mfa-token="mfaToken"
      @verified="handleMfaVerified"
      @cancel="handleMfaCancel"
    />

    <div
      v-else
      class="w-full max-w-[1000px] bg-card rounded-[2rem] shadow-xl border border-border/50 flex flex-col md:flex-row overflow-hidden relative z-10 min-h-[600px]"
    >
      <MarketingPanel />

      <!-- Auth form panel -->
      <div class="w-full md:w-[55%] bg-card p-10 flex flex-col relative">
        <div
          class="flex-1 flex flex-col justify-center max-w-[400px] w-full mx-auto"
        >
          <div class="text-center mb-8 mt-12 md:mt-0">
            <h2 class="text-[26px] font-bold text-foreground mb-2">
              {{ t('LOGIN.WELCOME_BACK') }}
            </h2>
            <p class="text-[14px] text-muted-foreground">
              {{ t('LOGIN.CONTINUE_TO') }}
              <span class="text-primary font-medium">{{
                installationDisplayName
              }}</span>
            </p>
          </div>

          <template v-if="!email">
            <div class="flex flex-col gap-3 mb-6">
              <button
                type="button"
                class="w-full h-11 bg-background border border-border rounded-lg shadow-sm flex items-center justify-center gap-3 hover:bg-muted/50 transition-colors text-[14px] font-medium text-foreground outline-none"
              >
                <span class="i-logos-google-icon size-5" />
                {{ t('LOGIN.OAUTH.GOOGLE_LOGIN') }}
              </button>
              <router-link
                v-if="showSamlLogin"
                to="/app/login/sso"
                class="w-full h-11 bg-background border border-border rounded-lg shadow-sm flex items-center justify-center gap-3 hover:bg-muted/50 transition-colors text-[14px] font-medium text-foreground outline-none"
              >
                <span class="i-lucide-lock size-[18px] text-muted-foreground" />
                {{ t('LOGIN.SAML.LABEL') }}
              </router-link>
            </div>

            <div class="flex items-center gap-4 mb-6">
              <div class="h-px bg-border flex-1" />
              <span
                class="text-[12px] font-medium text-muted-foreground uppercase tracking-wide"
              >
                {{ t('COMMON.OR') }}
              </span>
              <div class="h-px bg-border flex-1" />
            </div>

            <!-- Error alert -->
            <div
              v-if="loginApi.hasErrored"
              class="mb-5 flex items-start gap-3 bg-destructive/10 text-destructive border border-destructive/20 p-3 rounded-lg"
            >
              <span class="i-lucide-circle-alert size-5 shrink-0 mt-0.5" />
              <div class="text-[13px] font-medium leading-relaxed">
                {{ loginApi.message }}
              </div>
            </div>

            <form class="flex flex-col gap-5" @submit.prevent="submitFormLogin">
              <AuthInput
                v-model="credentials.email"
                name="email_address"
                type="email"
                icon="i-lucide-mail"
                data-testid="email_input"
                required
                :tabindex="1"
                :label="t('LOGIN.EMAIL.LABEL')"
                :placeholder="t('LOGIN.EMAIL.PLACEHOLDER')"
                :has-error="v$.credentials.email.$error"
                :error-message="t('LOGIN.EMAIL.ERROR')"
                @input="v$.credentials.email.$touch"
              />
              <AuthInput
                v-model="credentials.password"
                name="password"
                type="password"
                icon="i-lucide-lock"
                data-testid="password_input"
                required
                :tabindex="2"
                :label="t('LOGIN.PASSWORD.LABEL')"
                :placeholder="t('LOGIN.PASSWORD.PLACEHOLDER')"
                :has-error="v$.credentials.password.$error"
                @input="v$.credentials.password.$touch"
              >
                <template #rightOfLabel>
                  <router-link
                    v-if="!globalConfig.disableUserProfileUpdate"
                    to="/app/auth/reset/password"
                    class="text-[13px] font-medium text-primary hover:underline"
                    tabindex="4"
                  >
                    {{ t('LOGIN.FORGOT_PASSWORD') }}
                  </router-link>
                </template>
              </AuthInput>
              <button
                type="submit"
                data-testid="submit_button"
                :tabindex="3"
                :disabled="loginApi.showLoading"
                class="w-full h-11 mt-3 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-md hover:shadow-lg transition-all flex items-center justify-center gap-2 font-medium text-[15px] outline-none disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-primary disabled:hover:shadow-md"
              >
                <span
                  v-if="loginApi.showLoading"
                  class="i-lucide-loader-circle size-4 animate-spin"
                />
                {{ t('LOGIN.SUBMIT') }}
                <span
                  v-if="!loginApi.showLoading"
                  class="i-lucide-arrow-right size-4"
                />
              </button>
            </form>

            <p class="text-center text-[14px] text-muted-foreground mt-8">
              {{ t('LOGIN.NO_ACCOUNT') }}
              <router-link
                to="/app/auth/signup"
                class="text-primary font-medium hover:underline"
              >
                {{ t('LOGIN.CREATE_NEW_ACCOUNT') }}
              </router-link>
            </p>
          </template>
          <div v-else class="flex items-center justify-center">
            <Spinner color-scheme="primary" size="" />
          </div>
        </div>
      </div>
    </div>
  </AuthShell>
</template>
