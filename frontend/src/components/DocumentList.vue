<template>
  <div class="document-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>文档列表</span>
          <el-button 
            type="primary" 
            size="small" 
            @click="documentsStore.fetchDocuments()"
            :loading="documentsStore.loading"
          >
            刷新
          </el-button>
        </div>
      </template>

      <el-table 
        :data="documentsStore.documents" 
        style="width: 100%"
        v-loading="documentsStore.loading"
      >
        <el-table-column prop="filename" label="文件名" min-width="200">
          <template #default="{ row }">
            <el-button 
              type="text" 
              @click="handleSelectDocument(row)"
              :disabled="row.status !== 'completed'"
            >
              {{ row.filename }}
            </el-button>
          </template>
        </el-table-column>

        <el-table-column prop="status" label="状态" width="120">
          <template #default="{ row }">
            <el-tag 
              :type="getStatusType(row.status)"
              effect="light"
            >
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="pages" label="页数" width="80" />
        
        <el-table-column prop="chunk_count" label="文本块" width="100">
          <template #default="{ row }">
            {{ row.chunk_count || '-' }}
          </template>
        </el-table-column>

        <el-table-column prop="file_size" label="文件大小" width="120">
          <template #default="{ row }">
            {{ formatFileSize(row.file_size) }}
          </template>
        </el-table-column>

        <el-table-column prop="upload_time" label="上传时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.upload_time) }}
          </template>
        </el-table-column>

        <el-table-column label="操作" width="200">
          <template #default="{ row }">
            <el-button 
              size="small" 
              @click="handleSelectDocument(row)"
              :disabled="row.status !== 'completed'"
            >
              查看
            </el-button>
            <el-button 
              size="small" 
              type="info"
              @click="handleGenerateSummary(row)"
              :disabled="row.status !== 'completed'"
            >
              摘要
            </el-button>
            <el-button 
              size="small" 
              type="danger"
              @click="handleDeleteDocument(row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <div v-if="documentsStore.documents.length === 0" class="empty-state">
        <el-empty description="暂无文档，请先上传PDF文件" />
      </div>
    </el-card>

    <!-- 摘要对话框 -->
    <el-dialog 
      v-model="summaryDialogVisible" 
      title="文档摘要" 
      width="50%"
      :before-close="handleCloseSummaryDialog"
    >
      <div v-loading="summaryLoading" class="summary-content">
        <div v-if="currentSummary">
          {{ currentSummary }}
        </div>
        <el-empty v-else-if="!summaryLoading" description="生成摘要失败" />
      </div>
      <template #footer>
        <el-button @click="summaryDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useDocumentsStore } from '@/stores/documents'
import type { Document } from '@/api/types'

const documentsStore = useDocumentsStore()

const summaryDialogVisible = ref(false)
const summaryLoading = ref(false)
const currentSummary = ref('')

const emit = defineEmits<{
  selectDocument: [document: Document]
}>()

const handleSelectDocument = (document: Document) => {
  if (document.status === 'completed') {
    documentsStore.selectDocument(document.document_id)
    emit('selectDocument', document)
  }
}

const handleGenerateSummary = async (document: Document) => {
  summaryDialogVisible.value = true
  summaryLoading.value = true
  currentSummary.value = ''

  const summary = await documentsStore.generateSummary(document.document_id)
  
  summaryLoading.value = false
  if (summary) {
    currentSummary.value = summary
  }
}

const handleDeleteDocument = async (document: Document) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除文档 "${document.filename}" 吗？此操作不可恢复。`,
      '删除确认',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )
    
    await documentsStore.deleteDocument(document.document_id)
  } catch (error) {
    // 用户取消删除
  }
}

const handleCloseSummaryDialog = () => {
  summaryDialogVisible.value = false
  currentSummary.value = ''
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
.document-list {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.empty-state {
  padding: 40px 0;
}

.summary-content {
  min-height: 200px;
  max-height: 400px;
  overflow-y: auto;
  padding: 20px;
  background-color: #f5f7fa;
  border-radius: 4px;
  line-height: 1.6;
  white-space: pre-wrap;
}
</style> 