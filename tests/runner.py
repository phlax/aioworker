
import asyncio

from unittest.mock import (
    patch, MagicMock, PropertyMock)

import pytest

from aioworker import App, Backend, Config, Job, Worker, task
from aioworker.runner import Py__Runner as Runner
from aioworker.utils import pack_task

from .base import AsyncMock


def test_runner_signature():

    with pytest.raises(TypeError):
        Runner()


class _MockWorker(Worker):
    pass


def MockWorker(broker="BROKER", **kwargs):
    return _MockWorker(
        Config(
            concurrency=23,
            broker=broker,
            **kwargs))


class _MockBackend(Backend):

    def __init__(self, worker, app):
        self.worker = worker
        self.app = app
        self.prefix = "MOCK_PREFIX"


def MockBackend():
    return _MockBackend(MockWorker(), App())


@patch('aioworker.runner.Py__Runner.set_concurrency')
def test_runner(concurrent_m):
    Runner(MockBackend())
    assert [c[0] for c in concurrent_m.call_args_list] == [()]


@patch('aioworker.runner.asyncio.BoundedSemaphore')
def test_runner_set_concurrency(async_m):
    backend = MockBackend()
    runner = Runner(backend)
    async_m.reset_mock()
    backend.loop = "SPIRAL"
    runner.set_concurrency()
    assert (
        [list(c) for c in async_m.call_args_list]
        == [[(23,), {'loop': 'SPIRAL'}]])


async def _atask(self):
    return "done"


@patch('aioworker.runner.Py__Runner.set_concurrency')
@patch('aioworker.runner.Py__Runner.return_job_result')
def test_runner_on_job_complete(return_m, concurrent_m):
    runner = Runner(MockBackend())
    runner.jobs = MagicMock()
    runner.job_done = MagicMock()
    runner.concurrency_sem = MagicMock()
    atask = asyncio.get_event_loop().create_task(
        asyncio.coroutine(lambda: "done")())

    runner.jobs.pop.return_value.returns = True
    runner.on_job_complete("JOB", atask)
    assert (
        [c[0] for c in runner.jobs.pop.call_args_list]
        == [("JOB", )])
    assert (
        [c[0] for c in runner.concurrency_sem.release.call_args_list]
        == [()])
    assert (
        [c[0] for c in return_m.call_args_list]
        == [("JOB", atask)])

    runner.jobs.reset_mock()
    return_m.reset_mock()
    runner.concurrency_sem.reset_mock()
    runner.jobs.pop.return_value.returns = False
    runner.on_job_complete("JOB", atask)
    assert (
        [c[0] for c in runner.jobs.pop.call_args_list]
        == [("JOB", )])
    assert (
        [c[0] for c in runner.concurrency_sem.release.call_args_list]
        == [()])
    assert (
        [c[0] for c in return_m.call_args_list]
        == [])


@pytest.mark.asyncio
async def test_runner_return_job_result():
    backend = MockBackend()
    backend.publish = MagicMock()
    backend.loop = MagicMock()
    with patch('aioworker.runner.Py__Runner.set_concurrency'):
        runner = Runner(backend)
    atask = asyncio.get_event_loop().create_task(
        asyncio.coroutine(lambda: "done")())
    await atask
    runner.return_job_result("JOB", atask)
    assert (
        [c[0] for c in backend.publish.call_args_list]
        == [('JOB', {'result': 'done'})])
    assert (
        [c[0] for c in backend.loop.create_task.call_args_list]
        == [(backend.publish.return_value, )])


@patch('aioworker.runner.Py__Runner.set_concurrency')
def test_runner_parse_job(concurrent_m):
    backend = MockBackend()
    runner = Runner(backend)
    runner.get_task = MagicMock()
    runner.get_task.return_value = task(lambda: "done")
    result = runner.parse_job(
        ["SIGNAL",
         pack_task(
             "23", "FUN_TASK",
             ("x", "y"),
             {"some": "kwargs"})])
    assert (
        result
        == ("23", runner.get_task.return_value,
            ["x", "y"],
            {"some": "kwargs"}))
    assert (
        [c[0] for c in runner.get_task.call_args_list]
        == [('23', 'FUN_TASK')])


