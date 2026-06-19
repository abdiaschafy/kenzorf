/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{html,ts}'],
  theme: {
    extend: {
      colors: {
        // KENZORF — palette sobre noir / blanc + accent
        ink: {
          DEFAULT: '#0a0a0a',
          50: '#f6f6f6',
          100: '#e7e7e7',
          200: '#d1d1d1',
          300: '#b0b0b0',
          400: '#888888',
          500: '#6d6d6d',
          600: '#5d5d5d',
          700: '#4f4f4f',
          800: '#454545',
          900: '#3d3d3d',
          950: '#0a0a0a',
        },
        accent: {
          DEFAULT: '#c79a4b',
          50: '#fbf7ef',
          100: '#f4e9d2',
          200: '#e8d1a2',
          300: '#dab66f',
          400: '#cfa050',
          500: '#c79a4b',
          600: '#a87b38',
          700: '#875e30',
          800: '#714c2d',
          900: '#604029',
          950: '#372214',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
        display: ['"Cormorant Garamond"', 'Georgia', 'serif'],
      },
      boxShadow: {
        card: '0 1px 2px 0 rgba(10, 10, 10, 0.04), 0 1px 3px 0 rgba(10, 10, 10, 0.06)',
        elevated: '0 4px 16px -2px rgba(10, 10, 10, 0.08), 0 2px 6px -2px rgba(10, 10, 10, 0.05)',
      },
      borderRadius: {
        xl: '0.875rem',
      },
    },
  },
  plugins: [],
};
