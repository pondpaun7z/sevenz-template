import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import RubyPlugin from 'vite-plugin-ruby'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import Pages from 'vite-plugin-pages'
import Layouts from 'vite-plugin-vue-layouts-next'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const jsRoot = path.resolve(__dirname, 'app/javascript')

export default defineConfig({
  plugins: [
    vue(),
    AutoImport({
      imports: [
        'vue',
        'vue-router',
        'pinia',
        {
          axios: [['default', 'axios']],
        },
        {
          dayjs: [['default', 'dayjs']],
        },
      ],
      dirs: [
        path.join(jsRoot, 'composables'),
        path.join(jsRoot, 'stores'),
      ],
      dts: path.join(jsRoot, 'auto-imports.d.ts'),
    }),
    Components({
      dirs: [path.join(jsRoot, 'components')],
      dts: path.join(jsRoot, 'components.d.ts'),
    }),
    Pages({
      dirs: 'app/javascript/pages',
    }),
    Layouts({
      layoutsDirs: 'app/javascript/layouts',
      pagesDirs: 'app/javascript/pages',
    }),
    RubyPlugin(),
  ],
  resolve: {
    alias: {
      '@': jsRoot,
    },
  },
})
