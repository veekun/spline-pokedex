<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%! import re %>\

<%def name="title()">${c.move.name} - Moves</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li><a href="${url(controller='dex', action='moves_list')}">Moves</a></li>
    <li>${c.move.name}</li>
</ul>
</%def>

<div id="dex-header">
    <a href="${url.current(name=c.prev_move.name.lower(), form=None)}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${c.prev_move.name}
    </a>
    <a href="${url.current(name=c.next_move.name.lower(), form=None)}" id="dex-header-next" class="dex-box-link">
        ${c.next_move.name}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${c.move.name}
</div>

<%lib:cache_content>
${h.h1('Essentials')}

<div class="dex-page-portrait">
    <p id="dex-page-name">${c.move.name}</p>
    <p id="dex-page-types">
        ${h.pokedex.type_link(c.move.type)}
        ${h.pokedex.damage_class_icon(c.move.damage_class)}
    </p>
    <p>${h.pokedex.generation_icon(c.move.generation)}</p>
</div>

<div class="dex-page-beside-portrait">
    <h2>Summary</h2>
    <div class="markdown">
        ${h.literal(c.move.short_effect.as_html)}
    </div>

    <h2>Damage Dealt</h2>
    <ul class="dex-type-list">
        ## always sort ??? last
        % for type, damage_factor in sorted(c.type_efficacies.items(), \
                                            key=lambda x: (x[0].id == 18, x[0].name)):
        <li class="dex-damage-dealt-${damage_factor}">
            ${h.pokedex.type_link(type)} ${h.pokedex.type_efficacy_label[damage_factor]}
        </li>
        % endfor
    </ul>
</div>

<div class="dex-column-container">
<div class="dex-column">
    <h2>Stats</h2>
    <dl>
        <dt>Power</dt>
        % if c.move.damage_class.name == 'non-damaging':
        <dd>n/a</dd>
        % else:
        <dd>
            % if c.power_percentile is None:
            ${c.move.power}
            % else:
            ${c.move.power}; percentile ${"{0:.1f}".format(c.power_percentile * 100)}
            % endif
        </dd>
        % endif
        <dt>Accuracy</dt>
        <dd>
            % if c.move.accuracy is None:
            —  (cannot miss)
            % else:
            ${c.move.accuracy}%
            % if c.move.accuracy != 100 and c.move.damage_class.name != 'non-damaging':
            ≈ ${"%.1f" % (c.move.power * c.move.accuracy / 100.0)} power
            % endif
            % endif
        </dd>
        <dt>PP</dt>
        <dd>${c.move.pp}, up to ${c.move.pp * 8/5} with ${h.pokedex.item_link(c.pp_up)}</dd>
        <dt>Target</dt>
        <dd><abbr title="${c.move.target.description}">${c.move.target.name}</abbr></dd>
        <dt>Effect chance</dt>
        <dd>${c.move.effect_chance or 'n/a'}</dd>
        <dt>Priority</dt>
        % if c.move.priority > 0:
        <dd><span class="dex-priority-fast">${c.move.priority}</span> (fast)</dd>
        % elif c.move.priority < 0:
        <dd><span class="dex-priority-slow">${c.move.priority}</span> (slow)</dd>
        % else:
        <dd>${c.move.priority} (normal)</dd>
        % endif
    </dl>
</div>

<div class="dex-column">
    <h2>Flags</h2>
    <ul class="classic-list dex-move-flags">
      % for flag, has_flag in c.flags:
        <%
            search_param = "flag_{0}".format(flag.identifier)
            search_query = { search_param: u'yes' if has_flag else u'no' }
        %>\
        % if has_flag:
        <li>
            <a href="${url(controller='dex_search', action='move_search', **search_query)}">${flag.name}</a>
            <div class="markdown">
                ${h.literal(flag.description.as_html)}
            </div>
        </li>
        % else:
        <li class="disabled">
            <a href="${url(controller='dex_search', action='move_search', **search_query)}">${flag.name}</a>
        </li>
        % endif
      % endfor
    </ul>
</div>

<div class="dex-column">
    <h2>Machines</h2>
    <dl>
    % for generation, version_numbers in sorted(c.machines.items(), \
                                                key=lambda (k, v): k.id):
        <dt>${h.pokedex.generation_icon(generation)}</dt>
        <dd>
          % for version_group, machine_number in version_numbers:
            % if version_group:
            ## Null version_group means this gen is all the same machine
            ${h.pokedex.version_icons(*version_group.versions)}
            % endif
            % if not machine_number:
            Not a TM
            % elif machine_number > 100:
            HM${"%02d" % (machine_number - 100)}
            % else:
            TM${"%02d" % machine_number}
            % endif
            <br>
          % endfor
        </dd>
    % endfor
    </dl>
