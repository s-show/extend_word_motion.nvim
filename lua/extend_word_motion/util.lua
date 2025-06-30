--- 付随的な処理や繰り返し実行する処理を関数にして集めたモジュール
-- @module M
local M = {}

--- 引数で渡された文字が ASCII 文字かそうでないか判断する関数
-- @param - char is string
-- @return true or false
function M.IsASCIIChar(char)
  if vim.fn.strcharlen(char) > 1 then
    return false
  end
  local char_byte_count = string.len(char)
  if char_byte_count == 1 then
    return true
  else
    return false
  end
end

--- 引数で渡された文字が全角スペースかそうでないか判断する関数
-- @param - char is string
-- @return true or false
function M.IsFullWidthSpace(char)
  if char == '　' then
    return true
  else
    return false
  end
end

--- 次の行の最初の文字の場所や分かち書きしたテキストを返す関数
-- @param  next_line_number: 現在のカーソル行の次の行の行番号
-- @return first_char_position: カーソル行の最初の非空白文字の場所
-- @return parsed_text: tinysegmenter で分かち書きした後のテキスト
function M.GetNextLine(next_line_number)
  local tinysegmenter = require("tinysegmenter")
  local text = vim.fn.getline(next_line_number)
  local text_without_space = vim.fn.substitute(text, '^[[:space:]　]\\+', '', 'g')
  -- 行頭に空白が無い場合、`vim.fn.strcharlen(...)` の返り値が `0` になるので、
  -- `+1` して不正なインデックスにならないようにしている。
  local first_char_position = vim.fn.strcharlen(vim.fn.matchstr(text, '^[[:space:]　]\\+')) + 1
  local parsed_text = tinysegmenter.segment(text_without_space)
  return {
    first_char_position = first_char_position,
    parsed_text = parsed_text,
  }
end

--- 前の行の最後の文字の場所や分かち書きしたテキストを返す関数
-- @param  previous_line_number: 現在のカーソル行の前の行の行番号 
-- @return last_char_position: カーソル行の最後の非空白文字の場所
-- @return parsed_text: tinysegmenter で分かち書きした後のテキスト
function M.PreviousNextLine(previous_line_number)
  local tinysegmenter = require("tinysegmenter")
  local text = vim.fn.getline(previous_line_number)
  local text_without_space = vim.fn.substitute(text, '[[:space:]　]\\+\\_$', '', 'g')
  local last_char_position = vim.fn.strcharlen(text_without_space)
  local parsed_text = tinysegmenter.segment(text_without_space)
  return {
    last_char_position = last_char_position,
    parsed_text = parsed_text,
  }
end

--- 現在の行を解析して必要な情報を返す関数
-- @param line_number 行番号 (省略可能、省略時は現在の行)
-- @param tinysegmenter TinySegmenterインスタンス
-- @return テーブル: 以下のキーを持つ行解析結果
--   - cursor_line_text: 元の行テキスト (空白文字含む)
--   - cursor_line_text_without_eol_space: 行末の空白文字を削除したテキスト
--   - cursor_line_text_without_space: 行頭・行末の空白文字を削除したテキスト
--   - first_char_position: 最初の非空白文字の位置 (1ベース)
--   - last_char_position: 最後の非空白文字の位置 (文字数)
--   - parsed_text: TinySegmenterで分かち書きした結果のテーブル
function M.AnalyzeLine(line_number, tinysegmenter)
  local cursor_line_text = vim.fn.getline(line_number or '.')
  -- カーソル行の最初の非空白文字の位置を格納する。
  local first_char_position = vim.fn.strcharlen(vim.fn.matchstr(cursor_line_text, '^[[:space:]　]\\+')) + 1
  if first_char_position == 0 then
    first_char_position = first_char_position + 1
  end

  -- 行末の空白文字を残して分かち書きすると後処理が面倒なので削除する
  local cursor_line_text_without_eol_space = vim.fn.substitute(cursor_line_text, '[[:space:]　]\\+\\_$', '', 'g')
  -- 行末の文字の位置を格納する
  local last_char_position = vim.fn.strcharlen(cursor_line_text_without_eol_space)
  -- 行頭の空白文字も残すと後処理が面倒なので削除する
  local cursor_line_text_without_space = vim.fn.substitute(cursor_line_text_without_eol_space, '^[[:space:]　]\\+', '', 'g')

  local parsed_text = tinysegmenter.segment(cursor_line_text_without_space)

  return {
    cursor_line_text = cursor_line_text,
    cursor_line_text_without_eol_space = cursor_line_text_without_eol_space,
    cursor_line_text_without_space = cursor_line_text_without_space,
    first_char_position = first_char_position,
    last_char_position = last_char_position,
    parsed_text = parsed_text
  }
end

--- ユーザーが設定したモーションからこのプラグインでは非対応のモーションを削除して返す関数
-- @param given_motions: `setup()` 関数内で設定されたモーションリスト
-- @return given_motions: 非対応のモーションを削除したモーションリスト
function M.RemoveInvalidMotion(given_motions)
  -- テーブル同士の比較よりテーブルと文字列の比較の方が簡単なので
  -- デフォルトモーションを文字列で表現している。
  local default_motions = 'wbege'
  for i, given_motion in ipairs(given_motions) do
    if string.match(default_motions, given_motion) == nil then
      table.remove(given_motions, i)
      vim.notify(
        given_motion ..
        " is invalid motion in extend_word_motions plugin. Ignore this motion. (extend_word_motions plugin)",
        vim.log.levels.error)
    end
  end
  return given_motions
end

--- ユーザーが設定したモードからこのプラグインでは非対応のモードを削除して返す関数
-- @param given_modes: `setup()` 関数内で設定されたモードリスト
-- @return given_modes: 非対応のモードを削除したモードリスト
function M.RemoveInvalidMode(given_modes)
  -- テーブル同士の比較よりテーブルと文字列の比較の方が簡単なので
  -- デフォルトモードを文字列で表現している。
  local default_modes = 'nvo'
  for i, given_mode in ipairs(given_modes) do
    if string.match(default_modes, given_mode) == nil then
      table.remove(given_modes, i)
      vim.notify(
        given_mode ..
        " is an unacceptable mode in extend_word_motions plugin. Ignore this mode. (extend_word_motions plugin)",
        vim.log.levels.error)
    end
  end
  return given_modes
end

return M
