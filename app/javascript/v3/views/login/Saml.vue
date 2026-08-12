<script setup>
import { ref, nextTick, onMounted } from 'vue';
import { required, email } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

// components
import AuthIconCard from '../../components/auth/AuthIconCard.vue';
import AuthInput from '../../components/auth/AuthInput.vue';

const props = defineProps({
  authError: {
    type: String,
    default: '',
  },
  target: {
    type: String,
    default: 'web',
  },
});

const { t } = useI18n();

const credentials = ref({
  email: '',
});

const handleAuthError = () => {
  if (!props.authError) {
    return;
  }

  const translatedMessage = t('LOGIN.SAML.API.ERROR_MESSAGE');
  useAlert(translatedMessage);
};

const validations = {
  credentials: {
    email: {
      required,
      email,
    },
  },
};

const v$ = useVuelidate(validations, { credentials });

const csrfToken = ref('');

onMounted(async () => {
  csrfToken.value =
    document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute('content') || '';

  await nextTick(handleAuthError);
});
</script>

<template>
  <AuthIconCard icon="i-lucide-building-2">
    <h1 class="text-[26px] font-bold text-foreground mb-3">
      {{ t('LOGIN.SAML.TITLE') }}
    </h1>
    <p
      class="text-[14px] text-muted-foreground mb-8 px-2 leading-relaxed w-full"
    >
      {{ t('LOGIN.SAML.SUBTITLE') }}
    </p>

    <form
      class="w-full flex flex-col gap-5"
      method="POST"
      action="/api/v1/auth/saml_login"
    >
      <AuthInput
        v-model="credentials.email"
        name="email"
        type="email"
        :tabindex="1"
        required
        :label="t('LOGIN.SAML.WORK_EMAIL.LABEL')"
        :placeholder="t('LOGIN.SAML.WORK_EMAIL.PLACEHOLDER')"
        :has-error="v$.credentials.email.$error"
        :error-message="t('LOGIN.EMAIL.ERROR')"
        @input="v$.credentials.email.$touch"
      />
      <input
        type="hidden"
        class="h-0"
        name="authenticity_token"
        :value="csrfToken"
      />
      <input type="hidden" class="h-0" name="target" :value="target" />
      <button
        type="submit"
        :tabindex="2"
        :disabled="v$.credentials.email.$invalid"
        class="w-full h-11 mt-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg shadow-md hover:shadow-lg transition-all flex items-center justify-center gap-2 font-medium text-[15px] outline-none disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-primary disabled:hover:shadow-md"
      >
        {{ t('LOGIN.SAML.SUBMIT') }}
        <span class="i-lucide-arrow-right size-4" />
      </button>
    </form>

    <p class="text-center text-[14px] text-muted-foreground mt-8">
      <router-link
        to="/app/login"
        class="text-primary font-medium hover:underline"
      >
        {{ t('LOGIN.SAML.BACK_TO_LOGIN') }}
      </router-link>
    </p>
  </AuthIconCard>
</template>
