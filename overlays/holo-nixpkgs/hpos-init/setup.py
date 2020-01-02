from setuptools import setup

setup(
    name='hpos-init',
    packages=['hpos_init'],
    entry_points={
        'console_scripts': [
            'hpos-init=hpos_init.main:main'
        ],
    },
    install_requires=['hpos-seed']
)
