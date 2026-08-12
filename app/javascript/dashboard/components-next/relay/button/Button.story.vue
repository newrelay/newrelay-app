<script setup>
import Button from './Button.vue';

const VARIANTS = [
  'default',
  'destructive',
  'outline',
  'secondary',
  'ghost',
  'link',
];
const SIZES = ['default', 'sm', 'lg', 'icon'];
</script>

<template>
  <Story title="Relay/Button" :layout="{ type: 'grid', width: '800px' }">
    <Variant title="Variants">
      <div class="flex flex-wrap gap-2 p-4 bg-n-background">
        <Button v-for="variant in VARIANTS" :key="variant" :variant="variant">
          {{ variant }}
        </Button>
      </div>
    </Variant>

    <Variant title="Sizes">
      <div class="flex flex-wrap items-center gap-2 p-4 bg-n-background">
        <Button v-for="size in SIZES" :key="size" :size="size">
          <template v-if="size === 'icon'">
            <span class="i-lucide-plus size-4" />
          </template>
          <template v-else>{{ size }}</template>
        </Button>
      </div>
    </Variant>

    <Variant title="With icon">
      <div class="flex flex-wrap gap-2 p-4 bg-n-background">
        <Button>
          <span class="i-lucide-plus size-4" />
          Add item
        </Button>
        <Button variant="outline">
          Settings
          <span class="i-lucide-settings size-4" />
        </Button>
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="flex flex-wrap gap-2 p-4 bg-n-background">
        <Button disabled>Disabled</Button>
        <Button variant="outline" disabled>Outline disabled</Button>
      </div>
    </Variant>
  </Story>
</template>
