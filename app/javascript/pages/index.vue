<script setup lang="ts">
const stack = [
  'Ruby on Rails 8',
  'Vue 3',
  'TypeScript',
  'PostgreSQL',
  'Tailwind CSS',
  'Vite',
  'Pinia',
  'Vue Router',
  'Axios',
  'Day.js',
] as const

const appStore = useAppStore()
const today = dayjs().format('MMMM D, YYYY')
</script>

<template>
  <div class="flex flex-col items-center justify-center px-6 py-16">
    <div class="max-w-lg w-full text-center space-y-8">
      <div class="space-y-2">
        <p class="text-sm font-medium uppercase tracking-[0.2em] text-emerald-400/90">
          {{ appStore.title }}
        </p>
        <h1 class="text-3xl sm:text-4xl font-semibold tracking-tight">
          Rails + Vue + TypeScript
        </h1>
        <p class="text-slate-400 text-base leading-relaxed">
          Single-page shell with file-based pages, layouts, auto-imports, and Pinia.
        </p>
        <p class="text-xs text-slate-500">
          Today (dayjs): {{ today }}
        </p>
      </div>

      <ul class="flex flex-wrap justify-center gap-2">
        <StackPill v-for="item in stack" :key="item" :label="item" />
      </ul>
    </div>
  </div>
</template>
