<script setup>
import { ref } from 'vue';
import AddContactDrawer from 'dashboard/components-next/Contacts/Drawers/AddContactDrawer.vue';

const emit = defineEmits(['create']);

const drawerRef = ref(null);

const dialogRef = {
  open: () => drawerRef.value?.open(),
  close: () => drawerRef.value?.close(),
};

const onSuccess = () => {
  drawerRef.value?.close();
};

defineExpose({ dialogRef, onSuccess });
</script>

<template>
  <AddContactDrawer ref="drawerRef" @create="emit('create', $event)" />
</template>
