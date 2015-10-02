# coding: utf-8
from setuptools import setup

setup(
    name='graphite_raintank',
    version='0.1',
    url='https://github.com/raintank/graphite_raintank',
    license='apache2',
    author='Anthony Woods',
    author_email='awoods@raintank.io',
    description=('Raintank backend plugin for graphite_api'),
    long_description='',
    py_modules=('graphite_raintank',),
    zip_safe=False,
    include_package_data=True,
    platforms='any',
    classifiers=(
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'License :: OSI Approved :: BSD License',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Programming Language :: Python :: 2',
        'Topic :: System :: Monitoring',
    ),
    install_requires=(
        'requests',
        'elasticsearch',
        'flask',
        'graphite_api'
    ),
)