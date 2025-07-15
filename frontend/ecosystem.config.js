export default {
  apps: [{
    name: 'pdf-frontend',
    script: 'npm',
    args: 'run preview',
    cwd: '/my/project/pdf-document-rag/frontend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
} 