from sqlalchemy import *
from migrate import *

from sqlalchemy.ext.declarative import declarative_base
TableBase = declarative_base(bind=migrate_engine)


class GTSPokemon(TableBase):
    __tablename__ = 'gts_pokemon'
    id = Column(Integer, primary_key=True, autoincrement=True)
    pid = Column(Integer)
    pokemon_blob = Column(Binary(292), nullable=False)


def upgrade():
    GTSPokemon.__table__.create()

def downgrade():
    GTSPokemon.__table__.drop()
