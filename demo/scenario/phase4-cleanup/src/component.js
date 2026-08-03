import { sizes, variants, defaults } from './tokens.js';
import { validateOptions } from './validate.js';

// Migration phase 4: legacy positional `size` string removed. Options only.
function resolveVariant(name) {
  const variant = variants[name] ?? variants.primary;
  return { weight: variant.weight, uppercase: name === 'primary' };
}

export function createComponent(options = {}) {
  const errors = validateOptions(options);
  if (errors.length > 0) {
    throw new Error(`invalid component options: ${errors.join(', ')}`);
  }
  const size = sizes[options.size ?? defaults.size];
  const style = resolveVariant(options.variant ?? defaults.variant);
  return { size, style };
}
