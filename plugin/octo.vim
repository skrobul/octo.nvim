if exists('g:loaded_octo')
  finish
endif

function! s:command_complete(...)
  return luaeval('require("octo.commands").command_complete(_A)', a:000)
endfunction

" commands
if executable('gh')
  command! -complete=customlist,s:command_complete -nargs=* Octo lua require"octo.commands".octo(<f-args>)
  command! -range OctoAddReviewComment lua require"octo.reviews".add_review_comment(false)
  command! -range OctoAddReviewSuggestion lua require"octo.reviews".add_review_comment(true)
else
  echo 'Cannot find `gh` command.'
endif

" clear buffer undo history
function! octo#clear_history() abort
  let old_undolevels = &undolevels
  set undolevels=-1
  exe "normal a \<BS>\<Esc>"
  let &undolevels = old_undolevels
  unlet old_undolevels
endfunction

" completion
function! octo#issue_complete(findstart, base) abort
  return luaeval("require'octo.completion'.issue_complete(_A[1], _A[2])", [a:findstart, a:base])
endfunction

" autocommands
function s:configure_octo_buffer() abort
  " issue/pr/comment buffers
  if match(bufname(), "octo://.\\+/.\\+/pull/\\d\\+/file/") == -1
    setlocal omnifunc=octo#issue_complete
    setlocal nonumber norelativenumber nocursorline wrap
    setlocal foldcolumn=3
    setlocal signcolumn=yes
    setlocal fillchars=fold:⠀,foldopen:⠀,foldclose:⠀,foldsep:⠀
    setlocal foldtext=v:lua.OctoFoldText()
    setlocal foldmethod=manual
    setlocal foldenable
    setlocal foldcolumn=3
    setlocal foldlevelstart=99
    setlocal conceallevel=2
    setlocal syntax=markdown
  " file diff buffers
  else
    lua require"octo.reviews".place_comment_signs()
  end
endfunction

augroup octo_autocmds
au!
au BufEnter octo://* call s:configure_octo_buffer()
au BufReadCmd octo://* lua require'octo'.load_buffer()
au BufWriteCmd octo://* lua require'octo'.save_buffer()
au CursorHold octo://* lua require'octo.reviews'.show_comment()
au CursorHold octo://* lua require'octo'.show_summary()
augroup END

" sign definitions
sign define octo_comment text=❯ texthl=OctoNvimCommentLine linehl=OctoNvimCommentLine 
sign define octo_clean_block_start text=┌ linehl=OctoNvimEditable
sign define octo_clean_block_end text=└ linehl=OctoNvimEditable
sign define octo_dirty_block_start text=┌ texthl=OctoNvimDirty linehl=OctoNvimEditable
sign define octo_dirty_block_end text=└ texthl=OctoNvimDirty linehl=OctoNvimEditable
sign define octo_dirty_block_middle text=│ texthl=OctoNvimDirty linehl=OctoNvimEditable
sign define octo_clean_block_middle text=│ linehl=OctoNvimEditable
sign define octo_clean_line text=[ linehl=OctoNvimEditable
sign define octo_dirty_line text=[ texthl=OctoNvimDirty linehl=OctoNvimEditable

highlight default link OctoNvimDirty ErrorMsg
highlight default link OctoNvimIssueId Question
highlight default link OctoNvimIssueTitle PreProc
highlight default link OctoNvimEmpty Comment
highlight default link OctoNvimFloat NormalFloat
highlight default link OctoNvimTimelineItemHeading Comment
highlight default link OctoNvimSymbol Comment
highlight default link OctoNvimDate Comment
highlight default link OctoNvimDetailsLabel Title 
highlight default link OctoNvimDetailsValue Identifier
highlight default link OctoNvimMissingDetails Comment
highlight default link OctoNvimCommentLine Visual
highlight default link OctoNvimEditable NormalFloat
highlight default OctoNvimViewer guifg=#000000 guibg=#58A6FF
highlight default link OctoNvimBubble NormalFloat
highlight default OctoNvimBubbleGreen guifg=#ffffff guibg=#238636
highlight default OctoNvimBubbleRed guifg=#ffffff guibg=#f85149
highlight default link OctoNvimUser OctoNvimBubble
highlight default link OctoNvimUserViewer OctoNvimViewer
highlight default link OctoNvimReaction OctoNvimBubble
highlight default link OctoNvimReactionViewer OctoNvimViewer
highlight default OctoNvimPassingTest guifg=#238636
highlight default OctoNvimFailingTest guifg=#f85149
highlight default OctoNvimPullAdditions guifg=#2ea043
highlight default OctoNvimPullDeletions guifg=#da3633
highlight default OctoNvimPullModifications guifg=#58A6FF
highlight default OctoNvimStateOpen guifg=#44c150
highlight default OctoNvimStateClosed guifg=#ea4e48
highlight default OctoNvimStateMerged guifg=#ad7cfd
highlight default OctoNvimStatePending guifg=#d3c846
highlight default link OctoNvimStateApproved OctoNvimStateOpen
highlight default link OctoNvimStateChangesRequested OctoNvimStateClosed
highlight default link OctoNvimStateCommented Normal
highlight default link OctoNvimStateDismissed OctoNvimStateClosed

" folds
lua require'octo.folds'

" logged-in user
if !exists("g:octo_viewer")
  let g:octo_viewer = v:null
  lua require'octo'.check_login()
endif

" mappings
nnoremap <Plug>(OctoOpenIssueAtCursor) <cmd>lua require'octo.util'.open_issue_at_cursor()<CR>

" settings
let g:octo_date_format = get(g:, 'octo_date_format', "%Y %b %d %I:%M %p %Z")
let g:octo_default_remote = ["upstream", "origin"]
"let g:octo_qf_height = 11

let g:loaded_octo = 1
