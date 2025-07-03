<template>
  <div class="markdown-content" v-html="renderedHtml"></div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { marked } from 'marked'
import hljs from 'highlight.js'
import 'highlight.js/styles/github.css'

const props = defineProps<{
  content: string
}>()

// 配置marked
marked.setOptions({
  highlight: function(code, lang) {
    if (lang && hljs.getLanguage(lang)) {
      try {
        return hljs.highlight(code, { language: lang }).value
      } catch (err) {
        console.error('代码高亮失败:', err)
      }
    }
    return hljs.highlightAuto(code).value
  },
  breaks: true,
  gfm: true
})

// 内容预处理函数 - 清理引用信息
const cleanContent = (content: string): string => {
  if (!content) return ''
  
  let cleanedContent = content
  
  // 移除"原文支持："相关的引用内容
  cleanedContent = cleanedContent.replace(/原文支持：?\s*/gi, '')
  
  // 移除引用格式，例如："> "3.2 负荷计算" 这种格式
  cleanedContent = cleanedContent.replace(/>\s*"[^"]*"\s*/g, '')
  
  // 移除页码引用，例如：(段落5)、（页30）等
  cleanedContent = cleanedContent.replace(/（[^）]*页?\s*\d+[^）]*）/g, '')
  cleanedContent = cleanedContent.replace(/\([^)]*页?\s*\d+[^)]*\)/g, '')
  
  // 移除"--- ### 一、### 二、"这样的分隔符格式
  cleanedContent = cleanedContent.replace(/---\s*#+\s*[一二三四五六七八九十]+、\s*/g, '')
  
  // 移除多余的点号分隔符
  cleanedContent = cleanedContent.replace(/\.{3,}/g, '')
  
  // 移除"引用原文："
  cleanedContent = cleanedContent.replace(/引用原文：?\s*/gi, '')
  
  // 移除多余的换行和空格
  cleanedContent = cleanedContent.replace(/\n\s*\n\s*\n/g, '\n\n')
  cleanedContent = cleanedContent.trim()
  
  return cleanedContent
}

const renderedHtml = computed(() => {
  if (!props.content) return ''
  
  // 先清理内容，再渲染markdown
  const cleanedContent = cleanContent(props.content)
  return marked(cleanedContent)
})
</script>

<style scoped>
.markdown-content {
  line-height: 1.6;
  color: #2c3e50;
}

/* 标题样式 */
.markdown-content :deep(h1),
.markdown-content :deep(h2),
.markdown-content :deep(h3),
.markdown-content :deep(h4),
.markdown-content :deep(h5),
.markdown-content :deep(h6) {
  margin-top: 1.5em;
  margin-bottom: 0.5em;
  font-weight: 600;
  color: #2c3e50;
}

.markdown-content :deep(h1) {
  font-size: 1.5em;
  border-bottom: 2px solid #409eff;
  padding-bottom: 0.3em;
}

.markdown-content :deep(h2) {
  font-size: 1.3em;
  border-bottom: 1px solid #e4e7ed;
  padding-bottom: 0.2em;
}

.markdown-content :deep(h3) {
  font-size: 1.1em;
}

/* 段落样式 */
.markdown-content :deep(p) {
  margin: 0.8em 0;
  line-height: 1.7;
}

/* 列表样式 */
.markdown-content :deep(ul),
.markdown-content :deep(ol) {
  margin: 0.8em 0;
  padding-left: 2em;
}

.markdown-content :deep(li) {
  margin: 0.3em 0;
  line-height: 1.6;
}

/* 代码块样式 */
.markdown-content :deep(pre) {
  background-color: #f6f8fa;
  border-radius: 6px;
  padding: 1em;
  overflow-x: auto;
  border-left: 4px solid #409eff;
  margin: 1em 0;
}

.markdown-content :deep(code) {
  background-color: #f6f8fa;
  padding: 0.2em 0.4em;
  border-radius: 3px;
  font-family: 'SF Mono', 'Monaco', 'Inconsolata', 'Roboto Mono', monospace;
  font-size: 0.9em;
}

.markdown-content :deep(pre code) {
  background-color: transparent;
  padding: 0;
}

/* 引用样式 */
.markdown-content :deep(blockquote) {
  border-left: 4px solid #67c23a;
  background-color: #f0f9f0;
  padding: 0.8em 1.2em;
  margin: 1em 0;
  color: #606266;
  border-radius: 0 4px 4px 0;
}

.markdown-content :deep(blockquote p) {
  margin: 0;
}

/* 表格样式 */
.markdown-content :deep(table) {
  border-collapse: collapse;
  width: 100%;
  margin: 1em 0;
  border-radius: 6px;
  overflow: hidden;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.markdown-content :deep(th),
.markdown-content :deep(td) {
  border: 1px solid #e4e7ed;
  padding: 0.6em 1em;
  text-align: left;
}

.markdown-content :deep(th) {
  background-color: #409eff;
  color: white;
  font-weight: 600;
}

.markdown-content :deep(tr:nth-child(even)) {
  background-color: #f8f9fa;
}

/* 链接样式 */
.markdown-content :deep(a) {
  color: #409eff;
  text-decoration: none;
  border-bottom: 1px solid transparent;
  transition: border-color 0.2s;
}

.markdown-content :deep(a:hover) {
  border-bottom-color: #409eff;
}

/* 分割线样式 */
.markdown-content :deep(hr) {
  border: none;
  border-top: 2px solid #e4e7ed;
  margin: 2em 0;
}

/* 强调样式 */
.markdown-content :deep(strong) {
  font-weight: 600;
  color: #2c3e50;
}

.markdown-content :deep(em) {
  font-style: italic;
  color: #606266;
}
</style> 