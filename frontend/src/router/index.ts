import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/Home.vue'),
    meta: { title: 'PDF文献分析智能体' }
  },
  {
    path: '/documents',
    name: 'Documents',
    component: () => import('@/views/Documents.vue'),
    meta: { title: '文档管理' }
  },
  {
    path: '/documents/:id',
    name: 'DocumentDetail',
    component: () => import('@/views/DocumentDetail.vue'),
    meta: { title: '文档详情' }
  },
  {
    path: '/chat/:documentId?',
    name: 'Chat',
    component: () => import('@/views/Chat.vue'),
    meta: { title: '智能问答' }
  },
  {
    path: '/settings',
    name: 'Settings',
    component: () => import('@/views/Settings.vue'),
    meta: { title: '系统设置' }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/NotFound.vue'),
    meta: { title: '页面未找到' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// 路由守卫
router.beforeEach((to, from, next) => {
  // 设置页面标题
  if (to.meta?.title) {
    document.title = `${to.meta.title} - PDF文献分析智能体`
  }
  
  next()
})

export default router 