@pytest.mark.asyncio
async def test_runner_serve():
    backend = MockBackend()
    with patch('aioworker.runner.Py__Runner.set_concurrency'):
        runner = Runner(backend)
    runner.parse_job = MagicMock(
        return_value=(
            'ID', 'FUN',
            ['ARGS'],
            dict(kwargs='KWARGS')))
    tasks_m = PropertyMock(
        return_value=asyncio.coroutine(lambda: ["FOO", "BAR"])())
    type(runner).pending_tasks = tasks_m
    runner.concurrency_sem = AsyncMock()
    backend.loop = MagicMock()
    runner.jobs = MagicMock()
    runner.run = MagicMock()
    await runner.serve()
    assert (
        [c[0] for c in runner.parse_job.call_args_list]
        == [(['FOO', 'BAR'],)])
    assert (
        [c[0] for c in tasks_m.call_args_list]
        == [()])
    assert (
        [c[0] for c in runner.concurrency_sem.acquire.call_args_list]
        == [()])
    assert (
        [c[0] for c in runner.run.call_args_list]
        == [('FUN', 'ARGS')])
    assert (
        [c[1] for c in runner.run.call_args_list]
        == [{'kwargs': 'KWARGS'}])
    assert (
        [c[0] for c in runner.jobs.__setitem__.call_args_list]
        == [('ID', 'FUN')])
    assert (
        [c[0] for c in backend.loop.create_task.call_args_list]
        == [(runner.run.return_value,)])


@pytest.mark.asyncio
async def test_runner_serve_no_task():
    backend = MockBackend()
    with patch('aioworker.runner.Py__Runner.set_concurrency'):
        runner = Runner(backend)
    runner.parse_job = MagicMock(
        return_value=(
            'ID', None,
            ['ARGS'],
            dict(kwargs='KWARGS')))
    tasks_m = PropertyMock(
        return_value=asyncio.coroutine(lambda: ["FOO", "BAR"])())
    type(runner).pending_tasks = tasks_m
    runner.concurrency_sem = AsyncMock()
    backend.loop = MagicMock()
    runner.jobs = MagicMock()
    runner.run = MagicMock()
    await runner.serve()
    assert (
        [c[0] for c in runner.parse_job.call_args_list]
        == [(['FOO', 'BAR'],)])
    assert (
        [c[0] for c in tasks_m.call_args_list]
        == [()])
    assert (
        [c[0] for c in runner.concurrency_sem.acquire.call_args_list]
        == [])
    assert (
        [c[0] for c in runner.run.call_args_list]
        == [])
    assert (
        [c[1] for c in runner.run.call_args_list]
        == [])
    assert (
        [c[0] for c in runner.jobs.__setitem__.call_args_list]
        == [])
    assert (
        [c[0] for c in backend.loop.create_task.call_args_list]
        == [])


@pytest.mark.asyncio
async def test_runner_run():
    backend = MockBackend()
    with patch('aioworker.runner.Py__Runner.set_concurrency'):
        runner = Runner(backend)
    _task = task(lambda: "done")

    class MockJob(Job):
        async def __aenter__(self):
            return "RESULT"

        async def __aexit__(self, x, y, z):
            pass

    with patch('aioworker.runner.Py__Runner.get_job') as job_m:
        job_m.return_value = MockJob(backend.app, _task)
        result = await runner.run(_task, "ARG1", "ARG2", arg3=17, arg4=23)
        assert (
            [list(c) for c in job_m.call_args_list]
            == [[(backend.app,
                  _task,
                  ('ARG1', 'ARG2'),
                  {'arg3': 17, 'arg4': 23}), {}]])
        assert result == "RESULT"


_called = 0


@pytest.mark.asyncio
async def test_runner_start():
    backend = MockBackend()
    with patch('aioworker.runner.Py__Runner.set_concurrency'):
        runner = Runner(backend)

    with patch('aioworker.runner.Py__Runner.serve') as serve_m:

        async def _serve(*args, **kwargs):
            global _called
            if _called >= 2:
                raise TypeError(
                    "this func doesnt get called more than 3 times")
            _called += 1

        serve_m.side_effect = _serve
        try:
            await runner.start()
        except TypeError:
            pass
        assert (
            [c[0] for c in serve_m.call_args_list]
            == [(), (), ()])
