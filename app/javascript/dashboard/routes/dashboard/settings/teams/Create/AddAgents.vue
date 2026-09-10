<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

import router from '../../../../index';
import AgentSelector from '../AgentSelector.vue';
import { useVuelidate } from '@vuelidate/core';

export default {
  components: {
    AgentSelector,
  },
  validations: {
    selectedAgents: {
      isEmpty() {
        return !!this.selectedAgents.length;
      },
    },
  },

  setup() {
    return { v$: useVuelidate() };
  },

  data() {
    return {
      selectedAgents: [],
      isCreating: false,
    };
  },

  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
    }),

    teamId() {
      return this.$route.params.teamId;
    },
    headerTitle() {
      return this.$t('TEAMS_SETTINGS.ADD.TITLE', {
        teamName: this.currentTeam.name,
      });
    },
    currentTeam() {
      return this.$store.getters['teams/getTeam'](this.teamId);
    },
  },

  mounted() {
    this.$store.dispatch('agents/get');
  },

  methods: {
    updateSelectedAgents(newAgentList) {
      this.v$.selectedAgents.$touch();
      this.selectedAgents = [...newAgentList];
    },
    selectAllAgents() {
      this.selectedAgents = this.agentList.map(agent => agent.id);
    },
    async addAgents() {
      this.isCreating = true;
      const { teamId, selectedAgents } = this;

      try {
        await this.$store.dispatch('teamMembers/create', {
          teamId,
          agentsList: selectedAgents,
        });
        router.replace({
          name: 'settings_teams_finish',
          params: {
            page: 'new',
            teamId,
          },
        });
        this.$store.dispatch('teams/get');
      } catch (error) {
        useAlert(error.message);
      }
      this.isCreating = false;
    },
  },
};
</script>

<template>
  <div class="w-full animate-in fade-in duration-300">
    <form class="flex flex-col" @submit.prevent="addAgents">
      <div class="mb-6">
        <h3 class="mb-1 text-[16px] font-medium text-foreground">
          {{ headerTitle }}
        </h3>
        <p
          class="max-w-3xl text-[13.5px] leading-relaxed text-muted-foreground"
        >
          {{ $t('TEAMS_SETTINGS.ADD.DESC') }}
        </p>
      </div>

      <p
        v-if="v$.selectedAgents.$error"
        class="mb-3 text-[12.5px] text-destructive"
      >
        {{ $t('TEAMS_SETTINGS.ADD.AGENT_VALIDATION_ERROR') }}
      </p>
      <AgentSelector
        :agent-list="agentList"
        :selected-agents="selectedAgents"
        :update-selected-agents="updateSelectedAgents"
        :is-working="isCreating"
        :submit-button-text="$t('TEAMS_SETTINGS.ADD.BUTTON_TEXT')"
      />
    </form>
  </div>
</template>
