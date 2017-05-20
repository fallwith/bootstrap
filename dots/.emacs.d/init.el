;; set a high threshold for garbage collection for init,
;; and then scale back down to a still-much-higher-than-default value afterwards
(setq gc-cons-threshold 100000000)
(add-hook 'after-init-hook (lambda () (setq gc-cons-threshold 800000)))

;; disable the menu, tool, and scroll bars
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
;(setq inhibit-startup-screen t)

;; behavior settings
(setq make-backup-files nil)               ; stop creating backup~ files
(setq auto-save-default nil)               ; stop creating #autosave# files
(show-paren-mode 1)                        ; indicate where the matching parentheses (or other character) is
(setq default-tab-width 2)                 ; set the default tab width to n spaces
;; (setq-default show-trailing-whitespace t)  ; highlight trailing whitespace
(setq require-final-newline t)             ; add a final newline to files without them on write and save
(setq echo-keystrokes 0.5)                 ; shorten the time emacs displays part of an entered keybind
(fset 'yes-or-no-p 'y-or-n-p)              ; prompt for 'y' or 'n' instead of 'yes' or 'no'
(setq ring-bell-function #'ignore)         ; disable the bell
(setq vc-follow-symlinks t)                ; don't prompt when editing files via symlinks

;; set the path for executables (such as ImageMagick's "convert" used for dired image thumbnails
(setq exec-path (append exec-path '("/usr/local/bin")))


;; ModeLine configuration
(setq display-time-day-and-date t) ; display the day and date along with the time
(display-time)                     ; display the time
(column-number-mode 1)             ; display the current column number

;; frame dimensions and position
(setq initial-frame-alist '((width . 250) (height . 65)))
(add-to-list 'default-frame-alist '(width . 250))
(add-to-list 'default-frame-alist '(height . 65))
(set-frame-position (selected-frame) 250 250)

;; transparency
(set-frame-parameter (selected-frame) 'alpha '(85 . 50))
(add-to-list 'default-frame-alist '(alpha . (85 . 50)))

;; fonts
;; initial-frame = first window
(add-to-list 'initial-frame-alist '(font . "DejaVu Sans Mono-11"))
;; default-frame = subsequent windows
(add-to-list 'default-frame-alist '(font . "DejaVu Sans Mono-11"))

;; packages
(eval-and-compile
  (require 'package)
  (setq package-archives '(("melpa" . "https://melpa.org/packages/")
                           ("gnu" . "https://elpa.gnu.org/packages/")
                           ("org" . "https://orgmode.org/elpa/")))
  (setq package-enable-at-startup nil)
  (package-initialize))

(custom-set-variables
 '(package-selected-packages (quote (multi-term evil use-package))))
(custom-set-faces)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)
(use-package chruby)
(use-package evil)
(use-package evil-commentary)
(use-package evil-leader)
(use-package evil-surround)
(use-package flycheck)
(use-package framemove)
(use-package counsel-projectile)
(use-package hydra)
(use-package ivy)
(use-package counsel)
(use-package swiper)
(use-package key-chord)
(use-package multi-term)
(use-package powerline)
(use-package projectile)
(use-package smartparens)
;; themes
;(use-package distinguished-theme)
;(use-package monokai-theme)
(use-package ujelly-theme)

;; utf-8
(prefer-coding-system 'utf-8)
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)

;; color theme
;(load-theme 'distinguished t)
;(load-theme 'monokai t)
(load-theme 'ujelly t)

;; powerline
(powerline-center-evil-theme)

;; evil-leader
(evil-leader/set-leader ",")
(global-evil-leader-mode) ;; this should come before evil is loaded

;; evil
(evil-mode t)

;; j and k move the visual line in long wrapped lines
(define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
(define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line)

;; tabs
(setq-default
    ; use whitespace (soft tabs) instead of tabs
    indent-tabs-mode nil
    ; set a default tab width of 2
    tab-width 2
    ; set a default indent amount of 2
    tab-stop-list (quote (2 4))
)
; evil: have TAB work as it does with Vi
(define-key evil-insert-state-map (kbd "TAB") 'tab-to-tab-stop)
; evil: indent 2 spaces when shifting
'(evil-shift-width 2)

;; use evil's (vi's) search behavior for persistent highlights, repeating ssearches, etc.
; (evil-select-search-module 'evil-search-module 'evil-search)
;; define a keymap for the removal of search highlighting
; (evil-leader/set-key "/" 'evil-ex-nohighlight)
;
;; OR
;
; use default behavior - / to search and then n/N to repeat


;; evil visual mode - immediately reselect after indent/outdent
; from: https://github.com/djoyner/dotfiles/blob/888a1f0d5cdd9a15a0bfe93a96cdd1fc5d7f2d57/emacs/lisp/evil-config.el#L36-L40
(defun evil-shift-left-visual ()
  (interactive)
  (evil-shift-left (region-beginning) (region-end))
  (evil-normal-state)
  (evil-visual-restore))
(defun evil-shift-right-visual ()
  (interactive)
  (evil-shift-right (region-beginning) (region-end))
  (evil-normal-state)
  (evil-visual-restore))
(define-key evil-visual-state-map (kbd ">") 'evil-shift-right-visual)
(define-key evil-visual-state-map (kbd "<") 'evil-shift-left-visual)
(define-key evil-visual-state-map [tab] 'evil-shift-right-visual)
(define-key evil-visual-state-map [S-tab] 'evil-shift-left-visual)

;; swap ';' and ':'
(define-key evil-normal-state-map (kbd ";") 'evil-ex)
(define-key evil-normal-state-map (kbd ":") 'evil-repeat-find-char)

;; key-chord
(setq key-chord-two-keys-delay 0.25)
;; jk to escape to the normal state in evil (in addition to Esc, and C-[)
(key-chord-define evil-insert-state-map "jk" 'evil-normal-state)
(key-chord-define evil-visual-state-map "jk" 'evil-normal-state)
(key-chord-mode 1)

;; splits
;; use an empty buffer for new splits
;; http://www.alandmoore.com/blog/2013/05/01/better-window-splitting-in-emacs/
;; http://www.gnu.org/software/emacs/manual/html_node/elisp/Buffer-Names.html
(defun vsplit-last-buffer ()
  (interactive)
  (split-window-vertically)
  (other-window 1 nil)
  (setq bname (generate-new-buffer-name "scratch"))
  (get-buffer-create bname)
  (switch-to-buffer bname)
  (balance-windows)
)
(defun hsplit-last-buffer ()
  (interactive)
  (split-window-horizontally)
  (other-window 1 nil)
  (setq bname (generate-new-buffer-name "scratch"))
  (get-buffer-create bname)
  (switch-to-buffer bname)
  (balance-windows)
)
(evil-leader/set-key "v" 'hsplit-last-buffer
                     "h" 'vsplit-last-buffer)

;; smartparens
(require 'smartparens-config)
(require 'smartparens-ruby)
(add-hook 'ruby-mode-hook #'smartparens-mode)

;; server
; start the server if it is not already running
(require 'server)
(unless (server-running-p)
    (server-start))

;; ivy
(setq-default counsel-ag-base-command "/usr/local/bin/ag --vimgrep --nocolor --nogroup %s")
(setq-default counsel-rg-base-command "/usr/local/bin/rg -i --no-heading --line-number %s")
(ivy-mode 1)
(setq ivy-use-virtual-buffers t)
(setq enable-recursive-minibuffers t)
(global-set-key "\C-s" 'swiper)
(global-set-key (kbd "C-c C-r") 'ivy-resume)
(global-set-key (kbd "M-x") 'counsel-M-x)
(global-set-key (kbd "C-x C-f") 'counsel-find-file)
(global-set-key (kbd "C-c g") 'counsel-git)
(global-set-key (kbd "C-c j") 'counsel-git-grep)
(global-set-key (kbd "C-c k") 'counsel-rg)
(global-set-key (kbd "C-x l") 'counsel-locate)
(define-key read-expression-map (kbd "C-r") 'counsel-expression-history)

;; projectile
(projectile-global-mode)
(setq projectile-completion-system 'ivy)
(counsel-projectile-on)
(evil-leader/set-key "p" `counsel-projectile-switch-project)
(evil-leader/set-key "f" `counsel-projectile-find-file)
(evil-leader/set-key "b" `counsel-projectile-switch-to-buffer)


;; don't allow underscores to behave as word boundaries
;; helps with fuzzy finding of filenames with underscores
;; (modify-syntax-entry ?_ "w" text-mode-syntax-table)

;; windows
; enable windmove's default bindings (shift + left,right,down,up) to move between windows
; (windmove-default-keybindings)
; alternatively, map other keys to windmove-left/right/up/down
(global-unset-key (kbd "M-h"))
(global-unset-key (kbd "M-j"))
(global-unset-key (kbd "M-k"))
(global-unset-key (kbd "M-l"))
(global-set-key (kbd "M-h") 'windmove-left)
(global-set-key (kbd "M-j") 'windmove-down)
(global-set-key (kbd "M-k") 'windmove-up)
(global-set-key (kbd "M-l") 'windmove-right)
; window resizing
(global-unset-key (kbd "M-H"))
(global-unset-key (kbd "M-J"))
(global-unset-key (kbd "M-K"))
(global-unset-key (kbd "M-L"))
(global-set-key (kbd "M-H") 'shrink-window-horizontally)
(global-set-key (kbd "M-L") 'enlarge-window-horizontally)
(global-set-key (kbd "M-J") 'shrink-window)
(global-set-key (kbd "M-K") 'enlarge-window)

;; frames
(setq framemove-hook-into-windmove t)
(evil-leader/set-key "n" 'make-frame-command)  ; new frame

;; ctrl-+ and ctrl-- for text scale increase/decrease
(global-set-key (kbd "C-+") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)

;; image-mode
(evil-set-initial-state 'image-mode 'emacs)
(evil-set-initial-state 'image-dired-thumbnail-mode 'emacs)
(evil-set-initial-state 'image-dired-display-image-mode 'emacs)
(evil-leader/set-key "i" 'image-dired)

;; dired
(evil-leader/set-key "d" 'dired)

;; map cmd-. to ctrl-c, macOS style
(define-key key-translation-map (kbd "s-.") (kbd "C-c"))

; blackbox
(evil-set-initial-state 'blackbox-mode 'emacs)  ; disable evil for blackbox

;; prog-mode
(add-hook 'prog-mode-hook
          (lambda()
            (setq show-trailing-whitespace 1)))


;; multi-term
(evil-set-initial-state 'term-mode 'emacs)  ; disable evil for term-mode
(setq multi-term-program "/usr/local/bin/zsh")
(evil-leader/set-key "m" 'multi-term)
(setq multi-term-switch-after-close nil) ; do not switch to the next term on close

(add-hook 'term-mode-hook
          (lambda ()
            ;; (setq show-trailing-whitespace nil)
            ; extra term mode key mappings for normal shell key behavior
            (add-to-list 'term-bind-key-alist '("C-a" . move-beginning-of-line))
            (add-to-list 'term-bind-key-alist '("C-e" . move-end-of-line))
            (add-to-list 'term-bind-key-alist '("C-k" . kill-line))
            (add-to-list 'term-bind-key-alist '("C-d" . delete-char))
            (add-to-list 'term-bind-key-alist '("C-b" . backward-char))
            (add-to-list 'term-bind-key-alist '("C-f" . forward-char))
            (setq term-bind-key-alist (remove* '"C-r" term-bind-key-alist :test 'equal :key 'car)) ; unmap C-r
            (add-to-list 'term-bind-key-alist '("C-r" . term-send-reverse-search-history))
            ; macOS paste
            (add-to-list 'term-bind-key-alist '("s-v" . term-paste))
            ; scroll buffer
            (setq term-buffer-maximum-size 10240) ; default 2048, 0 for unlimited
            ; windmove
            (add-to-list 'term-unbind-key-list "M-h")
            (add-to-list 'term-unbind-key-list "M-j")
            (add-to-list 'term-unbind-key-list "M-k")
            (add-to-list 'term-unbind-key-list "M-l")
            (add-to-list 'term-bind-key-alist '("M-h" . windmove-left))
            (add-to-list 'term-bind-key-alist '("M-j" . windmove-down))
            (add-to-list 'term-bind-key-alist '("M-k" . windmove-up))
            (add-to-list 'term-bind-key-alist '("M-l" . windmove-right))
            ; window resizing
            (add-to-list 'term-unbind-key-list "M-H")
            (add-to-list 'term-unbind-key-list "M-J")
            (add-to-list 'term-unbind-key-list "M-K")
            (add-to-list 'term-unbind-key-list "M-L")
            (add-to-list 'term-bind-key-alist '("M-H" . shrink-window-horizontally))
            (add-to-list 'term-bind-key-alist '("M-J" . enlarge-window-horizontally))
            (add-to-list 'term-bind-key-alist '("M-K" . shrink-window))
            (add-to-list 'term-bind-key-alist '("M-L" . enlarge-window))))

;; evil-commentary
(add-hook 'prog-mode-hook 'evil-commentary-mode)

;; evil-surround
(add-hook 'prog-mode-hook 'evil-surround-mode)

;; ruby
(setq ruby-indent-level 2)
(chruby "ruby-2.4.1")
(setq flycheck-ruby-executable "~/bin/ruby")
(setq flycheck-ruby-rubocop-executable "~/bin/rubocop")
;; define additional patterns for files to be consider Ruby based
(add-to-list 'auto-mode-alist
             '("\\.?Brewfile" . ruby-mode))
(add-to-list 'auto-mode-alist
              '("\\.\\(?:irbrc\\|gemrc\\|pryrc\\)" . ruby-mode))
(add-hook 'ruby-mode-hook
          '(lambda ()
             ; (setq evil-shift-width ruby-indent-level)
             (setq flycheck-checker 'ruby-rubocop)
             ; (set-face-attribute 'flycheck-error nil
             ;                     :foreground "white"
             ;                     :background "red")
             ; (set-face-attribute 'flycheck-warning nil
             ;                     :foreground "black"
             ;                     :background "yellow")
             ; treat snake case words as one single word
             (global-superword-mode 1)
             ; enable syntax checking / linting
             (flycheck-mode 1)))

;; two space indent level for evil mode for all programming languages
(add-hook 'prog-mode-hook
          '(lambda ()
             (setq evil-shift-width 2)))

;; style long lines to indicate which columns are out of bounds
; http://emacsredux.com/blog/2013/05/31/highlight-lines-that-exceed-a-certain-length-limit/
(require 'whitespace)
(setq whitespace-line-column 120)
(setq whitespace-style '(face lines-tail))
(add-hook 'prog-mode-hook 'whitespace-mode)

;; switch to iTerm2
(defun focus-iterm ()
  (interactive)
  (shell-command "open -a iTerm"))
(evil-leader/set-key "t" 'focus-iterm)


(evil-leader/set-key "z" 'zone)

;; cookie / fortune paths
(setq fortune-dir "/usr/local/opt/fortune/share/games/fortunes")
(setq fortune-file "/usr/local/opt/fortune/share/games/fortunes/fortunes")
(setq cookie-dir "/usr/local/opt/fortune/share/games/fortunes")
(setq cookie-file "/usr/local/opt/fortune/share/games/fortunes/fortunes")

;; expose fun and games via a hydra menu
;; not listed: mpuz, landmark (not available?), 5x5
(defhydra amusements (nil nil :foreign-keys nil :hint nil :exit t)
  "
Amusements
----------
_a_ animate_bday
_b_ bubbles
_c_ cookie
_d_ doctor
_g_ gomoku
_h_ hanoi
_k_ snake
_l_ life
_n_ dunnet
_o_ pong
_p_ dissassociated_press
_s_ solitaire
_t_ tetris
_x_ blackbox
_y_ butterfly
_z_ zone

_q_ quit"
  ("q" nil)
  ("a" animate-birthday-present)
  ("b" bubbles)
  ("c" cookie)
  ("d" doctor)
  ("g" gomoku)
  ("h" hanoi)
  ("k" snake)
  ("l" life)
  ("n" dunnet)
  ("o" pong)
  ("p", dissassociated_press)
  ("s" solitaire)
  ("t" tetris)
  ("x" blackbox)
  ("y" butterfly)
  ("z" zone))
(evil-leader/set-key "a" 'amusements/body)

;; org
; (evil-leader/set-key "o" (lambda () (interactive) (find-file "~/.emacs/organizer.org")))
; (setq org-default-notes-file "~/.emacs/organizer.org")


;; TODO: any way to use any of this in 25.1+?
; unicode emoji support
; (deliberately removed from macOS builds since 25.1)
; (set-fontset-font t 'symbol (font-spec :family "Apple Color Emoji") nil 'prepend)
; (set-fontset-font t 'unicode "Apple Color Emoji" nil 'prepend)
;
; (defun use-emoji-font ()
;   (set-fontset-font t 'unicode "Apple Color Emoji" nil 'prepend))
; (add-hook 'term-mode-hook 'use-emoji-font)

;; TODO: underscores disrupt ivy's fuzzy finding

;; TODO: tramp with tunneling

;; TODO: magit
; then change EDITOR to emacsclient

;; TODO: ctags

;; TODO: ivy-avy - needed?

;; TODO: counsel-projectile-find-file trips on underscores
;; filename = "this_is_a_test_filename"
;; input of "thisi" results in 0 matches

;; TODO: projectile
; whitelist/blacklist certain patterns (ignore spec cassettes)
; how to navigate lists without the arrow keys?
; add to the projects list

;; TODO: evil-matchit - needed?
; use % to jump from the one logical section to another (from if to else to end)

;; TODO: synchronize all multi-term windows, ala tmux sync

;; TODO: powerline themes
; curves no longer work?
; ; (setq powerline-arrow-shape 'slant)   ; not working?
; milky's version is the one that comes from elpa? https://github.com/milkypostman/powerline

;; TODO: ewww

;; TODO: mu4e (and el feed)
;; http://irreal.org/blog/?p=6115

;; TODO: multi-term
; toggle between terminal and evil mode (for scrolling up, selecting text)

;; TODO: multi-term
; how to output more than 8 colors
; how to set term specific faces (term-color-cyan)

; (defface term-color-blue '((t (:foreground "#45B7FE" ))) "")
; (defface term-color-red '((t (:foreground "#ff3333" ))) "")
; (defface term-color-yellow '((t (:foreground "#FFFF00" ))) "")


; ; term colors
; (defface term-color-black
;   '((t (:foreground "#3f3f3f" :background "#272822")))
;   "Unhelpful docstring.")
; (defface term-color-red
;   '((t (:foreground "#cc9393" :background "#272822")))
;   "Unhelpful docstring.")
; (defface term-color-green
;   '((t (:foreground "#7f9f7f" :background "#272822")))
;   "Unhelpful docstring.")
; (defface term-color-yellow
;   '((t (:foreground "#f0dfaf" :background "#272822")))
;   "Unhelpful docstring.")
; (defface term-color-blue
;   '((t (:foreground "#6d85ba" :background "#272822")))
;   "Unhelpful docstring.")
; (defface term-color-magenta
;   '((t (:foreground "#dc8cc3" :background "#272822")))
;   "Unhelpful docstring.")
; (defface term-color-cyan
;   '((t (:foreground "#93e0e3" :background "#272822")))
;   "Unhelpful docstring.")
; (defface term-color-white
;   '((t (:foreground "#dcdccc" :background "#272822")))
;   "Unhelpful docstring.")
; '(term-default-fg-color ((t (:inherit term-color-white))))
; '(term-default-bg-color ((t (:inherit term-color-black))))
