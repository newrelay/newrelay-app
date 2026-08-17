<script setup>
import { RelayTooltip } from 'dashboard/components-next/relay';
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useI18n } from 'vue-i18n';

import semver from 'semver';

const { t } = useI18n();
const { currentAccount } = useAccount();

const latestChatwootVersion = computed(() => {
  return currentAccount.value.latest_chatwoot_version;
});

const globalConfig = useMapGetter('globalConfig/get');

const hasAnUpdateAvailable = computed(() => {
  if (
    !semver.valid(latestChatwootVersion.value) ||
    !semver.valid(globalConfig.value.appVersion)
  ) {
    return false;
  }

  return semver.lt(globalConfig.value.appVersion, latestChatwootVersion.value);
});

const gitSha = computed(() => {
  const sha = globalConfig.value.gitSha;
  if (!sha) return null;
  return sha.substring(0, 7);
});

const copyGitSha = () => {
  if (!globalConfig.value.gitSha) return;
  copyTextToClipboard(globalConfig.value.gitSha);
};
</script>

<template>
  <div class="p-4 text-sm text-center">
    <div v-if="hasAnUpdateAvailable && globalConfig.displayManifest">
      {{
        t('GENERAL_SETTINGS.UPDATE_CHATWOOT', {
          latestChatwootVersion: latestChatwootVersion,
        })
      }}
    </div>
    <div class="divide-x divide-muted-foreground">
      <span v-if="globalConfig.appVersion" class="px-2">{{
        `v${globalConfig.appVersion}`
      }}</span>
      <RelayTooltip :content="t('COMPONENTS.CODE.BUTTON_TEXT')">
        <span
          v-if="gitSha"
          class="px-2 build-id cursor-pointer"
          @click="copyGitSha"
        >
          {{ `Build ${gitSha}` }}
        </span>
      </RelayTooltip>
    </div>
  </div>
</template>
