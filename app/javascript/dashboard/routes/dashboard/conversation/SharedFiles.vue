<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { formatBytes } from 'shared/helpers/FileHelper';
import {
  dynamicTime,
  formatDuration,
  shortTimestamp,
} from 'shared/helpers/timeHelper';
import { downloadFile } from '@chatwoot/utils';
import {
  ATTACHMENT_TYPES,
  MEDIA_TYPES,
  isSvgAttachment,
} from 'dashboard/components-next/message/constants';

import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';
import Icon from 'next/icon/Icon.vue';
import FileIcon from 'next/icon/FileIcon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  compact: {
    type: Boolean,
    default: false,
  },
});

const MEDIA_PEEK_LIMIT = 6;
const FILES_PEEK_LIMIT = 3;
const COMPACT_PEEK_LIMIT = 3;

const { t } = useI18n();

const allAttachments = useMapGetter('getSelectedChatAttachments');
const attachmentsLoaded = useMapGetter('getSelectedChatAttachmentsLoaded');

const sortedAttachments = computed(() =>
  [...allAttachments.value].sort(
    (a, b) => (b.created_at || 0) - (a.created_at || 0)
  )
);

const mediaAttachments = computed(() =>
  sortedAttachments.value.filter(
    a => MEDIA_TYPES.includes(a.file_type) && !isSvgAttachment(a)
  )
);

const fileAttachments = computed(() =>
  sortedAttachments.value.filter(
    a =>
      a.data_url && (!MEDIA_TYPES.includes(a.file_type) || isSvgAttachment(a))
  )
);

const showAllMedia = ref(false);
const showAllFiles = ref(false);

const mediaPeekLimit = computed(() =>
  props.compact ? COMPACT_PEEK_LIMIT : MEDIA_PEEK_LIMIT
);
const filesPeekLimit = computed(() =>
  props.compact ? COMPACT_PEEK_LIMIT : FILES_PEEK_LIMIT
);

const visibleMedia = computed(() =>
  showAllMedia.value
    ? mediaAttachments.value
    : mediaAttachments.value.slice(0, mediaPeekLimit.value)
);

const visibleFiles = computed(() =>
  showAllFiles.value
    ? fileAttachments.value
    : fileAttachments.value.slice(0, filesPeekLimit.value)
);

const mediaOverflow = computed(() => {
  const total = mediaAttachments.value.length;
  return total > MEDIA_PEEK_LIMIT ? total - (MEDIA_PEEK_LIMIT - 1) : 0;
});

const showGallery = ref(false);
const selectedAttachment = ref(null);
const downloadingId = ref(null);

const fileNameFromUrl = url => {
  if (!url) return '';
  const name = url.split('/').pop()?.split('?')[0];
  if (!name) return '';
  try {
    return decodeURIComponent(name);
  } catch {
    return name;
  }
};

const onDownloadFile = async attachment => {
  const { id, file_type: type, data_url: url, extension } = attachment;
  try {
    downloadingId.value = id;
    await downloadFile({ url, type, extension });
  } catch (error) {
    useAlert(t('CONVERSATION_SIDEBAR.SHARED_FILES.DOWNLOAD_ERROR'));
  } finally {
    downloadingId.value = null;
  }
};

const isVideoType = type =>
  [ATTACHMENT_TYPES.VIDEO, ATTACHMENT_TYPES.IG_REEL].includes(type);

const isAudioType = type => type === ATTACHMENT_TYPES.AUDIO;
const isPlayableType = type => isVideoType(type) || isAudioType(type);

const durations = ref({});

const onLoadedMetadata = (attachment, event) => {
  const seconds = event.target?.duration;
  if (Number.isFinite(seconds) && seconds > 0) {
    durations.value[attachment.id] = seconds;
  }
};

const displayDuration = attachment => {
  const seconds = durations.value[attachment.id];
  return seconds ? formatDuration(Math.round(seconds)) : '';
};

const isOverflowTile = index =>
  !showAllMedia.value &&
  mediaOverflow.value > 0 &&
  index === MEDIA_PEEK_LIMIT - 1;

