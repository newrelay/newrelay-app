<script setup>
import { computed, ref } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import SectionLayout from './SectionLayout.vue';

const { t } = useI18n();
const { currentAccount } = useAccount();
const isCopied = ref(false);

const getAccountId = computed(() => currentAccount.value?.id?.toString() || '');

const copyAccountId = async () => {
  await copyTextToClipboard(getAccountId.value);
  isCopied.value = true;
  useAlert(t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
  setTimeout(() => {
    isCopied.value = false;
  }, 2000);
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.DEVELOPER_SECTION.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.DEVELOPER_SECTION.NOTE')"
    as-card
  >
    <div class="flex flex-col gap-1.5">
      <label for="account-id" class="text-[13.5px] font-medium text-foreground">
        {{ t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.TITLE') }}
      </label>
      <div class="flex items-center gap-3">
        <RelayInput
          id="account-id"
          :model-value="getAccountId"
          readonly
          class-name="h-10 min-w-0 flex-1 shadow-xs"
        />
        <RelayButton
          type="button"
          variant="outline"
          size="lg"
          class="shrink-0"
          @click="copyAccountId"
        >
          <span
            :class="
              isCopied ? 'i-lucide-check size-3.5' : 'i-lucide-copy size-3.5'
            "
          />
          {{
            isCopied
              ? t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.COPIED')
              : t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.COPY')
          }}
        </RelayButton>
      </div>
      <p class="text-[13px] leading-relaxed text-muted-foreground">
        {{ t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.NOTE') }}
      </p>
    </div>
  </SectionLayout>
</template>
