local M = {}

local pcall_result, tinysegmenter = pcall(require, "tinysegmenter")
local util = require('extend_word_motion.util')
local motion = require('extend_word_motion.motion')

M.options = {}

function M.setup(opts)
  if pcall_result == false then
    vim.notify("Not found 'tinysegment.nvim'!\nExtend_word_motion required 'tinysegmenter.nvim'.")
    return
  end

  local default_motions = { 'w', 'b', 'e', 'ge' }
  local default_modes = { 'n', 'v', 'o' }
  local extend_motions = {}
  local extend_modes = {}

  -- ユーザーが `setup()` 関数でモーションを設定していなければデフォルトモーションを使う
  if opts.extend_motions == nil then
    extend_motions = default_motions
  else
    extend_motions = util.RemoveInvalidMotion(opts.extend_motions)
  end
  -- ユーザーが `setup()` 関数でモードを設定していなければデフォルトモードを使う
  if opts.extend_modes == nil then
    extend_modes = default_modes
  else
    extend_modes = util.RemoveInvalidMode(opts.extend_modes)
  end
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})

  for _, motion_key in ipairs(extend_motions) do
    vim.keymap.set(extend_modes, motion_key, '', {
      noremap = true,
      callback = function()
        M.handle_motion(motion_key)
      end
    })
  end
end

--- モーション処理のハンドラー関数
-- @param motion_key 実行するモーション ('w', 'b', 'e', 'ge')
function M.handle_motion(motion_key)
  local count1 = vim.v.count1
  local cursor_line_number = 0

  while count1 > 0 do
    local cursor_position = vim.fn.getcursorcharpos()
    local under_cursor_char = vim.fn.matchstr(vim.fn.getline('.'), '.', vim.fn.col('.') - 1)

    local line_info
    if cursor_line_number ~= cursor_position[2] or cursor_line_number == 0 then
      -- 1回目の実行か、または、2回目以降の移動で直前のカーソル行と異なる行に移動したら、
      -- その時点のカーソル行の解析結果を変数に格納する。
      line_info = util.AnalyzeLine('.', tinysegmenter)
      cursor_line_number = cursor_position[2]
    end

    local last_char_position = 0
    if motion_key == 'w' or motion_key == 'e' then
      -- `w`, `e` はカーソルが非空白文字の末尾にあれば処理を分岐する必要があるので、
      -- 非空白文字の末尾の位置を取得しておく
      last_char_position = line_info.last_char_position
    end

    motion.execute_motion({
      motion = motion_key,
      parsed_text = line_info.parsed_text,
      cursor_position = cursor_position,
      under_cursor_char = under_cursor_char,
      first_char_position = line_info.first_char_position,
      last_char_position = last_char_position
    })

    count1 = count1 - 1
  end
end

return M
