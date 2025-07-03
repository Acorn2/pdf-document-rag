export interface Document {
  document_id: string
  filename: string
  file_size: number
  pages: number
  upload_time: string
  status: 'pending' | 'processing' | 'completed' | 'failed'
  chunk_count?: number
}

export interface QueryRequest {
  document_id: string
  question: string
  max_results?: number
}

export interface QueryResponse {
  answer: string
  confidence: number
  sources: Array<{
    chunk_id: string
    chunk_index: number
    similarity_score: number
    content_preview: string
  }>
  processing_time: number
}

export interface UploadResponse {
  document_id: string
  filename: string
  status: string
  upload_time: string
  message: string
}

export interface HealthCheck {
  status: string
  timestamp: string
  services: Record<string, string>
} 