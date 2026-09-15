<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useFontSize } from 'dashboard/composables/useFontSize';
import { useBranding } from 'shared/composables/useBranding';
import { clearCookiesOnLogout } from 'dashboard/store/utils/api.js';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import UserProfilePicture from './UserProfilePicture.vue';
import UserBasicDetails from './UserBasicDetails.vue';
import MessageSignature from './MessageSignature.vue';
import FontSize from './FontSize.vue';
import UserLanguageSelect from './UserLanguageSelect.vue';
import ChangePassword from './ChangePassword.vue';
import NotificationPreferences from './NotificationPreferences.vue';
import AudioNotifications from './AudioNotifications.vue';
import AccessToken from './AccessToken.vue';
import MfaSettingsCard from './MfaSettingsCard.vue';
import Policy from 'dashboard/components/policy.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import { RELAY_FORM_LABEL_CLASS } from 'dashboard/components-next/relay/form/constants';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';

const PROFILE_CARD_CLASS =
  'border border-border/60 bg-card rounded-xl p-6 shadow-sm';

export default {
  components: {
    MessageSignature,
    FontSize,
    UserLanguageSelect,
    UserProfilePicture,
    Policy,
    UserBasicDetails,
    ChangePassword,
    NotificationPreferences,
    AudioNotifications,
    AccessToken,
    MfaSettingsCard,
    Icon,
    RelayButton,
  },
  setup() {
    const { isEditorHotKeyEnabled, updateUISettings } = useUISettings();
    const { currentFontSize, updateFontSize } = useFontSize();
    const { replaceInstallationName } = useBranding();

    return {
      currentFontSize,
      updateFontSize,
      isEditorHotKeyEnabled,
      updateUISettings,
      replaceInstallationName,
      profileCardClass: PROFILE_CARD_CLASS,
      relayFormLabelClass: RELAY_FORM_LABEL_CLASS,
    };
  },
  data() {
    return {
      avatarFile: '',
      avatarUrl: '',
      name: '',
      displayName: '',
      email: '',
      messageSignature: '',
      hotKeys: [
        {
          key: 'enter',
          title: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.ENTER_KEY.HEADING'
          ),
          description: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.ENTER_KEY.CONTENT'
          ),
          mockSend: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.ENTER_KEY.MOCK_SEND'
          ),
        },
        {
          key: 'cmd_enter',
          title: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.CMD_ENTER_KEY.HEADING'
          ),
          description: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.CMD_ENTER_KEY.CONTENT'
          ),
          mockSend: this.$t(
            'PROFILE_SETTINGS.FORM.SEND_MESSAGE.CARD.CMD_ENTER_KEY.MOCK_SEND'
          ),
        },
      ],
      notificationPermissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      audioNotificationPermissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentUserId: 'getCurrentUserID',
      globalConfig: 'globalConfig/get',
    }),
  },
  mounted() {
    if (this.currentUserId) {
      this.initializeUser();
    }
  },
  methods: {
    initializeUser() {
      this.name = this.currentUser.name;
      this.email = this.currentUser.email;
      this.avatarUrl = this.currentUser.avatar_url;
      this.displayName = this.currentUser.display_name;
      this.messageSignature = this.currentUser.message_signature;
    },
    async dispatchUpdate(payload, successMessage, errorMessage) {
      let alertMessage = '';
      try {
        await this.$store.dispatch('updateProfile', payload);
        alertMessage = successMessage;

        return true; // return the value so that the status can be known
      } catch (error) {
        alertMessage = parseAPIErrorResponse(error) || errorMessage;

        return false; // return the value so that the status can be known
      } finally {
        useAlert(alertMessage);
      }
    },
    async updateProfile(userAttributes) {
      const { name, email, displayName } = userAttributes;
      const hasEmailChanged = this.currentUser.email !== email;
      this.name = name || this.name;
      this.email = email || this.email;
      this.displayName = displayName || this.displayName;

      const updatePayload = {
        name: this.name,
        email: this.email,
        displayName: this.displayName,
        avatar: this.avatarFile,
      };

      const success = await this.dispatchUpdate(
        updatePayload,
        hasEmailChanged
          ? this.$t('PROFILE_SETTINGS.AFTER_EMAIL_CHANGED')
          : this.$t('PROFILE_SETTINGS.UPDATE_SUCCESS'),
        this.$t('RESET_PASSWORD.API.ERROR_MESSAGE')
      );

      if (hasEmailChanged && success) clearCookiesOnLogout();
    },
    async updateSignature(signature) {
      const payload = { message_signature: signature };
      let successMessage = this.$t(
        'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.API_SUCCESS'
      );
      let errorMessage = this.$t(
        'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.API_ERROR'
      );

      await this.dispatchUpdate(payload, successMessage, errorMessage);
    },
    async updateProfilePicture({ file, url }) {
      const previousUrl = this.avatarUrl;
      this.avatarFile = file;
      this.avatarUrl = url;
      const success = await this.dispatchUpdate(
        {
          name: this.name,
          email: this.email,
          displayName: this.displayName,
          avatar: file,
        },
        this.$t('PROFILE_SETTINGS.UPDATE_SUCCESS'),
        this.$t('RESET_PASSWORD.API.ERROR_MESSAGE')
      );
      if (!success) {
        this.avatarUrl = previousUrl;
        this.avatarFile = '';
      }
    },
    async deleteProfilePicture() {
      try {
        await this.$store.dispatch('deleteAvatar');
        this.avatarUrl = '';
        this.avatarFile = '';
        useAlert(this.$t('PROFILE_SETTINGS.AVATAR_DELETE_SUCCESS'));
      } catch (error) {
        useAlert(this.$t('PROFILE_SETTINGS.AVATAR_DELETE_FAILED'));
      }
    },
    toggleHotKey(key) {
      this.hotKeys = this.hotKeys.map(hotKey =>
        hotKey.key === key ? { ...hotKey, active: !hotKey.active } : hotKey
      );
      this.updateUISettings({ editor_message_key: key });
      useAlert(this.$t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.UPDATE_SUCCESS'));
    },
    async onCopyToken(value) {
      await copyTextToClipboard(value);
      useAlert(this.$t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
    },
    async resetAccessToken() {
      const success = await this.$store.dispatch('resetAccessToken');
      if (success) {
        useAlert(this.$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.RESET_SUCCESS'));
      } else {
        useAlert(this.$t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.RESET_ERROR'));
      }
    },
  },
};
</script>

<template>
  <div class="w-full pb-10">
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
      <div :class="profileCardClass">
        <h2 class="text-base font-semibold text-foreground mb-6">
          {{ $t('PROFILE_SETTINGS.TITLE') }}
        </h2>
        <div class="flex flex-col sm:flex-row gap-6 sm:gap-8">
          <UserProfilePicture
            :src="avatarUrl"
            :name="name"
            @change="updateProfilePicture"
            @delete="deleteProfilePicture"
          />
          <div class="flex-1 min-w-0">
            <UserBasicDetails
              :name="name"
              :display-name="displayName"
              :email="email"
              :email-enabled="!globalConfig.disableUserProfileUpdate"
              @update-user="updateProfile"
            />
          </div>
        </div>
      </div>

      <div :class="profileCardClass">
        <div class="mb-6">
          <h2 class="text-base font-semibold text-foreground">
            {{ $t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.TITLE') }}
          </h2>
          <p class="text-[13px] text-muted-foreground mt-0.5">
            {{
              replaceInstallationName(
                $t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.NOTE')
              )
            }}
          </p>
        </div>
        <div class="space-y-6">
          <FontSize
            :value="currentFontSize"
            :label="
              $t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.TITLE')
            "
            :description="
              $t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.NOTE')
            "
            @change="updateFontSize"
          />
          <UserLanguageSelect
            :label="
              $t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.TITLE')
            "
            :description="
              $t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.NOTE')
            "
          />
        </div>
      </div>

      <div :class="profileCardClass">
        <div class="mb-6">
          <h2 class="text-base font-semibold text-foreground">
            {{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.TITLE') }}
          </h2>
          <p
            class="text-[13px] text-muted-foreground mt-0.5 leading-relaxed pr-4"
          >
            {{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.NOTE') }}
          </p>
        </div>
        <MessageSignature
          :message-signature="messageSignature"
          @update-signature="updateSignature"
        />
      </div>

      <div :class="profileCardClass">
        <div class="mb-6">
          <h2 class="text-base font-semibold text-foreground">
            {{ $t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.TITLE') }}
          </h2>
          <p class="text-[13px] text-muted-foreground mt-0.5 pr-4">
            {{ $t('PROFILE_SETTINGS.FORM.SEND_MESSAGE.NOTE') }}
          </p>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <button
            v-for="hotKey in hotKeys"
            :key="hotKey.key"
            type="button"
            :aria-pressed="isEditorHotKeyEnabled(hotKey.key)"
            class="border rounded-xl p-5 cursor-pointer transition-all relative flex flex-col h-full text-left"
            :class="[
              isEditorHotKeyEnabled(hotKey.key)
                ? 'border-primary ring-1 ring-primary/20 bg-primary/5'
                : 'border-border hover:border-primary/50 bg-card',
            ]"
            @click="toggleHotKey(hotKey.key)"
          >
            <div class="flex items-center justify-between mb-2">
              <span class="font-semibold text-[14px] text-foreground">
                {{ hotKey.title }}
              </span>
              <div
                class="size-4 rounded-full border flex items-center justify-center"
                :class="[
                  isEditorHotKeyEnabled(hotKey.key)
                    ? 'border-primary bg-primary'
                    : 'border-muted-foreground/30',
                ]"
              >
                <div
                  v-if="isEditorHotKeyEnabled(hotKey.key)"
                  class="size-1.5 rounded-full bg-primary-foreground"
                />
              </div>
            </div>
            <p
              class="text-[12px] text-muted-foreground leading-relaxed mb-6 flex-1"
            >
              {{ hotKey.description }}
            </p>
            <div
              class="rounded-lg p-3 pt-4 border flex flex-col gap-3 mt-auto transition-colors"
              :class="[
                isEditorHotKeyEnabled(hotKey.key)
                  ? 'bg-primary/10 border-primary/20'
                  : 'bg-muted/30 border-border/50',
              ]"
            >
              <div
                class="h-2 w-3/4 rounded-full transition-colors"
                :class="[
                  isEditorHotKeyEnabled(hotKey.key)
                    ? 'bg-primary/20'
                    : 'bg-muted-foreground/20',
                ]"
              />
              <div
                class="h-2 w-1/2 rounded-full transition-colors"
                :class="[
                  isEditorHotKeyEnabled(hotKey.key)
                    ? 'bg-primary/20'
                    : 'bg-muted-foreground/20',
                ]"
              />
              <div class="flex justify-end mt-2">
                <div
                  class="text-primary-foreground text-[10px] font-medium px-3 py-1.5 rounded transition-colors"
                  :class="[
                    isEditorHotKeyEnabled(hotKey.key)
                      ? 'bg-primary'
                      : 'bg-primary/50',
                  ]"
                >
                  {{ hotKey.mockSend }}
                </div>
              </div>
            </div>
          </button>
        </div>
      </div>

      <div
        v-if="!globalConfig.disableUserProfileUpdate"
        :class="profileCardClass"
      >
        <h2 class="text-base font-semibold text-foreground mb-6">
          {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.TITLE') }}
        </h2>
        <ChangePassword />
      </div>

      <div :class="profileCardClass">
        <div class="mb-6">
          <h2 class="text-base font-semibold text-foreground">
            {{ $t('PROFILE_SETTINGS.FORM.SECURITY_SECTION.TITLE') }}
          </h2>
          <p class="text-[13px] text-muted-foreground mt-0.5">
            {{ $t('PROFILE_SETTINGS.FORM.SECURITY_SECTION.NOTE') }}
          </p>
        </div>
        <MfaSettingsCard />
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 items-start">
      <Policy class="contents" :permissions="audioNotificationPermissions">
        <AudioNotifications />
      </Policy>
      <Policy class="contents" :permissions="notificationPermissions">
        <NotificationPreferences />
      </Policy>
      <div class="md:col-span-2 mb-10" :class="[profileCardClass]">
        <div class="mb-6">
          <h2 class="text-base font-semibold text-foreground">
            {{ $t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.TITLE') }}
          </h2>
          <p class="text-[13px] text-muted-foreground mt-0.5">
            {{
              replaceInstallationName(
                $t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.NOTE')
              )
            }}
          </p>
        </div>
        <AccessToken
          :value="currentUser.access_token"
          @on-copy="onCopyToken"
          @on-reset="resetAccessToken"
        />
        <div
          class="flex flex-col gap-4 p-4 mt-6 bg-muted/20 border border-border/60 rounded-xl"
        >
          <div class="flex flex-col gap-1.5 shrink-0">
            <label :class="relayFormLabelClass">
              {{ $t('MCP_SETTINGS.TITLE') }}
            </label>
            <p class="text-[13px] text-muted-foreground leading-relaxed">
              {{ $t('MCP_SETTINGS.SUBTITLE') }}
            </p>
          </div>
          <RelayButton
            as="router-link"
            :to="{
              name: 'profile_settings_mcp',
              params: { accountId: $route.params.accountId },
            }"
            variant="secondary"
            class="bg-primary/5 hover:bg-primary/10 border border-primary/20 text-primary font-medium whitespace-nowrap px-4 h-9 shadow-none shrink-0 self-start"
          >
            <Icon icon="i-lucide-shield-check" class="size-3.5" />
            {{ $t('MCP_SETTINGS.MANAGE_BUTTON') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </div>
</template>
