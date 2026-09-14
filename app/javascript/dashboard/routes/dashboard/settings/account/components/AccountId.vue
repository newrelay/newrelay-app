<script setup>
import { computed, ref } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { RelayButton } from 'dashboard/components-next/relay';
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
    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-foreground">
        {{ t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.TITLE') }}
      </label>
      <div class="mt-1 flex w-full">
        <div
          class="flex h-10 min-w-0 flex-1 items-center rounded-l-md border border-border bg-background px-3 text-sm text-foreground shadow-xs"
        >
          {{ getAccountId }}
        </div>
        <RelayButton
          type="button"
          :variant="isCopied ? 'secondary' : 'outline'"
          class="h-10 shrink-0 rounded-l-none border-l-0 text-sm font-medium shadow-xs"
          :class="
            isCopied
              ? 'bg-accent text-foreground'
              : 'bg-background hover:bg-accent'
          "
          @click="copyAccountId"
        >
          <span class="i-lucide-copy size-3.5" />
          {{
            isCopied
              ? t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.COPIED')
              : t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.COPY')
          }}
        </RelayButton>
      </div>
      <p class="mt-1 text-[13px] leading-relaxed text-muted-foreground">
        {{ t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.NOTE') }}
      </p>
    </div>
  </SectionLayout>
</template>
