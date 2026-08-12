<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import {
  addMonths,
  eachDayOfInterval,
  endOfMonth,
  endOfWeek,
  format,
  isSameDay,
  isSameMonth,
  parse,
  setHours,
  setMinutes,
  startOfMonth,
  startOfWeek,
  subMonths,
} from 'date-fns';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import {
  RelayBadge,
  RelayButton,
  RelayCheckbox,
  RelayInput,
} from 'dashboard/components-next/relay';
import TasksAPI from 'dashboard/api/tasks';

const { t } = useI18n();
const store = useStore();

const tasks = ref([]);
const isFetching = ref(false);
const searchQuery = ref('');
const activeTab = ref('all');
const openFilter = ref(null);
const openTaskMenu = ref(null);

const assigneeFilter = ref('any');
const statusFilter = ref('all');
const dueDateFilter = ref('any');

const isTaskModalOpen = ref(false);
const editingTask = ref(null);
const duePickerMonth = ref(startOfMonth(new Date()));
const taskForm = ref({
  title: '',
  description: '',
  assigneeId: '',
  contactId: '',
  dueDate: '',
  dueTimeHour: '12',
  dueTimeMinute: '00',
  dueTimePeriod: 'PM',
});

const emptyTaskForm = () => {
  const now = new Date();
  let hour = now.getHours();
  const period = hour >= 12 ? 'PM' : 'AM';
  let hour12 = hour % 12;
  if (hour12 === 0) hour12 = 12;

  return {
    title: '',
    description: '',
    assigneeId: '',
    contactId: '',
    dueDate: '',
    dueTimeHour: String(hour12).padStart(2, '0'),
    dueTimeMinute: String(now.getMinutes()).padStart(2, '0'),
    dueTimePeriod: period,
  };
};

const parseDueAtToForm = dueAt => {
  if (!dueAt) return emptyTaskForm();

  const date = new Date(dueAt);
  let hour = date.getHours();
  const period = hour >= 12 ? 'PM' : 'AM';
  let hour12 = hour % 12;
  if (hour12 === 0) hour12 = 12;

  return {
    dueDate: format(date, 'dd-MM-yyyy'),
    dueTimeHour: String(hour12).padStart(2, '0'),
    dueTimeMinute: String(date.getMinutes()).padStart(2, '0'),
    dueTimePeriod: period,
  };
};

const buildDueAtIso = () => {
  const { dueDate, dueTimeHour, dueTimeMinute, dueTimePeriod } = taskForm.value;
  if (!dueDate) return null;

  const parsed = parse(dueDate, 'dd-MM-yyyy', new Date());
  let hour = Number(dueTimeHour);
  if (dueTimePeriod === 'AM') {
    if (hour === 12) hour = 0;
  } else if (hour !== 12) {
    hour += 12;
  }

  return setMinutes(
    setHours(parsed, hour),
    Number(dueTimeMinute)
  ).toISOString();
};

const isTaskFormValid = computed(
  () =>
    taskForm.value.title.trim() !== '' &&
    taskForm.value.description.trim() !== ''
);

const dueDateTriggerLabel = computed(() => {
  if (!taskForm.value.dueDate) {
    return t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_DUE_DATE_PLACEHOLDER');
  }

  return `${taskForm.value.dueDate} ${taskForm.value.dueTimeHour}:${taskForm.value.dueTimeMinute} ${taskForm.value.dueTimePeriod}`;
});

const duePickerMonthLabel = computed(() =>
  format(duePickerMonth.value, 'MMMM, yyyy')
);

const calendarDays = computed(() => {
  const start = startOfWeek(startOfMonth(duePickerMonth.value), {
    weekStartsOn: 1,
  });
  const end = endOfWeek(endOfMonth(duePickerMonth.value), { weekStartsOn: 1 });
  return eachDayOfInterval({ start, end });
});

const selectedDueDate = computed(() => {
  if (!taskForm.value.dueDate) return null;
  return parse(taskForm.value.dueDate, 'dd-MM-yyyy', new Date());
});

const weekdayLabels = computed(() => [
  t('CONTACTS_LAYOUT.TASKS_VIEW.WEEKDAY.MO'),
  t('CONTACTS_LAYOUT.TASKS_VIEW.WEEKDAY.TU'),
  t('CONTACTS_LAYOUT.TASKS_VIEW.WEEKDAY.WE'),
  t('CONTACTS_LAYOUT.TASKS_VIEW.WEEKDAY.TH'),
  t('CONTACTS_LAYOUT.TASKS_VIEW.WEEKDAY.FR'),
  t('CONTACTS_LAYOUT.TASKS_VIEW.WEEKDAY.SA'),
  t('CONTACTS_LAYOUT.TASKS_VIEW.WEEKDAY.SU'),
]);

