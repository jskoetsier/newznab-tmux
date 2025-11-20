import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: [
                'resources/css/app.css',
                'resources/js/app.js',
                'resources/forum/livewire-tailwind/css/forum.css',
                'resources/forum/livewire-tailwind/js/forum.js',
                'resources/forum/blade-tailwind/css/forum.css',
                'resources/forum/blade-tailwind/js/forum.js',
            ],
            refresh: true,
        }),
    ],
    build: {
        manifest: true,
        outDir: 'public/build',
        rollupOptions: {
            output: {
                manualChunks: {
                    vendor: ['vue', 'axios', 'lodash'],
                    alpine: ['alpinejs'],
                    icons: ['feather-icons', '@fortawesome/fontawesome-free'],
                },
            },
        },
        chunkSizeWarningLimit: 1000,
        minify: 'esbuild',
        cssCodeSplit: true,
        sourcemap: false,
    },
    server: {
        hmr: {
            host: 'localhost',
        },
    },
    optimizeDeps: {
        include: ['vue', 'axios', 'lodash', 'alpinejs'],
    },
});
