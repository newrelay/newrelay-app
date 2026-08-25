<script setup>
import { ref, computed } from 'vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ConfirmButton from 'dashboard/components-next/button/ConfirmButton.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayInput } from 'dashboard/components-next/relay';

const props = defineProps({
  value: { type: String, default: '' },
  showResetButton: { type: Boolean, default: true },
});

const emit = defineEmits(['onCopy', 'onReset']);

const inputType = ref('password');

const toggleMasked = () => {
  inputType.value = inputType.value === 'password' ? 'text' : 'password';
};

const maskIcon = computed(() => {
  return inputType.value === 'password' ? 'i-lucide-eye' : 'i-lucide-eye-off';
});

const onClick = () => {
  emit('onCopy', props.value);
};

const onReset = () => {
  emit('onReset');
};
</script>

<template>
  <div class="flex flex-row justify-between gap-4">
    <div class="relative flex-1">
      <RelayInput
        name="access_token"
        :type="inputType"
        :model-value="value"
        readonly
        class-name="h-10 shadow-xs bg-background cursor-not-allowed ltr:pr-9 rtl:pl-9"
      />
      <button
        class="absolute top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground ltr:right-2.5 rtl:left-2.5"
        type="button"
        @click="toggleMasked"
      >
        <Icon :icon="maskIcon" class="size-4" />
      </button>
    </div>
    <div class="flex flex-row gap-2">
      <NextButton
        :label="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.COPY')"
        slate
        outline
        type="button"
        icon="i-lucide-copy"
        class="rounded-xl"
        @click="onClick"
      />
      <ConfirmButton
        v-if="showResetButton"
        :label="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.RESET')"
        :confirm-label="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.CONFIRM_RESET')"
        :confirm-hint="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.CONFIRM_HINT')"
        color="slate"
        confirm-color="ruby"
        variant="outline"
        icon="i-lucide-key-round"
        class="rounded-xl"
        @click="onReset"
      />
    </div>
  </div>
</template>
