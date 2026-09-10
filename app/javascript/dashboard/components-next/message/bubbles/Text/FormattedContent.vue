<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../../provider.js';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { MESSAGE_VARIANTS } from '../../constants';
import {
  highlightSearchHtml,
  useConversationMessageSearch,
} from 'dashboard/composables/useConversationMessageSearch';

const props = defineProps({
  content: {
    type: String,
    required: true,
  },
});

const { variant } = useMessageContext();
const { query } = useConversationMessageSearch();

const formattedContent = computed(() => {
  if (variant.value === MESSAGE_VARIANTS.ACTIVITY) {
    return highlightSearchHtml(props.content, query.value);
  }

  return highlightSearchHtml(
    new MessageFormatter(props.content).formattedMessage,
    query.value
  );
});
</script>

<template>
  <span v-dompurify-html="formattedContent" class="prose prose-bubble" />
</template>
