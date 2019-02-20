# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

from typing import Union

from .shared import tasks, workers

from cpython cimport bool
from .worker cimport Worker


cdef class task(object):

    __module__ = "aioworker.tasks"
    __qualname__ = "aioworker.tasks.task"

    def __cinit__(self, *args, **kwargs):
        if self._is_func(args) and not kwargs:
            self.fun_args = ()
            self.fun_kwargs = {}
            self.f = args[0]
            self.name = self.f.__name__
        else:
            self.fun_args = args
            self.fun_kwargs = kwargs
            self.name = (
                kwargs.get('name')
                or (args[0] if args else None))
        if self.name:
            tasks[self.name] = self

    cdef bool _is_func(self, tuple args):
        return bool(
            args
            and len(args) == 1
            and callable(args[0]))

    @property
    def worker(self) -> Union[None, Worker]:
        if workers:
            return workers[0]

    @property
    def returns(self):
        if "returns" in self.fun_kwargs:
            return self.fun_kwargs["returns"]
        if hasattr(self.f, "__annotations__"):
            if "return" in self.f.__annotations__:
                return self.f.__annotations__["return"]

    def __call__(self, *args, **kwargs) -> "task":
        if self._is_func(args):
            self.f = args[0]
            if not self.name:
                self.name = self.f.__name__
                tasks[self.name] = self
        return self

    # this is called from client code
    async def call(self, *args, **kwargs):
        return await self.worker.call(self, *args, **kwargs)


class py__task(task):
    pass
