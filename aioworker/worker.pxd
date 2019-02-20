
from .app cimport App
from .model cimport Config


cdef class Worker(object):
    cpdef public backend
    cpdef public loop
    cpdef public str prefix
    cpdef public dict subscribers
    cpdef public dict tasks
    cpdef public Config config

    cpdef public load(self, App app)
    cpdef public configure(self)
    cpdef public start(self)
    cpdef public stop(self)
    cpdef public _set_globals(self)
    cpdef public get_backend(self, App app)

cpdef public inline get_worker()
