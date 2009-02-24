from setuptools import setup, find_packages
setup(
    name = 'spline-pokedex',
    version = '0.1',
    packages = find_packages(),
    
    install_requires = ['spline', 'pokedex'],

    include_package_data = True,

    zip_safe = False,

    entry_points = {'spline.plugins': 'pokedex = spline.plugins.pokedex:PokedexPlugin'},

    namespace_packages = ['spline', 'spline.plugins'],
)
