<script setup>
import { computed, useAttrs } from 'vue';
import format from 'date-fns/format';
import fromUnixTime from 'date-fns/fromUnixTime';

import MessageMeta from '../MessageMeta.vue';

import { emitter } from 'shared/helpers/mitt';
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { MESSAGE_VARIANTS, ORIENTATION } from '../constants';

const props = defineProps({
  hideMeta: { type: Boolean, default: false },
});

defineOptions({ inheritAttrs: false });

const attrs = useAttrs();
const {
  variant,
  inReplyTo,
  shouldGroupWithNext,
  orientation,
  isInboxView,
  sender,
  createdAt,
} = useMessageContext();
const { t } = useI18n();

const isPrivateNote = computed(
  () => variant.value === MESSAGE_VARIANTS.PRIVATE
);

// Colored fill lives ONLY on the inner surface (never the meta wrapper).
// Agent/bot/template text: solid primary + white. Media/email override via attrs.
const maxWidthClass = computed(() =>
  isInboxView?.value ? 'max-w-full' : 'max-w-[85%]'
);

const varaintBaseMap = computed(() => ({
  [MESSAGE_VARIANTS.AGENT]: `bg-primary text-primary-foreground shadow-xs border-transparent w-fit ${maxWidthClass.value}`,
  [MESSAGE_VARIANTS.PRIVATE]: '',
  [MESSAGE_VARIANTS.USER]: `bg-card border border-border shadow-xs text-foreground w-fit ${maxWidthClass.value}`,
  [MESSAGE_VARIANTS.ACTIVITY]:
    'bg-muted/50 text-muted-foreground text-sm w-full',
  [MESSAGE_VARIANTS.BOT]: `bg-primary text-primary-foreground shadow-xs border-transparent w-fit ${maxWidthClass.value}`,
  [MESSAGE_VARIANTS.TEMPLATE]: `bg-card border border-border shadow-xs text-foreground w-fit ${maxWidthClass.value}`,
  [MESSAGE_VARIANTS.ERROR]: `bg-destructive/10 text-destructive border border-destructive/20 w-fit ${maxWidthClass.value}`,
  [MESSAGE_VARIANTS.EMAIL]: `w-fit ${maxWidthClass.value}`,
  [MESSAGE_VARIANTS.UNSUPPORTED]: `bg-warning/10 border border-dashed border-warning/50 text-warning w-fit ${maxWidthClass.value}`,
}));

const flexOrientationClass = computed(() => {
  return orientation.value === ORIENTATION.RIGHT
    ? 'justify-end w-full'
    : 'justify-start w-full';
});

const wrapperAlignClass = computed(() => {
  if (isPrivateNote.value) return 'w-full';
  return orientation.value === ORIENTATION.RIGHT
    ? 'items-end w-full'
    : 'items-start w-full';
});

const messageClass = computed(() => {
  const classToApply = [varaintBaseMap.value[variant.value]];

  if (variant.value === MESSAGE_VARIANTS.ACTIVITY) {
    classToApply.push('rounded-lg px-4 py-2 my-2');
  } else if (!isPrivateNote.value) {
    classToApply.push('rounded-2xl');
    if (orientation.value === ORIENTATION.RIGHT) {
      classToApply.push('ltr:rounded-br-sm rtl:rounded-bl-sm right-bubble');
    } else if (orientation.value === ORIENTATION.LEFT) {
      classToApply.push('ltr:rounded-bl-sm rtl:rounded-br-sm left-bubble');
    }
  }

  return classToApply;
});

const senderName = computed(() => sender.value?.name || '');

const noteTime = computed(() => {
  if (isInboxView?.value) {
    return format(fromUnixTime(createdAt.value), 'h:mm a');
  }
  return messageTimestamp(createdAt.value, 'LLL d, h:mm a');
});

const scrollToMessage = () => {
  emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, {
    messageId: inReplyTo.value.id,
  });
};

const shouldShowMeta = computed(
  () =>
    !props.hideMeta &&
    !shouldGroupWithNext.value &&
    variant.value !== MESSAGE_VARIANTS.ACTIVITY &&
    !isPrivateNote.value
);

const replyToPreview = computed(() => {
  if (!inReplyTo) return '';

  const { content, attachments } = inReplyTo.value;

  if (content) return new MessageFormatter(content).formattedMessage;
  if (attachments?.length) {
    const firstAttachment = attachments[0];
    const fileType = firstAttachment.fileType ?? firstAttachment.file_type;

    return t(`CHAT_LIST.ATTACHMENTS.${fileType}.CONTENT`);
  }

  return t('CONVERSATION.REPLY_MESSAGE_NOT_FOUND');
});
</script>

<template>
  <div v-if="isPrivateNote" class="my-2 flex w-full min-w-0 flex-col">
    <div class="flex w-full gap-4 rounded-xl bg-warning/10 p-4">
      <span class="i-lucide-sticky-note size-5 shrink-0 text-warning" />
      <div class="flex min-w-0 flex-1 flex-col gap-1 text-sm">
        <div
          v-if="inReplyTo"
          class="mb-2 cursor-pointer rounded-lg bg-black/5 p-2"
          @click="scrollToMessage"
        >
          <div
            v-dompurify-html="replyToPreview"
            class="prose prose-bubble line-clamp-2"
          />
        </div>
        <div class="font-medium leading-relaxed text-foreground/90">
          <slot />
        </div>
        <span class="mt-1 text-[13px] font-medium text-muted-foreground">
          <template v-if="senderName">
            {{ t('CONVERSATION.INTERNAL_NOTE.ADDED_BY', { name: senderName }) }}
            <span class="mx-1.5 text-muted-foreground/50">•</span>
          </template>
          {{ noteTime }}
        </span>
      </div>
    </div>
  </div>
  <div
    v-else
    class="flex min-w-0 w-full flex-col bg-transparent text-sm"
    :class="[wrapperAlignClass, isInboxView?.value ? 'gap-1' : 'gap-1.5']"
  >
    <div v-bind="attrs" :class="messageClass">
      <div
        v-if="inReplyTo"
        class="p-2 -mx-1 mb-2 rounded-lg cursor-pointer bg-black/5"
        @click="scrollToMessage"
      >
        <div
          v-dompurify-html="replyToPreview"
          class="prose prose-bubble line-clamp-2"
        />
      </div>
      <slot />
    </div>
    <MessageMeta
      v-if="shouldShowMeta"
      class="text-muted-foreground"
      :class="[flexOrientationClass]"
    />
  </div>
</template>
