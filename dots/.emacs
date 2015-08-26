(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq make-backup-files nil) ; stop creating backup~ files
(setq auto-save-default nil) ; stop creating #autosave# files
(setq linum-format "%d ")
(show-paren-mode 1)
(setq default-tab-width 2)
(setq show-trailing-whitespace t)
(setq require-final-newline t)

;; ModeLine configuration
(setq display-time-day-and-date t)
(display-time)
(column-number-mode 1)

;;; Replicate vim's line number properties:
; http://www.reddit.com/r/vim/comments/1vllqy/what_is_emacs_evilmode_missing/
(defun linum-format-func (line)
  (let ((w (length
             (number-to-string (count-lines (point-min) (point-max))))))
    (propertize
      (format
        (if (> w 3) (concat "%" (number-to-string w) "d ")
          "%3d ") line) 'face 'linum)))
(setq linum-format 'linum-format-func)
(global-linum-mode t)

(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("org" . "http://orgmode.org/elpa/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")
                         ("melpa" . "http://melpa.milkbox.net/packages/")
                         ("melpa-stable" . "http://stable.melpa.org/packages/")))
(package-initialize)

(defun require-package (package)
  (setq-default highlight-tabs t)
  "Install given PACKAGE."
  (unless (package-installed-p package)
    (package-list-packages)
    (unless (assoc package package-archive-contents)
      (package-refresh-contents))
    (package-install package)))

(require-package 'evil)
(require 'evil)

;; use C-hjkl to move between windows (instead of having to hit C-w first)
(define-key evil-emacs-state-map "\C-h" 'windmove-left)
(define-key evil-emacs-state-map "\C-j" 'windmove-down)
(define-key evil-emacs-state-map "\C-k" 'windmove-up)
(define-key evil-emacs-state-map "\C-l" 'windmove-right)

;;(evil-mode t)
(evil-mode 1)

(require-package 'evil-surround)
(require-package 'evil-matchit)
(require-package 'evil-search-highlight-persist)
(require-package 'evil-leader)
(require-package 'evil-commentary)
(require-package 'key-chord)
; https://github.com/keith/evil-tmux-navigator
(require-package 'navigate)
; https://github.com/Lokaltog/distinguished-theme
(require-package 'distinguished-theme)

(require-package 'helm)
(require-package 'projectile)
(require-package 'helm-projectile)

(projectile-global-mode)
(setq projectile-completion-system 'helm)
(helm-projectile-on)
(evil-leader/set-key "q" `helm-projectile-find-file)
(evil-leader/set-key "b" `helm-projectile-switch-to-buffer)

(require 'navigate)

(load-theme 'distinguished t)

(global-evil-matchit-mode t)
(global-evil-surround-mode t)
(global-evil-search-highlight-persist t)
(evil-commentary-mode)

(evil-leader/set-key "/" 'evil-search-highlight-persist-remove-all)

(global-evil-leader-mode t)
(setq evil-leader/in-all-states t)

(evil-leader/set-leader ",")

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

;; j and k move the visual line in long wrapped lines
(define-key evil-normal-state-map (kbd "j") 'evil-next-visual-line)
(define-key evil-normal-state-map (kbd "k") 'evil-previous-visual-line)

;; jk to escape to the normal state
(define-key evil-insert-state-map (kbd "jk") 'evil-normal-state)

;; swap ';' and ':'
(define-key evil-normal-state-map (kbd ";") 'evil-ex)
(define-key evil-normal-state-map (kbd ":") 'evil-repeat-find-char)

(require-package 'fill-column-indicator)
(require 'fill-column-indicator)
(setq fci-rule-width 1)
(setq fci-rule-column 120)
(setq fci-rule-character-color "darkgrey")
(setq fci-rule-character ?\u2758) ; light vertical bar
(define-globalized-minor-mode global-fci-mode fci-mode (lambda () (fci-mode 1)))
(global-fci-mode 1)

; (defun rtags ()
;  (interactive)
;  ;(shell-command (format "ttags %s" (get-fullpath-current-file)))
;  (shell-command (format "ttags %s" (copy-buffer-file-name)))
; )

(require-package 'magit)

(require-package 'powerline)
(require 'powerline)
(powerline-center-evil-theme)

(require-package 'neotree)
(evil-leader/set-key "d" 'dired)
(evil-leader/set-key "n" 'neotree-toggle)
(add-to-list 'evil-emacs-state-modes 'neotree-mode)
(setq neo-show-hidden-files 1)

(defalias 'yes-or-no-p 'y-or-n-p)

;; delimitmate alike - provides closing character for the opening character of a pair
(electric-pair-mode 1)

;; smart ruby code autocompletion (adds 'end' etc.)
(require-package 'ruby-electric)

(require-package 'flycheck)
(setq flycheck-ruby-rubocop-executable "~/.gem/ruby/2.2.3/bin/rubocop")
;; (add-hook 'after-init-hook #'global-flycheck-mode)
(eval-after-load 'flycheck
                 '(progn
                    (set-face-attribute 'flycheck-error nil
                                        :foreground "white"
                                        :background "red")
                    (set-face-attribute 'flycheck-warning nil
                                        :foreground "black"
                                        :background "yellow")))

(add-hook 'ruby-mode-hook
          '(lambda ()
             (setq flycheck-checker 'ruby-rubocop)
             (ruby-electric-mode 1)
             (flycheck-mode 1)))

;; http://emacswiki.org/emacs/RubyMode
(add-to-list 'auto-mode-alist
              '("\\.\\(?:gemspec\\|irbrc\\|gemrc\\|rake\\|rb\\|ru\\|thor\\)\\'" . ruby-mode))
(add-to-list 'auto-mode-alist
              '("\\(Capfile\\|Gemfile\\(?:\\.[a-zA-Z0-9._-]+\\)?\\|[rR]akefile\\)\\'" . ruby-mode))

; (require-package 'chruby)
; (chruby "ruby-2.2.2")

; (require-package 'enh-ruby-mode)
; (setq enh-ruby-program "~/.rubies/ruby-2.2.2/bin/ruby")

; maybe https://gist.github.com/gnufied/7160799
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
	 (quote
		(flycheck ruby-electric neotree powerline magit fill-column-indicator helm-projectile projectile helm distinguished-theme navigate key-chord evil-commentary evil-leader evil-search-highlight-persist evil-matchit evil-surround evil))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
