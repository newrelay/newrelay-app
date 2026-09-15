<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper.js';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { dynamicTime } from 'shared/helpers/timeHelper';
import {
  RELAY_DIALOG_OVERLAY_CLASS,
  RELAY_MODAL_CLOSE_BUTTON_CLASS,
  RELAY_MODAL_DESCRIPTION_CLASS,
  RELAY_MODAL_TITLE_CLASS,
} from 'dashboard/components-next/relay/modal/constants';

const props = defineProps({
  show: { type: Boolean, default: false },
  company: { type: Object, default: () => ({}) },
  conversations: { type: Array, default: () => [] },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const companyName = computed(
  () => props.company?.name || t('COMPANIES.UNNAMED')
);

const activityIcon = conversation => {
  const channel = conversation.meta?.channel;
  if (channel === INBOX_TYPES.EMAIL) return 'i-lucide-mail';
  if (channel === INBOX_TYPES.TWILIO || channel === INBOX_TYPES.SMS) {
    return 'i-lucide-phone';
  }
  return 'i-lucide-message-square';
};

const activityTitle = conversation => {
  const channel = conversation.meta?.channel;
  if (channel === INBOX_TYPES.EMAIL) {
    return t('COMPANIES.DETAIL.ACTIVITY.EMAIL');
  }
  if (channel === INBOX_TYPES.TWILIO || channel === INBOX_TYPES.SMS) {
    return t('COMPANIES.DETAIL.ACTIVITY.CALL');
  }
  return t('COMPANIES.DETAIL.ACTIVITY.CONVERSATION', {
    id: conversation.id,
  });
};

const activitySubtitle = conversation =>
  conversation.meta?.sender?.name ||
  conversation.meta?.assignee?.name ||
  t('COMPANIES.EMPTY_VALUE');

const openConversation = conversation => {
  emit('close');
  const path = frontendURL(
    conversationUrl({
      accountId: route.params.accountId,
      id: conversation.id,
    })
  );
  router.push({ path });
};
</script>

<template>
  <Teleport to="body">
    <div
      v-if="show"
      data-relay
      class="flex items-center justify-center p-4 sm:p-6 animate-in fade-in duration-200"
      :class="RELAY_DIALOG_OVERLAY_CLASS"
    >
      <div class="absolute inset-0" @click="emit('close')" />
      <div
        class="relative flex max-h-[85vh] w-full max-w-4xl animate-in zoom-in-95 flex-col rounded-2xl border border-border/60 bg-card shadow-xl duration-200"
        @click.stop
      >
        <div
          class="flex shrink-0 items-center justify-between gap-4 border-b border-border/40 p-6"
        >
          <div class="min-w-0">
            <h2 :class="RELAY_MODAL_TITLE_CLASS">
              {{ t('COMPANIES.DETAIL.ACTIVITY.MODAL.TITLE') }}
            </h2>
            <p :class="RELAY_MODAL_DESCRIPTION_CLASS">
              {{
                t('COMPANIES.DETAIL.ACTIVITY.MODAL.SUBTITLE', {
                  count: conversations.length,
                  company: companyName,
                })
              }}
            </p>
          </div>
          <button
            type="button"
            :class="`${RELAY_MODAL_CLOSE_BUTTON_CLASS} rounded-full hover:bg-muted/50`"
            @click="emit('close')"
          >
            <span class="i-lucide-x size-5" />
          </button>
        </div>

        <div class="flex-1 overflow-y-auto p-6">
          <div
            v-if="conversations.length === 0"
            class="flex h-full flex-col items-center justify-center py-12 text-center"
          >
            <span class="i-lucide-clock mb-3 size-8 text-muted-foreground" />
            <h3 class="text-sm font-medium text-foreground">
              {{ t('COMPANIES.DETAIL.ACTIVITY.MODAL.EMPTY_TITLE') }}
            </h3>
            <p class="mt-1 text-xs text-muted-foreground">
              {{ t('COMPANIES.DETAIL.ACTIVITY.MODAL.EMPTY_SUBTITLE') }}
            </p>
          </div>
          <div v-else class="flex flex-col space-y-6">
            <button
              v-for="conversation in conversations"
              :key="conversation.id"
              type="button"
              class="flex gap-4 text-left"
              @click="openConversation(conversation)"
            >
              <div
                class="relative z-10 flex size-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary"
              >
                <span class="size-4" :class="[activityIcon(conversation)]" />
              </div>
              <div class="flex w-full flex-col">
                <div class="flex items-center justify-between gap-3">
                  <span class="text-[14px] font-medium text-foreground">
                    {{ activityTitle(conversation) }}
                  </span>
                  <span class="shrink-0 text-[12px] text-muted-foreground">
                    {{
                      conversation.timestamp
                        ? dynamicTime(conversation.timestamp)
                        : ''
                    }}
                  </span>
                </div>
                <span class="mt-0.5 text-[13px] text-muted-foreground">
                  {{ activitySubtitle(conversation) }}
                </span>
              </div>
            </button>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>
