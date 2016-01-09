;;; http://lispblog.xach.com/post/129215925278/my-new-favorite-slimesbclccl-trick
#+sbcl
(push (lambda (&rest args)
        (apply #'swank:ed-in-emacs args)
        t)
      sb-ext:*ed-functions*)
