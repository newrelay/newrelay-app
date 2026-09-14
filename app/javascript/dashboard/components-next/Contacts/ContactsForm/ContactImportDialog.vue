<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import {
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_CLOSE_BUTTON_CLASS,
} from 'dashboard/components-next/relay/modal/constants';

const emit = defineEmits(['import']);
const { t } = useI18n();

const uiFlags = useMapGetter('contacts/getUIFlags');
const isImportingContact = computed(() => uiFlags.value.isImporting);

const isOpen = ref(false);
const fileInput = ref(null);
const hasSelectedFile = ref(null);

const handleRemoveFile = () => {
  hasSelectedFile.value = null;
  if (fileInput.value) {
    fileInput.value.value = null;
  }
};

const dialogRef = {
  open: () => {
    isOpen.value = true;
  },
  close: () => {
    isOpen.value = false;
    handleRemoveFile();
  },
};

const handleFileClick = () => fileInput.value?.click();

const handleFileChange = () => {
  hasSelectedFile.value = fileInput.value?.files[0] || null;
};

const handleFileDrop = event => {
  const file = event.dataTransfer?.files?.[0];
  if (!file) return;
  hasSelectedFile.value = file;
};

const uploadFile = async () => {
  if (!hasSelectedFile.value) return;
  emit('import', hasSelectedFile.value);
};

defineExpose({ dialogRef });
</script>

<template>
  <TeleportWithDirection to="body">
    <div
      v-if="isOpen"
      class="flex items-center justify-center p-4 transition-all duration-300"
      :class="[RELAY_DIALOG_OVERLAY_CLASS]"
      @click.self="dialogRef.close()"
    >
      <div
        data-relay
        class="relative w-full max-w-md overflow-hidden rounded-xl border border-border bg-card shadow-2xl"
        @click.stop
      >
        <div class="p-6">
          <div class="mb-4 flex items-center justify-between">
            <h2 class="text-lg font-semibold tracking-tight text-foreground">
              {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.TITLE') }}
            </h2>
            <button
              type="button"
              :class="RELAY_MODAL_CLOSE_BUTTON_CLASS"
              @click="dialogRef.close()"
            >
              <span class="i-lucide-x size-4" />
            </button>
          </div>
          <p class="mb-6 text-sm text-muted-foreground">
            {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.DESCRIPTION') }}
          </p>

          <button
            type="button"
            class="flex w-full cursor-pointer flex-col items-center justify-center rounded-lg border-2 border-dashed border-muted-foreground/20 p-10 text-center transition-colors hover:bg-accent"
            @click="handleFileClick"
            @dragover.prevent
            @drop.prevent="handleFileDrop"
          >
            <span
              :class="
                hasSelectedFile
                  ? 'i-lucide-file-spreadsheet text-primary'
                  : 'i-lucide-upload text-muted-foreground'
              "
              class="mb-3 size-8"
            />
            <p class="mb-1 text-sm font-medium text-foreground">
              {{
                hasSelectedFile
                  ? hasSelectedFile.name
                  : t(
                      'CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.DROPZONE_TITLE'
                    )
              }}
            </p>
            <p class="text-xs text-muted-foreground">
              {{
                t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.DROPZONE_HINT')
              }}
            </p>
          </button>
          <input
            ref="fileInput"
            type="file"
            accept=".csv,text/csv"
            class="hidden"
            @change="handleFileChange"
          />
        </div>
        <div
          class="flex justify-end gap-2 border-t border-border bg-muted/50 p-4"
        >
          <RelayButton variant="outline" @click="dialogRef.close()">
            {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.CANCEL') }}
          </RelayButton>
          <RelayButton
            :disabled="isImportingContact || !hasSelectedFile"
            @click="uploadFile"
          >
            {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.IMPORT') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </TeleportWithDirection>
</template>
