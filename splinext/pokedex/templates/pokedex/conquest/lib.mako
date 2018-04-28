<%namespace name="dexlib" file="/pokedex/lib.mako" />
<%! from splinext.pokedex import i18n %>

<%def name="pokemon_page_header()">
<div id="dex-header">
    <a href="${url.current(name=c.prev_pokemon.name.lower(), form=None)}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        <span class="sprite-icon sprite-icon-${c.prev_pokemon.id}"></span>
        ${c.prev_pokemon.conquest_order}: ${c.prev_pokemon.name}
    </a>
    <a href="${url.current(name=c.next_pokemon.name.lower(), form=None)}" id="dex-header-next" class="dex-box-link">
        ${c.next_pokemon.conquest_order}: ${c.next_pokemon.name}
        <span class="sprite-icon sprite-icon-${c.next_pokemon.id}"></span>
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${h.pokedex.species_image(c.pokemon, prefix='icons')}
    <br />${c.pokemon.conquest_order}: ${c.pokemon.name}

    <ul class="inline-menu">
    % for action, label in (('pokemon', u'Pokédex'), \
                            ('pokemon_flavor', u'Flavor'), \
                            ('pokemon_locations', u'Locations')):
        <li><a href="${url(controller='dex', action=action, name=c.pokemon.name.lower())}">${label}</a></li>
    % endfor
        <li>${_(u'Conquest')}</li>
    </ul>
</div>
</%def>


<%def name="move_table_columns()">
<colgroup>
    <col class="dex-col-name">
    <col class="dex-col-type">
    <col class="dex-col-icon">
    <col class="dex-col-stat">
    <col>
    <col class="dex-col-stat">
    <col class="dex-col-effect">
</colgroup>
</%def>

<%def name="move_table_header()">
<th>Move</th>
<th>Type</th>
<th>Range</th>
<th colspan="2">Power</th>
<th>Acc</th>
<th>Effect</th>
</%def>

<%def name="move_table_row(move)">
<td><a href="${url(controller='dex_conquest', action='moves', name=move.name.lower())}">${move.name}</a></td>
<td class="type">${h.pokedex.type_link(move.type)}</td>
<td class="icon">${range_image(move)}</td>

% if move.conquest_data.power:
<td>${move.conquest_data.power}</td>
% else:
<td>—</td>
% endif

<td style="text-align: left">${u'★' * move.conquest_data.star_rating}</td>

% if move.conquest_data.accuracy:
<td>${move.conquest_data.accuracy}%</td>
% else:
<td>—</td>
% endif

<td class="markdown effect">${move.conquest_data.short_effect}</td>
</%def>


<%def name="pokemon_table_columns(link_cols=0)">
% if link_cols:
<colgroup span=${link_cols}></colgroup>
% endif
<colgroup>
    <col class="dex-col-icon">
    <col class="dex-col-name">
    <col class="dex-col-type2">
    <col class="dex-col-ability">
    <col class="dex-col-stat">
    <col class="dex-col-stat">
    <col class="dex-col-stat">
    <col class="dex-col-stat">
    <col class="dex-col-stat">
    <col class="dex-col-stat-total">
</colgroup>
</%def>

<%def name="pokemon_table_header(link_cols=0)">
<tr class="header-row">
    % if link_cols:
    <th colspan="${link_cols}">Link</th>
    % endif
    <th></th>
    <th>Pokémon</th>
    <th>Type</th>
    <th>Abilities</th>
    <th>Range</th>
    <th><abbr title="Hit Points">HP</abbr></th>
    <th><abbr title="Attack">Atk</abbr></th>
    <th><abbr title="Defense">Def</abbr></th>
    <th><abbr title="Speed">Spd</abbr></th>
    <th>Total</th>
</tr>
% if link_cols > 1:
<tr class="subheader-row conquest-subheader-row">
    % for rank in range(1, link_cols + 1):
    <th>${h.pokedex.conquest_rank_label[rank]}</th>
    % endfor
    % for column in range(10):
    <th></th>
    % endfor
</tr>
% endif
</%def>

<%def name="pokemon_table_row(pokemon)">
<td class="icon"><span class="sprite-icon sprite-icon-${pokemon.id}"></span></td>
<td><a href="${url(controller='dex_conquest', action='pokemon', name=pokemon.name.lower())}">${pokemon.name}</a></td>
<td class="type2">
    % for type in pokemon.default_pokemon.types:
    ${h.pokedex.type_link(type)}
    % endfor
</td>
<td class="ability">
  % for i, ability in enumerate(pokemon.conquest_abilities):
    % if i > 0:
    <br />
    % endif
    <a href="${url(controller='dex_conquest', action='abilities', name=ability.name.lower())}">${ability.name}</a>
  % endfor
