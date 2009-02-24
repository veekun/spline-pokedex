from sqlalchemy import Column, ForeignKey
from sqlalchemy.orm import relation
from sqlalchemy.types import Integer, Unicode

from spline.model.meta import TableBase

class Pokemon(TableBase):
    __tablename__ = 'pokemon'
    whoops these don't go here lol
    id = Column(Integer, primary_key=True)
    name = Column(Unicode(length=20), nullable=False)
