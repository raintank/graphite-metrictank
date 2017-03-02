# coding: utf-8
from setuptools import setup

setup(
    name='graphite_metrictank',
    version='0.5',
    url='https://github.com/raintank/graphite_metrictank',
    license='apache2',
    author='Anthony Woods',
    author_email='awoods@raintank.io',
    description=('Metrictank backend plugin for graphite_api'),
    long_description='',
    py_modules=('graphite_metrictank',),
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
        'flask',
        'graphite_api',
        'simplejson'
    ),
    scripts=['bin/graphite_metrictank'],
)
