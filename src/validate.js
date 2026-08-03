import { sizes, variants } from './tokens.js';

// Migration phase 3: centralized validation for component options.
export function validateOptions(opts) {
  const errors = [];
  if (opts.size && !(opts.size in sizes)) {
    errors.push(`unknown size: ${opts.size}`);
  }
  if (opts.variant && !(opts.variant in variants)) {
    errors.push(`unknown variant: ${opts.variant}`);
  }
  return errors;
}
