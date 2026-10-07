<script setup lang="ts">
defineProps<{
  url: string
  thumbnailUrl?: string | null
  filename: string
}>()
</script>

<template>
  <a
    :href="url"
    target="_blank"
    rel="noopener noreferrer"
    class="block overflow-hidden rounded-lg border border-slate-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600"
  >
    <img
      v-if="thumbnailUrl"
      :src="thumbnailUrl"
      :alt="filename"
      width="320"
      height="320"
      loading="lazy"
      decoding="async"
      class="aspect-square w-full bg-slate-50 object-contain"
    >
    <span class="block truncate px-3 py-2 text-sm">{{ filename }}</span>
  </a>
</template>
