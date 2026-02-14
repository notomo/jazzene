# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a MoonBit + JavaScript hybrid project using the Luna UI framework. Luna is a reactive UI library with Signal-based fine-grained reactivity (inspired by Solid.js) that compiles MoonBit code to JavaScript for browser execution.

**Key Technologies:**
- **MoonBit**: Primary language for UI logic (`.mbt` files in `src/`)
- **Luna Framework**: Reactive UI library (`mizchi/luna` dependency)
- **Vite**: JavaScript bundler with MoonBit plugin
- **Tailwind CSS v4**: Styling via `@tailwindcss/vite`

## Development Commands

```bash
# Development server with HMR
npm run dev

# Build MoonBit and bundle for production
npm run build

# Type check without building
npm run check

# Format MoonBit code
npm run format

# Test MoonBit code
npm run test
```

## Quality Checks

**IMPORTANT**: Before completing any task, run `npm run check_all` to ensure all checks pass.

## Architecture

### Build Pipeline

1. **MoonBit Compilation**: `moon build` compiles `src/*.mbt` → `_build/js/release/build/app/app.js`
2. **Vite Integration**: `vite-plugin-moonbit` watches MoonBit files and triggers rebuilds
3. **Entry Point**: `main.ts` imports the compiled MoonBit module via `mbt:internal/jazzene` alias
4. **Bundle Output**: Vite bundles everything to `dist/`

The TypeScript path mapping in `tsconfig.json` resolves `mbt:internal/jazzene` to the compiled output.

### Luna Framework Integration

Luna uses **fine-grained reactivity** with Signals:

```moonbit
// Create reactive state
let count = @signals.signal(0)

// Computed values auto-track dependencies
let doubled = @signals.memo(fn() { count.get() * 2 })

// DOM nodes with dynamic content
@luna_dom.div([
  @luna_dom.text_dyn(fn() { "Count: " + count.get().to_string() }),
  @luna_dom.button(
    on=@luna_dom.events().click(_ => count.update(fn(n) { n + 1 })),
    [@luna_dom.text("+1")]
  )
])
```

**Key Luna imports** (from `src/ui/moon.pkg`):
- `mizchi/signals` → Signal primitives (`@signals.*`)
- `mizchi/luna/dom` (alias `@luna_dom`) → DOM node constructors
- `mizchi/js/browser/dom` (alias `@js_dom`) → Browser APIs (document, getElementById)

### File Structure

```
src/
├── lib.mbt          # Main entry point (state management)
├── moon.pkg         # Main package config
├── global.css       # Tailwind imports
├── test_helper/     # Test utilities
├── music/           # Music theory package
│   └── generator/   # Melody/improvisation generation
├── audio/           # Audio synthesis package
│   └── web_audio_api/  # Web Audio API FFI
└── ui/              # UI components package
    ├── app.mbt      # Main application UI and rendering
    ├── sheet/       # Sheet music (lead sheet) rendering
    └── piano_roll/  # Piano roll visualization

main.ts              # JavaScript entry (imports compiled MoonBit)
index.html           # HTML template with #app mount point
_build/js/           # MoonBit build output (gitignored)
.mooncakes/          # MoonBit package cache (like node_modules)
```

### Package Dependency Rules

**CRITICAL**: The main package (`src/moon.pkg`) should ONLY depend on:
- `internal/jazzene/music` - Music theory and primitives
- `internal/jazzene/music/generator` - Melody generation
- `internal/jazzene/audio` - Audio synthesis and Web Audio API
- `internal/jazzene/ui` - UI components and browser APIs
- `mizchi/signals` - Reactive state management (exception for core framework)

**Dependency Hierarchy:**
```
src/ (main)
├─→ mizchi/signals (Signal only)
├─→ internal/jazzene/music (no external dependencies)
│   └─→ internal/jazzene/music/generator
│       └─→ internal/jazzene/music
├─→ internal/jazzene/audio
│   └─→ internal/jazzene/audio/web_audio_api
│       └─→ mizchi/js/core
└─→ internal/jazzene/ui
    ├─→ mizchi/signals
    ├─→ mizchi/luna/dom
    ├─→ mizchi/js/browser/dom
    ├─→ internal/jazzene/music
    ├─→ internal/jazzene/ui/sheet
    └─→ internal/jazzene/ui/piano_roll
```

