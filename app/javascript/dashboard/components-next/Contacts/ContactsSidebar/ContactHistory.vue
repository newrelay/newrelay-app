<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper.js';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { RelayButton, RelayBadge } from 'dashboard/components-next/relay';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { getPlainText } = useMessageFormatter();

const conversations = useMapGetter(
  'contactConversations/getAllConversationsByContactId'
);
const stateInbox = useMapGetter('inboxes/getInboxById');
const uiFlags = useMapGetter('contactConversations/getUIFlags');

const isFetching = computed(() => uiFlags.value.isFetching);

const contactConversations = computed(() =>
  conversations.value(route.params.contactId)
);

const isEmailChannel = conversation => {
  const channel =
    conversation.meta?.channel ||
    stateInbox.value(conversation.inboxId)?.channelType ||
    '';
  return String(channel).toLowerCase().includes('email');
};

const activityTitle = conversation => {
  if (isEmailChannel(conversation)) {
    return t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.EMAIL_SENT');
  }
  return t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.CONVERSATION');
};

const directionLabel = conversation => {
  const messageType = conversation.lastNonActivityMessage?.messageType;
  // 0 = incoming, 1 = outgoing
  if (messageType === 1) {
    return t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.OUTBOUND');
  }
  if (messageType === 0) {
    return t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.INBOUND');
  }
  return null;
};

const subjectOrPreview = conversation => {
  const emailSubject = conversation.customAttributes?.email?.subject;
  const mailSubject = conversation.additionalAttributes?.mailSubject;
  const content = conversation.lastNonActivityMessage?.content;
  return getPlainText(
    emailSubject || mailSubject || content || t('CHAT_LIST.NO_CONTENT')
  );
};

const fromName = conversation =>
  conversation.meta?.assignee?.name ||
  conversation.lastNonActivityMessage?.sender?.name ||
  t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.UNKNOWN_AGENT');

const toName = conversation =>
  conversation.meta?.sender?.email ||
  conversation.meta?.sender?.name ||
  t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.CONTACT');

const openConversation = conversation => {
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
  <div
    v-if="isFetching"
    class="flex items-center justify-center py-10 text-muted-foreground"
  >
    <Spinner />
  </div>

  <div
    v-else-if="contactConversations.length > 0"
    class="w-full space-y-8 pb-12"
  >
    <div
      v-for="conversation in contactConversations"
      :key="conversation.id"
      class="relative pl-8"
    >
      <div class="absolute bottom-0 left-0 top-1 -z-10 w-px bg-border/60" />
      <div
        class="absolute left-[-5px] top-1 size-2.5 rounded-full bg-primary ring-4 ring-background"
      />

      <div class="mb-2 flex items-start justify-between gap-3">
        <div class="flex flex-wrap items-center gap-2">
          <span class="text-sm font-semibold text-foreground">
            {{ activityTitle(conversation) }}
          </span>
          <span
            v-if="directionLabel(conversation)"
            class="rounded-full border border-border/50 bg-muted/50 px-2 py-0.5 text-xs text-muted-foreground"
          >
            {{ directionLabel(conversation) }}
          </span>
        </div>
        <span class="shrink-0 text-xs font-medium text-muted-foreground">
          {{
            conversation.timestamp ? dynamicTime(conversation.timestamp) : ''
          }}
        </span>
      </div>

      <button
        type="button"
        class="group relative w-full overflow-hidden rounded-xl border border-border/50 bg-card p-4 text-left shadow-sm transition-colors hover:border-primary/50"
        @click="openConversation(conversation)"
      >
        <div
          class="mb-3 flex items-center justify-between gap-2 border-b border-border/40 pb-3"
        >
          <div
            class="flex min-w-0 flex-wrap items-center gap-2 text-sm text-muted-foreground"
          >
            <span>
              {{
                t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.FROM_LABEL', {
                  name: fromName(conversation),
                })
              }}
            </span>
            <span class="i-lucide-chevron-right size-3 shrink-0" />
            <span>
              {{
                t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.TO_LABEL', {
                  name: toName(conversation),
                })
              }}
            </span>
          </div>
          <RelayButton
            variant="ghost"
            size="sm"
            class="-mr-2 h-6 px-2 text-xs"
            @click.stop="openConversation(conversation)"
          >
            {{ t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.OPEN') }}
          </RelayButton>
        </div>
        <h4 class="mb-1 text-sm font-semibold text-foreground line-clamp-2">
          {{ subjectOrPreview(conversation) }}
        </h4>
        <div class="mt-2 flex items-center gap-2">
          <RelayBadge
            v-if="conversation.status"
            variant="outline"
            class="text-[10px] font-medium capitalize"
          >
            {{ conversation.status }}
          </RelayBadge>
        </div>
      </button>
    </div>
  </div>

  <div
    v-else
    class="mx-auto flex max-w-sm flex-col items-center justify-center py-16 text-center opacity-60"
  >
    <div
      class="mb-4 flex size-12 items-center justify-center rounded-full bg-muted"
    >
      <span class="i-lucide-history size-6 text-muted-foreground" />
    </div>
    <h3 class="mb-1 text-sm font-medium text-foreground">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.TABS.HISTORY') }}
    </h3>
    <p class="text-xs text-muted-foreground">
      {{ t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.EMPTY_STATE') }}
    </p>
  </div>
</template>
