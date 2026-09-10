<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  steps: {
    type: Array,
    required: true,
  },
  activeIndex: {
    type: Number,
    default: 0,
  },
  backLabel: {
    type: String,
    required: true,
  },
  stepLabel: {
    type: String,
    default: '',
  },
});

defineEmits(['back']);
</script>

<template>
  <div
    class="flex h-[calc(100vh-8rem)] w-full flex-col overflow-hidden rounded-xl border border-border/80 bg-background shadow-xs lg:h-[calc(100vh-6rem)]"
  >
    <div
      class="flex shrink-0 items-center gap-3 border-b border-border/40 bg-card px-6 py-4"
    >
      <button
        type="button"
        class="group flex items-center text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
        @click="$emit('back')"
      >
        <Icon
          icon="i-lucide-chevron-left"
          class="mr-1 size-4 transition-transform group-hover:-translate-x-0.5"
        />
        {{ backLabel }}
      </button>
      <div class="mx-2 h-4 w-px bg-border/80" />
      <h2 class="text-base font-semibold text-foreground">
        {{ title }}
      </h2>
      <span
        v-if="stepLabel"
        class="ml-2 text-[12px] font-normal text-muted-foreground"
      >
        {{ stepLabel }}
      </span>
    </div>

    <div
      class="relative w-full shrink-0 border-b border-border/40 bg-background p-5 lg:p-6"
    >
      <div class="relative mx-auto flex max-w-3xl items-start justify-between">
        <div
          class="absolute left-[8%] right-[8%] top-4 z-0 hidden h-px bg-border/60 sm:block"
        />

        <div
          v-for="(step, index) in steps"
          :key="step.route || index"
          class="relative z-10 flex flex-1 flex-col items-center gap-2.5"
        >
          <div
            class="relative z-10 flex size-8 shrink-0 items-center justify-center rounded-full border text-[13px] font-medium transition-colors duration-200"
            :class="[
              index < activeIndex
                ? 'border-primary bg-primary font-semibold text-primary-foreground'
                : index === activeIndex
                  ? 'border-primary bg-background text-primary'
                  : 'border-border/80 bg-background text-muted-foreground',
            ]"
          >
            <div
              v-if="index === activeIndex"
              class="absolute inset-0 rounded-full bg-primary/10"
            />
            <Icon
              v-if="index < activeIndex"
              icon="i-lucide-check"
              class="relative z-10 size-4 stroke-[2.5]"
            />
            <span v-else class="relative z-10">{{ index + 1 }}</span>
          </div>

          <div class="flex flex-col text-center">
            <h4
              class="text-[13.5px] font-medium transition-colors duration-200"
              :class="
                index === activeIndex ? 'text-primary' : 'text-foreground'
              "
            >
              {{ step.title }}
            </h4>
            <p
              class="mx-auto mt-0.5 hidden max-w-[130px] text-[12px] leading-relaxed text-muted-foreground sm:block"
            >
              {{ step.body }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <div
      class="relative mx-auto flex w-full max-w-4xl flex-1 flex-col overflow-y-auto bg-background p-6 lg:p-8"
    >
      <slot />
    </div>
  </div>
</template>
