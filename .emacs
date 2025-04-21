(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("7ed236688b971b70744d1410d4e86cebde9b2980e0568f38d22db4f319e8d135" "1e6997bc08f0b11a2b5b6253525aed4e1eb314715076a0c0c2486bd97569f18a" default))
 '(display-line-numbers-type 'relative)
 '(package-selected-packages
   '(diminish dape slime go-mode zprint-mode exec-path-from-shell orderless vertico company lsp-mode magit centaur-tabs auto-dark rainbow-delimiters treemacs-all-the-icons all-the-icons kaolin-themes cider treemacs neotree smartparens))
 '(tool-bar-mode nil))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "JetBrains Mono" :foundry "nil" :slant normal :weight regular :height 120 :width normal))))
 '(magit-diff-file-heading ((t (:extend t :foreground "systemOrangeColor" :weight bold)))))

; profile
(setq use-package-compute-statistics t)

;; automatically enable line numbers in all programming modes
(add-hook 'prog-mode-hook 'display-line-numbers-mode)


;; disable startup screen
; (setq inhibit-splash-screen t)

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

;; fix loading from applications directory
(require 'exec-path-from-shell)
(dolist (var '("CPPFLAGS" "GEM_HOME")))
(when (memq window-system '(mac ns x)) (exec-path-from-shell-initialize))

;; allow scrolling the window the mouse is over
(setq mouse-wheel-follow-mouse t)

;; disable line wrapping, allow horizontal scrolling, flip direction
;; so that it works right with mac trackpad
(set-default 'truncate-partial-width-windows nil)
(set-default 'truncate-lines t)
(setq mouse-wheel-tilt-scroll t)
(setq mouse-wheel-flip-direction t)

;; This defines ctrl-cmd-f to do the same as clicking the toggle-fullscreen
;; titlebar
;; icon usually meant for the "View -> Enter/Exit Full Screen" menu option in
;; Mac apps
(defun
  toggle-fullscreen
  ()
  "toggle-fullscreen, same as clicking the
 corresponding titlebar icon in the right hand corner of Mac app windows"
  (interactive)
  (set-frame-parameter nil
                       'fullscreen
                       (pcase (frame-parameter nil 'fullscreen)
                              (`fullboth nil)
                              (`fullscreen nil)
                              (_ 'fullscreen))))
(global-set-key (kbd "C-s-f") 'toggle-fullscreen)
; For some weird reason C-s-f only means right cmd key!
(global-set-key (kbd "<C-s-268632070>") 'toggle-fullscreen)

(use-package smartparens
  :ensure smartparens
  :defer t

  :hook ((clojure-mode . smartparens-strict-mode)
	 (lisp-mode . smartparens-strict-mode)
	 (emacs-lisp-mode . smartparens-strict-mode)
	 ruby-mode)
  
  :bind (:map prog-mode-map
	      ("C-M-n" . 'sp-up-sexp)
	      ("C-M-p" . 'sp-backward-down-sexp)
	      ("C-M-e" .  'sp-end-of-sexp)      
	      ("C-M-a" .  'sp-beginning-of-sexp)
	      ("C-M-^" . 'sp-raise-sexp)          
	      ("C-M-9" . 'sp-backward-barf-sexp)  
	      ("C-M-8" . 'sp-backward-slurp-sexp) 
	      ("C-M-0" . 'sp-forward-barf-sexp)   
	      ("C-M--" . 'sp-forward-slurp-sexp))
  
  :config
  (require 'smartparens-config))

(use-package treemacs
  :ensure treemacs
  :defer t
  
  :bind (("s-b" . 'treemacs) ;; bind toggle treemacs to s-b
	 :map treemacs-mode-map
	 ([mouse-1] . 'treemacs-single-click-expand-action)
	 ("SPC" . 'treemacs-RET-action))
  
  :custom (treemacs-position 'right)
  
  :config
  (require 'treemacs-all-the-icons)
  (treemacs-load-theme "all-the-icons"))

(use-package centaur-tabs
  :ensure centaur-tabs
  :defer t
  
  :custom ((centaur-tabs-style "slant")
	   (centaur-tabs-height 26)
	   (centaur-tabs-set-icons t)
	   (centaur-tabs-set-modified-marker t))

  :bind (("s-{" . 'centaur-tabs-backward)
	 ("s-}" . 'centaur-tabs-forward)
	 ("s-w" . 'kill-this-buffer))

  :hook ((fundemental-mode . (lambda () (centaur-tabs-mode t)))
	 (prog-mode . (lambda () (centaur-tabs-mode t)))))

;; Track the bottom window state
(defvar bottom-window-state
        nil
        "Store the state of the bottom window with tabs.")

;; Configure centaur-tabs for our bottom window buffers
(defvar bottom-window-group
        "BottomTabs"
        "Tab group name for bottom window buffers.")

(defun centaur-tabs-buffer-groups
       ()
       "Control buffer groups for centaur-tabs."
       (list (cond ((or (string= "*shell*" (buffer-name))
			(string-equal "magit" (substring (buffer-name) 0 5))
                        (string-equal "*cider" (substring (buffer-name) 0 6)))
                     bottom-window-group)
                     ((string-equal "*" (substring (buffer-name) 0 1)) "Emacs")
                   ((derived-mode-p 'prog-mode) "Editing")
                     (t (centaur-tabs-get-group-name (current-buffer))))))

(defun create-or-get-shell
       ()
       "Create or get an shell buffer."
       (let ((shell-buffer (get-buffer "*shell*")))
            (or shell-buffer
                (save-window-excursion (let ((display-buffer-alist nil))
                                            (shell))
                                       (get-buffer "*shell*")))))

(use-package magit
  :ensure magit
  :defer t

  :custom (magit-list-refs-sortby "-creatordate"))

(defun create-or-get-vc-dir
    ()
  "Create or get a vc-dir buffer for the current directory."
  (let ((existing-buffer
        (car (cl-remove-if-not
            (lambda (buf)
                (with-current-buffer buf
                (derived-mode-p 'magit-status-mode)))
            (buffer-list)))))
    (or existing-buffer
	(save-window-excursion (let ((display-buffer-alist nil))
				 (magit-status))
			       (car (cl-remove-if-not
				     (lambda (buf)
				       (with-current-buffer buf
					 (derived-mode-p 'magit-status-mode)))
				     (buffer-list)))))))

(defun toggle-bottom-window
       ()
       "Toggle a bottom window with tabs for shell and vc-dir."
       (interactive)
       (if bottom-window-state
         (progn
           ;; Clean up and close the window
           (setq bottom-window-state nil)
           (delete-window (get-buffer-window (car bottom-window-state))))
         ;; Create and set up the bottom window
         (let* ((shell-buf (create-or-get-shell))
                 (vc-buf (create-or-get-vc-dir))
                 (bottom-window
                   (display-buffer-in-side-window
                     vc-buf
                     `((side . bottom) (slot . 0) (window-height . 0.3)))))
               ;; Enable centaur-tabs globally if not already enabledo
               (unless centaur-tabs-mode (centaur-tabs-mode t))
               ;; Select the bottom window and set up buffers
               (select-window bottom-window)
               (switch-to-buffer shell-buf)
               ;; Make both buffers members of the bottom window group
               (with-current-buffer shell-buf
                                    (setq centaur-tabs-current-group
                                          bottom-window-group))
               (with-current-buffer vc-buf
                                    (setq centaur-tabs-current-group
                                          bottom-window-group))
               ;; Store the window state
               (setq bottom-window-state (list shell-buf vc-buf)))))

;; Bind the toggle function to s-j
(global-set-key (kbd "s-j") 'toggle-bottom-window)


;; remove the scroll bars
(scroll-bar-mode -1)
;; remove tool bar
(tool-bar-mode -1)

;; use a line cursor
(setq-default cursor-type 'bar)
;; but use a block cursor in the shell
(defun shell-cursor () (setq cursor-type 'box))
(add-hook 'shell-mode-hook 'shell-cursor)

;; theme set up done last
;; load the theme i want
(use-package kaolin-themes
  :ensure kaolin-themes

  :custom (kaolin-themes-italic-comments t)

  :config
  (load-theme 'kaolin-valley-light t)
  (load-theme 'kaolin-valley-dark t))

(use-package diminish
  :ensure t)

(use-package auto-dark
  :ensure auto-dark
  :defer 5
  
  :diminish auto-dark-mode
  
  :custom
  (auto-dark-themes '((kaolin-valley-dark) (kaolin-valley-light)))
  (auto-dark-polling-interval-seconds 5)

  :config
  (auto-dark-mode))
; these need to be outside of use-package cause of strangeness with tabs
(add-hook 'auto-dark-dark-mode-hook (lambda () (load-theme 'kaolin-valley-dark t)))
(add-hook 'auto-dark-light-mode-hook (lambda () (load-theme 'kaolin-valley-light t)))


;;
;; ---------- setting up programming environment -------
;;
(add-hook 'prog-mode-hook 'global-hl-line-mode)

(use-package lsp-mode
  :ensure t
  :defer t)

(use-package rainbow-delimiters
  :ensure t
  
  :hook prog-mode)

(use-package company
  :ensure t

  :diminish company-mode

  :hook prog-mode

  :bind (("C-h" . "DEL")
	 ("M-h" . "DEL")
	 :map company-mode-map
	 ("C-h" . "DEL")
	 :map company-active-map
	 ("C-h" . "DEL")))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; set up vertico
(use-package vertico
  :ensure t
  :init
  (vertico-mode))

;; Emacs minibuffer configurations.
(use-package emacs
  :custom
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  ;; Hide commands in M-x which do not work in the current mode.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Do not allow the cursor in the minibuffer prompt
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt)))

;; map command p to project file
(define-key prog-mode-map (kbd "s-p") 'project-find-file)
(define-key prog-mode-map (kbd "s-F") 'project-find-regexp)

(use-package cider
  :ensure t
  :bind (:map cider-mode-map
	      ("M-RET" . cider-eval-defun-at-point)
	      ("C-<return>" . cider-eval-sexp-at-point))
  :hook ((before-save-hook . (lambda ()
			       (when (eq major-mode 'clojure-mode)
				 (zprint))))
	 (clojure-mode-hook . lsp)))
              
;; finish up by only having one window at startup
(delete-other-windows)

;; meta return should send to m-: for evaluation
(define-key emacs-lisp-mode-map (kbd "M-RET") (kbd "C-x C-e"))

;; set up go mode
(use-package go-mode
  :ensure go-mode
  
  :hook ((go-mode-hook . lsp)
	 (go-mode-hook . (lambda () (setq tab-width 4)))
	 (go-mode-hook . (lambda ()
			   (add-hook 'before-save-hook #'lsp-format-buffer t t)
			   (add-hook 'before-save-hook #'lsp-organize-imports t t))))
  
  :bind (:map go-mode-map
	      ("M-?" . godoc-at-point)
	      ("M-_" . xref-find-references)))

;; add config for debugger
(use-package dape
  :ensure dape
  :defer t
  
  :config
  ;; Turn on global bindings for setting breakpoints with mouse
  (dape-breakpoint-global-mode)

  :custom
  ;; Info buffers to the right
  (dape-buffer-window-arrangement 'right))

(use-package ruby-mode
  :ensure ruby-mode
  :hook (ruby-mode-hook . lsp))

;; set cursor to blink indefinitely
(setq blink-cursor-blinks 0)

;; this is a temporary fix for tooltips opening on a new screen
(setopt tooltip-mode nil)

;; add slime mode hook for .cl files
(add-to-list 'auto-mode-alist '("\\.cl\\'" . common-lisp-mode))
(add-to-list 'auto-mode-alist '("\\.lisp\\'" . lisp-mode))
(add-hook 'lisp-mode-hook #'smartparens-strict-mode)

(setq inferior-lisp-program "sbcl")
(define-key lisp-mode-map (kbd "M-RET") 'slime-eval-defun)

(setq column-number-mode t)

;; this is a function that allows sending a definition to the shell
(defun send-bird-lisp-defun-to-repl ()
  "sends the current function definition to the repl, assuming its running in the shell"
  (let ((jump-back-to (point)))
    (progn
      (mark-defun)
      (copy-region-as-kill (region-beginning) (region-end))
      (let ((fundef (substring-no-properties (car kill-ring))))
	(process-send-string "*shell*" (concat (replace-regexp-in-string
						"\n" "" (replace-regexp-in-string
							 ";.*?\n" "\n" fundef))
					       "\n")))
      (goto-char jump-back-to))))

(defun lookup-bird-lisp-defun ()
  "look up a function definition in the current file"
  (progn
    (mark-word)
    (copy-region-as-kill (region-beginning) (region-end))
    (goto-char 0)
    (search-forward (substring-no-properties (car kill-ring)))))

