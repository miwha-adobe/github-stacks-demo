# Validation

```js
import { validateSize, validateVariant } from 'github-stacks-demo';

validateSize('m'); // true
validateSize('xxl'); // false, warns once in dev
validateVariant('accent'); // true
```
