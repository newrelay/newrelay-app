<script>
/* eslint no-console: 0 */
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

import InboxMembersAPI from '../../../../api/inboxMembers';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader.vue';
import { useVuelidate } from '@vuelidate/core';
import { RelayButton } from 'dashboard/components-next/relay';

export default {
  components: {
    PageHeader,
    TagInput,
    RelayButton,
  },
  validations: {
    selectedAgentIds: {
      isEmpty() {
        return !!this.selectedAgentIds.length;
      },
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      selectedAgentIds: [],
      isCreating: false,
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
    }),
    selectedAgentNames() {
      return this.selectedAgentIds.map(
        id => this.agentList.find(a => a.id === id)?.name ?? ''
      );
    },
    agentMenuItems() {
      return this.agentList
        .filter(({ id }) => !this.selectedAgentIds.includes(id))
        .map(({ id, name, thumbnail, avatar_url }) => ({
          label: name,
          value: id,
          action: 'select',
          thumbnail: { name, src: thumbnail || avatar_url || '' },
        }));
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
  },
  methods: {
    handleAgentAdd({ value }) {
      if (!this.selectedAgentIds.includes(value)) {
        this.selectedAgentIds.push(value);
      }
    },
    handleAgentRemove(index) {
      this.selectedAgentIds.splice(index, 1);
    },
    async addAgents() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      this.isCreating = true;
      const inboxId = this.$route.params.inbox_id;

      try {
        await InboxMembersAPI.update({
          inboxId,
          agentList: this.selectedAgentIds,
        });
        router.replace({
          name: 'settings_inbox_finish',
          params: {
            page: 'new',
            inbox_id: this.$route.params.inbox_id,
          },
        });
      } catch (error) {
        useAlert(error.message);
      }
      this.isCreating = false;
    },
  },
};
</script>

<template>
  <div class="w-full max-w-2xl">
    <form class="flex flex-col" @submit.prevent="addAgents()">
      <PageHeader
        :header-title="$t('INBOX_MGMT.ADD.AGENTS.TITLE')"
        :header-content="$t('INBOX_MGMT.ADD.AGENTS.DESC')"
      />

      <div class="flex flex-col gap-1.5">
        <label class="text-[13.5px] font-medium text-foreground">
          {{ $t('INBOX_MGMT.ADD.AGENTS.TITLE') }}
        </label>
        <div
          class="rounded-md border border-border/80 bg-background px-2 py-2 shadow-sm focus-within:ring-1 focus-within:ring-primary/30"
          :class="{ 'border-destructive': v$.selectedAgentIds.$error }"
        >
          <TagInput
            :model-value="selectedAgentNames"
            :placeholder="$t('INBOX_MGMT.ADD.AGENTS.PICK_AGENTS')"
            :menu-items="agentMenuItems"
            show-dropdown
            skip-label-dedup
            @add="handleAgentAdd"
            @remove="handleAgentRemove"
          />
        </div>
        <p
          v-if="v$.selectedAgentIds.$error"
          class="text-[12.5px] text-destructive"
        >
          {{ $t('INBOX_MGMT.ADD.AGENTS.VALIDATION_ERROR') }}
        </p>
      </div>

      <div class="pt-6">
        <RelayButton
          type="submit"
          class="shadow-sm"
          :disabled="isCreating || !selectedAgentIds.length"
        >
          {{ $t('INBOX_MGMT.AGENTS.BUTTON_TEXT') }}
        </RelayButton>
      </div>
    </form>
  </div>
</template>
