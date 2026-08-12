<script setup>
import { computed, useAttrs } from 'vue';

import MessageMeta from '../MessageMeta.vue';

import { emitter } from 'shared/helpers/mitt';
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { MESSAGE_VARIANTS, ORIENTATION } from '../constants';

const props = defineProps({
  hideMeta: { type: Boolean, default: false },
});

defineOptions({ inheritAttrs: false });

const attrs = useAttrs();
const { variant, inReplyTo, shouldGroupWithNext, orientation } =
  useMessageContext();
const { t } = useI18n();

// Colored fill lives ONLY on the inner surface (never the meta wrapper).
// Agent/bot/template text: solid primary + white. Media/email override via attrs.
const varaintBaseMap = {
  [MESSAGE_VARIANTS.AGENT]:
    'bg-primary text-primary-foreground shadow-xs border-transparent w-fit max-w-[85%]',
  [MESSAGE_VARIANTS.PRIVATE]:
    'bg-amber-100 dark:bg-amber-900/40 text-amber-900 dark:text-amber-100 border-transparent w-fit max-w-[85%]',
  [MESSAGE_VARIANTS.USER]:
    'bg-card border border-border shadow-xs text-foreground w-fit max-w-[85%]',
  [MESSAGE_VARIANTS.ACTIVITY]:
    'bg-muted/50 text-muted-foreground text-sm w-full',
  [MESSAGE_VARIANTS.BOT]:
    'bg-primary text-primary-foreground shadow-xs border-transparent w-fit max-w-[85%]',
  [MESSAGE_VARIANTS.TEMPLATE]:
    'bg-card border border-border shadow-xs text-foreground w-fit max-w-[85%]',
  [MESSAGE_VARIANTS.ERROR]:
    'bg-destructive/10 text-destructive w-fit max-w-[85%]',
  [MESSAGE_VARIANTS.EMAIL]: 'w-fit max-w-[85%]',
  [MESSAGE_VARIANTS.UNSUPPORTED]:
    'bg-amber-500/10 border border-dashed border-amber-500/50 text-amber-500 w-fit max-w-[85%]',
};

const flexOrientationClass = computed(() => {
  return orientation.value === ORIENTATION.RIGHT
    ? 'justify-end w-full'
    : 'justify-start w-full';
});

const wrapperAlignClass = computed(() => {
  return orientation.value === ORIENTATION.RIGHT
    ? 'items-end w-full'
    : 'items-start w-full';
});

const messageClass = computed(() => {
  const classToApply = [varaintBaseMap[variant.value]];

  if (variant.value === MESSAGE_VARIANTS.ACTIVITY) {
    classToApply.push('rounded-lg px-4 py-2 my-2');
  } else {
    classToApply.push('rounded-2xl');
    if (orientation.value === ORIENTATION.RIGHT) {
      classToApply.push('ltr:rounded-br-sm rtl:rounded-bl-sm right-bubble');
    } else if (orientation.value === ORIENTATION.LEFT) {
      classToApply.push('ltr:rounded-bl-sm rtl:rounded-br-sm left-bubble');
    }
  }

  return classToApply;
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
    variant.value !== MESSAGE_VARIANTS.ACTIVITY
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
  <div
    class="text-sm min-w-0 flex flex-col gap-1.5 bg-transparent w-full"
    :class="[wrapperAlignClass]"
  >
    <div v-bind="attrs" :class="messageClass">
      <div
        v-if="inReplyTo"
        class="p-2 -mx-1 mb-2 rounded-lg cursor-pointer bg-n-alpha-black1"
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
      :class="[
        flexOrientationClass,
        variant === MESSAGE_VARIANTS.PRIVATE
          ? 'text-n-amber-12/50'
          : 'text-muted-foreground',
      ]"
    />
  </div>
</template>
