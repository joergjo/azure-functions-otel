import globals from "globals";
import tseslint from "typescript-eslint";
import eslintPluginPrettierRecommended from "eslint-plugin-prettier/recommended";
import { defineConfig } from "eslint/config";

const typescriptSourceFiles = ["src/**/*.ts"];

export default defineConfig([
  {
    ignores: [
      ".azure/**",
      "**/.terraform/**",
      "azurite/**",
      "dist/**",
      "**/*.{js,mjs,cjs}",
      "local.settings.json",
      "cloud*.settings.json",
      "**/*.tfvars.json",
      "package-lock.json",
    ],
  },
  ...tseslint.configs.recommended.map((config) => ({
    ...config,
    files: typescriptSourceFiles,
  })),
  {
    files: typescriptSourceFiles,
    languageOptions: {
      globals: globals.node,
    },
    rules: {
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
    },
  },
  {
    ...eslintPluginPrettierRecommended,
    files: typescriptSourceFiles,
  },
]);
