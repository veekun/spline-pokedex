# encoding: utf8
from __future__ import absolute_import

from collections import defaultdict
import re

import pokedex.db.tables as t
from spline.lib.forms import QueryCheckboxSelectMultipleField
from splinext.pokedex import db
from splinext.pokedex.forms import PokedexLookupField

from sqlalchemy.orm import aliased, joinedload_all
from sqlalchemy.sql import and_, or_, not_, func

from sqlalchemy.orm import configure_mappers; configure_mappers()

class XXX_ARGUMENT_ENTITY_SESSION_REMOVE_ME(object):
    @classmethod
    def query(self, x):
        return db.pokedex_session.query(x)

def relationship_target(rel):
    return rel.property.argument

class Locus(object):
    def __init__(self, table, properties):
        self.table = table
        self.properties = properties

        self.prop_index = dict((prop.identifier, prop) for prop in properties)


class Argument(object):
    # TODO
    argname = None

    def form_field_name(self, prop_identifier, arg_name):
        if arg_name is None:
            return prop_identifier
        else:
            return "{0}.{1}".format(prop_identifier, arg_name)

    def __init__(self):
        pass

class TextArgument(Argument):
    def form_field(self, name):
        return fields.TextField(name)

    def render2(self, prop, arg_name, renderer):
        renderer.argument_text(
            name=self.form_field_name(prop.identifier, arg_name),
        )

class RangeArgument(TextArgument):
    only_one = True

class StringArgument(TextArgument):
    # XXX allow multiple of these?
    only_one = True

class OneOfArgument(Argument):
    only_one = True
    def __init__(self, *choices):
        # XXX first is default?
        self.choices = choices

    def render2(self, prop, arg_name, renderer):
        return renderer.argument_set_operation(
            name=self.form_field_name(prop.identifier, arg_name),
            choices=self.choices,
        )


class EntityArgument(Argument):
    def form_field(self, name):
        table = self.table
        # TODO get_label needs to be field-specific, alas
        return QueryCheckboxSelectMultipleField(
            name,
            query_factory=lambda: db.pokedex_session.query(table),
            get_pk=lambda row: row.identifier,
            get_label=lambda row: row.name)

    def __init__(self, *args, **kwargs):
        self.table = kwargs.pop('table')
        super(EntityArgument, self).__init__(*args, **kwargs)

    # metadata: any value vs specific value
    # metadata: once or n times
    def render2(self, prop, arg_name, renderer):
        return renderer.argument_entity(
            name=self.form_field_name(prop.identifier, arg_name),
            # XXX type: skip bad ones
            choices=map(lambda x: x.identifier, XXX_ARGUMENT_ENTITY_SESSION_REMOVE_ME.query(self.table)),
            label_factory=getattr(renderer, 'entity_' + self.table.__tablename__),  # XXX XXX  D:
        )

class SetOperationArgument(Argument):
    def render2(self, prop, arg_name, renderer):
        # XXX even this is too complex.  this stuff should be declarative, man.
        # XXX is there any point to Argument with this?
        # XXX default here?
        return renderer.argument_set_operation(
            name=self.form_field_name(prop.identifier, arg_name),
            choices=['any', 'all'],
        )






















class Property(object):
    def __init__(self, identifier, name, join=(), column=None, crossjoin=None, backref=None, subjoin=(), decorations=(), discriminator=None):
        self.identifier = identifier
        self.name = name

        self.join = join
        self.column = column
        # TODO clarify (diagram?) exactly how these all fit together, and enforce it with code
        self.crossjoin = crossjoin
        self.backref = backref
        self.subjoin = subjoin
        self.decorations = decorations
        self.discriminator = discriminator

    def arguments2(self):
        # XXX use me for validating incoming data?
        raise NotImplementedError

    def construct_subquery(self):
        """Return a subquery for querying stuff or whatever."""
        # XXX ARGH SESSION
        # Need a session that, ultimately, returns a locus id
        q = db.pokedex_session.query(self.backref)

        # Join along the join chain
        for rel in self.subjoin:
            q = q.join(rel)

        # OK done I guess
        return q

    def extract_data(self, row):
        """Get data out of a result row.  This common method traverses
        self.join for you; implement `_extract_data` to do something more
        interesting with the relationship at the end of the join chain.
        """
        final_rel = row
        for join in self.join:
            final_rel = apply_relationship(join, final_rel)

        if self.crossjoin:
            final_rel = apply_relationship(self.crossjoin, final_rel)

        # final_rel is now the thing that self.column is relative to.  Let
        # subclasses do final processing
        # XXX this is a terrible variable name
        return self._extract_data(final_rel)

    def _extract_data(self, final_rel):
        return apply_relationship(self.column, final_rel)


    def loading_options(self):
        """Returns SQLAlchemy query loading options for eager-loading this
        property's data.
        """
        if not self.join:
            return ()

        # XXX wrong; should be contains_eager.  except when it's not!
        return [joinedload_all(*self.join)]


