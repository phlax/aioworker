
from cpython cimport bool

from .app cimport App
from .model cimport Config
from .worker cimport Worker


cdef class Console(object):
    cdef public dict shared_config
    cdef public dict kwargs
    cdef public Config config
    cdef public App application
    cdef public Worker worker
    cdef public loop
    cdef public schema

    cpdef configure(self)
    cpdef str make_summary(self)
    cpdef run(self)
    cpdef _on_start(self)
    cpdef App get_application(self)
    cpdef Worker get_worker(self)
    cpdef set_logging(self)
    cpdef Config make_config(self)
    cpdef get_schema(self)
    cpdef setup_loop(self)
    cpdef bool should_set_loop_policy(self)
