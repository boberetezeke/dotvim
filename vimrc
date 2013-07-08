set tabstop=2
set shiftwidth=2
set softtabstop=2
set columns=80
set lines=24
set guifont=Courier:h18
set expandtab
set smarttab
let g:rubycomplete_rails = 1
syntax enable
"set statusline=%F%m%r%h%w[%L][%{&ff}]%y[%p%%][%04l,%04v]
set laststatus=2
set number " turn on line numbers
set numberwidth=4 " We are good up to 99999 lines
set ruler
let g:backup_directory="./.backups"
let g:backup_purge=20
set incsearch   "incremental search on 
set hlsearch    "highlight search matches


command! Cuke call s:RunShellCommand('bundle exec cucumber ' .expand('%:p'))
command! Zcuke call s:RunShellCommand('zeus cucumber ' .expand('%:p'))
command! CukeL call s:RunShellCommand('cucumber ' .expand('%:p').':'.line("."))
command! ZcukeL call s:RunShellCommand('zeus cucumber ' .expand('%:p').':'.line("."))
command! Spec call s:RunShellCommand('bundle exec rspec ' .expand('%:p'))
command! SpecL call s:RunShellCommand('rspec ' .expand('%p').':'.line("."))
command! Zspec call s:RunShellCommand('zeus rspec ' .expand('%:p'))
command! ZspecL call s:RunShellCommand('zeus rspec ' .expand('%p').':'.line("."))
command! Ctag call s:RunShellCommand('pickler --lookup ' .expand('%p') . ' ' . line("."))


set grepprg=rgrep
set grepformat=%f:%l:%m

let Tlist_Auto_Open=0 " let the tag list open automagically
let Tlist_Compact_Format = 1 " show small menu
let Tlist_Ctags_Cmd = 'ctags' " location of ctags
let Tlist_Enable_Fold_Column = 0 " do show folding tree
let Tlist_Exist_OnlyWindow = 1 " if you are the last, kill
                               " yourself
let Tlist_File_Fold_Auto_Close = 0 " fold closed other trees
let Tlist_Sort_Type = "name" " order by
let Tlist_Use_Right_Window = 1 " split to the right side
                               " of the screen
let Tlist_WinWidth = 40 " 40 cols wide, so i can (almost always)
                        " read my functions

" see for more info on this: http://vim.wikia.com/wiki/Maximize_window_and_return_to_previous_split_structure
nnoremap <C-W>O :call MaximizeToggle ()<CR>
nnoremap <C-W>o :call MaximizeToggle ()<CR>
nnoremap <C-W><C-O> :call MaximizeToggle ()<CR>

map <C-Tab> :tabn<CR>
map <C-S-Tab> :tabp<CR>
map <C-P> :cp<CR>
map <C-N> :cn<CR>
map <C-T> :tabnew<CR>

function! MaximizeToggle()
  if exists("s:maximize_session")
    exec "source " . s:maximize_session
    call delete(s:maximize_session)
    unlet s:maximize_session
    let &hidden=s:maximize_hidden_save
    unlet s:maximize_hidden_save
  else
    let s:maximize_hidden_save = &hidden
    let s:maximize_session = tempname()
    set hidden
    exec "mksession! " . s:maximize_session
    only
  endif
endfunction

ruby << EOF
class TestHandler
  def self.instance
    if !@instance
      @instance = self.new
    end
    @instance
  end

  attr_reader :runner

  def run(filename, line_number=nil)
    @runner = TestRunner.new(filename, line_number)
    @runner.run(switch_to_window("test_output"))
  end

  def rerun_last_test
    if @runner
      @runner.run(switch_to_window("test_output"))
    else
      puts "no test to rerun"
    end
  end

  def switch_to_window(name)
    VIM::evaluate('SwitchToWindow("' + name + '")').to_i == 1
  end
end

