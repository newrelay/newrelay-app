<script setup>
import { ref, computed } from 'vue';
import ConfirmButton from 'dashboard/components-next/button/ConfirmButton.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

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
  <div
    class="flex flex-col sm:flex-row gap-4 items-start sm:items-center max-w-3xl mt-4"
  >
    <div class="relative flex-1 w-full">
      <RelayInput
        name="access_token"
        :type="inputType"
        :model-value="value"
        readonly
        class-name="h-10 px-4 shadow-sm bg-muted/20 cursor-not-allowed ltr:pr-10 rtl:pl-10 font-mono text-muted-foreground"
      />
      <button
        class="absolute top-1/2 -translate-y-1/2 text-muted-foreground/50 hover:text-foreground transition-colors ltr:right-3 rtl:left-3"
        type="button"
        @click="toggleMasked"
      >
        <Icon :icon="maskIcon" class="size-4" />
      </button>
    </div>
    <div class="flex items-center gap-3 w-full sm:w-auto">
      <RelayButton
        type="button"
        variant="outline"
        class="h-10 px-4 bg-background shadow-sm shrink-0 border-border/80 text-foreground min-w-[95px]"
        @click="onClick"
      >
        <Icon icon="i-lucide-copy" class="size-3.5" />
        {{ $t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.COPY') }}
      </RelayButton>
      <ConfirmButton
        v-if="showResetButton"
        :label="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.RESET')"
        :confirm-label="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.CONFIRM_RESET')"
        :confirm-hint="$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.CONFIRM_HINT')"
        color="slate"
        confirm-color="ruby"
        variant="outline"
        icon="i-lucide-key-round"
        class="h-10 px-4 shadow-sm shrink-0 w-36"
        @click="onReset"
      />
    </div>
  </div>
</template>
