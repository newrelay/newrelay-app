<script setup>
import { useRouter, useRoute } from 'vue-router';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const router = useRouter();
const route = useRoute();

const navigateToMfa = () => {
  router.push({
    name: 'profile_settings_mfa',
    params: {
      accountId: route.params.accountId,
    },
  });
};
</script>

<template>
  <div class="bg-background rounded-xl p-4 border border-muted">
    <div class="flex flex-col xs:flex-row items-center justify-between gap-4">
      <div class="flex flex-col items-start gap-1.5">
        <div class="flex items-center gap-2">
          <Icon
            icon="i-lucide-lock-keyhole"
            class="size-4 text-muted-foreground flex-shrink-0"
          />
          <h5 class="text-heading-3 text-foreground">
            {{ $t('MFA_SETTINGS.TITLE') }}
          </h5>
        </div>
        <p class="text-body-para text-muted-foreground">
          {{ $t('MFA_SETTINGS.DESCRIPTION') }}
        </p>
      </div>
      <RelayButton
        type="button"
        variant="outline"
        class="flex-shrink-0"
        @click="navigateToMfa"
      >
        <Icon icon="i-lucide-settings" class="size-4" />
        {{ $t('PROFILE_SETTINGS.FORM.SECURITY_SECTION.MFA_BUTTON') }}
      </RelayButton>
    </div>
  </div>
</template>
