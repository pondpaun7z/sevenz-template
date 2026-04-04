import axios from 'axios'

/** Axios instance for Rails (JSON, same-origin). Add CSRF meta handling if you POST from outside Inertia/forms. */
export const http = axios.create({
  baseURL: '/',
  headers: {
    Accept: 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  },
})

export default http
