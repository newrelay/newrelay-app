<script setup>
import { ref, computed, reactive, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { required, helpers, url } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useToggle } from '@vueuse/core';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  RelayButton,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';

const props = defineProps({
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
  selectedBot: {
    type: Object,
    default: () => ({}),
  },
});

const MODAL_TYPES = {
  CREATE: 'create',
  EDIT: 'edit',
};

const DESCRIPTION_MAX = 200;

const store = useStore();
const { t } = useI18n();
const dialogRef = ref(null);
const uiFlags = useMapGetter('agentBots/getUIFlags');

const formState = reactive({
  botName: '',
  botDescription: '',
  botUrl: '',
  botAvatar: null,
  botAvatarUrl: '',
});

const [showAccessToken, toggleAccessToken] = useToggle();
const accessToken = ref('');
const botSecret = ref('');
const showTokenValue = ref(false);
const showSecretValue = ref(false);

const v$ = useVuelidate(
  {
    botName: {
      required: helpers.withMessage(
        () => t('AGENT_BOTS.FORM.ERRORS.NAME'),
        required
      ),
    },
    botUrl: {
      required: helpers.withMessage(
        () => t('AGENT_BOTS.FORM.ERRORS.URL'),
        required
      ),
      url: helpers.withMessage(
        () => t('AGENT_BOTS.FORM.ERRORS.VALID_URL'),
        url
      ),
    },
  },
  formState
);

const isLoading = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? uiFlags.value.isCreating
    : uiFlags.value.isUpdating
);

const isEdit = computed(() => props.type === MODAL_TYPES.EDIT);

const dialogWidth = computed(() => (showAccessToken.value ? 'md' : '3xl'));

const confirmButtonLabel = computed(() =>
  isEdit.value ? t('AGENT_BOTS.FORM.UPDATE') : t('AGENT_BOTS.FORM.CREATE')
);

const formTitle = computed(() =>
  isEdit.value ? t('AGENT_BOTS.EDIT.TITLE') : t('AGENT_BOTS.ADD.TITLE')
);

const botNameError = computed(() =>
  v$.value.botName.$error ? v$.value.botName.$errors[0]?.$message : ''
);

const botUrlError = computed(() =>
  v$.value.botUrl.$error ? v$.value.botUrl.$errors[0]?.$message : ''
);

const descriptionLength = computed(() => formState.botDescription.length);

const resetForm = () => {
  Object.assign(formState, {
    botName: '',
    botDescription: '',
    botUrl: '',
    botAvatar: null,
    botAvatarUrl: '',
  });
  v$.value.$reset();
};

const handleImageUpload = ({ file, url: avatarUrl }) => {
  formState.botAvatar = file;
  formState.botAvatarUrl = avatarUrl;
};

const handleAvatarDelete = async () => {
  if (props.selectedBot?.id) {
    try {
      await store.dispatch(
        'agentBots/deleteAgentBotAvatar',
        props.selectedBot.id
      );
      formState.botAvatar = null;
      formState.botAvatarUrl = '';
      useAlert(t('AGENT_BOTS.AVATAR.SUCCESS_DELETE'));
    } catch (error) {
      useAlert(t('AGENT_BOTS.AVATAR.ERROR_DELETE'));
    }
  } else {
    formState.botAvatar = null;
    formState.botAvatarUrl = '';
  }
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;
  if (showAccessToken.value) return;

  const botData = {
    name: formState.botName,
    description: formState.botDescription,
    outgoing_url: formState.botUrl,
    bot_type: 'webhook',
    avatar: formState.botAvatar,
  };

  const isCreate = props.type === MODAL_TYPES.CREATE;

  try {
    const actionPayload = isCreate
      ? botData
      : { id: props.selectedBot.id, data: botData };

    const response = await store.dispatch(
      `agentBots/${isCreate ? 'create' : 'update'}`,
      actionPayload
    );

    useAlert(
      isCreate
        ? t('AGENT_BOTS.ADD.API.SUCCESS_MESSAGE')
        : t('AGENT_BOTS.EDIT.API.SUCCESS_MESSAGE')
    );

    if (isCreate) {
      const {
        access_token: responseAccessToken,
        secret: responseSecret,
        id,
      } = response || {};

      if (id && responseAccessToken) {
        accessToken.value = responseAccessToken;
        botSecret.value = responseSecret || '';
        showTokenValue.value = false;
        showSecretValue.value = false;
        toggleAccessToken(true);
      } else {
        accessToken.value = '';
        botSecret.value = '';
        dialogRef.value.close();
      }
    } else {
      dialogRef.value.close();
    }

    resetForm();
  } catch (error) {
    useAlert(
      isCreate
        ? t('AGENT_BOTS.ADD.API.ERROR_MESSAGE')
        : t('AGENT_BOTS.EDIT.API.ERROR_MESSAGE')
    );
  }
};