</div>
</div>


${h.h1('Effect')}
<div class="markdown">
${h.literal(c.move.effect.as_html)}
</div>

<h2>Categories</h2>
<ul class="classic-list">
    % for category_map in c.move.move_effect.category_map:
    <li>
        <a href="${url(controller='dex_search', action='move_search', \
            category="{0}:{1}".format(category_map.category.id, 'self' if category_map.affects_user else 'target'))}">
        ${category_map.category.name}, vs ${'user' if category_map.affects_user else 'target'}
        </a>
    </li>
    % endfor
</ul>


% if c.move.changelog:
${h.h1('History')}
<dl>
    % for change in c.move.changelog:
    <dt>Before ${h.pokedex.version_icons(*change.changed_in.versions)}</dt>
    <dd>
        % if change.power is not None:
        Power was ${change.power}.
        % endif
        % if change.accuracy is not None:
        Accuracy was ${change.accuracy}%.
        % endif
        % if change.pp is not None:
        PP was ${change.pp}.
        % endif
    </dd>
    % endfor
</dl>
% endif


${h.h1('Flavor')}
<div class="dex-column-container">
<div class="dex-column-2x">
    <h2>Flavor Text</h2>
    ${dexlib.flavor_text_list(c.move.flavor_text)}
</div>

<div class="dex-column">
    <h2>Foreign Names</h2>
    <dl>
        % for foreign_name in c.move.foreign_names:
        ## </dt> needs to come right after the flag or else there's space between it and the colon
        <dt>${foreign_name.language.name}
        <img src="${h.static_uri('spline', "flags/{0}.png".format(foreign_name.language.iso3166))}" alt=""></dt>
        % if foreign_name.language.name == 'Japanese':
        <dd>${foreign_name.name} (${h.pokedex.romanize(foreign_name.name)})</dd>
        % else:
        <dd>${foreign_name.name}</dd>
        % endif
        % endfor
    </dl>
</div>
</div>


${h.h1('Contests')}
<div class="dex-column-container">
<div class="dex-column">
    <h2>${h.pokedex.generation_icon(3)} Contest</h2>
    % if c.move.contest_effect:
    <dl>
        <dt>Type</dt>
        <dd>${h.pokedex.pokedex_img('chrome/contest/%s.png' % c.move.contest_type.name, alt=c.move.contest_type.name)}</dd>
        <dt>Appeal</dt>
        <dd title="${c.move.contest_effect.appeal}">${u'♡' * c.move.contest_effect.appeal}</dd>
        <dt>Jam</dt>
        <dd title="${c.move.contest_effect.jam}">${u'♥' * c.move.contest_effect.jam}</dd>
        <dt>Flavor text</dt>
        <dd>${c.move.contest_effect.flavor_text}</dd>

        <dt>Use after</dt>
        <dd>
            % if c.move.contest_combo_prev:
            <ul class="inline-commas">
                % for move in c.move.contest_combo_prev:
                <li><a href="${url(controller='dex', action='moves', name=move.name.lower())}">${move.name}</a></li>
                % endfor
            </ul>
            % else:
            None
            % endif
        </dd>
        <dt>Use before</dt>
        <dd>
            % if c.move.contest_combo_next:
            <ul class="inline-commas">
                % for move in c.move.contest_combo_next:
                <li><a href="${url(controller='dex', action='moves', name=move.name.lower())}">${move.name}</a></li>
                % endfor
            </ul>
            % else:
            None
            % endif
        </dd>
    </dl>
    % else:
    <p>This move does not exist in games with Contests.</p>
    % endif
</div>

<div class="dex-column">
    <h2>${h.pokedex.generation_icon(4)} Super Contest</h2>
    % if c.move.super_contest_effect:
    <dl>
        <dt>Type</dt>
        <dd>${h.pokedex.pokedex_img('chrome/contest/%s.png' % c.move.contest_type.name, alt=c.move.contest_type.name)}</dd>
        <dt>Appeal</dt>
        <dd title="${c.move.super_contest_effect.appeal}">${u'♡' * c.move.super_contest_effect.appeal}</dd>
        <dt>Flavor text</dt>
        <dd>${c.move.super_contest_effect.flavor_text}</dd>

        <dt>Use after</dt>
        <dd>
            % if c.move.super_contest_combo_prev:
            <ul class="inline-commas">
                % for move in c.move.super_contest_combo_prev:
                <li><a href="${url(controller='dex', action='moves', name=move.name.lower())}">${move.name}</a></li>
                % endfor
            </ul>
            % else:
            None
            % endif
        </dd>
        <dt>Use before</dt>
        <dd>
            % if c.move.super_contest_combo_next:
            <ul class="inline-commas">
                % for move in c.move.super_contest_combo_next:
                <li><a href="${url(controller='dex', action='moves', name=move.name.lower())}">${move.name}</a></li>
                % endfor
            </ul>
            % else:
            None
            % endif
        </dd>
    </dl>
    % else:
    <p>This move does not exist in games with Super Contests.</p>
    % endif
