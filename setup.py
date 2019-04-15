# -*- coding: utf-8 -*-

import sys
from setuptools import setup, find_packages

from Cython.Build import cythonize


if sys.version_info < (3, 5,):
    raise RuntimeError("aioworker requires Python 3.5.0+")


install_requires = [
    "aioredis",
    "click",
    "colorlog",
    "cython",
    "marshmallow>=3.0.0rc4",
    "msgpack-python",
    "python-rapidjson",
    "umsgpack",
    "uvloop"]
extras_require = {}
extras_require['test'] = [
    "codecov",
    "coverage",
    "cython",
    "flake8",
    "pytest",
    "pytest-asyncio",
    "pytest-coverage",
    "pytest-mock"],


setup(
    name='aioworker',
    version='0.1.2',
    install_requires=install_requires,
    extras_require=extras_require,
    url='https://github.com/phlax/aioworker',
    license='GPL3',
    author='Ryan Northey',
    author_email='ryan@synca.io',
    packages=find_packages(),
    include_package_data=True,
    description='An obedient worker',
    long_description='Runs tasks async',
    classifiers=[
        'Environment :: Console',
        'License :: OSI Approved :: GPL3 License',
        'Operating System :: MacOS',
        'Operating System :: Microsoft :: Windows',
        'Operating System :: POSIX',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
    ],
    entry_points={'console_scripts': [
        'aioworker = aioworker.cli:cli',
    ]},
    ext_modules=(
        cythonize("aioworker/*.pyx", annotate=True)
        + cythonize("aioworker/backends/redis/*.pyx", annotate=True)))
