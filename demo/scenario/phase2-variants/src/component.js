import { sizes, variants } from './tokens.js';

// Migration phase 2: variants now resolve to a full style object.
function resolveVariant(name) {
  const variant = variants[name] ?? variants.primary;
  return { weight: variant.weight, uppercase: name === 'primary' };
}

export function createComponent(options) {
  const opts = typeof options === 'string' ? { size: options } : options ?? {};
  const size = sizes[opts.size] ?? sizes.medium;
  const style = resolveVariant(opts.variant);
  return { size, style };
}
