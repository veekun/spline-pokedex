<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%! from splinext.pokedex import db %>\
<%! import re %>\

<%! from splinext.pokedex import i18n %>\

<%def name="title()">\
${_(u"{pokemon.name} – #{pokemon.species.id} - {pokemon.species.genus}").format(pokemon=c.pokemon)}
</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url(controller='dex', action='pokemon_list')}">${_(u'Pokémon')}</a></li>
    <li>${c.pokemon.name}</li>
</ul>
</%def>

${dexlib.pokemon_page_header()}

<%lib:cache_content>
${h.h1(_('Essentials'))}

## Portrait block
<div class="dex-page-portrait">
    <p id="dex-page-name">${c.pokemon.species.name}</p>
    % if len(c.pokemon.forms) == 1 and \
        c.pokemon.default_form.form_name is not None:
    <p id="dex-pokemon-forme">${c.pokemon.default_form.form_name}</p>
    % else:
    <p id="dex-pokemon-genus">${c.pokemon.species.genus}</p>
    % endif
    <div id="dex-pokemon-portrait-sprite">
        ${h.pokedex.pokemon_form_image(c.pokemon.default_form)}
    </div>
    <p id="dex-page-types">
        % for type in c.pokemon.types:
        ${h.pokedex.type_link(type)}
        % endfor
    </p>
</div>

<div class="dex-page-beside-portrait">
<h2>${_(u"Abilities")}</h2>
<%def name="_render_ability(ability, _=_)">
    <dt><a href="${url(controller='dex', action='abilities', name=ability.name.lower())}">${ability.name}</a></dt>
    <dd class="markdown">${ability.short_effect}</dd>
</%def>
<dl class="pokemon-abilities">
    % for ability in c.pokemon.abilities:
    ${_render_ability(ability, _=_)}
    % endfor
</dl>
% if c.pokemon.hidden_ability:
<h3>Hidden Ability</h3>
<dl class="pokemon-abilities">
    ${_render_ability(c.pokemon.hidden_ability, _=_)}
</dl>
% endif

<h2>${_(u"Damage Taken")}</h2>
## Boo not using <dl>  :(  But I can't get them to align horizontally with CSS2
## if the icon and value have no common element..
<ul class="dex-type-list">
    % for type, damage_factor in h.keysort(c.type_efficacies, lambda k: k.name):
    <li class="dex-damage-taken-${damage_factor}">
        ${h.pokedex.type_link(type)} ${h.pokedex.type_efficacy_label[damage_factor]}
    </li>
    % endfor
</ul>
</div>

<div class="dex-column-container">
<div class="dex-column">
    <h2>${_(u"Pokédex Numbers")}</h2>
    <dl>
        <dt>${_(u"Introduced in")}</dt>
        <dd>${h.pokedex.generation_icon(c.pokemon.species.generation, _=_)}</dd>\

        % for number in c.pokemon.species.dex_numbers:
        % if number.pokedex.is_main_series:
        <dt>${number.pokedex.name}</dt>
        <dd>
            ${number.pokedex_number}
            % if number.pokedex.version_groups:
            ${h.pokedex.version_icons(*[v for vg in number.pokedex.version_groups for v in vg.versions], _=_)}
            % endif
        </dd>

        % endif
        % endfor
    </dl>

    <h2>${_(u"Names")}</h2>
    ${dexlib.foreign_names(c.pokemon.species)}
