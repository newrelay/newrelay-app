<script>
export default {
  computed: {
    items() {
      const steps = ['WIZARD_CREATE', 'WIZARD_ADD_AGENTS', 'WIZARD_FINISH'];

      const routes = {
        WIZARD_CREATE: 'settings_teams_new',
        WIZARD_ADD_AGENTS: 'settings_teams_add_agents',
        WIZARD_FINISH: 'settings_teams_finish',
      };

      return steps.map(step => {
        return {
          title: this.$t(`TEAMS_SETTINGS.CREATE_FLOW.${step}.TITLE`),
          body: this.$t(`TEAMS_SETTINGS.CREATE_FLOW.${step}.BODY`),
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
