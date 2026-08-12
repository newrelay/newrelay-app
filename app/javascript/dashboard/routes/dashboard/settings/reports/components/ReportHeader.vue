<script setup>
import BackButton from 'dashboard/components/widgets/BackButton.vue';

defineProps({
  headerTitle: {
    required: true,
    type: String,
  },
  headerDescription: {
    type: String,
    default: '',
  },
  hasBackButton: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <section class="flex flex-col gap-1 pt-6 pb-5">
    <div v-if="hasBackButton">
      <BackButton compact />
    </div>
    <div class="flex justify-between w-full gap-5">
      <div class="flex flex-col gap-2">
        <div class="flex flex-col gap-2 items-start">
          <h2 class="text-xl font-medium text-foreground tracking-tight">
            {{ headerTitle }}
          </h2>
          <p
            v-if="headerDescription"
            class="text-[13.5px] text-muted-foreground max-w-[800px] leading-relaxed mb-0"
          >
            {{ headerDescription }}
          </p>
        </div>
      </div>
      <div class="flex-shrink-0">
        <slot />
      </div>
    </div>
  </section>
</template>
