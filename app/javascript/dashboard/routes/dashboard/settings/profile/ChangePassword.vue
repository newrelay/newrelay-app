<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';

export default {
  components: {
    RelayButton,
    RelayInput,
    RelayLabel,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      currentPassword: '',
      password: '',
      passwordConfirmation: '',
      isPasswordChanging: false,
      errorMessage: '',
    };
  },
  validations: {
    currentPassword: {
      required,
    },
    password: {
      minLength: minLength(6),
    },
    passwordConfirmation: {
      minLength: minLength(6),
      isEqPassword(value) {
        if (value !== this.password) {
          return false;
        }
        return true;
      },
    },
  },
  computed: {
    isButtonDisabled() {
      return (
        !this.currentPassword ||
        !this.passwordConfirmation ||
        !this.v$.passwordConfirmation.isEqPassword
      );
    },
  },
  methods: {
    async changePassword() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        useAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
        return;
      }
      let alertMessage = this.$t('PROFILE_SETTINGS.PASSWORD_UPDATE_SUCCESS');
      try {
        await this.$store.dispatch('updatePassword', {
          password: this.password,
          passwordConfirmation: this.passwordConfirmation,
          currentPassword: this.currentPassword,
        });
      } catch (error) {
        alertMessage =
          parseAPIErrorResponse(error) ||
          this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
      } finally {
        useAlert(alertMessage);
      }
    },
  },
};
</script>

<template>
  <form @submit.prevent="changePassword()">
    <div class="flex flex-col w-full gap-4">
      <div class="flex flex-col gap-2">
        <RelayLabel html-for="current-password">
          {{ $t('PROFILE_SETTINGS.FORM.CURRENT_PASSWORD.LABEL') }}
        </RelayLabel>
        <RelayInput
          id="current-password"
          v-model="currentPassword"
          type="password"
          class-name="h-10 shadow-xs bg-background"
          :placeholder="
            $t('PROFILE_SETTINGS.FORM.CURRENT_PASSWORD.PLACEHOLDER')
          "
          @update:model-value="v$.currentPassword.$touch"
          @blur="v$.currentPassword.$touch"
        />
        <p v-if="v$.currentPassword.$error" class="text-xs text-destructive">
          {{ $t('PROFILE_SETTINGS.FORM.CURRENT_PASSWORD.ERROR') }}
        </p>
      </div>

      <div class="flex flex-col gap-2">
        <RelayLabel html-for="new-password">
          {{ $t('PROFILE_SETTINGS.FORM.PASSWORD.LABEL') }}
        </RelayLabel>
        <RelayInput
          id="new-password"
          v-model="password"
          type="password"
          class-name="h-10 shadow-xs bg-background"
          :placeholder="$t('PROFILE_SETTINGS.FORM.PASSWORD.PLACEHOLDER')"
          @update:model-value="v$.password.$touch"
          @blur="v$.password.$touch"
        />
        <p v-if="v$.password.$error" class="text-xs text-destructive">
          {{ $t('PROFILE_SETTINGS.FORM.PASSWORD.ERROR') }}
        </p>
      </div>

      <div class="flex flex-col gap-2">
        <RelayLabel html-for="confirm-password">
          {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.LABEL') }}
        </RelayLabel>
        <RelayInput
          id="confirm-password"
          v-model="passwordConfirmation"
          type="password"
          class-name="h-10 shadow-xs bg-background"
          :placeholder="
            $t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.PLACEHOLDER')
          "
          @update:model-value="v$.passwordConfirmation.$touch"
          @blur="v$.passwordConfirmation.$touch"
        />
        <p
          v-if="v$.passwordConfirmation.$error"
          class="text-xs text-destructive"
        >
          {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.ERROR') }}
        </p>
      </div>

      <div>
        <RelayButton
          type="submit"
          class="shadow-sm"
          :disabled="isButtonDisabled"
        >
          {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.BTN_TEXT') }}
        </RelayButton>
      </div>
    </div>
  </form>
</template>
