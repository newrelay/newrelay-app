<script setup>
import { ref } from 'vue';
import Tabs from './Tabs.vue';
import TabsList from './TabsList.vue';
import TabsTrigger from './TabsTrigger.vue';
import TabsContent from './TabsContent.vue';

const tab = ref('account');
</script>

<template>
  <Story title="Relay/Tabs" :layout="{ type: 'grid', width: '560px' }">
    <Variant title="Default">
      <div class="p-4 bg-n-background">
        <Tabs v-model="tab">
          <TabsList>
            <TabsTrigger value="account">Account</TabsTrigger>
            <TabsTrigger value="password">Password</TabsTrigger>
            <TabsTrigger value="team">Team</TabsTrigger>
          </TabsList>
          <TabsContent value="account">
            <p class="text-sm text-n-slate-11">Account settings panel.</p>
          </TabsContent>
          <TabsContent value="password">
            <p class="text-sm text-n-slate-11">Password settings panel.</p>
          </TabsContent>
          <TabsContent value="team">
            <p class="text-sm text-n-slate-11">Team settings panel.</p>
          </TabsContent>
        </Tabs>
      </div>
    </Variant>
  </Story>
</template>
