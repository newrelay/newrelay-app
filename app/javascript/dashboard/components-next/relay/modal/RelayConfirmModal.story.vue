<script setup>
import { ref } from 'vue';
import RelayConfirmModal from './RelayConfirmModal.vue';
import Button from '../button/Button.vue';

const show = ref(false);
const showTyped = ref(false);
</script>

<template>
  <Story
    title="Relay/RelayConfirmModal"
    :layout="{ type: 'single', iframe: true }"
  >
    <Variant title="Default">
      <div class="flex min-h-[320px] items-center justify-center bg-background">
        <Button @click="show = true">Open confirm modal</Button>
        <RelayConfirmModal
          :show="show"
          title="Confirm action"
          message="Are you sure you want to continue?"
          confirm-text="Confirm"
          cancel-text="Cancel"
          @close="show = false"
          @confirm="show = false"
        />
      </div>
    </Variant>

    <Variant title="Type to confirm">
      <div class="flex min-h-[320px] items-center justify-center bg-background">
        <Button @click="showTyped = true">Open (type to confirm)</Button>
        <RelayConfirmModal
          :show="showTyped"
          title="Delete workspace"
          message="Type "
          message-value="acme-inc"
          confirm-value="acme-inc"
          confirm-placeholder="Type the workspace name"
          confirm-text="Delete"
          cancel-text="Cancel"
          @close="showTyped = false"
          @confirm="showTyped = false"
        />
      </div>
    </Variant>
  </Story>
</template>
