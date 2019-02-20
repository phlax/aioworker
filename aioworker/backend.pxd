
from .app cimport App
from .model cimport Config
from .runner cimport Runner
from .subscriber cimport Subscriber
from .tasks cimport task
from .worker cimport Worker


cdef class Backend:
    cdef public App app
    cdef public loop
    cdef public tasks
    cdef public Subscriber subscriber
    cdef public Runner runner
    cdef public concurrency
    cdef public str task_event
    cdef public Config config
    cdef public Worker worker

    cpdef str get_task_event(self)
    cpdef connect(self)
    cpdef publish(self, str channel, dict msg)
    cpdef push_task(self, task task, tuple args, dict kwargs)