const initializeForm = () => {
  if (props.selectedBot && Object.keys(props.selectedBot).length) {
    const {
      name,
      description,
      outgoing_url: botUrl,
      thumbnail,
      bot_config: botConfig,
      access_token: botAccessToken,
      secret: botSecretValue,
    } = props.selectedBot;
    formState.botName = name || '';
    formState.botDescription = description || '';
    formState.botUrl = botUrl || botConfig?.webhook_url || '';
    formState.botAvatarUrl = thumbnail || '';

    if (props.type === MODAL_TYPES.EDIT) {
      if (botAccessToken) accessToken.value = botAccessToken;
      if (botSecretValue) botSecret.value = botSecretValue;
    }
  } else {
    resetForm();
  }
};

const onCopyToken = async () => {
  await copyTextToClipboard(accessToken.value);
  useAlert(t('AGENT_BOTS.ACCESS_TOKEN.COPY_SUCCESSFUL'));
};

const onCopySecret = async () => {
  await copyTextToClipboard(botSecret.value);
  useAlert(t('AGENT_BOTS.SECRET.COPY_SUCCESS'));
};

const onResetToken = async () => {
  const response = await store.dispatch(
    'agentBots/resetAccessToken',
    props.selectedBot.id
  );
  if (response) {
    accessToken.value = response.access_token;
    useAlert(t('AGENT_BOTS.ACCESS_TOKEN.RESET_SUCCESS'));
  } else {
    useAlert(t('AGENT_BOTS.ACCESS_TOKEN.RESET_ERROR'));
  }
};

const closeModal = () => {
  if (!showAccessToken.value) v$.value?.$reset();
  accessToken.value = '';
  botSecret.value = '';
  showTokenValue.value = false;
  showSecretValue.value = false;
  toggleAccessToken(false);
};

const onClickClose = () => {
  closeModal();
  dialogRef.value.close();
};

