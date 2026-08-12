<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['confirm']);

const { t } = useI18n();

const dialogRef = ref(null);
const targetPlan = ref('');
const retentionMonths = ref(null);
const isLoading = ref(false);

const description = computed(() => {
  return retentionMonths.value
    ? t('BILLING_SETTINGS.DOWNGRADE_WARNING.DESCRIPTION_WITH_LIMIT', {
        months: retentionMonths.value,
      })
    : t('BILLING_SETTINGS.DOWNGRADE_WARNING.DESCRIPTION_UNLIMITED');
});

const open = (plan, months) => {
  targetPlan.value = plan;
  retentionMonths.value = months;
  isLoading.value = false;
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

const setLoading = value => {
  isLoading.value = value;
};

const handleConfirm = () => {
  emit('confirm', targetPlan.value);
};

defineExpose({ open, close, setLoading });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    width="md"
    :title="
      $t('BILLING_SETTINGS.DOWNGRADE_WARNING.TITLE', { plan: targetPlan })
    "
    :description="description"
    :confirm-button-label="$t('BILLING_SETTINGS.DOWNGRADE_WARNING.CONFIRM')"
    :cancel-button-label="$t('BILLING_SETTINGS.DOWNGRADE_WARNING.CANCEL')"
    :is-loading="isLoading"
    @confirm="handleConfirm"
  />
</template>
