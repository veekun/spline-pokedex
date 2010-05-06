<%def name="pokemon_page_header()">
<div id="dex-header">
    <a href="${url.current(name=c.prev_pokemon.name.lower(), form=None)}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${h.pokedex.pokemon_sprite(prefix='icons', pokemon=c.prev_pokemon)}
        ${c.prev_pokemon.national_id}: ${c.prev_pokemon.name}
    </a>
    <a href="${url.current(name=c.next_pokemon.name.lower(), form=None)}" id="dex-header-next" class="dex-box-link">
        ${c.next_pokemon.national_id}: ${c.next_pokemon.name}
        ${h.pokedex.pokemon_sprite(prefix='icons', pokemon=c.next_pokemon)}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${h.pokedex.pokemon_sprite(prefix='icons', pokemon=c.pokemon)}
    <br>${c.pokemon.national_id}: ${c.pokemon.name}
    <ul class="inline-menu">
    % for action, label in (('pokemon', u'Pokédex'), \
                            ('pokemon_flavor', u'Flavor'), \
                            ('pokemon_locations', u'Locations')):
        % if action == request.environ['pylons.routes_dict']['action']:
        <li>${label}</li>
        % else:
        <li><a href="${url.current(action=action)}">${label}</a></li>
        % endif
    % endfor
    </ul>
</div>
</%def>


###### Common tables
<%def name="pokemon_move_table_column_header(column)">
<th class="version">
  % if len(column) == len(column[0].generation.version_groups):
    ## If the entire gen has been collapsed into a single column, just show
    ## the gen icon instead of the messy stack of version icons
    ${h.pokedex.generation_icon(column[0].generation)}
  % else:
    % for i, version_group in enumerate(column):
    % if i != 0:
    <br>
    % endif
    ${h.pokedex.version_icons(*version_group.versions)}
    % endfor
  % endif
</th>
</%def>


## Given a method and some data, returns a cell indicating in some useful
## manner how a move is learned.
## Makes some use of c.move_tutor_version_groups, if it exists.
## XXX How to sort these "correctly"...?
## XXX How to sort these "correctly"...?
<%def name="pokemon_move_table_method_cell(column, method, version_group_data)">
<% version_group = column[0] %>\
% if method.name == 'Tutor' and c.move_tutor_version_groups:
<td class="tutored">
  ## Tutored moves never ever collapse!  Have to merge all the known values,
  ## rather than ignoring all but the first
  % for version_group in column:
    % if version_group in version_group_data:
    ${h.pokedex.version_icons(*version_group.versions)}
    % elif version_group in c.move_tutor_version_groups:
    <span class="no-tutor">${h.pokedex.version_icons(*version_group.versions)}</span>
    % endif
  % endfor
</td>
% elif version_group not in version_group_data:
## Could be an empty hash, in which case it's here but has no metadata
<td></td>
% elif method.name == 'Level up':
<td>
  % if version_group_data[version_group]['level'] == 1:
    —
  % else:
    ${version_group_data[version_group]['level']}
  % endif
</td>
% elif method.name == 'Machine':
<% machine_number = version_group_data[version_group]['machine'] %>\
<td>
  % if machine_number > 100:
  ## HM
    <strong>H</strong>${machine_number - 100}
  % else:
    ${"%02d" % machine_number}
  % endif
</td>
% elif method.name == 'Egg':
<td class="dex-moves-egg">${h.pokedex.pokedex_img('icons/egg-cropped.png')}</td>
% else:
<td>&bull;</td>
% endif
</%def>


<%def name="pokemon_table_columns()">
<col class="dex-col-icon">
<col class="dex-col-name">
<col class="dex-col-type2">
<col class="dex-col-ability">
<col class="dex-col-gender">
<col class="dex-col-egg-group">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat-total">
</%def>

<%def name="pokemon_table_header()">
<th></th>
<th>Pokémon</th>
<th>Type</th>
<th>Ability</th>
<th>Gender</th>
<th>Egg Group</th>
<th><abbr title="Hit Points">HP</abbr></th>
<th><abbr title="Attack">Atk</abbr></th>
<th><abbr title="Defense">Def</abbr></th>
<th><abbr title="Special Attack">SpA</abbr></th>
<th><abbr title="Special Defense">SpD</abbr></th>
<th><abbr title="Speed">Spd</abbr></th>
<th>Total</th>
</%def>

<%def name="pokemon_table_row(pokemon)">
<td class="icon">${h.pokedex.pokemon_sprite(pokemon, prefix='icons')}</td>
<td>${h.pokedex.pokemon_link(pokemon)}</td>
<td class="type2">
    % for type in pokemon.types:
    ${h.pokedex.type_link(type)}
    % endfor
</td>
<td class="ability">
  % for i, ability in enumerate(pokemon.abilities):
    % if i > 0:
    <br>
    % endif
    <a href="${url(controller='dex', action='abilities', name=ability.name.lower())}">${ability.name}</a>
  % endfor
</td>
<td>${h.pokedex.pokedex_img('gender-rates/%d.png' % pokemon.gender_rate, alt=h.pokedex.gender_rate_label[pokemon.gender_rate])}</td>
<td class="egg-group">
  % for i, egg_group in enumerate(pokemon.egg_groups):
    % if i > 0:
    <br>
    % endif
    ${egg_group.name}
  % endfor
</td>
% for pokemon_stat in pokemon.stats:
<td class="stat">${pokemon_stat.base_stat}</td>
% endfor
<td>${sum((pokemon_stat.base_stat for pokemon_stat in pokemon.stats))}</td>
</%def>


<%def name="move_table_columns()">
<col class="dex-col-name">
<col class="dex-col-type">
<col class="dex-col-type">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-stat">
<col class="dex-col-effect">
</%def>

<%def name="move_table_header(gen_instead_of_type=False)">
<th>Move</th>
% if gen_instead_of_type:
<th>Gen</th>
% else:
<th>Type</th>
% endif
<th>Class</th>
<th>PP</th>
<th>Power</th>
<th>Acc</th>
<th>Pri</th>
<th>Effect</th>
</%def>

<%def name="move_table_row(move, gen_instead_of_type=False)">
<td><a href="${url(controller='dex', action='moves', name=move.name.lower())}">${move.name}</a></td>
% if gen_instead_of_type:
## Done on type pages; we already know the type, so show the generation instead
<td class="type">${h.pokedex.generation_icon(move.generation)}</td>
% else:
<td class="type">${h.pokedex.type_link(move.type)}</td>
% endif
<td class="class">${h.pokedex.damage_class_icon(move.damage_class)}</td>
<td>${move.pp}</td>
<td>${move.power}</td>
<td>${move.accuracy}%</td>
## Priority is colored red for slow and green for fast
% if move.priority == 0:
<td></td>
% elif move.priority > 0:
<td class="dex-priority-fast">${move.priority}</td>
% else:
<td class="dex-priority-slow">${move.priority}</td>
% endif
<td class="effect">${h.literal(move.short_effect.as_html)}</td>
</%def>
