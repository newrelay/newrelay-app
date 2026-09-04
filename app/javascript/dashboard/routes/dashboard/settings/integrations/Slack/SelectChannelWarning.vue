<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { RelayButton } from 'dashboard/components-next/relay';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  hasConnectedAChannel: {
    type: Boolean,
    default: true,
  },
});

const store = useStore();
const { t } = useI18n();

const { formatMessage } = useMessageFormatter();
const { replaceInstallationName } = useBranding();

const selectedChannelId = ref('');
const availableChannels = ref([]);

const uiFlags = computed(() => store.getters['integrations/getUIFlags']);

const errorDescription = computed(() => {
  return !props.hasConnectedAChannel
    ? t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.DESCRIPTION')
    : t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.EXPIRED');
});

const formattedErrorMessage = computed(() => {
  return formatMessage(replaceInstallationName(errorDescription.value), false);
});

const fetchChannels = async () => {
  try {
    availableChannels.value = await store.dispatch(
      'integrations/listAllSlackChannels'
    );
    availableChannels.value.sort((c1, c2) => c1.name - c2.name);
  } catch {
    t('INTEGRATION_SETTINGS.SLACK.FAILED_TO_FETCH_CHANNELS');
    availableChannels.value = [];
  }
};

const updateIntegration = async () => {
  try {
    await store.dispatch('integrations/updateSlack', {
      referenceId: selectedChannelId.value,
    });
    useAlert(t('INTEGRATION_SETTINGS.SLACK.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(error.message || 'INTEGRATION_SETTINGS.SLACK.UPDATE_ERROR');
  }
};
</script>

<template>
  <div
    class="mb-4 rounded-xl border border-warning/30 bg-warning/5 px-6 py-4 shadow-xs"
  >
    <div class="flex">
      <div class="shrink-0">
        <Icon icon="i-lucide-bell" class="mt-1 size-5 text-warning" />
      </div>
      <div class="ml-3">
        <p class="mb-1 text-sm font-medium text-foreground">
          {{
            $t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.ATTENTION_REQUIRED')
          }}
        </p>
        <div class="mb-3 mt-2 text-[13.5px] text-muted-foreground">
          <p v-dompurify-html="formattedErrorMessage" />
        </div>
      </div>
    </div>
    <div v-if="!hasConnectedAChannel" class="ml-8 mt-1">
      <RelayButton
        v-if="!availableChannels.length"
        variant="outline"
        size="sm"
        class="h-8 border-warning/40 text-[13px]"
        :disabled="uiFlags.isFetchingSlackChannels"
        @click="fetchChannels"
      >
        <Icon
          v-if="uiFlags.isFetchingSlackChannels"
          icon="i-lucide-loader-2"
          class="size-3.5 animate-spin"
        />
        {{ $t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.BUTTON_TEXT') }}
      </RelayButton>
      <div v-else class="inline-flex items-center gap-3">
        <select
          v-model="selectedChannelId"
          class="h-8 rounded-md border border-warning/40 bg-background px-2 text-xs leading-4 text-foreground shadow-xs"
        >
          <option value="">
            {{ $t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.OPTION_LABEL') }}
          </option>
          <option
            v-for="channel in availableChannels"
            :key="channel.id"
            :value="channel.id"
          >
            #{{ channel.name }}
          </option>
        </select>
        <RelayButton
          size="sm"
          class="h-8 text-[13px]"
          :disabled="uiFlags.isUpdatingSlack"
          @click="updateIntegration"
        >
          <Icon
            v-if="uiFlags.isUpdatingSlack"
            icon="i-lucide-loader-2"
            class="size-3.5 animate-spin"
          />
          {{ $t('INTEGRATION_SETTINGS.SLACK.SELECT_CHANNEL.UPDATE') }}
        </RelayButton>
      </div>
    </div>
  </div>
</template>