class ScalarNumberProperty(Property):
    def arguments2(self):
        return {
            None: RangeArgument(),
        }

    def apply_criterion(self, kw):
        if not kw.get(None):
            return

        # XXX actually...............something else should make sure there's just one
        assert len(kw[None]) == 1
        # XXX actually!!  someone else should also do the actual work here.
        return self.column == int(kw[None][0])


def ilike(column, string):
    # XXX document me and put me somewhere sharedy
    string = string.lower()

    # If there are no wildcards, assume it's a partial match
    if '*' not in string and '?' not in string:
        string = u"*{0}*".format(string)

    # LIKE wildcards should be escaped: % -> ^%, _ -> ^_, ^ -> ^^
    # Our wildcards should be changed: * -> %, ? -> _
    # And all at once.
    translations = {
        '%': u'^%',     '_': u'^_',     '^': u'^^',
        '*': u'%',      '?': u'_',
    }
    string = re.sub(ur'([%_*?^])',
                    lambda match: translations[match.group(0)],
                    string)

    return func.lower(column).like(string, escape='^')

class ScalarStringProperty(Property):
    def arguments2(self):
        return {
            None: TextArgument(),
            'match-type': OneOfArgument(u'substring', u'wildcard', u'exact'),
        }

    def apply_criterion(self, kw):
        if not kw.get(None):
            return

        # XXX actually...............something else should make sure there's just one
        assert len(kw[None]) == 1
        # XXX actually!!  someone else should also do the actual work here??

        pattern = kw[None][0]
        match_type = kw.get('match-type', ('substring',))[0]  # XXX assert not empty whatever
        if match_type == u'substring':
            return ilike(self.column, pattern)
        elif match_type == u'wildcard':
            return ilike(self.column, pattern)
        elif match_type == u'exact':
            return func.lower(self.column) == pattern.lower()
        else:
            raise ValueError  # XXX improve exceptions

class IdentifierProperty(Property):
    def arguments2(self):
        return {
            None: TextArgument(),  # XXX multiple?
        }

    def apply_criterion(self, kw):
        if not kw.get(None):
            return

        # XXX actually...............something else should make sure there's just one
        assert len(kw[None]) == 1
        return self.column == kw[None][0]

class EntityScalarProperty(Property):
    def arguments2(self):
        return {
            None: EntityArgument(table=relationship_target(self.crossjoin or self.join[-1])),  # XXX multiple?
        }

    def apply_criterion(self, kw):
        if not kw.get(None):
            return

        # XXX should verify that these are legit identifiers
        return self.column.in_(kw[None])

    # XXX match-type here?

class EntityListProperty(Property):
    def arguments2(self):
        return {
            None: EntityArgument(table=relationship_target(self.crossjoin or self.join[-1])),  # XXX multiple?
            'match-type': OneOfArgument(u'any', u'none', u'all'),  # XXX only one blah blah
        }

    def apply_criterion(self, kw):
        if not kw.get(None):
            return

        # XXX should verify that these are legit identifiers
        # XXX XXX crossjoin needs to be made relative to the parent alias thing


        candidates = kw[None]
        # any; all; none; exact; ???
        match_type = kw.get('match-type', ('any',))[0]
        if match_type == u'any':
            return self.crossjoin.any(self.column.in_(candidates))
        elif match_type == u'none':
            return not_(self.crossjoin.any(self.column.in_(candidates)))
        elif match_type == u'all':
            # TODO probably a nicer way to write this
            return and_(*(
                self.crossjoin.any(self.column == candidate)
                for candidate in candidates
            ))
        else:
            # XXX error handling
            raise ValueError

    def loading_options(self):
        """Returns SQLAlchemy query loading options for eager-loading this
        property's data.
        """
        # TODO
        # XXX needs ALL the aliases again, whoops
        # XXX needs to do custom post-loading for many-to-many
        return []

    def _extract_data(self, final_rel):
        # The final_rel should now actually be a list of subentities
        return [apply_relationship(self.column, subentity) for subentity in final_rel]

