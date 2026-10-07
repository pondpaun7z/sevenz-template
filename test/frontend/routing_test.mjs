import assert from 'node:assert/strict'
import { mkdtemp, mkdir, readFile, rm, symlink, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { createSSRApp, h } from 'vue'
import { renderToString } from '@vue/server-renderer'
import { createMemoryHistory, createRouter, RouterView } from 'vue-router'
import VueRouter from 'vue-router/vite'
import vue from '@vitejs/plugin-vue'
import { createServer } from 'vite'

const project = fileURLToPath(new URL('../../', import.meta.url))

test('file routes render default, named, disabled, and nested layouts', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'sevenz-routing-'))
  let server

  try {
    await symlink(path.join(project, 'node_modules'), path.join(root, 'node_modules'), 'dir')
    const fixtures = {
      'router/layouts.ts': await readFile(path.join(project, 'app/javascript/router/layouts.ts'), 'utf8'),
      'layouts/default.vue': '<template><section data-layout="default"><RouterView /></section></template>',
      'layouts/named.vue': '<template><section data-layout="named"><RouterView /></section></template>',
      'pages/index.vue': '<template><div data-page="home">Home</div></template>',
      'pages/named.vue': '<route lang="json">{"meta":{"layout":"named"}}</route><template><div data-page="named">Named</div></template>',
      'pages/plain.vue': '<route lang="json">{"meta":{"layout":false}}</route><template><div data-page="plain">Plain</div></template>',
      'pages/users/[id].vue': '<route lang="json">{"meta":{"layout":false}}</route><template><div data-page="user">User</div></template>',
      'pages/nested.vue': '<template><article data-page="parent"><RouterView /></article></template>',
      'pages/nested/child.vue': '<route lang="json">{"meta":{"layout":"named"}}</route><template><div data-page="child">Child</div></template>',
    }

    for (const [file, content] of Object.entries(fixtures)) {
      await mkdir(path.dirname(path.join(root, file)), { recursive: true })
      await writeFile(path.join(root, file), content)
    }

    server = await createServer({
      root,
      configFile: false,
      cacheDir: path.join(root, '.vite'),
      plugins: [VueRouter({ root, routesFolder: path.join(root, 'pages'), dts: false }), vue()],
      server: { middlewareMode: true, hmr: false },
      logLevel: 'error',
    })

    const { routes } = await server.ssrLoadModule('vue-router/auto-routes')
    const { setupLayouts } = await server.ssrLoadModule('/router/layouts.ts')
    const router = createRouter({ history: createMemoryHistory(), routes: setupLayouts(routes) })

    for (const [url, page, layouts] of [
      ['/', 'home', ['default']],
      ['/named', 'named', ['named']],
      ['/plain', 'plain', []],
      ['/users/42', 'user', []],
      ['/nested/child', 'child', ['default', 'named']],
    ]) {
      await router.push(url)
      const app = createSSRApp({ render: () => h(RouterView) }).use(router)
      const html = await renderToString(app)
      assert.ok(html.includes(`data-page="${page}"`), `${url} must render its page`)
      assert.deepEqual([...html.matchAll(/data-layout="([^"]+)"/g)].map((match) => match[1]), layouts, url)
    }

    await router.push('/users/42')
    assert.equal(router.currentRoute.value.params.id, '42')
  } finally {
    await server?.close()
    await rm(root, { recursive: true, force: true })
  }
})
