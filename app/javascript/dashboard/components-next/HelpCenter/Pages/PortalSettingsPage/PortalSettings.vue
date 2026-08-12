<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import PortalBaseSettings from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/PortalBaseSettings.vue';
import PortalConfigurationSettings from './PortalConfigurationSettings.vue';
import PortalLayoutContentSettings from './PortalLayoutContentSettings.vue';
import ConfirmDeletePortalDialog from 'dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/ConfirmDeletePortalDialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  portals: {
    type: Array,
    required: true,
  },
  isFetching: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits([
  'updatePortal',
  'updatePortalConfiguration',
  'deletePortal',
  'refreshStatus',
  'sendCnameInstructions',
]);

const { t } = useI18n();
const route = useRoute();

const confirmDeletePortalDialogRef = ref(null);
const baseSettingsRef = ref(null);
const experienceSettingsRef = ref(null);

const currentPortalSlug = computed(() => route.params.portalSlug);

const isSwitchingPortal = useMapGetter('portals/isSwitchingPortal');
const isFetchingSSLStatus = useMapGetter('portals/isFetchingSSLStatus');

const activePortal = computed(() => {
  return props.portals?.find(portal => portal.slug === currentPortalSlug.value);
});

const activePortalName = computed(() => activePortal.value?.name || '');

const isLoading = computed(() => props.isFetching || isSwitchingPortal.value);

const unwrap = value =>
  value && typeof value === 'object' && 'value' in value ? value.value : value;

const canSave = computed(() => {
  const base = baseSettingsRef.value;
  if (!base) return false;

  return (
    !unwrap(base.isInvalid) &&
    !unwrap(base.isUpdatingPortal) &&
    !props.isFetching
  );
});

const handleSaveChanges = () => {
  const base = baseSettingsRef.value;
  const experience = experienceSettingsRef.value;
  if (!base || !experience || unwrap(base.isInvalid)) return;

  // Base payload last so a renamed slug wins over the active portal slug.
  const payload = {
    ...experience.getPayload(),
    ...base.getPayload(),
  };

  emit('updatePortal', payload);
};

const handleUpdatePortalConfiguration = portal => {
  emit('updatePortalConfiguration', portal);
};

const fetchSSLStatus = () => {
  emit('refreshStatus');
};

const handleSendCnameInstructions = payload => {
  emit('sendCnameInstructions', payload);
};

const openConfirmDeletePortalDialog = () => {
  confirmDeletePortalDialogRef.value.dialogRef.open();
};

const handleDeletePortal = () => {
  emit('deletePortal', activePortal.value);
  confirmDeletePortalDialogRef.value.dialogRef.close();
};
</script>

<template>
  <HelpCenterLayout :show-pagination-footer="false">
    <template #content>
      <div
        v-if="isLoading"
        class="flex items-center justify-center py-10 text-muted-foreground"
      >
        <Spinner />
      </div>
      <div v-else-if="activePortal" class="flex w-full flex-col gap-8 pb-8">
        <PortalBaseSettings
          ref="baseSettingsRef"
          :active-portal="activePortal"
          :is-fetching="isFetching"
        >
          <template #custom-domain>
            <PortalConfigurationSettings
              :active-portal="activePortal"
              :is-fetching-status="isFetchingSSLStatus"
              @update-portal-configuration="handleUpdatePortalConfiguration"
              @refresh-status="fetchSSLStatus"
              @send-cname-instructions="handleSendCnameInstructions"
            />
          </template>
        </PortalBaseSettings>

        <PortalLayoutContentSettings
          ref="experienceSettingsRef"
          :active-portal="activePortal"
        />

        <div class="flex justify-end pt-2">
          <RelayButton
            class="h-9 px-6 shadow-sm"
            :disabled="!canSave"
            @click="handleSaveChanges"
          >
            {{ t('HELP_CENTER.PORTAL_SETTINGS.FORM.SAVE_CHANGES') }}
          </RelayButton>
        </div>

        <div
          class="mt-2 flex w-full flex-col items-start justify-between gap-6 rounded-2xl border border-border/40 bg-card p-6 shadow-sm sm:flex-row sm:items-center"
        >
          <div class="space-y-1.5">
            <h3 class="text-base font-medium text-foreground">
              {{
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.HEADER'
                )
              }}
            </h3>
            <p class="text-[14px] text-muted-foreground">
              {{
                t(
                  'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.DESCRIPTION'
                )
              }}
            </p>
          </div>
          <RelayButton
            variant="destructive"
            class="h-10 shrink-0 px-5 shadow-sm"
            @click="openConfirmDeletePortalDialog"
          >
            {{
              t(
                'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.BUTTON',
                {
                  portalName: activePortalName,
                }
              )
            }}
          </RelayButton>
        </div>
      </div>
    </template>
    <ConfirmDeletePortalDialog
      ref="confirmDeletePortalDialogRef"
      :active-portal-name="activePortalName"
      @delete-portal="handleDeletePortal"
    />
  </HelpCenterLayout>
</template>
