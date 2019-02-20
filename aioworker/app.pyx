# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True


cdef class App(object):

    async def on_start(self):
        pass

    async def on_exit(self):
        pass

    async def on_job_request(self, task, request, *args, **kwargs):
        pass

    async def on_job_done(self):
        pass
