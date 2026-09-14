<script>
import ReplyBox from './ReplyBox.vue';

export default {
  name: 'InboxReplyComposer',
  components: { ReplyBox },
  emits: ['toggleEditorSize'],
  methods: {
    openWhatsappTemplateModal() {
      this.$refs.replyBox?.openWhatsappTemplateModal?.();
    },
  },
};
</script>

<template>
  <ReplyBox
    ref="replyBox"
    variant="inbox"
    @toggle-editor-size="$emit('toggleEditorSize')"
  />
</template>
