module.exports = {
  env: {
    es6: true,
    node: true,
  },
  extends: [
    'eslint:recommended',
    'google',
  ],
  rules: {
    'no-restricted-globals': ['error', 'name', 'length'],
    'prefer-arrow-callback': 'error',
    'quotes': ['error', 'single', {'allowTemplateLiterals': true}],
    'max-len': ['error', {'code': 120}],
    'require-jsdoc': 'off',
    'valid-jsdoc': 'off',
    'linebreak-style': 'off', // Disable for Windows compatibility
  },
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
};

