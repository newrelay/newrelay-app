import ApiClient from './ApiClient';

class TasksAPI extends ApiClient {
  constructor() {
    super('tasks', { accountScoped: true });
  }
}

export default new TasksAPI();
