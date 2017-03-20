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
(use-package distinguished-theme)
(use-package powerline)
(use-package evil-leader)
(use-package key-chord)
(use-package smartparens)

;; color theme
(load-theme 'distinguished t)

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

;; multi-term
(setq multi-term-program "/usr/local/bin/zsh")

;; smartparens
(require 'smartparens-config)
(require 'smartparens-ruby)
(add-hook 'ruby-mode-hook #'smartparens-mode)






;; TODO: any way to use any of this in 25.1+?
; unicode emoji support
; (deliberately removed from macOS builds since 25.1)
; http://www.lunaryorn.com/posts/bye-bye-emojis-emacs-hates-macos.html
; (set-fontset-font t 'symbol (font-spec :family "Apple Color Emoji") nil 'prepend)
; (set-fontset-font t 'unicode "Apple Color Emoji" nil 'prepend)

;; TODO: needed for multi-term?
; use emacs' own terminfo instead of ~/.terminfo
; (setq system-uses-terminfo nil)

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

;; TODO: projectile / helm-projectile
; (projectile-global-mode)
; (setq projectile-completion-system 'helm)
; (helm-projectile-on)
; (evil-leader/set-key "q" `helm-projectile-find-file)
; (evil-leader/set-key "b" `helm-projectile-switch-to-buffer)

;; TODO: rg

;; TODO: evil-surround

;; TODO: evil-matchit

;; TODO: evil-commentary