</div>
<div class="dex-column">
    <h2>${_(u"Breeding")}</h2>
    <dl>
        <dt>${_(u"Gender")}</dt>
        <dd>
            ${h.pokedex.chrome_img('gender-rates/%d.png' % c.pokemon.species.gender_rate, alt='')}
            ${_(h.pokedex.gender_rate_label[c.pokemon.species.gender_rate])}
            ${dexlib.subtle_search(action='pokemon_search', gender_rate=c.pokemon.species.gender_rate, _=_)}
        </dd>

        <dt>${_(u"Egg groups")}</dt>
        <dd>
            <ul class="inline-commas">
                % for i, egg_group in enumerate(c.pokemon.species.egg_groups):
                <li>${egg_group.name}</li>
                % endfor
            </ul>
            % if len(c.pokemon.species.egg_groups) > 1:
            ${dexlib.subtle_search(action='pokemon_search', egg_group=[group.id for group in c.pokemon.species.egg_groups], _=_)}
            % endif
        </dd>

        <dt>${_(u"Hatch counter")}</dt>
        <dd>
            ${c.pokemon.species.hatch_counter}
            ${dexlib.subtle_search(action='pokemon_search', hatch_counter=c.pokemon.species.hatch_counter, sort='evolution-chain', _=_)}
        </dd>

        <dt>${_(u"Steps to hatch")}</dt>
        <dd>
            ${(c.pokemon.species.hatch_counter + 1) * 255} /

            ## If any party Pokémon has Magma Armor or Flame Body, hatch counters go down by two (instead of one) every 255 steps.
            ## Then there's the final lap after the egg hits zero.  So, for MA/FB steps: (ceil(counter / 2.0) + 1) * 255
            ## ceil() returns a float, but we can avoid a messy int(ceil(...)) like so: ceil(x / 2.0) == floor((x + 1) / 2.0) == (x + 1) // 2
            ## And thus: (ceil(x / 2.0) + 1) * 255 == ((x + 1) // 2 + 1) * 255 == (x + 3) // 2 * 255
            <span class="annotation" title="${_('With Magma Armor or Flame Body')}">${(c.pokemon.species.hatch_counter + 3) // 2 * 255}</span>
        </dd>
    </dl>

    <h2>${_(u"Compatibility")}</h2>
    % if c.pokemon.species.egg_groups[0].id == 13:
    ## Egg group 13 is the special Ditto group
    <p>${_(u"Ditto can breed with any other breedable Pokémon, but can never produce a Ditto egg.")}</p>
    % elif c.pokemon.species.egg_groups[0].id == 15:
    ## Egg group 15 is the special No Eggs group
    <p>${_("{0} cannot breed.").format(c.pokemon.name)}</p>
    % else:
    <ul class="inline dex-pokemon-compatibility">
        % for species in c.compatible_families:
        <li>${h.pokedex.pokemon_link(
            species.default_pokemon,
            h.pokedex.pokemon_icon(species.default_pokemon),
            form=None,
            class_='dex-icon-link',
            title=species.name,
        )}</li>
        % endfor
    </ul>
    % endif
</div>
<div class="dex-column">
    <h2>${_(u"Training")}</h2>
    <dl>
        <dt>${_(u"Base EXP")}</dt>
        <dd>
            <span id="dex-pokemon-exp-base">${c.pokemon.base_experience}</span>
            ${dexlib.subtle_search(action='pokemon_search', base_experience=c.pokemon.base_experience, _=_)}
        </dd>
        <dt>${_(u"Effort points")}</dt>
        <dd>
            <ul>
                % for pokemon_stat in c.pokemon.stats:
                % if pokemon_stat.effort:
                <li>${pokemon_stat.effort} ${pokemon_stat.stat.name}</li>
                % endif
                % endfor
            </ul>
        </dd>
        <dt>${_(u"Capture rate")}</dt>
        <dd>
            ${c.pokemon.species.capture_rate}
            ${dexlib.subtle_search(action='pokemon_search', capture_rate=c.pokemon.species.capture_rate, _=_)}
        </dd>
        <dt>${_(u"Base happiness")}</dt>
        <dd>
            ${c.pokemon.species.base_happiness}
            ${dexlib.subtle_search(action='pokemon_search', base_happiness=c.pokemon.species.base_happiness, _=_)}
        </dd>
        <dt>${_(u"Growth rate")}</dt>
        <dd>
            ${c.pokemon.species.growth_rate.name}
            ${dexlib.subtle_search(action='pokemon_search', growth_rate=c.pokemon.species.growth_rate.max_experience, _=_)}
        </dd>
    </dl>

    <h2>${_(u"Wild held items")}</h2>
    <table class="dex-pokemon-held-items striped-row-groups">
    % for generation, version_dict in h.keysort(c.held_items, lambda k: k.id):
    <tbody>
    % for versions, item_records in h.keysort(version_dict, lambda k: k[0].id):
    <tr class="new-version">
      % for i in range(len(item_records) or 1):
        % if i == 0:
        <td class="versions" rowspan="${len(item_records) or 1}">
            % if len(version_dict) == 1:
            ${h.pokedex.generation_icon(generation, _=_)}
            % else:
            ${h.pokedex.version_icons(*versions, _=_)}
            % endif
        </td>
        % else:
    </tr>
    <tr>
        % endif

        ## Print the item and rarity.  Might be nothing
        % if i < len(item_records):
        <td class="rarity">${item_records[i][1]}%</td>
        <td class="item">${h.pokedex.item_link(item_records[i][0], _=_)}</td>
        % else:
        <td class="rarity"></td>
        <td class="item">${_(u"nothing")}</td>
        % endif
      % endfor
    </tr>
    % endfor
    </tbody>
    % endfor
    </table>
</div>
</div>

${h.h1(_('Evolution'))}
<ul class="see-also">
<li>
    <img src="${h.static_uri('spline', 'icons/chart--arrow.png')}" alt="${_(u"See also:")}">
    <a href="${url(controller='dex_gadgets', action='compare_pokemon',
        pokemon=[pokemon.name for species in c.pokemon.species.evolution_chain.species
                              for pokemon in species.pokemon]
        )}">${_('Compare this family')}</a>
