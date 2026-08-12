<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  fingerprint: {
    type: String,
    default: '',
  },
  spEntityId: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const { accountId } = useAccount();

const acsUrl = computed(() => {
  const currentHost = window.location.origin;
  return `${currentHost}/omniauth/saml/callback?account_id=${accountId.value}`;
});

const allInfoItems = computed(() => [
  {
    key: 'ACS_URL',
    label: t('SECURITY_SETTINGS.SAML.ACS_URL.LABEL'),
    value: acsUrl.value,
    tooltip: t('SECURITY_SETTINGS.SAML.ACS_URL.TOOLTIP'),
    show: true,
  },
  {
    key: 'SP_ENTITY_ID',
    label: t('SECURITY_SETTINGS.SAML.SP_ENTITY_ID.LABEL'),
    value: props.spEntityId,
    tooltip: t('SECURITY_SETTINGS.SAML.SP_ENTITY_ID.TOOLTIP'),
    show: !!props.spEntityId,
  },
  {
    key: 'FINGERPRINT',
    label: t('SECURITY_SETTINGS.SAML.FINGERPRINT.LABEL'),
    value: props.fingerprint,
    tooltip: t('SECURITY_SETTINGS.SAML.FINGERPRINT.TOOLTIP'),
    show: !!props.fingerprint,
  },
]);

const visibleInfoItems = computed(() =>
  allInfoItems.value.filter(item => item.show)
);

const handleCopy = async text => {
  await copyTextToClipboard(text);
  useAlert(t('SECURITY_SETTINGS.SAML.COPY_SUCCESS'));
};
</script>

<template>
  <div>
    <h4
      class="mb-3 flex items-center gap-1.5 text-[13px] font-semibold text-foreground"
    >
      {{ t('SECURITY_SETTINGS.SAML.INFO_SECTION.TITLE') }}
      <i
        v-tooltip.top="t('SECURITY_SETTINGS.SAML.INFO_SECTION.TOOLTIP')"
        class="i-lucide-info size-3.5 cursor-help text-muted-foreground"
      />
    </h4>
    <div
      class="divide-y divide-border overflow-hidden rounded-lg border border-border bg-background"
    >
      <div
        v-for="item in visibleInfoItems"
        :key="item.key"
        class="flex flex-col justify-between gap-3 p-3 sm:flex-row sm:items-center"
      >
        <span
          class="flex w-[160px] shrink-0 items-center gap-1 text-[13px] text-muted-foreground"
        >
          {{ item.label }}
          <i
            v-tooltip.top="item.tooltip"
            class="i-lucide-info inline size-3.5 cursor-help"
          />
        </span>
        <div class="flex w-full items-center gap-3 sm:w-auto">
          <span
            class="max-w-[280px] truncate text-[13px] text-foreground lg:max-w-[400px]"
          >
            {{ item.value }}
          </span>
          <button
            type="button"
            class="shrink-0 p-1 text-muted-foreground transition-colors hover:text-foreground"
            :aria-label="t('SECURITY_SETTINGS.SAML.COPY')"
            @click="handleCopy(item.value)"
          >
            <Icon icon="i-lucide-copy" class="size-3.5" />
          </button>
        </div>
      </div>
      <slot name="footer" />
    </div>
  </div>
</template>
