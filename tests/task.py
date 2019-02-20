
from unittest.mock import patch

import pytest

from aioworker.tasks import py__task as task


@patch('aioworker.tasks.tasks')
@patch('aioworker.tasks.workers')
def test_task(workers_m, tasks_m, mocker):

    @task
    def add(x, y):
        return x + y

    workers_m.__getitem__.return_value = None
    assert add.worker is None

    worker_m = mocker.MagicMock()
    workers_m.__getitem__.return_value = worker_m
    assert add.worker is worker_m
    assert (
        [c[0] for c in tasks_m.__setitem__.call_args_list]
        == [('add', add)])
    assert add.f(6, 7) == 13


@patch('aioworker.tasks.tasks')
@patch('aioworker.tasks.workers')
def test_task_name_kwargs(workers_m, tasks_m, mocker):

    @task(name="plus")
    def add(x, y):
        return x + y

    worker_m = mocker.MagicMock()
    workers_m.__getitem__.return_value = worker_m
    assert add.worker is worker_m
    assert (
        [c[0] for c in tasks_m.__setitem__.call_args_list]
        == [('plus', add)])
    assert add.f(6, 7) == 13


@patch('aioworker.tasks.tasks')
@patch('aioworker.tasks.workers')
def test_task_name_arg(workers_m, tasks_m, mocker):

    @task("plus")
    def add(x, y):
        return x + y

    worker_m = mocker.MagicMock()
    workers_m.__getitem__.return_value = worker_m
    assert add.worker is worker_m
    assert (
        [c[0] for c in tasks_m.__setitem__.call_args_list]
        == [('plus', add)])
    assert add.f(6, 7) == 13


@patch('aioworker.tasks.tasks')
@patch('aioworker.tasks.workers')
def test_task_name_empty_arg(workers_m, tasks_m, mocker):

    @task()
    def add(x, y):
        return x + y

    workers_m.__getitem__.return_value = None
    assert add.worker is None

    worker_m = mocker.MagicMock()
    workers_m.__getitem__.return_value = worker_m
    assert add.worker is worker_m
    assert (
        [c[0] for c in tasks_m.__setitem__.call_args_list]
        == [('add', add)])
    assert add.f(6, 7) == 13


@pytest.mark.asyncio
async def test_task_returns():
    with patch('aioworker.tasks.tasks'):
        with patch('aioworker.tasks.workers'):
            await _fun_tests()


async def _fun_tests():
    @task
    def fun(x):
        return x
    assert not fun.returns

    @task
    def fun(x) -> dict:
        return x
    assert fun.returns == dict

    @task
    def fun(x) -> list:
        return x
    assert fun.returns == list

    @task()
    def fun(x):
        return x
    assert not fun.returns

    @task()
    def fun(x) -> dict:
        return x
    assert fun.returns == dict

    @task(returns=list)
    def fun(x):
        return x
    assert fun.returns == list

    @task(returns=dict)
    def fun(x) -> list:
        return x
    assert fun.returns == dict

    # async
    @task
    async def fun(x):
        return x
    assert not fun.returns

    @task
    async def fun(x) -> dict:
        return x
    assert fun.returns == dict

    @task
    async def fun(x) -> list:
        return x
    assert fun.returns == list

    @task()
    async def fun(x):
        return x
    assert not fun.returns

    @task()
    async def fun(x) -> dict:
        return x
    assert fun.returns == dict

    @task(returns=list)
    async def fun(x):
        return x
    assert fun.returns == list

    @task(returns=dict)
    async def fun(x) -> list:
        return x
    assert fun.returns == dict
