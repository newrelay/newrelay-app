<script>
/* eslint-env browser */
/* global FB */
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { required } from '@vuelidate/validators';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';

import ChannelApi from '../../../../../api/channels';
import PageHeader from '../../SettingsSubPageHeader.vue';
import router from '../../../../index';
import { useBranding } from 'shared/composables/useBranding';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

import { loadScript } from 'dashboard/helper/DOMHelpers';
import * as Sentry from '@sentry/vue';

export default {
  components: {
    LoadingState,
    PageHeader,
    NextButton,
    ComboBox,
  },
  setup() {
    const { accountId } = useAccount();
    const { replaceInstallationName } = useBranding();
    return {
      accountId,
      replaceInstallationName,
      v$: useVuelidate(),
    };
  },
  data() {
    return {
      isCreating: false,
      hasError: false,
      omniauth_token: '',
      user_access_token: '',
      channel: 'facebook',
      selectedPage: { name: null, id: null },
      pageName: '',
      pageList: [],
      emptyStateMessage: this.$t('INBOX_MGMT.DETAILS.LOADING_FB'),
      errorStateMessage: '',
      errorStateDescription: '',
      hasLoginStarted: false,
    };
  },

  validations: {
    pageName: {
      required,
    },

    selectedPage: {
      isEmpty() {
        return this.selectedPage !== null && !!this.selectedPage.name;
      },
    },
  },

  computed: {
    showLoader() {
      return !this.user_access_token || this.isCreating;
    },
    getSelectablePages() {
      return this.pageList.filter(item => !item.exists);
    },
    comboBoxPageOptions() {
      return this.getSelectablePages.map(({ id, name }) => ({
        value: id,
        label: name,
      }));
    },
  },

  mounted() {
    window.fbAsyncInit = this.runFBInit;
  },

  methods: {
    async startLogin() {
      this.hasLoginStarted = true;
      try {
        // this will load the SDK in a promise, and resolve it when the sdk is loaded
        // in case the SDK is already present, it will resolve immediately
        await this.loadFBsdk();
        this.runFBInit(); // run init anyway, `tryFBlogin` won't wait for `fbAsyncInit` otherwise.
        this.tryFBlogin(); // make an attempt to login
      } catch (error) {
        if (error.name === 'ScriptLoaderError') {
          // if the error was related to script loading, we show a toast
          useAlert(this.$t('INBOX_MGMT.DETAILS.ERROR_FB_LOADING'));
        } else {
          // if the error was anything else, we capture it and show a toast
          Sentry.captureException(error);
          useAlert(this.$t('INBOX_MGMT.DETAILS.ERROR_FB_AUTH'));
        }
      }
    },

    setPageName(pageId) {
      const page = this.pageList.find(p => p.id === pageId);
      if (page) {
        this.selectedPage = page;
        this.pageName = page.name;
      } else {
        this.selectedPage = { name: null, id: null };
        this.pageName = '';
      }
      this.v$.selectedPage.$touch();
    },

    initChannelAuth(channel) {
      if (channel === 'facebook') {
        this.loadFBsdk();
      }
    },

    runFBInit() {
      FB.init({
        appId: window.chatwootConfig.fbAppId,
        xfbml: true,
        version: window.chatwootConfig.fbApiVersion,
        status: true,
      });
      window.fbSDKLoaded = true;
      FB.AppEvents.logPageView();
    },

    async loadFBsdk() {
      return loadScript('https://connect.facebook.net/en_US/sdk.js', {
        id: 'facebook-jssdk',
      });
    },

    tryFBlogin() {
      FB.login(
        response => {
          this.hasError = false;
          if (response.status === 'connected') {
            this.fetchPages(response.authResponse.accessToken);
          } else if (response.status === 'not_authorized') {
            // eslint-disable-next-line no-console
            console.error('FACEBOOK AUTH ERROR', response);
            this.hasError = true;
            // The person is logged into Facebook, but not your app.
            this.errorStateMessage = this.$t(
              'INBOX_MGMT.DETAILS.ERROR_FB_UNAUTHORIZED'
            );
            this.errorStateDescription = this.$t(
              'INBOX_MGMT.DETAILS.ERROR_FB_UNAUTHORIZED_HELP'
            );
          } else {
            // eslint-disable-next-line no-console
            console.error('FACEBOOK AUTH ERROR', response);
            this.hasError = true;
            // The person is not logged into Facebook, so we're not sure if
            // they are logged into this app or not.
            this.errorStateMessage = this.$t(
              'INBOX_MGMT.DETAILS.ERROR_FB_AUTH'
            );
            this.errorStateDescription = '';
          }
        },
        {
          scope:
            'pages_manage_metadata,business_management,pages_messaging,instagram_basic,pages_show_list,pages_read_engagement,instagram_manage_messages',
        }
      );
    },

    async fetchPages(_token) {
      try {
        const response = await ChannelApi.fetchFacebookPages(
          _token,
          this.accountId
        );
        const {
          data: { data },
        } = response;
        this.pageList = data.page_details;
        this.user_access_token = data.user_access_token;
      } catch (error) {
        // Ignore error
      }
    },

    channelParams() {
      return {
        user_access_token: this.user_access_token,
        page_access_token: this.selectedPage.access_token,
        page_id: this.selectedPage.id,
        inbox_name: this.selectedPage.name?.trim(),
      };
    },

    createChannel() {
      this.v$.$touch();
      if (!this.v$.$error) {
        this.emptyStateMessage = this.$t('INBOX_MGMT.DETAILS.CREATING_CHANNEL');
        this.isCreating = true;
        this.$store
          .dispatch('inboxes/createFBChannel', this.channelParams())
          .then(data => {
            router.replace({
              name: 'settings_inboxes_add_agents',
              params: { page: 'new', inbox_id: data.id },
            });
          })
          .catch(() => {
            this.isCreating = false;
          });
      }
    },
  },
};
</script>

