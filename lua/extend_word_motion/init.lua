local M = {}

local pcall_result, tinysegmenter = pcall(require, "tinysegmenter")
local util = require('extend_word_motion.util')
local motion = require('extend_word_motion.motion')

M.options = {
  extend_motions = { 'w', 'b', 'e', 'ge' }
}

function M.setup(opts)
  if pcall_result == false then
    vim.notify("Not found 'tinysegment.nvim'!\nExtend_word_motion required 'tinysegmenter.nvim'.")
    return
  end

  if opts and opts.extend_motions ~= nil then
    opts.extend_motions = util.MotionValidation(opts.extend_motions)
  end
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})

  for _, motion_key in ipairs(M.options.extend_motions) do
    vim.keymap.set({ 'n', 'v', 'o' }, motion_key, '', {
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
      -- 1回目の実行とは別の行に移動しているので、再度カーソル下の行を解析する
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
