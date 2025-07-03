<template>
  <div class="chat-interface">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>智能问答</span>
          <div v-if="documentsStore.currentDocument">
            <el-tag type="success">
              {{ documentsStore.currentDocument.filename }}
            </el-tag>
          </div>
        </div>
      </template>

      <div v-if="!documentsStore.currentDocument" class="no-document">
        <el-empty description="请先选择一个已处理完成的文档" />
      </div>

      <div v-else class="chat-container">
        <!-- 聊天历史 -->
        <div class="chat-history" ref="chatHistoryRef">
          <div 
            v-for="(item, index) in documentsStore.queryHistory" 
            :key="index"
            class="chat-item"
          >
            <!-- 用户问题 -->
            <div class="message user-message">
              <div class="message-content">
                <div class="message-text">{{ item.question }}</div>
                <div class="message-time">
                  {{ formatTime(item.timestamp) }}
                </div>
              </div>
              <div class="message-avatar user-avatar">
                <el-icon><User /></el-icon>
              </div>
            </div>

            <!-- AI回答 或 loading状态 -->
            <div v-if="item.response || item.isLoading" class="message ai-message">
              <div class="message-avatar ai-avatar" :class="{ 'loading-avatar': item.isLoading }">
                <el-icon v-if="item.isLoading" class="is-loading"><Loading /></el-icon>
                <el-icon v-else><Cpu /></el-icon>
              </div>
              <div class="message-content">
                <div class="ai-header">
                  <span class="ai-name">AI助手</span>
                  <div v-if="!item.isLoading" class="message-time">
                    {{ formatTime(item.timestamp) }}
                  </div>
                </div>
                
                <!-- Loading状态 -->
                <div v-if="item.isLoading" class="loading-text">
                  <el-icon class="is-loading"><Loading /></el-icon>
                  正在思考中...
                </div>
                
                <!-- 正常回答 - 使用markdown渲染 -->
                <template v-else-if="item.response">
                  <div class="message-text ai-text">
                    <MarkdownRenderer :content="item.response.answer" />
                  </div>
                  <div class="message-meta">
                    <span class="confidence">
                      <el-icon><TrendCharts /></el-icon>
                      置信度: {{ (item.response.confidence * 100).toFixed(1) }}%
                    </span>
                    <span class="processing-time">
                      <el-icon><Timer /></el-icon>
                      处理时间: {{ item.response.processing_time.toFixed(2) }}s
                    </span>
                  </div>
                  
                  <!-- 引用来源 -->
                  <div v-if="item.response.sources.length > 0" class="sources">
                    <el-collapse size="small">
                      <el-collapse-item name="sources">
                        <template #title>
                          <div class="sources-title">
                            <el-icon><Link /></el-icon>
                            <span>查看引用来源 ({{ item.response.sources.length }})</span>
                          </div>
                        </template>
                        <div 
                          v-for="(source, sourceIndex) in item.response.sources" 
                          :key="sourceIndex"
                          class="source-item"
                        >
                          <div class="source-header">
                            <span class="source-index">
                              <el-icon><Document /></el-icon>
                              段落 {{ parseInt(source.chunk_index) + 1 }}
                            </span>
                            <span class="source-score">
                              相似度: {{ (parseFloat(source.similarity_score) * 100).toFixed(1) }}%
                            </span>
                          </div>
                          <div class="source-content">{{ source.content_preview }}</div>
                        </div>
                      </el-collapse-item>
                    </el-collapse>
                  </div>
                </template>
                
                <!-- 错误状态 -->
                <div v-else-if="item.error" class="error-text">
                  查询失败，请重试
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 输入区域 -->
        <div class="chat-input">
          <el-input
            v-model="currentQuestion"
            type="textarea"
            :rows="3"
            placeholder="请输入您的问题..."
            @keydown.ctrl.enter="handleSendQuestion"
            :disabled="queryLoading"
          />
          <div class="input-actions">
            <div class="input-tip">Ctrl + Enter 发送</div>
            <el-button 
              type="primary" 
              @click="handleSendQuestion"
              :loading="queryLoading"
              :disabled="!currentQuestion.trim()"
            >
              发送
            </el-button>
          </div>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { 
  User, 
  Loading, 
  Cpu, 
  TrendCharts, 
  Timer, 
  Link, 
  Document 
} from '@element-plus/icons-vue'
import { useDocumentsStore } from '@/stores/documents'
import MarkdownRenderer from './MarkdownRenderer.vue'

const documentsStore = useDocumentsStore()

const currentQuestion = ref('')
const queryLoading = ref(false)
const chatHistoryRef = ref<HTMLElement>()

// 监听查询历史变化，自动滚动到底部
watch(
  () => documentsStore.queryHistory.length,
  () => {
    nextTick(() => {
      if (chatHistoryRef.value) {
        chatHistoryRef.value.scrollTop = chatHistoryRef.value.scrollHeight
      }
    })
  }
)

