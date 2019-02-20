
from unittest.mock import patch, MagicMock

import pytest

from aioworker.job import Py__Job as Job
from aioworker import App, JobRequest, task

from .base import AsyncMock


def test_job_signature():

    with pytest.raises(TypeError):
        Job()


@patch("aioworker.job.Py__Job.create_request")
def test_job(request_m):
    app = App()

    @task
    def do_foo(request, *args, **kwargs):
        pass

    request_m.return_value = JobRequest(app, task, (), {})
    job = Job(app, do_foo)

    assert (
        [c[0] for c in request_m.call_args_list]
        == [(app, do_foo, (), {})])
    assert job.request == request_m.return_value

    request_m.reset_mock()
    job = Job(app, do_foo, "x", "y", z=23)
    assert job.request == request_m.return_value
    assert (
        [c[0] for c in request_m.call_args_list]
        == [(app, do_foo, ('x', 'y'), {'z': 23})])


@pytest.mark.asyncio
async def test_job_context():
    app = App()

    @task
    def do_foo(request, *args, **kwargs):
        pass

    job = Job(app, do_foo, "x", "y", z=23)
    job.request = MagicMock()
    job.request.app.on_job_request = AsyncMock()
    job.request.task.f = AsyncMock(return_value="RESULT")
    job.request.app.on_job_done = AsyncMock()
    job.request.args = (7, 23)
    job.request.kwargs = {"x": "y"}
    with patch("aioworker.job.time.time", return_value=1337) as time_m:
        async with job as result:
            assert result == job.request.task.f.return_value
            assert (
                [c[0] for c in job.request.task.f.call_args_list]
                == [(job.request, 7, 23)])
            assert (
                [c[1] for c in job.request.task.f.call_args_list]
                == [{'x': 'y'}])
            assert time_m.call_args_list == [()]
            assert job._start == 1337
            assert (
                [c[0] for c in job.request.app.on_job_request.call_args_list]
                == [(job.request,)])
            assert (
                [c[0] for c in job.request.app.on_job_done.call_args_list]
                == [])
            time_m.return_value = 13
        assert (
            [c[0] for c in job.request.app.on_job_done.call_args_list]
            == [(job.request, 'RESULT', -1324.0)])