# XXX this name kinda sucks
class DecoratedEntityListProperty(Property):
    def arguments2(self):
        return {
            None: TextArgument(),  # XXX multiple
            # XXX slot, hidden, lookup, oh lord
        }

    def apply_criterion(self, kw):
        identifiers = []

        if not kw.get(None):
            # XXX fix this to work more often.  i might want to find all pokemon with a hidden ability, say.
            return

        # XXX this should be using match-type

        # XXX should verify that these are legit identifiers
        if None in kw:
            identifiers = kw[None]

        # XXX don't do this; make lookup a separate service and do it...  separately
        if 'lookup' in kw:
            results = db.pokedex_lookup.lookup(kw['lookup'][0])
            assert results, "dunno what that name is"
            identifiers.extend(result.object.identifier for result in results)

        subq = self.construct_subquery()
        subq = subq.filter(self.column.in_(identifiers))

        # XXX this is ability-specific  :(
        if 'slot' in kw:
            clauses = {
                '1': t.PokemonAbility.slot == 1,
                '2': t.PokemonAbility.slot == 2,
                'hidden': t.PokemonAbility.is_dream == True,
            }
            # XXX validate this list, sigh
            subq = subq.filter(or_(
                *(clauses[key] for key in kw['slot'])
            ))

        return t.Pokemon.id.in_(subq.subquery())

    def loading_options(self):
        """Returns SQLAlchemy query loading options for eager-loading this
        property's data.
        """
        # TODO
        # XXX needs ALL the aliases again, whoops
        # XXX needs to do custom post-loading for many-to-many
        return []

    def _extract_data(self, final_rel):
        # final_rel should now actually be a list of PokemonAbility things
        results = []
        for row in final_rel:
            result = {}
            for key, rel_path in self.decorations.items():
                point = row
                for rel in rel_path[:-1]:
                    point = apply_relationship(rel, point)

                result[key] = apply_relationship(rel_path[-1], point)

                # XXX aughuguhguhg
                if key == 'slot' and point.is_dream:
                    result[key] = u'hidden'

            results.append(result)

        return results


