<script>
import { RelayModal, RelayButton } from 'dashboard/components-next/relay';

export default {
  components: {
    RelayModal,
    RelayButton,
  },
  props: {
    title: {
      type: String,
      default: 'This is a title',
    },
    description: {
      type: String,
      default: 'This is your description',
    },
    confirmLabel: {
      type: String,
      default: 'Yes',
    },
    cancelLabel: {
      type: String,
      default: 'No',
    },
  },
  data: () => ({
    show: false,
    resolvePromise: undefined,
    rejectPromise: undefined,
  }),

  methods: {
    showConfirmation() {
      this.show = true;
      return new Promise(resolve => {
        this.resolvePromise = resolve;
      });
    },
    confirm() {
      this.resolvePromise?.(true);
      this.show = false;
    },

    cancel() {
      this.resolvePromise?.(false);
      this.show = false;
    },
  },
};
</script>

<template>
  <RelayModal
    :show="show"
    :title="title"
    :description="description"
    @close="cancel"
  >
    <div class="flex justify-end gap-3">
      <RelayButton type="button" variant="outline" @click="cancel">
        {{ cancelLabel }}
      </RelayButton>
      <RelayButton type="button" @click="confirm">
        {{ confirmLabel }}
      </RelayButton>
    </div>
  </RelayModal>
</template>
