<script setup>
import { useSlots } from 'vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from '../../../../helper/featureHelper';
import BackButton from '../../../../components/widgets/BackButton.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayInput } from 'dashboard/components-next/relay';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  linkText: {
    type: String,
    default: '',
  },
  featureName: {
    type: String,
    default: '',
  },
  backButtonLabel: {
    type: String,
    default: '',
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
});

const slots = useSlots();

const searchQuery = defineModel('searchQuery', { type: String, default: '' });

const helpURL = getHelpUrlForFeature(props.featureName);
</script>

<template>
  <div class="flex w-full flex-col items-start">
    <BackButton
      v-if="backButtonLabel"
      compact
      :button-label="backButtonLabel"
      class="my-1"
    />
    <div
      v-if="title"
      class="mb-2 flex min-h-8 w-full items-center justify-between gap-4"
    >
      <h1 class="text-xl font-semibold tracking-tight text-foreground">
        {{ title }}
      </h1>
    </div>
    <div
      v-if="description || $slots.description || linkText || helpURL"
      class="flex w-full flex-col gap-1.5 text-muted-foreground"
    >
      <p
        v-if="description || $slots.description"
        class="mb-0 line-clamp-5 max-w-3xl text-sm leading-relaxed sm:line-clamp-none"
      >
        <slot name="description">{{ description }}</slot>
      </p>
      <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
        <a
          v-if="helpURL && linkText"
          :href="helpURL"
          target="_blank"
          rel="noopener noreferrer"
          class="mb-2 hidden w-fit items-center gap-1 text-sm font-medium text-primary hover:underline sm:inline-flex"
        >
          {{ linkText }}
          <Icon
            icon="i-lucide-chevron-right"
            class="size-4 flex-shrink-0 text-primary"
          />
        </a>
      </CustomBrandPolicyWrapper>
    </div>
  </div>
  <div
    v-if="searchPlaceholder || slots.actions || slots.tabs"
    class="flex min-w-0 justify-between gap-3 sm:mt-4"
  >
    <div
      v-if="slots.tabs || searchPlaceholder"
      class="flex items-center gap-3"
      :class="{
        'hidden sm:flex': !slots.tabs,
      }"
    >
      <slot name="tabs" />
      <div
        v-if="searchPlaceholder"
        class="relative hidden w-56 min-w-0 sm:block"
      >
        <Icon
          icon="i-lucide-search"
          class="pointer-events-none absolute top-1/2 size-3.5 -translate-y-1/2 text-muted-foreground ltr:left-2.5 rtl:right-2.5"
        />
        <RelayInput
          v-model="searchQuery"
          :placeholder="searchPlaceholder"
          type="search"
          class-name="h-9 w-full ltr:pl-8 rtl:pr-8"
        />
      </div>
    </div>
    <div
      class="flex min-w-0 items-center gap-3"
      :class="{ 'flex-row-reverse sm:flex-row': !slots.tabs }"
    >
      <slot name="count" />
      <div
        v-if="slots.count"
        class="mx-1 h-3 w-px flex-shrink-0 rounded-lg bg-border"
      />
      <slot name="actions" />
    </div>
  </div>
</template>
