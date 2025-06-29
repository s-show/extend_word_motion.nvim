--- 拡張されたワードモーション処理のコア機能
-- @module motion
local M = {}

local util = require('extend_word_motion.util')

--- 拡張されたワードモーション処理を実行する関数
-- @param arg テーブル: motion, parsed_text, cursor_position, under_cursor_char, first_char_position, last_char_position
function M.execute_motion(arg)
  -- ASCIIコード or 全角スペースの上にカーソルがある場合は通常の word motion を実行する
  if util.IsASCIIChar(arg.under_cursor_char) or util.IsFullWidthSpace(arg.under_cursor_char) then
    vim.cmd.normal({ arg.motion, bang = true })
    return
  end

  local parsed_text_with_position = M.create_text_positions(arg.parsed_text)
  M.process_motion(arg, parsed_text_with_position)
end

--- 分析されたテキストに位置情報を追加する関数
-- @param parsed_text 分析されたテキストのテーブル
-- @return 位置情報付きのテーブル
function M.create_text_positions(parsed_text)
  local parsed_text_with_position = {}
  local text_start_position = 1

  for i, text in ipairs(parsed_text) do
    parsed_text_with_position[i] = {
      text = text,
      start = text_start_position,
      ['end'] = text_start_position + vim.fn.strcharlen(text) - 1
    }
    text_start_position = text_start_position + vim.fn.strcharlen(text)
  end

  return parsed_text_with_position
end

--- モーションの処理を実行する関数
-- @param arg 引数テーブル
-- @param parsed_text_with_position 位置情報付きテキスト
function M.process_motion(arg, parsed_text_with_position)
  for i, text_with_position in ipairs(parsed_text_with_position) do
    if M.is_cursor_in_segment(arg.cursor_position[3], text_with_position, arg.first_char_position) then
      M.handle_motion_type(arg, text_with_position, parsed_text_with_position, i)
      vim.fn.setcursorcharpos(arg.cursor_position[2], arg.cursor_position[3])
      break
    end
  end
end

--- カーソルが指定されたセグメント内にあるかチェックする関数
-- @param cursor_col カーソルの列位置
-- @param text_with_position 位置情報付きテキスト
-- @param first_char_position 最初の文字の位置
-- @return boolean
function M.is_cursor_in_segment(cursor_col, text_with_position, first_char_position)
  return cursor_col >= text_with_position['start'] + first_char_position - 1 and
         cursor_col <= text_with_position['end'] + first_char_position - 1
end

--- モーションタイプに応じた処理を実行する関数
-- @param arg 引数テーブル
-- @param text_with_position 現在のテキスト位置情報
-- @param parsed_text_with_position 全体のテキスト位置情報
-- @param current_index 現在のインデックス
function M.handle_motion_type(arg, text_with_position, parsed_text_with_position, current_index)
  if arg.motion == 'w' then
    M.handle_w_motion(arg, text_with_position, parsed_text_with_position, current_index)
  elseif arg.motion == 'ge' then
    M.handle_ge_motion(arg, text_with_position, parsed_text_with_position, current_index)
  elseif arg.motion == 'b' then
    M.handle_b_motion(arg, text_with_position, parsed_text_with_position, current_index)
  elseif arg.motion == 'e' then
    M.handle_e_motion(arg, text_with_position, parsed_text_with_position, current_index)
  end
end

--- 'w' モーションの処理
-- @param arg 引数テーブル
-- @param text_with_position 現在のテキスト位置情報
-- @param parsed_text_with_position 全体のテキスト位置情報
-- @param current_index 現在のインデックス
function M.handle_w_motion(arg, text_with_position, parsed_text_with_position, current_index)
  -- カーソルが非空白文字の末尾 or 分かち書きした文字列の最後のノードにある
  if arg.cursor_position[3] == arg.last_char_position or
      text_with_position['end'] + arg.first_char_position - 1 == arg.last_char_position then
    local next_line = util.GetNextLine(arg.cursor_position[2] + 1)
    arg.cursor_position[3] = next_line.first_char_position
    arg.cursor_position[2] = arg.cursor_position[2] + 1
  elseif current_index ~= #parsed_text_with_position then
    arg.cursor_position[3] = parsed_text_with_position[current_index + 1]['start'] + arg.first_char_position - 1
  end
