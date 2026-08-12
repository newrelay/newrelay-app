<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['import']);
const { t } = useI18n();

const uiFlags = useMapGetter('contacts/getUIFlags');
const isImportingContact = computed(() => uiFlags.value.isImporting);

const dialogRef = ref(null);
const fileInput = ref(null);

const hasSelectedFile = ref(null);
const selectedFileName = ref('');

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

const handleRemoveFile = () => {
  hasSelectedFile.value = null;
  if (fileInput.value) {
    fileInput.value.value = null;
  }
  selectedFileName.value = '';
};

const uploadFile = async () => {
  if (!hasSelectedFile.value) return;
  emit('import', hasSelectedFile.value);
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.TITLE')"
    :confirm-button-label="
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.IMPORT')
    "
    :is-loading="isImportingContact"
    :disable-confirm-button="isImportingContact || !hasSelectedFile"
    @confirm="uploadFile"
  >
    <template #description>
      <p class="mb-0 text-sm text-muted-foreground">
        {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.DESCRIPTION') }}
      </p>
    </template>

    <div
      class="mt-4 flex flex-col items-center justify-center rounded-xl border-2 border-dashed border-border bg-card p-10 transition-colors hover:bg-muted/50 cursor-pointer"
      @click="handleFileClick"
      @dragover.prevent
      @drop.prevent="
        e => {
          if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
            hasSelectedFile = e.dataTransfer.files[0];
            selectedFileName = processFileName(hasSelectedFile.name);
            if (fileInput) fileInput.value = null;
          }
        }
      "
    >
      <div
        v-if="!hasSelectedFile"
        class="flex flex-col items-center gap-3 text-center"
      >
        <div class="rounded-full bg-muted/50 p-3">
          <span class="i-lucide-upload size-6 text-foreground" />
        </div>
        <div class="space-y-1">
          <p class="text-sm font-medium text-foreground">
            Click to upload or drag and drop
          </p>
          <p class="text-xs text-muted-foreground">CSV up to 10MB</p>
        </div>
      </div>

      <div v-else class="flex w-full items-center justify-between gap-4">
        <div class="flex items-center gap-3">
          <div class="rounded-lg border border-border bg-muted/50 p-2">
            <span class="i-lucide-file-spreadsheet size-5 text-primary" />
          </div>
          <div class="flex flex-col text-start">
            <span class="text-sm font-medium text-foreground">{{
              selectedFileName
            }}</span>
            <span class="text-xs text-muted-foreground">Ready to upload</span>
          </div>
        </div>
        <div class="flex items-center gap-1">
          <Button
            label="Change"
            color="slate"
            variant="ghost"
            size="sm"
            @click.stop="handleFileClick"
          />
          <div class="h-3 w-px bg-border mx-1" />
          <Button
            icon="i-lucide-trash"
            color="slate"
            variant="ghost"
            size="sm"
            @click.stop="handleRemoveFile"
          />
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
  </Dialog>
</template>
