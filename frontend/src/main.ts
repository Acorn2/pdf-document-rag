import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import 'element-plus/dist/index.css'
import 'element-plus/theme-chalk/dark/css-vars.css'

import App from './App.vue'
import router from './router'
import ErrorBoundary from './components/ErrorBoundary.vue'

// 导入全局样式
import './styles/global.scss'

const app = createApp(App)

// 注册插件
app.use(createPinia())
app.use(router)
app.use(ElementPlus)

// 注册所有图标
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

// 注册全局组件
app.component('ErrorBoundary', ErrorBoundary)

// 全局错误处理
app.config.errorHandler = (err, instance, info) => {
  console.error('全局错误:', err, info)
}

// 全局属性
app.config.globalProperties.$version = import.meta.env.VITE_APP_VERSION

app.mount('#app') 