class EvolutionProperty(Property):
    """Evolution is weird and complex."""
    # XXX explain just how weird and complex it really is

    def apply_criterion(self, kw):
        identifiers = []
        # XXX general note: check for bogus kw

        # XXX should verify that these are legit identifiers
        if None in kw:
            identifiers = kw[None]

        # Create a big ol' subquery to check for includedness.
        # TODO do we care that this is pokemon-specific?  no.
        # XXX session
        me_species = aliased(t.PokemonSpecies)
        parent_species = aliased(t.PokemonSpecies)
        grandparent_species = aliased(t.PokemonSpecies)

        # TODO do joins need to be minimized here?
        subq = (db.pokedex_session.query(me_species.id)
            .outerjoin(parent_species, me_species.parent_species)
            .outerjoin(grandparent_species, parent_species.parent_species)
        )

        # Get all ye data
        stages = set(kw.get('stage', []))
        positions = set(kw.get('position', []))
        forks = set(kw.get('fork', []))

        if not stages and not positions and not forks:
            return None

        ### Stage
        stage_clauses = []

        if 'baby' in stages:
            # Baby: easy.
            stage_clauses.append(me_species.is_baby)

        if 'basic' in stages:
            # Basic: either an orphan that's not a baby, or has a baby parent
            stage_clauses.append(
                ~ me_species.is_baby
                & ((parent_species.id == None) | parent_species.is_baby)
            )

        if 'stage1' in stages:
            # Stage 1: has a non-baby parent, and a baby-or-missing grandparent
            stage_clauses.append(
                ~ parent_species.is_baby
                & ((grandparent_species.id == None) | grandparent_species.is_baby)
            )

        if 'stage2' in stages:
            # Stage 2: has a non-baby grandparent
            stage_clauses.append(grandparent_species.is_baby)

        if stage_clauses:
            subq = subq.filter(or_(*stage_clauses))

        ### Position (relative to the chain)
        pos_clauses = []

        any_parent = (parent_species.id != None)
        any_children = me_species.child_species.any()
        # TODO it would be neat to do some boolean simplification here, to avoid multiple EXISTSes
        # ...i imagine that "first or middle" is far more common than "middle or only"

        if 'first' in positions:
            pos_clauses.append(~ any_parent & any_children)

        if 'middle' in positions:
            pos_clauses.append(any_parent & any_children)

        if 'last' in positions:
            pos_clauses.append(any_parent & ~ any_children)

        if 'only' in positions:
            pos_clauses.append(~ any_parent & ~ any_children)

        if pos_clauses:
            subq = subq.filter(or_(*pos_clauses))

        ### Fork this
        fork_clauses = []

        has_childrens = (
            db.pokedex_session.query(func.count(t.PokemonSpecies.id))
                .correlate(me_species)
                .filter(t.PokemonSpecies.evolves_from_species_id == me_species.id)
                .as_scalar()
            > 1)
        has_siblings = (
            db.pokedex_session.query(func.count(t.PokemonSpecies.id))
                .correlate(me_species)
                .filter(t.PokemonSpecies.evolves_from_species_id == me_species.evolves_from_species_id)
                .as_scalar()
            > 1)
        if 'branching' in forks:
            fork_clauses.append(has_childrens)

        if 'branched' in forks:
            fork_clauses.append(has_siblings)

        if 'linear' in forks:
            fork_clauses.append(~ has_childrens & ~ has_siblings)

        if fork_clauses:
            subq = subq.filter(or_(*fork_clauses))


        # TODO this will cause a lot of useless effort if someone passes a single bogus datum
        return t.Pokemon.species_id.in_(subq.subquery())

    def loading_options(self):
        """Returns SQLAlchemy query loading options for eager-loading this
        property's data.
        """
        # TODO
        # XXX needs ALL the aliases again, whoops  # wait no it doesn't?
        # XXX needs to do custom post-loading for many-to-many
        return []

    def _extract_data(self, final_rel):
        ret = dict(
            stage=None,
            position=None,
            fork=None,
        )
        species = final_rel.species

        if species.is_baby:
            ret['stage'] = u'baby'
        elif not species.parent_species:
            ret['stage'] = u'basic'
        elif species.parent_species.is_baby or not species.parent_species.parent_species:
            ret['stage'] = u'stage1'
        else:
            ret['stage'] = u'stage2'

        if species.parent_species:
            if species.child_species:
                ret['position'] = u'middle'
            else:
                ret['position'] = u'last'
        else:
            if species.child_species:
                ret['position'] = u'first'
            else:
                ret['position'] = u'only'

        # nb: So far, no evolution chain branches twice.  If this changed, the
        # following will stop making sense.
        if len(species.child_species) > 1:
            ret['fork'] = 'branching'
        elif len(species.parent_species.child_species) > 1:
            ret['fork'] = 'branched'
        else:
            ret['fork'] = 'linear'

        return ret