end

--- 'ge' モーションの処理
-- @param arg 引数テーブル
-- @param text_with_position 現在のテキスト位置情報
-- @param parsed_text_with_position 全体のテキスト位置情報
-- @param current_index 現在のインデックス
function M.handle_ge_motion(arg, text_with_position, parsed_text_with_position, current_index)
  -- カーソルが非空白文字の始め or 分かち書きした文字列の最初のノードにある
  if arg.cursor_position[3] == arg.first_char_position or
      text_with_position['start'] + arg.first_char_position - 1 == arg.first_char_position then
    local previous_line = util.PreviousNextLine(arg.cursor_position[2] - 1)
    arg.cursor_position[3] = previous_line.last_char_position
    arg.cursor_position[2] = arg.cursor_position[2] - 1
  elseif current_index ~= 1 then
    arg.cursor_position[3] = parsed_text_with_position[current_index - 1]['end'] + arg.first_char_position - 1
  end
end

--- 'b' モーションの処理
-- @param arg 引数テーブル
-- @param text_with_position 現在のテキスト位置情報
-- @param parsed_text_with_position 全体のテキスト位置情報
-- @param current_index 現在のインデックス
function M.handle_b_motion(arg, text_with_position, parsed_text_with_position, current_index)
  -- カーソルが非空白文字の始めにある
  if arg.cursor_position[3] == arg.first_char_position then
    local previous_line = util.PreviousNextLine(arg.cursor_position[2] - 1)
    arg.cursor_position[3] = previous_line.last_char_position - vim.fn.strcharlen(previous_line.parsed_text[#previous_line.parsed_text]) + 1
    arg.cursor_position[2] = arg.cursor_position[2] - 1
    -- カーソルが分かち書きした文字列の最初のノードにある
  elseif text_with_position['start'] + arg.first_char_position - 1 == arg.first_char_position then
    arg.cursor_position[3] = text_with_position['start'] + arg.first_char_position - 1
  elseif current_index ~= 1 then
    -- カーソルが分かち書きした各ノードの1文字目にある
    if arg.cursor_position[3] == text_with_position['start'] + arg.first_char_position - 1 then
      arg.cursor_position[3] = parsed_text_with_position[current_index - 1]['start'] + arg.first_char_position - 1
    else
      arg.cursor_position[3] = text_with_position['start'] + arg.first_char_position - 1
    end
  end
end

--- 'e' モーションの処理
-- @param arg 引数テーブル
-- @param text_with_position 現在のテキスト位置情報
-- @param parsed_text_with_position 全体のテキスト位置情報
-- @param current_index 現在のインデックス
function M.handle_e_motion(arg, text_with_position, parsed_text_with_position, current_index)
  -- カーソルが非空白文字の末尾にある
  if arg.cursor_position[3] == arg.last_char_position then
    local next_line = util.GetNextLine(arg.cursor_position[2] + 1)
    arg.cursor_position[3] = vim.fn.strcharlen(next_line.parsed_text[1]) + next_line.first_char_position - 1
    arg.cursor_position[2] = arg.cursor_position[2] + 1
    -- カーソルが分かち書きした文字列の最後のノードにある
  elseif text_with_position['end'] + arg.first_char_position - 1 == arg.last_char_position then
    arg.cursor_position[3] = text_with_position['end'] + arg.first_char_position - 1
  elseif current_index ~= #parsed_text_with_position then
    -- カーソルが分かち書きした各ノードの最後の文字にある
    if arg.cursor_position[3] == text_with_position['end'] + arg.first_char_position - 1 then
      arg.cursor_position[3] = parsed_text_with_position[current_index + 1]['end'] + arg.first_char_position - 1
    else
      arg.cursor_position[3] = text_with_position['end'] + arg.first_char_position - 1
    end
  end
end

return M