const handleSendQuestion = async () => {
  const question = currentQuestion.value.trim()
  if (!question) {
    ElMessage.warning('请输入问题')
    return
  }

  if (!documentsStore.currentDocument) {
    ElMessage.warning('请先选择文档')
    return
  }

  // 立即添加用户问题到聊天历史
  const questionItem = {
    question,
    response: null as any, // 暂时为null，等待API响应
    timestamp: new Date(),
    isLoading: true // 添加loading标识
  }
  
  documentsStore.queryHistory.push(questionItem)
  
  // 清空输入框
  currentQuestion.value = ''
  queryLoading.value = true
  
  try {
    const response = await documentsStore.queryDocument(question, questionItem)
  } catch (error) {
    console.error('查询失败:', error)
    // 如果查询失败，移除这个问题项或者标记为错误
    const index = documentsStore.queryHistory.findIndex(item => item === questionItem)
    if (index !== -1) {
      documentsStore.queryHistory.splice(index, 1)
    }
  } finally {
    queryLoading.value = false
  }
}

const formatTime = (date: Date) => {
  return date.toLocaleTimeString('zh-CN', {
    hour: '2-digit',
    minute: '2-digit'
  })
}
</script>

<style scoped>
.chat-interface {
  height: 100%;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.no-document {
  padding: 40px 0;
  text-align: center;
}

.chat-container {
  height: 600px;
  display: flex;
  flex-direction: column;
}

.chat-history {
  flex: 1;
  overflow-y: auto;
  padding: 15px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  margin-bottom: 20px;
  background-color: #fafbfc;
}

.chat-item {
  margin-bottom: 25px;
}

.message {
  display: flex;
  margin-bottom: 15px;
  align-items: flex-start;
}

.user-message {
  justify-content: flex-end;
}

.ai-message {
  justify-content: flex-start;
}

.message-avatar {
  width: 42px;
  height: 42px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  flex-shrink: 0;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.user-avatar {
  background: linear-gradient(135deg, #409eff, #5dade2);
  color: white;
  margin-left: 12px;
}

.ai-avatar {
  background: linear-gradient(135deg, #67c23a, #52c41a);
  color: white;
  margin-right: 12px;
}

.loading-avatar {
  opacity: 0.8;
}

.message-content {
  max-width: 75%;
  min-width: 150px;
}

.ai-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.ai-name {
  font-size: 13px;
  font-weight: 600;
  color: #67c23a;
}

.message-text {
  background-color: #f5f7fa;
  padding: 14px 18px;
  border-radius: 16px;
  line-height: 1.6;
  word-wrap: break-word;
  font-size: 14px;
  position: relative;
}

.ai-text {
  background: linear-gradient(135deg, #f8f9fa, #e9ecef);
  border: 1px solid #e4e7ed;
  border-radius: 16px 16px 16px 4px;
  padding: 16px 20px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.ai-text :deep(.markdown-content) {
  margin: 0;
}

.user-message .message-text {
  background: linear-gradient(135deg, #409eff, #5dade2);
  color: white;
  border-radius: 16px 16px 4px 16px;
}

.ai-message .message-text {
  border-radius: 16px 16px 16px 4px;
}

.message-time {
  font-size: 11px;
  color: #909399;
  margin-top: 4px;
}

.user-message .message-time {
  text-align: right;
}

.ai-message .message-time {
  text-align: left;
}

.message-meta {
  display: flex;
  gap: 20px;
  margin-top: 10px;
  font-size: 12px;
  color: #606266;
  align-items: center;
}

.confidence, .processing-time {
  display: flex;
  align-items: center;
  gap: 4px;
}

.confidence {
  color: #67c23a;
  font-weight: 500;
}

.processing-time {
  color: #909399;
}

.sources {
  margin-top: 12px;
}

.sources-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #606266;
}

.source-item {
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 8px;
  background-color: #ffffff;
  transition: box-shadow 0.2s;
}

.source-item:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.source-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
  font-size: 12px;
}

.source-index {
  font-weight: 600;
  color: #409eff;
  display: flex;
  align-items: center;
  gap: 4px;
}

.source-score {
  color: #67c23a;
  font-weight: 500;
}

.source-content {
  font-size: 13px;
  line-height: 1.5;
  color: #606266;
  background-color: #f8f9fa;
  padding: 8px 12px;
  border-radius: 6px;
  border-left: 3px solid #409eff;
}

.loading-text {
  display: flex;
  align-items: center;
  gap: 8px;
  font-style: italic;
  color: #909399;
  background-color: #f5f7fa;
  padding: 14px 18px;
  border-radius: 16px 16px 16px 4px;
  border: 1px solid #e4e7ed;
}

.chat-input {
  border-top: 1px solid #e4e7ed;
  padding-top: 15px;
  background-color: white;
  border-radius: 0 0 8px 8px;
}

.input-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 10px;
}

.input-tip {
  font-size: 12px;
  color: #909399;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .message-content {
    max-width: 85%;
  }
  
  .message-avatar {
    width: 36px;
    height: 36px;
    font-size: 16px;
  }
  
  .message-meta {
    flex-direction: column;
    gap: 8px;
    align-items: flex-start;
  }
}

/* 滚动条美化 */
.chat-history::-webkit-scrollbar {
  width: 6px;
}

.chat-history::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

.chat-history::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

.chat-history::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}
</style> 