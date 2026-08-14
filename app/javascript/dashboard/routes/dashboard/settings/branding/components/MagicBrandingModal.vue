<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import NextModal from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import NextInput from 'dashboard/components-next/input/Input.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  show: { type: Boolean, default: false },
});

const emit = defineEmits(['close', 'apply']);
const { t } = useI18n();
const { accountId } = useAccount();

const dialogRef = ref(null);
const activeTab = ref('url'); // 'url', 'prompt', 'image'
const urlInput = ref('');
const promptInput = ref('');
const imageInput = ref(null);
const imagePreview = ref(null);
const imageBase64 = ref(null);

const isLoading = ref(false);
const options = ref([]);
const selectedOption = ref(null);
const fileInputRef = ref(null);

const tabs = [
  {
    id: 'url',
    label: t('BRANDING_SETTINGS.MAGIC_AI.TABS.URL'),
    icon: 'i-lucide-globe',
  },
  {
    id: 'prompt',
    label: t('BRANDING_SETTINGS.MAGIC_AI.TABS.PROMPT'),
    icon: 'i-lucide-sparkles',
  },
  {
    id: 'image',
    label: t('BRANDING_SETTINGS.MAGIC_AI.TABS.IMAGE'),
    icon: 'i-lucide-image',
  },
];

const resetState = () => {
  urlInput.value = '';
  promptInput.value = '';
  imageInput.value = null;
  imagePreview.value = null;
  imageBase64.value = null;
  options.value = [];
  selectedOption.value = null;
};

const handleClose = () => {
  emit('close');
  setTimeout(() => {
    resetState();
  }, 300);
};

const resizeImage = file => {
  return new Promise(resolve => {
    const reader = new FileReader();
    reader.onload = e => {
      const img = new Image();
      img.onload = () => {
        const canvas = document.createElement('canvas');
        const MAX_WIDTH = 512;
        const MAX_HEIGHT = 512;
        let { width, height } = img;

        if (width > height) {
          if (width > MAX_WIDTH) {
            height = Math.round((height * MAX_WIDTH) / width);
            width = MAX_WIDTH;
          }
        } else if (height > MAX_HEIGHT) {
          width = Math.round((width * MAX_HEIGHT) / height);
          height = MAX_HEIGHT;
        }

        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, width, height);
        resolve(canvas.toDataURL(file.type || 'image/jpeg', 0.8));
      };
      img.src = e.target.result;
    };
    reader.readAsDataURL(file);
  });
};

const onImageChange = async event => {
  const [file] = event.target.files;
  if (!file) return;

  imageInput.value = file;
  imagePreview.value = URL.createObjectURL(file);

  try {
    imageBase64.value = await resizeImage(file);
  } catch (error) {
    useAlert(t('BRANDING_SETTINGS.MAGIC_AI.ERROR'));
  }
};

const generatePalettes = async () => {
  isLoading.value = true;
  options.value = [];
  selectedOption.value = null;

  try {
    const payload = {};
    if (activeTab.value === 'url') payload.url = urlInput.value;
    else if (activeTab.value === 'prompt') payload.prompt = promptInput.value;
    else if (activeTab.value === 'image') payload.image = imageBase64.value;

    const response = await window.axios.post(
      `/api/v1/accounts/${accountId.value}/captain/branding`,
      payload
    );
    options.value = response.data.options || [];
  } catch (error) {
    useAlert(
      error.response?.data?.error || t('BRANDING_SETTINGS.MAGIC_AI.ERROR')
    );
  } finally {
    isLoading.value = false;
  }
};

const applyPalette = () => {
  if (selectedOption.value) {
    emit('apply', selectedOption.value);
    handleClose();
  }
};

watch(
  () => props.show,
  newVal => {
    if (newVal) {
      dialogRef.value?.open();
    } else {
      dialogRef.value?.close();
    }
  }
);
</script>

