import { resolve } from 'path';
import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    target: 'es2022', 
    rollupOptions: {
      input: {
        main: resolve('index.html'),
        dashboard: resolve('dashboard.html'),
      },
    },
  },
  esbuild: {
    target: 'es2022'
  }
});