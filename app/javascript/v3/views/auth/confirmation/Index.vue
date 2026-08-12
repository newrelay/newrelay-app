<script setup>
import { onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { verifyPasswordToken } from '../../../api/auth';
import AuthShell from '../../../components/auth/AuthShell.vue';
import Spinner from 'shared/components/Spinner.vue';

const props = defineProps({
  confirmationToken: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

onMounted(async () => {
  try {
    await verifyPasswordToken({
      confirmationToken: props.confirmationToken,
    });
    window.location = DEFAULT_REDIRECT_URL;
  } catch {
    window.location = DEFAULT_REDIRECT_URL;
  }
});
</script>

<template>
  <AuthShell>
    <div class="flex items-center justify-center relative z-10">
      <Spinner color-scheme="primary" size="" />
      <div class="ml-2 text-muted-foreground">{{ t('CONFIRM_EMAIL') }}</div>
    </div>
  </AuthShell>
</template>
