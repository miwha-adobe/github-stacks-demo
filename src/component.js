import { sizes, variants, defaults } from './tokens.js';
import { validateOptions } from './validate.js';

// Migration phase 3: validate options and fall back to shared defaults.
function resolveVariant(name) {
  const variant = variants[name] ?? variants.primary;
  return { weight: variant.weight, uppercase: name === 'primary' };
}

export function createComponent(options) {
  const opts = typeof options === 'string' ? { size: options } : options ?? {};
  const errors = validateOptions(opts);
  if (errors.length > 0) {
    throw new Error(`invalid component options: ${errors.join(', ')}`);
  }
  const size = sizes[opts.size ?? defaults.size];
  const style = resolveVariant(opts.variant ?? defaults.variant);
  return { size, style };
}
