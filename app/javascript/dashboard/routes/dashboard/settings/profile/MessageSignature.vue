<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { stripInlineBase64Images } from 'dashboard/helper/editorHelper';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  messageSignature: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['updateSignature']);

const { t } = useI18n();
const signature = ref(props.messageSignature ?? '');
watch(
  () => props.messageSignature ?? '',
  newValue => {
    signature.value = newValue;
  }
);

const updateSignature = () => {
  const { sanitizedContent, hasInlineImages } = stripInlineBase64Images(
    signature.value || ''
  );
  signature.value = sanitizedContent.trim();
  if (hasInlineImages) {
    useAlert(
      t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.INLINE_IMAGE_WARNING')
    );
  }
  emit('updateSignature', signature.value);
};
</script>

<template>
  <form class="flex flex-col gap-6" @submit.prevent="updateSignature()">
    <Editor
      id="message-signature-input"
      v-model="signature"
      class="min-h-[10rem]"
      channel-type="Context::MessageSignature"
      :enable-canned-responses="false"
      :show-character-count="false"
      :placeholder="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE.PLACEHOLDER')"
    />
    <div>
      <RelayButton type="submit" class="shadow-sm">
        {{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.BTN_TEXT') }}
      </RelayButton>
    </div>
  </form>
</template>