</li>
</ul>

<table class="dex-evolution-chain">
<thead>
<tr>
    <th>${_(u"Baby")}</th>
    <th>${_(u"Basic")}</th>
    <th>${_(u"Stage 1")}</th>
    <th>${_(u"Stage 2")}</th>
</tr>
</thead>
<tbody>
% for row in c.evolution_table:
<tr>
    % for col in row:
    ## Empty cell
    % if col == '':
    <td></td>
    % elif col != None:
    <td rowspan="${col['span']}"\
        % if col['species'] == c.pokemon.species:
        ${h.literal(' class="selected"')}\
        % endif
    >
        % if col['species'] == c.pokemon.species:
        <span class="dex-evolution-chain-pokemon">
            ${h.pokedex.pokemon_icon(col['species'].default_pokemon)}
            ${col['species'].name}
        </span>
        % else:
        ${h.pokedex.pokemon_link(
            pokemon=col['species'].default_pokemon,
            content=h.pokedex.pokemon_icon(col['species'].default_pokemon)
                   + col['species'].name,
            class_='dex-evolution-chain-pokemon',
        )}
        % endif
        % for evolution in col['species'].evolutions:
        <span class="dex-evolution-chain-method">
            ${dexlib.evolution_description(evolution)}
        </span>
        % endfor
        % if col['species'].is_baby and c.pokemon.species.evolution_chain.baby_trigger_item:
        <span class="dex-evolution-chain-method">
            ${_(u"Either parent must hold ")} ${h.pokedex.item_link(c.pokemon.species.evolution_chain.baby_trigger_item, include_icon=False, _=_)}
        </span>
        % endif
    </td>
    % endif
    % endfor
</tr>
% endfor
</tbody>
</table>
% if len(c.pokemon.species.forms) > 1:
<h2 id="forms"> <a href="#forms" class="subtle">${_("%s Forms") % c.pokemon.species.name}</a> </h2>
<ul class="inline">
    % for form in sorted(c.pokemon.species.forms, key=lambda f: (f.order, f.name)):
<%
    link_class = 'dex-box-link'
    if form == c.pokemon.default_form:
        link_class = link_class + ' selected'
%>\
    % if form.is_default:
        <li>${h.pokedex.pokemon_link(form.pokemon, h.pokedex.pokemon_form_image(form), class_=link_class)}</li>
    % else:
        <li>${h.pokedex.form_flavor_link(form, h.pokedex.pokemon_form_image(form), class_=link_class)}</li>
    % endif
    % endfor
</ul>
<div class="markdown">${c.pokemon.species.form_description}</div>
% endif

${h.h1(_('Stats'))}
<%
    # Most people want to see the best they can get
    default_stat_level = 100
    default_stat_effort = 255
%>\
<table class="dex-pokemon-stats">
<colgroup>
    <col class="dex-col-stat-name">
    <col class="dex-col-stat-bar">
    <col class="dex-col-stat-pctile">
</colgroup>
<colgroup>
    <col class="dex-col-stat-result">
    <col class="dex-col-stat-result">
