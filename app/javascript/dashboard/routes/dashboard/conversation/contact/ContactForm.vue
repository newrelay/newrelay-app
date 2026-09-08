<script>
import { useAlert } from 'dashboard/composables';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import { required, email } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import countries from 'shared/constants/countries.js';
import { isPhoneNumberValid } from 'shared/helpers/Validators';
import parsePhoneNumber from 'libphonenumber-js';
import {
  RelayInput,
  RelayTextarea,
  RelayLabel,
  RelayButton,
  RELAY_FORM_FIELD_CLASS,
  RELAY_FORM_INPUT_FULL_CLASS,
} from 'dashboard/components-next/relay';
import PhoneNumberInput from 'dashboard/components-next/phonenumberinput/PhoneNumberInput.vue';
import Avatar from 'next/avatar/Avatar.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

export default {
  components: {
    RelayInput,
    RelayTextarea,
    RelayLabel,
    RelayButton,
    PhoneNumberInput,
    Avatar,
    ComboBox,
  },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    inProgress: {
      type: Boolean,
      default: false,
    },
    onSubmit: {
      type: Function,
      default: () => {},
    },
  },
  emits: ['cancel', 'success'],
  setup() {
    return {
      v$: useVuelidate(),
      RELAY_FORM_FIELD_CLASS,
      RELAY_FORM_INPUT_FULL_CLASS,
    };
  },
  data() {
    return {
      countries: countries,
      companyName: '',
      description: '',
      email: '',
      name: '',
      phoneNumber: '',
      activeDialCode: '',
      avatarFile: null,
      avatarUrl: '',
      country: {
        id: '',
        name: '',
      },
      city: '',
      socialProfileUserNames: {
        facebook: '',
        twitter: '',
        linkedin: '',
        github: '',
        telegram: '',
      },
      socialProfileKeys: [
        { key: 'facebook', prefixURL: 'https://facebook.com/' },
        { key: 'twitter', prefixURL: 'https://twitter.com/' },
        { key: 'linkedin', prefixURL: 'https://linkedin.com/' },
        { key: 'github', prefixURL: 'https://github.com/' },
        { key: 'telegram', prefixURL: 'https://t.me/' },
        { key: 'tiktok', prefixURL: 'https://tiktok.com/@' },
      ],
    };
  },
  validations: {
    name: {
      required,
    },
    description: {},
    email: {
      email,
    },
    companyName: {},
    phoneNumber: {},
    bio: {},
  },
  computed: {
    parsePhoneNumber() {
      return parsePhoneNumber(this.phoneNumber);
    },
    isPhoneNumberNotValid() {
      if (this.phoneNumber !== '') {
        return (
          !isPhoneNumberValid(this.phoneNumber, this.activeDialCode) ||
          (this.phoneNumber !== '' ? this.activeDialCode === '' : false)
        );
      }
      return false;
    },
    phoneNumberError() {
      if (this.activeDialCode === '') {
        return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DIAL_CODE_ERROR');
      }
      if (!isPhoneNumberValid(this.phoneNumber, this.activeDialCode)) {
        return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.ERROR');
      }
      return '';
    },
    setPhoneNumber() {
      if (this.parsePhoneNumber && this.parsePhoneNumber.countryCallingCode) {
        return this.phoneNumber;
      }
      if (this.phoneNumber === '' && this.activeDialCode !== '') {
        return '';
      }
      return this.activeDialCode
        ? `${this.activeDialCode}${this.phoneNumber}`
        : '';
    },
  },
  watch: {
    contact() {
      this.setContactObject();
    },
    phoneNumber() {
      this.setDialCode();
    },
  },
  mounted() {
    this.setContactObject();
    this.setDialCode();
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('success');
    },
    countryNameWithCode({ name, id }) {
      if (!id) return name;
      if (!name && !id) return '';
      return `${name} (${id})`;
    },
    onCountryChange(value) {
      const selected = this.countries.find(c => c.id === value);
      this.country = selected
        ? { id: selected.id, name: selected.name }
        : { id: '', name: '' };
    },
    setDialCode() {
      if (
        this.phoneNumber !== '' &&
        this.parsePhoneNumber &&
        this.parsePhoneNumber.countryCallingCode
      ) {
        const dialCode = this.parsePhoneNumber.countryCallingCode;
        this.activeDialCode = `+${dialCode}`;
      }
    },
    setContactObject() {
      const {
        email: emailAddress,
        phone_number: phoneNumber,
        name,
      } = this.contact;
      const additionalAttributes = this.contact.additional_attributes || {};

      this.name = name || '';
      this.email = emailAddress || '';
      this.phoneNumber = phoneNumber || '';
      this.companyName = additionalAttributes.company_name || '';
      this.country = {
        id: additionalAttributes.country_code || '',
        name:
          additionalAttributes.country ||
          this.$t('CONTACT_FORM.FORM.COUNTRY.SELECT_COUNTRY'),
      };
      this.city = additionalAttributes.city || '';
      this.description = additionalAttributes.description || '';
      this.avatarUrl = this.contact.thumbnail || '';
      const {
        social_profiles: socialProfiles = {},
        screen_name: twitterScreenName,
        social_telegram_user_name: telegramUserName,
      } = additionalAttributes;
      this.socialProfileUserNames = {
        twitter: socialProfiles.twitter || twitterScreenName || '',
        facebook: socialProfiles.facebook || '',
        linkedin: socialProfiles.linkedin || '',
        github: socialProfiles.github || '',
        telegram: socialProfiles.telegram || telegramUserName || '',
        instagram: socialProfiles.instagram || '',
        tiktok: socialProfiles.tiktok || '',
      };
    },
    getContactObject() {
      if (this.country === null) {
        this.country = {
          id: '',
          name: '',
        };
      }
      const contactObject = {
        id: this.contact.id,
        name: this.name,
        email: this.email,
        phone_number: this.setPhoneNumber,
        additional_attributes: {
          ...this.contact.additional_attributes,
          description: this.description,
          company_name: this.companyName,
          country_code: this.country.id,
          country:
            this.country.name ===
            this.$t('CONTACT_FORM.FORM.COUNTRY.SELECT_COUNTRY')
              ? ''
              : this.country.name,
          city: this.city,
          social_profiles: this.socialProfileUserNames,
        },
      };
      if (this.avatarFile) {
        contactObject.avatar = this.avatarFile;
        contactObject.isFormData = true;
      }
      return contactObject;
    },
    setPhoneCode(code) {
      if (this.phoneNumber !== '' && this.parsePhoneNumber) {
        const dialCode = this.parsePhoneNumber.countryCallingCode;
        if (dialCode === code) {
          return;
        }
        this.activeDialCode = `+${dialCode}`;
        const newPhoneNumber = this.phoneNumber.replace(
          `+${dialCode}`,
          `${code}`
        );
        this.phoneNumber = newPhoneNumber;
      } else {
        this.activeDialCode = code;
      }
    },
    async handleSubmit() {
      this.v$.$touch();
      if (this.v$.$invalid || this.isPhoneNumberNotValid) {
        return;
      }
      try {
        await this.onSubmit(this.getContactObject());
        this.onSuccess();
        useAlert(this.$t('CONTACT_FORM.SUCCESS_MESSAGE'));
      } catch (error) {
        if (error instanceof DuplicateContactException) {
          if (error.data.includes('email')) {
            useAlert(this.$t('CONTACT_FORM.FORM.EMAIL_ADDRESS.DUPLICATE'));
          } else if (error.data.includes('phone_number')) {
            useAlert(this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DUPLICATE'));
          }
        } else if (error instanceof ExceptionWithMessage) {
          useAlert(error.data);
        } else {
          useAlert(this.$t('CONTACT_FORM.ERROR_MESSAGE'));
        }
      }
    },
    handleImageUpload({ file, url }) {
      this.avatarFile = file;
      this.avatarUrl = url;
    },
    async handleAvatarDelete() {
      try {
        if (this.contact && this.contact.id) {
          await this.$store.dispatch('contacts/deleteAvatar', this.contact.id);
          useAlert(this.$t('CONTACT_FORM.DELETE_AVATAR.API.SUCCESS_MESSAGE'));
        }
        this.avatarFile = null;
        this.avatarUrl = '';
        this.activeDialCode = '';
      } catch (error) {
        useAlert(
          error.message
            ? error.message
            : this.$t('CONTACT_FORM.DELETE_AVATAR.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <form
    class="flex w-full flex-col gap-4 px-8 pt-6 pb-8"
    @submit.prevent="handleSubmit"
  >
    <div class="flex flex-col items-start gap-1.5 w-full">
      <RelayLabel>
        {{ $t('CONTACT_FORM.FORM.AVATAR.LABEL') }}
      </RelayLabel>
      <Avatar
        :src="avatarUrl"
        :size="72"
        :name="contact.name"
        allow-upload
        rounded-full
        @upload="handleImageUpload"
        @delete="handleAvatarDelete"
      />
    </div>
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel>
        {{ $t('CONTACT_FORM.FORM.NAME.LABEL') }}
      </RelayLabel>
      <RelayInput
        v-model="name"
        :placeholder="$t('CONTACT_FORM.FORM.NAME.PLACEHOLDER')"
        @update:model-value="v$.name.$touch"
      />
    </div>
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel>
        {{ $t('CONTACT_FORM.FORM.EMAIL_ADDRESS.LABEL') }}
      </RelayLabel>
      <RelayInput
        v-model="email"
        type="email"
        :placeholder="$t('CONTACT_FORM.FORM.EMAIL_ADDRESS.PLACEHOLDER')"
        @update:model-value="v$.email.$touch"
      />
      <span v-if="v$.email.$error" class="text-[13px] text-destructive">
        {{ $t('CONTACT_FORM.FORM.EMAIL_ADDRESS.ERROR') }}
      </span>
    </div>
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel>
        {{ $t('CONTACT_FORM.FORM.BIO.LABEL') }}
      </RelayLabel>
      <RelayTextarea
        v-model="description"
        :placeholder="$t('CONTACT_FORM.FORM.BIO.PLACEHOLDER')"
        :rows="3"
        @update:model-value="v$.description.$touch"
      />
    </div>
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel>
        {{ $t('CONTACT_FORM.FORM.PHONE_NUMBER.LABEL') }}
      </RelayLabel>
      <PhoneNumberInput
        v-model="phoneNumber"
        :placeholder="$t('CONTACT_FORM.FORM.PHONE_NUMBER.PLACEHOLDER')"
      />
      <span v-if="isPhoneNumberNotValid" class="text-[13px] text-destructive">
        {{ phoneNumberError }}
      </span>
      <div
        v-if="isPhoneNumberNotValid || !phoneNumber"
        class="rounded-md border border-warning/20 bg-warning/10 p-2 text-sm text-warning"
      >
        {{ $t('CONTACT_FORM.FORM.PHONE_NUMBER.HELP') }}
      </div>
    </div>
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel>
        {{ $t('CONTACT_FORM.FORM.COMPANY_NAME.LABEL') }}
      </RelayLabel>
      <RelayInput
        v-model="companyName"
        :placeholder="$t('CONTACT_FORM.FORM.COMPANY_NAME.PLACEHOLDER')"
      />
    </div>
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel>
        {{ $t('CONTACT_FORM.FORM.COUNTRY.LABEL') }}
      </RelayLabel>
      <ComboBox
        :model-value="country.id"
        :options="
          countries.map(c => ({
            value: c.id,
            label: countryNameWithCode(c),
          }))
        "
        :placeholder="$t('CONTACT_FORM.FORM.COUNTRY.PLACEHOLDER')"
        :search-placeholder="$t('CONTACT_FORM.FORM.COUNTRY.SELECT_PLACEHOLDER')"
        @update:model-value="onCountryChange"
      />
    </div>
    <div :class="RELAY_FORM_FIELD_CLASS">
      <RelayLabel>
        {{ $t('CONTACT_FORM.FORM.CITY.LABEL') }}
      </RelayLabel>
      <RelayInput
        v-model="city"
        :placeholder="$t('CONTACT_FORM.FORM.CITY.PLACEHOLDER')"
      />
    </div>

    <div class="flex flex-col gap-2">
      <RelayLabel>
        {{ $t('CONTACTS_PAGE.LIST.TABLE_HEADER.SOCIAL_PROFILES') }}
      </RelayLabel>
      <div
        v-for="socialProfile in socialProfileKeys"
        :key="socialProfile.key"
        class="flex w-full items-stretch"
      >
        <span
          class="flex h-9 items-center border border-border/80 bg-muted px-2 text-[13px] text-muted-foreground ltr:rounded-l-md ltr:border-r-0 rtl:rounded-r-md rtl:border-l-0"
        >
          {{ socialProfile.prefixURL }}
        </span>
        <input
          v-model="socialProfileUserNames[socialProfile.key]"
          :class="RELAY_FORM_INPUT_FULL_CLASS"
          class="h-9 !rounded-none ltr:!rounded-r-md rtl:!rounded-l-md"
          type="text"
        />
      </div>
    </div>
    <div class="flex flex-row justify-start gap-3 pt-2">
      <RelayButton type="submit" :disabled="inProgress">
        {{ $t('CONTACT_FORM.FORM.SUBMIT') }}
      </RelayButton>
      <RelayButton type="button" variant="outline" @click="onCancel">
        {{ $t('CONTACT_FORM.FORM.CANCEL') }}
      </RelayButton>
    </div>
  </form>
</template>
