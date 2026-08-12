<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { RelayButton } from 'dashboard/components-next/relay';

defineProps({
  open: { type: Boolean, default: false },
});

const emit = defineEmits(['update:open']);
const { t } = useI18n();
const fileInput = ref(null);

const close = () => emit('update:open', false);

const onUploadClick = () => {
  useAlert(t('COMPANIES.IMPORT.UNAVAILABLE'));
};
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      data-relay
      class="fixed inset-0 z-50 flex items-center justify-center bg-background/80 backdrop-blur-sm transition-all duration-300"
      @click.self="close"
    >
      <div
        class="relative w-full max-w-md overflow-hidden rounded-xl border border-border bg-card shadow-2xl"
      >
        <div class="p-6">
          <div class="mb-4 flex items-center justify-between">
            <h2 class="text-lg font-semibold tracking-tight text-foreground">
              {{ t('COMPANIES.IMPORT.TITLE') }}
            </h2>
            <RelayButton
              variant="ghost"
              size="icon"
              class="size-8 text-muted-foreground hover:text-foreground"
              @click="close"
            >
              <span class="i-lucide-x size-4" />
            </RelayButton>
          </div>
          <p class="mb-6 text-sm text-muted-foreground">
            {{ t('COMPANIES.IMPORT.DESCRIPTION') }}
          </p>

          <button
            type="button"
            class="flex w-full cursor-pointer flex-col items-center justify-center rounded-lg border-2 border-dashed border-muted-foreground/20 p-10 text-center transition-colors hover:bg-muted/50"
            @click="onUploadClick"
          >
            <span class="i-lucide-upload mb-3 size-8 text-muted-foreground" />
            <p class="mb-1 text-sm font-medium text-foreground">
              {{ t('COMPANIES.IMPORT.DROPZONE_TITLE') }}
            </p>
            <p class="text-xs text-muted-foreground">
              {{ t('COMPANIES.IMPORT.DROPZONE_HINT') }}
            </p>
          </button>
          <input
            ref="fileInput"
            type="file"
            class="hidden"
            accept=".csv,.xlsx,.xls"
          />
        </div>
        <div
          class="flex justify-end gap-2 border-t border-border bg-muted/50 p-4"
        >
          <RelayButton variant="outline" @click="close">
            {{ t('COMPANIES.IMPORT.CANCEL') }}
          </RelayButton>
          <RelayButton disabled>
            {{ t('COMPANIES.IMPORT.UPLOAD') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </Teleport>
</template>
