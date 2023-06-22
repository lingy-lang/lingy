(ns lingy.string
  ; TODO move the clojure source code into Lingy/string.clj
  ; (:use clojure.string)
)

; Parts of clojure/string.clj were copied into the remainder of this file.
; Those parts are covered by the following license:

;   Copyright (c) Rich Hickey. All rights reserved.
;   The use and distribution terms for this software are covered by the
;   Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
;   which can be found in the file epl-v10.html at the root of this distribution.
;   By using this software in any fashion, you are agreeing to be bound by
;   the terms of this license.
;   You must not remove this notice, or any other, from this software.

(defn ^String reverse
  "Returns s with its characters reversed."
  {:added "1.2"}
  [^CharSequence s]
  (.toString (.reverse (StringBuilder. s))))

(defn ^String join
  "Returns a string of all elements in coll, as returned by (seq coll),
   separated by an optional separator."
  {:added "1.2"}
  ([coll]
     (apply str coll))
  ([separator coll]
     (loop [sb (StringBuilder. (str (first coll)))
            more (next coll)
            sep (str separator)]
       (if more
         (recur (-> sb (.append sep) (.append (str (first more))))
                (next more)
                sep)
         (str sb)))))

(defn ends-with?
  "True if s ends with substr."
  {:added "1.8"}
  [^CharSequence s ^String substr]
  (.endsWith (.toString s) substr))
