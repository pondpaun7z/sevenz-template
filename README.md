# sevenz-template

Public starter template: Rails 8 with a Vue 3 single-page front end: file-based pages, layouts, auto-imports, Pinia, and Vue Router, bundled with [Vite](https://vitejs.dev/) via [vite_rails](https://github.com/ElMassimo/vite_ruby).

## Stack

- **Backend:** Ruby on Rails 8, PostgreSQL, Puma, Propshaft  
- **Frontend:** Vue 3, TypeScript, Vite, Tailwind CSS, Pinia, Vue Router, Axios, Day.js  
- **Infra (optional):** Solid Cache / Solid Queue / Solid Cable, Kamal, Thruster

## Prerequisites

- Ruby **3.4.5** (see `.ruby-version`)
- Node.js and npm (for the Vite toolchain)
- PostgreSQL

## Setup

```bash
bundle install
npm install
bin/rails db:prepare
```

`db:prepare` creates the database if needed and loads schema (including Solid adapters when configured).

## Running locally

Start Rails and the Vite dev server together:

```bash
bin/dev
```

Then open [http://localhost:3000](http://localhost:3000). The root route serves the Vue shell from `app/javascript/`.

## Front-end layout

- **Entry:** `app/javascript/entrypoints/application.ts`
- **Pages:** `app/javascript/pages/` (via `vite-plugin-pages`)
- **Layouts:** `app/javascript/layouts/`
- **Stores:** `app/javascript/stores/`

## Tests

```bash
bin/rails test
bin/rails test:system   # Capybara + Selenium (requires drivers)
```

## Linting and security (development)

```bash
bin/rubocop
bin/brakeman
bundle exec bundler-audit check --update
```

## Deployment

This project includes Kamal and Thruster for container-style deploys; see the Kamal docs and your `config/deploy.yml` when you wire up hosting.

Production primary DB password is read from `SEVENZ_TEMPLATE_DATABASE_PASSWORD` (see `config/database.yml`).
