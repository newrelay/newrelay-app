<script>
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';

export default {
  components: {
    LoadingState,
  },
  props: {
    config: {
      type: Array,
      default: () => [],
    },
    currentChat: {
      type: Object,
      default: () => ({}),
    },
    isVisible: {
      type: Boolean,
      default: false,
    },
    position: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      hasOpenedAtleastOnce: false,
      iframeLoading: true,
    };
  },
  computed: {
    dashboardAppContext() {
      return {
        conversation: this.currentChat,
        contact: this.$store.getters['contacts/getContact'](this.contactId),
        currentAgent: this.currentAgent,
      };
    },
    contactId() {
      return this.currentChat?.meta?.sender?.id;
    },
    currentAgent() {
      const { id, name, email } = this.$store.getters.getCurrentUser;
      return { id, name, email };
    },
  },
  watch: {
    isVisible() {
      if (this.isVisible) {
        this.hasOpenedAtleastOnce = true;
      }
    },
  },
  mounted() {
    window.addEventListener('message', this.triggerEvent);
  },
  unmounted() {
    window.removeEventListener('message', this.triggerEvent);
  },
  methods: {
    triggerEvent(event) {
      if (!this.isVisible) return;
      if (event.data === 'chatwoot-dashboard-app:fetch-info') {
        this.onIframeLoad(0);
      }
    },
    getFrameId(index) {
      return `dashboard-app--frame-${this.position}-${index}`;
    },
    onIframeLoad(index) {
      // A possible alternative is to use ref instead of document.getElementById
      // However, when ref is used together with v-for, the ref you get will be
      // an array containing the child components mirroring the data source.
      const frameElement = document.getElementById(this.getFrameId(index));
      const eventData = { event: 'appContext', data: this.dashboardAppContext };
      frameElement.contentWindow.postMessage(JSON.stringify(eventData), '*');
      this.iframeLoading = false;
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div v-if="hasOpenedAtleastOnce" class="h-full w-full">
    <div
      v-for="(configItem, index) in config"
      :key="index"
      class="h-full w-full"
    >
      <LoadingState
        v-if="iframeLoading"
        :message="$t('DASHBOARD_APPS.LOADING_MESSAGE')"
        class="flex items-center justify-center h-full w-full"
      />
      <iframe
        v-if="configItem.type === 'frame' && configItem.url"
        :id="getFrameId(index)"
        :src="configItem.url"
        class="h-full w-full border-0"
        @load="() => onIframeLoad(index)"
      />
    </div>
  </div>
</template>
