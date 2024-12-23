" Title:        extend_word_motion
" Description:  A plugin to extend word_motion for japanese.
" Last Change:  8 November 2021
" Maintainer:   s-show <https://github.com/s-show>

" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_extend_word_motion")
    finish
endif
let g:loaded_extend_word_motion = 1
