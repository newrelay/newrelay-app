<script setup>
import { computed } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  size: {
    type: String,
    default: 'md',
    validator: value => ['md', 'lg'].includes(value),
  },
});

const emit = defineEmits(['close']);

const maxWidthClass = computed(() =>
  props.size === 'lg' ? 'max-w-[550px]' : 'max-w-[500px]'
);
</script>

<template>
  <TeleportWithDirection to="body">
    <div
      v-if="show"
      class="fixed inset-0 z-50 flex items-center justify-center bg-n-alpha-black2 backdrop-blur-[4px]"
      @click.self="emit('close')"
    >
      <div
        class="mx-4 flex w-full flex-col overflow-hidden rounded-[10px] border border-border/40 bg-card shadow-xl"
        :class="maxWidthClass"
        @click.stop
      >
        <div class="px-7 py-6" :class="description ? '' : 'pb-4'">
          <div class="flex items-start justify-between">
            <div class="space-y-1.5">
              <h2 class="text-base font-medium text-foreground">
                {{ title }}
              </h2>
              <p
                v-if="description"
                class="pr-6 text-[13px] leading-relaxed text-muted-foreground"
              >
                {{ description }}
              </p>
            </div>
            <button
              type="button"
              class="-mr-2 shrink-0 rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
              @click="emit('close')"
            >
              <Icon icon="i-lucide-x" class="size-4" />
            </button>
          </div>
        </div>
        <slot />
      </div>
    </div>
  </TeleportWithDirection>
</template>
