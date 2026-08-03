import { sizes, variants } from './tokens.js';

// Migration phase 1: accept an options object while still supporting the
// legacy positional `size` string. Both paths coexist during the migration.
export function createComponent(options) {
  const opts = typeof options === 'string' ? { size: options } : options ?? {};
  const size = sizes[opts.size] ?? sizes.medium;
  const variant = variants[opts.variant] ?? variants.primary;
  return { size, variant };
}
