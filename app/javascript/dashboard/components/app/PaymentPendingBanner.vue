<script>
import { mapGetters } from 'vuex';
import { differenceInCalendarDays } from 'date-fns';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAccount } from 'dashboard/composables/useAccount';
import Banner from 'dashboard/components/ui/Banner.vue';

const PAST_DUE_STATUSES = ['past_due', 'unpaid'];

export default {
  components: { Banner },
  setup() {
    const { isAdmin } = useAdmin();

    const { accountId } = useAccount();

    return {
      accountId,
      isAdmin,
    };
  },
  computed: {
    ...mapGetters({
      isOnChatwootCloud: 'globalConfig/isOnChatwootCloud',
      getAccount: 'accounts/getAccount',
    }),
    subscription() {
      return this.getAccount(this.accountId)?.subscription;
    },
    // Shown while a failed payment is still within its grace period (subscription
    // stays `active` on the backend during that window - see Subscription#active?).
    // Once the grace period lapses, UpgradePage takes over and blocks the dashboard.
    daysRemaining() {
      if (!this.subscription?.grace_period_ends_at) return null;
      return Math.max(
        0,
        differenceInCalendarDays(
          new Date(this.subscription.grace_period_ends_at),
          new Date()
        )
      );
    },
    bannerMessage() {
      if (Number.isInteger(this.daysRemaining)) {
        return this.$t('GENERAL_SETTINGS.PAYMENT_PENDING_WITH_DAYS', {
          days: this.daysRemaining,
        });
      }
      return this.$t('GENERAL_SETTINGS.PAYMENT_PENDING');
    },
    actionButtonMessage() {
      return this.$t('GENERAL_SETTINGS.OPEN_BILLING');
    },
    shouldShowBanner() {
      if (!this.isOnChatwootCloud) {
        return false;
      }

      if (!this.isAdmin) {
        return false;
      }

      return this.isPaymentPending();
    },
  },
  methods: {
    routeToBilling() {
      this.$router.push({
        name: 'billing_settings_index',
        params: { accountId: this.accountId },
      });
    },
    isPaymentPending() {
      if (!this.subscription) return false;
      return (
        this.subscription.active &&
        PAST_DUE_STATUSES.includes(this.subscription.status)
      );
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Banner
    v-if="shouldShowBanner"
    color-scheme="alert"
    :banner-message="bannerMessage"
    :action-button-label="actionButtonMessage"
    has-action-button
    @primary-action="routeToBilling"
  />
</template>
