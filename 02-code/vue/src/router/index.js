import { createRouter, createWebHistory } from 'vue-router'
import EmailLogs from '@/views/EmailLogs.vue'
import Login from '@/views/Login.vue'
import Register from '@/views/Register.vue'
import RoomsList from '@/views/RoomsList.vue'
import RoomDetail from '@/views/RoomDetail.vue'
import { authService } from '@/services/auth.service'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: RoomsList,  // Show rooms list as home page
    meta: { requiresAuth: true }
  },
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { requiresAuth: false }
  },
  {
    path: '/register',
    name: 'Register',
    component: Register,
    meta: { requiresAuth: false }
  },
  {
    path: '/rooms',
    name: 'RoomsList',
    component: RoomsList,
    meta: { requiresAuth: true }
  },
  {
    path: '/room/:location/:name',
    name: 'RoomDetail',
    component: RoomDetail,
    meta: { requiresAuth: true }
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/'
  },
  {
    path: '/emails',
    name: 'emails',
    component: EmailLogs,
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Auth guard
router.beforeEach((to, from, next) => {
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)
  const isAuthenticated = authService.isAuthenticated()

  if (requiresAuth && !isAuthenticated) {
    next('/login')
  } else if ((to.path === '/login' || to.path === '/register') && isAuthenticated) {
    next('/')
  } else {
    next()
  }
})

export default router
