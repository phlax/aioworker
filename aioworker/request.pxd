

cdef class JobRequest(object):
    cdef public app
    cdef public task    
    cdef public args
    cdef public kwargs    