const onTileActivate = (attachment, index) => {
  if (isOverflowTile(index)) {
    showAllMedia.value = true;
    return;
  }
  selectedAttachment.value = attachment;
  showGallery.value = true;
};

const failedThumbs = ref(new Set());
const failedPreviews = ref(new Set());

const imagePreviewSrc = ({
  id,
  file_type: type,
  thumb_url: thumbUrl,
  data_url: dataUrl,
}) => {
  const canUseThumb = thumbUrl && !failedThumbs.value.has(id);
  if (type === ATTACHMENT_TYPES.IMAGE) return canUseThumb ? thumbUrl : dataUrl;
  if (isVideoType(type)) return canUseThumb ? thumbUrl : null;
  return null;
};

const onPreviewError = ({
  id,
  file_type: type,
  thumb_url: thumbUrl,
  data_url: dataUrl,
}) => {
  const canRetryWithFull = thumbUrl && !failedThumbs.value.has(id) && dataUrl;
  if (
    canRetryWithFull &&
    (type === ATTACHMENT_TYPES.IMAGE || isVideoType(type))
  ) {
    failedThumbs.value.add(id);
    return;
  }
  failedPreviews.value.add(id);
};

const hasPreview = attachment =>
  !!imagePreviewSrc(attachment) && !failedPreviews.value.has(attachment.id);
const hasVideoPreview = attachment =>
  isVideoType(attachment.file_type) &&
  attachment.data_url &&
  !failedPreviews.value.has(attachment.id);

const fallbackIcon = type => {
  if (type === ATTACHMENT_TYPES.AUDIO) return 'i-lucide-music';
  if (isVideoType(type)) return 'i-lucide-video';
  return 'i-lucide-image';
};

const displayName = attachment =>
  fileNameFromUrl(attachment.data_url) ||
  t('CONVERSATION_SIDEBAR.SHARED_FILES.UNTITLED_FILE');

const displaySize = attachment => {
  if (attachment.file_size) return formatBytes(attachment.file_size);
  if (attachment.extension) return attachment.extension.toUpperCase();
  return '—';
};

const displayTime = attachment => {
  if (!attachment.created_at) return '';
  return shortTimestamp(dynamicTime(attachment.created_at), true);
};

const isPdfFile = attachment => attachment.extension?.toLowerCase() === 'pdf';
</script>

