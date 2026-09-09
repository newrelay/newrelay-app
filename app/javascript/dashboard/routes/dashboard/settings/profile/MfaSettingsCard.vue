<script setup>
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { parseBoolean } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import { RELAY_FORM_LABEL_CLASS } from 'dashboard/components-next/relay/form/constants';

const router = useRouter();
const route = useRoute();
const { t } = useI18n();

const isMfaEnabled = () => parseBoolean(window.newrelayConfig?.isMfaEnabled);

const navigateToMfa = () => {
  if (!isMfaEnabled()) {
    useAlert(t('PROFILE_SETTINGS.FORM.SECURITY_SECTION.MFA_UNAVAILABLE'));
    return;
  }

  router.push({
    name: 'profile_settings_mfa',
    params: {
      accountId: route.params.accountId,
    },
  });
};
</script>

<template>
  <div
    class="flex flex-col gap-4 p-4 bg-muted/20 border border-border/60 rounded-xl mt-12"
  >
    <div class="flex flex-col gap-1.5 shrink-0">
      <label :class="RELAY_FORM_LABEL_CLASS">
        {{ $t('MFA_SETTINGS.TITLE') }}
      </label>
      <p class="text-[13px] text-muted-foreground leading-relaxed">
        {{ $t('MFA_SETTINGS.DESCRIPTION') }}
      </p>
    </div>
    <RelayButton
      type="button"
      variant="secondary"
      class="bg-primary/5 hover:bg-primary/10 border border-primary/20 text-primary font-medium whitespace-nowrap px-4 h-9 shadow-none shrink-0 self-start"
      @click="navigateToMfa"
    >
      <Icon icon="i-lucide-settings" class="size-3.5" />
      {{ $t('PROFILE_SETTINGS.FORM.SECURITY_SECTION.MFA_BUTTON') }}
    </RelayButton>
  </div>
</template>