<template>
  <NextModal
    ref="dialogRef"
    :title="t('BRANDING_SETTINGS.MAGIC_AI.TITLE')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    width="md"
    @close="handleClose"
  >
    <div
      class="flex flex-col gap-5 mt-4 overflow-y-auto max-h-[65vh] pr-2 -mr-2"
    >
      <div class="flex items-center gap-1 p-1 bg-card rounded-lg">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          class="flex-1 flex items-center justify-center gap-2 py-1.5 text-xs font-medium rounded-md transition-colors"
          :class="[
            activeTab === tab.id
              ? 'bg-muted text-foreground shadow-sm border border-border'
              : 'text-muted-foreground hover:text-foreground hover:bg-black/10',
          ]"
          @click="activeTab = tab.id"
        >
          <span :class="tab.icon" class="size-4" />
          {{ tab.label }}
        </button>
      </div>

      <div class="flex flex-col gap-4">
        <template v-if="activeTab === 'url'">
          <NextInput
            v-model="urlInput"
            type="url"
            :placeholder="t('BRANDING_SETTINGS.MAGIC_AI.URL_PLACEHOLDER')"
            class="w-full"
          />
        </template>

        <template v-else-if="activeTab === 'prompt'">
          <textarea
            v-model="promptInput"
            :placeholder="t('BRANDING_SETTINGS.MAGIC_AI.PROMPT_PLACEHOLDER')"
            class="w-full min-h-[100px] p-3 bg-black/10 border-none outline outline-1 outline-border outline-offset-[-1px] focus:outline-primary text-foreground placeholder:text-muted-foreground text-[14px] border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30 shadow-sm rounded-md"
          />
        </template>

        <template v-else-if="activeTab === 'image'">
          <div
            class="flex flex-col items-center justify-center p-6 border border-dashed border-border rounded-xl bg-card text-center"
          >
            <img
              v-if="imagePreview"
              :src="imagePreview"
              class="max-h-32 object-contain mb-4 rounded-lg"
            />
            <div
              v-else
              class="w-16 h-16 rounded-full bg-muted border border-border flex items-center justify-center mb-4"
            >
              <span class="i-lucide-image text-muted-foreground size-6" />
            </div>
            <input
              ref="fileInputRef"
              type="file"
              accept="image/*"
              class="hidden text-[14px] border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30 shadow-sm rounded-md"
              @change="onImageChange"
            />
            <NextButton
              blue
              size="small"
              type="button"
              @click="$refs.fileInputRef.click()"
            >
              {{
                imagePreview
                  ? t('BRANDING_SETTINGS.MAGIC_AI.CHANGE_IMAGE')
                  : t('BRANDING_SETTINGS.MAGIC_AI.UPLOAD_IMAGE')
              }}
            </NextButton>
          </div>
        </template>

        <NextButton
          blue
          class="w-full"
          :is-loading="isLoading"
          :disabled="(!urlInput && !promptInput && !imageBase64) || isLoading"
          @click="generatePalettes"
        >
          {{ t('BRANDING_SETTINGS.MAGIC_AI.GENERATE') }}
        </NextButton>
      </div>

      <div
        v-if="options.length > 0"
        class="flex flex-col gap-3 mt-2 pt-5 border-t border-border"
      >
        <h4 class="capitalize text-sm font-semibold text-foreground">
          {{ t('BRANDING_SETTINGS.MAGIC_AI.RESULTS') }}
        </h4>
        <div class="grid grid-cols-1 gap-3">
          <div
            v-for="(option, index) in options"
            :key="index"
            class="flex items-center justify-between p-3 rounded-xl border cursor-pointer transition-all"
            :class="[
              selectedOption === option
                ? 'border-primary bg-primary/5 ring-1 ring-primary/20'
                : 'border-border bg-muted hover:border-border',
            ]"
            @click="selectedOption = option"
          >
            <div class="flex items-center gap-4">
              <div class="flex -space-x-2">
                <div
                  class="w-8 h-8 rounded-full border-2 border-muted shadow-sm"
                  :style="{ backgroundColor: option.primary }"
                />
                <div
                  class="w-8 h-8 rounded-full border-2 border-muted shadow-sm"
                  :style="{ backgroundColor: option.background }"
                />
                <div
                  class="w-8 h-8 rounded-full border-2 border-muted shadow-sm"
                  :style="{ backgroundColor: option.text }"
                />
              </div>
              <div class="flex flex-col">
                <span class="text-sm font-medium text-foreground">{{
                  option.name
                }}</span>
                <span
                  class="text-xs text-muted-foreground uppercase font-mono"
                  >{{ option.primary }}</span
                >
              </div>
            </div>
            <span
              v-if="selectedOption === option"
              class="i-lucide-check-circle-2 text-primary size-5"
            />
          </div>
        </div>

        <NextButton
          blue
          class="w-full mt-2"
          :disabled="!selectedOption"
          @click="applyPalette"
        >
          {{ t('BRANDING_SETTINGS.MAGIC_AI.APPLY') }}
        </NextButton>
      </div>
    </div>
  </NextModal>
</template>
