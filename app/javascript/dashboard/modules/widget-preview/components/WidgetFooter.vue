<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';
import Avatar from 'next/avatar/Avatar.vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

const props = defineProps({
  config: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

const isInputFocused = ref(false);

const getStatusText = computed(() => {
  return props.config.isOnline
    ? t('INBOX_MGMT.WIDGET_BUILDER.BODY.TEAM_AVAILABILITY.ONLINE')
    : t('INBOX_MGMT.WIDGET_BUILDER.BODY.TEAM_AVAILABILITY.OFFLINE');
});
</script>

<template>
  <div class="relative flex flex-col w-full px-4">
    <div
      v-if="config.isDefaultScreen"
      class="p-4 rounded-md shadow-sm bg-background dark:bg-secondary"
    >
      <div class="flex items-center justify-between">
        <div>
          <div
            class="text-sm font-medium leading-4 text-foreground dark:text-background"
          >
            {{ getStatusText }}
          </div>
          <div class="mt-1 text-xs text-muted-foreground">
            {{ config.replyTime }}
          </div>
        </div>
        <Avatar name="C" :size="34" rounded-full />
      </div>
      <button
        v-if="config.isDefaultScreen"
        class="inline-flex items-center justify-between px-2 py-1 mt-1 -ml-2 font-medium leading-6 bg-transparent rounded-md text-foreground dark:bg-transparent"
        :style="{ color: config.color }"
      >
        <span class="pr-2 text-xs">
          {{
            $t(
              'INBOX_MGMT.WIDGET_BUILDER.FOOTER.START_CONVERSATION_BUTTON_TEXT'
            )
          }}
        </span>
        <FluentIcon icon="arrow-right" size="14" />
      </button>
    </div>
    <div
      v-else
      class="flex h-12 items-center overflow-hidden rounded-xl border border-border bg-background shadow-sm transition-shadow"
      :class="{ 'ring-1 ring-primary/30': isInputFocused }"
    >
      <ResizableTextArea
        id="chat-input"
        :rows="1"
        :placeholder="
          $t('INBOX_MGMT.WIDGET_BUILDER.FOOTER.CHAT_INPUT_PLACEHOLDER')
        "
        class="reset-base !mb-0 h-8 min-w-0 flex-1 resize-none border-0 bg-transparent px-3 py-1.5 text-sm text-foreground outline-none placeholder:text-muted-foreground focus:outline-none"
        @focus="isInputFocused = true"
        @blur="isInputFocused = false"
      />
      <div class="flex shrink-0 items-center gap-1 pr-2">
        <span class="flex size-8 items-center justify-center text-foreground">
          <FluentIcon icon="emoji" size="20" />
        </span>
        <span class="flex size-8 items-center justify-center text-foreground">
          <FluentIcon icon="send" size="20" />
        </span>
      </div>
    </div>
  </div>
</template>
