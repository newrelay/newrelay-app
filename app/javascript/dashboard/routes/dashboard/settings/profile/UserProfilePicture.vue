<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import { RELAY_FORM_LABEL_CLASS } from 'dashboard/components-next/relay/form/constants';

const props = defineProps({
  src: {
    type: String,
    default: '',
  },
  name: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['change', 'delete']);
const { t } = useI18n();
const fileInput = ref(null);

const initial = computed(() => {
  const trimmed = (props.name || '').trim();
  return trimmed ? trimmed.charAt(0).toUpperCase() : '';
});

const openFilePicker = () => {
  fileInput.value?.click();
};

const handleImageUpload = event => {
  const [file] = event.target.files || [];
  if (!file) return;
  emit('change', {
    file,
    url: URL.createObjectURL(file),
  });
  event.target.value = '';
};

const deleteProfilePicture = () => {
  emit('delete');
};
</script>

<template>
  <div class="flex flex-col gap-1.5 shrink-0">
    <label :class="RELAY_FORM_LABEL_CLASS">
      {{ $t('PROFILE_SETTINGS.FORM.PICTURE') }}
    </label>
    <div class="relative size-24 mt-1">
      <img
        v-if="src"
        :src="src"
        :alt="name"
        class="size-full rounded-[20px] object-cover"
      />
      <div
        v-else
        class="size-full rounded-[20px] bg-primary/10 text-primary flex items-center justify-center text-3xl font-medium"
      >
        {{ initial }}
      </div>
      <input
        ref="fileInput"
        type="file"
        accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
        class="hidden"
        @change="handleImageUpload"
      />
      <RelayButton
        v-if="src"
        type="button"
        variant="outline"
        size="icon"
        class="absolute -top-2 -right-2 size-7 rounded-full border border-border/60 bg-background shadow-sm z-20"
        :aria-label="t('PROFILE_SETTINGS.DELETE_AVATAR')"
        @click="deleteProfilePicture"
      >
        <Icon icon="i-lucide-x" class="size-3.5" />
      </RelayButton>
      <RelayButton
        type="button"
        variant="outline"
        size="icon"
        class="absolute -bottom-2 -right-2 size-8 rounded-full border border-border/60 bg-background shadow-sm text-primary hover:text-primary/80 z-20"
        :aria-label="t('PROFILE_SETTINGS.FORM.UPLOAD_IMAGE')"
        @click="openFilePicker"
      >
        <Icon icon="i-lucide-pen-line" class="size-4" />
      </RelayButton>
    </div>
  </div>
</template>
