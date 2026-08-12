<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';

import AddCustomDomainDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/AddCustomDomainDialog.vue';
import DNSConfigurationDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/DNSConfigurationDialog.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  activePortal: {
    type: Object,
    required: true,
  },
  isFetchingStatus: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits([
  'updatePortalConfiguration',
  'refreshStatus',
  'sendCnameInstructions',
]);

const SSL_STATUS = {
  LIVE: ['active', 'staging_active'],
  PENDING: [
    'provisioned',
    'pending',
    'initializing',
    'pending_validation',
    'pending_deployment',
    'pending_issuance',
    'holding_deployment',
    'holding_validation',
    'pending_expiration',
    'pending_cleanup',
    'pending_deletion',
    'staging_deployment',
    'backup_issued',
  ],
  ERROR: [
    'blocked',
    'inactive',
    'moved',
    'expired',
    'deleted',
    'timed_out_initializing',
    'timed_out_validation',
    'timed_out_issuance',
    'timed_out_deployment',
    'timed_out_deletion',
    'deactivating',
  ],
};

const { t } = useI18n();
const { isOnChatwootCloud } = useAccount();

const addCustomDomainDialogRef = ref(null);
const dnsConfigurationDialogRef = ref(null);
const updatedDomainAddress = ref('');

const customDomainAddress = computed(
  () => props.activePortal?.custom_domain || ''
);

const sslSettings = computed(() => props.activePortal?.ssl_settings || {});
const verificationErrors = computed(
  () => sslSettings.value.verification_errors || ''
);

const isLive = computed(() =>
  SSL_STATUS.LIVE.includes(sslSettings.value.status)
);
const isPending = computed(() =>
  SSL_STATUS.PENDING.includes(sslSettings.value.status)
);
const isError = computed(() =>
  SSL_STATUS.ERROR.includes(sslSettings.value.status)
);

const statusText = computed(() => {
  if (isLive.value)
    return t(
      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.STATUS.LIVE'
    );
  if (isPending.value)
    return t(
      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.STATUS.PENDING'
    );
  if (isError.value)
    return t(
      'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.STATUS.ERROR'
    );
  return '';
});

const statusColors = computed(() => {
  if (isLive.value) return 'text-emerald-600';
  if (isError.value) return 'text-destructive';
  return 'text-amber-600';
});

const updatePortalConfiguration = customDomain => {
  const portal = {
    id: props.activePortal?.id,
    custom_domain: customDomain,
  };
  emit('updatePortalConfiguration', portal);
  addCustomDomainDialogRef.value.dialogRef.close();
  if (customDomain) {
    updatedDomainAddress.value = customDomain;
    dnsConfigurationDialogRef.value.dialogRef.open();
  }
};

const closeDNSConfigurationDialog = () => {
  updatedDomainAddress.value = '';
  dnsConfigurationDialogRef.value.dialogRef.close();
};

const onClickRefreshSSLStatus = () => {
  emit('refreshStatus');
};

const onClickSend = email => {
  emit('sendCnameInstructions', {
    portalSlug: props.activePortal?.slug,
    email,
  });
};

const openDomainDialog = () => {
  addCustomDomainDialogRef.value.dialogRef.open();
};
</script>

<template>
  <div class="mt-4 rounded-xl border border-border bg-muted/10 p-5">
    <div class="flex flex-col items-start justify-between gap-4 sm:flex-row">
      <div class="flex-1 space-y-2">
        <h3 class="text-[14px] font-semibold text-foreground">
          {{
            t(
              'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.HEADER'
            )
          }}
        </h3>
        <p class="text-[13px] leading-relaxed text-muted-foreground">
          {{
            t(
              'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DESCRIPTION'
            )
          }}
        </p>

        <div
          v-if="customDomainAddress"
          class="mt-4 flex flex-wrap items-center gap-2"
        >
          <span class="text-[13px] font-medium text-foreground">
            {{
              t(
                'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.LABEL'
              )
            }}
          </span>
          <span class="text-[14px] font-semibold text-primary">
            {{ customDomainAddress }}
          </span>
          <span
            v-if="isLive || (!isOnChatwootCloud && customDomainAddress)"
            class="i-lucide-circle-check size-4 text-emerald-500"
            aria-hidden="true"
          />
          <span
            v-else-if="statusText && isOnChatwootCloud"
            v-tooltip="verificationErrors"
            class="text-[13px] font-medium"
            :class="statusColors"
          >
            {{ statusText }}
          </span>
        </div>
        <p v-if="customDomainAddress" class="text-[12px] text-muted-foreground">
          {{
            t(
              'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.STATUS_DESCRIPTION'
            )
          }}
        </p>
        <p v-else class="pt-2 text-[13px] text-muted-foreground">
          {{
            t(
              'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.NOT_SET'
            )
          }}
        </p>
      </div>

      <div class="flex shrink-0 items-center gap-1">
        <RelayButton
          v-if="customDomainAddress"
          variant="ghost"
          class="h-8 border border-border px-3 text-[13px] text-muted-foreground hover:border-transparent hover:text-foreground"
          @click="openDomainDialog"
        >
          <span class="i-lucide-pencil size-3.5" />
          {{
            t(
              'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.EDIT_BUTTON'
            )
          }}
        </RelayButton>
        <RelayButton
          v-else
          variant="ghost"
          class="h-8 border border-border px-3 text-[13px] text-muted-foreground hover:border-transparent hover:text-foreground"
          @click="openDomainDialog"
        >
          {{
            t(
              'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.ADD_BUTTON'
            )
          }}
        </RelayButton>
        <RelayButton
          v-if="isOnChatwootCloud && customDomainAddress"
          variant="ghost"
          size="icon"
          class="size-8 border border-border text-muted-foreground hover:border-transparent hover:text-foreground"
          :class="isFetchingStatus && 'animate-spin'"
          @click="onClickRefreshSSLStatus"
        >
          <span class="i-lucide-refresh-cw size-3.5" />
        </RelayButton>
      </div>
    </div>

    <AddCustomDomainDialog
      ref="addCustomDomainDialogRef"
      :mode="customDomainAddress ? 'edit' : 'add'"
      :custom-domain="customDomainAddress"
      @add-custom-domain="updatePortalConfiguration"
    />
    <DNSConfigurationDialog
      ref="dnsConfigurationDialogRef"
      :custom-domain="updatedDomainAddress || customDomainAddress"
      @close="closeDNSConfigurationDialog"
      @send="onClickSend"
    />
  </div>
</template>
