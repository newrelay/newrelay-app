import { mount } from '@vue/test-utils';
import McpPermissionsForm from '../McpPermissionsForm.vue';

const ALL_TOOL_NAMES = [
  'list_accounts',
  'list_conversations',
  'get_conversation',
  'list_contacts',
  'get_contact',
  'list_inboxes',
  'list_agents',
  'list_teams',
  'list_labels',
  'add_private_note',
  'add_label',
  'remove_label',
  'assign_conversation',
  'set_priority',
];

describe('McpPermissionsForm.vue', () => {
  it('renders all 14 tools as checkboxes', () => {
    const wrapper = mount(McpPermissionsForm, {
      props: { initialScopes: [] },
    });

    expect(wrapper.findAll('[role="checkbox"]')).toHaveLength(14);
  });

  it('shows every tool checked when initialScopes is empty', () => {
    const wrapper = mount(McpPermissionsForm, {
      props: { initialScopes: [] },
    });

    const checkboxes = wrapper.findAll('[role="checkbox"]');
    checkboxes.forEach(checkbox => {
      expect(checkbox.attributes('aria-checked')).toBe('true');
    });
  });

  it('shows only the scoped tools checked when initialScopes is non-empty', () => {
    const wrapper = mount(McpPermissionsForm, {
      props: { initialScopes: ['list_inboxes', 'add_label'] },
    });

    const checked = wrapper
      .findAll('[role="checkbox"][aria-checked="true"]')
      .map(node => node.attributes('data-tool-name'));

    expect(checked).toEqual(
      expect.arrayContaining(['list_inboxes', 'add_label'])
    );
    expect(checked).toHaveLength(2);
  });

  it('disables Save until a checkbox is toggled', async () => {
    const wrapper = mount(McpPermissionsForm, {
      props: { initialScopes: ['list_inboxes'] },
    });

    expect(
      wrapper.findAll('button').at(-1).attributes('disabled')
    ).toBeDefined();

    await wrapper.find('[data-tool-name="add_label"]').trigger('click');

    expect(
      wrapper.findAll('button').at(-1).attributes('disabled')
    ).toBeUndefined();
  });

  it('keeps Save disabled when every tool is unchecked, even though the selection is dirty', async () => {
    const wrapper = mount(McpPermissionsForm, {
      props: { initialScopes: ['list_inboxes'] },
    });

    await wrapper.find('[data-tool-name="list_inboxes"]').trigger('click');

    expect(
      wrapper.findAll('button').at(-1).attributes('disabled')
    ).toBeDefined();
    expect(wrapper.emitted('save')).toBeUndefined();
  });

  it('emits save with the full explicit list of currently checked tool names', async () => {
    const wrapper = mount(McpPermissionsForm, {
      props: { initialScopes: [] },
    });

    await wrapper.find('[data-tool-name="list_accounts"]').trigger('click');
    await wrapper.findAll('button').at(-1).trigger('click');

    const emitted = wrapper.emitted('save');
    expect(emitted).toHaveLength(1);
    expect(emitted[0][0].sort()).toEqual(
      ALL_TOOL_NAMES.filter(name => name !== 'list_accounts').sort()
    );
  });
});
