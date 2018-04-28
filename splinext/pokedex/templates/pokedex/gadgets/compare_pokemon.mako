<%inherit file="/base.mako" />
<%namespace name="dexlib" file="/pokedex/lib.mako" />
<%! from splinext.pokedex import i18n %>\

<%def name="title()">${_(u"Compare Pokémon")}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li>${_(u"Gadgets")}</li>
    <li>${_(u"Compare Pokémon")}</li>
</ul>
</%def>

${h.h1(_(u"Compare Pokémon"), _('compare'))}
<p>${_(u"Select up to eight Pokémon to compare their stats, moves, etc.")}</p>

${h.form(url.current(), method='GET')}
<input type="hidden" name="shorten" value="1">
<div>
    ${_(u"Version to use for moves:")}
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
            ${_(u"no matches")}
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
        <th><button type="submit">${_(u"Compare:")}</button></th>
        % for found_pokemon in c.found_pokemon:
        <th>
            % if found_pokemon.pokemon:
            ${h.pokedex.pokemon_link(found_pokemon.pokemon,
                h.pokedex.pokemon_form_image(found_pokemon.form, prefix=u'icons')
                    + h.literal(u'<br>') + found_pokemon.pokemon.name,
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
                <img src="${h.static_uri('spline', 'icons/arrow-180-small.png')}" alt="←" title="${_(u"Move left")}">
            </a>
            <a href="${c.create_comparison_link(target=found_pokemon, replace_with=u'')}">
                <img src="${h.static_uri('spline', 'icons/cross-small.png')}" alt="${_(u"remove")}" title="${_(u"Remove")}">
            </a>
            <a href="${c.create_comparison_link(target=found_pokemon, move=+1)}">
                <img src="${h.static_uri('spline', 'icons/arrow-000-small.png')}" alt="→" title="${_(u"Move right")}">
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
    ${row(_(u'Type'), type_cell, class_='dex-compare-list')}
    ${row(_(u'Abilities'), abilities_cell, class_='dex-compare-list')}
    ${row(_(u'Hidden Ability'), hidden_ability_cell, class_='dex-compare-hidden-ability')}

    ${subheader_row(_(u'Breeding + Training'), 'breeding-training')}
    ${row(_(u'Egg groups'), egg_groups_cell, class_='dex-compare-list')}
    ${row(_(u'Gender'), gender_cell, class_='dex-compare-flavor-text')}
    ${relative_row(_(u'Base EXP'), 'Base EXP')}
    ${relative_row(_(u'Base happiness'), 'Base happiness')}
    ${relative_row(_(u'Capture rate'), 'Capture rate')}

    ${subheader_row(_('Stats'), 'stats')}
    % for stat in c.stats:
    ${relative_row(stat.name, stat.name)}
    % endfor
    ${relative_row(_(u'Base stat total'), 'Base stat total')}
    ${row(_(u'Effort'), effort_cell)}

    ${subheader_row(_('Flavor'), 'flavor')}

    <tr class="size">
        <th>${h.pokedex.chrome_img('trainer-male.png', alt='${_(u"Trainer dude")}', style="height: %.2f%%" % (c.heights['trainer'] * 100))}</th>
        % for i, found_pokemon in enumerate(c.found_pokemon):
        <td>
            % if found_pokemon.pokemon:
            ${h.pokedex.pokemon_form_image(found_pokemon.form, prefix='cropped', style="height: %.2f%%;" % (c.heights[i] * 100))}
            % endif
        </td>
        % endfor
    </tr>
    ${row(_(u'Height'), height_cell, class_='dex-compare-flavor-text')}

    <tr class="size">
        <th>${h.pokedex.chrome_img('trainer-female.png', alt='${_(u"Trainer dudette")}', style="height: %.2f%%" % (c.weights['trainer'] * 100))}</th>
        % for i, found_pokemon in enumerate(c.found_pokemon):
        <td>
            % if found_pokemon.pokemon:
            ${h.pokedex.pokemon_form_image(found_pokemon.form, prefix='cropped', style="height: %.2f%%;" % (c.weights[i] * 100))}
            % endif
        </td>
        % endfor
    </tr>
    ${row(_(u'Weight'), weight_cell, class_='dex-compare-flavor-text')}

    ${row(_(u'Genus'),     genus_cell,     class_='dex-compare-flavor-text')}
    ${row(_(u'Color'),     color_cell,     class_='dex-compare-flavor-text')}
    ${row(_(u'Habitat'),   habitat_cell,   class_='dex-compare-flavor-text')}
    ${row(_(u'Footprint'), footprint_cell, class_='dex-compare-flavor-text')}
    ${row(_(u'Shape'),     shape_cell,     class_='dex-compare-flavor-text')}
</tbody>
</table>

${h.h1('Level-up moves')}
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

${h.h1('Moves')}
<table class="striped-rows dex-compare-pokemon dex-compare-pokemon-moves">
<col class="labels">
${move_table_header()}
<tbody>
    % for method, move_pokemons in h.keysort(c.moves, lambda k: k.id):
    ${subheader_row(method.name, 'moves:' + h.sanitize_id(method.name))}
    % for move, pokemons in h.keysort(move_pokemons, lambda k: k.name):
    <tr>
        <th>
            <a href="${url(controller='dex', action='moves', name=move.name.lower())}">${move.name}</a>
            % if method.identifier == 'machine':
            ${machine_label(move)}
            % endif
        </th>

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
                h.pokedex.pokemon_form_image(found_pokemon.form, prefix=u'icons')
                + h.literal('<br>')
                + found_pokemon.pokemon.name)}
            % endif
        </th>
        % endfor
    </tr>
