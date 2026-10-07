# Project decisions

## 2026-10-07: Use built-in file routing and layout discovery

Context: The page and layout plugins pull in unpatched `braces`, failing the full npm security audit.
Decision: Use the installed Vue Router 5 Vite plugin for file-based pages and Vite glob imports for layouts.
Consequence: Remove both vulnerable plugin dependency chains while retaining default, named, nested, and disabled layouts. Generated routes are imported from `vue-router/auto-routes`.
