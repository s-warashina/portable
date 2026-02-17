;; MELPAリポジトリを登録
(require 'package)
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)
;; パッケージを上手くインストールできない時はpackage-refresh-contentsを実行する
;; (package-refresh-contents)

;; 設定
(global-display-line-numbers-mode t)

;; 上部のUIを非表示にする
(scroll-bar-mode -1)
(menu-bar-mode -1)
(tool-bar-mode -1)


;; テーマ設定 (内部)
(load-theme 'modus-vivendi)
;; テーマ設定 (外部)
;; (use-package kuronami-theme
;;   :ensure t
;;   :config
;;   (load-theme 'kuronami t)
;;   )

;; カスタムできるダッシュボード
(use-package dashboard
  :ensure t
  :config
  (setq dashboard-startup-banner 'logo) ;; dashboardのロゴを使用
  (dashboard-setup-startup-hook) ;; 起動時にdashboardの画面を表示
  )


;; vim風味のモーダル編集機能を提供するパッケージ
(use-package meow
  :ensure t
  :load-path "~/.emacs.d/meow-config/"
  :config 
  (require 'meow-keybindings)
  (meow-keybindings-setup)
  (setq meow-use-clipboard t)
  (meow-global-mode 1)
  )

;; 補完UIパッケージ
(use-package vertico
  :ensure t
  :custom
  (vertico-count 8)
  (vertico-cycle t)
  :init
  (vertico-mode)
  )


;; verticoの補完UIに対して順序不問の文字列一致検索を提供するパッケージ
(use-package orderless
  :ensure t
  :custom
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch))
  ;; (orderless-component-separator #'orderless-escapable-split-on-space)
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

;; 候補表示パッケージ
(use-package consult
  :ensure t
  :bind
  (("C-x b" . consult-buffer) ;; バッファ表示
   ("M-s g" . consult-ripgrep)
   ("M-s G" . consult-git-grep)
   ("C-s" . consult-line)
   )
  )

;; フォント(windows)
(when (eq system-type 'windows-nt)
  (add-to-list 'default-frame-alist '(font . "Moralerspace Neon-12"))
  ;; (add-to-list 'default-frame-alist '(font . "Meiryo UI-12"))
  )
;; ファイルサイズをモードラインに表示
(size-indication-mode t)

;; 閉じ括弧の自動入力
(electric-pair-mode 1)

;; 自動インデントの無効化
(electric-indent-mode -1)

;; scratchバッファのモードを変更 (pareditが邪魔なので)
(setq initial-major-mode 'fundamental-mode)

(use-package paredit
  :ensure t
  :hook
  (emacs-lisp-mode . paredit-mode) ; .elファイルでparedit-modeを有効にする
  )

(use-package rainbow-delimiters
  :ensure t
  :hook
  (emacs-lisp-mode . rainbow-delimiters-mode) ; .elファイルでrainbow-delimiters-modeを有効にする
  )

;; 改行文字の文字列表現
(set 'eol-mnemonic-dos "(CRLF)")
(set 'eol-mnemonic-unix "(LF)")
(set 'eol-mnemonic-mac "(CR)")
(set 'eol-mnemonic-undecided "(?)")

;; 現在入力しているキーに続く候補をミニバッファに表示するwhich-key-modeを有効化
(which-key-mode t)

;; ミニバッファの履歴を保存する
(savehist-mode 1)

;; 前方検索
(global-set-key (kbd "M-i") 'isearch-forward)
;; ヘルプキーを変更し、代わりにbackspaceをC-hに割当
(global-set-key (kbd "M-?") 'help-command)
(global-set-key (kbd "C-h") 'delete-backward-char)

;; file~ のような自動バックアップファイルを作らない
(setq make-backup-files nil)

(use-package magit
  :ensure t
  :custom
  (magit-refresh-verbose t)
  )

;; Emacs minibuffer configurations.
(use-package emacs
  :custom
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  ;; Hide commands in M-x which do not work in the current mode.  Vertico
  ;; commands are hidden in normal buffers. This setting is useful beyond
  ;; Vertico.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Do not allow the cursor in the minibuffer prompt
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt)))

;; org-roam
(use-package org-roam
  :ensure t
  :bind
  (("C-c n f" . org-roam-node-find) ; ノート検索
   ("C-c n i" . org-roam-node-insert) ; ノートリンク挿入
   ("C-c n c" . org-roam-capture) ; 新規ノート作成
   )
  :config
  (let ((org-roam-dir "~/emacs-org-roam"))
    (unless (file-directory-p org-roam-dir)
      (make-directory org-roam-dir)
      )
    (setq org-roam-directory (file-truename org-roam-dir))
    )
  (org-roam-db-autosync-mode) ; org-roamがキャッシュの一貫性を維持するため、ファイル保存時に関数を実行する
  )


;; タブ幅を4に設定
(setq-default tab-width 4)

;; 変更のあったファイルを自動再読み込み windowsだと正しく動かない…
;; (global-auto-revert-mode 1)
;; (setq auto-revert-interval 3)

;; C-c rで確認無しでバッファをrevert
(defun revert-buffer-without-confirmation ()
  "Revert buffer without confirmation"
  (interactive)
  (revert-buffer t t)
  (message "Reverted `%s'" (buffer-name))
  )
(global-set-key (kbd "C-c r") 'revert-buffer-without-confirmation)
;; (global-set-key (kbd "M") 'point-to-register)
;; (global-set-key (kbd "`") 'jump-to-register)

;; 補完ライブラリ
(use-package company
  :ensure t
  :hook
  (emacs-lisp-mode . company-mode) ; .elファイルでcompany-modeを自動的に有効化する
   :config
  ;; (global-company-mode) ; 全バッファで有効にする 
  (setq company-idle-delay 0.1) ; デフォルトは0.5
  (setq company-tooltip-minimum-width 25) ; 表示文字数を増やす
  (setq company-tooltip-maximum-width 60) ; 表示文字数を増やす
  (setq company-minimum-prefix-length 3) ; デフォルトは4
  (setq company-selection-wrap-around t) ; 候補の一番下でさらに下に行こうとすると一番上に戻る
  (setq company-dabbrev-downcase nil)    ; 補完時にlower caseに変わってしまうのを防ぐ
  (define-key company-mode-map (kbd "C-,") 'company-complete)
  (define-key company-active-map (kbd "C-n") 'company-select-next)
  (define-key company-active-map (kbd "C-p") 'company-select-previous)
  )

;; ガベージコレクションのしきい値を設定
(setq gc-cons-threshold (* 64 1024 1024))


;; recentf - 最近開いたファイルの履歴を保存・表示する機能
;; C-x C-r でrecentfのリストを表示できる
;; 履歴はデフォルトでは ~/.emacs.d/recentf に保存される
(use-package recentf
  :ensure nil			  ; 組み込みパッケージのため、インストール不要
  :custom
  (recentf-max-saved-items 500) ; 保存する最大ファイル件数
  (recentf-exclude '("\.elc$")) ; 除外するファイル
  (run-with-idle-timer 180 t 'recentf-save-list) ;; 3分間アイドル後に保存
  :config
  (recentf-mode 1)
  )

;; magitのコミットメッセージ文字化け対策
(set-buffer-file-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

;; 自作
;; 連続する数字をカンマ区切りで挿入する関数
(defun insert-number-sequence (start end)
  "Insert a comma-separated sequence of numbers from START to END at point."
  (interactive "nStart number: \nnEnd number: ")
  (let* ((numbers (number-sequence start end))
         (sequence (mapconcat #'number-to-string numbers ",")))
    (insert sequence)))

;; JST時間をUTC時間に変換する関数
(defun jst-to-utc (jst-date-time)
  "Convert JST date-time string to UTC.
JST-DATE-TIME should be in format 'YYYY-MM-DD HH:MM:SS'.
Returns the UTC date-time string in the same format."
  (interactive "sJST date-time (YYYY-MM-DD HH:MM:SS): ")
  (let* ((parsed-time (parse-time-string jst-date-time))
         (decoded-time (encode-time parsed-time))
         ;; JST is UTC+9, so subtract 9 hours (32400 seconds) to get UTC
         (utc-time (time-subtract decoded-time (seconds-to-time (* 9 60 60))))
         (utc-string (format-time-string "%Y-%m-%d %H:%M:%S" utc-time)))
    (if (called-interactively-p 'any)
        (progn
          (insert utc-string)
          (message "JST: %s → UTC: %s" jst-date-time utc-string))
      utc-string)))

;; UTC時間をJST時間に変換する関数
(defun utc-to-jst (utc-date-time)
  "Convert UTC date-time string to JST.
UTC-DATE-TIME should be in format 'YYYY-MM-DD HH:MM:SS'.
Returns the JST date-time string in the same format."
  (interactive "sUTC date-time (YYYY-MM-DD HH:MM:SS): ")
  (let* ((parsed-time (parse-time-string utc-date-time))
         (decoded-time (encode-time parsed-time))
         ;; JST is UTC+9, so add 9 hours (32400 seconds) to get JST
         (jst-time (time-add decoded-time (seconds-to-time (* 9 60 60))))
         (jst-string (format-time-string "%Y-%m-%d %H:%M:%S" jst-time)))
    (if (called-interactively-p 'any)
        (progn
          (insert jst-string)
          (message "UTC: %s → JST: %s" utc-date-time jst-string))
      jst-string)))

(defun calc-date-diff (date-str1 date-str2)
  "2つの日付（YYYYMMDD形式）の差を計算して表示します。"
  (interactive "s開始日 (YYYYMMDD): \ns終了日 (YYYYMMDD): ")
    (let* ((parse-date (lambda (s)
                       (let ((year  (string-to-number (substring s 0 4)))
                             (month (string-to-number (substring s 4 6)))
                             (day   (string-to-number (substring s 6 8))))
                         ;; encode-time の引数: (秒 分 時 日 月 年)
                         (encode-time 0 0 0 day month year))))      
         ;; 文字列を内部時間形式に変換
         (time1 (funcall parse-date date-str1))
         (time2 (funcall parse-date date-str2))
         ;; 時間の差分を取得（秒単位）
         (diff-seconds (float-time (time-subtract time2 time1)))
         ;; 秒を日に変換 (1日 = 60秒 * 60分 * 24時間 = 86400秒)
         (diff-days (truncate (/ diff-seconds 86400))))
    (message "日付の差は %d 日です。" (abs diff-days))))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

