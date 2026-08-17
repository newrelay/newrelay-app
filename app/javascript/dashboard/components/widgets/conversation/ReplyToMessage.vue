<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';
import MessagePreview from 'dashboard/components/widgets/conversation/MessagePreview.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  message: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['dismiss']);
</script>

<template>
  <div
    class="reply-editor bg-muted-foreground/10 rounded-md py-1 pl-2 pr-1 text-xs tracking-wide mt-2 flex items-center gap-1.5"
  >
    <fluent-icon class="flex-shrink-0 icon" icon="arrow-reply" size="14" />
    <div class="flex-grow gap-1 mt-px text-xs truncate">
      {{ $t('CONVERSATION.REPLYBOX.REPLYING_TO') }}
      <MessagePreview
        :message="message"
        :show-message-type="false"
        :default-empty-message="$t('CONVERSATION.REPLY_MESSAGE_NOT_FOUND')"
        class="inline"
      />
    </div>
    <RelayTooltip :content="$t('CONVERSATION.REPLYBOX.DISMISS_REPLY')">
      <Button
        ghost
        xs
        slate
        icon="i-lucide-x"
        class="flex-shrink-0"
        @click.stop="emit('dismiss')"
      />
    </RelayTooltip>
  </div>
</template>

<style lang="scss">
// TODO: Remove this
// override for dashboard/assets/scss/widgets/_reply-box.scss
.reply-editor {
  .icon {
    margin-right: 0px !important;
  }
}
</style>
