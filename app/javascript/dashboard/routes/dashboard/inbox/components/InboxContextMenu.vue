<script setup>
import ContextMenu from 'dashboard/components/ui/ContextMenu.vue';
import MenuItem from 'dashboard/components/widgets/conversation/contextMenu/menuItem.vue';

defineProps({
  contextMenuPosition: {
    type: Object,
    default: () => ({}),
  },
  menuItems: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['close', 'selectAction']);

const handleClose = () => {
  emit('close');
};

const onMenuItemClick = key => {
  emit('selectAction', key);
  handleClose();
};
</script>

<template>
  <ContextMenu
    :x="contextMenuPosition.x"
    :y="contextMenuPosition.y"
    @close="handleClose"
  >
    <div
      class="z-50 min-w-56 overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
    >
      <MenuItem
        v-for="item in menuItems"
        :key="item.key"
        :option="item"
        variant="icon"
        @click.stop="onMenuItemClick(item.key)"
      />
    </div>
  </ContextMenu>
</template>
