export default {
  apps: [{
    name: 'pdf-frontend',
    script: 'npm',
    args: 'run preview',
    cwd: process.cwd(), // 使用当前目录，自动适配路径
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