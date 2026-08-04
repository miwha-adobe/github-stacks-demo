import { sizes } from './tokens.js';

// Legacy API: a single positional `size` string, no validation.
export function createComponent(size) {
  return {
    size: sizes[size] ?? sizes.medium,
  };
}
