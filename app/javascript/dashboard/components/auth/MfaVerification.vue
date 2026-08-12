<script setup>
import axios from 'axios';
import { ref, computed, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { handleOtpPaste } from 'shared/helpers/clipboard';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { useAccount } from 'dashboard/composables/useAccount';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import AuthInput from 'v3/components/auth/AuthInput.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  mfaToken: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['verified', 'cancel']);

const { t } = useI18n();
const { isOnChatwootCloud } = useAccount();

const OTP = 'otp';
const BACKUP = 'backup';

// State
const verificationMethod = ref(OTP);
const otpDigits = ref(['', '', '', '', '', '']);
const backupCode = ref('');
const isVerifying = ref(false);
const errorMessage = ref('');
const helpModalRef = ref(null);
const otpInputRefs = ref([]);

// Computed
const otpCode = computed(() => otpDigits.value.join(''));
const canSubmit = computed(() =>
  verificationMethod.value === OTP
    ? otpCode.value.length === 6
    : backupCode.value.length === 8
);

const contactDescKey = computed(() =>
  isOnChatwootCloud.value ? 'CONTACT_DESC_CLOUD' : 'CONTACT_DESC_SELF_HOSTED'
);

const focusInput = i => otpInputRefs.value[i]?.focus();

// Verification
const handleVerification = async () => {
  if (!canSubmit.value || isVerifying.value) return;

  isVerifying.value = true;
  errorMessage.value = '';

  try {
    const payload = {
      mfa_token: props.mfaToken,
    };

    if (verificationMethod.value === OTP) {
      payload.otp_code = otpCode.value;
    } else {
      payload.backup_code = backupCode.value;
    }

    const response = await axios.post('/auth/sign_in', payload);

    // Set auth credentials and redirect
    if (response.data && response.headers) {
      // Store auth credentials in cookies
      const authData = {
        'access-token': response.headers['access-token'],
        'token-type': response.headers['token-type'],
        client: response.headers.client,
        expiry: response.headers.expiry,
        uid: response.headers.uid,
      };

      // Store in cookies for auth
      document.cookie = `cw_d_session_info=${encodeURIComponent(JSON.stringify(authData))}; path=/; SameSite=Lax`;

      // Redirect to dashboard
      window.location.href = '/app/';
    } else {
      emit('verified', response.data);
    }
  } catch (error) {
    errorMessage.value =
      parseAPIErrorResponse(error) || t('MFA_VERIFICATION.VERIFICATION_FAILED');

    // Clear inputs on error
    if (verificationMethod.value === OTP) {
      otpDigits.value.fill('');
      await nextTick();
      focusInput(0);
    } else {
      backupCode.value = '';
    }
  } finally {
    isVerifying.value = false;
  }
};

// OTP Input Handling
const handleOtpInput = async i => {
  const v = otpDigits.value[i];

  // Only allow numbers
  if (!/^\d*$/.test(v)) {
    otpDigits.value[i] = '';
    return;
  }

  // Move to next input if value entered
  if (v && i < 5) {
    await nextTick();
    focusInput(i + 1);
  }

  // Auto-submit if all digits entered
  if (otpCode.value.length === 6) {
    handleVerification();
  }
};

const handleBackspace = (e, i) => {
  if (!otpDigits.value[i] && i > 0) {
    e.preventDefault();
    focusInput(i - 1);
    otpDigits.value[i - 1] = '';
  }
};

const handleOtpCodePaste = e => {
  e.preventDefault();
  const code = handleOtpPaste(e, 6);

  if (code) {
    otpDigits.value = code.split('');
    handleVerification();
  }
};

// Alternative Actions
const handleTryAnotherMethod = () => {
  // Toggle between methods
  verificationMethod.value = verificationMethod.value === OTP ? BACKUP : OTP;
  otpDigits.value.fill('');
  backupCode.value = '';
  errorMessage.value = '';
};
</script>

<template>
  <div class="w-full max-w-md mx-auto">
    <div
      class="sm:mx-auto sm:w-full sm:max-w-lg p-11 bg-card border border-border/50 shadow-xl sm:rounded-[2rem]"
    >
      <!-- Header -->
      <div class="text-center mb-6">
        <div
          class="inline-flex items-center justify-center size-14 bg-primary/10 border border-primary/20 rounded-2xl mb-4 shadow-sm"
        >
          <Icon icon="i-lucide-lock-keyhole" class="size-6 text-primary" />
        </div>
        <h2 class="text-2xl font-semibold text-foreground">
          {{ $t('MFA_VERIFICATION.TITLE') }}
        </h2>
        <p class="text-sm text-muted-foreground mt-2">
          {{ $t('MFA_VERIFICATION.DESCRIPTION') }}
        </p>
      </div>

      <!-- Tab Selection -->
      <div class="flex rounded-lg bg-muted p-1 mb-6">
        <button
          v-for="method in [OTP, BACKUP]"
          :key="method"
          class="flex-1 py-2 px-4 text-sm font-medium rounded-md transition-colors"
          :class="
            verificationMethod === method
              ? 'bg-background text-foreground shadow-sm'
              : 'text-muted-foreground hover:text-foreground'
          "
          @click="verificationMethod = method"
        >
          {{
            $t(
              `MFA_VERIFICATION.${method === OTP ? 'AUTHENTICATOR_APP' : 'BACKUP_CODE'}`
            )
          }}
        </button>
      </div>

      <!-- Verification Form -->
      <form class="space-y-4" @submit.prevent="handleVerification">
        <!-- OTP Code Input -->
        <div v-if="verificationMethod === OTP">
          <label class="block text-[13.5px] font-medium text-foreground mb-2">
            {{ $t('MFA_VERIFICATION.ENTER_OTP_CODE') }}
          </label>
          <div class="flex justify-between gap-2">
            <input
              v-for="(_, i) in otpDigits"
              :key="i"
              ref="otpInputRefs"
              v-model="otpDigits[i]"
              type="text"
              maxlength="1"
              pattern="[0-9]"
              inputmode="numeric"
              class="w-12 h-12 text-center text-lg font-semibold border border-input hover:border-border rounded-lg focus:border-primary focus-visible:ring-1 focus-visible:ring-primary/30 outline-none bg-background text-foreground placeholder:text-muted-foreground transition-colors"
              @input="handleOtpInput(i)"
              @keydown.left.prevent="focusInput(i - 1)"
              @keydown.right.prevent="focusInput(i + 1)"
              @keydown.backspace="handleBackspace($event, i)"
              @paste="handleOtpCodePaste"
            />
          </div>
        </div>

        <!-- Backup Code Input -->
        <div v-if="verificationMethod === BACKUP">
          <AuthInput
            v-model="backupCode"
            name="backup_code"
            type="text"
            data-testid="backup_code_input"
            :tabindex="1"
            required
            :label="$t('MFA_VERIFICATION.ENTER_BACKUP_CODE')"
            :placeholder="
              $t('MFA_VERIFICATION.BACKUP_CODE_PLACEHOLDER') || '000000'
            "
            @keyup.enter="handleVerification"
          />
        </div>

        <!-- Error Message -->
        <div
          v-if="errorMessage"
          class="p-3 bg-destructive/10 border border-destructive/20 rounded-lg"
        >
          <p class="text-sm text-destructive">{{ errorMessage }}</p>
        </div>

        <!-- Submit Button -->
        <NextButton
          lg
          type="submit"
          data-testid="submit_button"
          class="w-full"
          :tabindex="2"
          :label="$t('MFA_VERIFICATION.VERIFY_BUTTON')"
          :disabled="!canSubmit || isVerifying"
          :is-loading="isVerifying"
        />

        <!-- Alternative Actions -->
        <div class="text-center flex items-center flex-col gap-2 pt-4">
          <NextButton
            sm
            link
            type="button"
            class="w-full hover:!no-underline"
            :tabindex="2"
            :label="$t('MFA_VERIFICATION.TRY_ANOTHER_METHOD')"
            @click="handleTryAnotherMethod"
          />
          <NextButton
            sm
            slate
            link
            type="button"
            class="w-full hover:!no-underline"
            :tabindex="3"
            :label="$t('MFA_VERIFICATION.CANCEL_LOGIN')"
            @click="() => emit('cancel')"
          />
        </div>
      </form>
    </div>

    <!-- Help Text -->
    <div class="mt-6 text-center">
      <p class="text-sm text-muted-foreground">
        {{ $t('MFA_VERIFICATION.HELP_TEXT') }}
      </p>
      <NextButton
        sm
        link
        type="button"
        class="w-full hover:!no-underline"
        :tabindex="4"
        :label="$t('MFA_VERIFICATION.LEARN_MORE')"
        @click="helpModalRef?.open()"
      />
    </div>

    <!-- Help Modal -->
    <Dialog
      ref="helpModalRef"
      :title="$t('MFA_VERIFICATION.HELP_MODAL.TITLE')"
      :show-confirm-button="false"
      class="[&>dialog>div]:bg-n-alpha-3 [&>dialog>div]:rounded-lg"
      @confirm="helpModalRef?.close()"
    >
      <div class="space-y-4 text-sm text-muted-foreground">
        <div v-for="section in ['AUTHENTICATOR', 'BACKUP']" :key="section">
          <h4 class="font-medium text-foreground mb-2">
            {{ $t(`MFA_VERIFICATION.HELP_MODAL.${section}_TITLE`) }}
          </h4>
          <p>{{ $t(`MFA_VERIFICATION.HELP_MODAL.${section}_DESC`) }}</p>
        </div>
        <div>
          <h4 class="font-medium text-foreground mb-2">
            {{ $t('MFA_VERIFICATION.HELP_MODAL.CONTACT_TITLE') }}
          </h4>
          <p>{{ $t(`MFA_VERIFICATION.HELP_MODAL.${contactDescKey}`) }}</p>
        </div>
      </div>
    </Dialog>
  </div>
</template>