const hourOptions = Array.from({ length: 12 }, (_, index) =>
  String(index + 1).padStart(2, '0')
);
const minuteOptions = Array.from({ length: 60 }, (_, index) =>
  String(index).padStart(2, '0')
);

const selectDueCalendarDay = day => {
  taskForm.value.dueDate = format(day, 'dd-MM-yyyy');
};

const clearDueDate = () => {
  taskForm.value.dueDate = '';
};

const setDueDateToday = () => {
  const today = new Date();
  duePickerMonth.value = startOfMonth(today);
  taskForm.value.dueDate = format(today, 'dd-MM-yyyy');
};

const shiftDuePickerMonth = direction => {
  duePickerMonth.value =
    direction === 'prev'
      ? subMonths(duePickerMonth.value, 1)
      : addMonths(duePickerMonth.value, 1);
};

const agents = useMapGetter('agents/getAgents');
const contacts = useMapGetter('contacts/getContactsList');

const timeframeTabs = computed(() => [
  { value: 'all', label: t('CONTACTS_LAYOUT.TASKS_VIEW.TAB_ALL') },
  { value: 'today', label: t('CONTACTS_LAYOUT.TASKS_VIEW.TAB_TODAY') },
  { value: 'overdue', label: t('CONTACTS_LAYOUT.TASKS_VIEW.TAB_OVERDUE') },
  { value: 'upcoming', label: t('CONTACTS_LAYOUT.TASKS_VIEW.TAB_UPCOMING') },
]);

const assigneeFilterOptions = computed(() => [
  {
    value: 'any',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.ASSIGNEE_ANY'),
  },
  {
    value: 'unassigned',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.ASSIGNEE_UNASSIGNED'),
  },
  ...(agents.value || []).map(agent => ({
    value: agent.id.toString(),
    label: agent.name,
  })),
]);

