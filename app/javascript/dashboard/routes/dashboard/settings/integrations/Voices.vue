<script setup>
import { onBeforeUnmount, onMounted, ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ElevenlabsVoicesAPI from 'dashboard/api/elevenlabsVoices';
import {
  RelayButton,
  RelayCheckbox,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';

const { t } = useI18n();
const connected = ref(true);
const voices = ref([]);
const name = ref('');
const consent = ref(false);
const clip = ref(null);
const fileInput = ref(null);
const isCreating = ref(false);
let pollTimer = null;

const canCreate = computed(
  () =>
    connected.value &&
    name.value.trim() &&
    consent.value &&
    clip.value &&
    !isCreating.value
);

const loadVoices = async () => {
  try {
    const { data } = await ElevenlabsVoicesAPI.get();
    connected.value = data.connected !== false;
    voices.value = data.voices || [];
  } catch {
    connected.value = false;
    voices.value = [];
  }
  if (voices.value.some(voice => voice.status === 'pending')) {
    pollTimer = pollTimer || setInterval(loadVoices, 3000);
  } else if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
};

const onFile = event => {
  clip.value = event.target.files?.[0] || null;
};

const play = url => {
  if (!url) return;
  const audio = new Audio(url);
  audio.play();
};

const createVoice = async () => {
  if (!canCreate.value) return;
  isCreating.value = true;
  const form = new FormData();
  form.append('name', name.value.trim());
  form.append('consent', 'true');
  form.append('clip', clip.value);
  try {
    await ElevenlabsVoicesAPI.createVoice(form);
    name.value = '';
    consent.value = false;
    clip.value = null;
    if (fileInput.value) fileInput.value.value = '';
    useAlert(t('INBOX_MGMT.VOICES.CREATING'));
    await loadVoices();
  } catch (error) {
    useAlert(error?.response?.data?.error || t('INBOX_MGMT.VOICES.FAILED'));
  } finally {
    isCreating.value = false;
  }
};

onMounted(loadVoices);
onBeforeUnmount(() => {
  if (pollTimer) clearInterval(pollTimer);
});
</script>

<template>
  <div class="flex flex-col gap-6 p-6">
    <div class="flex flex-col gap-1">
      <h1 class="text-base font-medium text-foreground">
        {{ $t('INBOX_MGMT.VOICES.TITLE') }}
      </h1>
      <p class="text-[14px] font-normal text-muted-foreground">
        {{ $t('INBOX_MGMT.VOICES.DESCRIPTION') }}
      </p>
    </div>

    <p v-if="!connected" class="text-[14px] text-muted-foreground">
      {{ $t('INBOX_MGMT.ELEVENLABS.MISSING_KEY') }}
    </p>

    <form
      v-else
      class="flex max-w-xl flex-col gap-4"
      @submit.prevent="createVoice"
    >
      <div class="flex flex-col gap-1.5">
        <RelayLabel html-for="voice-name">
          {{ $t('INBOX_MGMT.VOICES.NAME') }}
        </RelayLabel>
        <RelayInput id="voice-name" v-model="name" />
      </div>
      <div class="flex flex-col gap-1.5">
        <RelayLabel html-for="voice-clip">
          {{ $t('INBOX_MGMT.VOICES.CLIP') }}
        </RelayLabel>
        <input
          id="voice-clip"
          ref="fileInput"
          type="file"
          accept="audio/mpeg,audio/wav,.mp3,.wav"
          class="text-[14px] text-foreground"
          @change="onFile"
        />
      </div>
      <div
        class="flex items-center gap-3 text-[13.5px] font-medium text-foreground"
        @click="consent = !consent"
      >
        <RelayCheckbox v-model="consent" />
        {{ $t('INBOX_MGMT.VOICES.CONSENT') }}
      </div>
      <RelayButton type="submit" :disabled="!canCreate">
        {{ $t('INBOX_MGMT.VOICES.CREATE') }}
      </RelayButton>
    </form>

    <ul v-if="connected" class="flex flex-col gap-2">
      <li
        v-for="voice in voices"
        :key="voice.voice_id || voice.name"
        class="flex items-center justify-between gap-3 rounded-md border border-border px-3 py-2"
      >
        <div class="flex flex-col">
          <span class="text-[14px] text-foreground">{{ voice.name }}</span>
          <span class="text-[13px] text-muted-foreground">
            {{
              voice.status === 'pending' ? $t('INBOX_MGMT.VOICES.PENDING') : ''
            }}
            {{
              voice.requires_verification
                ? $t('INBOX_MGMT.VOICES.UNVERIFIED')
                : ''
            }}
            {{ voice.error_message || '' }}
          </span>
        </div>
        <RelayButton
          v-if="voice.preview_url"
          variant="ghost"
          class="border border-border hover:border-transparent"
          type="button"
          @click="play(voice.preview_url)"
        >
          {{ $t('INBOX_MGMT.VOICES.PLAY') }}
        </RelayButton>
      </li>
    </ul>
  </div>
</template>
