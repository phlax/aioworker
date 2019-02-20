
import asyncio

from .app cimport App
from .backend cimport Backend
from .job cimport Job
from .tasks cimport task


cdef class Runner:
    cdef public loop
    cdef task_prefix
    cdef public jobs
    cdef concurrency
    cdef public tasks
    cdef prefix
    cdef public app
    cdef public Backend backend
    cdef public concurrency_sem

    cpdef Job get_job(self, App app, task task, tuple args, dict kwargs)
    cpdef on_job_complete(self, str running_task, future: asyncio.tasks.Task)
    cpdef tuple parse_job(self, list incoming)
    cpdef task get_task(self, str taskid, str function)
    cpdef set_concurrency(self)
    cpdef return_job_result(self, str job, future: asyncio.Future)
