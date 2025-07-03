<template>
  <div class="documents-page">
    <div class="page-header">
      <h1>文档管理</h1>
      <p>上传和管理您的PDF文档</p>
    </div>

    <el-row :gutter="20">
      <el-col :span="8">
        <DocumentUpload />
      </el-col>
      <el-col :span="16">
        <DocumentList @select-document="handleDocumentSelect" />
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import DocumentUpload from '@/components/DocumentUpload.vue'
import DocumentList from '@/components/DocumentList.vue'
import { useRouter } from 'vue-router'
import type { Document } from '@/api/types'

const router = useRouter()

const handleDocumentSelect = (document: Document) => {
  router.push(`/chat/${document.document_id}`)
}
</script>

<style scoped>
.documents-page {
  padding: 20px;
}

.page-header {
  margin-bottom: 30px;
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