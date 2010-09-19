<%inherit file="/base.mako" />

<%def name="title()">Compare Pokémon</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li>Gadgets</li>
    <li>Compare Pokémon</li>
</ul>
</%def>

<h1>Compare Pokémon</h1>
<p>Select up to eight Pokémon to compare their stats, moves, etc.</p>

${h.form(url.current(), method='GET')}
<input type="hidden" name="shorten" value="1">
<div>
    Version to use for moves:
    <ul class="dex-compare-pokemon-version-list">
        % for version_group in c.version_groups:
        <li> <label>
            <input type="radio" name="version_group" value="${version_group.id}" \
                % if c.version_group == version_group:
                checked="checked" \
                % endif
            >
            ${h.pokedex.version_icons(*version_group.versions)}
        </label> </li>
        % endfor
    </ul>
</div>
<table class="dex-compare-pokemon">
<col class="labels">
<thead>
    % if c.did_anything and any(_ and _.suggestions for _ in c.found_pokemon):
    <tr class="dex-compare-suggestions">
        <th><!-- label column --></th>
        % for found_pokemon in c.found_pokemon:
        <th>
            % if found_pokemon.suggestions is None:
            <% pass %>\
            % elif found_pokemon.pokemon is None:
            no matches
            % else:
            <ul>
                % for suggestion, iso3166 in found_pokemon.suggestions:
                <li><a href="${c.create_comparison_link(target=found_pokemon, replace_with=suggestion)}">
                    % if iso3166:
                    <img src="${h.static_uri('spline', "flags/{0}.png".format(iso3166))}" alt="">
                    % endif
                    ${suggestion}?
                </a></li>
                % endfor
            </ul>
            % endif
        </th>
        % endfor
    </tr>
    % endif
    <tr class="header-row">
        <th><button type="submit">Compare:</button></th>
        % for found_pokemon in c.found_pokemon:
        <th>
            % if found_pokemon.pokemon:
            ${h.pokedex.pokemon_link(found_pokemon.pokemon,
                h.pokedex.pokemon_sprite(found_pokemon.pokemon, prefix=u'icons')
                    + h.literal(u'<br>') + found_pokemon.pokemon.full_name,
            )}<br>
            % endif
            <input type="text" name="pokemon" value="${found_pokemon.input}">
        </th>
        % endfor
    </tr>
    % if c.did_anything:
    <tr class="subheader-row">
        <th><!-- label column --></th>
        % for found_pokemon in c.found_pokemon:
        <th>
            <a href="${c.create_comparison_link(target=found_pokemon, move=-1)}">
                <img src="${h.static_uri('spline', 'icons/arrow-180-small.png')}" alt="←" title="Move left">
            </a>
            <a href="${c.create_comparison_link(target=found_pokemon, replace_with=u'')}">
                <img src="${h.static_uri('spline', 'icons/cross-small.png')}" alt="remove" title="Remove">
            </a>
            <a href="${c.create_comparison_link(target=found_pokemon, move=+1)}">
                <img src="${h.static_uri('spline', 'icons/arrow-000-small.png')}" alt="→" title="Move right">
            </a>
        </th>
        % endfor
    </tr>
    % endif
</thead>
</table>
${h.end_form()}