watch(() => props.selectedBot, initializeForm, { immediate: true, deep: true });

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    title=""
    :width="dialogWidth"
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
    @close="closeModal"
  >
    <!-- Access Token (post-create) -->
    <div v-if="showAccessToken" class="flex flex-col gap-6">
      <div class="relative -mt-2 flex items-center justify-between">
        <h3 class="text-base font-semibold text-foreground">
          {{ t('AGENT_BOTS.ACCESS_TOKEN.TITLE') }}
        </h3>
        <button
          type="button"
          class="text-muted-foreground transition-colors hover:text-foreground"
          @click="onClickClose"
        >
          <Icon icon="i-lucide-x" class="size-5" />
        </button>
      </div>

      <div>
        <p class="mb-3 text-[13.5px] font-medium text-foreground">
          {{ t('AGENT_BOTS.ACCESS_TOKEN.DESCRIPTION') }}
        </p>
        <div class="flex items-center gap-2">
          <div class="relative flex-1">
            <input
              :type="showTokenValue ? 'text' : 'password'"
              :value="showTokenValue ? accessToken : '••••••••••••••••••••••••'"
              readonly
              class="h-10 w-full rounded-md border border-border/80 bg-background pl-3 pr-10 font-mono text-[14px] text-foreground shadow-sm focus:outline-none"
            />
            <button
              type="button"
              class="absolute top-1/2 p-1 text-muted-foreground transition-colors -translate-y-1/2 hover:text-foreground ltr:right-2.5 rtl:left-2.5"
              @click="showTokenValue = !showTokenValue"
            >
              <Icon
                :icon="showTokenValue ? 'i-lucide-eye-off' : 'i-lucide-eye'"
                class="size-4"
              />
            </button>
          </div>
          <RelayButton
            type="button"
            variant="outline"
            class="h-10 shrink-0 border-border/80 bg-card px-3 hover:bg-muted"
            @click="onCopyToken"
          >
            <Icon icon="i-lucide-copy" class="size-4" />
            {{ t('AGENT_BOTS.ACCESS_TOKEN.COPY') }}
          </RelayButton>
        </div>
      </div>

      <div v-if="botSecret">
        <p class="mb-3 text-[13.5px] leading-relaxed text-muted-foreground">
          {{ t('AGENT_BOTS.SECRET.CREATED_DESC') }}
        </p>
        <p class="mb-2 text-[13.5px] font-medium text-foreground">
          {{ t('AGENT_BOTS.SECRET.LABEL') }}
        </p>
        <div class="flex items-center gap-2">
          <div class="relative flex-1">
            <input
              :type="showSecretValue ? 'text' : 'password'"
              :value="showSecretValue ? botSecret : '••••••••••••••••••••••••'"
              readonly
              class="h-10 w-full rounded-md border border-border/80 bg-background pl-3 pr-10 font-mono text-[14px] text-foreground shadow-sm focus:outline-none"
            />
            <button
              type="button"
              class="absolute top-1/2 p-1 text-muted-foreground transition-colors -translate-y-1/2 hover:text-foreground ltr:right-2.5 rtl:left-2.5"
              @click="showSecretValue = !showSecretValue"
            >
              <Icon
                :icon="showSecretValue ? 'i-lucide-eye-off' : 'i-lucide-eye'"
                class="size-4"
              />
            </button>
          </div>
          <RelayButton
            type="button"
            variant="outline"
            class="h-10 shrink-0 border-border/80 bg-card px-3 hover:bg-muted"
            @click="onCopySecret"
          >
            <Icon icon="i-lucide-copy" class="size-4" />
            {{ t('AGENT_BOTS.ACCESS_TOKEN.COPY') }}
          </RelayButton>
        </div>
      </div>

      <div class="flex justify-end">
        <RelayButton
          type="button"
          variant="outline"
          class="h-10 border-border/80 bg-muted px-6 hover:bg-muted/80"
          @click="onClickClose"
        >
          {{ t('AGENT_BOTS.FORM.CANCEL') }}
        </RelayButton>
      </div>
    </div>

    <!-- Add / Edit Bot -->
    <form v-else class="flex flex-col gap-6" @submit.prevent="handleSubmit">
      <div class="relative flex items-center gap-4">
        <div
          class="flex size-12 shrink-0 items-center justify-center rounded-2xl border border-border/40 bg-[#FFEBDD]"
        >
          <Icon icon="i-lucide-bot" class="size-6 text-[#EB7A26]" />
        </div>
        <div class="min-w-0 pr-8">
          <h3 class="text-[20px] font-semibold text-foreground">
            {{ formTitle }}
          </h3>
          <p class="mt-0.5 text-[14px] text-muted-foreground">
            {{ t('AGENT_BOTS.FORM.SUBTITLE') }}
          </p>
        </div>
        <button
          type="button"
          class="absolute top-0 flex size-8 items-center justify-center rounded-full bg-muted/40 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground ltr:right-0 rtl:left-0"
          @click="onClickClose"
        >
          <Icon icon="i-lucide-x" class="size-4" />
        </button>
      </div>

      <div class="flex flex-col gap-2">
        <h4 class="text-[13.5px] font-semibold text-foreground">
          {{ t('AGENT_BOTS.FORM.AVATAR.LABEL') }}
        </h4>
        <Avatar
          :src="formState.botAvatarUrl"
          :name="formState.botName || 'Bot'"
          :size="64"
          allow-upload
          icon-name="i-lucide-bot"
          @upload="handleImageUpload"
          @delete="handleAvatarDelete"
        />
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="bot-name"
          class="text-[13.5px] font-semibold text-foreground"
        >
          {{ t('AGENT_BOTS.FORM.NAME.LABEL') }}
          <span class="text-red-500">*</span>
        </RelayLabel>
        <RelayInput
          id="bot-name"
          v-model="formState.botName"
          :placeholder="t('AGENT_BOTS.FORM.NAME.PLACEHOLDER')"
          class-name="h-10 rounded-lg border-border/80 bg-background text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30"
          @blur="v$.botName.$touch()"
        />
        <p v-if="botNameError" class="text-[12.5px] text-destructive">
          {{ botNameError }}
        </p>
        <p v-else class="mt-0.5 text-[12.5px] text-muted-foreground">
          {{ t('AGENT_BOTS.FORM.NAME.HELP') }}
        </p>
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="bot-description"
          class="text-[13.5px] font-semibold text-foreground"
        >
          {{ t('AGENT_BOTS.FORM.DESCRIPTION.LABEL') }}
        </RelayLabel>
        <div class="relative">
          <textarea
            id="bot-description"
            v-model="formState.botDescription"
            :placeholder="t('AGENT_BOTS.FORM.DESCRIPTION.PLACEHOLDER')"
            :maxlength="DESCRIPTION_MAX"
            class="h-[100px] w-full resize-none rounded-lg border border-border/80 bg-background p-3 text-[14px] text-foreground shadow-sm focus:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
          />
          <div
            class="absolute bottom-3 text-[12px] font-medium text-muted-foreground ltr:right-3 rtl:left-3"
          >
            {{ descriptionLength }} / {{ DESCRIPTION_MAX }}
          </div>
        </div>
      </div>

      <div class="flex flex-col gap-1.5">
        <RelayLabel
          html-for="bot-url"
          class="text-[13.5px] font-semibold text-foreground"
        >
          {{ t('AGENT_BOTS.FORM.WEBHOOK_URL.LABEL') }}
        </RelayLabel>
        <RelayInput
          id="bot-url"
          v-model="formState.botUrl"
          :placeholder="t('AGENT_BOTS.FORM.WEBHOOK_URL.PLACEHOLDER')"
          :class-name="
            botUrlError
              ? 'h-10 rounded-lg border-destructive/80 bg-background text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-destructive/30'
              : 'h-10 rounded-lg border-border/80 bg-background text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30'
          "
          @blur="v$.botUrl.$touch()"
        />
        <p v-if="botUrlError" class="text-[12.5px] text-destructive">
          {{ botUrlError }}
        </p>
      </div>

      <div
        v-if="isEdit"
        class="flex flex-col gap-1.5 border-t border-border/40 pt-3"
      >
        <RelayLabel class="text-[13.5px] font-semibold text-foreground">
          {{ t('AGENT_BOTS.ACCESS_TOKEN.TITLE') }}
        </RelayLabel>
        <div class="flex items-center gap-2">
          <div class="relative flex-1">
            <input
              :type="showTokenValue ? 'text' : 'password'"
              :value="showTokenValue ? accessToken : '••••••••••••••••••••••••'"
              readonly
              class="h-10 w-full rounded-lg border border-border/80 bg-background pl-3 pr-9 font-mono text-[14px] text-foreground shadow-sm focus:outline-none"
            />
            <button
              type="button"
              class="absolute top-1/2 p-1 text-muted-foreground transition-colors -translate-y-1/2 hover:text-foreground ltr:right-2 rtl:left-2"
              @click="showTokenValue = !showTokenValue"
            >
              <Icon
                :icon="showTokenValue ? 'i-lucide-eye-off' : 'i-lucide-eye'"
                class="size-4"
              />
            </button>
          </div>
          <RelayButton
            type="button"
            variant="outline"
            class="h-10 shrink-0 border-border/80 bg-card px-3 hover:bg-muted"
            @click="onCopyToken"
          >
            <Icon icon="i-lucide-copy" class="size-4" />
            {{ t('AGENT_BOTS.ACCESS_TOKEN.COPY') }}
          </RelayButton>
          <RelayButton
            type="button"
            variant="outline"
            class="h-10 shrink-0 border-border/80 bg-card px-3 text-muted-foreground hover:bg-muted"
            @click="onResetToken"
          >
            <Icon icon="i-lucide-key" class="size-4" />
            {{ t('AGENT_BOTS.ACCESS_TOKEN.RESET') }}
          </RelayButton>
        </div>
      </div>

      <div class="flex items-center justify-end gap-3 pt-2">
        <RelayButton
          type="button"
          variant="outline"
          class="h-10 rounded-lg border-border/80 bg-card px-6 font-medium text-foreground hover:bg-muted"
          @click="onClickClose"
        >
          {{ t('AGENT_BOTS.FORM.CANCEL') }}
        </RelayButton>
        <RelayButton
          type="submit"
          class="flex h-10 items-center gap-2 rounded-lg px-6 font-medium"
          :disabled="isLoading"
        >
          <Icon icon="i-lucide-wand-2" class="size-4" />
          {{ confirmButtonLabel }}
        </RelayButton>
      </div>
    </form>
  </Dialog>
</template>
