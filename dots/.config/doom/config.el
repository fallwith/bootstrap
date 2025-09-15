;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; allowlist of themes
(defvar themes
  '(doom-nova
    doom-material-dark
    doom-monokai-pro
    doom-nord
    doom-palenight
    doom-spacegrey
    catppuccin
    doom-dracula
    modus-vivendi))

;; choose a random theme
(setq doom-theme (nth (random (length themes)) themes))

(setq display-line-numbers-type t)

(after! evil
  (setq evil-ex-search-case 'smart))

(after! evil
  (setq evil-escape-key-sequence "jk"
        evil-escape-delay 0.25
        evil-escape-unordered-key-sequence t))

;; flip ; and : for evil mode
(map! :after evil
      :n ";" #'evil-ex
      :n ":" #'evil-repeat-find-char)

(setq scroll-margin 5
      scroll-conservatively 101)

(setq-default indent-tabs-mode nil
              tab-width 2
              standard-indent 2)

(setq display-fill-column-indicator-column 80)
(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)

(map! :leader
      :desc "Open terminal" "t" #'+vterm/toggle
      :desc "Clear search highlight" "/" #'evil-ex-nohighlight
      :desc "Vertical split" "v" #'evil-window-vsplit
      :desc "Horizontal split" "h" #'evil-window-split)

(map! :map evil-normal-state-map
      "C-h" #'evil-window-left
      "C-j" #'evil-window-down
      "C-k" #'evil-window-up
      "C-l" #'evil-window-right)

(map! :n "H" #'previous-buffer
      :n "L" #'next-buffer)

;; Custom functions
(defun copy-file-path ()
  "Copy the current file path to clipboard"
  (interactive)
  (if buffer-file-name
      (progn
        (kill-new buffer-file-name)
        (message "File path copied: %s" buffer-file-name))
    (message "No file associated with this buffer")))

(defun strip-trailing-whitespace-custom ()
  "Remove trailing whitespace from entire buffer"
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "[ \t]+$" nil t)
      (replace-match "" nil nil))))

(defun rails-alternate-file ()
  "Switch between app/ and spec/ files (Rails convention)"
  (interactive)
  (let* ((file (buffer-file-name))
         (alt-file (cond
                    ;; From spec to app
                    ((string-match "^\\(.*\\)/spec/\\(.*\\)_spec\\.rb$" file)
                     (concat (match-string 1 file) "/app/" (match-string 2 file) ".rb"))
                    ;; From app to spec
                    ((string-match "^\\(.*\\)/app/\\(.*\\)\\.e?rb$" file)
                     (concat (match-string 1 file) "/spec/" (match-string 2 file) "_spec.rb"))
                    ;; Default: add _spec.rb
                    (t (concat (file-name-sans-extension file) "_spec.rb")))))
    (find-file alt-file)))

;; command aliases
(defalias 'CP 'copy-file-path "Copy current file path")
(defalias 'Strip 'strip-trailing-whitespace-custom "Strip trailing whitespace")
(defalias 'A 'rails-alternate-file "Alternate between app and spec files")
(defalias 'TF 'rspec-verify-matching "Run all specs related to the current buffer")
(defalias 'TN 'rspec-verify-single "Run specified example at point")

(defun random-theme ()
  "Load a random dark theme from our rotation"
  (interactive)
  (let ((theme (nth (random (length themes)) themes)))
    (load-theme theme t)
    (setq doom-theme theme)
    (message "Loaded theme: %s" theme)))

(defun preview-theme (theme)
  "Preview a theme temporarily"
  (interactive
   (list (intern (completing-read "Preview theme: "
                                  (mapcar #'symbol-name (custom-available-themes))))))
  (let ((current-theme doom-theme))
    (load-theme theme t)
    (message "Previewing %s. Press any key to continue, 'k' to keep, 'r' to restore" theme)
    (let ((key (read-key)))
      (cond
       ((eq key ?k)
        (setq doom-theme theme)
        (message "Kept theme: %s" theme))
       (t
        (load-theme current-theme t)
        (message "Restored theme: %s" current-theme))))))

(defun show-current-theme ()
  "Display the current theme"
  (interactive)
  (message "Current theme: %s" (or doom-theme "none")))

(defalias 'theme 'switch-theme "Switch theme")
(defalias 'randomtheme 'random-theme "Load random theme")
(defalias 'preview 'preview-theme "Preview theme")
(defalias 'currenttheme 'show-current-theme "Show current theme")

;; Use oil.nvim style '-' for dired jump and up-directory
(map! :n "-" #'dired-jump)
(after! dired
  (map! :map dired-mode-map
        :n "-" #'dired-up-directory)
  (setq dired-listing-switches "-alh --group-directories-first"))

;; Jump navigation (Flash.nvim equivalent)
;; Use 'f' for avy jump (replaces Evil's find-char)
(map! :n "f" #'avy-goto-char-timer
      :n "F" #'avy-goto-line)

;; tabstop 2
(after! ruby-mode
  (setq ruby-indent-level 2
        ruby-indent-tabs-mode nil))
(after! js-mode
  (setq js-indent-level 2))
(after! typescript-mode
  (setq typescript-indent-level 2))
(after! python-mode
  (setq python-indent-offset 2))
(after! yaml-mode
  (setq yaml-indent-offset 2))

;; auto-detect .jbuilder files as Ruby
(add-to-list 'auto-mode-alist '("\\.json\\.jbuilder\\'" . ruby-mode))

(setq doom-font (font-spec :family "NotoSansM Nerd Font Mono" :size 14)
      doom-big-font (font-spec :family "NotoSansM Nerd Font Mono" :size 18)
      doom-unicode-font doom-font
      doom-variable-pitch-font doom-font)

(setq org-directory "~/org/")

;; enable evil-escape
(after! evil-escape
  (evil-escape-mode 1))
