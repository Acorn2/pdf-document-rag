<template>
  <div class="not-found">
    <el-result
      icon="warning"
      title="404"
      sub-title="抱歉，您访问的页面不存在"
    >
      <template #extra>
        <el-button type="primary" @click="$router.push('/')">
          返回首页
        </el-button>
        <el-button @click="$router.back()">
          返回上页
        </el-button>
      </template>
    </el-result>
  </div>
</template>

<script setup lang="ts">
// 404页面组件
</script>

<style scoped>
.not-found {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  background-color: #f5f7fa;
}
</style> 