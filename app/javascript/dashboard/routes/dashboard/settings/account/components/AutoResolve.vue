<script setup>
import { h, ref, watch, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { RelayButton, RelaySwitch } from 'dashboard/components-next/relay';
import DurationInput from 'next/input/DurationInput.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';

const { t } = useI18n();
const duration = ref(0);
const unit = ref(DURATION_UNITS.MINUTES);
const message = ref('');
const labelToApply = ref({});
const ignoreWaiting = ref(false);
const isEnabled = ref(false);
const isSubmitting = ref(false);

const { currentAccount, updateAccount } = useAccount();

const labels = useMapGetter('labels/getLabels');

const labelOptions = computed(() =>
  labels.value?.length
    ? labels.value.map(label => ({
        id: label.title,
        name: label.title,
        icon: h('span', {
          class: `size-[12px] ring-1 ring-border ring-inset rounded-sm`,
          style: { backgroundColor: label.color },
        }),
      }))
    : []
);

const selectedLabelName = computed(() => {
  return labelToApply.value?.name ?? null;
});

watch(
  [currentAccount, labelOptions],
  () => {
    const {
      auto_resolve_after,
      auto_resolve_message,
      auto_resolve_ignore_waiting,
      auto_resolve_label,
    } = currentAccount.value?.settings || {};

    duration.value = auto_resolve_after;
    message.value = auto_resolve_message;
    ignoreWaiting.value = auto_resolve_ignore_waiting;
    labelToApply.value = labelOptions.value.find(
      option => option.name === auto_resolve_label
    );

    if (duration.value) {
      if (duration.value % (24 * 60) === 0) {
        unit.value = DURATION_UNITS.DAYS;
      } else if (duration.value % 60 === 0) {
        unit.value = DURATION_UNITS.HOURS;
      } else {
        unit.value = DURATION_UNITS.MINUTES;
      }
    }

    if (duration.value) {
      isEnabled.value = true;
    }
  },
  { deep: true, immediate: true }
);

const updateAccountSettings = async settings => {
  try {
    isSubmitting.value = true;
    await updateAccount(settings, { silent: true });
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.DURATION.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.DURATION.API.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const handleSubmit = async () => {
  if (duration.value < 10) {
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.DURATION.ERROR'));
    return Promise.resolve();
  }

  return updateAccountSettings({
    auto_resolve_after: duration.value,
    auto_resolve_message: message.value,
    auto_resolve_ignore_waiting: ignoreWaiting.value,
    auto_resolve_label: selectedLabelName.value,
  });
};

const handleDisable = async () => {
  duration.value = null;
  message.value = '';
  ignoreWaiting.value = false;
  labelToApply.value = {};

  return updateAccountSettings({
    auto_resolve_after: null,
    auto_resolve_message: '',
    auto_resolve_ignore_waiting: false,
    auto_resolve_label: null,
  });
};

const onEnabledChange = val => {
  isEnabled.value = val;
  if (!val) handleDisable();
};
</script>

<template>
  <div
    class="bg-card border-border/60 overflow-hidden rounded-xl border shadow-xs"
  >
    <div class="flex items-start justify-between gap-4 p-5 sm:p-6">
      <div>
        <h3 class="text-foreground text-[16px] font-semibold">
          {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.TITLE') }}
        </h3>
        <p class="text-muted-foreground mt-1.5 text-[13.5px] leading-relaxed">
          {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.NOTE') }}
        </p>
      </div>
      <div class="shrink-0 pt-0.5">
        <RelaySwitch
          :model-value="isEnabled"
          @update:model-value="onEnabledChange"
        />
      </div>
    </div>

    <div
      class="border-border/40 space-y-8 border-t bg-muted/5 p-5 transition-opacity duration-300 sm:p-6"
      :class="
        !isEnabled
          ? 'pointer-events-none select-none opacity-50 grayscale-[0.2]'
          : ''
      "
    >
      <form class="space-y-8" @submit.prevent="handleSubmit">
        <div class="space-y-2">
          <label class="text-foreground text-[14px] font-semibold">
            {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.DURATION.LABEL') }}
          </label>
          <DurationInput
            v-model="duration"
            v-model:unit="unit"
            :min="0"
            :max="1438560"
            :disabled="!isEnabled"
          />
          <p class="text-muted-foreground pt-1 text-[12.5px]">
            {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.DURATION.HELP') }}
          </p>
        </div>

        <div class="space-y-2">
          <label class="text-foreground text-[14px] font-semibold">
            {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.MESSAGE.LABEL') }}
          </label>
          <textarea
            v-model="message"
            :disabled="!isEnabled"
            rows="4"
            class="border-border/80 text-foreground placeholder:text-muted-foreground focus-visible:ring-primary/30 w-full resize-y rounded-md border bg-background p-3 text-[14px] shadow-xs focus-visible:outline-none focus-visible:ring-1 disabled:cursor-not-allowed disabled:opacity-50"
            :placeholder="
              t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.MESSAGE.PLACEHOLDER')
            "
          />
          <p class="text-muted-foreground pt-1 text-[12.5px]">
            {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.MESSAGE.HELP') }}
          </p>
        </div>

        <div class="space-y-4 pt-2">
          <label class="text-foreground text-[14px] font-semibold">
            {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.PREFERENCES') }}
          </label>

          <div class="flex items-center justify-between gap-4 py-1">
            <span class="text-foreground text-[14px] font-medium">
              {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.IGNORE_WAITING.LABEL') }}
            </span>
            <RelaySwitch v-model="ignoreWaiting" :disabled="!isEnabled" />
          </div>

          <div class="flex items-center justify-between gap-4 py-1">
            <span class="text-foreground text-[14px] font-medium">
              {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.LABEL.LABEL') }}
            </span>
            <SingleSelect
              v-model="labelToApply"
              :options="labelOptions"
              :placeholder="
                $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.LABEL.PLACEHOLDER')
              "
              placeholder-icon="i-lucide-chevron-down"
              placeholder-trailing-icon
              variant="faded"
              class="w-[180px]"
            />
          </div>
        </div>

        <div class="border-border/40 border-t pt-4">
          <RelayButton
            type="submit"
            class="h-9 px-5 font-medium shadow-xs"
            :disabled="isSubmitting || !isEnabled"
          >
            {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.UPDATE_BUTTON') }}
          </RelayButton>
        </div>
      </form>
    </div>
  </div>
</template>
