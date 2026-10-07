import type { Component } from 'vue'
import type { RouteRecordRaw } from 'vue-router'

const layouts = import.meta.glob<Component>('../layouts/**/*.vue', { import: 'default' })

export function setupLayouts(routes: RouteRecordRaw[], top = true): RouteRecordRaw[] {
  return routes.map((route) => {
    const group = !route.component && !('components' in route)
    const children = route.children ? setupLayouts(route.children, group ? top : false) : undefined
    const page = { ...route, ...(children ? { children } : {}) } as RouteRecordRaw
    const layout = route.meta?.layout
    const hasLayout = typeof layout === 'string' && layout.length > 0

    if (group || layout === false || (!top && !hasLayout)) return page

    const name = hasLayout ? layout : 'default'
    const component = layouts[`../layouts/${name}.vue`]
    if (!component) throw new Error(`Unknown layout: ${name}`)

    return {
      path: route.path,
      component,
      children: [{ ...page, path: top && route.path === '/' ? '/' : '' }],
      meta: { isLayout: true },
    }
  })
}
