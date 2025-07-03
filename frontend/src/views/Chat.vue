<template>
  <div class="chat-page">
    <div class="page-header">
      <h1>智能问答</h1>
      <p>与您的文档进行智能对话</p>
    </div>

    <el-row :gutter="20">
      <!-- 左侧：文档选择 -->
      <el-col :span="6">
        <el-card>
          <template #header>
            <span>选择文档</span>
          </template>
          <DocumentList @select-document="handleDocumentSelect" />
        </el-card>
      </el-col>

      <!-- 右侧：聊天界面 -->
      <el-col :span="18">
        <ChatInterface />
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useRoute } from 'vue-router'
import DocumentList from '@/components/DocumentList.vue'
import ChatInterface from '@/components/ChatInterface.vue'
import { useDocumentsStore } from '@/stores/documents'
import type { Document } from '@/api/types'

const route = useRoute()
const documentsStore = useDocumentsStore()

onMounted(async () => {
  // 加载文档列表
  await documentsStore.fetchDocuments()
  
  // 如果URL中有documentId参数，自动选择该文档
  const documentId = route.params.documentId as string
  if (documentId) {
    await documentsStore.selectDocument(documentId)
  }
})

const handleDocumentSelect = (document: Document) => {
  documentsStore.selectDocument(document.document_id)
}
</script>

<style scoped>
.chat-page {
  padding: 20px;
  min-height: 100vh;
}

.page-header {
  margin-bottom: 30px;
  text-align: center;
}

.page-header h1 {
  font-size: 2rem;
  margin-bottom: 0.5rem;
  color: #2c3e50;
}

.page-header p {
  color: #7f8c8d;
  font-size: 1.1rem;
}
</style> 