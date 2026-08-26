# Repository Guidelines

## Architecture

Rails is the backend API only. Rails controllers must return JSON and must not render application UI. Vue owns all frontend pages, routing, state, and user interactions. Keep API endpoints consistently namespaced, such as `/api/v1`.

Vue must call Rails through the shared client in `app/javascript/api/http.ts`. Authenticated requests must send the JWT using the standard header:

```http
Authorization: Bearer <token>
```

Authentication and authorization must always be validated by Rails; never rely on frontend checks for access control.

## Project Structure & Module Organization

Rails code lives in `app/controllers`, `app/models`, `app/jobs`, and `app/mailers`. Vue code is under `app/javascript`: use `pages/` for file-based routes, `layouts/` for page shells, `components/` for reusable UI, `stores/` for Pinia state, and `api/` for Rails communication. Static files belong in `public/`; database definitions and seeds live in `db/`; configuration lives in `config/`. Tests belong in `test/` and should mirror the Rails structure.

## Build, Test, and Development Commands

- `bin/setup` installs dependencies and prepares the database.
- `bin/dev` starts Rails and Vite on `http://localhost:3000`.
- `bin/rails db:prepare` creates or migrates development and test databases.
- `bin/rails test` runs Minitest; `bin/rails test:system` runs browser tests.
- `npx vue-tsc --noEmit` checks Vue and TypeScript types.
- `bin/rubocop` checks Ruby style; `bin/brakeman` scans Rails security issues.
- `bin/ci` runs the complete local CI sequence.

## Coding Style & Naming Conventions

Use two-space indentation. Ruby follows `rubocop-rails-omakase`. TypeScript uses single quotes and no semicolons. Use `snake_case` for Ruby files and methods, `PascalCase` for classes and Vue components, `useThing` for composables, and `useThingStore` for Pinia stores.

Use Tailwind CSS utility classes for Vue styling. Do not add custom CSS when Tailwind can express the design. If custom CSS is genuinely necessary, keep it minimal and scoped to the component.

## Testing Guidelines

Name Minitest files `*_test.rb` and classes `*Test`. Add the smallest regression test that proves non-trivial API behavior, especially authentication and authorization. There is no JavaScript test runner or coverage threshold; type-check every frontend change.

## Commit & Pull Request Guidelines

Use short, imperative commit subjects such as `Add booking endpoint`. Keep commits focused. Pull requests should explain the change, list verification commands, link relevant issues, and include screenshots for visual changes. Never commit secrets, JWTs, local databases, logs, or generated build output.