</colgroup>
<thead>
    <tr>
        <th><!-- stat name --></th>
        <th><!-- bar and value --></th>
        <th><!-- percentile --></th>
        <th><label for="dex-pokemon-stats-level">${_("Level")}</label></th>
        <th><input type="text" size="3" value="${default_stat_level}" disabled="disabled" id="dex-pokemon-stats-level"></th>
    </tr>
    <tr>
        <th><!-- stat name --></th>
        <th><!-- bar and value --></th>
        <th><!-- percentile --></th>
        <th><label for="dex-pokemon-stats-effort">${_("Effort")}</label></th>
        <th><input type="text" size="3" value="${default_stat_effort}" disabled="disabled" id="dex-pokemon-stats-effort"></th>
    </tr>
    <tr class="header-row">
        <th><!-- stat name --></th>
        <th><!-- bar and value --></th>
        <th><abbr title="${_(u"Percentile rank")}">${_(u"Pctile")}</abbr></th>
        <th>${_(u"Min IVs")}</th>
        <th>${_(u"Max IVs")}</th>
    </tr>
</thead>
<tbody>
    % for pokemon_stat in c.pokemon.stats:
<%
        stat_info = c.stats[pokemon_stat.stat.name]

        if pokemon_stat.stat.identifier == 'hp':
            stat_formula = h.pokedex.formulae.calculated_hp
        else:
            stat_formula = h.pokedex.formulae.calculated_stat
%>\
    <tr class="color1">
        <th>${pokemon_stat.stat.name}</th>
        <td>
            <div class="dex-pokemon-stats-bar-container">
                <div class="dex-pokemon-stats-bar" style="margin-right: ${(1 - stat_info['percentile']) * 100}%; background-color: ${stat_info['background']}; border-color: ${stat_info['border']};">${pokemon_stat.base_stat}</div>
            </div>
        </td>
        <td class="dex-pokemon-stats-pctile">${"%0.1f" % (stat_info['percentile'] * 100)}</td>
        <td class="dex-pokemon-stats-result">${stat_formula(pokemon_stat.base_stat, level=default_stat_level, iv=0, effort=default_stat_effort)}</td>
        <td class="dex-pokemon-stats-result">${stat_formula(pokemon_stat.base_stat, level=default_stat_level, iv=31, effort=default_stat_effort)}</td>
    </tr>
    % endfor
</tbody>
<tr class="color1">
    <th>Total</th>
    <td>
        <div class="dex-pokemon-stats-bar-container">
            <div class="dex-pokemon-stats-bar" style="margin-right: ${(1 - c.stats['total']['percentile']) * 100}%; background-color: ${c.stats['total']['background']}; border-color: ${c.stats['total']['border']};">${c.stats['total']['value']}</div>
        </div>
    </td>
    <td class="dex-pokemon-stats-pctile">${"%0.1f" % (c.stats['total']['percentile'] * 100)}</td>
    <td></td>
    <td></td>
</tr>
</table>

% if c.pokeathlon_stats:
${h.h2(h.pokedex.version_icons('HeartGold', 'SoulSilver') + u' Pokéathlon Performance', id='pokeathlon')}
<%
    star_buffed = h.pokedex.pokedex_img('chrome/pokeathlon/star-buffed.png', alt=u'★')
    star_base = h.pokedex.pokedex_img('chrome/pokeathlon/star.png', alt=u'✯')
    star_empty = h.pokedex.pokedex_img('chrome/pokeathlon/star-empty.png', alt=u'☆')
%>

<p>${star_buffed} Minimum; ${star_base} Base; ${star_empty} Maximum</p>

% for label, stats in c.pokeathlon_stats:
<div class="dex-pokeathlon-stats">
    % if label:
    <p>${label}</p>
    % endif

    <dl>
        % for stat in stats:
        <dt>${stat.pokeathlon_stat.name}</dt>
        <dd>${star_buffed * stat.minimum_stat}${star_base * (stat.base_stat - stat.minimum_stat)}${star_empty * (stat.maximum_stat - stat.base_stat)}</dd>
        % endfor

        <dt>Total</dt>
        <dd>${sum(stat.minimum_stat for stat in stats)}/${sum(stat.base_stat for stat in stats)}/${sum(stat.maximum_stat for stat in stats)}</dd>
    </dl>
</div>
% endfor
% endif

${h.h1(_('Flavor'))}
<ul class="see-also">
<li> <img src="${h.static_uri('spline', 'icons/arrow-000-medium.png')}" alt="${_('See also:')}"> <a href="${url.current(action='pokemon_flavor')}">${_('Detailed flavor page covering all versions')}</a> </li>
</ul>

