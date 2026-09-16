<template>
  <div class="relative flex mt-1">
    <div class="flex items-center gap-1">
      <fluent-icon icon="wand" size="14" class="text-primary" />
      <label class="text-primary ltr:mr-1 rtl:ml-1 inline-block">
        {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.AI_WRITING') }}
      </label>
    </div>
    <span
      class="bg-primary inline-block size-1.5 ltr:mr-1 rtl:ml-1 mt-3 rounded-full animate-bubble-scale"
    />
    <span
      class="bg-primary inline-block size-1.5 ltr:mr-1 rtl:ml-1 mt-3 rounded-full animate-bubble-scale [animation-delay:0.4s]"
    />
    <span
      class="bg-primary inline-block size-1.5 ltr:mr-1 rtl:ml-1 mt-3 rounded-full animate-bubble-scale [animation-delay:0.8s]"
    />
  </div>
</template>
