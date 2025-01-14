(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("1e6997bc08f0b11a2b5b6253525aed4e1eb314715076a0c0c2486bd97569f18a" default))
 '(display-line-numbers-type 'relative)
 '(package-selected-packages
   '(go-mode zprint-mode exec-path-from-shell orderless vertico company lsp-mode magit centaur-tabs auto-dark rainbow-delimiters treemacs-all-the-icons all-the-icons kaolin-themes cider treemacs neotree smartparens))
 '(tool-bar-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "JetBrains Mono" :foundry "nil" :slant normal :weight regular :height 120 :width normal)))))

;; automatically enable line numbers in all programming modes
(add-hook 'prog-mode-hook 'display-line-numbers-mode)
;; use relative line numbers
(setq display-line-numbers-type 'relative)

;; disable startup screen
(setq inhibit-splash-screen t)

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(dolist (package package-selected-packages)
  (unless (package-installed-p package)
    (package-install package)))

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

;; enable smartparens
(require 'smartparens-config)


;;
;; treemacs settings
;;

;; bind toggle treemacs to s-b
(global-set-key (kbd "s-b") 'treemacs)
;; set treemacs to open on the right
(setq treemacs-position 'right)

;; (global-set-key (kbd "s-w") 'close-current-tab)
(require 'centaur-tabs)
(centaur-tabs-mode t)
(setq centaur-tabs-style "slant")
(setq centaur-tabs-height 26)
(global-set-key (kbd "s-{") 'centaur-tabs-backward)
(global-set-key (kbd "s-}") 'centaur-tabs-forward)
(global-set-key (kbd "s-w") 'kill-this-buffer)
(setq centaur-tabs-set-icons t)
(setq centaur-tabs-icon-type 'all-the-icons)
(setq centaur-tabs-set-modified-marker t)

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
       (list (cond ((or (string= "*eshell*" (buffer-name))
			(string-equal "magit" (substring (buffer-name) 0 5))
                        (string-equal "*cider" (substring (buffer-name) 0 6)))
                     bottom-window-group)
                     ((string-equal "*" (substring (buffer-name) 0 1)) "Emacs")
                   ((derived-mode-p 'prog-mode) "Editing")
                     (t (centaur-tabs-get-group-name (current-buffer))))))

(defun create-or-get-eshell
       ()
       "Create or get an eshell buffer."
       (let ((eshell-buffer (get-buffer "*eshell*")))
            (or eshell-buffer
                (save-window-excursion (let ((display-buffer-alist nil))
                                            (eshell))
                                       (get-buffer "*eshell*")))))

(require 'magit)
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
       "Toggle a bottom window with tabs for eshell and vc-dir."
       (interactive)
       (if bottom-window-state
         (progn
           ;; Clean up and close the window
           (setq bottom-window-state nil)
           (delete-window (get-buffer-window (car bottom-window-state))))
         ;; Create and set up the bottom window
         (let* ((eshell-buf (create-or-get-eshell))
                 (vc-buf (create-or-get-vc-dir))
                 (bottom-window
                   (display-buffer-in-side-window
                     vc-buf
                     `((side . bottom) (slot . 0) (window-height . 0.3)))))
               ;; Enable centaur-tabs globally if not already enabledo
               (unless centaur-tabs-mode (centaur-tabs-mode t))
               ;; Select the bottom window and set up buffers
               (select-window bottom-window)
               (switch-to-buffer eshell-buf)
               ;; Make both buffers members of the bottom window group
               (with-current-buffer eshell-buf
                                    (setq centaur-tabs-current-group
                                          bottom-window-group))
               (with-current-buffer vc-buf
                                    (setq centaur-tabs-current-group
                                          bottom-window-group))
               ;; Store the window state
               (setq bottom-window-state (list eshell-buf vc-buf)))))

;; Bind the toggle function to s-j
(global-set-key (kbd "s-j") 'toggle-bottom-window)


;; remove the scroll bars
(scroll-bar-mode -1)

;; use a line cursor
(setq-default cursor-type 'bar)
;; but use a block cursor in the shell
(defun shell-cursor () (setq cursor-type 'box))
(add-hook 'eshell-mode-hook 'shell-cursor)

;; theme set up done last
;; load the theme i want
(require 'kaolin-themes)
(load-theme 'kaolin-valley-light t)
(load-theme 'kaolin-valley-dark t)
(require 'treemacs-all-the-icons)
(treemacs-load-theme "all-the-icons")
(setq kaolin-themes-italic-comments t)
(add-hook 'prog-mode-hook 'hl-line-mode)
(auto-dark-mode)
(setq auto-dark-themes '((kaolin-valley-dark) (kaolin-valley-light)))
;; lambdas fix issue with tabs not setting properly
(add-hook 'auto-dark-dark-mode-hook
          (lambda () (load-theme 'kaolin-valley-dark t)))
(add-hook 'auto-dark-light-mode-hook
          (lambda () (load-theme 'kaolin-valley-light t)))

;; disable tool bar
(tool-bar-mode -1)

;;
;; ---------- setting up programming environment -------
;;

(require 'lsp-mode)
(add-hook 'clojure-mode-hook 'lsp)
(add-hook 'ruby-mode-hook 'lsp)
(add-hook 'go-mode-hook 'lsp)
;; enable smart parens by default for some modes
(add-hook 'emacs-lisp-mode-hook #'smartparens-strict-mode)
(add-hook 'clojure-mode-hook #'smartparens-strict-mode)
(add-hook 'ruby-mode-hook #'smartparens-mode)
(add-hook 'prog-mode-hook #'rainbow-delimiters-mode)

;; turn on company mode for programming modes
(require 'company)
(add-hook 'prog-mode-hook 'company-mode)
;; rebind C-h to backspace
(global-set-key (kbd "C-h") (kbd "DEL"))
(define-key company-mode-map (kbd "C-h") (kbd "DEL"))
(define-key company-active-map (kbd "C-h") (kbd "DEL"))
;; escape should clear the active search map

;; set up orderless
(require 'orderless)
(setq completion-styles
      '(orderless basic)
      completion-category-overrides
      '((file (styles basic partial-completion))))

;; set up vertico
(require 'vertico)
(vertico-mode)

;; map command p to project file
(define-key prog-mode-map (kbd "s-p") 'project-find-file)

;; set up the key bindings for repl functions in cider
(require 'cider)
(define-key cider-mode-map (kbd "M-RET") 'cider-eval-defun-at-point)
(define-key cider-mode-map (kbd "C-<return>") 'cider-eval-sexp-at-point)
(define-key prog-mode-map (kbd "C-M-9") 'sp-backward-barf-sexp)
(define-key prog-mode-map (kbd "C-M-8") 'sp-backward-slurp-sexp)
(define-key prog-mode-map (kbd "C-M-0") 'sp-forward-barf-sexp)
(define-key prog-mode-map (kbd "C-M--") 'sp-forward-slurp-sexp)

;; finish up by only having one window at startup
(delete-other-windows)

;; meta return should send to m-: for evaluation
(define-key emacs-lisp-mode-map (kbd "M-RET") (kbd "C-x C-e"))

(defun clojure-mode-before-save-hook ()
  (when (eq major-mode 'clojure-mode)
    (zprint)))
(add-hook 'before-save-hook 'clojure-mode-before-save-hook)

(with-eval-after-load 'treemacs
  (define-key
   treemacs-mode-map
   [mouse-1]
   #'treemacs-single-click-expand-action))

;; set up go mode
(require 'go-mode)
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))
(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

;; paredit raise s-exp
(define-key prog-mode-map (kbd "C-M-P C-M-R") 'sp-raise-sexp)

