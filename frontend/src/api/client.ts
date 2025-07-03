import axios from 'axios'
import type { AxiosInstance, AxiosResponse } from 'axios'
import { ElMessage } from 'element-plus'
import type { Document, QueryRequest, QueryResponse, UploadResponse, HealthCheck } from './types'

class ApiClient {
  private client: AxiosInstance

  constructor() {
    this.client = axios.create({
      baseURL: '/api',
      timeout: 60000,
    })

    // 请求拦截器
    this.client.interceptors.request.use(
      (config) => {
        return config
      },
      (error) => {
        return Promise.reject(error)
      }
    )

    // 响应拦截器
    this.client.interceptors.response.use(
      (response: AxiosResponse) => {
        return response
      },
      (error) => {
        const message = error.response?.data?.detail || error.message || '请求失败'
        ElMessage.error(message)
        return Promise.reject(error)
      }
    )
  }

  // 健康检查
  async healthCheck(): Promise<HealthCheck> {
    const response = await this.client.get('/')
    return response.data
  }

  // 上传文档
  async uploadDocument(file: File, onProgress?: (progress: number) => void): Promise<UploadResponse> {
    const formData = new FormData()
    formData.append('file', file)

    const response = await this.client.post('/documents/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      onUploadProgress: (progressEvent) => {
        if (progressEvent.total && onProgress) {
          const progress = Math.round((progressEvent.loaded / progressEvent.total) * 100)
          onProgress(progress)
        }
      },
    })

    return response.data
  }

  // 获取文档列表
  async getDocuments(skip: number = 0, limit: number = 20): Promise<Document[]> {
    const response = await this.client.get(`/documents?skip=${skip}&limit=${limit}`)
    return response.data
  }

  // 获取文档详情
  async getDocument(documentId: string): Promise<Document> {
    const response = await this.client.get(`/documents/${documentId}`)
    return response.data
  }

  // 查询文档
  async queryDocument(request: QueryRequest): Promise<QueryResponse> {
    const response = await this.client.post(`/documents/${request.document_id}/query`, {
      question: request.question,
      max_results: request.max_results || 5,
    })
    return response.data
  }

  // 生成文档摘要
  async generateSummary(documentId: string): Promise<{ summary: string }> {
    const response = await this.client.post(`/documents/${documentId}/summary`)
    return response.data
  }

  // 删除文档
  async deleteDocument(documentId: string): Promise<{ message: string }> {
    const response = await this.client.delete(`/documents/${documentId}`)
    return response.data
  }
}

export const apiClient = new ApiClient() 