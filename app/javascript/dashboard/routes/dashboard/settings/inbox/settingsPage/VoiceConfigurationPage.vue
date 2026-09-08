<script>
import { useAlert } from 'dashboard/composables';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import { RelayInput, RelayLabel } from 'dashboard/components-next/relay';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    SettingsFieldSection,
    SettingsToggleSection,
    RelayInput,
    RelayLabel,
    NextButton,
  },
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      voiceEnabled: this.inbox.voice_enabled || false,
      apiKeySid: this.inbox.api_key_sid || '',
      apiKeySecret: '',
      isUpdating: false,
    };
  },
  computed: {
    isVoiceConfigured() {
      return !!this.inbox.voice_configured;
    },
    hasApiKeySid() {
      return !!this.inbox.api_key_sid;
    },
    hasExistingCredentials() {
      return this.hasApiKeySid && !!this.inbox.has_api_key_secret;
    },
    needsCredentials() {
      return (
        this.voiceEnabled &&
        !this.isVoiceConfigured &&
        !this.hasExistingCredentials
      );
    },
    needsApiKeySid() {
      return this.needsCredentials && !this.hasApiKeySid;
    },
    isSubmitDisabled() {
      if (!this.voiceEnabled) return false;
      if (this.needsCredentials) {
        if (this.needsApiKeySid && !this.apiKeySid) return true;
        return !this.apiKeySecret;
      }
      return false;
    },
  },
  watch: {
    'inbox.voice_enabled'(val) {
      this.voiceEnabled = val || false;
    },
    'inbox.api_key_sid'(val) {
      this.apiKeySid = val || '';
    },
  },
  methods: {
    async updateVoiceSettings() {
      this.isUpdating = true;
      try {
        const channelPayload = { voice_enabled: this.voiceEnabled };

        if (this.needsCredentials) {
          if (this.needsApiKeySid) {
            channelPayload.api_key_sid = this.apiKeySid;
          }
          channelPayload.api_key_secret = this.apiKeySecret;
        }

        await this.$store.dispatch('inboxes/updateInbox', {
          id: this.inbox.id,
          formData: false,
          channel: channelPayload,
        });
        this.apiKeySecret = '';
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-6">
    <SettingsToggleSection
      v-model="voiceEnabled"
      :header="$t('INBOX_MGMT.VOICE_CONFIGURATION.ENABLE_VOICE.LABEL')"
      :description="
        $t('INBOX_MGMT.VOICE_CONFIGURATION.ENABLE_VOICE.DESCRIPTION')
      "
    />

    <div v-if="voiceEnabled && needsCredentials" class="flex flex-col gap-4">
      <p class="text-sm text-muted-foreground">
        {{ $t('INBOX_MGMT.VOICE_CONFIGURATION.CREDENTIALS.DESCRIPTION') }}
      </p>
      <div v-if="needsApiKeySid" class="flex flex-col gap-1.5">
        <RelayLabel class="text-[13.5px] font-medium text-foreground">
          {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.LABEL') }}
        </RelayLabel>
        <RelayInput
          v-model="apiKeySid"
          :placeholder="
            $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.PLACEHOLDER')
          "
          class-name="h-9 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
        />
      </div>
      <div class="flex flex-col gap-1.5">
        <RelayLabel class="text-[13.5px] font-medium text-foreground">
          {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.LABEL') }}
        </RelayLabel>
        <RelayInput
          v-model="apiKeySecret"
          type="password"
          :placeholder="
            $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.PLACEHOLDER')
          "
          class-name="h-9 px-4 text-[14px] shadow-sm rounded-md border-border/80 bg-background focus-visible:ring-1 focus-visible:ring-primary/30"
        />
      </div>
    </div>

    <div v-if="inbox.voice_enabled && inbox.voice_call_webhook_url">
      <SettingsFieldSection
        :label="$t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_VOICE_URL_TITLE')"
        :help-text="
          $t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_VOICE_URL_SUBTITLE')
        "
      >
        <woot-code :script="inbox.voice_call_webhook_url" lang="html" />
      </SettingsFieldSection>
      <SettingsFieldSection
        :label="
          $t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_STATUS_URL_TITLE')
        "
        :help-text="
          $t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_STATUS_URL_SUBTITLE')
        "
      >
        <woot-code :script="inbox.voice_status_webhook_url" lang="html" />
      </SettingsFieldSection>
    </div>

    <div>
      <NextButton
        :disabled="isSubmitDisabled"
        :is-loading="isUpdating"
        :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
        @click="updateVoiceSettings"
      />
    </div>
  </div>
</template>
