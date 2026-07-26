const js = require('@eslint/js');
const globals = require('globals');

module.exports = [{
  ignores: ['**/node_modules/**', '**/coverage/**', '**/dist/**']
}, {
  files: ['src/**/*.js', 'test/**/*.js'],

  languageOptions: {
    ecmaVersion: 2021,
    sourceType: 'commonjs',
    globals: {
      __dirname: 'readonly',
      __filename: 'readonly',
      require: 'readonly',
      module: 'readonly',
      console: 'readonly',
      ...globals.node,
      jest: 'readonly',
      describe: 'readonly',
      test: 'readonly',
      expect: 'readonly',
      beforeAll: 'readonly',
      afterAll: 'readonly',
      beforeEach: 'readonly',
      afterEach: 'readonly'
    }
  },

  rules: {
    ...js.configs.recommended.rules,
    semi: ['error', 'always'],
    'no-console': ['off'], // Permitir console logs para monitoreo del API y errores
    eqeqeq: ['error'],
    camelcase: ['off'],
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    'max-lines-per-function': ['error', { max: 150, skipBlankLines: true, skipComments: true }]
  }
}, {
  files: ['test/**/*.js'],
  rules: {
    'max-lines-per-function': ['off'] // Desactivar limite de lineas para archivos de pruebas
  }
}];
