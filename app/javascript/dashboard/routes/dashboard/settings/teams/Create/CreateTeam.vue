<script>
import { useAlert } from 'dashboard/composables';
import TeamForm from '../TeamForm.vue';
import router from '../../../../index';

export default {
  components: {
    TeamForm,
  },
  methods: {
    async createTeam(data) {
      try {
        const team = await this.$store.dispatch('teams/create', {
          ...data,
        });

        router.replace({
          name: 'settings_teams_add_agents',
          params: {
            page: 'new',
            teamId: team.id,
          },
        });
      } catch (error) {
        useAlert(this.$t('TEAMS_SETTINGS.TEAM_FORM.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <div class="w-full max-w-2xl animate-in fade-in duration-300">
    <div class="mb-6">
      <h3 class="mb-1 text-[16px] font-medium text-foreground">
        {{ $t('TEAMS_SETTINGS.CREATE_FLOW.CREATE.TITLE') }}
      </h3>
      <p class="text-[13.5px] text-muted-foreground">
        {{ $t('TEAMS_SETTINGS.CREATE_FLOW.CREATE.DESC') }}
      </p>
    </div>
    <TeamForm
      :on-submit="createTeam"
      :submit-in-progress="false"
      :submit-button-text="$t('TEAMS_SETTINGS.FORM.SUBMIT_CREATE')"
    />
  </div>
</template>