## Only showing current generation's sprites and text
<div class="dex-column-container">
<div class="dex-column-2x">
    <h2>${_("Flavor Text")}</h2>
    <% flavor_text = filter(lambda text: text.version.generation.id >= 5,
                            c.pokemon.species.flavor_text) %>
    ${dexlib.flavor_text_list(flavor_text, 'dex-pokemon-flavor-text')}
</div>
<div class="dex-column">
    <h2>${_("Sprites")}</h2>
    ${h.pokedex.pokemon_form_image(c.pokemon.default_form, prefix='main-sprites/ultra-sun-ultra-moon')}
    ${h.pokedex.pokemon_form_image(c.pokemon.default_form, prefix='main-sprites/ultra-sun-ultra-moon/shiny')}
    % if h.pokedex.pokemon_has_media(c.pokemon.default_form, 'main-sprites/ultra-sun-ultra-moon/female', 'png'):
        ${h.pokedex.pokemon_form_image(c.pokemon.default_form, prefix='main-sprites/ultra-sun-ultra-moon/female')}
        ${h.pokedex.pokemon_form_image(c.pokemon.default_form, prefix='main-sprites/ultra-sun-ultra-moon/shiny/female')}
    % endif
</div>
</div>

<div class="dex-column-container">
<div class="dex-column">
    <h2>${_("Miscellany")}</h2>
    <dl>
        <dt>${_("Species")}</dt>
        <dd>
            ${c.pokemon.species.genus}
            ${dexlib.subtle_search(action='pokemon_search', genus=c.pokemon.species.genus, _=_)}
        </dd>

        <dt>${_("Color")}</dt>
        <dd>
            <span class="dex-color-${c.pokemon.species.color.identifier}"></span>
            ${c.pokemon.species.color.name}
            ${dexlib.subtle_search(action='pokemon_search', color=c.pokemon.species.color.identifier, _=_)}
        </dd>

        <dt>${_("Cry")}</dt>
        <dd>
            ${dexlib.pokemon_cry(c.pokemon.default_form)}
        </dd>

        % if c.pokemon.species.generation_id <= 3:
        <dt>${_("Habitat")} ${h.pokedex.version_icons(u'FireRed', u'LeafGreen')}</dt>
        <dd>
            ${h.pokedex.pokedex_img('habitats/%s.png' % c.pokemon.species.habitat.identifier)}
            ${c.pokemon.species.habitat.name}
            ${dexlib.subtle_search(action='pokemon_search', habitat=c.pokemon.species.habitat.identifier, _=_)}
        </dd>
        % endif

        % if c.pokemon.species.generation_id <= 5:
        <dt>${_("Footprint")}</dt>
        <dd>${h.pokedex.species_image(c.pokemon.species, prefix='footprints')}</dd>
        % endif

        <dt>${_("Shape")}</dt>
        <dd>
            ${h.pokedex.pokedex_img('shapes/%s.png' % c.pokemon.species.shape.identifier, alt='', title=c.pokemon.species.shape.name)}
            ${c.pokemon.species.shape.awesome_name}
            ${dexlib.subtle_search(action='pokemon_search', shape=c.pokemon.species.shape.identifier, _=_)}
        </dd>
    </dl>
</div>
<div class="dex-column">
    <h2>${_("Height")}</h2>
    <div class="dex-size">
        <div class="dex-size-trainer">
            ${h.pokedex.chrome_img('trainer-male.png', alt=_("Trainer dude"), style="height: %.2f%%" % (c.heights['trainer'] * 100))}
            <p class="dex-size-value">
                <input type="text" size="6" value="${h.pokedex.format_height_imperial(c.trainer_height)}" disabled="disabled" id="dex-pokemon-height">
            </p>
        </div>
        <div class="dex-size-pokemon">
            ${h.pokedex.pokemon_form_image(c.pokemon.default_form, prefix='cropped', style="height: %.2f%%;" % (c.heights['pokemon'] * 100))}
            <div class="js-dex-size-raw">${c.pokemon.height}</div>
            <p class="dex-size-value">
                ${h.pokedex.format_height_imperial(c.pokemon.height)} <br/>
                ${h.pokedex.format_height_metric(c.pokemon.height)}
            </p>
        </div>
    </div>
