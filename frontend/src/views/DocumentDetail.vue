<template>
  <div class="document-detail">
    <div class="page-header">
      <el-button @click="$router.back()" type="text">
        <el-icon><ArrowLeft /></el-icon>
        返回
      </el-button>
      <h1 v-if="document">{{ document.filename }}</h1>
    </div>

    <div v-if="loading" v-loading="true" style="height: 400px;"></div>
    
    <div v-else-if="document">
      <el-row :gutter="20">
        <!-- 文档信息 -->
        <el-col :span="8">
          <el-card>
            <template #header>
              <span>文档信息</span>
            </template>
            
            <el-descriptions :column="1" border>
              <el-descriptions-item label="文件名">
                {{ document.filename }}
              </el-descriptions-item>
              <el-descriptions-item label="状态">
                <el-tag :type="getStatusType(document.status)">
                  {{ getStatusText(document.status) }}
                </el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="页数">
                {{ document.pages }}
              </el-descriptions-item>
              <el-descriptions-item label="文本块数">
                {{ document.chunk_count || '-' }}
              </el-descriptions-item>
              <el-descriptions-item label="文件大小">
                {{ formatFileSize(document.file_size) }}
              </el-descriptions-item>
              <el-descriptions-item label="上传时间">
                {{ formatDateTime(document.upload_time) }}
              </el-descriptions-item>
            </el-descriptions>

            <div class="actions" style="margin-top: 20px;">
              <el-button 
                type="primary" 
                @click="$router.push(`/chat/${document.document_id}`)"
                :disabled="document.status !== 'completed'"
              >
                开始问答
              </el-button>
              <el-button @click="handleGenerateSummary">
                生成摘要
              </el-button>
            </div>
          </el-card>
        </el-col>

        <!-- 文档摘要 -->
        <el-col :span="16">
          <el-card>
            <template #header>
              <span>文档摘要</span>
            </template>
            
            <div v-loading="summaryLoading" style="min-height: 200px;">
              <div v-if="summary" class="summary-content">
                {{ summary }}
              </div>
              <el-empty v-else description="暂无摘要，点击生成摘要按钮" />
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <el-empty v-else description="文档不存在" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ArrowLeft } from '@element-plus/icons-vue'
import { apiClient } from '@/api/client'
import type { Document } from '@/api/types'

const route = useRoute()
const document = ref<Document | null>(null)
const loading = ref(false)
const summary = ref('')
const summaryLoading = ref(false)

onMounted(async () => {
  const documentId = route.params.id as string
  if (documentId) {
    await loadDocument(documentId)
  }
})

const loadDocument = async (documentId: string) => {
  loading.value = true
  try {
    document.value = await apiClient.getDocument(documentId)
  } catch (error) {
    console.error('加载文档失败:', error)
  } finally {
    loading.value = false
  }
}

const handleGenerateSummary = async () => {
  if (!document.value) return
  
  summaryLoading.value = true
  try {
    const response = await apiClient.generateSummary(document.value.document_id)
    summary.value = response.summary
  } catch (error) {
    console.error('生成摘要失败:', error)
  } finally {
    summaryLoading.value = false
  }
}

const getStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: 'info',
    processing: 'warning',
    completed: 'success',
    failed: 'danger'
  }
  return statusMap[status] || 'info'
}

const getStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    pending: '等待中',
    processing: '处理中',
    completed: '已完成',
    failed: '失败'
  }
  return statusMap[status] || status
}

const formatFileSize = (bytes: number) => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const formatDateTime = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}
</script>

<style scoped>
.document-detail {
  padding: 20px;
}

.page-header {
  display: flex;
  align-items: center;
  gap: 15px;
  margin-bottom: 30px;
}

.page-header h1 {
  margin: 0;
  color: #2c3e50;
}

.summary-content {
  line-height: 1.8;
  color: #606266;
  white-space: pre-wrap;
}
</style> 