;;; org-download.el --- Image drag-and-drop for Emacs org-mode

;; Copyright (C) 2013  Oleh Krehel

;; Author: Oleh Krehel <ohwoeowho@gmail.com>
;; URL: https://github.com/abo-abo/org-download
;; Version: 0.1

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This extension enables dragging an image from a browser to
;; an org-mode buffer in Emacs.
;; The image will be downloaded to an appropriate folder and a link
;; to it will be inserted at point.



(require 'async)
(eval-when-compile
  (require 'cl))

(defvar org-download-image-dir nil
  "If not nil, `org-download-image' will store images here.")

(defun org-download--image (link basedir)
  (async-start
   `(lambda() (shell-command
          ,(format "wget \"%s\" -P \"%s\""
                   link
                   (expand-file-name basedir))))
   (lexical-let ((cur-buf (current-buffer)))
     (lambda(x) (message "Async process done")
       (with-current-buffer cur-buf
         (org-display-inline-images))))))

(defun org-download-image (link)
  "Save image at address LINK to current directory's sub-directory DIR.
DIR is the name of the current level 0 heading."
  (interactive (list (current-kill 0)))
  (let ((filename (car (last (split-string link "/"))))
        (dir (or org-download-image-dir
                 (format
                  "./%s"
                  (save-excursion
                    (org-up-heading-all (1- (org-current-level)))
                    (substring-no-properties
                     (org-get-heading)))))))
    (if (null (image-type-from-file-name filename))
        (message "not an image URL")
      (unless (file-exists-p (expand-file-name filename dir))
        (org-download--image link dir))
      (if (looking-back "^[ \t]+")
          (delete-region (match-beginning 0) (match-end 0))
        (newline))
      (insert (format "#+DOWNLOADED: %s @ %s\n [[%s/%s]]"
                      link
                      (format-time-string "%Y-%m-%d %H:%M:%S")
                      dir
                      filename))
      (org-display-inline-images))))

(setcdr (assoc "^\\(https?\\|ftp\\|file\\|nfs\\)://" dnd-protocol-alist) 'org-download-dnd)

(defun org-download-dnd (uri action)
  (org-download-image uri))

(provide 'org-download)
;;; org-download.el ends here
