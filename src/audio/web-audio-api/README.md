# Web Audio API Wrapper

This package provides MoonBit wrappers for the Web Audio API.

## Package Rules

### 1. Link to MDN Documentation

All types and functions must include links to their corresponding MDN documentation in doc comments.

Example:
```moonbit
///| [AudioContext](https://developer.mozilla.org/en-US/docs/Web/API/AudioContext)
pub type AudioContext
```

### 2. Follow JavaScript Naming Conventions (snake_case)

Function names must match the underlying JavaScript API names, converted to snake_case.

- JavaScript: `createOscillator()` → MoonBit: `create_oscillator()`
- JavaScript: `setValueAtTime()` → MoonBit: `set_value_at_time()`

### 3. Encapsulate Low-Level FFI

This package must encapsulate all low-level JavaScript interop (`@js.Any`, `_get`, `_call`, etc.) so that code outside this package does not need to use these primitives directly.

All FFI operations should be hidden behind type-safe APIs:
- Define `#external` types for Web Audio API objects
- Provide typed methods instead of exposing `as_any()` conversions
- Return proper MoonBit types instead of `@js.Any` where possible

### 4. No Application Logic

This package must only contain Web Audio API wrappers and must not include any application-specific logic.

**Allowed:**
- Type definitions for Web Audio API objects
- Methods that directly correspond to Web Audio API methods
- Helper functions for type conversions (e.g., MIDI to frequency)

**Not Allowed:**
- Audio scheduling algorithms
- Music notation processing
- Application state management
- UI-specific audio handling
