
    
cdef class Subscriber:
    cdef public _loop_subscribers
    cdef prefix
    cdef public dict running_tasks
    cdef topics_subscribers
    cdef subscriber_ready
    cdef _launcher_topics
    
    cpdef _make_tasks_done_subscriber(self, task_id, future)
