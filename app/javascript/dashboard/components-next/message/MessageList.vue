<script setup>
import { computed, reactive } from 'vue';
import Message from './Message.vue';
import InboxMessageDateSeparator from './InboxMessageDateSeparator.vue';
import { MESSAGE_TYPES, ATTACHMENT_TYPES } from './constants.js';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { useMapGetter } from 'dashboard/composables/store.js';
import MessageApi from 'dashboard/api/inbox/message.js';

/**
 * Props definition for the component
 * @typedef {Object} Props
 * @property {Array} readMessages - Array of read messages
 * @property {Array} unReadMessages - Array of unread messages
 * @property {Number} currentUserId - ID of the current user
 * @property {Boolean} isAnEmailChannel - Whether this is an email channel
 * @property {Object} inboxSupportsReplyTo - Inbox reply support configuration
 * @property {Array} messages - Array of all messages [These are not in camelcase]
 */
const props = defineProps({
  currentUserId: {
    type: Number,
    required: true,
  },
  firstUnreadId: {
    type: Number,
    default: null,
  },
  isAnEmailChannel: {
    type: Boolean,
    default: false,
  },
  inboxSupportsReplyTo: {
    type: Object,
    default: () => ({ incoming: false, outgoing: false }),
  },
  messages: {
    type: Array,
    default: () => [],
  },
  isInboxView: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['retry']);

const allMessages = computed(() => {
  return useCamelCase(props.messages, {
    deep: true,
    stopPaths: ['content_attributes.translations'],
  });
});

const ALBUM_MEDIA_TYPES = [
  ATTACHMENT_TYPES.IMAGE,
  ATTACHMENT_TYPES.VIDEO,
  ATTACHMENT_TYPES.IG_REEL,
];
const ALBUM_MAX_GAP_SECONDS = 120;

const isAlbumMediaMessage = message => {
  if (message.private) return false;
  if (message.status === 'failed') return false;
  if (!Array.isArray(message.attachments) || message.attachments.length !== 1) {
    return false;
  }
  return ALBUM_MEDIA_TYPES.includes(message.attachments[0].fileType);
};

const canJoinAlbum = (first, candidate) => {
  if (!isAlbumMediaMessage(candidate) || candidate.content) return false;
  const firstSender = first.senderId ?? first.sender?.id;
  const candidateSender = candidate.senderId ?? candidate.sender?.id;
  if (firstSender !== candidateSender) return false;
  if (first.messageType !== candidate.messageType) return false;
  return (
    Math.abs((candidate.createdAt || 0) - (first.createdAt || 0)) <=
    ALBUM_MAX_GAP_SECONDS
  );
};

const albumByIndex = computed(() => {
  const list = allMessages.value;
  const result = list.map(() => ({ skip: false, attachments: null }));
  let i = 0;
  while (i < list.length) {
    if (isAlbumMediaMessage(list[i])) {
      const group = [i];
      let j = i + 1;
      while (j < list.length && canJoinAlbum(list[i], list[j])) {
        group.push(j);
        j += 1;
      }
      if (group.length >= 2) {
        result[i] = {
          skip: false,
          attachments: group.flatMap(idx => list[idx].attachments),
        };
        group.slice(1).forEach(idx => {
          result[idx] = { skip: true, attachments: null };
        });
      }
      i = j;
    } else {
      i += 1;
    }
  }
  return result;
});

const currentChat = useMapGetter('getSelectedChat');

// Cache for fetched reply messages to avoid duplicate API calls
const fetchedReplyMessages = reactive(new Map());

/**
 * Fetches a specific message from the API by trying to get messages around it
 * @param {number} messageId - The ID of the message to fetch
 * @param {number} conversationId - The ID of the conversation
 * @returns {Promise<Object|null>} - The fetched message or null if not found/error
 */
const fetchReplyMessage = async (messageId, conversationId) => {
  // Return cached result if already fetched
  if (fetchedReplyMessages.has(messageId)) {
    return fetchedReplyMessages.get(messageId);
  }

  try {
    const response = await MessageApi.getPreviousMessages({
      conversationId,
      before: messageId + 100,
      after: messageId - 100,
    });

    const messages = response.data?.payload || [];
    const targetMessage = messages.find(msg => msg.id === messageId);

    if (targetMessage) {
      const camelCaseMessage = useCamelCase(targetMessage);
      fetchedReplyMessages.set(messageId, camelCaseMessage);
      return camelCaseMessage;
    }

    // Cache null result to avoid repeated API calls
    fetchedReplyMessages.set(messageId, null);
    return null;
  } catch (error) {
    fetchedReplyMessages.set(messageId, null);
    return null;
  }
};

/**
 * Determines if a message should be grouped with the next message
 * @param {Number} index - Index of the current message
 * @param {Array} searchList - Array of messages to check
 * @returns {Boolean} - Whether the message should be grouped with next
 */
const shouldGroupWithNext = (index, searchList) => {
  if (index === searchList.length - 1) return false;

  const current = searchList[index];
  const next = searchList[index + 1];

  if (next.status === 'failed') return false;

  const nextSenderId = next.senderId ?? next.sender?.id;
  const currentSenderId = current.senderId ?? current.sender?.id;
  const hasSameSender = nextSenderId === currentSenderId;

  const nextMessageType = next.messageType;
  const currentMessageType = current.messageType;

  const areBothTemplates =
    nextMessageType === MESSAGE_TYPES.TEMPLATE &&
    currentMessageType === MESSAGE_TYPES.TEMPLATE;

  if (!hasSameSender || areBothTemplates) return false;

  if (currentMessageType !== nextMessageType) return false;

  // Check if messages are in the same minute by rounding down to nearest minute
  return Math.floor(next.createdAt / 60) === Math.floor(current.createdAt / 60);
};

/**
 * Gets the message that was replied to
 * @param {Object} parentMessage - The message containing the reply reference
 * @returns {Object|null} - The message being replied to, or null if not found
 */
const getInReplyToMessage = parentMessage => {
  if (!parentMessage) return null;

  const inReplyToMessageId =
    parentMessage.contentAttributes?.inReplyTo ??
    parentMessage.content_attributes?.in_reply_to;

  if (!inReplyToMessageId) return null;

  // Try to find in current messages first
  let replyMessage = props.messages?.find(msg => msg.id === inReplyToMessageId);

  // Then try store messages
  if (!replyMessage && currentChat.value?.messages) {
    replyMessage = currentChat.value.messages.find(
      msg => msg.id === inReplyToMessageId
    );
  }

  // Then check fetch cache
  if (!replyMessage && fetchedReplyMessages.has(inReplyToMessageId)) {
    replyMessage = fetchedReplyMessages.get(inReplyToMessageId);
  }

  // If still not found and we have conversation context, fetch it
  if (!replyMessage && currentChat.value?.id) {
    fetchReplyMessage(inReplyToMessageId, currentChat.value.id);
    return null; // Let UI handle loading state
  }

  return replyMessage ? useCamelCase(replyMessage) : null;
};

const shouldShowDateSeparator = index => {
  if (index === 0) return true;

  const current = allMessages.value[index];
  const previous = allMessages.value[index - 1];
  const currentDay = new Date(current.createdAt * 1000).toDateString();
  const previousDay = new Date(previous.createdAt * 1000).toDateString();

  return currentDay !== previousDay;
};
</script>

<template>
  <div v-if="isInboxView" class="flex flex-col gap-4 bg-transparent px-6 py-6">
    <slot name="beforeAll" />
    <template v-for="(message, index) in allMessages" :key="message.id">
      <InboxMessageDateSeparator
        v-if="!albumByIndex[index].skip && shouldShowDateSeparator(index)"
        :timestamp="message.createdAt"
      />
      <slot
        v-if="
          !albumByIndex[index].skip &&
          firstUnreadId &&
          message.id === firstUnreadId
        "
        name="unreadBadge"
      />
      <Message
        v-if="!albumByIndex[index].skip"
        v-bind="message"
        :attachments="albumByIndex[index].attachments || message.attachments"
        :is-email-inbox="isAnEmailChannel"
        :in-reply-to="getInReplyToMessage(message)"
        :group-with-next="
          albumByIndex[index].attachments
            ? false
            : shouldGroupWithNext(index, allMessages)
        "
        :inbox-supports-reply-to="inboxSupportsReplyTo"
        :current-user-id="currentUserId"
        is-inbox-view
        data-clarity-mask="True"
        @retry="emit('retry', message)"
      />
    </template>
    <slot name="after" />
  </div>
  <ul v-else class="list-none bg-transparent px-4">
    <slot name="beforeAll" />
    <template v-for="(message, index) in allMessages" :key="message.id">
      <slot
        v-if="
          !albumByIndex[index].skip &&
          firstUnreadId &&
          message.id === firstUnreadId
        "
        name="unreadBadge"
      />
      <Message
        v-if="!albumByIndex[index].skip"
        v-bind="message"
        :attachments="albumByIndex[index].attachments || message.attachments"
        :is-email-inbox="isAnEmailChannel"
        :in-reply-to="getInReplyToMessage(message)"
        :group-with-next="
          albumByIndex[index].attachments
            ? false
            : shouldGroupWithNext(index, allMessages)
        "
        :inbox-supports-reply-to="inboxSupportsReplyTo"
        :current-user-id="currentUserId"
        data-clarity-mask="True"
        @retry="emit('retry', message)"
      />
    </template>
    <slot name="after" />
  </ul>
</template>
