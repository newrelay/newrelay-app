<script setup>
import { onBeforeUnmount, onMounted, ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ElevenlabsVoicesAPI from 'dashboard/api/elevenlabsVoices';
import VoiceSample from 'dashboard/components-next/voice/VoiceSample.vue';
import {
  RelayButton,
  RelayCheckbox,
  RelayInput,
  RelayLabel,
  RelayTextarea,
} from 'dashboard/components-next/relay';

const MAX_RECORD_SECONDS = 60;
const { t } = useI18n();
const connected = ref(true);
const voices = ref([]);
const name = ref('');
const tone = ref('');
const persona = ref('');
const consent = ref(false);
const clip = ref(null);
const fileInput = ref(null);
const isCreating = ref(false);
const recording = ref(false);
const recordSeconds = ref(0);
let pollTimer = null;
let recordTimer = null;
let audioContext = null;
let processor = null;
let micStream = null;
let recordChunks = [];
let stoppingRecording = false;

const canCreate = computed(
  () =>
    connected.value &&
    name.value.trim() &&
    consent.value &&
    clip.value &&
    !isCreating.value &&
    !recording.value
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

const mergeSamples = chunks => {
  const length = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
  const samples = new Float32Array(length);
  let offset = 0;
  chunks.forEach(chunk => {
    samples.set(chunk, offset);
    offset += chunk.length;
  });
  return samples;
};

const encodeWav = (samples, sampleRate) => {
  const buffer = new ArrayBuffer(44 + samples.length * 2);
  const view = new DataView(buffer);
  const write = (offset, value) => {
    for (let index = 0; index < value.length; index += 1) {
      view.setUint8(offset + index, value.charCodeAt(index));
    }
  };
  write(0, 'RIFF');
  view.setUint32(4, 36 + samples.length * 2, true);
  write(8, 'WAVE');
  write(12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, 1, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * 2, true);
  view.setUint16(32, 2, true);
  view.setUint16(36, 16, true);
  write(40, 'data');
  view.setUint32(44, samples.length * 2, true);
  let offset = 44;
  samples.forEach(sample => {
    const clamped = Math.max(-1, Math.min(1, sample));
    view.setInt16(
      offset,
      clamped < 0 ? clamped * 0x8000 : clamped * 0x7fff,
      true
    );
    offset += 2;
  });
  return new Blob([buffer], { type: 'audio/wav' });
};

const releaseMic = async () => {
  processor?.disconnect();
  micStream?.getTracks().forEach(track => track.stop());
  const rate = audioContext?.sampleRate || 44100;
  const samples = mergeSamples(recordChunks);
  if (audioContext) await audioContext.close();
  processor = null;
  micStream = null;
  audioContext = null;
  recordChunks = [];
  return { samples, rate };
};

const finishRecording = async () => {
  if (stoppingRecording || !micStream) return;
  stoppingRecording = true;
  clearInterval(recordTimer);
  recordTimer = null;
  recording.value = false;
  try {
    const { samples, rate } = await releaseMic();
    recordSeconds.value = 0;
    if (!samples.length) return;
    clip.value = new File([encodeWav(samples, rate)], 'recording.wav', {
      type: 'audio/wav',
    });
    if (fileInput.value) fileInput.value.value = '';
  } finally {
    stoppingRecording = false;
  }
};

const startRecording = async () => {
  micStream = await navigator.mediaDevices.getUserMedia({ audio: true });
  // ponytail: ScriptProcessor is deprecated; upgrade path is an AudioWorklet that emits the same Float32 chunks.
  audioContext = new AudioContext();
  const source = audioContext.createMediaStreamSource(micStream);
  const silent = audioContext.createGain();
  silent.gain.value = 0;
  processor = audioContext.createScriptProcessor(4096, 1, 1);
  recordChunks = [];
  processor.onaudioprocess = event => {
    recordChunks.push(new Float32Array(event.inputBuffer.getChannelData(0)));
  };
  source.connect(processor);
  processor.connect(silent);
  silent.connect(audioContext.destination);
  recording.value = true;
  recordSeconds.value = 0;
  recordTimer = setInterval(() => {
    recordSeconds.value += 1;
    if (recordSeconds.value >= MAX_RECORD_SECONDS) finishRecording();
  }, 1000);
};

const toggleRecording = async () => {
  if (recording.value) {
    await finishRecording();
    return;
  }
  try {
    await startRecording();
  } catch {
    useAlert(t('INBOX_MGMT.VOICES.MIC_DENIED'));
  }
};

const createVoice = async () => {
  if (!canCreate.value) return;
  isCreating.value = true;
  const form = new FormData();
  form.append('name', name.value.trim());
  form.append('tone', tone.value.trim());
  form.append('persona', persona.value.trim());
  form.append('consent', 'true');
  form.append('clip', clip.value);
  try {
    await ElevenlabsVoicesAPI.createVoice(form);
    name.value = '';
    tone.value = '';
    persona.value = '';
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
  if (recording.value) releaseMic();
  clearInterval(recordTimer);
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
        <RelayLabel html-for="voice-tone">
          {{ $t('INBOX_MGMT.VOICES.TONE') }}
        </RelayLabel>
        <RelayInput id="voice-tone" v-model="tone" maxlength="80" />
      </div>
      <div class="flex flex-col gap-1.5">
        <RelayLabel html-for="voice-persona">
          {{ $t('INBOX_MGMT.VOICES.PERSONA') }}
        </RelayLabel>
        <RelayTextarea
          id="voice-persona"
          v-model="persona"
          rows="3"
          maxlength="500"
        />
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
        <RelayButton
          type="button"
          variant="ghost"
          class="w-fit border border-border hover:border-transparent"
          @click="toggleRecording"
        >
          {{
            recording
              ? $t('INBOX_MGMT.VOICES.STOP_RECORDING')
              : $t('INBOX_MGMT.VOICES.RECORD')
          }}
          <span v-if="recording">
            {{
              $t('INBOX_MGMT.VOICES.RECORDING_TIME', { seconds: recordSeconds })
            }}
          </span>
        </RelayButton>
        <p v-if="clip" class="text-[13px] text-muted-foreground">
          {{ clip.name }}
        </p>
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
          <span
            v-if="voice.tone || voice.persona || voice.traits"
            class="text-[13px] text-muted-foreground"
          >
            {{
              [voice.tone, voice.persona, voice.traits]
                .filter(Boolean)
                .join(' · ')
            }}
          </span>
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
        <VoiceSample v-if="voice.preview_url" :src="voice.preview_url" />
      </li>
    </ul>
  </div>
</template>
