<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import { RELAY_DIALOG_OVERLAY_CLASS } from 'dashboard/components-next/relay/modal/constants';

const emit = defineEmits(['import']);
const { t } = useI18n();

const uiFlags = useMapGetter('contacts/getUIFlags');
const isImportingContact = computed(() => uiFlags.value.isImporting);

const isOpen = ref(false);
const fileInput = ref(null);

const hasSelectedFile = ref(null);
const selectedFileName = ref('');

const handleRemoveFile = () => {
  hasSelectedFile.value = null;
  if (fileInput.value) {
    fileInput.value.value = null;
  }
  selectedFileName.value = '';
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

const processFileName = fileName => {
  const lastDotIndex = fileName.lastIndexOf('.');
  const extension = fileName.slice(lastDotIndex);
  const baseName = fileName.slice(0, lastDotIndex);

  return baseName.length > 20
    ? `${baseName.slice(0, 20)}...${extension}`
    : fileName;
};

const handleFileChange = () => {
  const file = fileInput.value?.files[0];
  hasSelectedFile.value = file;
  selectedFileName.value = file ? processFileName(file.name) : '';
};

const handleFileDrop = event => {
  const file = event.dataTransfer?.files?.[0];
  if (!file) return;

  hasSelectedFile.value = file;
  selectedFileName.value = processFileName(file.name);
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
      class="flex items-center justify-center p-4"
      :class="[RELAY_DIALOG_OVERLAY_CLASS]"
      @click.self="dialogRef.close()"
    >
      <div
        data-relay
        class="mx-4 flex w-full max-w-[480px] flex-col rounded-xl border border-border/80 bg-background p-6 shadow-xl"
        @click.stop
      >
        <div class="flex flex-col">
          <h2 class="text-[16px] font-medium text-foreground">
            {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.TITLE') }}
          </h2>
          <p class="mt-1 text-[14px] text-muted-foreground">
            {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.DESCRIPTION') }}
          </p>
        </div>

        <div
          class="mt-5 flex cursor-pointer flex-col items-center gap-3 rounded-xl border border-dashed border-border/80 bg-muted/10 p-10 transition-colors hover:bg-muted/30"
          @click="handleFileClick"
          @dragover.prevent
          @drop.prevent="handleFileDrop"
        >
          <template v-if="!hasSelectedFile">
            <span class="i-lucide-upload size-8 text-muted-foreground" />
            <div class="space-y-1 text-center">
              <p class="text-[14px] font-medium text-foreground">
                {{
                  t(
                    'CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.DROPZONE_TITLE'
                  )
                }}
              </p>
              <p class="text-[13px] text-muted-foreground">
                {{
                  t(
                    'CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.DROPZONE_HINT'
                  )
                }}
              </p>
            </div>
          </template>

          <div v-else class="flex w-full items-center justify-between gap-4">
            <div class="flex min-w-0 items-center gap-3">
              <span
                class="i-lucide-file-spreadsheet size-5 shrink-0 text-primary"
              />
              <div class="flex min-w-0 flex-col text-start">
                <span class="truncate text-[14px] font-medium text-foreground">
                  {{ selectedFileName }}
                </span>
                <span class="text-[13px] text-muted-foreground">
                  {{
                    t(
                      'CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.READY_TO_UPLOAD'
                    )
                  }}
                </span>
              </div>
            </div>
            <div class="flex shrink-0 items-center gap-2">
              <RelayButton
                type="button"
                variant="outline"
                size="sm"
                class="h-8 border-border text-[13px] hover:border-transparent"
                @click.stop="handleFileClick"
              >
                {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.CHANGE') }}
              </RelayButton>
              <RelayButton
                type="button"
                variant="outline"
                size="sm"
                class="h-8 border-border text-[13px] hover:border-transparent"
                @click.stop="handleRemoveFile"
              >
                <span class="i-lucide-trash size-3.5" />
              </RelayButton>
            </div>
          </div>
        </div>

        <input
          ref="fileInput"
          type="file"
          accept="text/csv"
          class="hidden"
          @change="handleFileChange"
        />

        <div class="mt-6 flex gap-3">
          <RelayButton
            type="button"
            variant="outline"
            class="h-10 flex-1 rounded-xl border border-border bg-background text-[14px] font-medium shadow-sm hover:border-transparent"
            @click="dialogRef.close()"
          >
            {{ t('DIALOG.BUTTONS.CANCEL') }}
          </RelayButton>
          <RelayButton
            type="button"
            class="h-10 flex-1 rounded-xl bg-primary text-[14px] font-medium text-primary-foreground shadow-sm hover:bg-primary/90"
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
