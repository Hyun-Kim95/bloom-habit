import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  preview: {
    // Railway preview 도메인으로 접근할 수 있도록 허용
    allowedHosts: true,
  },
})