const statusFilterOptions = computed(() => [
  { value: 'all', label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.STATUS_ALL') },
  {
    value: 'pending',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.STATUS_PENDING'),
  },
  {
    value: 'completed',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.STATUS_COMPLETED'),
  },
]);

const dueDateFilterOptions = computed(() => [
  { value: 'any', label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.DUE_ANY') },
  { value: 'today', label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.DUE_TODAY') },
  {
    value: 'tomorrow',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.DUE_TOMORROW'),
  },
  { value: 'week', label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.DUE_WEEK') },
]);

const agentOptions = computed(() => [
  {
    value: '',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.ASSIGNEE_UNASSIGNED'),
  },
  ...(agents.value || []).map(agent => ({
    value: agent.id.toString(),
    label: agent.name,
  })),
]);

const contactOptions = computed(() => [
  {
    value: '',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_CONTACT_PLACEHOLDER'),
  },
  ...(contacts.value || []).map(contact => ({
    value: contact.id.toString(),
    label:
      contact.name ||
      contact.email ||
      t('CONTACTS_LAYOUT.CARD.UNNAMED_CONTACT'),
  })),
]);

const assigneeFilterLabel = computed(() => {
  const selected = assigneeFilterOptions.value.find(
    option => option.value === assigneeFilter.value
  );
  return selected?.label || assigneeFilterOptions.value[0].label;
});

const statusFilterLabel = computed(() => {
  const selected = statusFilterOptions.value.find(
    option => option.value === statusFilter.value
  );
  return selected?.label || statusFilterOptions.value[0].label;
});

const dueDateFilterLabel = computed(() => {
  const selected = dueDateFilterOptions.value.find(
    option => option.value === dueDateFilter.value
  );
  return selected?.label || dueDateFilterOptions.value[0].label;
});

const startOfDay = date => {
  const next = new Date(date);
  next.setHours(0, 0, 0, 0);
  return next;
};

const endOfDay = date => {
  const next = new Date(date);
  next.setHours(23, 59, 59, 999);
  return next;
};

const matchesClientDueDate = task => {
  if (dueDateFilter.value === 'any') return true;
  if (!task.due_at) return false;

  const due = new Date(task.due_at);
  const today = startOfDay(new Date());

  if (dueDateFilter.value === 'today') {
    return due >= today && due <= endOfDay(today);
  }

  if (dueDateFilter.value === 'tomorrow') {
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    return due >= tomorrow && due <= endOfDay(tomorrow);
  }

  if (dueDateFilter.value === 'week') {
    const weekEnd = new Date(today);
    weekEnd.setDate(weekEnd.getDate() + 7);
    return due >= today && due <= endOfDay(weekEnd);
  }

  return true;
};

const displayedTasks = computed(() =>
  tasks.value.filter(task => {
    if (assigneeFilter.value === 'unassigned' && task.assignee_id) {
      return false;
    }
    return matchesClientDueDate(task);
  })
);

const getAgentName = id => {
  if (!id) return '';
  const agent = (agents.value || []).find(
    item => item.id.toString() === id.toString()
  );
  return agent ? agent.name : '';
};

const getAgentOptionLabel = value => {
  const option = agentOptions.value.find(item => item.value === value);
  return option?.label || agentOptions.value[0].label;
};

const getContactOptionLabel = value => {
  const option = contactOptions.value.find(item => item.value === value);
  return option?.label || contactOptions.value[0].label;
};

const formatDate = dateString => {
  if (!dateString) return '';
  return new Date(dateString).toLocaleString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const isOverdue = task => {
  if (task.completed || !task.due_at) return false;
  return new Date(task.due_at) < new Date();
};

const statusLabelFor = task =>
  task.completed
    ? t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.STATUS_COMPLETED')
    : t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.STATUS_PENDING');

const closeMenus = () => {
  openFilter.value = null;
  openTaskMenu.value = null;
};

const toggleFilter = key => {
  openFilter.value = openFilter.value === key ? null : key;
  openTaskMenu.value = null;
};

const toggleTaskMenu = id => {
  openTaskMenu.value = openTaskMenu.value === id ? null : id;
  openFilter.value = null;
};

const fetchTasks = async () => {
  isFetching.value = true;
  try {
    const params = {
      q: searchQuery.value || undefined,
    };

    if (activeTab.value !== 'all') {
      params.due_filter = activeTab.value;
    } else if (dueDateFilter.value === 'today') {
      params.due_filter = 'today';
    }

    if (
      assigneeFilter.value !== 'any' &&
      assigneeFilter.value !== 'unassigned'
    ) {
      params.assignee_id = assigneeFilter.value;
    }

    if (statusFilter.value !== 'all') {
      params.completed = statusFilter.value === 'completed';
    }

    const response = await TasksAPI.get(params);
    tasks.value = response.data || [];
  } catch {
    // Ignore error
  } finally {
    isFetching.value = false;
  }
};

const setTab = tab => {
  activeTab.value = tab;
  if (tab !== 'all') {
    dueDateFilter.value = 'any';
  }
  fetchTasks();
};

const selectAssignee = value => {
  assigneeFilter.value = value;
  closeMenus();
};

const selectStatus = value => {
  statusFilter.value = value;
  closeMenus();
};

const selectDueDate = value => {
  dueDateFilter.value = value;
  if (value !== 'any') {
    activeTab.value = 'all';
  }
  closeMenus();
  fetchTasks();
};

const setTaskCompleted = async (task, completed) => {
  const originalVal = task.completed;
  task.completed = completed;
  try {
    await TasksAPI.update(task.id, { task: { completed } });
  } catch {
    task.completed = originalVal;
  }
};

const openAddTaskDialog = () => {
  editingTask.value = null;
  taskForm.value = emptyTaskForm();
  duePickerMonth.value = startOfMonth(new Date());
  closeMenus();
  isTaskModalOpen.value = true;
};

const openEditTaskDialog = task => {
  editingTask.value = task;
  const dueParts = parseDueAtToForm(task.due_at);
  taskForm.value = {
    title: task.title,
    description: task.description || '',
    assigneeId: task.assignee_id ? task.assignee_id.toString() : '',
    contactId: task.contacts?.[0]?.id ? task.contacts[0].id.toString() : '',
    dueDate: dueParts.dueDate,
    dueTimeHour: dueParts.dueTimeHour,
    dueTimeMinute: dueParts.dueTimeMinute,
    dueTimePeriod: dueParts.dueTimePeriod,
  };
  duePickerMonth.value = dueParts.dueDate
    ? startOfMonth(parse(dueParts.dueDate, 'dd-MM-yyyy', new Date()))
    : startOfMonth(new Date());
  closeMenus();
  isTaskModalOpen.value = true;
};

const closeTaskModal = () => {
  isTaskModalOpen.value = false;
  openFilter.value = null;
  editingTask.value = null;
};

const handleDeleteTask = async id => {
  closeMenus();
  if (!window.confirm(t('CONTACTS_LAYOUT.TASKS_VIEW.DELETE_CONFIRM'))) return;
  try {
    await TasksAPI.delete(id);
    tasks.value = tasks.value.filter(taskItem => taskItem.id !== id);
  } catch {
    // Ignore error
  }
};

const handleSaveTask = async () => {
  if (!isTaskFormValid.value) return;

  const payload = {
    task: {
      title: taskForm.value.title,
      description: taskForm.value.description,
      assignee_id: taskForm.value.assigneeId || null,
      due_at: buildDueAtIso(),
      contact_ids: taskForm.value.contactId
        ? [Number(taskForm.value.contactId)]
        : [],
    },
  };

  try {
    if (editingTask.value) {
      await TasksAPI.update(editingTask.value.id, payload);
    } else {
      await TasksAPI.create(payload);
    }
    fetchTasks();
    closeTaskModal();
  } catch {
    // Ignore error
  }
};

watch([assigneeFilter, statusFilter], () => {
  fetchTasks();
});

watch(searchQuery, () => {
  fetchTasks();
});

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('contacts/get', { page: 1 });
  fetchTasks();
});
</script>

<template>
  <div
    v-on-click-outside="closeMenus"
    class="relative flex h-full flex-1 flex-col overflow-y-auto bg-background p-6"
  >
    <div class="w-full">
      <!-- Header -->
      <div class="mb-6 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <h2 class="text-base font-semibold tracking-tight text-foreground">
            {{ t('CONTACTS_LAYOUT.TASKS_VIEW.TITLE') }}
          </h2>
          <RelayBadge
            class="rounded-full bg-primary px-2.5 py-0.5 text-xs font-semibold text-primary-foreground hover:bg-primary/90"
          >
            {{
              t('CONTACTS_LAYOUT.TASKS_VIEW.TASKS_COUNT', {
                count: displayedTasks.length,
              })
            }}
          </RelayBadge>
        </div>
        <RelayButton
          class="h-9 gap-1.5 rounded-lg px-4 text-sm font-medium shadow-sm"
          @click="openAddTaskDialog"
        >
          <span class="i-lucide-plus size-4" />
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.ADD_TASK') }}
        </RelayButton>
      </div>

      <!-- Timeframe tabs: absolute bar — global button { border-0 } kills border-b-2 -->
      <div class="mb-4 border-b border-border/60">
        <div class="flex items-center gap-6" role="tablist">
          <button
            v-for="tab in timeframeTabs"
            :key="tab.value"
            type="button"
            role="tab"
            :aria-selected="activeTab === tab.value"
            class="relative -mb-px rounded-none px-1 pb-2.5 text-[14px] font-medium transition-colors"
            :class="
              activeTab === tab.value
                ? 'text-foreground'
                : 'text-muted-foreground hover:text-foreground'
            "
            @click="setTab(tab.value)"
          >
            {{ tab.label }}
            <span
              v-if="activeTab === tab.value"
              class="absolute inset-x-0 bottom-0 h-0.5 bg-primary"
              aria-hidden="true"
            />
          </button>
        </div>
      </div>

      <!-- Filters -->
      <div class="mb-6 flex items-center justify-between gap-4 py-2">
        <div class="flex flex-wrap items-center gap-3">
          <div class="relative">
            <RelayButton
              variant="outline"
              class="h-9 gap-2 rounded-lg border-border bg-background px-3 text-[13px] font-medium text-foreground shadow-sm hover:bg-muted/50"
              @click="toggleFilter('assignee')"
            >
              <span class="font-normal text-muted-foreground">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.ASSIGNEE_LABEL') }}
              </span>
              {{ assigneeFilterLabel }}
              <span
                class="i-lucide-chevron-down size-3.5 text-muted-foreground opacity-50"
              />
            </RelayButton>
            <div
              v-if="openFilter === 'assignee'"
              class="absolute left-0 top-full z-50 mt-1 max-h-64 w-[220px] overflow-y-auto rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
            >
              <button
                v-for="option in assigneeFilterOptions"
                :key="option.value"
                type="button"
                class="flex w-full cursor-pointer items-center rounded-sm px-3 py-2 text-left text-[13px] text-foreground hover:bg-muted"
                :class="{ 'bg-muted': assigneeFilter === option.value }"
                @click="selectAssignee(option.value)"
              >
                {{ option.label }}
              </button>
            </div>
          </div>

          <div class="relative">
            <RelayButton
              variant="outline"
              class="h-9 gap-2 rounded-lg border-border bg-background px-3 text-[13px] font-medium text-foreground shadow-sm hover:bg-muted/50"
              @click="toggleFilter('status')"
            >
              <span class="font-normal text-muted-foreground">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.STATUS_LABEL') }}
              </span>
              {{ statusFilterLabel }}
              <span
                class="i-lucide-chevron-down size-3.5 text-muted-foreground opacity-50"
              />
            </RelayButton>
            <div
              v-if="openFilter === 'status'"
              class="absolute left-0 top-full z-50 mt-1 w-[200px] overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
            >
              <button
                v-for="option in statusFilterOptions"
                :key="option.value"
                type="button"
                class="flex w-full cursor-pointer items-center rounded-sm px-3 py-2 text-left text-[13px] text-foreground hover:bg-muted"
                :class="{ 'bg-muted': statusFilter === option.value }"
                @click="selectStatus(option.value)"
              >
                {{ option.label }}
              </button>
            </div>
          </div>

          <div class="relative">
            <RelayButton
              variant="outline"
              class="h-9 gap-2 rounded-lg border-border bg-background px-3 text-[13px] font-medium text-foreground shadow-sm hover:bg-muted/50"
              @click="toggleFilter('dueDate')"
            >
              <span class="font-normal text-muted-foreground">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.DUE_LABEL') }}
              </span>
              {{ dueDateFilterLabel }}
              <span
                class="i-lucide-chevron-down size-3.5 text-muted-foreground opacity-50"
              />
            </RelayButton>
            <div
              v-if="openFilter === 'dueDate'"
              class="absolute left-0 top-full z-50 mt-1 w-[200px] overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
            >
              <button
                v-for="option in dueDateFilterOptions"
                :key="option.value"
                type="button"
                class="flex w-full cursor-pointer items-center rounded-sm px-3 py-2 text-left text-[13px] text-foreground hover:bg-muted"
                :class="{ 'bg-muted': dueDateFilter === option.value }"
                @click="selectDueDate(option.value)"
              >
                {{ option.label }}
              </button>
            </div>
          </div>

          <div class="ml-2 flex items-center gap-1">
            <RelayButton
              variant="ghost"
              size="icon"
              class="size-8 rounded-md text-muted-foreground hover:text-foreground"
            >
              <span class="i-lucide-list-filter size-4" />
            </RelayButton>
            <RelayButton
              variant="ghost"
              size="icon"
              class="size-8 rounded-md text-muted-foreground hover:text-foreground"
            >
              <span class="i-lucide-arrow-up-down size-4" />
            </RelayButton>
          </div>
        </div>

        <div class="relative w-64 shrink-0">
          <span
            class="i-lucide-search pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
          />
          <RelayInput
            v-model="searchQuery"
            type="search"
            :placeholder="t('CONTACTS_LAYOUT.TASKS_VIEW.SEARCH_PLACEHOLDER')"
            class-name="h-9 rounded-lg border-border/80 bg-muted/20 pl-9 text-[13px] shadow-sm"
          />
        </div>
      </div>

      <!-- Content -->
      <div v-if="isFetching" class="flex h-[350px] items-center justify-center">
        <Spinner />
      </div>

      <div v-else-if="displayedTasks.length" class="flex flex-col gap-3">
        <div
          v-for="task in displayedTasks"
          :key="task.id"
          class="flex items-start gap-4 rounded-xl border border-border/60 bg-card p-4 shadow-sm transition-shadow hover:shadow-md"
        >
          <RelayCheckbox
            :model-value="!!task.completed"
            class="mt-1 border-muted-foreground/30"
            @update:model-value="value => setTaskCompleted(task, value)"
          />
          <div class="flex flex-1 flex-col gap-1.5">
            <div class="flex items-start justify-between gap-4">
              <div>
                <h3
                  class="text-[15px] font-semibold tracking-tight text-foreground"
                  :class="{
                    'line-through text-muted-foreground': task.completed,
                  }"
                >
                  {{ task.title }}
                </h3>
                <p
                  v-if="task.description"
                  class="mt-1 line-clamp-2 text-[13.5px] text-muted-foreground"
                >
                  {{ task.description }}
                </p>
              </div>
              <div class="flex items-center gap-2">
                <RelayBadge
                  variant="outline"
                  class="bg-muted/30 text-xs font-medium"
                >
                  {{ statusLabelFor(task) }}
                </RelayBadge>
                <div class="relative">
                  <RelayButton
                    variant="ghost"
                    size="icon"
                    class="size-7 text-muted-foreground hover:text-foreground"
                    @click="toggleTaskMenu(task.id)"
                  >
                    <span class="i-lucide-more-horizontal size-4" />
                  </RelayButton>
                  <div
                    v-if="openTaskMenu === task.id"
                    class="absolute right-0 top-full z-50 mt-1 w-[160px] overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
                  >
                    <button
                      type="button"
                      class="flex w-full cursor-pointer items-center gap-2 rounded-sm px-3 py-2 text-left text-[13px] text-foreground hover:bg-muted"
                      @click="openEditTaskDialog(task)"
                    >
                      <span class="i-lucide-pencil size-3.5" />
                      {{ t('CONTACTS_LAYOUT.TASKS_VIEW.EDIT_TASK') }}
                    </button>
                    <button
                      type="button"
                      class="flex w-full cursor-pointer items-center gap-2 rounded-sm px-3 py-2 text-left text-[13px] text-destructive hover:bg-destructive/10"
                      @click="handleDeleteTask(task.id)"
                    >
                      <span class="i-lucide-trash size-3.5" />
                      {{ t('CONTACTS_LAYOUT.TASKS_VIEW.DELETE_TASK') }}
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div class="mt-2 flex flex-wrap items-center gap-4">
              <div
                v-if="task.due_at"
                class="flex items-center gap-1.5 rounded-md px-2 py-0.5 text-[12px] font-medium"
                :class="
                  isOverdue(task)
                    ? 'bg-destructive/10 text-destructive'
                    : 'bg-muted/40 text-muted-foreground'
                "
              >
                <span class="i-lucide-calendar size-3.5" />
                {{ formatDate(task.due_at) }}
              </div>
              <div
                v-if="task.assignee_id"
                class="flex items-center gap-1.5 text-[12px] font-medium text-muted-foreground"
              >
                <span class="i-lucide-user size-3.5" />
                {{ getAgentName(task.assignee_id) }}
              </div>
              <div
                v-if="task.contacts?.length"
                class="flex items-center gap-1.5 text-[12px] font-medium text-muted-foreground"
              >
                <span class="i-lucide-link-2 size-3.5" />
                {{ task.contacts[0].name }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div
        v-else
        class="relative flex h-[350px] flex-col items-center justify-center rounded-xl border border-border/60 bg-card shadow-sm"
      >
        <h3 class="mb-1 text-[20px] font-semibold text-foreground">
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.NO_TASKS') }}
        </h3>
        <p class="text-[14px] font-medium text-muted-foreground">
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.NO_TASKS_SUBTITLE') }}
        </p>
      </div>
    </div>

    <Teleport to="body">
      <div
        v-if="isTaskModalOpen"
        data-relay
        class="fixed inset-0 z-[60] flex items-start justify-center overflow-y-auto bg-background/80 p-4 backdrop-blur-sm sm:items-center sm:p-6"
        @click.self="closeTaskModal"
      >
        <div
          class="flex w-full max-w-[480px] animate-in fade-in zoom-in-95 flex-col rounded-2xl border border-border bg-card shadow-xl duration-200"
        >
          <div class="border-b border-border px-6 py-5">
            <h2 class="text-base font-semibold tracking-tight text-foreground">
              {{
                editingTask
                  ? t('CONTACTS_LAYOUT.TASKS_VIEW.EDIT_TASK')
                  : t('CONTACTS_LAYOUT.TASKS_VIEW.ADD_TASK')
              }}
            </h2>
          </div>

          <div class="space-y-5 p-6" @click="closeMenus">
            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_TITLE') }}
              </label>
              <RelayInput
                v-model="taskForm.title"
                :placeholder="
                  t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_TITLE_PLACEHOLDER')
                "
                class-name="h-10 rounded-md border-border bg-background text-[14px] shadow-sm focus-visible:ring-primary/30"
              />
            </div>

            <div class="flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_DESCRIPTION') }}
              </label>
              <textarea
                v-model="taskForm.description"
                :placeholder="
                  t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_DESCRIPTION_PLACEHOLDER')
                "
                class="min-h-[100px] w-full resize-y rounded-md border border-solid border-border bg-background p-3 text-[14px] text-foreground shadow-sm outline-none placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
              />
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div class="relative flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_ASSIGNEE') }}
                </label>
                <RelayButton
                  variant="outline"
                  class="h-10 w-full justify-between rounded-md border-border bg-background px-3 text-[14px] font-normal text-foreground shadow-sm hover:bg-muted/50"
                  @click.stop="toggleFilter('formAssignee')"
                >
                  <span class="truncate">
                    {{ getAgentOptionLabel(taskForm.assigneeId) }}
                  </span>
                  <span class="i-lucide-chevron-down size-4 opacity-50" />
                </RelayButton>
                <div
                  v-if="openFilter === 'formAssignee'"
                  class="absolute left-0 right-0 top-full z-[70] mt-1 max-h-48 overflow-y-auto rounded-md border border-border bg-popover p-1 shadow-md"
                  @click.stop
                >
                  <button
                    v-for="option in agentOptions"
                    :key="`assignee-${option.value || 'none'}`"
                    type="button"
                    class="flex w-full cursor-pointer items-center rounded-sm px-3 py-2 text-left text-[13px] hover:bg-muted"
                    @click="
                      taskForm.assigneeId = option.value;
                      closeMenus();
                    "
                  >
                    {{ option.label }}
                  </button>
                </div>
              </div>

              <div class="relative flex flex-col gap-1.5">
                <label class="text-[13.5px] font-medium text-foreground">
                  {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_CONTACT') }}
                </label>
                <RelayButton
                  variant="outline"
                  class="h-10 w-full justify-between rounded-md border-border bg-background px-3 text-[14px] font-normal shadow-sm hover:bg-muted/50"
                  :class="
                    !taskForm.contactId
                      ? 'text-muted-foreground'
                      : 'text-foreground'
                  "
                  @click.stop="toggleFilter('formContact')"
                >
                  <span class="truncate">
                    {{ getContactOptionLabel(taskForm.contactId) }}
                  </span>
                  <span class="i-lucide-chevron-down size-4 opacity-50" />
                </RelayButton>
                <div
                  v-if="openFilter === 'formContact'"
                  class="absolute left-0 right-0 top-full z-[70] mt-1 max-h-48 overflow-y-auto rounded-md border border-border bg-popover p-1 shadow-md"
                  @click.stop
                >
                  <button
                    v-for="option in contactOptions"
                    :key="`contact-${option.value || 'none'}`"
                    type="button"
                    class="flex w-full cursor-pointer items-center rounded-sm px-3 py-2 text-left text-[13px] hover:bg-muted"
                    @click="
                      taskForm.contactId = option.value;
                      closeMenus();
                    "
                  >
                    {{ option.label }}
                  </button>
                </div>
              </div>
            </div>

            <div class="relative flex flex-col gap-1.5">
              <label class="text-[13.5px] font-medium text-foreground">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_DUE_DATE') }}
              </label>
              <RelayButton
                variant="outline"
                class="h-10 w-full justify-between rounded-md border-border bg-background px-3 text-[14px] font-normal shadow-sm hover:bg-muted/50"
                :class="
                  !taskForm.dueDate
                    ? 'text-muted-foreground'
                    : 'text-foreground'
                "
                @click.stop="toggleFilter('formDueDate')"
              >
                <span class="truncate">{{ dueDateTriggerLabel }}</span>
                <span
                  class="i-lucide-calendar size-4 text-foreground opacity-50"
                />
              </RelayButton>

              <div
                v-if="openFilter === 'formDueDate'"
                class="absolute left-0 top-full z-[70] mt-1 w-auto rounded-xl border border-border bg-popover p-4 shadow-xl"
                @click.stop
              >
                <div class="flex gap-4">
                  <div class="flex w-[220px] flex-col gap-3">
                    <div class="mb-2 flex items-center justify-between">
                      <div
                        class="-ml-2 flex cursor-default items-center gap-1 rounded-md px-2 py-1"
                      >
                        <span class="text-[13px] font-semibold text-foreground">
                          {{ duePickerMonthLabel }}
                        </span>
                        <span
                          class="i-lucide-chevron-down size-3.5 text-muted-foreground"
                        />
                      </div>
                      <div class="flex items-center gap-1">
                        <button
                          type="button"
                          class="flex size-7 cursor-pointer items-center justify-center rounded-md hover:bg-muted"
                          @click="shiftDuePickerMonth('prev')"
                        >
                          <span
                            class="i-lucide-arrow-up size-4 text-muted-foreground"
                          />
                        </button>
                        <button
                          type="button"
                          class="flex size-7 cursor-pointer items-center justify-center rounded-md hover:bg-muted"
                          @click="shiftDuePickerMonth('next')"
                        >
                          <span
                            class="i-lucide-arrow-down size-4 text-muted-foreground"
                          />
                        </button>
                      </div>
                    </div>

                    <div
                      class="grid grid-cols-7 gap-1 text-center text-[11px] font-semibold text-muted-foreground"
                    >
                      <div v-for="dayLabel in weekdayLabels" :key="dayLabel">
                        {{ dayLabel }}
                      </div>
                    </div>

                    <div class="grid grid-cols-7 gap-y-1 text-[13px]">
                      <button
                        v-for="day in calendarDays"
                        :key="day.toISOString()"
                        type="button"
                        class="flex size-8 items-center justify-center rounded-md p-0 font-medium outline-none"
                        :class="
                          !isSameMonth(day, duePickerMonth)
                            ? 'cursor-default text-muted-foreground/30'
                            : selectedDueDate && isSameDay(day, selectedDueDate)
                              ? 'cursor-pointer bg-primary text-primary-foreground shadow-sm hover:bg-primary/90'
                              : 'cursor-pointer text-foreground hover:bg-muted'
                        "
                        :disabled="!isSameMonth(day, duePickerMonth)"
                        @click="selectDueCalendarDay(day)"
                      >
                        {{ format(day, 'd') }}
                      </button>
                    </div>

                    <div
                      class="mt-1 flex items-center justify-between border-t border-border pt-3"
                    >
                      <button
                        type="button"
                        class="cursor-pointer text-[13px] font-medium text-primary hover:underline"
                        @click="clearDueDate"
                      >
                        {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_CLEAR') }}
                      </button>
                      <button
                        type="button"
                        class="cursor-pointer p-0 text-[13px] font-medium text-primary hover:underline focus:bg-transparent"
                        @click="setDueDateToday"
                      >
                        {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_TODAY') }}
                      </button>
                    </div>
                  </div>

                  <div class="flex w-[120px] gap-1 border-l border-border pl-4">
                    <div
                      class="flex h-[280px] flex-1 flex-col gap-1 overflow-y-auto pr-1 [scrollbar-width:none]"
                    >
                      <button
                        v-for="hour in hourOptions"
                        :key="`hour-${hour}`"
                        type="button"
                        class="w-full rounded py-1.5 text-center text-[13px] font-medium transition-colors"
                        :class="
                          taskForm.dueTimeHour === hour
                            ? 'bg-primary text-primary-foreground shadow-sm'
                            : 'text-foreground hover:bg-muted'
                        "
                        @click="taskForm.dueTimeHour = hour"
                      >
                        {{ hour }}
                      </button>
                    </div>
                    <div
                      class="flex h-[280px] flex-1 flex-col gap-1 overflow-y-auto pr-1 [scrollbar-width:none]"
                    >
                      <button
                        v-for="minute in minuteOptions"
                        :key="`minute-${minute}`"
                        type="button"
                        class="w-full rounded py-1.5 text-center text-[13px] font-medium transition-colors"
                        :class="
                          taskForm.dueTimeMinute === minute
                            ? 'bg-primary/20 text-primary'
                            : 'text-foreground hover:bg-muted'
                        "
                        @click="taskForm.dueTimeMinute = minute"
                      >
                        {{ minute }}
                      </button>
                    </div>
                    <div class="flex flex-1 flex-col gap-1">
                      <button
                        type="button"
                        class="w-full rounded py-1.5 text-center text-[13px] font-medium transition-colors"
                        :class="
                          taskForm.dueTimePeriod === 'AM'
                            ? 'bg-primary text-primary-foreground shadow-sm'
                            : 'text-foreground hover:bg-muted'
                        "
                        @click="taskForm.dueTimePeriod = 'AM'"
                      >
                        {{ 'AM' }}
                      </button>
                      <button
                        type="button"
                        class="w-full rounded py-1.5 text-center text-[13px] font-medium transition-colors"
                        :class="
                          taskForm.dueTimePeriod === 'PM'
                            ? 'bg-primary text-primary-foreground shadow-sm'
                            : 'text-foreground hover:bg-muted'
                        "
                        @click="taskForm.dueTimePeriod = 'PM'"
                      >
                        {{ 'PM' }}
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="mt-auto flex gap-4 border-t border-border px-6 py-4">
            <RelayButton
              variant="outline"
              class="h-9 flex-1 border-border bg-background text-sm font-medium shadow-sm hover:bg-muted"
              @click="closeTaskModal"
            >
              {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_CANCEL') }}
            </RelayButton>
            <RelayButton
              class="h-9 flex-1 text-sm font-medium shadow-sm disabled:pointer-events-none disabled:opacity-50"
              :disabled="!isTaskFormValid"
              @click="handleSaveTask"
            >
              {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_CONFIRM') }}
            </RelayButton>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
