<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import AccountAPI from 'dashboard/api/account';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import SettingsLayout from '../SettingsLayout.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
  RelaySwitch,
} from 'dashboard/components-next/relay';

const store = useStore();
const { t } = useI18n();
const { accountId } = useAccount();
const { replaceInstallationName } = useBranding();

const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);
const getAccount = useMapGetter('accounts/getAccount');
const uiFlags = useMapGetter('accounts/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);
const isFetchingItem = computed(() => uiFlags.value.isFetchingItem);

const customDomain = ref('');
const activeAccount = computed(() => getAccount.value(accountId.value));

const isWhiteLabelEnabled = computed(() =>
  isFeatureEnabledonAccount.value(
    accountId.value,
    FEATURE_FLAGS.DISABLE_BRANDING
  )
);

const hasSavedDomain = computed(() => !!activeAccount.value?.custom_domain);

const normalizedDomain = computed(() =>
  (customDomain.value || '').trim().replace(/\.$/, '').toLowerCase()
);

const domainStatus = computed(
  () => activeAccount.value?.ssl_settings?.cf_status || 'not_configured'
);

const isDomainUnchanged = computed(
  () =>
    normalizedDomain.value ===
    (activeAccount.value?.custom_domain || '').toLowerCase()
);

const isVerified = computed(
  () => isDomainUnchanged.value && domainStatus.value === 'active'
);

const isPending = computed(
  () =>
    isDomainUnchanged.value &&
    ['pending_validation', 'pending_issuance', 'pending_deployment'].includes(
      domainStatus.value
    )
);

const cnameTarget = computed(() => {
  const hostURL =
    window.chatwootConfig?.hostURL || 'https://domains.newrelay.com';
  try {
    return new URL(hostURL).hostname;
  } catch (e) {
    return hostURL.replace(/^(https?:\/\/)/, '').replace(/\/$/, '');
  }
});

const txtVerificationRecord = computed(
  () => activeAccount.value?.ssl_settings?.cf_verification_body || ''
);

const txtVerificationName = computed(() => {
  if (!normalizedDomain.value) return '';
  return `_cf-custom-hostname.${normalizedDomain.value}`;
});

const serverIp = computed(() => activeAccount.value?.server_ip || '');

const routingRecordType = computed(() => {
  if (!serverIp.value) return 'A';
  return serverIp.value.includes(':') ? 'AAAA' : 'A';
});

const isRootDomain = computed(() => {
  if (!normalizedDomain.value) return false;
  const parts = normalizedDomain.value.split('.').filter(Boolean);
  return (
    parts.length <= 2 ||
    (parts.length === 3 &&
      ['co', 'com', 'org', 'net', 'edu', 'gov'].includes(parts[1]))
  );
});

// Option 2 shows once the domain is saved / pending, or as soon as CF returns
// the TXT token — matching the old branding helper once Verify has run.
const showTxtOption = computed(
  () =>
    !!normalizedDomain.value &&
    !isVerified.value &&
    (txtVerificationRecord.value || hasSavedDomain.value || isPending.value)
);

// Avoid rendering an empty bordered box (root domains have no CNAME option until TXT is ready).
const showDnsInstructions = computed(() => {
  if (!normalizedDomain.value || isVerified.value) return false;
  if (isRootDomain.value) return showTxtOption.value;
  return true;
});

const whiteLabelDescription = computed(() =>
  replaceInstallationName(
    t('BRANDING_SETTINGS.CUSTOM_DOMAIN.WHITE_LABEL.DESCRIPTION')
  )
);

const cnameRecordType = 'CNAME';
const txtRecordType = 'TXT';
const rootRecordName = '@';

const initFromAccount = () => {
  if (!activeAccount.value) return;
  customDomain.value = activeAccount.value.custom_domain || '';
};

watch(
  () => activeAccount.value?.custom_domain,
  () => {
    if (isUpdating.value) return;
    initFromAccount();
  },
  { immediate: true }
);

const saveErrorMessage = error => {
  const data = error?.response?.data;
  return (
    data?.message ||
    data?.error ||
    t('BRANDING_SETTINGS.CUSTOM_DOMAIN.SAVE_ERROR')
  );
};

const mergeAccountUpdate = data => {
  store.commit('accounts/EDIT_ACCOUNT', {
    ...activeAccount.value,
    ...data,
  });
};

const wait = ms =>
  new Promise(resolve => {
    setTimeout(resolve, ms);
  });

const refreshSslSettings = async (attempt = 0) => {
  // Cloudflare hostname create/check runs async; poll until TXT token arrives.
  if (activeAccount.value?.ssl_settings?.cf_verification_body) return;
  if (attempt >= 6) return;

  await wait(1500);
  await store.dispatch('accounts/get', { silent: true });
  await refreshSslSettings(attempt + 1);
};

const handleSave = async (isVerifyAction = false) => {
  try {
    const formData = new FormData();
    formData.append('custom_domain', normalizedDomain.value || '');
    if (isVerifyAction) formData.append('force_verify', 'true');

    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: true });
    const response = await AccountAPI.update(formData);
    mergeAccountUpdate(response.data);
    customDomain.value =
      response.data.custom_domain || normalizedDomain.value || '';
    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: false });

    useAlert(t('BRANDING_SETTINGS.CUSTOM_DOMAIN.SAVE_SUCCESS'));

    if (isVerifyAction && normalizedDomain.value) {
      refreshSslSettings();
    }
  } catch (error) {
    store.commit('accounts/SET_ACCOUNT_UI_FLAG', { isUpdating: false });
    useAlert(saveErrorMessage(error));
  }
};

