<script setup>
import { onBeforeUnmount, ref } from 'vue';
import { RelayButton } from 'dashboard/components-next/relay';

defineProps({
  src: { type: String, required: true },
});

const playing = ref(false);
const audioRef = ref(null);

const stopOthers = audio => {
  document.querySelectorAll('audio[data-voice-sample]').forEach(node => {
    if (node !== audio) node.pause();
  });
};

const toggle = async () => {
  const audio = audioRef.value;
  if (!audio) return;
  if (playing.value) {
    audio.pause();
    return;
  }
  stopOthers(audio);
  try {
    await audio.play();
  } catch {
    playing.value = false;
  }
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
  <div>
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
      ref="audioRef"
      data-voice-sample
      :src="src"
      class="hidden"
      @play="onPlay"
      @pause="onPause"
      @ended="onPause"
    />
  </div>
</template>
