<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

import TeamForm from '../TeamForm.vue';
import router from '../../../../index';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    TeamForm,
    Spinner,
  },
  computed: {
    teamData() {
      const { teamId } = this.$route.params;
      return this.$store.getters['teams/getTeam'](teamId);
    },
    showTeamForm() {
      const { id } = this.teamData;
      return id && !this.uiFlags.isFetching;
    },
    ...mapGetters({
      uiFlags: 'teams/getUIFlags',
    }),
  },
  methods: {
    async updateTeam(data) {
      try {
        const { teamId } = this.$route.params;

        await this.$store.dispatch('teams/update', {
          id: teamId,
          ...data,
        });

        router.replace({
          name: 'settings_teams_edit_members',
          params: {
            page: 'edit',
            teamId,
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
        {{ $t('TEAMS_SETTINGS.EDIT_FLOW.CREATE.TITLE') }}
      </h3>
      <p class="text-[13.5px] text-muted-foreground">
        {{ $t('TEAMS_SETTINGS.EDIT_FLOW.CREATE.DESC') }}
      </p>
    </div>
    <TeamForm
      v-if="showTeamForm"
      :on-submit="updateTeam"
      :submit-in-progress="false"
      :submit-button-text="$t('TEAMS_SETTINGS.EDIT_FLOW.CREATE.BUTTON_TEXT')"
      :form-data="teamData"
    />
    <Spinner v-else />
  </div>
</template>
