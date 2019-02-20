# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

import time

from .app cimport App
from .request cimport JobRequest
from .tasks cimport task


cdef class Job(object):

    def __init__(self, App app, task task, *args, **kwargs):
        self.request = self.create_request(app, task, args, kwargs)

    cpdef JobRequest create_request(
            self, App app, task task, tuple args, dict kwargs):
        return JobRequest(app, task, args, kwargs)

    async def __aenter__(self):
        self._start = time.time()
        await self.request.app.on_job_request(self.request)
        self.result = await self.request.task.f(
            self.request,
            *self.request.args,
            **self.request.kwargs)
        return self.result

    async def __aexit__(self, x, y, z):
        await self.request.app.on_job_done(
            self.request,
            self.result,
            time.time() - self._start)


class Py__Job(Job):
    pass
