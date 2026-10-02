<script setup>
import { nextTick, onBeforeUnmount, ref } from 'vue';
import { RelayButton } from 'dashboard/components-next/relay';

defineProps({
  src: { type: String, required: true },
});

const started = ref(false);
const playing = ref(false);
const audioRef = ref(null);

const stopOthers = audio => {
  document.querySelectorAll('audio[data-voice-sample]').forEach(node => {
    if (node !== audio) node.pause();
  });
};

const toggle = async () => {
  if (playing.value) {
    audioRef.value?.pause();
    return;
  }
  started.value = true;
  await nextTick();
  const audio = audioRef.value;
  if (!audio) return;
  stopOthers(audio);
  audio.play();
};

const onPlay = () => {
  playing.value = true;
};

const onPause = () => {
  playing.value = false;
};

onBeforeUnmount(() => {
  audioRef.value?.pause();
});
</script>

<template>
  <div class="flex min-w-[220px] flex-col items-stretch gap-2">
    <RelayButton
      variant="ghost"
      size="sm"
      type="button"
      class="border border-border hover:border-transparent"
      @click="toggle"
    >
      {{
        playing ? $t('INBOX_MGMT.VOICES.STOP') : $t('INBOX_MGMT.VOICES.PLAY')
      }}
    </RelayButton>
    <audio
      v-if="started"
      ref="audioRef"
      data-voice-sample
      :src="src"
      controls
      class="h-8 w-full"
      @play="onPlay"
      @pause="onPause"
      @ended="onPause"
    />
  </div>
</template>
