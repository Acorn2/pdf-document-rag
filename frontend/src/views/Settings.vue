<template>
  <div class="settings-page">
    <div class="page-header">
      <h1>系统设置</h1>
      <p>配置系统参数和偏好设置</p>
    </div>

    <el-row :gutter="20">
      <el-col :span="16">
        <el-card>
          <template #header>
            <span>基本设置</span>
          </template>

          <el-form :model="settings" label-width="120px">
            <el-form-item label="API地址">
              <el-input 
                v-model="settings.apiUrl" 
                placeholder="后端API地址"
                readonly
              />
              <div class="form-tip">当前API地址，仅供查看</div>
            </el-form-item>

            <el-form-item label="应用版本">
              <el-input 
                v-model="settings.version" 
                readonly
              />
            </el-form-item>

            <el-form-item label="主题模式">
              <el-radio-group v-model="settings.theme">
                <el-radio label="light">浅色主题</el-radio>
                <el-radio label="dark">深色主题</el-radio>
                <el-radio label="auto">跟随系统</el-radio>
              </el-radio-group>
            </el-form-item>

            <el-form-item label="语言设置">
              <el-select v-model="settings.language">
                <el-option label="简体中文" value="zh-CN" />
                <el-option label="English" value="en-US" />
              </el-select>
            </el-form-item>

            <el-form-item label="自动保存">
              <el-switch v-model="settings.autoSave" />
              <div class="form-tip">自动保存聊天记录</div>
            </el-form-item>

            <el-form-item>
              <el-button type="primary" @click="saveSettings">
                保存设置
              </el-button>
              <el-button @click="resetSettings">
                恢复默认
              </el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <el-col :span="8">
        <el-card>
          <template #header>
            <span>系统信息</span>
          </template>

          <el-descriptions :column="1">
            <el-descriptions-item label="应用名称">
              PDF文献分析智能体
            </el-descriptions-item>
            <el-descriptions-item label="版本号">
              {{ settings.version }}
            </el-descriptions-item>
            <el-descriptions-item label="构建时间">
              {{ buildTime }}
            </el-descriptions-item>
            <el-descriptions-item label="技术栈">
              Vue 3 + TypeScript
            </el-descriptions-item>
          </el-descriptions>
        </el-card>

        <el-card style="margin-top: 20px;">
          <template #header>
            <span>帮助与支持</span>
          </template>

          <div class="help-links">
            <el-button type="text" @click="checkHealth">
              <el-icon><Connection /></el-icon>
              检查服务状态
            </el-button>
            <el-button type="text">
              <el-icon><Document /></el-icon>
              查看文档
            </el-button>
            <el-button type="text">
              <el-icon><QuestionFilled /></el-icon>
              常见问题
            </el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Connection, Document, QuestionFilled } from '@element-plus/icons-vue'
import { apiClient } from '@/api/client'

const settings = ref({
  apiUrl: '/api/v1',
  version: '1.0.0',
  theme: 'light',
  language: 'zh-CN',
  autoSave: true
})

const buildTime = ref(new Date().toLocaleString('zh-CN'))

onMounted(() => {
  loadSettings()
})

const loadSettings = () => {
  // 从localStorage加载设置
  const savedSettings = localStorage.getItem('app-settings')
  if (savedSettings) {
    try {
      Object.assign(settings.value, JSON.parse(savedSettings))
    } catch (error) {
      console.error('加载设置失败:', error)
    }
  }
  
  // 设置版本号
  settings.value.version = import.meta.env.VITE_APP_VERSION || '1.0.0'
  settings.value.apiUrl = import.meta.env.VITE_API_BASE_URL || '/api/v1'
}

const saveSettings = () => {
  try {
    localStorage.setItem('app-settings', JSON.stringify(settings.value))
    ElMessage.success('设置已保存')
  } catch (error) {
    ElMessage.error('保存设置失败')
  }
}

const resetSettings = () => {
  settings.value = {
    apiUrl: '/api/v1',
    version: '1.0.0',
    theme: 'light',
    language: 'zh-CN',
    autoSave: true
  }
  localStorage.removeItem('app-settings')
  ElMessage.success('已恢复默认设置')
}

const checkHealth = async () => {
  try {
    const health = await apiClient.healthCheck()
    if (health.status === 'healthy') {
      ElMessage.success('后端服务运行正常')
    } else {
      ElMessage.warning('后端服务状态异常')
    }
  } catch (error) {
    ElMessage.error('无法连接到后端服务')
  }
}
</script>

<style scoped>
.settings-page {
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

.form-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 5px;
}

.help-links {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.help-links .el-button {
  justify-content: flex-start;
}
</style> 