% if c.did_anything:
<table class="striped-rows dex-compare-pokemon">
<col class="labels">
<tbody>
    ${row(u'Type', type_cell, class_='dex-compare-list')}
    ${row(u'Abilities', abilities_cell, class_='dex-compare-list')}

    <tr class="subheader-row">
        <th colspan="${len(c.found_pokemon) + 1}">Breeding + Training</th>
    </tr>
    ${row(u'Egg groups', egg_groups_cell, class_='dex-compare-list')}
    ${row(u'Gender', gender_cell, class_='dex-compare-flavor-text')}
    ${relative_row(u'Base EXP')}
    ${relative_row(u'Base happiness')}
    ${relative_row(u'Capture rate')}

    <tr class="subheader-row">
        <th colspan="${len(c.found_pokemon) + 1}">Stats</th>
    </tr>
    % for stat in c.stats:
    ${relative_row(stat.name)}
    % endfor
    ${relative_row(u'Base stat total')}
    ${row(u'Effort', effort_cell)}

    <tr class="subheader-row">
        <th colspan="${len(c.found_pokemon) + 1}">Flavor</th>
    </tr>

    <tr class="size">
        <th>${h.pokedex.pokedex_img('chrome/trainer-male.png', alt='Trainer dude', style="height: %.2f%%" % (c.heights['trainer'] * 100))}</th>
        % for i, found_pokemon in enumerate(c.found_pokemon):
        <td>
            % if found_pokemon.pokemon:
            ${h.pokedex.pokemon_sprite(found_pokemon.pokemon, prefix='cropped-pokemon', style="height: %.2f%%;" % (c.heights[i] * 100))}
            % endif
        </td>
        % endfor
    </tr>
    ${row(u'Height', height_cell, class_='dex-compare-flavor-text')}

    <tr class="size">
        <th>${h.pokedex.pokedex_img('chrome/trainer-female.png', alt='Trainer dudette', style="height: %.2f%%" % (c.weights['trainer'] * 100))}</th>
        % for i, found_pokemon in enumerate(c.found_pokemon):
        <td>
            % if found_pokemon.pokemon:
            ${h.pokedex.pokemon_sprite(found_pokemon.pokemon, prefix='cropped-pokemon', style="height: %.2f%%;" % (c.weights[i] * 100))}
            % endif
        </td>
        % endfor
    </tr>
    ${row(u'Weight', weight_cell, class_='dex-compare-flavor-text')}

    ${row(u'Species',   species_cell,   class_='dex-compare-flavor-text')}
    ${row(u'Color',     color_cell,     class_='dex-compare-flavor-text')}
    ${row(u'Habitat',   habitat_cell,   class_='dex-compare-flavor-text')}
    ${row(u'Pawprint',  pawprint_cell,  class_='dex-compare-flavor-text')}
    ${row(u'Shape',     shape_cell,     class_='dex-compare-flavor-text')}
</tbody>
</table>

<h1>Level-up moves</h1>
<table class="striped-rows dex-compare-pokemon dex-compare-pokemon-moves">
<col class="labels">
${move_table_header()}
<tbody>
    % for level, pokemon_moves in sorted(c.level_moves.items()):
    <tr>
        <th>Level ${level}</th>
        % for found_pokemon in c.found_pokemon:
        <td>
            % for move in pokemon_moves[found_pokemon.pokemon]:
            <a href="${url(controller='dex', action='moves', name=move.name.lower())}">${move.name}</a> <br>
            % endfor
        </td>
        % endfor
    </tr>
    % endfor
</tbody>
</table>

<h1>Moves</h1>
<table class="striped-rows dex-compare-pokemon dex-compare-pokemon-moves">
<col class="labels">
${move_table_header()}
<tbody>
    % for method, move_pokemons in sorted(c.moves.items(), key=lambda (k, v): k.id):
    <tr class="subheader-row">
        <th colspan="${len(c.found_pokemon) + 1}">${method.name}</th>
    </tr>
    % for move, pokemons in sorted(move_pokemons.items(), key=lambda (k, v): k.name):
    <tr>
        <th><a href="${url(controller='dex', action='moves', name=move.name.lower())}">${move.name}</a></th>
        % for found_pokemon in c.found_pokemon:
        <td>
            % if found_pokemon.pokemon in pokemons:
            ✔
            % endif
        </td>
        % endfor
    </tr>
    % endfor
    % endfor
</tbody>
</table>
% endif  ## did anything


## Column headers for a new table
<%def name="move_table_header()">
<thead>
    <tr class="header-row">
        <th class="versions">${h.pokedex.version_icons(*c.version_group.versions)}</th>
        % for found_pokemon in c.found_pokemon:
        <th>
            % if found_pokemon.pokemon:
            ${h.pokedex.pokemon_link(found_pokemon.pokemon,
                h.pokedex.pokemon_sprite(found_pokemon.pokemon, prefix=u'icons')
                + h.literal('<br>')
                + found_pokemon.pokemon.full_name)}
            % endif
        </th>
        % endfor
    </tr>
</thead>
</%def>

