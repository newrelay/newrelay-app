<script setup>
import { ref } from 'vue';
import RelayDeleteConfirmModal from './RelayDeleteConfirmModal.vue';
import Button from '../button/Button.vue';

const show = ref(false);
</script>

<template>
  <Story
    title="Relay/RelayDeleteConfirmModal"
    :layout="{ type: 'single', iframe: true }"
  >
    <Variant title="Default">
      <div class="flex min-h-[360px] items-center justify-center bg-background">
        <Button variant="destructive" @click="show = true">
          Delete contact
        </Button>
        <RelayDeleteConfirmModal
          :show="show"
          title="Delete this contact?"
          description-prefix="This will permanently remove "
          highlight-name="John Doe"
          description-suffix=" and all associated conversations."
          confirm-text="Delete"
          cancel-text="Cancel"
          @close="show = false"
          @confirm="show = false"
        />
      </div>
    </Variant>
  </Story>
</template>
