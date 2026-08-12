<script>
import ReplyBox from './ReplyBox.vue';

export default {
  name: 'InboxReplyComposer',
  components: { ReplyBox },
  emits: ['toggleEditorSize'],
};
</script>

<template>
  <ReplyBox variant="inbox" @toggle-editor-size="$emit('toggleEditorSize')" />
</template>
