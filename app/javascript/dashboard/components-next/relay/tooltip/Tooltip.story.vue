<script setup>
import Tooltip from './Tooltip.vue';
import TooltipProvider from './TooltipProvider.vue';
import Button from '../button/Button.vue';
</script>

<template>
  <Story title="Relay/Tooltip" :layout="{ type: 'grid', width: '480px' }">
    <Variant title="Sides">
      <TooltipProvider>
        <div class="flex flex-wrap items-center gap-6 p-8 bg-background">
          <Tooltip content="Top tooltip" side="top">
            <Button variant="outline">Top</Button>
          </Tooltip>
          <Tooltip content="Right tooltip" side="right">
            <Button variant="outline">Right</Button>
          </Tooltip>
          <Tooltip content="Bottom tooltip" side="bottom">
            <Button variant="outline">Bottom</Button>
          </Tooltip>
          <Tooltip content="Left tooltip" side="left">
            <Button variant="outline">Left</Button>
          </Tooltip>
        </div>
      </TooltipProvider>
    </Variant>

    <Variant title="Disabled">
      <TooltipProvider>
        <div class="flex items-center gap-3 p-8 bg-background">
          <Tooltip content="You won't see this" disabled>
            <Button variant="outline">Disabled tooltip</Button>
          </Tooltip>
        </div>
      </TooltipProvider>
    </Variant>
  </Story>
</template>
