# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

import asyncio
import functools
import importlib
import logging
import uuid

from .app cimport App
from .backend cimport Backend
from .job cimport Job
from .tasks cimport task
from .utils cimport pack, unpack_task


log = logging.getLogger("aioworker")


cdef class Runner(object):

    def __cinit__(self, Backend backend):
        self.backend = backend
        self.jobs = dict()

    def __init__(self, Backend backend):
        self.set_concurrency()
        self.tasks = backend.worker.tasks

    cpdef on_job_complete(self, str job, future: asyncio.tasks.Task):
        self.concurrency_sem.release()
        if self.jobs.pop(job).returns:
            self.return_job_result(job, future)

    cpdef tuple parse_job(self, list incoming):
        (taskid, function,
         args, kwargs) = unpack_task(incoming[1])
        return taskid, self.get_task(taskid, function), args, kwargs

    cpdef return_job_result(self, str job, future: asyncio.Future):
        self.backend.loop.create_task(self.backend.publish(job, dict(result=future.result())))

    cpdef set_concurrency(self):
        self.concurrency_sem = (
            asyncio.BoundedSemaphore(
                self.backend.config.concurrency,
                loop=self.backend.loop))

    cpdef task get_task(self, str taskid, str function):
        try:
            if type(taskid) is int:
                taskid = str(taskid)
            uuid.UUID(taskid, version=4)
        except ValueError:
            log.error(
                "Task ID '{}' has not valid UUID4 format".format(taskid))
            return
        try:
            return self.tasks[function]
        except KeyError:
            log.warning(
                "No local task with name '{}'".format(function))

    cpdef Job get_job(self, App app, task task, tuple args, dict kwargs):
        return Job(app, task, *args, **kwargs)

    async def run(self, task task, *args, **kwargs) -> object:
        async with self.get_job(self.backend.app, task, args, kwargs) as result:
            return result

    async def serve(self) -> None:
        taskid, task, args, kwargs = self.parse_job(
            await self.pending_tasks)
        if not task:
            return
        await self.concurrency_sem.acquire()
        job = self.backend.loop.create_task(
            self.run(
                task,
                *args,
                **kwargs))
        job.add_done_callback(
            functools.partial(self.on_job_complete, taskid))
        self.jobs[taskid] = task

    async def start(self) -> None:
        while True:
            await self.serve()

    def pending_tasks(self):
        pass

    async def has_pending_tasks(self):
        pass


class Py__Runner(Runner):
    pass
