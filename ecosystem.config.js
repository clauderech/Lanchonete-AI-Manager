module.exports = {
  apps: [
    {
      name: 'lanchonete-backend',
      script: 'server.js',
      instances: 'max', // Usa todos os núcleos de CPU disponíveis
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '1G',
      watch: false
    },
    {
      name: 'lanchonete-frontend',
      script: 'serve',
      args: '-s dist -l 3000',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/frontend-error.log',
      out_file: './logs/frontend-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      autorestart: true,
      max_memory_restart: '512M'
    }
  ]
};
