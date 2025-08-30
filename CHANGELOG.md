 Change Log

## 1.2.0 (2025-08-30)

### 概要

- デバッグ機能を追加し、問題診断を容易に
- 設定確認用の関数を追加
- ドキュメントの改善と整理

### 新機能

- **デバッグ機能**: `debug` オプションを追加し、分かち書き結果などのデバッグ情報を出力可能に
- **設定確認関数**: `show_config()` 関数を追加し、現在の設定を簡単に確認可能に

### 改善

- **ドキュメント構造**: README.mdのオプション説明をセクション分けし、可読性を向上
- **ヘルプファイル**: 新機能のドキュメントを追加し、フォーマットを改善

### バグ修正

- **変数スコープ**: `handle_motion` 関数内の `line_info` 変数のスコープを適切に修正

## 1.1.0 (2025-06-30)

### 概要

- 大幅なリファクタリング実施
- ビジュアルモードとオペレーション待機モードでも使えるようにしました。
- 関数ドキュメントを全面的に改善し、保守性を向上

### 新機能

- **モード設定機能**: `extend_modes` オプションでキーマップを適用するモードを個別設定可能 [f3305be](https://github.com/s-show/extend_word_motion.nvim/commit/f3305be)
- **オペレータペンディングモード対応**: `o` モードに対応し、`dw`, `cw`, `yw` などのオペレータとの組み合わせが動作 [df40f1b](https://github.com/s-show/extend_word_motion.nvim/commit/df40f1b)

### リファクタリング

- **行解析処理の共通化**: `AnalyzeLine` 関数で現在行の解析処理を統一 [6c67c62](https://github.com/s-show/extend_word_motion.nvim/commit/6c67c62)
- **モジュール分離**: `ExtendWordMotion` 処理を独立した `motion.lua` モジュールに分離してコードの見通しをよくしました。 [5504df5](https://github.com/s-show/extend_word_motion.nvim/commit/5504df5)
- **setup関数の簡潔化**: 初期化処理を整理し、モジュール間の依存関係を明確化 [f399ef8](https://github.com/s-show/extend_word_motion.nvim/commit/f399ef8)
- **バリデーション関数の改善**: `MotionValidation` を `RemoveInvalidMotion` に名前変更し、新たに `RemoveInvalidMode` 関数を追加 [f3305be](https://github.com/s-show/extend_word_motion.nvim/commit/f3305be)

### ドキュメント

- **CLAUDE.md追加**: Claude Code用のプロジェクト説明ファイルを追加し、アーキテクチャと開発ガイドラインを文書化 [06c86c0](https://github.com/s-show/extend_word_motion.nvim/commit/06c86c0)

## 1.0.1 (2024-12-28)

### 概要

- ヘルプファイルの拡張子を .txt から .jax に変更 [8e415e1](https://github.com/s-show/extend_word_motion.nvim/commit/8e415e1740490c500e6a37237b434ce0d5d460de)

## 1.0.0 (2024-12-24)

### 概要

最初のリリース
