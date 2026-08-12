<template>
  <div
    class="group flex flex-col justify-between gap-4 p-4 transition-colors hover:bg-muted/10 sm:flex-row sm:items-center"
  >
    <div class="flex min-w-0 flex-1 items-center gap-4">
      <slot name="leading" />
      <div class="flex min-w-0 flex-col">
        <slot />
      </div>
    </div>
    <div
      class="flex items-center gap-1 self-end pr-2 opacity-0 transition-opacity group-hover:opacity-100 sm:self-auto"
    >
      <slot name="actions" />
    </div>
  </div>
</template>
