from setuptools import setup

setup(
    name='hpos-admin',
    packages=['hpos_admin'],
    entry_points={
        'console_scripts': [
            'hpos-admin=hpos_admin.main:main'
        ],
    },
    install_requires=['hpos-config']
)
