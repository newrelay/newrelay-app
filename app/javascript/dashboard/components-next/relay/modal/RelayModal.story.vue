<script setup>
import { ref } from 'vue';
import RelayModal from './RelayModal.vue';
import Button from '../button/Button.vue';

const show = ref(false);
</script>

<template>
  <Story title="Relay/RelayModal" :layout="{ type: 'single', iframe: true }">
    <Variant title="Default">
      <div class="flex min-h-[320px] items-center justify-center bg-background">
        <Button @click="show = true">Open modal</Button>
        <RelayModal
          :show="show"
          title="Modal title"
          description="A short description of what this modal does."
          @close="show = false"
        >
          <div class="p-6 text-sm text-muted-foreground">
            Modal body content.
          </div>
        </RelayModal>
      </div>
    </Variant>
  </Story>
</template>
