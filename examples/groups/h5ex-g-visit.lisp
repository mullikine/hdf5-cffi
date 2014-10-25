;;;; Copyright by The HDF Group.                                              
;;;; All rights reserved.
;;;;
;;;; This file is part of hdf5-cffi.
;;;; The full hdf5-cffi copyright notice, including terms governing
;;;; use, modification, and redistribution, is contained in the file COPYING,
;;;; which can be found at the root of the source code distribution tree.
;;;; If you do not have access to this file, you may request a copy from
;;;; help @hdfgroup.org.

;;; This example shows how to recursively traverse a file
;;; using H5Ovisit and H5Lvisit.  The program prints all of
;;; the objects in the file specified in FILE, then prints all
;;; of the links in that file.

;;; http://www.hdfgroup.org/ftp/HDF5/examples/examples-by-api/hdf5-examples/1_8/C/H5G/h5ex_g_visit.c

#+sbcl(require 'asdf)
(asdf:operate 'asdf:load-op 'hdf5-cffi)

(in-package :hdf5)

;;; Download the input file from
;;; http://www.hdfgroup.org/ftp/HDF5/examples/files/exbyapi/h5ex_g_visit.h5
;;; or use one of your own files.

(defparameter *FILE* "h5ex_g_visit.h5")

;;; I'm not sure how to invoke a CFFI callback as a LISP function.
;;; This is a workaround...

(defun print-info-et-name (info name)
  (format t "/")
  (let ((type (cffi:foreign-slot-value info '(:struct h5o-info-t) 'type)))
    (if (equal name ".")
	(format t "  (Group)~%")
	(cond ((eql type :H5O-TYPE-GROUP)
	       (format t "~a  (Group)~%" name))
	      ((eql type :H5O-TYPE-DATASET)
	       (format t "~a  (Dataset)~%" name))
	      ((eql type :H5O-TYPE-NAMED-DATATYPE)
	       (format t "~a  (Datatype)~%" name))
	      (t (format t "~a  (Unknown)~%" name))))))
  
;;; the callback function for H5Ovisit

(cffi:defcallback op-func herr-t
    ((loc-id hid-t)
     (name :string)
     (info (:pointer (:struct h5o-info-t)))
     (operator-data :pointer))
  (prog2
    (print-info-et-name info name)
    0))

;;; the callback function for H5Lvisit

(cffi:defcallback op-func-l herr-t
    ((loc-id hid-t)
     (name :string)
     (info (:pointer (:struct h5l-info-t)))
     (operator-data :pointer))
  (progn
    (cffi:with-foreign-object (infobuf '(:struct h5o-info-t) 1)
      (let ((infobuf-ptr (cffi:mem-aptr infobuf '(:struct h5o-info-t) 0)))
	(h5oget-info-by-name loc-id name infobuf-ptr +H5P-DEFAULT+)
	(print-info-et-name infobuf-ptr name)
	0))))

;;; Showtime

(let*
    ((fapl (h5pcreate +H5P-FILE-ACCESS+))
     (file (prog2
	       (h5pset-fclose-degree fapl :H5F-CLOSE-STRONG)
	       (h5fopen *FILE* +H5F-ACC-RDONLY+ fapl))))

  (unwind-protect

       (progn
	 (format t "Objects in the file:~%")
	 (h5ovisit file :H5-INDEX-NAME :H5-ITER-NATIVE
		   (cffi:callback op-func) (cffi:null-pointer))
	 (format t "~%Links in the file:~%")
	 (h5lvisit file :H5-INDEX-NAME :H5-ITER-NATIVE
		   (cffi:callback op-func-l) (cffi:null-pointer))))
    
    (h5fclose file)
    (h5pclose fapl))

#+sbcl(sb-ext:quit)