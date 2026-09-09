<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { downloadFile } from '@chatwoot/utils';
import { formatBytes } from 'shared/helpers/FileHelper';
import { RelayButton } from 'dashboard/components-next/relay';
import { RELAY_DIALOG_OVERLAY_CLASS } from 'dashboard/components-next/relay/modal/constants';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
  allAttachments: {
    type: Array,
    required: true,
  },
  autoPlay: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close']);
const show = defineModel('show', { type: Boolean, default: false });

const { t } = useI18n();

const ALLOWED_FILE_TYPES = {
  IMAGE: 'image',
  VIDEO: 'video',
  IG_REEL: 'ig_reel',
  AUDIO: 'audio',
};

const isDownloading = ref(false);
const activeAttachment = ref({});
const activeFileType = ref('');
const activeImageIndex = ref(
  (() => {
    const byId = props.allAttachments.findIndex(
      attachment => attachment.id === props.attachment.id
    );
    if (byId >= 0) return byId;
    const byMessage = props.allAttachments.findIndex(
      attachment => attachment.message_id === props.attachment.message_id
    );
    return byMessage >= 0 ? byMessage : 0;
  })()
);

const hasMoreThanOneAttachment = computed(
  () => props.allAttachments.length > 1
);

const showDots = computed(
  () => hasMoreThanOneAttachment.value && props.allAttachments.length <= 16
);

const isImage = computed(
  () => activeFileType.value === ALLOWED_FILE_TYPES.IMAGE
);
const isVideo = computed(() =>
  [ALLOWED_FILE_TYPES.VIDEO, ALLOWED_FILE_TYPES.IG_REEL].includes(
    activeFileType.value
  )
);
const isAudio = computed(
  () => activeFileType.value === ALLOWED_FILE_TYPES.AUDIO
);

const fileNameFromDataUrl = computed(() => {
  const { data_url: dataUrl } = activeAttachment.value;
  if (!dataUrl) return t('GALLERY_VIEW.SHARED_IMAGE');

  const fileName = dataUrl.split('/').pop();
  return fileName
    ? decodeURIComponent(fileName)
    : t('GALLERY_VIEW.SHARED_IMAGE');
});

const fileSizeLabel = computed(() => {
  const size =
    activeAttachment.value.file_size ?? activeAttachment.value.fileSize;
  if (size == null || size === '') return '';
  return formatBytes(size);
});

const metaDot = '\u2022';

const onClose = () => emit('close');

const setImageAndVideoSrc = attachment => {
  const { file_type: type } = attachment;
  if (!Object.values(ALLOWED_FILE_TYPES).includes(type)) return;

  activeAttachment.value = attachment;
  activeFileType.value = type;
};

const onClickChangeAttachment = (attachment, index) => {
  if (!attachment) return;

  activeImageIndex.value = index;
  setImageAndVideoSrc(attachment);
};

const stepAttachment = delta => {
  const total = props.allAttachments.length;
  if (total <= 1) return;
  const nextIndex = (activeImageIndex.value + delta + total) % total;
  onClickChangeAttachment(props.allAttachments[nextIndex], nextIndex);
};

const onClickDownload = async () => {
  const { file_type: type, data_url: url, extension } = activeAttachment.value;
  if (!Object.values(ALLOWED_FILE_TYPES).includes(type)) return;

  try {
    isDownloading.value = true;
    await downloadFile({ url, type, extension });
  } catch {
    useAlert(t('GALLERY_VIEW.ERROR_DOWNLOADING'));
  } finally {
    isDownloading.value = false;
  }
};

const keyboardEvents = {
  Escape: { action: onClose },
  ArrowLeft: {
    action: () => stepAttachment(-1),
  },
  ArrowRight: {
    action: () => stepAttachment(1),
  },
};

useKeyboardEvents(keyboardEvents);

onMounted(() => {
  setImageAndVideoSrc(props.attachment);
});

watch(
  () => props.attachment?.id,
  () => {
    setImageAndVideoSrc(props.attachment);
  }
);
</script>

