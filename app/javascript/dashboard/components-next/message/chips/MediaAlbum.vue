<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';
import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';
import { ATTACHMENT_TYPES } from '../constants';

const props = defineProps({
  attachments: {
    type: Array,
    required: true,
  },
});

const MAX_VISIBLE = 4;
const { t } = useI18n();
const { filteredCurrentChatAttachments } = useMessageContext();

const failedIds = ref(new Set());
const showGallery = ref(false);
const galleryAttachment = ref(null);

const count = computed(() => props.attachments.length);

const visibleAttachments = computed(() =>
  props.attachments.slice(0, MAX_VISIBLE)
);

const overflowCount = computed(() => Math.max(0, count.value - MAX_VISIBLE));

const albumClass = computed(() => {
  const n = Math.min(count.value, MAX_VISIBLE);
  if (n === 2) return 'grid-cols-2 h-[148px]';
  return 'grid-cols-2 grid-rows-2 h-[280px]';
});

const tileClass = index => {
  if (Math.min(count.value, MAX_VISIBLE) === 3 && index === 0) {
    return 'row-span-2';
  }
  return '';
};

const isVideo = attachment =>
  [ATTACHMENT_TYPES.VIDEO, ATTACHMENT_TYPES.IG_REEL].includes(
    attachment.fileType
  );

const markFailed = id => {
  failedIds.value = new Set(failedIds.value).add(id);
};

const openGallery = attachment => {
  galleryAttachment.value = attachment;
  showGallery.value = true;
};

const galleryList = computed(() => {
  const fromAlbum = useSnakeCase(props.attachments);
  if (Array.isArray(fromAlbum) && fromAlbum.length) return fromAlbum;
  return filteredCurrentChatAttachments.value;
});
</script>

<template>
  <div
    class="grid w-[280px] max-w-full gap-0.5 overflow-hidden rounded-xl"
    :class="albumClass"
  >
    <button
      v-for="(attachment, index) in visibleAttachments"
      :key="attachment.id"
      type="button"
      class="reset-base relative min-h-0 min-w-0 cursor-pointer overflow-hidden border-0 bg-muted p-0"
      :class="tileClass(index)"
      @click="openGallery(attachment)"
    >
      <div
        v-if="failedIds.has(attachment.id)"
        class="flex size-full items-center justify-center text-muted-foreground"
      >
        <span
          class="size-4"
          :class="
            isVideo(attachment) ? 'i-lucide-video-off' : 'i-lucide-image-off'
          "
        />
      </div>
      <video
        v-else-if="isVideo(attachment)"
        :src="attachment.dataUrl"
        class="size-full object-cover"
        muted
        playsinline
        preload="metadata"
        @error="markFailed(attachment.id)"
      />
      <img
        v-else
        :src="attachment.dataUrl"
        class="skip-context-menu size-full object-cover"
        alt=""
        @error="markFailed(attachment.id)"
      />
      <div
        v-if="isVideo(attachment) && !failedIds.has(attachment.id)"
        class="pointer-events-none absolute inset-0 flex items-center justify-center bg-foreground/10"
      >
        <div
          class="flex size-8 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-sm"
        >
          <span class="i-lucide-play ml-0.5 size-3.5" />
        </div>
      </div>
      <div
        v-if="overflowCount && index === visibleAttachments.length - 1"
        class="pointer-events-none absolute inset-0 flex items-center justify-center bg-foreground/55"
      >
        <span class="text-[20px] font-semibold text-primary-foreground">
          {{
            t('CONVERSATION_SIDEBAR.SHARED_FILES.MORE_COUNT', {
              count: overflowCount,
            })
          }}
        </span>
      </div>
    </button>
  </div>
  <GalleryView
    v-if="showGallery && galleryAttachment"
    v-model:show="showGallery"
    :attachment="useSnakeCase(galleryAttachment)"
    :all-attachments="galleryList"
    @close="() => (showGallery = false)"
  />
</template>
