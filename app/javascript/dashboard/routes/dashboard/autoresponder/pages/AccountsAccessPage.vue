<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import {
  RelayBadge,
  RelayButton,
  RelayDropdownMenu,
  RelayDropdownMenuTrigger,
  RelayDropdownMenuContent,
  RelayDropdownMenuItem,
} from 'dashboard/components-next/relay';
import AccountSwitcher from '../components/AccountSwitcher.vue';
import { useAutoresponderAccount } from '../composables/useAutoresponderAccount';

const { t } = useI18n();
const { accounts, updateAccount } = useAutoresponderAccount();

const instagramAccounts = computed(() =>
  accounts.value.filter(a => a.platform === 'Instagram')
);
const facebookAccounts = computed(() =>
  accounts.value.filter(a => a.platform === 'Facebook')
);

const teamOptions = [
  'Sales Team',
  'Support Team',
  'Marketing Team',
  'E-commerce Team',
  'Customer Care',
];

const allTeamMembers = [
  {
    id: 'u-1',
    name: 'John Smith',
    email: 'john@example.com',
    avatar: 'https://i.pravatar.cc/150?u=john',
  },
  {
    id: 'u-2',
    name: 'Sarah Miller',
    email: 'sarah@example.com',
    avatar: 'https://i.pravatar.cc/150?u=sarah',
  },
  {
    id: 'u-3',
    name: 'Elena Rostova',
    email: 'elena@example.com',
    avatar: 'https://i.pravatar.cc/150?u=elena',
  },
  {
    id: 'u-4',
    name: 'David Vance',
    email: 'david@example.com',
    avatar: 'https://i.pravatar.cc/150?u=david',
  },
  {
    id: 'u-5',
    name: 'Michael Chang',
    email: 'michael@example.com',
    avatar: 'https://i.pravatar.cc/150?u=michael',
  },
  {
    id: 'u-6',
    name: 'Aisha Robinson',
    email: 'aisha@example.com',
    avatar: 'https://i.pravatar.cc/150?u=aisha',
  },
];

const isDrawerOpen = ref(false);
const selectedAccount = ref(null);
const isAddingMember = ref(false);
const isSyncing = ref(false);
const drawerForm = ref({
  assignedTeam: '',
  accessLevel: 'Manager',
  assignedMembers: [],
});

function openManageDrawer(acc) {
  selectedAccount.value = acc;
  drawerForm.value = {
    assignedTeam: acc.assignedTeam,
    accessLevel: acc.accessLevel || 'Manager',
    assignedMembers: JSON.parse(JSON.stringify(acc.assignedMembers || [])),
  };
  isAddingMember.value = false;
  isDrawerOpen.value = true;
}

function addMemberToAccount(member) {
  if (!drawerForm.value.assignedMembers.some(m => m.id === member.id)) {
    drawerForm.value.assignedMembers.push({
      ...member,
      role: drawerForm.value.accessLevel,
    });
    useAlert(
      t('AUTORESPONDER.ACCOUNTS_ACCESS.ADDED_MEMBER', { name: member.name })
    );
  }
  isAddingMember.value = false;
}

function removeMemberFromAccount(memberId) {
  drawerForm.value.assignedMembers = drawerForm.value.assignedMembers.filter(
    m => m.id !== memberId
  );
}

function saveDrawerChanges() {
  if (selectedAccount.value) {
    updateAccount({
      ...selectedAccount.value,
      assignedTeam: drawerForm.value.assignedTeam,
      accessLevel: drawerForm.value.accessLevel,
      assignedMembers: drawerForm.value.assignedMembers,
    });
    useAlert(
      t('AUTORESPONDER.ACCOUNTS_ACCESS.SAVED', {
        handle: selectedAccount.value.handle,
      })
    );
  }
  isDrawerOpen.value = false;
}

function handleSyncNow() {
  if (isSyncing.value) return;
  isSyncing.value = true;
  setTimeout(() => {
    isSyncing.value = false;
    useAlert(t('AUTORESPONDER.ACCOUNTS_ACCESS.SYNCED'));
  }, 1200);
}

function handleConnect(platform) {
  useAlert(t(`AUTORESPONDER.ACCOUNTS_ACCESS.CONNECT_${platform}`));
}
</script>

