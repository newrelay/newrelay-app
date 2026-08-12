<script setup>
import { ref, computed } from 'vue';

import microsoftClient from 'dashboard/api/channel/microsoftClient';
import googleClient from 'dashboard/api/channel/googleClient';
import SettingsSubPageHeader from '../../../SettingsSubPageHeader.vue';
import { RelayButton } from 'dashboard/components-next/relay';

import { useAlert } from 'dashboard/composables';

const props = defineProps({
  provider: {
    type: String,
    required: true,
    validate: value => ['microsoft', 'google'].includes(value),
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  submitButtonText: {
    type: String,
    required: true,
  },
  errorMessage: {
    type: String,
    required: true,
  },
});

const isRequestingAuthorization = ref(false);

const client = computed(() => {
  if (props.provider === 'microsoft') {
    return microsoftClient;
  }

  return googleClient;
});

async function requestAuthorization() {
  try {
    isRequestingAuthorization.value = true;
    const response = await client.value.generateAuthorization();
    const {
      data: { url },
    } = response;

    window.location.href = url;
  } catch (error) {
    useAlert(props.errorMessage);
  } finally {
    isRequestingAuthorization.value = false;
  }
}
</script>

<template>
  <div class="w-full max-w-2xl">
    <SettingsSubPageHeader
      :header-title="title"
      :header-content="description"
    />
    <form @submit.prevent="requestAuthorization">
      <RelayButton
        type="submit"
        class="shadow-sm"
        :disabled="isRequestingAuthorization"
      >
        {{ submitButtonText }}
      </RelayButton>
    </form>
  </div>
</template>
