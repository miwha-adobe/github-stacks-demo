// Validation logic. DEPENDS ON the foundation layer (warn + tokens).
import { warnOnce } from './warn.js';
import { SIZES, VARIANTS } from './tokens.js';

export function validateSize(value) {
    if (!SIZES.includes(value)) {
        warnOnce(`size:${value}`, `"${value}" is not a valid size. Expected one of: ${SIZES.join(', ')}.`);
        return false;
    }
    return true;
}

export function validateVariant(value) {
    if (!VARIANTS.includes(value)) {
        warnOnce(`variant:${value}`, `"${value}" is not a valid variant. Expected one of: ${VARIANTS.join(', ')}.`);
        return false;
    }
    return true;
}
