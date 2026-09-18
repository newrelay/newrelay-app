<script setup>
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useBranding } from 'shared/composables/useBranding';

defineProps({
  greeting: { type: String, required: true },
  subtitle: { type: String, default: '' },
  continueLabel: { type: String, default: 'Continue' },
  isLoading: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
});

defineEmits(['continue']);

const { replaceInstallationName } = useBranding();
</script>

<template>
  <div
    class="relative flex flex-col min-h-screen w-full bg-background text-foreground overflow-hidden"
  >
    <!-- Ambient background accents -->
    <div
      class="fixed -bottom-32 -left-32 w-[520px] h-[520px] rounded-full bg-gradient-to-tr from-primary/[0.08] via-primary/[0.04] to-transparent pointer-events-none blur-2xl"
    />
    <div
      class="fixed top-0 right-0 w-[500px] h-[500px] bg-primary/[0.03] rounded-full blur-3xl pointer-events-none"
    />

    <div
      class="relative flex-1 w-full max-w-[1120px] mx-auto px-6 sm:px-8 lg:px-10 py-10 flex flex-col"
    >
      <div
        class="flex-1 grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-14 items-start pt-2"
      >
        <!-- Left: brand mark -->
        <aside class="lg:col-span-5 flex flex-col self-stretch">
          <div class="flex items-center gap-3">
            <div
              class="size-9 rounded-xl bg-primary text-primary-foreground flex items-center justify-center p-2 shadow-xs"
            >
              <svg class="size-full fill-current" viewBox="0 0 24 24">
                <path
                  d="M7 17a5 5 0 0 1-5-5 5 5 0 0 1 5-5c1.4 0 2.7.6 3.6 1.5L12 10l1.4-1.5A5 5 0 0 1 17 7a5 5 0 0 1 5 5 5 5 0 0 1-5 5c-1.4 0-2.7-.6-3.6-1.5L12 14l-1.4 1.5A5 5 0 0 1 7 17z"
                />
              </svg>
            </div>
            <span
              class="font-bold text-[18px] tracking-tight text-foreground leading-tight"
            >
              {{ replaceInstallationName('NewRelay') }}
            </span>
          </div>
        </aside>

        <!-- Right: form -->
        <main class="lg:col-span-7 flex flex-col w-full">
          <div class="mb-7">
            <h1
              class="text-2xl sm:text-3xl font-bold text-foreground tracking-tight capitalize"
            >
              {{ greeting }}
            </h1>
            <p v-if="subtitle" class="text-[14px] text-muted-foreground mt-1">
              {{ subtitle }}
            </p>
          </div>

          <!-- Sections -->
          <slot />

          <div class="pt-1">
            <NextButton
              type="submit"
              blue
              :is-loading="isLoading"
              :disabled="disabled"
              class="w-full h-12 rounded-xl justify-center text-[15px] font-semibold shadow-md shadow-primary/25 transition-all hover:-translate-y-0.5"
              @click="$emit('continue')"
            >
              {{ continueLabel }}
            </NextButton>
          </div>
        </main>
      </div>
    </div>
  </div>
</template>
