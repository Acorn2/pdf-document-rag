<template>
  <div id="app">
    <el-container class="main-container">
      <!-- 头部导航 -->
      <el-header class="app-header">
        <div class="header-content">
          <div class="logo">
            <el-icon><Document /></el-icon>
            <span>PDF文献分析智能体</span>
          </div>
          <div class="header-actions">
            <el-button @click="checkHealth" :loading="healthLoading">
              <el-icon><Connection /></el-icon>
              检查连接
            </el-button>
          </div>
        </div>
      </el-header>

      <!-- 主要内容区域 -->
      <el-main class="app-main">
        <el-row :gutter="20">
          <!-- 左侧：文档上传和列表 -->
          <el-col :span="12">
            <DocumentUpload />
            <DocumentList @select-document="handleDocumentSelect" />
          </el-col>

          <!-- 右侧：聊天界面 -->
          <el-col :span="12">
            <ChatInterface />
          </el-col>
        </el-row>
      </el-main>
    </el-container>

    <!-- 全局加载遮罩 -->
    <el-loading
      v-if="globalLoading"
      element-loading-text="正在初始化..."
      element-loading-background="rgba(0, 0, 0, 0.8)"
      body-style="position: fixed; top: 0; left: 0; width: 100%; height: 100%;"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Document, Connection } from '@element-plus/icons-vue'
import DocumentUpload from '@/components/DocumentUpload.vue'
import DocumentList from '@/components/DocumentList.vue'
import ChatInterface from '@/components/ChatInterface.vue'
import { useDocumentsStore } from '@/stores/documents'
import { apiClient } from '@/api/client'
import type { Document as DocumentType } from '@/api/types'

const documentsStore = useDocumentsStore()

const globalLoading = ref(true)
const healthLoading = ref(false)

onMounted(async () => {
  try {
    // 检查服务健康状态
    await checkHealth()
    
    // 加载文档列表
    await documentsStore.fetchDocuments()
    
    ElMessage.success('系统初始化完成')
  } catch (error) {
    console.error('初始化失败:', error)
    ElMessage.error('系统初始化失败，请检查后端服务是否正常运行')
  } finally {
    globalLoading.value = false
  }
})

const checkHealth = async () => {
  healthLoading.value = true
  try {
    const health = await apiClient.healthCheck()
    if (health.status === 'healthy') {
      ElMessage.success('后端服务连接正常')
    } else {
      ElMessage.warning('后端服务状态异常')
    }
  } catch (error) {
    ElMessage.error('无法连接到后端服务')
  } finally {
    healthLoading.value = false
  }
}

const handleDocumentSelect = (document: DocumentType) => {
  console.log('选择文档:', document)
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  background-color: #f5f7fa;
}

#app {
  height: 100vh;
}

.main-container {
  height: 100%;
}

.app-header {
  background-color: #fff;
  border-bottom: 1px solid #e4e7ed;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 20px;
  font-weight: bold;
  color: #409eff;
}

.logo .el-icon {
  font-size: 24px;
}

.app-main {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

/* Element Plus 样式覆盖 */
.el-card {
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.el-button {
  border-radius: 6px;
}

.el-input__wrapper {
  border-radius: 6px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .el-col {
    margin-bottom: 20px;
  }
  
  .header-content {
    padding: 0 10px;
  }
  
  .app-main {
    padding: 10px;
  }
}
</style> 