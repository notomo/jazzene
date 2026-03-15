# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MoonBit + JavaScript hybrid using Luna UI framework (Signal-based reactivity, inspired by Solid.js). Compiles MoonBit to JavaScript for browser execution.

**Key Technologies:** MoonBit, Luna (`mizchi/luna`), Vite, Tailwind CSS v4

## Development Commands

```bash
npm run dev      # Development server with HMR
npm run build    # Build and bundle for production
npm run check    # Type check
npm run format   # Format MoonBit code
npm run test     # Test MoonBit code
```

## Quality Checks

**IMPORTANT**: Before completing any task, run `npm run check_all` to ensure all checks pass.

## Package Structure

```
src/
├── lib.mbt          # Main entry
├── music/           # Music theory (pure logic)
│   ├── sheet/       # Sheet music layout calculations
│   └── generator/   # Melody/improvisation generation
├── audio/           # Audio synthesis
│   └── web_audio_api/  # Web Audio API FFI
└── ui/              # UI components
    ├── theme/       # Color theme constants
    ├── sheet/       # Sheet music SVG rendering
    └── piano_roll/  # Piano roll visualization
```

## Package Rules

**CRITICAL**: The main package (`src/moon.pkg`) should ONLY depend on: `internal/jazzene/music`, `internal/jazzene/audio`, `internal/jazzene/ui`, `mizchi/signals`.

**When adding new code:**
- Music theory logic → `src/music/`
- Sheet music layout (pure logic, no rendering) → `src/music/sheet/`
- Melody generation → `src/music/generator/`
- Web Audio API bindings → `src/audio/web_audio_api/`
- Audio synthesis logic → `src/audio/`
- Color theme constants → `src/ui/theme/`
- Sheet music SVG rendering → `src/ui/sheet/`
- Piano roll rendering → `src/ui/piano_roll/`
- UI components or browser APIs → `src/ui/`
- Application composition → `src/lib.mbt`

## Tailwind CSS

Use Tailwind utility classes for all styling applied directly in MoonBit code (e.g. `class="text-3xl flex flex-col gap-3"`). **DO NOT modify `src/global.css`**. No custom CSS.

## Coding Style

**Prefer iterator methods over for loops**: Use `map`, `fold`, `filter`, `Array::makei` etc. for collection processing. Use `for` loops only for complex control flow (`continue`/`break`) or while-style loops.

**Prefer match over if-else chains**: Use `match` expressions for pattern matching — enables exhaustiveness checking, clearer intent, and better destructuring support.

## Important Notes

- **Web Audio API**: All access must go through `src/audio/web_audio_api/`. Never use raw JS FFI for Web Audio outside this package.
- **Target**: JS only (`preferred-target: "js"`); ESM format; `src/moon.pkg` has `"is-main": true`.
- **MoonBit Reference**: Use `/moonbit-agent-guide` or `/moonbit-refactoring` skills for MoonBit language questions.
