module.exports = [
  {
    files: ["**/*.js"],
    languageOptions: {
      parserOptions: {
        ecmaVersion: 12,
        sourceType: "module",
      },
      globals: {
        admin: "readonly",
        functions: "readonly",
      },
    },
    rules: {
      "indent": ["error", 2],
      "max-len": ["error", { "code": 80 }],
    },
  },
];

