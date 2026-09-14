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

defineOptions({
  inheritAttrs: false,
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

const overflowCount = computed(() =>
  count.value > MAX_VISIBLE ? count.value - 3 : 0
);

const tileClass = index => {
  if (count.value === 2) return 'h-[86px]';
  if (count.value === 3 && index === 0) return 'col-span-2 h-[90px]';
  if (count.value === 3) return 'h-[72px]';
  return 'h-[78px]';
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
  <div class="flex w-full flex-col gap-1.5 overflow-hidden" v-bind="$attrs">
    <div class="grid grid-cols-2 gap-1 overflow-hidden rounded-lg">
      <button
        v-for="(attachment, index) in visibleAttachments"
        :key="attachment.id"
        type="button"
        class="reset-base group relative min-h-0 min-w-0 cursor-pointer overflow-hidden border-0 bg-muted/40 p-0"
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
          class="size-full object-cover transition-transform duration-300 group-hover:scale-105"
          muted
          playsinline
          preload="metadata"
          @error="markFailed(attachment.id)"
        />
        <img
          v-else
          :src="attachment.dataUrl"
          class="skip-context-menu size-full object-cover transition-transform duration-300 group-hover:scale-105"
          alt=""
          @error="markFailed(attachment.id)"
        />
        <div
          v-if="overflowCount && index === visibleAttachments.length - 1"
          class="absolute inset-0 flex flex-col items-center justify-center bg-background/80 text-foreground backdrop-blur-xs transition-colors group-hover:bg-background/90"
        >
          <span class="text-[15px] font-bold">
            {{
              t('CONVERSATION_SIDEBAR.SHARED_FILES.MORE_COUNT', {
                count: overflowCount,
              })
            }}
          </span>
          <span class="text-[10px] font-medium text-muted-foreground">
            {{ t('CONVERSATION_SIDEBAR.SHARED_FILES.MORE_IMAGES') }}
          </span>
        </div>
        <div
          v-else
          class="absolute inset-0 flex items-center justify-center bg-background/60 opacity-0 backdrop-blur-xs transition-opacity group-hover:opacity-100"
        >
          <span
            v-if="isVideo(attachment) && !failedIds.has(attachment.id)"
            class="flex size-8 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-sm"
          >
            <span class="i-lucide-play ml-0.5 size-3.5" />
          </span>
          <span
            v-else
            class="flex size-6 items-center justify-center rounded-full bg-background/90 text-foreground shadow-md"
          >
            <span class="i-lucide-maximize-2 size-3" />
          </span>
        </div>
      </button>
    </div>
    <div
      class="flex items-center justify-between border-t border-border/40 px-1 pt-1 text-[10.5px] text-muted-foreground"
    >
      <span class="flex items-center gap-1 font-medium">
        <span class="i-lucide-image size-3 text-primary" />
        {{
          t('CONVERSATION_SIDEBAR.SHARED_FILES.IMAGES_ATTACHED', {
            count: count,
          })
        }}
      </span>
      <button
        type="button"
        class="reset-base text-[11px] font-medium text-primary hover:underline"
        @click="openGallery(attachments[0])"
      >
        {{ t('CONVERSATION_SIDEBAR.SHARED_FILES.VIEW_ALL') }}
      </button>
    </div>
  </div>
  <GalleryView
    v-if="showGallery && galleryAttachment"
    v-model:show="showGallery"
    :attachment="useSnakeCase(galleryAttachment)"
    :all-attachments="galleryList"
    @close="() => (showGallery = false)"
  />
</template>