</td>
% for stat in sorted(pokemon.conquest_stats, key=(lambda s: (s.stat.is_base, s.conquest_stat_id))):
<td class="stat stat-${stat.stat.identifier}">${stat.base_stat}</td>
% endfor
<td>${sum(stat.base_stat for stat in pokemon.conquest_stats if stat.stat.is_base)}</td>
</%def>

<%def name="range_image(move)">
<%
if move.conquest_data.move_displacement:
    identifier = '{0}-{1}'.format(move.conquest_data.range.identifier, move.conquest_data.move_displacement.identifier)
    title = '{0}, {1}'.format(move.conquest_data.range.name, move.conquest_data.move_displacement.name)
else:
    identifier = move.conquest_data.range.identifier
    title = move.conquest_data.range.name
%>

${h.pokedex.pokedex_img('chrome/conquest-move-ranges/{0}.png'.format(identifier),
    alt=title, title=title)}
</%def>


<%def name="warrior_image(warrior, dir, rank=None, attr=None)">
<%
if rank is None:
    if warrior.identifier == 'nobunaga':
        rank = 2
    else:
        rank = 1

if attr is None:
    attr = {}

if warrior.archetype:
    identifier = warrior.archetype.identifier
    attr['alt'] = attr['title'] = identifier
else:
    identifier = '{0}-{1}'.format(warrior.identifier, rank)
    attr['alt'] = attr['title'] = u'Rank {rank} {name}'.format(
        rank=h.pokedex.conquest_rank_label[rank],
        name=warrior.name
    )

if dir == 'small-icons':
    attr['class'] = 'warrior-icon-small'
elif dir == 'big-icons':
    attr['class'] = 'warrior-icon-big'
%>
${h.pokedex.pokedex_img('warriors/{0}/{1}.png'.format(dir, identifier), **attr)}
</%def>

<%def name="warrior_table_columns()">
<colgroup>
    <col class="dex-col-warrior-icon">
    <col class="dex-col-name">
    <col class="dex-col-type2">
    <col class="dex-col-ability">
</colgroup>
% for stat in range(4):
<colgroup>
    <col class="dex-col-stat">
    <col class="dex-col-stat">
    <col class="dex-col-stat">
</colgroup>
% endfor
</%def>

<%def name="warrior_table_header(link_cols=False)">
<thead>
    <tr class="header-row">
        % if link_cols:
        <th colspan="3">Link</th>
        % endif
        <th colspan="2">Warrior</th>
        <th>Specialty</th>
        <th>Skill</th>
        <th colspan="3">Power</th>
        <th colspan="3">Wisdom</th>
        <th colspan="3">Charisma</th>
        <th colspan="3">Capacity</th>
    </tr>
    <tr class="subheader-row conquest-subheader-row">
        % if link_cols:
        <th>I</th><th>II</th><th>III</th>
        % endif
        <th colspan="2"></th>
        <th></th>
        <th>I / II / III</th>
        % for stat in range(4):
        <th>I</th><th>II</th><th>III</th>
        % endfor
    </tr>
</thead>
</%def>

<%def name="warrior_table_row(warrior, icon_rank=None, ranks=None)">
<%
# For performance, if we already /have/ all the ranks, we can pass them here.
# In particular, this is the case when creating a Pokémon's max link table,
# because we'll have a link for every rank when we have a link at all; going
# and getting them again would take another query for each row.
if ranks is None:
    ranks = warrior.ranks
%>

<td class="warrior-icon">${warrior_image(warrior, 'big-icons', rank=icon_rank)}</td>
<td><a href="${url(controller='dex_conquest', action='warriors', name=warrior.name.lower())}">${warrior.name}</a></td>
<td class="type2">
    % for type in warrior.types:
    ${h.pokedex.type_link(type)}
    % endfor
</td>
<td class="ability">
    % for rank in ranks:
    % if rank.rank > 1:
    <br />
    % endif
    <a href="${url(controller='dex_conquest', action='skills', name=rank.skill.name.lower())}">${rank.skill.name}</a>
    % endfor
</td>
% for stats in zip(*(rank.stats for rank in ranks)):
${warrior_table_stat_colgroup(stats)}
% endfor
</%def>

<%def name="warrior_table_stat_colgroup(stats)">
% for rank_stat in stats:
<td>${rank_stat.base_stat}</td>
% endfor
% for dummy_rank in range(3 - len(stats)):
<td></td>
% endfor
</%def>


<%def name="warrior_rank_table_head()">
<colgroup>
    <col class="dex-col-icon"/>
    <col>
    <col class="dex-col-name"/>
    <col class="dex-col-type2"/>
    <col class="dex-col-ability"/>
    <col class="dex-col-stat"/>
    <col class="dex-col-stat"/>
    <col class="dex-col-stat"/>
    <col class="dex-col-stat"/>
