<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import { RelaySwitch } from 'dashboard/components-next/relay';

const { t } = useI18n();
const isEnabled = ref(false);

const { currentAccount, updateAccount } = useAccount();

watch(
  currentAccount,
  () => {
    const { audio_transcriptions } = currentAccount.value?.settings || {};
    isEnabled.value = !!audio_transcriptions;
  },
  { deep: true, immediate: true }
);

const updateAccountSettings = async settings => {
  try {
    await updateAccount(settings);
    useAlert(t('GENERAL_SETTINGS.FORM.AUDIO_TRANSCRIPTION.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.AUDIO_TRANSCRIPTION.API.ERROR'));
  }
};

const toggleAudioTranscription = async () => {
  return updateAccountSettings({
    audio_transcriptions: isEnabled.value,
  });
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.PREFERENCES_SECTION.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.PREFERENCES_SECTION.NOTE')"
    as-card
  >
    <div class="flex flex-row items-start justify-between gap-8">
      <div class="flex-1">
        <label class="block text-sm font-medium text-foreground">
          {{ t('GENERAL_SETTINGS.FORM.AUDIO_TRANSCRIPTION.TITLE') }}
        </label>
        <p class="mt-1 text-[13px] leading-relaxed text-muted-foreground">
          {{ t('GENERAL_SETTINGS.FORM.AUDIO_TRANSCRIPTION.NOTE') }}
        </p>
      </div>
      <div class="mt-1 shrink-0">
        <RelaySwitch
          v-model="isEnabled"
          @update:model-value="toggleAudioTranscription"
        />
      </div>
    </div>
  </SectionLayout>
</template>
