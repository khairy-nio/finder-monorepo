'use strict';

module.exports = {
  apps: [
    {
      name: 'finder-backend',
      script: 'server.js',
      cwd: '/home/ec2-user/backend-service',

      // ── Environment ─────────────────────────────────────────────────────────
      // Actual secrets are loaded from .env via dotenv — do NOT put secrets here.
      env_production: {
        NODE_ENV: 'production',
        PORT: 3500,
      },

      // ── Cluster / scaling ───────────────────────────────────────────────────
      // 'fork' keeps Socket.io working without a Redis adapter.
      // Switch to 'cluster' + Redis Socket.io adapter if you need horizontal scale.
      instances: 1,
      exec_mode: 'fork',

      // ── Reliability ─────────────────────────────────────────────────────────
      watch: false,               // never watch in production
      autorestart: true,
      max_restarts: 10,
      min_uptime: '5s',           // don't count a crash if < 5s alive
      restart_delay: 3000,        // wait 3s between restarts

      // ── Logging ─────────────────────────────────────────────────────────────
      output: '/home/ec2-user/logs/finder-out.log',
      error: '/home/ec2-user/logs/finder-err.log',
      merge_logs: true,
      time: true,                 // prefix every log line with timestamp

      // ── Memory guard ────────────────────────────────────────────────────────
      max_memory_restart: '512M',
    },
  ],
};
