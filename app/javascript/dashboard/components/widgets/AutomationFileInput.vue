<script>
import { useAlert } from 'dashboard/composables';
import Spinner from 'shared/components/Spinner.vue';
export default {
  components: {
    Spinner,
  },
  props: {
    initialFileName: {
      type: String,
      default: '',
    },
  },
  emits: ['update:modelValue'],
  data() {
    return {
      uploadState: 'idle',
      label: this.$t('AUTOMATION.ATTACHMENT.LABEL_IDLE'),
    };
  },
  mounted() {
    if (this.initialFileName) {
      this.label = this.initialFileName;
      this.uploadState = 'uploaded';
    }
  },
  methods: {
    async onChangeFile(event) {
      this.uploadState = 'processing';
      this.label = this.$t('AUTOMATION.ATTACHMENT.LABEL_UPLOADING');
      try {
        const file = event.target.files[0];
        const id = await this.$store.dispatch(
          'automations/uploadAttachment',
          file
        );
        this.$emit('update:modelValue', [id]);
        this.uploadState = 'uploaded';
        this.label = this.$t('AUTOMATION.ATTACHMENT.LABEL_UPLOADED');
      } catch (error) {
        this.uploadState = 'failed';
        this.label = this.$t('AUTOMATION.ATTACHMENT.LABEL_UPLOAD_FAILED');
        useAlert(this.$t('AUTOMATION.ATTACHMENT.UPLOAD_ERROR'));
      }
    },
  },
};
</script>

<template>
  <label
    class="flex h-8 bg-background py-1 px-2 items-center text-xs cursor-pointer rounded-lg border border-dashed border-border text-[13.5px] font-[500] text-foreground"
    :class="uploadState === 'processing' ? 'cursor-not-allowed opacity-90' : ''"
  >
    <input
      v-if="uploadState !== 'processing'"
      type="file"
      name="attachment"
      class="hidden"
      @change="onChangeFile"
    />
    <Spinner v-if="uploadState === 'processing'" />
    <fluent-icon v-if="uploadState === 'idle'" icon="file-upload" />
    <fluent-icon
      v-if="uploadState === 'uploaded'"
      icon="checkmark-circle"
      type="outline"
      class="text-success mr-2"
    />
    <fluent-icon
      v-if="uploadState === 'failed'"
      icon="dismiss-circle"
      type="outline"
      class="text-destructive mr-2"
    />
    <p class="whitespace-nowrap overflow-hidden text-ellipsis w-full mb-0">
      {{ label }}
    </p>
  </label>
</template>
