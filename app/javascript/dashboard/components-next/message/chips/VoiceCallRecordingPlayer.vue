<script setup>
import {
  computed,
  onMounted,
  useTemplateRef,
  ref,
  getCurrentInstance,
} from 'vue';
import { timeStampAppendedURL } from 'dashboard/helper/URLHelper';
import { useEmitter } from 'dashboard/composables/emitter';
import { emitter } from 'shared/helpers/mitt';

const { attachment, hasRecording = true } = defineProps({
  attachment: {
    type: Object,
    default: null,
  },
  hasRecording: {
    type: Boolean,
    default: true,
  },
});

const timeStampURL = computed(() =>
  attachment?.dataUrl ? timeStampAppendedURL(attachment.dataUrl) : ''
);

const audioPlayer = useTemplateRef('audioPlayer');
const isPlaying = ref(false);
const isMuted = ref(false);
const currentTime = ref(0);
const duration = ref(0);
const playbackSpeed = ref(1);

const { uid } = getCurrentInstance();

const resolveStreamingDuration = () => {
  const el = audioPlayer.value;
  if (!el) return;
  const onTimeUpdate = () => {
    el.removeEventListener('timeupdate', onTimeUpdate);
    el.currentTime = 0;
    duration.value = el.duration;
  };
  el.addEventListener('timeupdate', onTimeUpdate);
  try {
    el.currentTime = Number.MAX_SAFE_INTEGER;
  } catch {
    el.removeEventListener('timeupdate', onTimeUpdate);
  }
};

const onLoadedMetadata = () => {
  const d = audioPlayer.value?.duration;
  if (!Number.isFinite(d)) {
    resolveStreamingDuration();
    return;
  }
  duration.value = d;
};

const playbackSpeedLabel = computed(() => `${playbackSpeed.value}x`);

const progressPercent = computed(() => {
  if (!duration.value) return 0;
  return Math.min(100, (currentTime.value / duration.value) * 100);
});

onMounted(() => {
  const d = audioPlayer.value?.duration;
  if (Number.isFinite(d)) duration.value = d;
  if (audioPlayer.value) audioPlayer.value.playbackRate = playbackSpeed.value;
});

useEmitter('pause_playing_audio', currentPlayingId => {
  if (currentPlayingId !== uid && isPlaying.value) {
    try {
      audioPlayer.value?.pause();
    } catch {
      /* ignore */
    }
    isPlaying.value = false;
  }
});

const formatTime = time => {
  if (!time || Number.isNaN(time)) return '0:00';
  const minutes = Math.floor(time / 60);
  const seconds = Math.floor(time % 60);
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
};

const toggleMute = () => {
  if (!hasRecording || !audioPlayer.value) return;
  audioPlayer.value.muted = !audioPlayer.value.muted;
  isMuted.value = audioPlayer.value.muted;
};

const onTimeUpdate = () => {
  currentTime.value = audioPlayer.value?.currentTime || 0;
};

const seekFromClick = event => {
  if (!hasRecording) return;
  const el = event.currentTarget;
  if (!audioPlayer.value || !duration.value) return;
  const rect = el.getBoundingClientRect();
  const ratio = Math.min(
    1,
    Math.max(0, (event.clientX - rect.left) / rect.width)
  );
  const time = ratio * duration.value;
  audioPlayer.value.currentTime = time;
  currentTime.value = time;
};

const playOrPause = () => {
  if (!hasRecording || !audioPlayer.value) return;
  if (isPlaying.value) {
    audioPlayer.value.pause();
    isPlaying.value = false;
    return;
  }
  emitter.emit('pause_playing_audio', uid);
  audioPlayer.value.play();
  isPlaying.value = true;
};

const onEnd = () => {
  isPlaying.value = false;
  currentTime.value = 0;
  playbackSpeed.value = 1;
  if (audioPlayer.value) audioPlayer.value.playbackRate = 1;
};

const changePlaybackSpeed = () => {
  if (!hasRecording) return;
  const speeds = [1, 1.5, 2, 0.5];
  const currentIndex = speeds.indexOf(playbackSpeed.value);
  const nextIndex = (currentIndex + 1) % speeds.length;
  playbackSpeed.value = speeds[nextIndex];
  if (audioPlayer.value) audioPlayer.value.playbackRate = playbackSpeed.value;
};
</script>

<template>
  <div>
    <audio
      v-if="hasRecording && timeStampURL"
      ref="audioPlayer"
      class="hidden"
      playsinline
      @loadedmetadata="onLoadedMetadata"
      @timeupdate="onTimeUpdate"
      @ended="onEnd"
    >
      <source :src="timeStampURL" />
    </audio>

    <div
      class="flex items-center gap-4 rounded-xl border border-border/50 bg-muted/30 px-4 py-2.5"
      :class="{ 'opacity-60': !hasRecording }"
    >
      <button
        type="button"
        class="flex size-8 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-sm transition-colors hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-50"
        :disabled="!hasRecording"
        @click="playOrPause"
      >
        <span v-if="isPlaying" class="i-lucide-pause size-4" />
        <span v-else class="i-lucide-play size-4 ml-0.5" />
      </button>

      <div
        class="group relative h-1.5 flex-1 overflow-hidden rounded-full bg-border"
        :class="hasRecording ? 'cursor-pointer' : 'cursor-default'"
        @click="seekFromClick"
      >
        <div
          class="absolute bottom-0 left-0 top-0 rounded-full bg-primary transition-[width]"
          :style="{ width: `${progressPercent}%` }"
        />
        <div
          class="absolute top-1/2 size-3 -translate-y-1/2 rounded-full border border-primary/20 bg-background opacity-0 shadow-sm transition-opacity group-hover:opacity-100"
          :style="{ left: `calc(${progressPercent}% - 6px)` }"
        />
      </div>

      <span
        class="w-8 shrink-0 text-right text-[11px] font-medium text-muted-foreground"
      >
        {{ formatTime(currentTime) }}
      </span>

      <div class="flex items-center gap-1.5 border-l border-border/50 pl-3">
        <button
          type="button"
          class="w-9 rounded px-1.5 py-1 text-center text-[11px] font-semibold text-primary transition-colors hover:bg-primary/10 disabled:cursor-not-allowed disabled:opacity-50"
          :disabled="!hasRecording"
          @click="changePlaybackSpeed"
        >
          {{ playbackSpeedLabel }}
        </button>
        <button
          type="button"
          class="flex size-7 items-center justify-center rounded text-muted-foreground transition-colors hover:bg-muted hover:text-foreground disabled:cursor-not-allowed disabled:opacity-50"
          :disabled="!hasRecording"
          @click="toggleMute"
        >
          <span
            class="size-3.5"
            :class="isMuted ? 'i-lucide-volume-x' : 'i-lucide-volume-2'"
          />
        </button>
      </div>
    </div>
  </div>
</template>
