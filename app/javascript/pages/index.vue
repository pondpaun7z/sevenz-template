<script setup lang="ts">
const stack = [
  ['RA', 'Rails 8'], ['VU', 'Vue 3'], ['TS', 'TypeScript'],
  ['TW', 'Tailwind 4'], ['PG', 'Postgres'], ['VT', 'Vite'],
] as const

const copied = ref(false)

async function copySetup() {
  const command = 'bin/setup && bin/dev'
  try {
    await navigator.clipboard.writeText(command)
  } catch {
    const input = Object.assign(document.createElement('textarea'), { value: command })
    document.body.append(input)
    input.select()
    document.execCommand('copy')
    input.remove()
  }
  copied.value = true
  window.setTimeout(() => (copied.value = false), 1800)
}
</script>

<template>
  <main>
    <section class="hero-shell">
      <nav class="nav-wrap" aria-label="Main navigation">
        <a class="brand" href="#top" aria-label="Sevenz Template home"><img class="brand-mark" :src="'/sevenz-logo.svg'" alt=""><span>sevenz <small>template</small></span></a>
        <div class="nav-links"><a href="#features">Inside</a><a href="#stack">Stack</a><a href="https://github.com/pondpaun7z/sevenz-template" target="_blank" rel="noreferrer">GitHub ↗</a></div>
        <a class="nav-cta" href="#start">Use template <span>↗</span></a>
      </nav>

      <div id="top" class="hero-grid">
        <div class="hero-copy">
          <p class="eyebrow reveal reveal-1"><span></span> Rails on the back. Vue in the front.</p>
          <h1 class="reveal reveal-2">Skip the setup.<br><em>Ship the idea.</em></h1>
          <p class="hero-intro reveal reveal-3">A sharp, opinionated Rails 8 + Vue 3 starter for people who would rather build the product than assemble the plumbing.</p>
          <div class="hero-actions reveal reveal-4"><a class="button button-dark" href="#start">Start building <span>↗</span></a><a class="text-link" href="#features">See what’s inside <span>↓</span></a></div>
        </div>

        <div class="hero-visual reveal reveal-3" aria-label="Project architecture preview">
          <div class="orbit orbit-one"></div><div class="orbit orbit-two"></div><img class="seven-watermark" :src="'/sevenz-logo.svg'" alt="">
          <div class="code-card">
            <div class="code-head"><span><i></i><i></i><i></i></span><span>app/javascript/pages/index.vue</span></div>
            <pre><span class="code-faint">&lt;script setup lang="ts"&gt;</span>
<span class="code-accent">const</span> product = {
  backend: <span class="code-string">'Rails 8'</span>,
  frontend: <span class="code-string">'Vue 3'</span>,
  ready: <span class="code-accent">true</span>,
}
<span class="code-faint">&lt;/script&gt;</span>

<span class="code-faint">&lt;template&gt;</span>
  &lt;Ship <span class="code-accent">:fast="true"</span> /&gt;
<span class="code-faint">&lt;/template&gt;</span></pre>
          </div>
          <div class="status-chip"><span></span> dev server ready</div>
        </div>
      </div>

      <div class="hero-foot"><p>One repo.<br><strong>Zero glue code.</strong></p><div class="scroll-cue"><span></span> Scroll to unpack</div><p class="hero-note">Built for small teams<br>with big release energy.</p></div>
    </section>

    <section id="features" class="manifesto section-pad">
      <div class="section-kicker">01 / The shortcut</div>
      <div class="manifesto-grid">
        <h2>Everything connected.<br><em>Nothing in your way.</em></h2>
        <div class="manifesto-copy"><p>Sevenz handles the quiet, tedious work before your first commit: routing, state, typed imports, asset builds, and a production-ready Rails foundation.</p><p>What’s left is the good part—your product.</p></div>
      </div>
      <div class="feature-grid">
        <article><span class="feature-no">01</span><div class="feature-icon" aria-hidden="true">↗</div><h3>Pages become routes</h3><p>Add a Vue file. Get a route. The directory is the map—no registry to babysit.</p></article>
        <article><span class="feature-no">02</span><div class="feature-icon" aria-hidden="true">✦</div><h3>Imports, automated</h3><p>Vue APIs, stores, and components are available where you need them, fully typed.</p></article>
        <article><span class="feature-no">03</span><div class="feature-icon" aria-hidden="true">▱</div><h3>One clean deploy</h3><p>Rails serves the app. Vite builds it fast. Kamal takes the whole thing to production.</p></article>
      </div>
    </section>

    <section id="stack" class="stack-section section-pad">
      <div class="section-kicker light">02 / Good company</div>
      <div class="stack-heading"><h2>A modern stack.<br><em>Already introduced.</em></h2><p>Proven tools with the awkward handshakes handled. Every layer stays recognizable, replaceable, and yours.</p></div>
      <div class="stack-list">
        <div v-for="([short, name], index) in stack" :key="name" class="stack-row"><span class="stack-index">0{{ index + 1 }}</span><span class="stack-monogram">{{ short }}</span><strong>{{ name }}</strong><span class="stack-arrow">↗</span></div>
      </div>
    </section>

    <section id="start" class="start-section section-pad">
      <div class="start-badge">Ready when you are</div><h2>Make the first<br><em>real</em> commit.</h2><p>Clone it. Name it. Build the thing you came here to build.</p>
      <button class="command" type="button" @click="copySetup"><span><b>$</b> bin/setup &amp;&amp; bin/dev</span><span class="copy-state">{{ copied ? 'Copied!' : 'Copy' }}</span></button>
      <a class="button button-orange" href="https://github.com/pondpaun7z/sevenz-template/generate" target="_blank" rel="noreferrer">Use this template <span>↗</span></a>
    </section>

    <footer>
      <a class="brand footer-brand" href="#top"><img class="brand-mark" :src="'/sevenz-logo.svg'" alt=""><span>sevenz <small>template</small></span></a><p>Rails speed. Vue clarity.<br>Less ceremony.</p>
      <div class="footer-links"><a href="https://sevenz-studio.pages.dev/" target="_blank" rel="noreferrer">Sevenz Studio ↗</a><a href="https://github.com/pondpaun7z/sevenz-template" target="_blank" rel="noreferrer">GitHub ↗</a></div><p class="copyright">© {{ new Date().getFullYear() }} Sevenz Studio</p>
    </footer>
  </main>
</template>
