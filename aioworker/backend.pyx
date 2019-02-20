# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

import asyncio
import uuid

from .app cimport App
from .tasks cimport task
from .worker cimport Worker


cdef class Backend(object):

    def __cinit__(self, Worker worker, App app):
        self.worker = worker
        self.config = worker.config
        self.app = app
        self.loop = worker.loop

    def __init__(self, Worker worker, App app):
        self.connect()

    cpdef connect(self):
        self.task_event = self.get_task_event()
        self.subscriber = self.get_subscriber()
        if self.config.is_worker:
            self.runner = self.get_runner()

    cpdef str get_task_event(self):
        return "{}:{}".format(self.config.prefix, "tasks")

    cpdef publish(self, str channel, dict msg):
        return self.subscriber.publish(channel, msg)

    cpdef push_task(self, task task, tuple args, dict kwargs):
        return self.subscriber.push_task(
            uuid.uuid4().hex,
            task, *args, **kwargs)

    async def stop(self):
        await self.app.on_exit()
        for t in asyncio.Task.all_tasks(loop=self.loop):
            t.cancel()
        self.loop.stop()

    async def start(self):
        await self.app.on_start()
        if self.config.is_worker:
            self.loop.create_task(self.runner.start())
        self.loop.create_task(self.subscriber.start())

    def get_subscriber(self):
        raise NotImplementedError

    def get_runner(self):
        raise NotImplementedError



class Py__Backend(Backend):
    pass
