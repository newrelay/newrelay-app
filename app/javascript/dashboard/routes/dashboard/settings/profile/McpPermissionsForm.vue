<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { RelayCheckbox, RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  initialScopes: { type: Array, default: () => [] },
});

const emit = defineEmits(['save']);

const TOOL_GROUPS = [
  {
    key: 'read',
    labelKey: 'MCP_SETTINGS.GROUPS.READ',
    tools: [
      {
        name: 'list_accounts',
        labelKey: 'MCP_SETTINGS.TOOLS.LIST_ACCOUNTS.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_ACCOUNTS.DESCRIPTION',
      },
      {
        name: 'list_conversations',
        labelKey: 'MCP_SETTINGS.TOOLS.LIST_CONVERSATIONS.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_CONVERSATIONS.DESCRIPTION',
      },
      {
        name: 'get_conversation',
        labelKey: 'MCP_SETTINGS.TOOLS.GET_CONVERSATION.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.GET_CONVERSATION.DESCRIPTION',
      },
      {
        name: 'list_contacts',
        labelKey: 'MCP_SETTINGS.TOOLS.LIST_CONTACTS.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_CONTACTS.DESCRIPTION',
      },
      {
        name: 'get_contact',
        labelKey: 'MCP_SETTINGS.TOOLS.GET_CONTACT.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.GET_CONTACT.DESCRIPTION',
      },
      {
        name: 'list_inboxes',
        labelKey: 'MCP_SETTINGS.TOOLS.LIST_INBOXES.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_INBOXES.DESCRIPTION',
      },
      {
        name: 'list_agents',
        labelKey: 'MCP_SETTINGS.TOOLS.LIST_AGENTS.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_AGENTS.DESCRIPTION',
      },
      {
        name: 'list_teams',
        labelKey: 'MCP_SETTINGS.TOOLS.LIST_TEAMS.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_TEAMS.DESCRIPTION',
      },
      {
        name: 'list_labels',
        labelKey: 'MCP_SETTINGS.TOOLS.LIST_LABELS.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.LIST_LABELS.DESCRIPTION',
      },
    ],
  },
  {
    key: 'write',
    labelKey: 'MCP_SETTINGS.GROUPS.WRITE',
    tools: [
      {
        name: 'add_private_note',
        labelKey: 'MCP_SETTINGS.TOOLS.ADD_PRIVATE_NOTE.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.ADD_PRIVATE_NOTE.DESCRIPTION',
      },
      {
        name: 'add_label',
        labelKey: 'MCP_SETTINGS.TOOLS.ADD_LABEL.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.ADD_LABEL.DESCRIPTION',
      },
      {
        name: 'remove_label',
        labelKey: 'MCP_SETTINGS.TOOLS.REMOVE_LABEL.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.REMOVE_LABEL.DESCRIPTION',
      },
      {
        name: 'assign_conversation',
        labelKey: 'MCP_SETTINGS.TOOLS.ASSIGN_CONVERSATION.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.ASSIGN_CONVERSATION.DESCRIPTION',
      },
      {
        name: 'set_priority',
        labelKey: 'MCP_SETTINGS.TOOLS.SET_PRIORITY.LABEL',
        descriptionKey: 'MCP_SETTINGS.TOOLS.SET_PRIORITY.DESCRIPTION',
      },
    ],
  },
];

const ALL_TOOL_NAMES = TOOL_GROUPS.flatMap(group =>
  group.tools.map(tool => tool.name)
);

const { t } = useI18n();

const toBaseline = scopes =>
  scopes.length ? [...scopes] : [...ALL_TOOL_NAMES];

const savedTools = ref(toBaseline(props.initialScopes));
const selectedTools = ref(new Set(savedTools.value));

watch(
  () => props.initialScopes,
  newScopes => {
    savedTools.value = toBaseline(newScopes);
    selectedTools.value = new Set(savedTools.value);
  }
);

const isToolSelected = toolName => selectedTools.value.has(toolName);

const toggleTool = toolName => {
  const next = new Set(selectedTools.value);
  if (next.has(toolName)) {
    next.delete(toolName);
  } else {
    next.add(toolName);
  }
  selectedTools.value = next;
};

const isDirty = computed(() => {
  const current = [...selectedTools.value].sort();
  const saved = [...savedTools.value].sort();
  return (
    current.length !== saved.length ||
    current.some((tool, index) => tool !== saved[index])
  );
});

const handleSave = () => {
  const scopes = [...selectedTools.value];
  emit('save', scopes);
  savedTools.value = scopes;
};
</script>

<template>
  <div class="flex flex-col gap-8">
    <div
      v-for="group in TOOL_GROUPS"
      :key="group.key"
      class="flex flex-col gap-4"
    >
      <h3 class="text-sm font-semibold text-foreground">
        {{ t(group.labelKey) }}
      </h3>
      <div
        v-for="tool in group.tools"
        :key="tool.name"
        class="flex items-center justify-between gap-4"
      >
        <div class="max-w-[380px]">
          <div class="text-[13.5px] font-medium text-foreground">
            {{ t(tool.labelKey) }}
          </div>
          <p class="text-xs text-muted-foreground mt-0.5">
            {{ t(tool.descriptionKey) }}
          </p>
        </div>
        <RelayCheckbox
          :data-tool-name="tool.name"
          :model-value="isToolSelected(tool.name)"
          @update:model-value="toggleTool(tool.name)"
        />
      </div>
    </div>
    <div>
      <RelayButton
        type="button"
        :disabled="!isDirty || selectedTools.size === 0"
        @click="handleSave"
      >
        {{ t('MCP_SETTINGS.SAVE') }}
      </RelayButton>
    </div>
  </div>
</template>