</div>
<div class="dex-column">
    <h2>${_("Weight")}</h2>
    <div class="dex-size">
        <div class="dex-size-trainer">
            ${h.pokedex.chrome_img('trainer-female.png', alt=_("Trainer dudette"), style="height: %.2f%%" % (c.weights['trainer'] * 100))}
            <p class="dex-size-value">
                <input type="text" size="6" value="${h.pokedex.format_weight_imperial(c.trainer_weight)}" disabled="disabled" id="dex-pokemon-weight">
            </p>
        </div>
        <div class="dex-size-pokemon">
            ${h.pokedex.pokemon_form_image(c.pokemon.default_form, prefix='cropped', style="height: %.2f%%;" % (c.weights['pokemon'] * 100))}
            <div class="js-dex-size-raw">${c.pokemon.weight}</div>
            <p class="dex-size-value">
                ${h.pokedex.format_weight_imperial(c.pokemon.weight)} <br/>
                ${h.pokedex.format_weight_metric(c.pokemon.weight)}
            </p>
        </div>
    </div>
</div>
</div>

${h.h1(_('Locations'))}
<ul class="see-also">
<li> <img src="${h.static_uri('spline', 'icons/map--arrow.png')}" alt="${_("See also:")}"> <a href="${url.current(action='pokemon_locations')}">${_("Ridiculously detailed breakdown")}</a> </li>
</ul>

<dl class="dex-simple-encounters">
    ## Sort versions by order, which happens to be id
    % for version, method_etc in h.keysort(c.locations, lambda k: k.id):
    <dt>${(version.name)} ${h.pokedex.version_icons(version, _=_)}</dt>
    <dd>
        ## Sort method by name
        % for method, area_condition_encounters in h.keysort(method_etc, lambda k: k.id):
        <div class="dex-simple-encounters-method">
            ${h.pokedex.chrome_img('encounters/' + c.encounter_method_icons.get(method.identifier, 'unknown.png'), \
                                    alt=method.name)}
            <ul>
                ## Sort locations by name
                % for location_area, (conditions, combined_encounter) \
                    in h.keysort(area_condition_encounters, lambda k: (k.location.name, k.name)):
                <li title="${combined_encounter.level} ${combined_encounter.rarity}% ${';'.join(condition.name for condition in conditions)}">
                    <a href="${url(controller="dex", action="locations", name=location_area.location.name.lower())}${'#area:' + (location_area.name) if location_area.name else ''}">
                        ${(location_area.location.name)}${', ' + (location_area.name) if location_area.name else ''}
                    </a>
                </li>
                % endfor
            </ul>
        </div>
        % endfor
    </dd>
    % endfor
</dl>

% if c.pokemon.species.pal_park:
${h.h2(_(u'Pal Park'))}
<dl>
<dt>${_(u'Area')}</dt>
<dd>${c.pokemon.species.pal_park.area.name}</dd>

<dt>${_(u'Score')}</dt>
<dd>${c.pokemon.species.pal_park.base_score}</dd>

<dt>${_(u'Rate')}</dt>
<dd>${c.pokemon.species.pal_park.rate}</dd>
</dl>
% endif

${h.h1(_('Moves'))}
<p>${u' and '.join(t.name for t in c.pokemon.types)} moves get STAB, and have their type highlighted in green.</p>
% if c.better_damage_class:
<p>${c.better_damage_class.name.capitalize()} moves better suit ${c.pokemon.species.name}'s higher ${u'Special Attack' if c.better_damage_class.identifier == u'special' else u'Attack'}, and have their class highlighted in green.</p>
% endif
<% columns = sum(c.move_columns, []) %>
<table class="dex-pokemon-moves dex-pokemon-pokemon-moves striped-rows">
## COLUMNS
% for column_group in c.move_columns:
<colgroup class="dex-colgroup-versions">
    % for column in column_group:
    <col class="dex-col-version">
    % endfor
</colgroup>
% endfor

<colgroup>\
    ${dexlib.move_table_columns()}\
</colgroup>

<% last_method_id = None %>
% for method, method_list in c.moves:
## HEADERS
<tbody>
% if last_method_id != method.id:
<%
    method_id = "moves:" + h.sanitize_id(method.name)
