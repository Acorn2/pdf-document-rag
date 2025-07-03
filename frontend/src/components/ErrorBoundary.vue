<template>
  <div v-if="hasError" class="error-boundary">
    <el-result
      icon="error"
      title="出现错误"
      :sub-title="errorMessage"
    >
      <template #extra>
        <el-button type="primary" @click="handleReload">
          重新加载
        </el-button>
        <el-button @click="handleReset">
          重置应用
        </el-button>
      </template>
    </el-result>
  </div>
  <slot v-else />
</template>

<script setup lang="ts">
import { ref, onErrorCaptured } from 'vue'
import { ElMessage } from 'element-plus'

const hasError = ref(false)
const errorMessage = ref('')

onErrorCaptured((err: Error) => {
  hasError.value = true
  errorMessage.value = err.message || '未知错误'
  
  // 记录错误日志
  console.error('捕获到错误:', err)
  
  // 显示错误提示
  ElMessage.error('应用出现错误，请尝试刷新页面')
  
  return false
})

const handleReload = () => {
  window.location.reload()
}

const handleReset = () => {
  hasError.value = false
  errorMessage.value = ''
  // 清除本地存储
  localStorage.clear()
  sessionStorage.clear()
  window.location.reload()
}
</script>

<style scoped>
.error-boundary {
  padding: 50px;
  text-align: center;
}
</style> 