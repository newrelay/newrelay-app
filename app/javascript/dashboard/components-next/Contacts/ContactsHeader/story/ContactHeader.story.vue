<script setup>
import { ref } from 'vue';
import ContactHeader from '../ContactHeader.vue';

// Base state controls
const searchValue = ref('');

const onSearch = value => {
  searchValue.value = value;
  console.log('🔍 Search:', value);
};

const onFilter = () => {
  console.log('🏷️ Filter clicked');
};

const onMessage = () => {
  console.log('💬 Message clicked');
};

const onAdd = () => {
  console.log('➕ Add contact clicked');
};

const onImport = () => {
  console.log('📥 Import contacts clicked');
};

const onExport = () => {
  console.log('📤 Export contacts clicked');
};
</script>

<template>
  <Story
    title="Components/Contacts/ContactHeader"
    :layout="{ type: 'grid', width: '900px' }"
  >
    <Variant title="Default">
      <div class="w-full h-[400px]">
        <ContactHeader
          header-title="Contacts"
          button-label="Message"
          :search-value="searchValue"
          @search="onSearch"
          @filter="onFilter"
          @message="onMessage"
          @add="onAdd"
          @import="onImport"
          @export="onExport"
        />
      </div>
    </Variant>

    <Variant title="Empty State">
      <div class="w-full">
        <ContactHeader
          :show-search="false"
          header-title="Contacts"
          button-label="Message"
          :search-value="searchValue"
          @search="onSearch"
          @filter="onFilter"
          @message="onMessage"
          @add="onAdd"
          @import="onImport"
          @export="onExport"
        />
      </div>
    </Variant>

    <Variant title="Segment View">
      <div class="w-full">
        <ContactHeader
          :show-search="false"
          header-title="Segment: VIP Customers"
          button-label="Message"
          :search-value="searchValue"
          @search="onSearch"
          @filter="onFilter"
          @message="onMessage"
          @add="onAdd"
          @import="onImport"
          @export="onExport"
        />
      </div>
    </Variant>
  </Story>
</template>
