# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Neovim plugin that extends word motion functionality for Japanese text. It uses TinySegmenter.nvim to perform Japanese word segmentation and provides natural word-based cursor movement in Japanese text, unlike Neovim's default behavior which treats different character types (kanji, hiragana, katakana) as separate movement boundaries.

## Architecture

The plugin consists of several key components:

- **lua/extend_word_motion/init.lua**: Main module containing the setup function and core ExtendWordMotion logic. Handles keymap registration for w/b/e/ge motions and implements the segmentation-based cursor movement.
- **lua/extend_word_motion/util.lua**: Utility functions for character detection (ASCII, full-width space), line navigation, and motion validation.
- **plugin/extend_word_motion.vim**: Standard Neovim plugin guard to prevent multiple loading.

## Key Dependencies

- **tinysegmenter.nvim**: Required dependency for Japanese text segmentation. The plugin will not function without this dependency and will show a notification if it's missing.

## Configuration

The plugin accepts an `extend_motions` option (note: there's an inconsistency where README mentions `extend_word_motions` but code uses `extend_motions`) to specify which motions to extend. Default motions are `{ 'w', 'b', 'e', 'ge' }`.

## Core Logic

The plugin works by:
1. Intercepting configured word motions (w/b/e/ge)
2. Segmenting the current line using TinySegmenter
3. Calculating cursor position based on segmentation boundaries
4. Falls back to default Neovim behavior for ASCII characters and full-width spaces

## Development Notes

- All code comments and documentation are in Japanese
- The plugin handles multi-byte character positioning carefully using Neovim's character position functions
- Line boundaries are handled specially for each motion type
- Motion validation ensures only valid motions are configured