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
-- @param - next_line_number is number
-- @return first: number
-- @return second: table of string
function M.GetNextLine(next_line_number)
  local tinysegmenter = require("tinysegmenter")
  local text = vim.fn.getline(next_line_number)
  local text_without_space = vim.fn.substitute(text, '^[[:space:]　]\\+', '', 'g')
  -- 行頭に空白が無い場合、`vim.fn.strcharlen(...)` の返り値が `0` になるので、
  -- `+1` して不正なインデックスにならないようにしている。
  local first_char_position = vim.fn.strcharlen(vim.fn.matchstr(text, '^[[:space:]　]\\+')) + 1
  local parsed_text = tinysegmenter.segment(text_without_space)
  return { first_char_position = first_char_position, parsed_text = parsed_text, }
end

--- 前の行の最後の文字の場所や分かち書きしたテキストを返す関数
-- @param - previous_line_number is number
-- @return first: number
-- @return second: table of string
function M.PreviousNextLine(previous_line_number)
  local tinysegmenter = require("tinysegmenter")
  local text = vim.fn.getline(previous_line_number)
  local text_without_space = vim.fn.substitute(text, '[[:space:]　]\\+\\_$', '', 'g')
  local last_char_position = vim.fn.strcharlen(text_without_space)
  local parsed_text = tinysegmenter.segment(text_without_space)
  return { last_char_position = last_char_position, parsed_text = parsed_text, }
end

--- 現在の行を解析して必要な情報を返す関数
-- @param line_number 行番号
-- @return テーブル: cursor_line_text, cursor_line_text_without_eol_space, cursor_line_text_without_space, first_char_position, last_char_position, parsed_text
function M.AnalyzeLine(line_number, tinysegmenter)
  local cursor_line_text = vim.fn.getline(line_number or '.')
  local first_char_position = vim.fn.strcharlen(vim.fn.matchstr(cursor_line_text, '^[[:space:]　]\\+')) + 1
  if first_char_position == 0 then
    first_char_position = first_char_position + 1
  end

  -- 行末の空白文字を残して分かち書きすると後処理が面倒なので削除する
  local cursor_line_text_without_eol_space = vim.fn.substitute(cursor_line_text, '[[:space:]　]\\+\\_$', '', 'g')
  -- 行頭の空白文字も残すと後処理が面倒なので削除する
  local cursor_line_text_without_space = vim.fn.substitute(cursor_line_text_without_eol_space, '^[[:space:]　]\\+', '', 'g')

  local last_char_position = vim.fn.strcharlen(cursor_line_text_without_eol_space)
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

--- ユーザーが設定したモーションが正しいモーションか確認し、正しくない場合はそのモーションを削除したモーションを返す関数
-- @param - motions is table
-- @return table of string
function M.MotionValidation(motions)
  local validation_motion = false
  local original_motions = { 'w', 'b', 'e', 'ge' }
  local invalid_motion_index = {}
  for i, motion in ipairs(motions) do
    for _, original_motion in ipairs(original_motions) do
      if string.match(motion, original_motion) ~= nil then
        validation_motion = true
        break
      else
        validation_motion = false
      end
    end
    if validation_motion == false then
      vim.notify(motion .. " is invalid motion. Ignore this motion. (extend_word_motions plugin)",
        vim.log.levels.error)
      table.insert(invalid_motion_index, 1, i)
    end
  end
  for _, index in ipairs(invalid_motion_index) do
    table.remove(motions, index)
  end
  return motions
end

return M
