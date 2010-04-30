from sqlalchemy import *
from migrate import *

from sqlalchemy.ext.declarative import declarative_base
TableBase = declarative_base(bind=migrate_engine)


class FakeGTSBeta(TableBase):
    __tablename__ = 'fake_gts_beta'
    pid = Column(Integer, primary_key=True, autoincrement=True)
    pokemon_blob = Column(Binary(292), nullable=False)


def upgrade():
    FakeGTSBeta.__table__.drop()

def downgrade():
    FakeGTSBeta.__table__.create()