<template>
  <div
    class="flex-1 overflow-y-auto w-full bg-background p-4 sm:p-6 lg:p-8 space-y-8 relative"
  >
    <div
      class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-border/40"
    >
      <div>
        <h1 class="text-[16px] font-medium text-foreground">
          {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.TITLE') }}
        </h1>
        <p class="text-[13.5px] text-muted-foreground mt-0.5 leading-relaxed">
          {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.SUBTITLE') }}
        </p>
      </div>
      <div class="flex items-center gap-3">
        <RelayButton
          variant="outline"
          size="sm"
          :disabled="isSyncing"
          class="group h-9 px-3.5 gap-2 rounded-lg bg-card border border-border shadow-xs hover:border-transparent cursor-pointer text-[13px] font-medium"
          @click="handleSyncNow"
        >
          <span
            class="i-lucide-refresh-cw size-3.5 text-muted-foreground group-hover:text-accent-foreground transition-colors"
            :class="{ 'animate-spin text-primary': isSyncing }"
          />
          <span>{{
            isSyncing
              ? t('AUTORESPONDER.ACCOUNTS_ACCESS.SYNCING')
              : t('AUTORESPONDER.ACCOUNTS_ACCESS.SYNC')
          }}</span>
        </RelayButton>
        <AccountSwitcher />
      </div>
    </div>

    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <span class="i-lucide-instagram size-4 text-rose-500" />
          <h2 class="text-base font-semibold text-foreground">
            {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.INSTAGRAM') }}
          </h2>
          <span
            class="text-[12px] font-medium px-2 py-0.5 rounded-full bg-muted text-muted-foreground"
          >
            {{
              t('AUTORESPONDER.ACCOUNTS_ACCESS.CONNECTED_COUNT', {
                count: instagramAccounts.length,
              })
            }}
          </span>
        </div>
        <RelayButton
          variant="outline"
          size="sm"
          class="h-8 gap-1.5 rounded-lg border border-border hover:border-transparent text-[13px] font-medium shadow-xs"
          @click="handleConnect('INSTAGRAM')"
        >
          <span class="i-lucide-plus size-3.5" />
          {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.CONNECT_INSTAGRAM_BTN') }}
        </RelayButton>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div
          v-for="acc in instagramAccounts"
          :key="acc.id"
          class="p-5 rounded-xl bg-card border border-border/70 shadow-xs hover:border-primary/40 transition-all flex flex-col justify-between space-y-5"
        >
          <div class="flex items-start justify-between gap-3">
            <div class="flex items-center gap-3 min-w-0">
              <div
                class="relative size-10 rounded-full overflow-hidden bg-muted border border-border shrink-0"
              >
                <img
                  :src="acc.avatar"
                  :alt="acc.name"
                  class="size-full object-cover"
                />
              </div>
              <div class="min-w-0">
                <div class="text-[14px] font-semibold text-foreground truncate">
                  {{ acc.handle }}
                </div>
                <div
                  class="text-[12px] text-emerald-600 dark:text-emerald-400 font-medium flex items-center gap-1 mt-0.5"
                >
                  <span class="size-1.5 rounded-full bg-emerald-500" />
                  {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.CONNECTED_ACTIVE') }}
                </div>
              </div>
            </div>
            <RelayBadge
              variant="secondary"
              class="text-[11px] font-medium shrink-0"
            >
              {{ acc.accessLevel }}
            </RelayBadge>
          </div>

          <div
            class="grid grid-cols-2 gap-2 p-3 rounded-lg bg-muted/40 border border-border/40 text-[12.5px]"
          >
            <div>
              <div class="text-muted-foreground text-[11.5px]">
                {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.AUTOMATIONS') }}
              </div>
              <div class="font-semibold text-foreground">
                {{
                  t('AUTORESPONDER.ACCOUNTS_ACCESS.ACTIVE_COUNT', {
                    count: acc.automationsCount,
                  })
                }}
              </div>
            </div>
            <div>
              <div class="text-muted-foreground text-[11.5px]">
                {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.AUDIENCE') }}
              </div>
              <div class="font-semibold text-foreground">
                {{ acc.followersCount }}
              </div>
            </div>
          </div>

          <div
            class="flex items-center justify-between pt-2 border-t border-border/40"
          >
            <div>
              <div class="text-[11.5px] text-muted-foreground">
                {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.ASSIGNED_TO') }}
              </div>
              <div
                class="text-[13px] font-medium text-foreground flex items-center gap-1.5"
              >
                <span class="i-lucide-users size-3.5 text-muted-foreground" />
                {{ acc.assignedTeam }}
              </div>
            </div>
            <RelayButton
              variant="outline"
              size="sm"
              class="h-8 px-3 gap-1 rounded-lg border border-border hover:border-transparent text-[12.5px] font-medium shadow-xs"
              @click="openManageDrawer(acc)"
            >
              <span>{{ t('AUTORESPONDER.ACCOUNTS_ACCESS.MANAGE') }}</span>
              <span class="i-lucide-arrow-right size-3.5" />
            </RelayButton>
          </div>
        </div>
      </div>
    </div>

    <div class="space-y-4 pt-4 border-t border-border/40">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <span class="i-lucide-facebook size-4 text-blue-600" />
          <h2 class="text-base font-semibold text-foreground">
            {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.FACEBOOK') }}
          </h2>
          <span
            class="text-[12px] font-medium px-2 py-0.5 rounded-full bg-muted text-muted-foreground"
          >
            {{
              t('AUTORESPONDER.ACCOUNTS_ACCESS.CONNECTED_COUNT', {
                count: facebookAccounts.length,
              })
            }}
          </span>
        </div>
        <RelayButton
          variant="outline"
          size="sm"
          class="h-8 gap-1.5 rounded-lg border border-border hover:border-transparent text-[13px] font-medium shadow-xs"
          @click="handleConnect('FACEBOOK')"
        >
          <span class="i-lucide-plus size-3.5" />
          {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.CONNECT_FACEBOOK_BTN') }}
        </RelayButton>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div
          v-for="acc in facebookAccounts"
          :key="acc.id"
          class="p-5 rounded-xl bg-card border border-border/70 shadow-xs hover:border-primary/40 transition-all flex flex-col justify-between space-y-5"
        >
          <div class="flex items-start justify-between gap-3">
            <div class="flex items-center gap-3 min-w-0">
              <div
                class="relative size-10 rounded-full overflow-hidden bg-muted border border-border shrink-0"
              >
                <img
                  :src="acc.avatar"
                  :alt="acc.name"
                  class="size-full object-cover"
                />
              </div>
              <div class="min-w-0">
                <div class="text-[14px] font-semibold text-foreground truncate">
                  {{ acc.handle }}
                </div>
                <div
                  class="text-[12px] text-emerald-600 dark:text-emerald-400 font-medium flex items-center gap-1 mt-0.5"
                >
                  <span class="size-1.5 rounded-full bg-emerald-500" />
                  {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.CONNECTED_ACTIVE') }}
                </div>
              </div>
            </div>
            <RelayBadge
              variant="secondary"
              class="text-[11px] font-medium shrink-0"
            >
              {{ acc.accessLevel }}
            </RelayBadge>
          </div>

          <div
            class="grid grid-cols-2 gap-2 p-3 rounded-lg bg-muted/40 border border-border/40 text-[12.5px]"
          >
            <div>
              <div class="text-muted-foreground text-[11.5px]">
                {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.AUTOMATIONS') }}
              </div>
              <div class="font-semibold text-foreground">
                {{
                  t('AUTORESPONDER.ACCOUNTS_ACCESS.ACTIVE_COUNT', {
                    count: acc.automationsCount,
                  })
                }}
              </div>
            </div>
            <div>
              <div class="text-muted-foreground text-[11.5px]">
                {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.FOLLOWERS') }}
              </div>
              <div class="font-semibold text-foreground">
                {{ acc.followersCount }}
              </div>
            </div>
          </div>

          <div
            class="flex items-center justify-between pt-2 border-t border-border/40"
          >
            <div>
              <div class="text-[11.5px] text-muted-foreground">
                {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.ASSIGNED_TO') }}
              </div>
              <div
                class="text-[13px] font-medium text-foreground flex items-center gap-1.5"
              >
                <span class="i-lucide-users size-3.5 text-muted-foreground" />
                {{ acc.assignedTeam }}
              </div>
            </div>
            <RelayButton
              variant="outline"
              size="sm"
              class="h-8 px-3 gap-1 rounded-lg border border-border hover:border-transparent text-[12.5px] font-medium shadow-xs"
              @click="openManageDrawer(acc)"
            >
              <span>{{ t('AUTORESPONDER.ACCOUNTS_ACCESS.MANAGE') }}</span>
              <span class="i-lucide-arrow-right size-3.5" />
            </RelayButton>
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="isDrawerOpen && selectedAccount"
      class="fixed inset-0 z-[100] bg-black/40 backdrop-blur-xs flex justify-end"
      @click="isDrawerOpen = false"
    >
      <div
        class="w-full max-w-[480px] h-full bg-card border-l border-border shadow-2xl flex flex-col pointer-events-auto"
        @click.stop
      >
        <div
          class="p-5 border-b border-border flex items-start justify-between gap-4"
        >
          <div class="flex items-center gap-3.5 min-w-0">
            <div
              class="relative size-12 rounded-full overflow-hidden bg-muted border border-border shrink-0"
            >
              <img
                :src="selectedAccount.avatar"
                :alt="selectedAccount.name"
                class="size-full object-cover"
              />
            </div>
            <div class="min-w-0">
              <div class="text-[12px] text-muted-foreground font-medium">
                {{
                  t('AUTORESPONDER.ACCOUNTS_ACCESS.PLATFORM_ACCOUNT', {
                    platform: selectedAccount.platform,
                  })
                }}
              </div>
              <h2 class="text-[15px] font-semibold text-foreground truncate">
                {{ selectedAccount.handle }}
              </h2>
              <div
                class="text-[12px] text-emerald-600 dark:text-emerald-400 font-medium flex items-center gap-1 mt-0.5"
              >
                <span class="size-1.5 rounded-full bg-emerald-500" />
                {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.CONNECTED') }}
              </div>
            </div>
          </div>
          <button
            type="button"
            class="p-1.5 rounded-lg text-muted-foreground hover:text-foreground hover:bg-muted transition-colors shrink-0"
            @click="isDrawerOpen = false"
          >
            <span class="i-lucide-x size-5" />
          </button>
        </div>

        <div class="flex-1 overflow-y-auto p-5 space-y-6">
          <div class="space-y-3">
            <label class="text-[13.5px] font-medium text-foreground">{{
              t('AUTORESPONDER.ACCOUNTS_ACCESS.ASSIGNED_TEAM')
            }}</label>
            <RelayDropdownMenu>
              <RelayDropdownMenuTrigger as-child>
                <RelayButton
                  variant="outline"
                  class="h-9 justify-between rounded-lg text-[13.5px] font-normal bg-background border border-border shadow-xs px-3 hover:border-transparent text-left w-full"
                >
                  <span>{{ drawerForm.assignedTeam }}</span>
                  <span
                    class="i-lucide-chevron-down size-3.5 opacity-50 ml-2 shrink-0"
                  />
                </RelayButton>
              </RelayDropdownMenuTrigger>
              <RelayDropdownMenuContent align="start" class="w-80 z-[150]">
                <RelayDropdownMenuItem
                  v-for="team in teamOptions"
                  :key="team"
                  class="text-[13px]"
                  @click="drawerForm.assignedTeam = team"
                >
                  <span>{{ team }}</span>
                  <span
                    v-if="drawerForm.assignedTeam === team"
                    class="i-lucide-check size-3.5 text-primary ml-auto"
                  />
                </RelayDropdownMenuItem>
              </RelayDropdownMenuContent>
            </RelayDropdownMenu>
          </div>

          <div class="space-y-3 pt-3 border-t border-border/40">
            <div class="flex items-center justify-between">
              <label class="text-[13.5px] font-medium text-foreground">{{
                t('AUTORESPONDER.ACCOUNTS_ACCESS.ASSIGNED_MEMBERS')
              }}</label>
              <RelayButton
                variant="ghost"
                size="sm"
                class="h-7 px-2 text-[12px] text-primary hover:bg-primary/10 border border-border hover:border-transparent"
                @click="isAddingMember = !isAddingMember"
              >
                <span class="i-lucide-plus size-3 mr-1" />
                {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.ADD_MEMBER') }}
              </RelayButton>
            </div>

            <div
              v-if="isAddingMember"
              class="p-3 rounded-lg bg-muted/40 border border-border space-y-2"
            >
              <div class="text-[12px] font-medium text-muted-foreground">
                {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.SELECT_MEMBER') }}
              </div>
              <div class="max-h-36 overflow-y-auto space-y-1">
                <div
                  v-for="cand in allTeamMembers"
                  :key="cand.id"
                  class="flex items-center justify-between p-2 rounded-md hover:bg-card border border-transparent hover:border-border cursor-pointer transition-colors"
                  @click="addMemberToAccount(cand)"
                >
                  <div class="flex items-center gap-2">
                    <img :src="cand.avatar" class="size-6 rounded-full" />
                    <div>
                      <div class="text-[12.5px] font-medium text-foreground">
                        {{ cand.name }}
                      </div>
                      <div class="text-[11px] text-muted-foreground">
                        {{ cand.email }}
                      </div>
                    </div>
                  </div>
                  <span class="i-lucide-plus size-3.5 text-primary" />
                </div>
              </div>
            </div>

            <div class="space-y-2">
              <div
                v-for="m in drawerForm.assignedMembers"
                :key="m.id"
                class="flex items-center justify-between p-2.5 rounded-lg bg-muted/30 border border-border/60"
              >
                <div class="flex items-center gap-2.5 min-w-0">
                  <img
                    :src="m.avatar"
                    class="size-7 rounded-full object-cover shrink-0"
                  />
                  <div class="min-w-0">
                    <div
                      class="text-[13px] font-medium text-foreground truncate"
                    >
                      {{ m.name }}
                    </div>
                    <div class="text-[11.5px] text-muted-foreground truncate">
                      {{ m.email }}
                    </div>
                  </div>
                </div>
                <div class="flex items-center gap-2 shrink-0">
                  <RelayBadge
                    variant="outline"
                    class="text-[11px] font-medium bg-card"
                  >
                    {{ drawerForm.accessLevel }}
                  </RelayBadge>
                  <button
                    type="button"
                    class="p-1 text-muted-foreground hover:text-destructive rounded transition-colors"
                    @click="removeMemberFromAccount(m.id)"
                  >
                    <span class="i-lucide-trash-2 size-3.5" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div class="space-y-3 pt-3 border-t border-border/40">
            <div>
              <label class="text-[13.5px] font-medium text-foreground">{{
                t('AUTORESPONDER.ACCOUNTS_ACCESS.ACCESS_LEVEL')
              }}</label>
              <p class="text-[12.5px] text-muted-foreground mt-0.5">
                {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.ACCESS_LEVEL_DESC') }}
              </p>
            </div>

            <div class="space-y-2.5">
              <div
                class="p-3.5 rounded-xl border transition-all cursor-pointer"
                :class="
                  drawerForm.accessLevel === 'Manager'
                    ? 'bg-primary/[0.03] border-primary shadow-xs'
                    : 'bg-card border-border hover:border-border/80'
                "
                @click="drawerForm.accessLevel = 'Manager'"
              >
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <div
                      class="size-4 rounded-full border flex items-center justify-center"
                      :class="
                        drawerForm.accessLevel === 'Manager'
                          ? 'border-primary bg-primary text-primary-foreground'
                          : 'border-muted-foreground'
                      "
                    >
                      <span
                        v-if="drawerForm.accessLevel === 'Manager'"
                        class="i-lucide-check size-2.5"
                      />
                    </div>
                    <span class="text-[13.5px] font-semibold text-foreground">{{
                      t('AUTORESPONDER.ACCOUNTS_ACCESS.MANAGER')
                    }}</span>
                  </div>
                  <span class="text-[11.5px] text-primary font-medium">{{
                    t('AUTORESPONDER.ACCOUNTS_ACCESS.MANAGER_BADGE')
                  }}</span>
                </div>
                <div class="mt-2.5 pl-6 space-y-1 text-[12px]">
                  <div class="text-muted-foreground flex items-center gap-1.5">
                    <span class="i-lucide-check size-3 text-emerald-500" />
                    {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.MANAGER_P1') }}
                  </div>
                  <div class="text-muted-foreground flex items-center gap-1.5">
                    <span class="i-lucide-check size-3 text-emerald-500" />
                    {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.MANAGER_P2') }}
                  </div>
                  <div class="text-muted-foreground flex items-center gap-1.5">
                    <span class="i-lucide-check size-3 text-emerald-500" />
                    {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.MANAGER_P3') }}
                  </div>
                  <div
                    class="text-muted-foreground/70 flex items-center gap-1.5 pt-0.5"
                  >
                    <span class="i-lucide-x size-3 text-rose-400" />
                    {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.MANAGER_P4') }}
                  </div>
                </div>
              </div>

              <div
                class="p-3.5 rounded-xl border transition-all cursor-pointer"
                :class="
                  drawerForm.accessLevel === 'Operator'
                    ? 'bg-primary/[0.03] border-primary shadow-xs'
                    : 'bg-card border-border hover:border-border/80'
                "
                @click="drawerForm.accessLevel = 'Operator'"
              >
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <div
                      class="size-4 rounded-full border flex items-center justify-center"
                      :class="
                        drawerForm.accessLevel === 'Operator'
                          ? 'border-primary bg-primary text-primary-foreground'
                          : 'border-muted-foreground'
                      "
                    >
                      <span
                        v-if="drawerForm.accessLevel === 'Operator'"
                        class="i-lucide-check size-2.5"
                      />
                    </div>
                    <span class="text-[13.5px] font-semibold text-foreground">{{
                      t('AUTORESPONDER.ACCOUNTS_ACCESS.OPERATOR')
                    }}</span>
                  </div>
                </div>
                <div class="mt-2.5 pl-6 space-y-1 text-[12px]">
                  <div class="text-muted-foreground flex items-center gap-1.5">
                    <span class="i-lucide-check size-3 text-emerald-500" />
                    {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.OPERATOR_P1') }}
                  </div>
                  <div
                    class="text-muted-foreground/70 flex items-center gap-1.5 pt-0.5"
                  >
                    <span class="i-lucide-x size-3 text-rose-400" />
                    {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.OPERATOR_P2') }}
                  </div>
                </div>
              </div>

              <div
                class="p-3.5 rounded-xl border transition-all cursor-pointer"
                :class="
                  drawerForm.accessLevel === 'Viewer'
                    ? 'bg-primary/[0.03] border-primary shadow-xs'
                    : 'bg-card border-border hover:border-border/80'
                "
                @click="drawerForm.accessLevel = 'Viewer'"
              >
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <div
                      class="size-4 rounded-full border flex items-center justify-center"
                      :class="
                        drawerForm.accessLevel === 'Viewer'
                          ? 'border-primary bg-primary text-primary-foreground'
                          : 'border-muted-foreground'
                      "
                    >
                      <span
                        v-if="drawerForm.accessLevel === 'Viewer'"
                        class="i-lucide-check size-2.5"
                      />
                    </div>
                    <span class="text-[13.5px] font-semibold text-foreground">{{
                      t('AUTORESPONDER.ACCOUNTS_ACCESS.VIEWER')
                    }}</span>
                  </div>
                </div>
                <div class="mt-2.5 pl-6 space-y-1 text-[12px]">
                  <div class="text-muted-foreground flex items-center gap-1.5">
                    <span class="i-lucide-check size-3 text-emerald-500" />
                    {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.VIEWER_P1') }}
                  </div>
                  <div
                    class="text-muted-foreground/70 flex items-center gap-1.5 pt-0.5"
                  >
                    <span class="i-lucide-x size-3 text-rose-400" />
                    {{ t('AUTORESPONDER.ACCOUNTS_ACCESS.VIEWER_P2') }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div
            class="p-3.5 rounded-xl bg-muted/40 border border-border/80 flex items-start gap-3"
          >
            <span class="i-lucide-lock size-4 text-primary shrink-0 mt-0.5" />
            <div class="text-[12px] leading-relaxed text-muted-foreground">
              <span class="font-medium text-foreground">{{
                t('AUTORESPONDER.ACCOUNTS_ACCESS.PRIVACY_TITLE')
              }}</span>
              {{
                t('AUTORESPONDER.ACCOUNTS_ACCESS.PRIVACY_BODY', {
                  handle: selectedAccount.handle,
                })
              }}
            </div>
          </div>
        </div>

        <div
          class="p-4 border-t border-border flex items-center justify-end gap-3 bg-muted/20"
        >
          <RelayButton
            variant="outline"
            class="h-9 px-4 rounded-lg border border-border hover:border-transparent text-[13.5px]"
            @click="isDrawerOpen = false"
          >
            {{ t('AUTORESPONDER.COMMON.CANCEL') }}
          </RelayButton>
          <RelayButton
            class="h-9 px-5 rounded-lg shadow-xs text-[13.5px]"
            @click="saveDrawerChanges"
          >
            {{ t('AUTORESPONDER.COMMON.SAVE_CHANGES') }}
          </RelayButton>
        </div>
      </div>
    </div>
  </div>
</template>
