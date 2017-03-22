;; set a high threshold for garbage collection for init,
;; and then scale back down to a still-much-higher-than-default value afterwards
(setq gc-cons-threshold 100000000)
(add-hook 'after-init-hook (lambda () (setq gc-cons-threshold 800000)))

;; disable the menu, tool, and scroll bars
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; behavior settings
(setq make-backup-files nil)       ; stop creating backup~ files
(setq auto-save-default nil)       ; stop creating #autosave# files
(show-paren-mode 1)                ; visually indicate where the matching parentheses (or other character pair) is
(setq default-tab-width 2)         ; set the default tab width to n spaces
(setq show-trailing-whitespace t)  ; highlight trailing whitespace
(setq require-final-newline t)     ; add a final newline to files without them on write and save
(setq echo-keystrokes 0.5)         ; shorten the time emacs displays part of an entered keybind
(fset 'yes-or-no-p 'y-or-n-p)      ; prompt for 'y' or 'n' instead of 'yes' or 'no'
(setq ring-bell-function #'ignore) ; disable the bell
(setq vc-follow-symlinks t)        ; don't prompt when editing files via symlinks

;; ModeLine configuration
(setq display-time-day-and-date t) ; display the day and date along with the time
(display-time)                     ; display the time
(column-number-mode 1)             ; display the current column number

;; frame dimensions and position
(setq initial-frame-alist '((width . 250) (height . 65)))
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
 '(package-selected-packages (quote (multi-term helm evil use-package))))
(custom-set-faces)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)
(use-package evil)
(use-package helm)
(use-package multi-term)
(use-package powerline)
(use-package evil-leader)
(use-package key-chord)
(use-package smartparens)
(use-package projectile)
(use-package helm-projectile)
;; themes
(use-package distinguished-theme)
(use-package ujelly-theme)

;; utf-8 everywhere
(prefer-coding-system 'utf-8)
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)

;; color theme
;(load-theme 'distinguished t)
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
; evil: have TAB work as it does with Vi
(define-key evil-insert-state-map (kbd "TAB") 'tab-to-tab-stop)
; use whitespace (soft tabs) instead of tabs
'(indent-tabs-mode nil)
; set a default tab width of 2
'(tab-width 2)
; set a default indent amount of 2
'(tab-stop-list (number-sequence 2 120 2))
; evil: indent 2 spaces when shifting
'(evil-shift-width 2)

;; use evil's (vi's) search behavior for persistent highlights, repeating ssearches, etc.
(evil-select-search-module 'evil-search-module 'evil-search)
;; define a keymap for the removal of search highlighting
(evil-leader/set-key "/" 'evil-ex-nohighlight)

;; swap ';' and ':'
(define-key evil-normal-state-map (kbd ";") 'evil-ex)
(define-key evil-normal-state-map (kbd ":") 'evil-repeat-find-char)

;; key-chord
(setq key-chord-two-keys-delay 0.25)
;; jk to escape to the normal state in evil (in addition to Esc, and C-[)
(key-chord-define evil-insert-state-map "jk" 'evil-normal-state)
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

;; projectile
(projectile-global-mode)
(setq projectile-completion-system 'helm)
(helm-projectile-on)
(evil-leader/set-key "p" `helm-projectile-switch-project)
(evil-leader/set-key "f" `helm-projectile-find-file)
(evil-leader/set-key "b" `helm-projectile-switch-to-buffer)

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

;; ctrl-+ and ctrl-- for text scale increase/decrease
(global-set-key (kbd "C-+") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)

;; multi-term
(setq multi-term-program "/usr/local/bin/zsh")
(evil-leader/set-key "m" 'multi-term)
(setq multi-term-switch-after-close nil) ; do not switch to the next term on close

(add-hook 'term-mode-hook
          (lambda ()
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

;; TODO: any way to use any of this in 25.1+?
; unicode emoji support
; (deliberately removed from macOS builds since 25.1)
; http://www.lunaryorn.com/posts/bye-bye-emojis-emacs-hates-macos.html
; (set-fontset-font t 'symbol (font-spec :family "Apple Color Emoji") nil 'prepend)
; (set-fontset-font t 'unicode "Apple Color Emoji" nil 'prepend)
;
; (defun use-emoji-font ()
;   (set-fontset-font t 'unicode "Apple Color Emoji" nil 'prepend))
; (add-hook 'term-mode-hook 'use-emoji-font)

;; TODO: which of these patterns is still needed?
; http://emacswiki.org/emacs/RubyMode
; (add-to-list 'auto-mode-alist
;               '("\\.\\(?:gemspec\\|irbrc\\|gemrc\\|rake\\|rb\\|ru\\|thor\\)\\'" . ruby-mode))
; (add-to-list 'auto-mode-alist
;               '("\\(Capfile\\|Gemfile\\(?:\\.[a-zA-Z0-9._-]+\\)?\\|[rR]akefile\\)\\'" . ruby-mode))

;; TODO: flycheck / rubocop
; (setq flycheck-ruby-rubocop-executable "~/bin/rubocop")
; (eval-after-load 'flycheck
;                  '(progn
;                     (set-face-attribute 'flycheck-error nil
;                                         :foreground "white"
;                                         :background "red")
;                     (set-face-attribute 'flycheck-warning nil
;                                         :foreground "black"
;                                         :background "yellow")))
; (add-hook 'ruby-mode-hook
;           '(lambda ()
;              (setq flycheck-checker 'ruby-rubocop)
;              (flycheck-mode 1)))

;; TODO: neotree
; (evil-leader/set-key "n" 'neotree-toggle)
; (add-to-list 'evil-emacs-state-modes 'neotree-mode)
; (setq neo-show-hidden-files 1)

;; TODO: magit

;; TODO: dired (built-in)
; (evil-leader/set-key "d" 'dired)

;; TODO: ctags

;; TODO rulers
; (require-package 'fill-column-indicator)
; (require 'fill-column-indicator)
; (setq fci-rule-width 1)
; (setq fci-rule-column 120)
; (setq fci-rule-character-color "darkgrey")
; (setq fci-rule-character ?\u2758) ; light vertical bar
; (define-globalized-minor-mode global-fci-mode fci-mode (lambda () (fci-mode 1)))
; (global-fci-mode 1)

;; TODO: helm

;; TODO: rg

;; TODO: evil-surround

;; TODO: evil-matchit

;; TODO: evil-commentary

;; TODO: synchronize all multi-term windows, ala tmux sync

;; TODO: powerline themes

;; TODO: use frames to replace tmux windows
; * create new frame with same dimensions as the original
; * cycle between frames (Frame Move)
; https://www.emacswiki.org/emacs/FrameMove

;; TODO: better term appearance

;; TODO: fix vi mode in zsh in term, or conditionally switch to emacs mode within emacs term