class PokemonMoveProperty(Property):
    """Movelists get their own special kind of property, due to doing too
    much...
    """

    def apply_criterion(self, kw):
        identifiers = []

        # XXX should verify that these are legit identifiers
        if None in kw:
            identifiers = kw[None]

        subq = self.construct_subquery()
        subq = subq.filter(self.column.in_(identifiers))

        # XXX verify identifiers
        # XXX what should this default to?  current games like __version__, or everything?
        if 'version' in kw:
            subq = (subq
                .join(t.PokemonMove.version_group)
                .filter(t.VersionGroup.versions.any(t.Version.identifier.in_(kw['version'])))
            )

        # XXX verify identifiers
        # XXX what should this default to??
        # XXX i think this needs a thing for checking for parents moves too
        if 'method' in kw:
            subq = subq.filter(t.PokemonMove.method.has(
                t.PokemonMoveMethod.identifier.in_(kw['method'])))
            

        return t.Pokemon.id.in_(subq.subquery())

    def loading_options(self):
        """Returns SQLAlchemy query loading options for eager-loading this
        property's data.
        """
        # TODO
        # XXX needs ALL the aliases again, whoops
        # XXX needs to do custom post-loading for many-to-many
        return []

    def _extract_data(self, final_rel):
        # final_rel should now actually be a list of PokemonMove things
        # results will be a nested dict of version => method => [level:, move:]
        from collections import defaultdict
        results = {}
        for row in final_rel:
            result = {}

            for key, rel_path in self.decorations.items():
                point = row
                for rel in rel_path[:-1]:
                    point = apply_relationship(rel, point)

                result[key] = apply_relationship(rel_path[-1], point)

            # XXX egh
            for version in row.version_group.versions:
                results.setdefault(version.identifier, {}).setdefault(row.method.identifier, []).append(result)

        # XXX eggggh
        return {'white': {'level-up': results['white']['level-up'] }}

        return results


class EntityMapProperty(Property):
    def apply_criterion(self, kw):
        # XXX do something more delicate here
        assert None not in kw

        if not kw:
            return None

        # XXX should verify that these are legit identifiers
        operands = []
        for stat_identifier, values in kw.iteritems():
            # XXX get this crap outta here, especially the Pokemon.id bit
            # XXX fix the subjoins
            subq = db.pokedex_session.query(self.backref) \
                .join(self.subjoin[0]) \
                .filter(self.discriminator == stat_identifier) \
                .filter(self.column.in_(values)) \
                .subquery()
            operands.append(t.Pokemon.id.in_(subq))

        return and_(*operands)

    def loading_options(self):
        """Returns SQLAlchemy query loading options for eager-loading this
        property's data.
        """
        # TODO
        # XXX needs ALL the aliases again, whoops
        # XXX needs to do custom post-loading for many-to-many
        return []

    def _extract_data(self, final_rel):
        # final_rel should now actually be a list of PokemonStat things
        # TODO apply subjoin here too?
        # TODO how do we know where the discriminator goes if we use subjoin?
        # XXX this is pretty awful and probably not how subjoin ought to work
        return dict(
            (apply_relationship(self.discriminator, apply_relationship(self.subjoin[0], row)), apply_relationship(self.column, row))
            for row in final_rel
        )

