local M = {}

local util = require('extend_word_motion.util')
local pcall_result, tinysegmenter = pcall(require, "tinysegmenter")

M.options = {
  extend_word_motions = { 'w', 'b', 'e', 'ge' }
}

function M.setup(opts)
  if pcall_result == false then
    vim.notify("Not found 'tinysegment.nvim'!\nExtend_word_motion required 'tinysegmenter.nvim'.")
    -- Lua で早期リターンするためのコード
    do return end
  else
    opts.extend_word_motions = util.MotionValidation(opts.extend_word_motions)
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})
    local cursor_position = {}
    local cursor_line_number = 0
    local cursor_line_text = ''
    local cursor_line_text_without_eol_space = ''
    local cursor_line_text_without_space = ''
    local first_char_position = 0
    local last_char_position = 0
    local parsed_text = {}
    local under_cursor_char = ''
    for _, motion in ipairs(M.options.extend_word_motions) do
      vim.api.nvim_set_keymap('n', motion, '', {
        noremap = true,
        callback = function()
          local count1 = vim.v.count1
          while count1 > 0 do
            cursor_position = vim.fn.getcursorcharpos()
            cursor_line_text = vim.fn.getline('.')
            under_cursor_char = vim.fn.matchstr(cursor_line_text, '.', vim.fn.col('.') - 1)
            if cursor_line_number ~= cursor_position[2] or cursor_line_number == 0 then
              -- 1回目の実行とは別の行に移動しているので、再度カーソル下の行を取得する。
              cursor_line_text = vim.fn.getline('.')
              first_char_position = vim.fn.strcharlen(vim.fn.matchstr(cursor_line_text, '^[[:space:]　]\\+')) + 1
              if first_char_position == 0 then
                first_char_position = first_char_position + 1
              end
              -- 行末の空白文字を残して分かち書きすると後処理が面倒なので削除する
              cursor_line_text_without_eol_space = vim.fn.substitute(cursor_line_text, '[[:space:]　]\\+\\_$', '', 'g')
              -- 行頭の空白文字も残すと後処理が面倒なので削除する
              cursor_line_text_without_space = vim.fn.substitute(cursor_line_text_without_eol_space, '^[[:space:]　]\\+', '', 'g')
            end
            if motion == 'w' or motion == 'e' then
              -- `w`, `e` はカーソルが非空白文字の末尾にあれば処理を分岐する必要があるので、
              -- 非空白文字の末尾の位置を取得しておく。
              last_char_position = vim.fn.strcharlen(cursor_line_text_without_eol_space)
            end
            parsed_text = tinysegmenter.segment(cursor_line_text_without_space)
            ExtendWordMotion({
              motion = motion,
              parsed_text = parsed_text,
              cursor_position = cursor_position,
              under_cursor_char = under_cursor_char,
              first_char_position = first_char_position,
              last_char_position = last_char_position
            })
            count1 = count1 - 1
          end
        end
      })
    end
  end
end

function ExtendWordMotion(arg)
  -- ASCIIコード or 全角スペースの上にカーソルがある場合は通常の word motion を実行する
  if util.IsASCIIChar(arg.under_cursor_char) or util.IsFullWidthSpace(arg.under_cursor_char) then
    vim.cmd.normal({ arg.motion, bang = true })
  else
    local parsed_text_with_position = {}
    local text_start_position = 1
    for i, text in ipairs(arg.parsed_text) do
      parsed_text_with_position[i] = {}
      parsed_text_with_position[i]['text'] = text
      parsed_text_with_position[i]['start'] = text_start_position
      parsed_text_with_position[i]['end'] = text_start_position + vim.fn.strcharlen(text) - 1
      text_start_position = text_start_position + vim.fn.strcharlen(text)
    end
    for i, text_with_position in ipairs(parsed_text_with_position) do
      if arg.cursor_position[3] >= text_with_position['start'] + arg.first_char_position - 1 and
          arg.cursor_position[3] <= text_with_position['end'] + arg.first_char_position - 1 then
        if arg.motion == 'w' then
          -- カーソルが非空白文字の末尾 or 分かち書きした文字列の最後のノードにある
          if arg.cursor_position[3] == arg.last_char_position or
              text_with_position['end'] + arg.first_char_position - 1 == arg.last_char_position then
            local next_line = util.GetNextLine(arg.cursor_position[2] + 1)
            arg.cursor_position[3] = next_line.first_char_position
            arg.cursor_position[2] = arg.cursor_position[2] + 1
          elseif i ~= #parsed_text_with_position then
            arg.cursor_position[3] = parsed_text_with_position[i + 1]['start'] + arg.first_char_position - 1
          end
        end
        if arg.motion == 'ge' then
          -- カーソルが非空白文字の始め or 分かち書きした文字列の最初のノードにある
          if arg.cursor_position[3] == arg.first_char_position or
              text_with_position['start'] + arg.first_char_position - 1 == arg.first_char_position then
            local previous_line = util.PreviousNextLine(arg.cursor_position[2] - 1)
            arg.cursor_position[3] = previous_line.last_char_position
            arg.cursor_position[2] = arg.cursor_position[2] - 1
          elseif i ~= 1 then
            arg.cursor_position[3] = parsed_text_with_position[i - 1]['end'] + arg.first_char_position - 1
          end
        end
        if arg.motion == 'b' then
          -- カーソルが非空白文字の始めにある
          if arg.cursor_position[3] == arg.first_char_position then
            local previous_line = util.PreviousNextLine(arg.cursor_position[2] - 1)
            arg.cursor_position[3] = previous_line.last_char_position - vim.fn.strcharlen(previous_line.parsed_text[#previous_line.parsed_text]) + 1
            arg.cursor_position[2] = arg.cursor_position[2] - 1
            -- カーソルが分かち書きした文字列の最初のノードにある
          elseif text_with_position['start'] + arg.first_char_position - 1 == arg.first_char_position then
            arg.cursor_position[3] = text_with_position['start'] + arg.first_char_position - 1
          elseif i ~= 1 then
            -- カーソルが分かち書きした各ノードの1文字目にある
            if arg.cursor_position[3] == text_with_position['start'] + arg.first_char_position - 1 then
              arg.cursor_position[3] = parsed_text_with_position[i - 1]['start'] + arg.first_char_position - 1
            else
              arg.cursor_position[3] = text_with_position['start'] + arg.first_char_position - 1
            end
          end
        end
        if arg.motion == 'e' then
          -- カーソルが非空白文字の末尾にある
          if arg.cursor_position[3] == arg.last_char_position then
            local next_line = util.GetNextLine(arg.cursor_position[2] + 1)
            arg.cursor_position[3] = vim.fn.strcharlen(next_line.parsed_text[1]) + next_line.first_char_position - 1
            arg.cursor_position[2] = arg.cursor_position[2] + 1
            -- カーソルが分かち書きした文字列の最後のノードにある
          elseif text_with_position['end'] + arg.first_char_position - 1 == arg.last_char_position then
            arg.cursor_position[3] = text_with_position['end'] + arg.first_char_position - 1
          elseif i ~= #parsed_text_with_position then
            -- カーソルが分かち書きした各ノードの最後の文字にある
            if arg.cursor_position[3] == text_with_position['end'] + arg.first_char_position - 1 then
              arg.cursor_position[3] = parsed_text_with_position[i + 1]['end'] + arg.first_char_position - 1
            else
              arg.cursor_position[3] = text_with_position['end'] + arg.first_char_position - 1
            end
          end
        end
        vim.fn.setcursorcharpos(arg.cursor_position[2], arg.cursor_position[3])
        break
      end
    end
  end
end

return M
