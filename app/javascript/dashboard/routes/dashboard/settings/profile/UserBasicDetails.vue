<script>
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { RelayInput, RelayLabel } from 'dashboard/components-next/relay';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
export default {
  components: {
    NextButton,
    RelayInput,
    RelayLabel,
  },
  props: {
    name: {
      type: String,
      default: '',
    },
    email: {
      type: String,
      default: '',
    },
    displayName: {
      type: String,
      default: '',
    },
    emailEnabled: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['updateUser'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      userName: this.name,
      userDisplayName: this.displayName,
      userEmail: this.email,
    };
  },
  validations: {
    userName: {
      required,
      minLength: minLength(1),
    },
    userDisplayName: {},
    userEmail: {
      required,
      email,
    },
  },
  watch: {
    name: {
      handler(value) {
        this.userName = value;
      },
      immediate: true,
    },
    displayName: {
      handler(value) {
        this.userDisplayName = value;
      },
      immediate: true,
    },
    email: {
      handler(value) {
        this.userEmail = value;
      },
      immediate: true,
    },
  },
  methods: {
    async updateUser() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        useAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
        return;
      }
      this.$emit('updateUser', {
        name: this.userName,
        displayName: this.userDisplayName,
        email: this.userEmail,
      });
    },
  },
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="updateUser('profile')">
    <div class="flex flex-col gap-2">
      <RelayLabel html-for="profile-name">
        {{ $t('PROFILE_SETTINGS.FORM.NAME.LABEL') }}
      </RelayLabel>
      <RelayInput
        id="profile-name"
        v-model="userName"
        class-name="h-10 shadow-xs bg-background"
        :placeholder="$t('PROFILE_SETTINGS.FORM.NAME.PLACEHOLDER')"
        @update:model-value="v$.userName.$touch"
        @blur="v$.userName.$touch"
      />
      <p v-if="v$.userName.$error" class="text-xs text-destructive">
        {{ $t('PROFILE_SETTINGS.FORM.NAME.ERROR') }}
      </p>
    </div>
    <div class="flex flex-col gap-2">
      <RelayLabel html-for="profile-display-name">
        {{ $t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.LABEL') }}
      </RelayLabel>
      <RelayInput
        id="profile-display-name"
        v-model="userDisplayName"
        class-name="h-10 shadow-xs bg-background"
        :placeholder="$t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.PLACEHOLDER')"
        @update:model-value="v$.userDisplayName.$touch"
        @blur="v$.userDisplayName.$touch"
      />
      <p v-if="v$.userDisplayName.$error" class="text-xs text-destructive">
        {{ $t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.ERROR') }}
      </p>
    </div>
    <div v-if="emailEnabled" class="flex flex-col gap-2">
      <RelayLabel html-for="profile-email">
        {{ $t('PROFILE_SETTINGS.FORM.EMAIL.LABEL') }}
      </RelayLabel>
      <RelayInput
        id="profile-email"
        v-model="userEmail"
        class-name="h-10 shadow-xs bg-background"
        :placeholder="$t('PROFILE_SETTINGS.FORM.EMAIL.PLACEHOLDER')"
        @update:model-value="v$.userEmail.$touch"
        @blur="v$.userEmail.$touch"
      />
      <p v-if="v$.userEmail.$error" class="text-xs text-destructive">
        {{ $t('PROFILE_SETTINGS.FORM.EMAIL.ERROR') }}
      </p>
    </div>
    <div>
      <NextButton type="submit" :label="$t('PROFILE_SETTINGS.BTN_TEXT')" />
    </div>
  </form>
</template>