pokemon_locus = Locus(t.Pokemon, [
    ScalarNumberProperty(u'id', u'ID', column=t.Pokemon.id),
    IdentifierProperty(u'identifier', u'Identifier', join=(t.Pokemon.species,), column=t.PokemonSpecies.identifier),
    ScalarStringProperty(u'name', u'Name', join=(t.Pokemon.species, t.PokemonSpecies.names_local,), column=t.PokemonSpecies.names_table.name),
    ScalarStringProperty(u'genus', u'Genus', join=(t.Pokemon.species, t.PokemonSpecies.names_local,), column=t.PokemonSpecies.names_table.genus),
    EntityScalarProperty(u'color', u'Color', join=(t.Pokemon.species, t.PokemonSpecies.color,), column=t.PokemonColor.identifier),
    EntityScalarProperty(u'growth-rate', u'Growth rate', join=(t.Pokemon.species, t.PokemonSpecies.growth_rate), column=t.GrowthRate.identifier),
    EntityScalarProperty(u'habitat', u'Habitat', join=(t.Pokemon.species, t.PokemonSpecies.habitat,), column=t.PokemonHabitat.identifier),  # XXX nullable
    EntityScalarProperty(u'shape', u'Shape', join=(t.Pokemon.species, t.PokemonSpecies.shape,), column=t.PokemonShape.identifier),
    EntityScalarProperty(u'generation', u'Introduced in', join=(t.Pokemon.species, t.PokemonSpecies.generation,), column=t.Generation.id),

    EntityListProperty(u'type', u'Type', crossjoin=t.Pokemon.types, column=t.Type.identifier),
    EntityListProperty(u'egg-group', u'Egg groups', join=(t.Pokemon.species,), crossjoin=t.PokemonSpecies.egg_groups, column=t.EggGroup.identifier),
    EvolutionProperty(u'evolution', u'Evolution'),
    EntityMapProperty(u'base-stats', u'Base stats', crossjoin=t.Pokemon.stats, backref=t.PokemonStat.pokemon_id, subjoin=(t.PokemonStat.stat,), discriminator=t.Stat.identifier, column=t.PokemonStat.base_stat),
    EntityMapProperty(u'effort', u'Effort', crossjoin=t.Pokemon.stats, backref=t.PokemonStat.pokemon_id, subjoin=(t.PokemonStat.stat,), discriminator=t.Stat.identifier, column=t.PokemonStat.effort),
    DecoratedEntityListProperty(u'ability', u'Abilities', crossjoin=t.Pokemon.pokemon_abilities, backref=t.PokemonAbility.pokemon_id, subjoin=(t.PokemonAbility.ability,), column=t.Ability.identifier, decorations=dict(ability=(t.PokemonAbility.ability, t.Ability.identifier), slot=(t.PokemonAbility.slot,))),
    DecoratedEntityListProperty(u'held-item', u'Held items', crossjoin=t.Pokemon.items, backref=t.PokemonItem.pokemon_id, column=t.Item.identifier, decorations=dict(item=(t.PokemonItem.item, t.Item.identifier), rarity=(t.PokemonItem.rarity,))),
    # XXX XXX XXX serious little issue: there is no Pokemon.pokemon_moves!  this needs custom shenanigans, both for search and retrieval, to get moves for only the selected version.  :(
    PokemonMoveProperty(u'move', u'Moves', crossjoin=t.Pokemon.pokemon_moves, backref=t.PokemonMove.pokemon_id, subjoin=(t.PokemonMove.move,), column=t.Move.identifier, decorations=dict(move=(t.PokemonMove.move, t.Move.identifier), level=(t.PokemonMove.level,))),

    EntityMapProperty(u'pokedex', u'Pokédex number', join=(t.Pokemon.species,), crossjoin=t.PokemonSpecies.dex_numbers, backref=t.PokemonDexNumber.species_id, subjoin=(t.PokemonDexNumber.pokedex,), discriminator=t.Pokedex.identifier, column=t.PokemonDexNumber.pokedex_number),

    # XXX is this useful?  shouldn't it be related to number of steps somewhere
    ScalarNumberProperty(u'hatch-counter', u'Hatch counter', join=(t.Pokemon.species,), column=t.PokemonSpecies.hatch_counter),
    ScalarNumberProperty(u'base-experience', u'Base EXP', column=t.Pokemon.base_experience),
    ScalarNumberProperty(u'capture-rate', u'Capture rate', join=(t.Pokemon.species,), column=t.PokemonSpecies.capture_rate),
    ScalarNumberProperty(u'base-happiness', u'Base happiness', join=(t.Pokemon.species,), column=t.PokemonSpecies.base_happiness),
])

# TODO more fetchables:
# - flavor text
# TODO figure out complex fetching.  perhaps these should be dicts that are partially filled in depending on __underscores__
# - moves are split by version, method
# - flavor text is split by version
# - held items are split by version
# - ???
# TODO part 2: need to get side data for fetches.  e.g. if i fetch moves, i probably want a dict of move information
# - only include moves that actually appear in the results
# - name should be specified by __language__, but in a dict the same way as for versions
# - what else should be fetchable here?  should this ALSO be specified by __fetch__?

def apply_relationship(rel, target):
    """Try valiantly to apply the given relationship to a table class, row, or
    alias.
    """
    # XXX oops this is supposed to work for columns too.  bad name.
    # XXX this blows!
    try:
        return getattr(target, rel.key)
    except AttributeError:
        # XXX it's None because if we get here then the target is a class.  yeah I know.
        return rel.__get__(None, target)

