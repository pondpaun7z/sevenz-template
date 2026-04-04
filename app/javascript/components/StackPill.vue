<script setup lang="ts">
defineProps<{
  label: string
}>()
</script>

<template>
  <li
    class="rounded-full border border-slate-700 bg-slate-900/80 px-3 py-1 text-sm text-slate-300"
  >
    {{ label }}
  </li>
</template>
