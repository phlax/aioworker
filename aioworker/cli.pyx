#!/usr/bin/env python3

import click
import logging

from .console import Console
from .options import global_options


log = logging.getLogger('aioworker')


@global_options()
@click.pass_context
def clinot(ctx, **kwargs):
    ctx.obj = kwargs


@click.command()
@click.option('--worker', '-w', 'worker')
@click.option('-a', '--agent', 'agent')
@click.option('-b', '--broker', 'broker')
@click.option('--loglevel', '-l', 'log_level')
@click.option('-c', '--config', 'config_file')
@click.pass_context
def cli(ctx, **kwargs):
    Console(ctx.obj, **kwargs).run()
