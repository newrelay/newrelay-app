<script setup>
import { RelayButton, RelayTooltip } from 'dashboard/components-next/relay';
import { computed } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import * as Sentry from '@sentry/vue';
import { RELAY_FORM_LABEL_CLASS } from 'dashboard/components-next/relay/form/constants';
import SiteLanguageSelect from '../account/components/SiteLanguageSelect.vue';

const props = defineProps({
  value: {
    type: String,
    required: true,
    validator: value =>
      ['ding', 'bell', 'chime', 'magic', 'ping'].includes(value),
  },
  label: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['change']);

const alertTones = computed(() => [
  {
    value: 'ding',
    label: 'Ding',
  },
  {
    value: 'bell',
    label: 'Bell',
  },
  {
    value: 'chime',
    label: 'Chime',
  },
  {
    value: 'magic',
    label: 'Magic',
  },
  {
    value: 'ping',
    label: 'Ping',
  },
]);

const selectedValue = computed({
  get: () => props.value,
  set: value => {
    emit('change', value);
  },
});

const audio = new Audio();

const playAudio = async () => {
  try {
    // Has great support https://caniuse.com/mdn-api_htmlaudioelement
    audio.src = `/audio/dashboard/${selectedValue.value}.mp3`;
    await audio.play();
  } catch (error) {
    Sentry.captureException(error);
  }
};
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <label :class="RELAY_FORM_LABEL_CLASS">
      {{ label }}
    </label>
    <div class="flex items-center gap-3">
      <div class="min-w-0 flex-1">
        <SiteLanguageSelect
          v-model="selectedValue"
          :options="alertTones"
          :show-search="false"
        />
      </div>
      <RelayTooltip
        :content="$t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.PLAY')"
        side="top"
      >
        <RelayButton
          type="button"
          variant="outline"
          size="icon"
          class="size-10 rounded-md border-border/80 shadow-sm text-muted-foreground shrink-0"
          @click="playAudio"
        >
          <Icon icon="i-lucide-volume-2" class="size-4" />
        </RelayButton>
      </RelayTooltip>
    </div>
  </div>
</template>