</thead>
</%def>

## An anchored table subheader row
<%def name="subheader_row(label, id)">
<tr class="subheader-row" id="${id}">
    <th colspan="${len(c.found_pokemon) + 1}"><a href="#${id}" class="subtle">${label}</a></th>
</tr>
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
<%def name="relative_row(label_text, label)">
    <tr class="dex-compare-relative">
        <th>${label_text}</th>
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

<%def name="hidden_ability_cell(pokemon)">
% if pokemon.hidden_ability:
<a href="${url(controller='dex', action='abilities', name=pokemon.hidden_ability.name.lower())}">${pokemon.hidden_ability.name}</a></li>
% endif
</%def>

<%def name="egg_groups_cell(pokemon)">
<ul>
    % for egg_group in pokemon.species.egg_groups:
    <li>${egg_group.name}</li>
    % endfor
</ul>
</%def>

<%def name="gender_cell(pokemon)">
${h.pokedex.chrome_img('gender-rates/%d.png' % pokemon.species.gender_rate, alt='')}<br>
${h.pokedex.gender_rate_label[pokemon.species.gender_rate]}
</%def>

<%def name="base_exp_cell(pokemon)">
<% value, pct = c.relatives[u'Base EXP'][pokemon] %>\
<span style="font-size: ${u'2.5' if pct == 1 else u'2'}em; font-weight: bold; color: #${'{0:02x}'.format(192 - int(pct * 192)) * 3};">
    ${value}
</span>
</%def>

<%def name="base_happiness_cell(pokemon)">${pokemon.base_happiness}</%def>

<%def name="capture_rate_cell(pokemon)">${pokemon.capture_rate}</%def>

<%def name="stat_cell(pokemon, stat)">${pokemon.base_stat(stat, '?')}</%def>

<%def name="effort_cell(pokemon)">
<ul>
    % for pokemon_stat in pokemon.stats:
    % if pokemon_stat.effort:
    <li>${pokemon_stat.effort} ${pokemon_stat.stat.name}</li>
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

<%def name="genus_cell(pokemon)">${pokemon.species.genus}</%def>
<%def name="color_cell(pokemon)"><span class="dex-color-${pokemon.species.color.identifier}"></span> ${pokemon.species.color.name}</%def>
<%def name="habitat_cell(pokemon)">
% if pokemon.species.generation_id <= 3:
${h.pokedex.pokedex_img('habitats/%s.png' % pokemon.species.habitat.identifier, \
    alt='', title=pokemon.species.habitat.name)}<br>
% else:
n/a
% endif
</%def>

<%def name="footprint_cell(pokemon)">\
% if pokemon.species.generation_id <= 5:
${h.pokedex.species_image(pokemon.species, prefix='footprints')}\
% else:
n/a\
% endif
</%def>

<%def name="shape_cell(pokemon)">
% if pokemon.species.shape:
${h.pokedex.pokedex_img('shapes/%s.png' % pokemon.species.shape.identifier, alt='', title=pokemon.species.shape.name)}<br>
${pokemon.species.shape.awesome_name}
% else:
n/a
% endif
</%def>

## TM/HM number half-a-cell
<%def name="machine_label(move)">
% if c.machines[move] > 100:
(HM${'{0:02}'.format(c.machines[move] - 100)})
% else:
(TM${'{0:02}'.format(c.machines[move])})
% endif
</%def>