# XXX this name blows
class APIQuery(object):
    """The actual interface.  Does all the important work."""
    def __init__(self, locus, session):
        self.locus = locus
        self.session = session

        # (rel1, rel2, rel3, ...) => alias
        self._joins = {}

    def entity_for(prop):
        """Get a unique table or column alias corresponding to the given
        property's specified relationship.  Phew, what a mouthful.
        """

    def get_join_alias(self, query, joins):
        """Given a sequence of SQLAlchemy relationships (which should start
        from the locus), joins along them and alias every single join.  A
        particular relationship is only ever joined once.
        """
        # XXX this, er, is really specific to the sqla query rather than the api query.  perhaps it belongs with a sqla query subclass.
        # Do some joinin'
        # Keep a cache of join relation chains, blah blah, XXX describe
        q = query
        last_alias = self.locus.table
        for i, relation in enumerate(joins):
            key = tuple(joins[:i+1])
            mapper = relation.property.mapper

            if key not in self._joins:
                from sqlalchemy.orm import aliased
                alias = aliased(mapper)
                q = q.join((alias, apply_relationship(relation, last_alias)))
                self._joins[key] = alias

            from sqlalchemy.orm.util import ORMAdapter
            alias = self._joins[key]
            q._filter_aliases = ORMAdapter(alias, equivalents=mapper._equivalent_columns, chain_to=q._filter_aliases)

            last_alias = alias

        return q, last_alias

    def process_query(self, formdata):
        # TODO split this into pieces

        errors = []

        q = self.session.query(self.locus.table)

        ### STEP 1: pull out the globalish options
        fetch = set(formdata.getall('__fetch__'))
        if not fetch:
            # Defaults
            fetch = set(('id',))
        if 'identifier' not in fetch:
            # Always always always provide the identifier
            fetch.add('identifier')

        # TODO just a version is a bit restrictive; this may want to be a
        # version group or even a generation.  which, of course, complicates
        # return values.
        if '__version__' in formdata:
            # XXX error handling
            version = self.session.query(t.Version).filter_by(identifier=formdata['__version__']).one()
        else:
            version = self.session.query(t.Version).order_by(t.Version.id.desc()).limit(1).first()

        try:
            fetch_props = [self.locus.prop_index[name] for name in fetch]
        except KeyError:
            # XXX error handling here
            raise

        ### STEP 2: parse the JSON criteria from each property
        # name.match-type becomes criteria['name']['match-type']
        criteria = defaultdict(dict)

        # Extract JSON arguments as a dictionary of sub-arguments for this
        # property.  "prop.x" becomes the key 'x', and "prop" becomes the
        # key None
        for key in formdata:
            form_value = formdata.getall(key)

            # Strip out blank values; never useful, but might be passed along
            # from an HTML form
            form_value = [_ for _ in form_value if _]
            if not form_value:
                continue

            if '.' in key:
                prop, subkey = key.split('.', 1)
            else:
                prop = key
                subkey = None
            criteria[prop][subkey] = form_value

        if not criteria:
            raise Exception("NO CRITERIA FOUND")

        from pprint import pprint
        print "criteria:", pprint(dict(criteria))

        ### STEP 3: Apply each criterion in turn to the query
        did_anything = False
        for prop in self.locus.properties:
            if prop.identifier not in criteria:
                continue

            q, last_alias = self.get_join_alias(q, prop.join)

            # XXX perhaps we should detect somehow whether to skip this criterion entirely, if it only has e.g. match type
            # XXX consider whether the `if not kw.get(None)` is a good plan
            print prop.identifier, criteria[prop.identifier].get(None)
            sql_condition = prop.apply_criterion(criteria[prop.identifier])
            print "sql_condition:", sql_condition
            q = q.filter(sql_condition)
            did_anything = True

        # prefetch
        # XXX actually do this correctly.  also, use contains_eager if already joined due to a filter.  also, join for filters.
        # XXX need to count the queries done in tests; how do I do that easily
        for prop in fetch_props:
            q = q.options(*prop.loading_options())

        print
        print "final query!!!"
        print q
        print

        if not did_anything:
            # XXX make this better, make a real way to ask for everything
            raise Exception("NO USEFUL CRITERIA GIVEN")

        results = []
        for row in q:
            result = {}
            for prop in fetch_props:
                result[prop.identifier] = prop.extract_data(row)
            results.append(result)
        #print results
        #print results[0]
        print [x['identifier'] for x in results]
        return results