</div>
</div>

${h.h1(u'Similar moves')}
% if c.similar_moves:
<p>These moves all have the same effect as ${c.move.name}.</p>
<table class="dex-pokemon-moves striped-rows">
## COLUMNS
<colgroup>
    ${dexlib.move_table_columns()}
</colgroup>
## HEADERS
<tr class="header-row">
    ${dexlib.move_table_header()}
</tr>
## DATA
% for move in c.similar_moves:
<tr>
    ${dexlib.move_table_row(move)}
</tr>
% endfor
</table>
% else:
<p>No other moves have the same effect as ${c.move.name}.</p>
% endif

${h.h1(u'Pokémon', id='pokemon')}
% if c.move.damage_class.name != u'non-damaging':
<p>${c.move.type.name} Pokémon get STAB, and have their types highlighted in green.</p>
<p>Pokémon with higher ${u'Special Attack' if c.move.damage_class.name == u'special' else u'Attack'} are more suited to ${c.move.name}'s ${c.move.damage_class.name} damage, and have the stat highlighted in green.</p>
% endif
<% columns = sum(c.pokemon_columns, []) %>
<table class="dex-pokemon-moves striped-rows">
## COLUMNS
% for column_group in c.pokemon_columns:
<colgroup class="dex-colgroup-versions">
    % for column in column_group:
    <col class="dex-col-version">
    % endfor
</colgroup>
% endfor

<colgroup>\
    ${dexlib.pokemon_table_columns()}\
</colgroup>

% for method, method_list in c.pokemon:
## HEADERS
<tbody>
<%
    method_id = "pokemon:" + re.sub("\W+", "-", method.name.lower())
%>\
    <tr class="header-row" id="${method_id}">
        % for column in columns:
        ${dexlib.pokemon_move_table_column_header(column)}
        % endfor
        ${dexlib.pokemon_table_header()}
    </tr>
    <tr class="subheader-row">
        <th colspan="${len(columns) + 13}"><a href="#${method_id}" class="subtle"><strong>${method.name}</a></strong>: ${method.description}</th>
    </tr>
</tbody>
## DATA
<tbody>
% for pokemon, version_group_data in method_list:
    <tr class="\
        % if c.move.damage_class.name != u'non-damaging' and c.move.type in pokemon.types:
        better-move-type\
        % endif
        % if c.move.damage_class == c.better_damage_classes[pokemon]:
        better-move-stat-${c.better_damage_classes[pokemon].name.lower()}\
        % endif
    ">
        % for column in columns:
        ${dexlib.pokemon_move_table_method_cell(column, method, version_group_data)}
        % endfor
        ${dexlib.pokemon_table_row(pokemon)}
    </tr>
% endfor
</tbody>
% endfor
</table>

${h.h1('External Links', id='links')}
<ul class="classic-list">
% if c.move.generation.id <= 1:
<li>${h.pokedex.generation_icon(1)} <a href="http://www.math.miami.edu/~jam/azure/attacks/${c.move.name[0].lower()}/${c.move.name.lower().replace(' ', '_')}.htm">Azure Heights</a></li>
% endif
<li><a href="http://bulbapedia.bulbagarden.net/wiki/${c.move.name.replace(' ', '_')}_%28move%29">Bulbapedia</a></li>
<li><a href="http://www.legendarypokemon.net/attacks/${c.move.name.replace(' ', '+')}/">Legendary Pok&eacute;mon</a></li>
<li><a href="http://www.psypokes.com/dex/techdex/${"%03d" % c.move.id}">PsyPoke</a></li>
<li><a href="http://www.serebii.net/attackdex-dp/${c.move.name.lower().replace(' ', '')}.shtml">Serebii.net</a></li>
<li><a href="http://www.smogon.com/dp/moves/${c.move.name.lower().replace(' ', '_')}">Smogon</a></li>
</ul>
</%lib:cache_content>