class TestRunner
  def initialize(filename, line_number=nil)
    @filename = filename
    @line_number = line_number

    puts "filename: '#{@filename}'"
    if line_number
      puts "line_number #{line_number}"
      @line_number_option = ":#{line_number}"
    else
      puts "whole file"
      @line_number_options = ""
    end

    case filename
    when /feature$/
      @command = "cucumber"
    when /spec\.rb$/
      @command = "rspec"
    else
      @command = "unknown"
    end

    @use_zeus = file_found("zeus.json")
    @zeus_command = @use_zeus ? "zeus" : ""
  end

  def run(reuse_window)
    cmd = "#{@zeus_command} #{@command} #{@filename}#{@line_number_option}"
    puts "running: '#{cmd}'"

    if reuse_window then
      VIM::command("setlocal modifiable")
      VIM::command("g/.*/d")
      VIM::command("execute '$read !'. '#{cmd}'")
      VIM::command("setlocal nomodifiable")
    else
      VIM::command("botright new")
      VIM::command("setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap")
      VIM::command("execute '$read !'. '#{cmd}'")
      VIM::command("setlocal nomodifiable")
      VIM::command("file test_output")
      VIM::command("1")
    end
  end

  def file_found(filename)
    found = true
    begin
      File.open(filename) {}
    rescue
      found = false
    end
    found
  end

end
EOF

command! Tf call s:RunTestForFile()
command! Tl call s:RunTestForLine()
command! Tr call s:ReRunTest()

map <C-t> :Tl<CR>
map <C-y> :Tf<CR>
map <C-g> :Tr<CR>

function! s:ReRunTest()
ruby << EOF
  TestHandler.instance.rerun_last_test
EOF
endfunction

function! s:RunTestForFile()
ruby << EOF
  TestHandler.instance.run(VIM::evaluate("expand('%')"))
EOF
endfunction

function! s:RunTestForLine()
ruby << EOF
  TestHandler.instance.run(
    VIM::evaluate("expand('%')"),
    VIM::evaluate("line('.')").to_i
  )
EOF
endfunction

command! Ts call SwitchToWindow("test_output")

function! SwitchToWindow(name)
  let start = winnr()
  let window_name = expand("%")
  if window_name == a:name
    echo "window found1"
    return 1
  else
    execute "normal \<C-W>w"
    let window_name = expand("%")
    while window_name != a:name && winnr() != start
      execute "normal \<C-W>w"
    endwhile
    if window_name == a:name
      echo "window found2"
      return 1
    else
      echo "window not found"
      return 0
    endif
  endif
endfunction

function! s:RunShellCommand(cmdline)
  echo a:cmdline
  let expanded_cmdline = a:cmdline
  for part in split(a:cmdline, ' ')
     if part[0] =~ '\v[%#<]'
        let expanded_part = fnameescape(expand(part))
        let expanded_cmdline = substitute(expanded_cmdline, part, expanded_part, '')
     endif
  endfor
  botright new
  "source '/Users/robertt/.vim/bundle/AnsiEsc.vim/plugin/AnsiEscPlugin.vim'
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  call setline(1, 'You entered:    ' . a:cmdline)
  call setline(2, 'Expanded Form:  ' .expanded_cmdline)
  call setline(3,substitute(getline(2),'.','=','g'))
  execute '$read !'. expanded_cmdline
  setlocal nomodifiable
  1
endfunction

"if has("autocmd")
  " Enable filetype detection
  "filetype plugin indent on
 
  " Restore cursor position
  " autocmd BufReadPost *
  "  \ if line("'\"") > 1 && line("'\"") <= line("$") |
  "  \   exe "normal! g`\"" |
  "  \ endif
"endif
"if &t_Co > 2 || has("gui_running")
  " Enable syntax highlighting
"  syntax on
"endif

" rubyf ~/.vim/ruby_boot.rb

filetype plugin indent on
execute pathogen#infect()

autocmd User fugitive
  \ if fugitive#buffer().type() =~# '^\%(tree\|blob\)$' |
  \   nnoremap <buffer> .. :edit %:h<CR> |
  \ endif
autocmd BufReadPost fugitive://* set bufhidden=delete
set statusline=%<%f\ %h%m%r%{fugitive#statusline()}%=%-14.(%l,%c%V%)\ %P
