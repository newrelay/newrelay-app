import { computed, ref } from 'vue';

const accounts = ref([
  {
    id: 'acc-1',
    name: 'Main',
    handle: '@newrelay',
    platform: 'Instagram',
    avatar:
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    status: 'Connected',
    automationsCount: 4,
    followersCount: '12,482 Followers',
    assignedTeam: 'Sales Team',
    assignedMembers: [
      {
        id: 'u-1',
        name: 'John Smith',
        email: 'john@example.com',
        avatar: 'https://i.pravatar.cc/150?u=john',
        role: 'Manager',
      },
      {
        id: 'u-2',
        name: 'Sarah Miller',
        email: 'sarah@example.com',
        avatar: 'https://i.pravatar.cc/150?u=sarah',
        role: 'Operator',
      },
    ],
    accessLevel: 'Manager',
    lastSync: 'Just now',
  },
  {
    id: 'acc-2',
    name: 'Support',
    handle: '@newrelay.support',
    platform: 'Instagram',
    avatar:
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    status: 'Connected',
    automationsCount: 7,
    followersCount: '5,821 Followers',
    assignedTeam: 'Support Team',
    assignedMembers: [
      {
        id: 'u-3',
        name: 'Elena Rostova',
        email: 'elena@example.com',
        avatar: 'https://i.pravatar.cc/150?u=elena',
        role: 'Manager',
      },
    ],
    accessLevel: 'Manager',
    lastSync: '5 mins ago',
  },
  {
    id: 'acc-3',
    name: 'Store',
    handle: '@newrelay.store',
    platform: 'Instagram',
    avatar:
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
    status: 'Connected',
    automationsCount: 3,
    followersCount: '8,150 Followers',
    assignedTeam: 'E-commerce Team',
    assignedMembers: [
      {
        id: 'u-5',
        name: 'Michael Chang',
        email: 'michael@example.com',
        avatar: 'https://i.pravatar.cc/150?u=michael',
        role: 'Operator',
      },
    ],
    accessLevel: 'Operator',
    lastSync: '12 mins ago',
  },
  {
    id: 'acc-4',
    name: 'Official Page',
    handle: 'fb.com/newrelay-official',
    platform: 'Facebook',
    avatar:
      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    status: 'Connected',
    automationsCount: 5,
    followersCount: '24,300 Likes',
    assignedTeam: 'Marketing Team',
    assignedMembers: [
      {
        id: 'u-1',
        name: 'John Smith',
        email: 'john@example.com',
        avatar: 'https://i.pravatar.cc/150?u=john',
        role: 'Manager',
      },
    ],
    accessLevel: 'Manager',
    lastSync: '1 hour ago',
  },
]);

const activeAccountId = ref('acc-1');

export function platformIconClass(platform) {
  if (platform === 'Instagram') return 'i-lucide-instagram';
  if (platform === 'Facebook') return 'i-lucide-facebook';
  return 'i-lucide-globe';
}

export function useAutoresponderAccount() {
  const activeAccount = computed(
    () =>
      accounts.value.find(a => a.id === activeAccountId.value) ||
      accounts.value[0]
  );

  function selectAccount(id) {
    activeAccountId.value = id;
  }

  function updateAccount(updated) {
    const idx = accounts.value.findIndex(a => a.id === updated.id);
    if (idx !== -1) {
      accounts.value[idx] = { ...updated };
    }
  }

  return {
    accounts,
    activeAccountId,
    activeAccount,
    selectAccount,
    updateAccount,
  };
}
