<script>
import { mapGetters } from 'vuex';
import DyteAPI from 'dashboard/api/integrations/dyte';
import { useAlert } from 'dashboard/composables';
import { RelayButton } from 'dashboard/components-next/relay';

export default {
  components: {
    RelayButton,
  },
  props: {
    conversationId: {
      type: Number,
      default: 0,
    },
    compact: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return { isLoading: false };
  },
  computed: {
    ...mapGetters({ appIntegrations: 'integrations/getAppIntegrations' }),
    isVideoIntegrationEnabled() {
      return this.appIntegrations.find(
        integration => integration.id === 'dyte' && !!integration.hooks.length
      );
    },
  },
  mounted() {
    if (!this.appIntegrations.length) {
      this.$store.dispatch('integrations/get');
    }
  },
  methods: {
    async onClick() {
      this.isLoading = true;
      try {
        await DyteAPI.createAMeeting(this.conversationId);
      } catch (error) {
        useAlert(this.$t('INTEGRATION_SETTINGS.DYTE.CREATE_ERROR'));
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <RelayButton
    v-if="isVideoIntegrationEnabled"
    v-tooltip.top-end="
      $t('INTEGRATION_SETTINGS.DYTE.START_VIDEO_CALL_HELP_TEXT')
    "
    variant="ghost"
    :class="
      compact
        ? 'h-8 w-8 shrink-0 p-0 min-h-8 min-w-8 text-muted-foreground hover:text-foreground'
        : ''
    "
    :disabled="isLoading"
    @click="onClick"
  >
    <span class="i-lucide-video size-4 shrink-0" />
  </RelayButton>
</template>