## Print a row of 8
<%def name="row(label, cell_func, *args, **kwargs)">
    <tr class="${kwargs.pop('class_', u'')}">
        <th>${label}</th>
        % for found_pokemon in c.found_pokemon:
        <td>
            % if found_pokemon.pokemon:
            ${cell_func(found_pokemon.pokemon, *args, **kwargs)}
            % endif
        </td>
        % endfor
    </tr>
</%def>

## Print a row of 8 relatively-colored numbers
<%def name="relative_row(label)">
    <tr class="dex-compare-relative">
        <th>${label}</th>
        % for found_pokemon in c.found_pokemon:
        % if found_pokemon.pokemon:
        <% value, pct = c.relatives[label][found_pokemon.pokemon] %>\
        <td style="color: #${'{0:02x}'.format(int((1 - pct) * 192)) * 3};">${value}</td>
        % else:
        <td></td>
        % endif
        % endfor
    </tr>
</%def>

## Cells
<%def name="type_cell(pokemon)">
<ul>
    % for type in pokemon.types:
    <li>${h.pokedex.type_link(type)}</li>
    % endfor
</ul>
</%def>

<%def name="abilities_cell(pokemon)">
<ul>
    % for ability in pokemon.abilities:
    <li><a href="${url(controller='dex', action='abilities', name=ability.name.lower())}">${ability.name}</a></li>
    % endfor
</ul>
</%def>

<%def name="egg_groups_cell(pokemon)">
<ul>
    % for egg_group in pokemon.egg_groups:
    <li>${egg_group.name}</li>
    % endfor
</ul>
</%def>

<%def name="gender_cell(pokemon)">
${h.pokedex.pokedex_img('gender-rates/%d.png' % pokemon.gender_rate, alt='')}<br>
${h.pokedex.gender_rate_label[pokemon.gender_rate]}
</%def>

<%def name="base_exp_cell(pokemon)">
<% value, pct = c.relatives[u'Base EXP'][pokemon] %>\
<span style="font-size: ${u'2.5' if pct == 1 else u'2'}em; font-weight: bold; color: #${'{0:02x}'.format(192 - int(pct * 192)) * 3};">
    ${value}
</span>
</%def>

<%def name="base_happiness_cell(pokemon)">${pokemon.base_happiness}</%def>

<%def name="capture_rate_cell(pokemon)">${pokemon.capture_rate}</%def>

<%def name="stat_cell(pokemon, stat)">${pokemon.stat(stat).base_stat}</%def>

<%def name="effort_cell(pokemon)">
<ul>
    % for stat in c.stats:
    <% effort = pokemon.stat(stat).effort %>\
    % if effort:
    <li>${effort} ${stat.name}</li>
    % endif
    % endfor
</ul>
</%def>

## Flavor cells
<%def name="height_cell(pokemon)">
${h.pokedex.format_height_imperial(pokemon.height)}<br>
${h.pokedex.format_height_metric(pokemon.height)}
</%def>
<%def name="weight_cell(pokemon)">
${h.pokedex.format_weight_imperial(pokemon.weight)}<br>
${h.pokedex.format_weight_metric(pokemon.weight)}
</%def>

<%def name="species_cell(pokemon)">${pokemon.species}</%def>
<%def name="color_cell(pokemon)"><span style="color: ${pokemon.color};">${pokemon.color}</span></%def>
<%def name="habitat_cell(pokemon)">
% if pokemon.generation.id <= 3:
${h.pokedex.pokedex_img('chrome/habitats/%s.png' % h.pokedex.filename_from_name(pokemon.habitat), \
    alt='', title=pokemon.habitat)}<br>
% else:
n/a
% endif
</%def>

<%def name="pawprint_cell(pokemon)">${h.pokedex.pokemon_sprite(pokemon, prefix='pawprints', form=None)}</%def>

<%def name="shape_cell(pokemon)">
% if pokemon.shape:
${h.pokedex.pokedex_img('chrome/shapes/%d.png' % pokemon.shape.id, alt='', title=pokemon.shape.name)}<br>
${pokemon.shape.awesome_name}
% else:
n/a
% endif
</%def>