**Package Responsibilities:**
- **music**: Pure music theory logic (chords, notes, MIDI, beaming, measures)
- **music/generator**: Melody generation and improvisation algorithms
- **audio/web_audio_api**: Low-level Web Audio API FFI wrappers
- **audio**: Audio synthesis, scheduling, AudioContext management
- **ui**: Top-level UI components, DOM construction, browser API wrappers
- **ui/sheet**: Sheet music (lead sheet) SVG rendering
- **ui/piano_roll**: Piano roll canvas visualization

**When adding new code:**
- Music theory logic → `src/music/`
- Melody generation → `src/music/generator/`
- Web Audio API bindings → `src/audio/web_audio_api/`
- Audio synthesis logic → `src/audio/`
- Sheet music rendering → `src/ui/sheet/`
- Piano roll rendering → `src/ui/piano_roll/`
- UI components or browser APIs → `src/ui/`
- Application composition → `src/lib.mbt` (state management only)

## Rendering Flow

1. MoonBit `main()` function runs on page load
2. Gets DOM element: `@js_dom.document().getElementById("app")`
3. Builds component tree using `@luna_dom.*` constructors
4. Mounts to DOM: `@luna_dom.render(element, app)`
5. Signal updates trigger automatic DOM patches

## Tailwind CSS

Using Tailwind v4 via `@tailwindcss/vite` plugin. Import in `src/global.css`:

```css
@import "tailwindcss";
```

**Styling Guidelines:**
- **Use Tailwind utility classes** for all styling - apply classes directly in MoonBit code
- **DO NOT modify `src/global.css`** - it should only contain the Tailwind import
- **NO custom CSS** - use Tailwind's utility classes to achieve desired styling

Apply utility classes directly in MoonBit:
```moonbit
@luna_dom.div([], class="text-3xl flex flex-col gap-3")
```

## Coding Style

### Prefer Iterator Methods Over For Loops

When processing collections, prefer iterator methods (`map`, `fold`, `filter`, etc.) over `for` loops with mutable accumulation:

```moonbit
// Preferred: Using map + flatten for flat_map pattern
sounds.map(fn(sound) { process_sound(sound) }).flatten()

// Preferred: Using fold for accumulation
notes.iter().fold(init=Map::new(), fn(acc, note) {
  acc[note.key] = note.value
  acc
})

// Preferred: Using makei for index-based array creation
Array::makei(count, fn(i) { create_item(i) })

// Avoid: Mutable accumulation with for loops
let result = []
for item in items {
  result.push(transform(item))
}
```

**When to use `for` loops:**
- Complex control flow with `continue`/`break` that cannot be expressed with iterators
- While-style loops with mutable state that doesn't fit iterator patterns
- Performance-critical code where iterator overhead matters

### Prefer Match Over If-Else Chains

Use `match` expressions instead of `if-else` chains for clearer pattern matching:

```moonbit
// Preferred: Using match with tuple patterns and guards
let tie_state = match (total_pieces, split_piece) {
  (1, _) => None
  (_, 0) => TieStart
  (total, piece) if piece == total - 1 => TieEnd
  _ => TieBoth
}

// Avoid: If-else chains
let tie_state = if total_pieces == 1 {
  None
} else if split_piece == 0 {
  TieStart
} else if split_piece == total_pieces - 1 {
  TieEnd
} else {
  TieBoth
}
```

**Benefits of match:**
- Exhaustiveness checking by the compiler
- Clearer intent with pattern matching
- Better support for destructuring and guards

## Important Notes

- **Target Platform**: This project only targets JavaScript (`preferred-target: "js"`)
- **No Hot Reload for MoonBit**: Changes to `.mbt` files require full rebuild (handled by vite-plugin-moonbit)
- **Package Format**: ESM only (`"type": "module"` in package.json, `link: { "js": { "format": "esm" } }` in moon.pkg)
- **Main Entry**: `src/moon.pkg` has `"is-main": true` - this package exports the main function
- **Web Audio API**: All Web Audio API access must go through `src/audio/web_audio_api/`. Other packages should use wrappers in `src/audio/`. Never use raw JavaScript FFI for Web Audio APIs outside this package.
- **MoonBit Reference**: When you need to reference MoonBit language features, syntax, or conventions, use skill by invoking `/moonbit-agent-guide` or `/moonbit-refactoring`.
