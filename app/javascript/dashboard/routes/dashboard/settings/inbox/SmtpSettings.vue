<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import InputRadioGroup from './components/InputRadioGroup.vue';
import SingleSelectDropdown from './components/SingleSelectDropdown.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import {
  RelayInput,
  RelayLabel,
  RelayCheckbox,
} from 'dashboard/components-next/relay';

export default {
  components: {
    SettingsFieldSection,
    InputRadioGroup,
    SingleSelectDropdown,
    NextButton,
    RelayInput,
    RelayLabel,
    RelayCheckbox,
  },
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      isSMTPEnabled: false,
      address: '',
      port: '',
      login: '',
      password: '',
      domain: '',
      ssl: false,
      starttls: true,
      openSSLVerifyMode: 'none',
      authMechanism: 'login',
      encryptionProtocols: [
        { id: 'ssl', title: 'SSL/TLS', checked: false },
        { id: 'starttls', title: 'STARTTLS', checked: true },
      ],
      openSSLVerifyModes: [
        { key: 1, value: 'none' },
        { key: 2, value: 'peer' },
        { key: 3, value: 'client_once' },
        { key: 4, value: 'fail_if_no_peer_cert' },
      ],
      authMechanisms: [
        { key: 1, value: 'plain' },
        { key: 2, value: 'login' },
        { key: 3, value: 'cram-md5' },
        { key: 4, value: 'xoauth' },
        { key: 5, value: 'xoauth2' },
        { key: 6, value: 'ntlm' },
        { key: 7, value: 'gssapi' },
      ],
    };
  },
  validations: {
    address: { required },
    port: {
      required,
      minLength: minLength(2),
    },
    login: { required },
    password: { required },
    domain: { required },
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      const {
        smtp_enabled,
        smtp_address,
        smtp_port,
        smtp_login,
        smtp_password,
        smtp_domain,
        smtp_enable_starttls_auto,
        smtp_enable_ssl_tls,
        smtp_openssl_verify_mode,
        smtp_authentication,
      } = this.inbox;
      this.isSMTPEnabled = smtp_enabled;
      this.address = smtp_address;
      this.port = smtp_port;
      this.login = smtp_login;
      this.password = smtp_password;
      this.domain = smtp_domain;
      this.starttls = smtp_enable_starttls_auto;
      this.ssl = smtp_enable_ssl_tls;
      this.openSSLVerifyMode = smtp_openssl_verify_mode;
      this.authMechanism = smtp_authentication;

      this.encryptionProtocols = [
        { id: 'ssl', title: 'SSL/TLS', checked: smtp_enable_ssl_tls },
        {
          id: 'starttls',
          title: 'STARTTLS',
          checked: smtp_enable_starttls_auto,
        },
      ];
    },
    handleEncryptionChange(encryption) {
      if (encryption.id === 'ssl') {
        this.ssl = true;
        this.starttls = false;
      } else {
        this.ssl = false;
        this.starttls = true;
      }
    },
    handleSSLModeChange(mode) {
      this.openSSLVerifyMode = mode;
    },
    handleAuthMechanismChange(mode) {
      this.authMechanism = mode;
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          channel: {
            smtp_enabled: this.isSMTPEnabled,
            smtp_address: this.address,
            smtp_port: this.port,
            smtp_login: this.login,
            smtp_password: this.password,
            smtp_domain: this.domain,
            smtp_enable_ssl_tls: this.ssl,
            smtp_enable_starttls_auto: this.starttls,
            smtp_openssl_verify_mode: this.openSSLVerifyMode,
            smtp_authentication: this.authMechanism,
          },
        };
        await this.$store.dispatch('inboxes/updateInboxSMTP', payload);
        useAlert(this.$t('INBOX_MGMT.SMTP.EDIT.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(
          error.message || this.$t('INBOX_MGMT.SMTP.EDIT.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <SettingsFieldSection
    :label="$t('INBOX_MGMT.SMTP.TITLE')"
    :help-text="$t('INBOX_MGMT.SMTP.SUBTITLE')"
    class="[&>div]:!items-start [&>div>label]:mt-1 mb-4"
  >
    <form @submit.prevent="updateInbox">
      <label class="flex items-center gap-2.5 cursor-pointer">
        <RelayCheckbox v-model="isSMTPEnabled" />
        <span>{{ $t('INBOX_MGMT.SMTP.TOGGLE_AVAILABILITY') }}</span>
      </label>
      <p>{{ $t('INBOX_MGMT.SMTP.TOGGLE_HELP') }}</p>
      <div v-if="isSMTPEnabled" class="mb-6 flex flex-col gap-4">
        <div class="flex w-full flex-col gap-2">
          <RelayLabel html-for="smtp-address">
            {{ $t('INBOX_MGMT.SMTP.ADDRESS.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="smtp-address"
            v-model="address"
            :class-name="`h-10 shadow-xs bg-background ${v$.address.$error ? 'ring-1 ring-destructive' : ''}`"
            :placeholder="$t('INBOX_MGMT.SMTP.ADDRESS.PLACE_HOLDER')"
            @blur="v$.address.$touch"
          />
        </div>
        <div class="flex w-full flex-col gap-2">
          <RelayLabel html-for="smtp-port">
            {{ $t('INBOX_MGMT.SMTP.PORT.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="smtp-port"
            v-model="port"
            type="number"
            :class-name="`h-10 shadow-xs bg-background ${v$.port.$error ? 'ring-1 ring-destructive' : ''}`"
            :placeholder="$t('INBOX_MGMT.SMTP.PORT.PLACE_HOLDER')"
            @blur="v$.port.$touch"
          />
        </div>
        <div class="flex w-full flex-col gap-2">
          <RelayLabel html-for="smtp-login">
            {{ $t('INBOX_MGMT.SMTP.LOGIN.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="smtp-login"
            v-model="login"
            :class-name="`h-10 shadow-xs bg-background ${v$.login.$error ? 'ring-1 ring-destructive' : ''}`"
            :placeholder="$t('INBOX_MGMT.SMTP.LOGIN.PLACE_HOLDER')"
            @blur="v$.login.$touch"
          />
        </div>
        <div class="flex w-full flex-col gap-2">
          <RelayLabel html-for="smtp-password">
            {{ $t('INBOX_MGMT.SMTP.PASSWORD.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="smtp-password"
            v-model="password"
            type="password"
            :class-name="`h-10 shadow-xs bg-background ${v$.password.$error ? 'ring-1 ring-destructive' : ''}`"
            :placeholder="$t('INBOX_MGMT.SMTP.PASSWORD.PLACE_HOLDER')"
            @blur="v$.password.$touch"
          />
        </div>
        <div class="flex w-full flex-col gap-2">
          <RelayLabel html-for="smtp-domain">
            {{ $t('INBOX_MGMT.SMTP.DOMAIN.LABEL') }}
          </RelayLabel>
          <RelayInput
            id="smtp-domain"
            v-model="domain"
            :class-name="`h-10 shadow-xs bg-background ${v$.domain.$error ? 'ring-1 ring-destructive' : ''}`"
            :placeholder="$t('INBOX_MGMT.SMTP.DOMAIN.PLACE_HOLDER')"
            @blur="v$.domain.$touch"
          />
        </div>
        <InputRadioGroup
          :label="$t('INBOX_MGMT.SMTP.ENCRYPTION')"
          :items="encryptionProtocols"
          :action="handleEncryptionChange"
        />
        <SingleSelectDropdown
          class="w-full"
          :label="$t('INBOX_MGMT.SMTP.OPEN_SSL_VERIFY_MODE')"
          :selected="openSSLVerifyMode"
          :options="openSSLVerifyModes"
          :action="handleSSLModeChange"
        />
        <SingleSelectDropdown
          class="w-full"
          :label="$t('INBOX_MGMT.SMTP.AUTH_MECHANISM')"
          :selected="authMechanism"
          :options="authMechanisms"
          :action="handleAuthMechanismChange"
        />
      </div>
      <NextButton
        type="submit"
        :label="$t('INBOX_MGMT.SMTP.UPDATE')"
        :is-loading="uiFlags.isUpdatingSMTP"
        :disabled="(v$.$invalid && isSMTPEnabled) || uiFlags.isUpdatingSMTP"
      />
    </form>
  </SettingsFieldSection>
</template>
