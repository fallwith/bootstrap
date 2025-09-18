;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(when (display-graphic-p)
  ;; (set-frame-parameter (selected-frame) 'fullscreen 'maximized)
  (set-frame-size (selected-frame) 145 60))

;; allowlist of themes
(defvar themes
  '(everforest-hard-dark everforest-hard-dark everforest-hard-dark everforest-hard-dark everforest-hard-dark
    doom-nova
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

; (after! evil
;   (setq evil-ex-search-case 'smart)
;   (setq evil-ex-completion-system 'emacs))

(after! evil
  (setq evil-escape-key-sequence "jk"
        evil-escape-delay 0.25))

;; flip ; and : for evil mode
(map! :after evil
      :n ";" #'evil-ex
      :n ":" #'evil-repeat-find-char)

; (setq scroll-margin 5
;       scroll-conservatively 101)

(setq-default indent-tabs-mode nil
              tab-width 2
              standard-indent 2)

(setq-default fill-column 120)
;; ?\u2502 = │ (default)
;; ?\u2506 = ┆ (dashed)
;; ?\u254e = ╎ (light dashed)
;; ?\u2016 = ‖ (double vertical)
;; ?|      = | (ASCII pipe)
; (setq-default display-fill-column-indicator-character ?\u254e)
(global-display-fill-column-indicator-mode)

(add-hook 'tetris-mode-hook
          (lambda ()
            (evil-local-set-key 'normal (kbd "<up>") 'tetris-rotate-prev)
            (evil-local-set-key 'normal (kbd "<down>") 'tetris-rotate-next)
            (evil-local-set-key 'normal (kbd "<left>") 'tetris-move-left)
            (evil-local-set-key 'normal (kbd "<right>") 'tetris-move-right)
            (evil-local-set-key 'normal (kbd "w") 'tetris-move-bottom) ; hard drop
            (evil-local-set-key 'normal (kbd "d") 'tetris-move-down) ; soft drop
            (evil-local-set-key 'normal (kbd "n") 'tetris-start-game)
            (evil-local-set-key 'normal (kbd "p") 'tetris-pause-game)
            (evil-local-set-key 'normal (kbd "q") 'tetris-end-game)))

(map! :leader
      :desc "Open terminal" "t" #'+vterm/here
      :desc "Clear search highlight" "/" #'evil-ex-nohighlight
      :desc "Vertical split" "v" (cmd! (evil-window-vsplit) (other-window 1))
      :desc "Horizontal split" "h" (cmd! (evil-window-split) (other-window 1)))

(map! :map evil-normal-state-map
      "C-h" #'evil-window-left
      "C-j" #'evil-window-down
      "C-k" #'evil-window-up
      "C-l" #'evil-window-right)

(map! :n "H" #'previous-buffer
      :n "L" #'next-buffer)

;; custom functions
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
(defalias 'TN 'rspec-run-single-in-full-vterm "Run the test at the cursor's current line")
(defalias 'TF 'rspec-run-file-in-full-vterm "Run all tests in the current file")

;; RSpec
;; shared runner function
(defun rspec-run-in-vterm (command)
  "Run RSpec command in a full-window vterm"
  (let ((buffer-name "*RSpec*"))
    ;; kill existing RSpec buffer if it exists
    (when (get-buffer buffer-name)
      (kill-buffer buffer-name))

    ;; create new vterm buffer in full window
    (delete-other-windows)
    (let ((vterm-buffer (vterm buffer-name)))
      (with-current-buffer vterm-buffer
        ;; disable line numbers
        (display-line-numbers-mode -1)

        ;; evil keybindings
        (evil-local-set-key 'insert (kbd "C-o")
          (lambda () (interactive) (vterm-copy-mode 1) (evil-normal-state)))
        (evil-local-set-key 'normal (kbd "C-o")
          (lambda () (interactive) (other-window 1)))

        ;; process killing with either C-c C-c or s-.
        (evil-local-set-key 'insert (kbd "s-.")
          (lambda () (interactive) (vterm-send "C-c")))
        (evil-local-set-key 'insert (kbd "C-c C-c")
          (lambda () (interactive) (vterm-send "C-c")))

        ;; 'q' to close when done - kill the vterm process without prompting
        (evil-local-set-key 'normal (kbd "q")
          (lambda ()
            (interactive)
            (let ((proc (get-buffer-process (current-buffer))))
              (when proc
                (set-process-query-on-exit-flag proc nil)
                (kill-process proc))
              (kill-buffer (current-buffer))
              (when (= (length (window-list)) 1)
                (previous-buffer)))))

        ;; run the command
        (vterm-send-string command)
        (vterm-send-return)))))

;; single test runner
(defun rspec-run-single-in-full-vterm ()
    "Run the RSpec test on the current line"
    (interactive)
    (let* ((test-file (buffer-file-name))
           (line-number (line-number-at-pos))
           (command (format "cd %s && bundle exec rspec %s:%d"
                           (projectile-project-root)
                           (file-relative-name test-file (projectile-project-root))
                           line-number)))
      (rspec-run-in-vterm command)))

;; all tests in file runner
(defun rspec-run-file-in-full-vterm ()
    "Run all RSpec tests in the current file"
    (interactive)
    (let* ((test-file (buffer-file-name))
           (command (format "cd %s && bundle exec rspec %s"
                           (projectile-project-root)
                           (file-relative-name test-file (projectile-project-root)))))
      (rspec-run-in-vterm command)))

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

;; fuzzy search with orderless
(after! orderless
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-pcm-leading-wildcard t)
  (setq orderless-matching-styles '(orderless-flex)))

;; vterm configuration - ensure Evil works in copy mode
(after! vterm
  (add-hook 'vterm-copy-mode-hook #'evil-normal-state)
  ;; Map Cmd-. to send C-c (Mac Terminal.app behavior)
  (define-key vterm-mode-map (kbd "s-.") (lambda () (interactive) (vterm-send "C-c"))))

;; do not by default yank to the kill ring (which syncs to the system
;; clipboard) and instead use <leader>y to do do
(setq select-enable-clipboard nil)
(after! evil
  (map! :leader
        "y" (lambda! ()
              (interactive)
              (setq evil-this-register ?+)
              (call-interactively #'evil-yank))))
