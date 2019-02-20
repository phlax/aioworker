

class WorkerRequest(object):

    def __init__(self, app, session):
        self._session = session
        self.app = app

    @property
    def session(self):
        # lazily load the session from redis...
        return self._session

    @property
    def user(self):
        # lazily load the db user from the session
        pass

    async def send(self, message):
        pass


cdef class JobRequest(object):

    def __cinit__(self, app, task, args, kwargs):
        self.app = app
        self.task = task
        self.args = args
        self.kwargs = kwargs