<template>
  <div :class="compact ? 'flex flex-col gap-2' : 'flex flex-col gap-5 p-2'">
    <div v-if="!attachmentsLoaded" class="flex justify-center p-3">
      <Spinner class="size-5" />
    </div>
    <div
      v-else-if="!mediaAttachments.length && !fileAttachments.length"
      class="flex flex-col items-center justify-center gap-2 py-3 text-muted-foreground"
    >
      <span
        class="i-lucide-paperclip opacity-40"
        :class="compact ? 'mb-2 size-4' : 'size-8 text-muted-foreground/50'"
      />
      <p :class="compact ? 'text-[11px]' : 'text-[13.5px] text-center'">
        {{ t('CONVERSATION_SIDEBAR.SHARED_FILES.EMPTY', 'No attachments yet') }}
      </p>
    </div>

    <template v-else-if="compact">
      <div
        v-if="fileAttachments.length"
        class="mt-1 flex max-h-52 flex-col gap-1.5 overflow-y-auto"
      >
        <div
          v-for="attachment in visibleFiles"
          :key="attachment.id"
          role="button"
          tabindex="0"
          class="flex cursor-pointer items-center gap-3 rounded-lg border border-border/50 bg-muted/30 p-2 transition-colors hover:bg-accent"
          @click="onDownloadFile(attachment)"
          @keydown.enter="onDownloadFile(attachment)"
        >
          <div
            class="flex size-8 shrink-0 items-center justify-center rounded-lg"
            :class="
              isPdfFile(attachment)
                ? 'bg-destructive/10 text-destructive'
                : 'bg-primary/10 text-primary'
            "
          >
            <span v-if="isPdfFile(attachment)" class="text-[9px] font-bold">
              {{ t('CONVERSATION_SIDEBAR.SHARED_FILES.PDF_LABEL') }}
            </span>
            <FileIcon
              v-else
              :file-type="attachment.extension?.toLowerCase() || ''"
              class="size-4"
            />
          </div>
          <div class="flex min-w-0 flex-1 flex-col">
            <span class="truncate text-[13px] font-medium text-foreground">
              {{ displayName(attachment) }}
            </span>
            <div
              class="mt-0.5 flex items-center gap-2 text-[10px] text-muted-foreground"
            >
              <span>{{ displaySize(attachment) }}</span>
              <template v-if="displayTime(attachment)">
                <span class="size-1 rounded-full bg-muted-foreground/30" />
                <span>{{ displayTime(attachment) }}</span>
              </template>
            </div>
          </div>
        </div>
        <button
          v-if="fileAttachments.length > filesPeekLimit"
          type="button"
          class="self-start text-[12px] font-medium text-primary"
          @click="showAllFiles = !showAllFiles"
        >
          {{
            showAllFiles
              ? t('CONVERSATION_SIDEBAR.SHARED_FILES.SHOW_LESS')
              : t('CONVERSATION_SIDEBAR.SHARED_FILES.VIEW_ALL')
          }}
        </button>
      </div>

      <div
        v-if="mediaAttachments.length"
        class="mt-1 flex max-h-52 flex-col gap-1.5 overflow-y-auto"
      >
        <div
          v-for="(attachment, index) in visibleMedia"
          :key="attachment.id"
          role="button"
          tabindex="0"
          class="flex cursor-pointer items-center gap-3 rounded-lg border border-border/50 bg-muted/30 p-2 transition-colors hover:bg-accent"
          @click="onTileActivate(attachment, index)"
          @keydown.enter="onTileActivate(attachment, index)"
        >
          <img
            v-if="hasPreview(attachment)"
            :src="imagePreviewSrc(attachment)"
            class="size-8 shrink-0 rounded-lg object-cover"
            alt=""
          />
          <div
            v-else
            class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
          >
            <Icon :icon="fallbackIcon(attachment.file_type)" class="size-4" />
          </div>
          <div class="flex min-w-0 flex-1 flex-col">
            <span class="truncate text-[13px] font-medium text-foreground">
              {{ displayName(attachment) }}
            </span>
            <div
              v-if="displayTime(attachment)"
              class="mt-0.5 text-[10px] text-muted-foreground"
            >
              {{ displayTime(attachment) }}
            </div>
          </div>
        </div>
        <button
          v-if="mediaAttachments.length > mediaPeekLimit"
          type="button"
          class="self-start text-[12px] font-medium text-primary"
          @click="showAllMedia = !showAllMedia"
        >
          {{
            showAllMedia
              ? t('CONVERSATION_SIDEBAR.SHARED_FILES.SHOW_LESS')
              : t('CONVERSATION_SIDEBAR.SHARED_FILES.VIEW_ALL')
          }}
        </button>
      </div>
    </template>

    <template v-else>
      <section v-if="mediaAttachments.length" class="flex flex-col gap-2.5">
        <header class="flex items-center justify-between px-0.5">
          <h4
            class="capitalize text-xs font-semibold tracking-wider uppercase text-muted-foreground"
          >
            {{ t('CONVERSATION_SIDEBAR.SHARED_FILES.MEDIA_HEADING') }}
            <span
              class="ms-1 font-medium tracking-normal normal-case text-muted-foreground"
            >
              {{ mediaAttachments.length }}
            </span>
          </h4>
          <NextButton
            v-if="mediaOverflow > 0"
            ghost
            slate
            xs
            trailing-icon
            :icon="
              showAllMedia ? 'i-lucide-chevron-up' : 'i-lucide-chevron-right'
            "
            :label="
              showAllMedia
                ? t('CONVERSATION_SIDEBAR.SHARED_FILES.SHOW_LESS')
                : t('CONVERSATION_SIDEBAR.SHARED_FILES.VIEW_ALL')
            "
            @click="showAllMedia = !showAllMedia"
          />
        </header>
        <div class="grid grid-cols-3 gap-2">
          <div
            v-for="(attachment, index) in visibleMedia"
            :key="attachment.id"
            role="button"
            tabindex="0"
            class="relative w-full overflow-hidden transition-all duration-200 rounded-lg cursor-pointer aspect-square bg-muted shadow-sm hover:shadow-md hover:-translate-y-px group focus:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            @click="onTileActivate(attachment, index)"
            @keydown.enter="onTileActivate(attachment, index)"
            @keydown.space.prevent="onTileActivate(attachment, index)"
          >
            <template v-if="!isOverflowTile(index)">
              <img
                v-if="hasPreview(attachment)"
                :src="imagePreviewSrc(attachment)"
                class="object-cover w-full h-full transition-transform duration-300 group-hover:scale-110"
                loading="lazy"
                :alt="fileNameFromUrl(attachment.data_url)"
                @error="onPreviewError(attachment)"
              />
              <video
                v-else-if="hasVideoPreview(attachment)"
                :src="`${attachment.data_url}#t=0.1`"
                preload="metadata"
                muted
                playsinline
                class="object-cover w-full h-full transition-transform duration-300 group-hover:scale-110 pointer-events-none"
                @loadedmetadata="onLoadedMetadata(attachment, $event)"
                @error="onPreviewError(attachment)"
              />
              <div
                v-else
                class="flex items-center justify-center w-full h-full bg-gradient-to-br from-muted to-muted"
              >
                <Icon
                  :icon="fallbackIcon(attachment.file_type)"
                  class="size-6 text-muted-foreground"
                />
              </div>

              <audio
                v-if="isAudioType(attachment.file_type) && attachment.data_url"
                :src="attachment.data_url"
                preload="metadata"
                class="hidden"
                @loadedmetadata="onLoadedMetadata(attachment, $event)"
              />

              <div
                class="absolute inset-0 transition-opacity duration-200 opacity-0 pointer-events-none group-hover:opacity-100 bg-gradient-to-t from-black/40 via-transparent to-transparent"
              />

              <div
                v-if="hasVideoPreview(attachment)"
                class="absolute inset-0 flex items-center justify-center pointer-events-none bg-gradient-to-t from-black/30 via-transparent to-transparent"
              >
                <div
                  class="flex items-center justify-center rounded-full size-7 bg-white/95 shadow-md"
                >
                  <Icon
                    icon="i-lucide-play"
                    class="ms-0.5 size-3.5 text-black"
                  />
                </div>
              </div>

              <span
                v-if="
                  isPlayableType(attachment.file_type) &&
                  displayDuration(attachment)
                "
                class="absolute text-xxs font-medium tabular-nums transition-opacity bottom-1.5 ltr:right-1.5 rtl:left-1.5 text-white [text-shadow:_0_1px_3px_rgba(0,0,0,0.95),_0_0_10px_rgba(0,0,0,0.7)] group-hover:opacity-0"
              >
                {{ displayDuration(attachment) }}
              </span>

              <span
                v-if="displayTime(attachment)"
                class="absolute text-xxs font-medium transition-opacity opacity-0 bottom-1.5 ltr:left-1.5 rtl:right-1.5 text-white [text-shadow:_0_1px_3px_rgba(0,0,0,0.95),_0_0_10px_rgba(0,0,0,0.7)] group-hover:opacity-100"
              >
                {{ displayTime(attachment) }}
              </span>

              <button
                type="button"
                class="absolute flex items-center justify-center !p-px transition-all rounded-full opacity-0 bottom-1.5 ltr:right-1.5 rtl:left-1.5 size-6 bg-white/95 shadow-md group-hover:opacity-100 hover:bg-white disabled:opacity-50"
                :disabled="downloadingId === attachment.id"
                :aria-label="t('CONVERSATION_SIDEBAR.SHARED_FILES.DOWNLOAD')"
                @click.stop="onDownloadFile(attachment)"
                @keydown.enter.stop
                @keydown.space.stop
              >
                <Icon icon="i-lucide-download" class="size-3 text-black" />
              </button>
            </template>

            <div
              v-if="isOverflowTile(index)"
              class="absolute inset-0 flex items-center justify-center bg-accent"
            >
              <span class="text-base font-semibold text-foreground">
                {{
                  t('CONVERSATION_SIDEBAR.SHARED_FILES.MORE_COUNT', {
                    count: mediaOverflow,
                  })
                }}
              </span>
            </div>
          </div>
        </div>
      </section>

      <section v-if="fileAttachments.length" class="flex flex-col gap-2.5">
        <header class="flex items-center justify-between px-0.5">
          <h4
            class="capitalize text-xs font-semibold tracking-wider uppercase text-muted-foreground"
          >
            {{ t('CONVERSATION_SIDEBAR.SHARED_FILES.FILES_HEADING') }}
            <span
              class="ms-1 font-medium tracking-normal normal-case text-muted-foreground"
            >
              {{ fileAttachments.length }}
            </span>
          </h4>
          <NextButton
            v-if="fileAttachments.length > FILES_PEEK_LIMIT"
            ghost
            slate
            xs
            trailing-icon
            :icon="
              showAllFiles ? 'i-lucide-chevron-up' : 'i-lucide-chevron-right'
            "
            :label="
              showAllFiles
                ? t('CONVERSATION_SIDEBAR.SHARED_FILES.SHOW_LESS')
                : t('CONVERSATION_SIDEBAR.SHARED_FILES.VIEW_ALL')
            "
            @click="showAllFiles = !showAllFiles"
          />
        </header>
        <ul class="flex list-none flex-col gap-2">
          <li
            v-for="attachment in visibleFiles"
            :key="attachment.id"
            class="group flex items-center gap-3 rounded-lg border border-border/50 bg-muted/30 p-2 transition-colors hover:bg-accent"
          >
            <div
              class="flex size-8 shrink-0 items-center justify-center rounded-lg"
              :class="
                isPdfFile(attachment)
                  ? 'bg-destructive/10 text-destructive'
                  : 'bg-primary/10 text-primary'
              "
            >
              <span v-if="isPdfFile(attachment)" class="text-[9px] font-bold">
                {{ t('CONVERSATION_SIDEBAR.SHARED_FILES.PDF_LABEL') }}
              </span>
              <FileIcon
                v-else
                :file-type="attachment.extension?.toLowerCase() || ''"
                class="size-4"
              />
            </div>
            <a
              :href="attachment.data_url"
              target="_blank"
              rel="noopener noreferrer"
              class="min-w-0 flex-1 no-underline"
              :title="displayName(attachment)"
            >
              <span
                class="block truncate text-[13px] font-medium text-foreground"
              >
                {{ displayName(attachment) }}
              </span>
              <span
                class="mt-0.5 flex items-center gap-2 text-[10px] text-muted-foreground"
              >
                <span>{{ displaySize(attachment) }}</span>
                <template v-if="displayTime(attachment)">
                  <span class="size-1 rounded-full bg-muted-foreground/30" />
                  <span>{{ displayTime(attachment) }}</span>
                </template>
              </span>
            </a>
            <NextButton
              ghost
              slate
              sm
              icon="i-lucide-download"
              class="opacity-0 group-hover:opacity-100"
              :is-loading="downloadingId === attachment.id"
              :aria-label="t('CONVERSATION_SIDEBAR.SHARED_FILES.DOWNLOAD')"
              @click="onDownloadFile(attachment)"
            />
          </li>
        </ul>
      </section>

      <GalleryView
        v-if="showGallery && selectedAttachment"
        v-model:show="showGallery"
        :attachment="selectedAttachment"
        :all-attachments="mediaAttachments"
        auto-play
        @close="showGallery = false"
      />
    </template>
  </div>
</template>
