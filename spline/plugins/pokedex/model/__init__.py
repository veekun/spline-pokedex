from sqlalchemy import Column, ForeignKey
from sqlalchemy.orm import relation
from sqlalchemy.types import Binary, Integer, Unicode

from spline.model.meta import TableBase

class FakeGTSBeta(TableBase):
    __tablename__ = 'fake_gts_beta'
    pid = Column(Integer, primary_key=True, autoincrement=True)
    pokemon_blob = Column(Binary(292), nullable=False)
