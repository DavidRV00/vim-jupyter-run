" Editing like a notebook and running in a REPL
function! StartAndConfigREPL()
  let g:jupyterrun_buf_configured[expand('%:p')] = 1

  if expand('%:e') == "r" || expand('%:e') == "R"
    " Enable clearing only after Slimux is configured
    nnoremap <buffer> <localleader>c :call SlimuxSendCode("system(\"clear\")\n")<cr>

    " Starting radian in this special way makes it so that unprocessed input does not get
    " visibly printed before earlier outputs have been printed.
    call SlimuxSendCode("stty -echo; radian; stty echo;\n\n")

    return
  endif

  " Enable clearing only after Slimux is configured
  nnoremap <buffer> <localleader>c :call SlimuxSendCode("clear\n")<cr>

  " Starting ipython in this special way fixes two problems:
  " * Unprocessed input does not get visibly printed before earlier outputs have been printed.
  " * Ipython's auto-indent doesn't mess up the indentation in our file.
  call SlimuxSendCode("stty -echo; ipython --no-autoindent; stty echo;\n\n")
endfunction
command! StartAndConfigREPL call StartAndConfigREPL()


function! EndOfCellOrEnd()
  if search("^# In\\[.*\\]", 'W') == 0
    normal! GG
    return 0
  endif
  normal! k
  return 1
endfunction
command! EndOfCellOrEnd call EndOfCellOrEnd()


function! NextCellOrEnd()
  if EndOfCellOrEnd() == 0
    return 0
  endif
  normal! j
  return 1
endfunction
command! NextCellOrEnd call NextCellOrEnd()


function! PrevCellOrFirst()
  call search("^# In\\[.*\\]", "bcW")
  call search("^# In\\[.*\\]", "bW")
endfunction
command! PrevCellOrFirst call PrevCellOrFirst()


function! RunCell()
  if g:jupyterrun_buf_configured[expand('%:p')] == 0
    call StartAndConfigREPL()
  endif
  if search("^# In\\[.*\\]", "bcW") == 0
    return NextCellOrEnd()
  endif
  normal! j
  normal! V
  call EndOfCellOrEnd()
  execute "normal! \<esc>"
  SlimuxREPLSendSelection
  return NextCellOrEnd()
endfunction
command! RunCell call RunCell()


function! InsertCellAfter()
  call EndOfCellOrEnd()
  execute "normal! o# In[ ]:\<cr>\<cr>\<cr>\<cr>\<cr>"
  normal! kk
endfunction
command! InsertCellAfter call InsertCellAfter()


function! RunCellAndAppend()
  if EndOfCellOrEnd() == 0
    call InsertCellAfter()
    call PrevCellOrFirst()
  endif
  call RunCell()
endfunction
command! RunCellAndAppend call RunCellAndAppend()


function! RunCellAndBelow()
  while RunCell() != 0
  endwhile
endfunction
command! RunCellAndBelow call RunCellAndBelow()


function! RunAllCells()
  normal! gg
  call NextCellOrEnd()
  call RunCellAndBelow()
endfunction
command! RunAllCells call RunAllCells()


" Syncing with notebook file
function! JupyterSync()
  " Don't want to use regular old 'silent execute...' here because it still
  " clears the screen and looks bad.
  Dispatch! jupytersync %:p
endfunction
command! JupyterSync call JupyterSync()


function! AutoJupyterSyncOn()
  augroup autojupytersyncon
    autocmd BufWritePre <buffer> call JupyterSync()
  augroup END
endfunction
command! AutoJupyterSyncOn call AutoJupyterSyncOn()


function! AutoJupyterSyncOff()
  autocmd! autojupytersyncon
endfunction
command! AutoJupyterSyncOff call AutoJupyterSyncOff()


" Syncing with Rmd file
function! RmdSync()
  " Don't want to use regular old 'silent execute...' here because it still
  " clears the screen and looks bad.
  Dispatch! make_nb %:p --rmd
endfunction
command! RmdSync call RmdSync()


function! AutoRmdSyncOn()
  augroup autormdsyncon
    autocmd BufWritePre <buffer> call RmdSync()
  augroup END
endfunction
command! AutoRmdSyncOn call AutoRmdSyncOn()


function! AutoRmdSyncOff()
  autocmd! autormdsyncon
endfunction
command! AutoRmdSyncOff call AutoRmdSyncOff()


" Mappings, settings...
function! SetJupyterRunSettings()
  nnoremap <buffer> <localleader><Enter> :RunCellAndAppend<cr>
  nnoremap <buffer> <localleader>b<Enter> :RunCellAndBelow<cr>
  nnoremap <buffer> <localleader>a<Enter> :RunAllCells<cr>

  " We need to use a global map instead of a buffer-local variable because
  " when the file gets rewritten during notebook sync, the buffer-local
  " variables get cleared.
  if !exists("g:jupyterrun_buf_configured")
    let g:jupyterrun_buf_configured = {}
  endif
  if !exists("g:jupyterrun_buf_configured[expand('%:p')]")
    let g:jupyterrun_buf_configured[expand('%:p')] = 0
  endif
endfunction


augroup jupyterrun
  autocmd FileType python,r call SetJupyterRunSettings()
augroup END
