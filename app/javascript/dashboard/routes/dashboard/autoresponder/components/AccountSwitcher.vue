<script setup>
import { onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import {
  RelayButton,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
  RelayDropdownMenuSeparator,
} from 'dashboard/components-next/relay';
import {
  platformIconClass,
  useAutoresponderAccount,
} from '../composables/useAutoresponderAccount';

const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const { accounts, activeAccount, selectAccount, refreshAccounts } =
  useAutoresponderAccount();

onMounted(() => {
  refreshAccounts();
});

function goToAccountsAccess() {
  router.push(accountScopedRoute('autoresponder_accounts_access'));
}
</script>

<template>
  <RelayDropdownMenu>
    <RelayDropdownMenuTrigger as-child>
      <RelayButton
        variant="outline"
        class="h-9 gap-2 rounded-lg text-[13.5px] font-medium bg-card border border-border shadow-xs px-3 hover:border-transparent cursor-pointer"
      >
        <span
          :class="platformIconClass(activeAccount.platform)"
          class="size-4 text-muted-foreground shrink-0"
        />
        <span class="font-medium text-foreground">{{
          activeAccount.handle
        }}</span>
        <span class="text-[11.5px] text-muted-foreground hidden sm:inline"
          >({{ activeAccount.platform }})</span
        >
        <span
          class="i-lucide-chevron-down size-3.5 opacity-50 ml-1 text-muted-foreground"
        />
      </RelayButton>
    </RelayDropdownMenuTrigger>

    <RelayDropdownMenuContent align="end" class="w-64 z-[150]">
      <RelayDropdownMenuItem
        v-for="acc in accounts"
        :key="acc.id"
        class="flex items-center gap-2.5 py-2 cursor-pointer"
        @click="selectAccount(acc.id)"
        @select="selectAccount(acc.id)"
      >
        <span
          :class="platformIconClass(acc.platform)"
          class="size-4 text-muted-foreground shrink-0"
        />
        <div class="flex-1 min-w-0">
          <div class="text-[13.5px] font-medium text-foreground truncate">
            {{ acc.handle }}
          </div>
          <div class="text-[11.5px] text-muted-foreground">
            {{ acc.platform }} &bull; {{ acc.followersCount }}
          </div>
        </div>
        <span
          v-if="String(activeAccount.id) === String(acc.id)"
          class="i-lucide-check size-4 text-primary shrink-0"
        />
      </RelayDropdownMenuItem>

      <RelayDropdownMenuSeparator />

      <RelayDropdownMenuItem
        class="text-[13px] text-primary flex items-center gap-2 cursor-pointer"
        @click="goToAccountsAccess"
      >
        <span class="i-lucide-plus size-3.5" />
        <span>{{ t('AUTORESPONDER.ACCOUNT_SWITCHER.CONNECT') }}</span>
      </RelayDropdownMenuItem>

      <RelayDropdownMenuItem
        class="text-[13px] text-muted-foreground hover:text-foreground flex items-center justify-between cursor-pointer"
        @click="goToAccountsAccess"
      >
        <span>{{ t('AUTORESPONDER.ACCOUNT_SWITCHER.MANAGE') }}</span>
        <span class="i-lucide-arrow-right size-3.5 opacity-70" />
      </RelayDropdownMenuItem>
    </RelayDropdownMenuContent>
  </RelayDropdownMenu>
</template>
