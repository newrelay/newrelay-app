<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import GreetingsEditor from 'shared/components/GreetingsEditor.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';

const INPUT_CLASS =
  'h-10 rounded-md border-border/80 bg-background px-4 text-[14px] shadow-sm focus-visible:ring-1 focus-visible:ring-primary/30';

export default {
  components: {
    PageHeader,
    GreetingsEditor,
    Editor,
    RelayButton,
    RelayInput,
  },
  data() {
    return {
      inboxName: '',
      channelWebsiteUrl: '',
      channelWidgetColor: '#009CE0',
      channelWelcomeTitle: '',
      channelWelcomeTagline: '',
      greetingEnabled: false,
      greetingMessage: '',
      inputClass: INPUT_CLASS,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
    textAreaChannels() {
      if (
        this.isATwilioChannel ||
        this.isATwitterInbox ||
        this.isAFacebookInbox
      )
        return true;
      return false;
    },
    canSubmit() {
      return Boolean(this.channelWebsiteUrl?.trim() && this.inboxName?.trim());
    },
  },
  methods: {
    async createChannel() {
      try {
        const website = await this.$store.dispatch(
          'inboxes/createWebsiteChannel',
          {
            name: this.inboxName?.trim(),
            greeting_enabled: this.greetingEnabled,
            greeting_message: this.greetingMessage,
            channel: {
              type: 'web_widget',
              website_url: this.channelWebsiteUrl,
              widget_color: this.channelWidgetColor,
              welcome_title: this.channelWelcomeTitle,
              welcome_tagline: this.channelWelcomeTagline,
            },
          }
        );
        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: website.id,
          },
        });
      } catch (error) {
        useAlert(
          error.message ||
            this.$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div class="w-full max-w-2xl">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.DESC')"
    />
    <woot-loading-state
      v-if="uiFlags.isCreating"
      :message="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.LOADING_MESSAGE')"
    />
    <form
      v-if="!uiFlags.isCreating"
      class="space-y-6"
      @submit.prevent="createChannel"
    >
      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ $t('INBOX_MGMT.ADD.WEBSITE_NAME.LABEL') }}
        </label>
        <RelayInput
          v-model="inboxName"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WEBSITE_NAME.PLACEHOLDER')"
          :class-name="inputClass"
        />
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.LABEL') }}
        </label>
        <RelayInput
          v-model="channelWebsiteUrl"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.PLACEHOLDER')
          "
          :class-name="inputClass"
        />
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.LABEL') }}
        </label>
        <div class="flex items-center gap-3">
          <input
            v-model="channelWidgetColor"
            type="color"
            class="size-10 cursor-pointer rounded-md border border-border bg-background p-1"
          />
          <span class="font-mono text-[13px] text-muted-foreground">
            {{ channelWidgetColor }}
          </span>
        </div>
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.LABEL') }}
        </label>
        <RelayInput
          v-model="channelWelcomeTitle"
          type="text"
          :placeholder="
            $t(
              'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.PLACEHOLDER'
            )
          "
          :class-name="inputClass"
        />
      </div>

      <Editor
        v-model="channelWelcomeTagline"
        :label="
          $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.LABEL')
        "
        :placeholder="
          $t(
            'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.PLACEHOLDER'
          )
        "
        :max-length="255"
        channel-type="Context::InboxSettings"
      />

      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.LABEL')
          }}
        </label>
        <select
          v-model="greetingEnabled"
          class="h-10 w-full rounded-md border border-border/80 bg-background px-3 text-[14px] text-foreground shadow-sm outline-none focus:ring-1 focus:ring-primary/30"
        >
          <option :value="true">
            {{
              $t(
                'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.ENABLED'
              )
            }}
          </option>
          <option :value="false">
            {{
              $t(
                'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.DISABLED'
              )
            }}
          </option>
        </select>
        <p class="text-[12.5px] text-muted-foreground">
          {{
            $t(
              'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.HELP_TEXT'
            )
          }}
        </p>
      </div>

      <GreetingsEditor
        v-if="greetingEnabled"
        v-model="greetingMessage"
        class="w-full"
        :label="
          $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_MESSAGE.LABEL')
        "
        :placeholder="
          $t(
            'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_MESSAGE.PLACEHOLDER'
          )
        "
        :richtext="!textAreaChannels"
      />

      <div class="pt-4">
        <RelayButton
          type="submit"
          class="shadow-sm"
          :disabled="!canSubmit || uiFlags.isCreating"
        >
          {{ $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.SUBMIT_BUTTON') }}
        </RelayButton>
      </div>
    </form>
  </div>
</template>