const handleVerify = async event => {
  event?.preventDefault?.();
  event?.stopPropagation?.();
  await handleSave(true);
};

const handleRemove = async event => {
  event?.preventDefault?.();
  event?.stopPropagation?.();
  customDomain.value = '';
  await handleSave(false);
};
</script>

<template>
  <SettingsLayout :is-loading="isFetchingItem">
    <template #body>
      <div class="flex w-full max-w-3xl flex-col gap-8 ltr:mr-auto rtl:ml-auto">
        <SectionLayout
          as-card
          :title="$t('BRANDING_SETTINGS.CUSTOM_DOMAIN.EXPERIENCE_TITLE')"
          :description="
            $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.EXPERIENCE_DESCRIPTION')
          "
        >
          <div class="flex flex-col gap-8">
            <div class="flex max-w-xl flex-col gap-2">
              <RelayLabel html-for="custom-domain">
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.LABEL') }}
              </RelayLabel>
              <form class="flex items-center gap-3" @submit.prevent="handleVerify">
                <template v-if="!isVerified">
                  <RelayInput
                    id="custom-domain"
                    v-model="customDomain"
                    class-name="h-10 shadow-xs flex-1"
                    :placeholder="
                      $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.PLACEHOLDER')
                    "
                  />
                  <RelayButton
                    type="button"
                    variant="outline"
                    size="lg"
                    class="shrink-0 px-6 font-medium shadow-none"
                    :disabled="isUpdating || !normalizedDomain"
                    @click="handleVerify"
                  >
                    <span
                      v-if="isUpdating"
                      class="i-lucide-loader-2 size-4 animate-spin"
                    />
                    {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.VERIFY') }}
                  </RelayButton>
                  <RelayButton
                    v-if="hasSavedDomain"
                    type="button"
                    variant="outline"
                    size="lg"
                    class="shrink-0 px-6 font-medium shadow-none"
                    :disabled="isUpdating"
                    @click="handleRemove"
                  >
                    {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.REMOVE') }}
                  </RelayButton>
                </template>
                <template v-else>
                  <div
                    class="flex h-10 min-w-0 flex-1 items-center justify-between rounded-md border border-border bg-background px-3 text-sm shadow-xs"
                  >
                    <span class="truncate text-foreground">{{ customDomain }}</span>
                    <span
                      class="ml-2 inline-flex shrink-0 items-center gap-1 rounded-md border border-emerald-500/20 bg-emerald-500/10 px-2 py-0.5 text-[12px] font-medium text-emerald-600"
                    >
                      {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.VERIFIED') }}
                      <span class="i-lucide-check-circle-2 size-3" />
                    </span>
                  </div>
                  <RelayButton
                    type="button"
                    variant="outline"
                    size="lg"
                    class="shrink-0 px-6 font-medium shadow-none"
                    :disabled="isUpdating"
                    @click="handleRemove"
                  >
                    <span
                      v-if="isUpdating"
                      class="i-lucide-loader-2 size-4 animate-spin"
                    />
                    {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.REMOVE') }}
                  </RelayButton>
                </template>
              </form>

              <p
                v-if="!isVerified && normalizedDomain && isPending"
                class="text-sm font-semibold text-amber-500"
              >
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.PENDING') }}
              </p>
              <p
                v-else-if="!isVerified"
                class="text-[13px] leading-relaxed text-muted-foreground"
              >
                {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.AUTO_CONNECT_LABEL') }}
              </p>
            </div>

            <div
              v-if="showDnsInstructions"
              class="flex flex-col gap-5 rounded-xl border border-border bg-muted/40 p-4"
            >
              <div v-if="!isRootDomain" class="flex flex-col gap-3">
              <p class="text-xs font-semibold text-foreground">
              {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.OPTION_1_TITLE') }}
              </p>
              <p class="text-xs text-muted-foreground">
              {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.CNAME_INSTRUCTION') }}
              </p>
              <div
              class="grid grid-cols-[80px_1fr] gap-x-4 gap-y-2 rounded-lg border border-border bg-background p-3 text-xs"
              >
              <span class="text-muted-foreground">{{
                $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.TYPE')
              }}</span>
              <span class="font-mono font-semibold text-foreground">{{
                cnameRecordType
              }}</span>
              <span class="text-muted-foreground">{{
                $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.NAME')
              }}</span>
              <code
                class="select-all bg-transparent p-0 font-mono font-semibold text-foreground"
                >{{ normalizedDomain }}</code
              >
              <span class="text-muted-foreground">{{
                $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.TARGET')
              }}</span>
              <code
                class="select-all bg-transparent p-0 font-mono font-semibold text-foreground"
                >{{ cnameTarget }}</code
              >
              </div>
              </div>

              <hr v-if="showTxtOption && !isRootDomain" class="border-border" />

              <div v-if="showTxtOption" class="flex flex-col gap-3">
              <p class="text-xs font-semibold text-foreground">
              {{
                isRootDomain
                  ? $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.ROOT_RECORDS_TITLE')
                  : $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.OPTION_2_TITLE')
              }}
              </p>
              <p class="text-xs text-muted-foreground">
              {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.TXT_INSTRUCTION') }}
              </p>
              <div
              class="flex flex-col gap-3 rounded-lg border border-border bg-background p-3"
              >
              <div
                class="grid grid-cols-[80px_1fr] gap-x-4 gap-y-2 border-b border-border pb-3 text-xs"
                :class="{ 'border-b-0 pb-0': !serverIp }"
              >
                <span class="text-muted-foreground">{{
                  $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.TYPE')
                }}</span>
                <span class="font-mono font-semibold text-foreground">{{
                  txtRecordType
                }}</span>
                <span class="text-muted-foreground">{{
                  $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.NAME')
                }}</span>
                <code
                  class="select-all bg-transparent p-0 font-mono font-semibold text-foreground"
                  >{{ txtVerificationName }}</code
                >
                <span class="text-muted-foreground">{{
                  $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.VALUE')
                }}</span>
                <code
                  v-if="txtVerificationRecord"
                  class="select-all bg-transparent p-0 font-mono font-semibold text-foreground"
                  >{{ txtVerificationRecord }}</code
                >
                <span
                  v-else
                  class="inline-flex items-center gap-2 font-medium text-muted-foreground"
                >
                  <span class="i-lucide-loader-2 size-3.5 animate-spin" />
                  {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.PENDING') }}
                </span>
              </div>
              <div
                v-if="serverIp"
                class="grid grid-cols-[80px_1fr] gap-x-4 gap-y-2 pt-1 text-xs"
              >
                <span class="text-muted-foreground">{{
                  $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.TYPE')
                }}</span>
                <span class="font-mono font-semibold text-foreground">{{
                  routingRecordType
                }}</span>
                <span class="text-muted-foreground">{{
                  $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.NAME')
                }}</span>
                <code
                  class="select-all bg-transparent p-0 font-mono font-semibold text-foreground"
                  >{{ rootRecordName }}</code
                >
                <span class="text-muted-foreground">{{
                  $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.VALUE')
                }}</span>
                <code
                  class="select-all bg-transparent p-0 font-mono font-semibold text-foreground"
                  >{{ serverIp }}</code
                >
              </div>
              </div>
              </div>
            </div>

            <div class="flex flex-col gap-2">
              <div class="flex items-center justify-between">
                <RelayLabel>
                  {{ $t('BRANDING_SETTINGS.CUSTOM_DOMAIN.WHITE_LABEL.TITLE') }}
                </RelayLabel>
                <RelaySwitch :model-value="isWhiteLabelEnabled" disabled />
              </div>
              <p class="pr-12 text-[13px] leading-relaxed text-muted-foreground">
                {{ whiteLabelDescription }}
              </p>
            </div>
          </div>
        </SectionLayout>
      </div>
    </template>
  </SettingsLayout>
</template>