<template>
  <TeleportWithDirection to="body">
    <template v-if="show">
      <div
        class="!z-[250]"
        :class="[RELAY_DIALOG_OVERLAY_CLASS]"
        role="presentation"
        @click="onClose"
      />
      <div
        class="fixed left-1/2 top-1/2 z-[250] flex max-h-[90vh] w-full max-w-4xl -translate-x-1/2 -translate-y-1/2 flex-col overflow-hidden rounded-2xl border border-border bg-card shadow-2xl"
        role="dialog"
        aria-modal="true"
        @click.stop
      >
        <header
          class="flex items-center justify-between border-b border-border bg-card px-6 py-4"
        >
          <div class="flex min-w-0 items-center gap-3">
            <div
              class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
            >
              <span class="i-lucide-image size-4" />
            </div>
            <div class="flex min-w-0 flex-col">
              <h3 class="m-0 truncate text-[14px] font-medium text-foreground">
                {{ fileNameFromDataUrl }}
              </h3>
              <p
                class="m-0 flex items-center gap-2 text-[11px] text-muted-foreground"
              >
                <span
                  v-if="hasMoreThanOneAttachment"
                  class="font-medium text-primary"
                >
                  {{
                    t('GALLERY_VIEW.IMAGE_OF', {
                      current: activeImageIndex + 1,
                      total: allAttachments.length,
                    })
                  }}
                </span>
                <span v-if="hasMoreThanOneAttachment && fileSizeLabel">
                  {{ metaDot }}
                </span>
                <span v-if="fileSizeLabel">{{ fileSizeLabel }}</span>
              </p>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <RelayButton
              variant="outline"
              size="sm"
              class="h-8 gap-1.5 px-3 text-[12px] font-medium shadow-xs"
              :disabled="isDownloading"
              @click="onClickDownload"
            >
              <span class="i-lucide-download size-3.5" />
              {{ t('CONVERSATION.DOWNLOAD') }}
            </RelayButton>
            <RelayButton
              variant="ghost"
              size="icon"
              class="size-8 text-muted-foreground hover:text-foreground"
              :aria-label="t('CONVERSATION.HEADER.CLOSE')"
              @click="onClose"
            >
              <span class="i-lucide-x size-4" />
            </RelayButton>
          </div>
        </header>

        <div
          class="relative flex min-h-[360px] flex-1 items-center justify-center overflow-hidden bg-muted/15 p-4 dark:bg-muted/10 sm:p-8"
        >
          <button
            v-if="hasMoreThanOneAttachment"
            type="button"
            class="reset-base absolute left-4 z-10 flex size-10 cursor-pointer items-center justify-center rounded-full border border-border/80 bg-background/90 text-foreground shadow-lg transition-all hover:scale-105 hover:bg-background"
            :aria-label="t('GALLERY_VIEW.PREVIOUS')"
            @click="stepAttachment(-1)"
          >
            <span class="i-lucide-chevron-left size-5 rtl:rotate-180" />
          </button>

          <img
            v-if="isImage"
            :key="activeAttachment.id || activeAttachment.data_url"
            :src="activeAttachment.data_url"
            :alt="fileNameFromDataUrl"
            class="max-h-[70vh] max-w-full rounded-lg border border-border/40 object-contain shadow-md"
          />

          <video
            v-else-if="isVideo"
            :key="activeAttachment.id || activeAttachment.data_url"
            :src="activeAttachment.data_url"
            controls
            playsInline
            :autoplay="autoPlay"
            class="max-h-[70vh] max-w-full rounded-lg object-contain"
          />

          <audio
            v-else-if="isAudio"
            :key="activeAttachment.id || activeAttachment.data_url"
            controls
            :autoplay="autoPlay"
            class="w-full max-w-md"
          >
            <source :src="`${activeAttachment.data_url}?t=${Date.now()}`" />
          </audio>

          <button
            v-if="hasMoreThanOneAttachment"
            type="button"
            class="reset-base absolute right-4 z-10 flex size-10 cursor-pointer items-center justify-center rounded-full border border-border/80 bg-background/90 text-foreground shadow-lg transition-all hover:scale-105 hover:bg-background"
            :aria-label="t('GALLERY_VIEW.NEXT')"
            @click="stepAttachment(1)"
          >
            <span class="i-lucide-chevron-right size-5 rtl:rotate-180" />
          </button>

          <div
            v-if="showDots"
            class="absolute bottom-3 left-1/2 flex -translate-x-1/2 items-center gap-1.5 rounded-full border border-border bg-background/90 px-3 py-1.5 shadow-md backdrop-blur-sm"
          >
            <button
              v-for="(item, idx) in allAttachments"
              :key="item.id || idx"
              type="button"
              class="reset-base size-2 rounded-full p-0 transition-all"
              :class="
                activeImageIndex === idx
                  ? 'scale-125 bg-primary ring-2 ring-primary/30'
                  : 'bg-muted-foreground/30 hover:bg-muted-foreground/70'
              "
              :aria-label="
                t('GALLERY_VIEW.IMAGE_OF', {
                  current: idx + 1,
                  total: allAttachments.length,
                })
              "
              @click="onClickChangeAttachment(item, idx)"
            />
          </div>
        </div>
      </div>
    </template>
  </TeleportWithDirection>
</template>