</colgroup>

<thead>
    <tr class="header-row">
        <th colspan="2">Warrior</th>
        <th>Rank</th>
        <th>Specialty</th>
        <th>Skill</th>
        <th>Power</th>
        <th>Wisdom</th>
        <th>Charisma</th>
        <th>Capacity</th>
    </tr>
</thead>
</%def>

<%def name="conquest_evolution_description(evolution)"><%
    """Crafts a human-readable description from a `conquest_pokemon_evolution`
    row object.
    """
    chunks = []

    # Trigger
    if evolution.recruiting_ko_required:
        chunks.append('Score a KO that makes a warrior offer to join your army')
    elif evolution.item_id is not None:
        chunks.append('Win a battle')
    else:
        chunks.append('Perform any action')

    # Conditions
    if evolution.kingdom_id is not None:
        chunks.append(h.literal(_(u'in {0}')).format(
            h.HTML.a(evolution.kingdom.name,
                href=url(controller='dex_conquest', action='kingdoms',
                         name=evolution.kingdom.name.lower()))))
    if evolution.item_id is not None:
        chunks.append(h.literal(_(u'with {article} {item} equipped')).format(
            article=h.pokedex.article(evolution.item.name),
            item=h.pokedex.item_link(evolution.item, include_icon=False)))
    if evolution.required_stat_id is not None:
        chunks.append(_(u'with at least {number} {stat} afterwards').format(
            number=evolution.minimum_stat,
            stat=evolution.stat.name))
    if evolution.minimum_link is not None:
        chunks.append(_(u'with at least {0}% link afterwards').format(
            evolution.minimum_link))
    if evolution.warrior_gender_id is not None:
        chunks.append(_(u'{0} warriors only').format(evolution.gender.identifier))

    return h.literal(u', ').join(chunks)
%></%def>

<%def name="conquest_transformation_description(tform)"><%
    """Crafts a human-readable description from a
    `conquest_warrior_transformation' row object.
    """
    # Dumb tricks for saving characters; this has a lot of big awkward lines
    def link(thing):
        return h.HTML.a(thing.name,
            href=h.pokedex.make_thingy_url(thing, controller='dex_conquest'))
    lit = h.literal

    chunks = []

    # Triggers
    if tform.is_automatic:
        chunks.append(_(u'Automatically happens in-story'))
    elif tform.required_link is not None:
        if tform.pokemon[0].identifier == 'eevee':
            pokemon = lit(_(u'{0} or any of its evolutions')).format(
                link(tform.pokemon[0]))
        else:
            pokemon = lit(_(u' or ')).join(link(p) for p in tform.pokemon)

        chunks.append(lit(_(u'Reach at least {link}% link with {pokemon}'))
            .format(link=tform.required_link, pokemon=pokemon))

    # Conditions
    if tform.completed_episode_id is not None:
        warrior = tform.completed_episode.warriors[0]
        if warrior != tform.warrior_rank.warrior:
            warrior = link(warrior)
        else:
            warrior = warrior.name

        chunks.append(lit(_(u'after completing {warrior}\'s episode, "{name}"'))
            .format(warrior=warrior, name=tform.completed_episode.name))
    elif tform.current_episode_id is not None:
        if tform.current_episode.warriors[0].identifier == 'player-m':
            warrior = _(u'the player')
        else:
            warrior = tform.current_episode.warriors[0].name

        chunks.append(_(u'during {warrior}\'s episode, "{name}"')
            .format(
                warrior=warrior,
                name=tform.current_episode.name
            ))
    elif tform.distant_warrior_id is not None:
        chunks.append(lit(_(u'with {0} in the army but not in the same kingdom '
            u'or any adjacent kingdom')).format(link(tform.distant_warrior)))
    elif tform.present_warriors:
        chunks.append(h.literal(_(u'with {0} in the same kingdom'))
            .format(lit(_(u' and ')).join(link(warrior) for warrior in
                                          tform.present_warriors)))
    elif tform.female_warlord_count is not None:
        chunks.append(_(u'with at least {0} female warlords in the same kingdom')
            .format(tform.female_warlord_count))
    elif tform.pokemon_count is not None:
        chunks.append(_(u'with at least {0} Pokémon in the gallery')
            .format(tform.pokemon_count))
    elif tform.collection_type_id is not None:
        chunks.append(_(u'with all {0}-type Pokémon in the gallery')
            .format(tform.type.name))
    elif tform.warrior_count is not None:
        chunks.append(_(u'with at least {0} warriors in the gallery')
            .format(tform.warrior_count))

    return lit(u', ').join(chunks)
%></%def>
