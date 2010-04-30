from sqlalchemy import Column, ForeignKey
from sqlalchemy.orm import relation
from sqlalchemy.types import Binary, Integer, Unicode

from spline.model.meta import TableBase

class GTSPokemon(TableBase):
    __tablename__ = 'gts_pokemon'
    id = Column(Integer, primary_key=True, autoincrement=True)
    pid = Column(Integer)
    pokemon_blob = Column(Binary(292), nullable=False)
