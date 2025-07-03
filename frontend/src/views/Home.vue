<template>
  <div class="home">
    <div class="hero-section">
      <div class="hero-content">
        <h1 class="hero-title">PDF文献分析智能体</h1>
        <p class="hero-description">
          基于先进的AI技术，为您的PDF文献提供智能分析和问答服务
        </p>
        <div class="hero-actions">
          <el-button type="primary" size="large" @click="$router.push('/documents')">
            开始使用
          </el-button>
          <el-button size="large" @click="showFeatures = true">
            了解功能
          </el-button>
        </div>
      </div>
    </div>

    <!-- 功能特性 -->
    <div class="features-section">
      <div class="container">
        <h2 class="section-title">核心功能</h2>
        <el-row :gutter="30">
          <el-col :span="8" v-for="feature in features" :key="feature.title">
            <el-card class="feature-card">
              <div class="feature-icon">
                <component :is="feature.icon" />
              </div>
              <h3>{{ feature.title }}</h3>
              <p>{{ feature.description }}</p>
            </el-card>
          </el-col>
        </el-row>
      </div>
    </div>

    <!-- 统计数据 -->
    <div class="stats-section">
      <div class="container">
        <el-row :gutter="30">
          <el-col :span="6" v-for="stat in stats" :key="stat.label">
            <div class="stat-item">
              <div class="stat-number">{{ stat.value }}</div>
              <div class="stat-label">{{ stat.label }}</div>
            </div>
          </el-col>
        </el-row>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useDocumentsStore } from '@/stores/documents'
import { Document, Reading, ChatDotSquare, TrendCharts } from '@element-plus/icons-vue'

const documentsStore = useDocumentsStore()
const showFeatures = ref(false)

const features = [
  {
    title: '智能文档解析',
    description: '支持PDF文档的智能解析，提取关键信息和结构化数据',
    icon: Document
  },
  {
    title: '语义问答',
    description: '基于文档内容进行智能问答，提供准确的答案和引用来源',
    icon: ChatDotSquare
  },
  {
    title: '内容分析',
    description: '深度分析文档内容，生成摘要和关键词提取',
    icon: TrendCharts
  }
]

const stats = ref([
  { label: '已处理文档', value: '0' },
  { label: '总查询次数', value: '0' },
  { label: '平均处理时间', value: '0s' },
  { label: '用户满意度', value: '98%' }
])

onMounted(async () => {
  await documentsStore.fetchDocuments()
  stats.value[0].value = documentsStore.documents.length.toString()
})
</script>

<style scoped>
.home {
  min-height: 100vh;
}

.hero-section {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 100px 0;
  text-align: center;
}

.hero-title {
  font-size: 3rem;
  margin-bottom: 1rem;
  font-weight: bold;
}

.hero-description {
  font-size: 1.2rem;
  margin-bottom: 2rem;
  opacity: 0.9;
}

.hero-actions .el-button {
  margin: 0 10px;
}

.features-section {
  padding: 80px 0;
  background-color: #f8f9fa;
}

.section-title {
  text-align: center;
  font-size: 2.5rem;
  margin-bottom: 3rem;
  color: #2c3e50;
}

.feature-card {
  text-align: center;
  height: 100%;
  transition: transform 0.3s;
}

.feature-card:hover {
  transform: translateY(-10px);
}

.feature-icon {
  font-size: 3rem;
  color: #409eff;
  margin-bottom: 1rem;
}

.stats-section {
  padding: 60px 0;
  background-color: #2c3e50;
  color: white;
}

.stat-item {
  text-align: center;
}

.stat-number {
  font-size: 2.5rem;
  font-weight: bold;
  margin-bottom: 0.5rem;
}

.stat-label {
  font-size: 1.1rem;
  opacity: 0.8;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}
</style> 