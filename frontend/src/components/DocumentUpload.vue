<template>
  <div class="document-upload">
    <el-card class="upload-card">
      <template #header>
        <div class="card-header">
          <span>文档上传</span>
        </div>
      </template>

      <el-upload
        ref="uploadRef"
        class="upload-demo"
        drag
        :auto-upload="false"
        accept=".pdf"
        :limit="1"
        :file-list="fileList"
        :on-change="handleFileChange"
        :on-remove="handleFileRemove"
      >
        <el-icon class="el-icon--upload">
          <upload-filled />
        </el-icon>
        <div class="el-upload__text">
          将PDF文件拖拽到此处，或<em>点击上传</em>
        </div>
        <template #tip>
          <div class="el-upload__tip">
            只能上传PDF文件，且不超过50MB
          </div>
        </template>
      </el-upload>

      <div class="upload-actions" v-if="fileList.length > 0">
        <el-button 
          type="primary" 
          @click="handleUpload"
          :loading="documentsStore.loading"
          :disabled="!selectedFile"
        >
          {{ documentsStore.loading ? '上传中...' : '开始上传' }}
        </el-button>
        <el-button @click="handleClear">清空</el-button>
      </div>

      <el-progress 
        v-if="documentsStore.uploadProgress > 0"
        :percentage="documentsStore.uploadProgress"
        :status="documentsStore.uploadProgress === 100 ? 'success' : undefined"
        class="upload-progress"
      />
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ElMessage } from 'element-plus'
import { UploadFilled } from '@element-plus/icons-vue'
import { useDocumentsStore } from '@/stores/documents'
import type { UploadFile, UploadFiles } from 'element-plus'

const documentsStore = useDocumentsStore()

const uploadRef = ref()
const fileList = ref<UploadFiles>([])
const selectedFile = ref<File | null>(null)

const handleFileChange = (uploadFile: UploadFile, uploadFiles: UploadFiles) => {
  fileList.value = uploadFiles
  
  if (uploadFile.raw) {
    // 验证文件类型
    if (!uploadFile.name.toLowerCase().endsWith('.pdf')) {
      ElMessage.error('只支持PDF文件!')
      fileList.value = []
      selectedFile.value = null
      return
    }
    
    // 验证文件大小
    if (uploadFile.raw.size > 50 * 1024 * 1024) {
      ElMessage.error('文件大小不能超过50MB!')
      fileList.value = []
      selectedFile.value = null
      return
    }
    
    selectedFile.value = uploadFile.raw
  }
}

const handleFileRemove = () => {
  fileList.value = []
  selectedFile.value = null
}

const handleUpload = async () => {
  if (!selectedFile.value) {
    ElMessage.warning('请选择要上传的PDF文件')
    return
  }

  const documentId = await documentsStore.uploadDocument(selectedFile.value)
  
  if (documentId) {
    handleClear()
    // 刷新文档列表
    documentsStore.fetchDocuments()
  }
}

const handleClear = () => {
  uploadRef.value?.clearFiles()
  fileList.value = []
  selectedFile.value = null
}
</script>

<style scoped>
.document-upload {
  margin-bottom: 20px;
}

.upload-card {
  width: 100%;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.upload-demo {
  width: 100%;
}

.upload-actions {
  margin-top: 20px;
  text-align: center;
}

.upload-actions .el-button {
  margin: 0 10px;
}

.upload-progress {
  margin-top: 20px;
}

.el-icon--upload {
  font-size: 67px;
  color: #c0c4cc;
  margin: 40px 0 16px;
  line-height: 50px;
}
</style> 