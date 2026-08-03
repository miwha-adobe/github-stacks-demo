// Dev-only warning helper. Foundational: other layers build on this.
const seen = new Set();

export function warnOnce(key, message) {
    if (process.env.NODE_ENV === 'production') return;
    if (seen.has(key)) return;
    seen.add(key);
    // eslint-disable-next-line no-console
    console.warn(`[github-stacks-demo] ${message}`);
}
