<script>
export default {
  computed: {
    items() {
      const routes = {
        EDIT_WIZARD_DETAILS: 'settings_teams_edit',
        EDIT_WIZARD_AGENTS: 'settings_teams_edit_members',
        EDIT_WIZARD_FINISH: 'settings_teams_edit_finish',
      };

      const steps = [
        'EDIT_WIZARD_DETAILS',
        'EDIT_WIZARD_AGENTS',
        'EDIT_WIZARD_FINISH',
      ];

      return steps.map(step => {
        return {
          title: this.$t(`TEAMS_SETTINGS.EDIT_FLOW.${step}.TITLE`),
          body: this.$t(`TEAMS_SETTINGS.EDIT_FLOW.${step}.BODY`),
          route: routes[step],
        };
      });
    },
  },
};
</script>

<template>
  <div class="mx-auto mb-8 flex w-full max-w-7xl flex-col gap-6 !px-6">
    <div
      class="grid h-full min-h-[50dvh] w-full grid-cols-1 rounded-xl border border-border/60 bg-card shadow-xs lg:grid-cols-8 lg:divide-x lg:divide-border/40"
    >
      <woot-wizard
        class="hidden h-fit px-6 py-8 lg:col-span-2 lg:block"
        :items="items"
      />
      <router-view />
    </div>
  </div>
</template>
