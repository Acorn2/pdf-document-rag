import fitz  # PyMuPDF
import os
import hashlib
from typing import List, Dict, Optional
from langchain.text_splitter import RecursiveCharacterTextSplitter
import logging

logger = logging.getLogger(__name__)

class DocumentProcessor:
    """PDF文档处理器"""
    
    def __init__(self, chunk_size: int = 1000, chunk_overlap: int = 200):
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap,
            length_function=len
        )
    
    def extract_text_from_pdf(self, file_path: str) -> Dict[str, any]:
        """从PDF文件中提取文本和元数据"""
        try:
            with fitz.open(file_path) as doc:
                # 检查PDF是否有密码保护
                if doc.needs_pass:
                    return {
                        "metadata": {},
                        "full_text": "",
                        "page_texts": [],
                        "success": False,
                        "error": "PDF文件需要密码"
                    }
                
                # 提取基本信息
                metadata = {
                    "pages": len(doc),
                    "title": doc.metadata.get("title", ""),
                    "author": doc.metadata.get("author", ""),
                    "subject": doc.metadata.get("subject", ""),
                    "keywords": doc.metadata.get("keywords", "")
                }
                
                # 提取文本内容
                full_text = ""
                page_texts = []
                total_chars = 0
                empty_pages = 0  # 记录空页数
                
                logger.info(f"开始处理PDF文档，共 {len(doc)} 页")
                
                for page_num in range(len(doc)):
                    page = doc[page_num]
                    
                    # 尝试多种文本提取方法
                    page_text = page.get_text()
                    
                    # 如果普通提取失败，尝试其他方法
                    if not page_text.strip():
                        # 尝试不同的文本提取模式
                        page_text = page.get_text("text")
                        if not page_text.strip():
                            page_text = page.get_text("dict")
                            if isinstance(page_text, dict) and "blocks" in page_text:
                                extracted_text = []
                                for block in page_text["blocks"]:
                                    if "lines" in block:
                                        for line in block["lines"]:
                                            if "spans" in line:
                                                for span in line["spans"]:
                                                    if "text" in span:
                                                        extracted_text.append(span["text"])
                                page_text = " ".join(extracted_text)
                            else:
                                page_text = ""
                    
                    # 记录页面文本长度
                    page_text_length = len(page_text.strip())
                    total_chars += page_text_length
                    
                    logger.debug(f"第{page_num + 1}页提取文本长度: {page_text_length} 字符")
                    
                    if page_text.strip():
                        page_texts.append({
                            "page_number": page_num + 1,
                            "text": page_text,
                            "char_count": page_text_length
                        })
                        # 关键修改：只有当页面有实际内容时才添加页码标题
                        full_text += f"\n\n--- 第{page_num + 1}页 ---\n\n{page_text}"
                    else:
                        empty_pages += 1
                        logger.warning(f"第{page_num + 1}页未提取到文本内容")
                        page_texts.append({
                            "page_number": page_num + 1,
                            "text": "",
                            "char_count": 0
                        })
                        # 空页面不添加到full_text中
                
                logger.info(f"PDF处理完成 - 总页数: {len(doc)}, 有效页数: {len(doc) - empty_pages}, 总字符数: {total_chars}")
                
                # 检查是否提取到有效内容
                if total_chars < 100:  # 如果总字符数太少
                    error_msg = f"PDF文档可能是扫描版或无有效文本内容，仅提取到 {total_chars} 个字符，空页数: {empty_pages}/{len(doc)}"
                    logger.error(error_msg)
                    return {
                        "metadata": metadata,
                        "full_text": full_text,
                        "page_texts": page_texts,
                        "success": False,
                        "error": error_msg
                    }
                
                return {
                    "metadata": metadata,
                    "full_text": full_text,
                    "page_texts": page_texts,
                    "success": True,
                    "error": None
                }
                
        except Exception as e:
            logger.error(f"PDF文本提取失败: {str(e)}")
            return {
                "metadata": {},
                "full_text": "",
                "page_texts": [],
                "success": False,
                "error": str(e)
            }
    
    def split_text_into_chunks(self, text: str) -> List[Dict[str, any]]:
        """将文本分割成块"""
        try:
            # 检查输入文本是否有效
            if not text or len(text.strip()) < 10:
                logger.warning(f"输入文本过短或为空，无法有效分块。文本长度: {len(text)}")
                return []
            
            chunks = self.text_splitter.split_text(text)
            
            processed_chunks = []
            for i, chunk in enumerate(chunks):
                # 过滤掉过短的块（可能只是页码标题）
                chunk_content = chunk.strip()
                if len(chunk_content) < 50:  # 小于50字符的块可能没有实际意义
                    logger.debug(f"跳过过短的文本块 {i}: {chunk_content[:100]}")
                    continue
                    
                # 生成块的唯一ID
                chunk_id = hashlib.md5(f"{chunk}_{i}".encode()).hexdigest()
                
                processed_chunks.append({
                    "chunk_id": chunk_id,
                    "content": chunk,
                    "chunk_index": len(processed_chunks),  # 使用实际索引
                    "chunk_length": len(chunk)
                })
            
            logger.info(f"文本分块完成，原始块数: {len(chunks)}, 有效块数: {len(processed_chunks)}")
            return processed_chunks
            
        except Exception as e:
            logger.error(f"文本分块失败: {str(e)}")
            return []
    
    def process_document(self, file_path: str) -> Dict[str, any]:
        """处理文档的完整流程"""
        # 提取文本
        extraction_result = self.extract_text_from_pdf(file_path)
        
        if not extraction_result["success"]:
            return extraction_result
        
        # 分割文本
        chunks = self.split_text_into_chunks(extraction_result["full_text"])
        
        return {
            "metadata": extraction_result["metadata"],
            "full_text": extraction_result["full_text"],
            "page_texts": extraction_result["page_texts"],
            "chunks": chunks,
            "chunk_count": len(chunks),
            "success": True,
            "error": None
        } 