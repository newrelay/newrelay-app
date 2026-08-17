<script>
import { RelayTooltip, RelayButton } from 'dashboard/components-next/relay';
import { mapGetters } from 'vuex';
import DyteAPI from 'dashboard/api/integrations/dyte';
import { useAlert } from 'dashboard/composables';

export default {
  components: {
    RelayTooltip,
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
    plain: {
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
  <RelayTooltip
    v-if="isVideoIntegrationEnabled && plain"
    :content="$t('INTEGRATION_SETTINGS.DYTE.START_VIDEO_CALL_HELP_TEXT')"
    side="top"
  >
    <button
      type="button"
      :disabled="isLoading"
      class="size-8 flex items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-muted hover:text-foreground focus-visible:outline-none disabled:opacity-50"
      @click="onClick"
    >
      <span class="i-lucide-video size-4 shrink-0" />
    </button>
  </RelayTooltip>
  <RelayTooltip
    v-else-if="isVideoIntegrationEnabled"
    :content="$t('INTEGRATION_SETTINGS.DYTE.START_VIDEO_CALL_HELP_TEXT')"
    side="top"
    align="end"
  >
    <RelayButton
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
  </RelayTooltip>
</template>
