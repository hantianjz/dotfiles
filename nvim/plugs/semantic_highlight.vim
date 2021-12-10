Plug 'jaxbot/semantic-highlight.vim'

noremap <leader>C :SemanticHighlightToggle<CR>

let g:semanticPersistCache = 1
let g:semanticUseCache = 1
let g:semanticTermColors = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]

let g:semanticEnableFileTypes = ["c", "python", "cpp", "cmake", "java", "gn", "gni", "cc", "zig"]