%>\
    <tr class="header-row" id="${method_id}">
        % for column in columns:
            ${dexlib.pokemon_move_table_column_header(column, method)}
        % endfor
        ${dexlib.move_table_header()}
    </tr>
    <tr class="subheader-row">
        <th colspan="${len(columns) + 8}"><a href="#${method_id}" class="subtle"><strong>${method.name}</strong></a>: ${method.description}</th>
    </tr>
<% last_method_id = method.id %>\
% endif
% if method.pokemon != c.pokemon:
    <tr class="subheader-row">
        <th colspan="${len(columns) + 8}"><strong>${method.name}</strong>, learned by ${method.pokemon.species.name} but not ${c.pokemon.species.name}</th>
    </tr>
% endif
</tbody>
## DATA
<tbody>
% for move, version_group_data in method_list:
    <tr class="\
        % if move.damage_class.identifier != u'status':
            % if move.type in c.pokemon.types:
                better-move-type\
            % endif
            % if move.damage_class == c.better_damage_class:
                better-move-stat\
            % endif
        % endif
    ">
        % for column in columns:
        ${dexlib.pokemon_move_table_method_cell(column, method, version_group_data)}
        % endfor
        ${dexlib.move_table_row(move)}
    </tr>
% endfor
</tbody>
% endfor
</table>

${h.h1(_('External Links'), id=_('links', context='header id'))}
<%
    # Some sites don't believe in Unicode URLs.  Scoff, scoff.
    # And they all do it differently.  Ugh, ugh.
    if c.pokemon.identifier == u'nidoran-f':
        lp_name = 'Nidoran(f)'
        ghpd_name = 'nidoran_f'
        smogon_name = 'nidoran-f'
    elif c.pokemon.identifier == u'nidoran-m':
        lp_name = 'Nidoran(m)'
        ghpd_name = 'nidoran_m'
        smogon_name = 'nidoran-m'
    else:
        lp_name = c.pokemon.species.name
        ghpd_name = re.sub(' ', '_', c.pokemon.species.name.lower())
        ghpd_name = re.sub('[^\w-]', '', ghpd_name)
        smogon_name = ghpd_name

    if not c.pokemon.is_default and c.pokemon.default_form.form_identifier:
        if c.pokemon.default_form.form_identifier == u'sandy':
            smogon_name += '-g'
        elif c.pokemon.default_form.form_identifier == u'trash':
            smogon_name += '-s'
        elif c.pokemon.default_form.form_identifier == u'mow':
            smogon_name += '-c'
        elif c.pokemon.default_form.form_identifier == u'fan':
            smogon_name += '-s'
        else:
            smogon_name += '-' + c.pokemon.default_form.form_identifier[0]
%>
<ul class="classic-list">
% if c.pokemon.species.generation_id <= 1:
<li>${h.pokedex.generation_icon(1)} <a href="http://www.math.miami.edu/~jam/azure/pokedex/species/${"%03d" % c.pokemon.species.id}.htm">${_("Azure Heights")}</a></li>
% endif
<li><a href="http://bulbapedia.bulbagarden.net/wiki/${re.sub(' ', '_', c.pokemon.species.name)}_%28Pok%C3%A9mon%29">${_("Bulbapedia")}</a></li>
% if c.pokemon.species.generation_id <= 2:
<li>${h.pokedex.generation_icon(2)} <a href="http://www.pokemondungeon.com/Library/Pokedex/pokedex/${ghpd_name}.shtml">${_(u"Gengar and Haunter's Pokémon Dungeon")}</a></li>
% endif
% if c.pokemon.species.generation_id <= 4:
<li>${h.pokedex.generation_icon(4)} <a href="http://www.legendarypokemon.net/pokedex/${lp_name}">${_(u"Legendary Pokémon")}</a></li>
% endif
<li><a href="http://www.psypokes.com/dex/psydex/${"%03d" % c.pokemon.species.id}">${_(u"PsyPoke")}</a></li>
<li><a href="http://www.serebii.net/pokedex-sm/${"%03d" % c.pokemon.species.id}.shtml">${_(u"Serebii.net")}</a></li>
<li><a href="http://www.smogon.com/dex/sm/pokemon/${smogon_name}">${_(u"Smogon")}</a></li>
</ul>
</%lib:cache_content>
