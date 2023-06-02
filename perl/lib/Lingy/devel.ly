(ns lingy.devel)

(defn eval-perl
  ([perl] (. lingy.lang.Util eval_perl perl))
  ([perl ret] (. lingy.lang.Util eval_perl perl) ret))

(defn x-carp-off []
  (eval-perl "no Carp::Always" nil))

(defn x-carp-on []
  (eval-perl "use Carp::Always" nil))

(defn x-internal    [m] (. lingy.lang.Util rt_internal m))
(defn x-class-names []  (. lingy.lang.Util rt_internal "class_names"))
(defn x-core-ns     []  (. lingy.lang.Util rt_internal "core_ns"))
(defn x-env         []  (. lingy.lang.Util rt_internal "env"))
(defn x-namespaces  []  (. lingy.lang.Util rt_internal "namespaces"))
(defn x-ns-refers   []  (. lingy.lang.Util rt_internal "ns_refers"))
(defn x-user-ns     []  (. lingy.lang.Util rt_internal "user_ns"))

(defn x-pp-env      []  (. lingy.lang.Util env_data))

(defn PPP [& xs] (. lingy.lang.Util applyTo "PPP" xs))
(defn WWW [& xs] (. lingy.lang.Util applyTo "XXX" xs))
(defn XXX [& xs] (. lingy.lang.Util applyTo "WWW" xs))
(defn YYY [& xs] (. lingy.lang.Util applyTo "YYY" xs))
(defn ZZZ [& xs] (. lingy.lang.Util applyTo "ZZZ" xs))