<template>
  <div class="w-full max-w-2xl overflow-auto">
    <div
      v-if="!hasLoginStarted"
      class="flex flex-col items-center justify-center py-16 text-center"
    >
      <a href="#" @click="startLogin()">
        <img
          class="h-10 w-auto rounded-md"
          src="~dashboard/assets/images/channels/facebook_login.png"
          alt="Facebook-logo"
        />
      </a>
      <p
        class="max-w-md py-6 text-[13px] leading-relaxed text-muted-foreground"
      >
        {{ replaceInstallationName($t('INBOX_MGMT.ADD.FB.HELP')) }}
      </p>
    </div>
    <div v-else>
      <div v-if="hasError" class="mx-auto max-w-lg text-center">
        <h5 class="text-base font-semibold text-foreground">
          {{ errorStateMessage }}
        </h5>
        <p
          v-if="errorStateDescription"
          v-dompurify-html="errorStateDescription"
          class="mt-2 text-[13px] text-muted-foreground"
        />
      </div>
      <LoadingState v-else-if="showLoader" :message="emptyStateMessage" />
      <form
        v-else
        class="flex flex-col space-y-6"
        @submit.prevent="createChannel()"
      >
        <PageHeader
          :header-title="$t('INBOX_MGMT.ADD.DETAILS.TITLE')"
          :header-content="
            replaceInstallationName($t('INBOX_MGMT.ADD.DETAILS.DESC'))
          "
        />
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground">
            {{ $t('INBOX_MGMT.ADD.FB.CHOOSE_PAGE') }}
          </label>
          <ComboBox
            :model-value="selectedPage.id"
            :options="comboBoxPageOptions"
            :placeholder="$t('INBOX_MGMT.ADD.FB.PICK_A_VALUE')"
            :has-error="v$.selectedPage.$error"
            @update:model-value="setPageName"
          />
          <p
            v-if="v$.selectedPage.$error"
            class="text-[12.5px] text-destructive"
          >
            {{ $t('INBOX_MGMT.ADD.FB.CHOOSE_PLACEHOLDER') }}
          </p>
        </div>
        <div class="flex flex-col gap-1.5">
          <label class="text-[13.5px] font-medium text-foreground">
            {{ $t('INBOX_MGMT.ADD.FB.INBOX_NAME') }}
          </label>
          <input
            v-model="pageName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.FB.PICK_NAME')"
            class="h-10 w-full rounded-md border border-border/80 bg-background px-4 text-[14px] text-foreground shadow-sm outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
            @input="v$.pageName.$touch"
          />
          <p v-if="v$.pageName.$error" class="text-[12.5px] text-destructive">
            {{ $t('INBOX_MGMT.ADD.FB.ADD_NAME') }}
          </p>
        </div>
        <div class="pt-2">
          <NextButton
            type="submit"
            :label="$t('INBOX_MGMT.ADD.FB.CREATE_INBOX')"
            class="shadow-sm"
          />
        </div>
      </form>
    </div>
  </div>
</template>
