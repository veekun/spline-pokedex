from setuptools import setup, find_packages
setup(
    name = 'spline-gts',
    version = '0.1',
    packages = find_packages(),

    install_requires = [
        'spline',
        'spline-users',
        'pokedex',
    ],

    include_package_data = True,

    zip_safe = False,

    entry_points = {'spline.plugins': 'gts = splinext.gts:GTSPlugin'},

    namespace_packages = ['splinext'],
)
