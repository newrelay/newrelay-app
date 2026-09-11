import { mount } from '@vue/test-utils';
import ContactsBulkActionBar from './ContactsBulkActionBar.vue';

const mountBar = (selectedContactIds, visibleContactIds = [1, 2]) =>
  mount(ContactsBulkActionBar, {
    props: {
      visibleContactIds,
      selectedContactIds,
    },
    global: {
      stubs: {
        Policy: { template: '<div><slot /></div>' },
        BulkLabelActions: true,
      },
    },
  });

describe('ContactsBulkActionBar select-all checkbox', () => {
  it('emits toggleAll false when the checkbox is clicked while every row is selected', async () => {
    const wrapper = mountBar([1, 2]);
    const checkbox = wrapper.get('[role="checkbox"]');

    expect(checkbox.attributes('aria-checked')).toBe('true');
    await checkbox.trigger('click');

    expect(wrapper.emitted('toggleAll')).toEqual([[false]]);
  });

  it('emits toggleAll false when the select-all label is clicked while every row is selected', async () => {
    const wrapper = mountBar([1, 2]);

    await wrapper.get('button.tabular-nums').trigger('click');

    expect(wrapper.emitted('toggleAll')).toEqual([[false]]);
  });
});
