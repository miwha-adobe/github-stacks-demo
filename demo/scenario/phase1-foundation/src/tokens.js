// Design tokens shared across the component library.
export const sizes = {
  small: 8,
  medium: 16, // legacy default; see migration phase 1
  large: 24,
};

// New in the migration: named variants layered on top of sizes.
export const variants = {
  primary: { weight: 'bold' },
  secondary: { weight: 'regular' },
};
