/// <reference types="vite/client" />

declare module 'vue-router/auto-routes' {
  import type { RouteRecordRaw } from 'vue-router'
  export const routes: RouteRecordRaw[]
}

declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<object, object, unknown>
  export default component
}
