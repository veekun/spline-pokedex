<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%! from splinext.pokedex import i18n %>\
<%! import pokedex.db.tables as t %>\

<%def name="title()">${_("%s - Moves") % c.move.name}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li><a href="${url(controller='dex', action='moves_list')}">${_(u"Moves")}</a></li>
    <li>${c.move.name}</li>
</ul>
</%def>

<div id="dex-header">
    <a href="${url.current(name=c.prev_move.name.lower())}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${c.prev_move.name}
    </a>
    <a href="${url.current(name=c.next_move.name.lower())}" id="dex-header-next" class="dex-box-link">
        ${c.next_move.name}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${c.move.name}

    % if c.move.conquest_data:
    <ul class="inline-menu">
        <li>${_(u'Main')}</li>
        <li><a href="${url(controller='dex_conquest', action='moves', name=c.move.name.lower())}">${_(u'Conquest')}</a></li>
    </ul>
    % endif
</div>

<%lib:cache_content>
${h.h1(_('Essentials'))}

<div class="dex-page-portrait">
    <p id="dex-page-name">${c.move.name}</p>
    <p id="dex-page-types">
        ${dexlib.type_link(c.move.type)}
        ${dexlib.damage_class_icon(c.move.damage_class)}
    </p>
    <p>${dexlib.generation_icon(c.move.generation)}</p>
</div>

<div class="dex-page-beside-portrait">
    <h2>${_(u"Summary")}</h2>
    <div class="markdown">
        ${c.move.short_effect}
    </div>

    <h2>${_(u"Damage Dealt")}</h2>
    <ul class="dex-type-list">
        % for type_efficacy in sorted(c.move.type.damage_efficacies, key=lambda efficacy: efficacy.target_type.name):
        <li class="dex-damage-dealt-${type_efficacy.damage_factor}">
            ${dexlib.type_link(type_efficacy.target_type)} ${h.pokedex.type_efficacy_label[type_efficacy.damage_factor]}
        </li>
        % endfor
    </ul>
</div>

<div class="dex-column-container">
<div class="dex-column">
    <h2>${_(u"Stats")}</h2>
    <dl>
        <dt>${_(u"Power")}</dt>
        % if c.move.power is not None:
        <dd>
            % if c.power_percentile is None:
            ${c.move.power}
            % else:
            ${_(u"{power}; percentile {perc:.1f}").format(power=c.move.power, perc=c.power_percentile * 100)}
            % endif
        </dd>
        % elif c.move.damage_class.identifier == 'status':
        <dd>${_(u"—  (no damage)")}</dd>
        % else:
        <dd>${_(u'*  (no fixed power)')}</dd>
        % endif

        <dt>${_(u"Accuracy")}</dt>
        <dd>
            % if c.move.accuracy is None:
            ${_(u"—  (cannot miss)")}
            % else:
            ${c.move.accuracy}%
            % if c.move.accuracy != 100 and c.move.power is not None:
            ${_(u"≈ {0:.1f} power").format(c.move.power * c.move.accuracy / 100.0)}
            % endif
            % endif
        </dd>
        <dt>${_(u"PP")}</dt>
        % if c.move.pp is not None:
        <dd>${"{base}, up to {max} with {ppup}".format(base=c.move.pp, max=c.move.pp * 8/5, ppup=dexlib.item_link(c.pp_up)) | n}</dd>
        % else:
        <dd>${_('n/a')}</dd>
        % endif
        <dt>${_(u"Target")}</dt>
        <dd><abbr title="${c.move.target.description}">${c.move.target.name}</abbr></dd>
        <dt>Effect chance</dt>
        <dd>${c.move.effect_chance or 'n/a'}</dd>
        <dt>Priority</dt>
        % if c.move.priority > 0:
        <dd><span class="dex-priority-fast">${c.move.priority}</span> ${_("(fast)")}</dd>
        % elif c.move.priority < 0:
        <dd><span class="dex-priority-slow">${c.move.priority}</span> ${_("(slow)")}</dd>
        % else:
        <dd>${c.move.priority} ${_("(normal)")}</dd>
        % endif
    </dl>
</div>

<div class="dex-column">
    <h2>${_("Flags")}</h2>
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
                ${flag.description}
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
    <h2>${_("Machines")}</h2>
    <dl>
    % for generation, version_numbers in h.keysort(c.machines, lambda k: k.id):
        <dt>${dexlib.generation_icon(generation)}</dt>
        <dd>
          % for version_group, machine_number in version_numbers:
            % if version_group:
            ## Null version_group means this gen is all the same machine
            ${dexlib.version_icons(*version_group.versions)}
            % endif
            % if not machine_number:
            ${_("Not a TM")}
            % elif machine_number > 100:
            ${_("HM{number:02d}").format(number=machine_number - 100)}
            % else:
            ${_("TM{number:02d}").format(number=machine_number)}
            % endif
            <br>
          % endfor
        </dd>
    % endfor
    </dl>
</div>
</div>


${h.h1(_('Effect'))}
<div class="markdown">
${c.move.effect}
</div>

<% meta = c.move.meta %>
% if meta:
<h2>Meta</h2>
<p><em>This reflects how the games treat moves and may be somewhat idealistic.</em></p>
<ul class="classic-list">
    <li>
        <a href="${url(controller='dex_search', action='move_search', category=meta.category.identifier)}">
            ${meta.category.description}</a>
    </li>
    % if meta.meta_ailment_id:
    <li>
        % if meta.ailment_chance:
        ${meta.ailment_chance}% chance to
        <a href="${url(controller='dex_search', action='move_search', ailment=meta.ailment.identifier)}">
            inflict ${meta.ailment.name}</a>
        % else:
        <a href="${url(controller='dex_search', action='move_search', ailment=meta.ailment.identifier)}">
            Inflicts ${meta.ailment.name}</a>
        % endif
    </li>
    % endif
    % if meta.flinch_chance:
    <li>${meta.flinch_chance}% chance to
        <a href="${url(controller='dex_search', action='move_search', flinch_chance='>0')}">
            make the target flinch</a>
    </li>
    % endif
    % if c.move.meta_stat_changes:
    <li>
        % if meta.stat_chance:
        ${meta.stat_chance}% chance to
        % endif
        % for stat_change in c.move.meta_stat_changes:
        <a href="${url(controller='dex_search', action='move_search', **dict([('stat_change_' + stat_change.stat.identifier.replace('-', '_'), stat_change.change)]))}">
            ${u'raise' if stat_change.change > 0 else u'lower'} ${stat_change.stat.name}
            by ${abs(stat_change.change)}</a>
        % endfor
    </li>
    % endif

    % if meta.crit_rate:
    <li>
        <a href="${url(controller='dex_search', action='move_search', crit_rate='y')}">
            Critical hit rate increased by ${meta.crit_rate}</a>
    </li>
    % endif
    % if meta.min_hits:
    <li>
        <a href="${url(controller='dex_search', action='move_search', multi_hit='y')}">
            Hits ${meta.min_hits}${u'–{0}'.format(meta.max_hits) if meta.max_hits != meta.min_hits else u''} times</a>
    </li>
    % endif
    % if meta.min_turns:
    <li>
        <a href="${url(controller='dex_search', action='move_search', multi_turn='y')}">
            Effect lasts ${meta.min_turns}${u'–{0}'.format(meta.max_turns) if meta.max_turns != meta.min_turns else u''} turns</a>
    </li>
    % endif
    % if meta.recoil and meta.recoil > 0:
    <li>
        <a href="${url(controller='dex_search', action='move_search', recoil='>0')}">
            User takes ${meta.recoil}% of the damage inflicted as recoil</a>
    </li>
    % elif meta.recoil and meta.recoil < 0:
    <li>
        <a href="${url(controller='dex_search', action='move_search', recoil='<0')}">
            User absorbs ${abs(meta.recoil)}% of the damage inflicted</a>
    </li>
    % endif
    % if meta.healing and meta.healing > 0:
    <li>
        <a href="${url(controller='dex_search', action='move_search', healing='>0')}">
            User regains ${meta.healing}% of its max HP</a>
    </li>
    % elif meta.healing and meta.healing < 0:
    <li>
        <a href="${url(controller='dex_search', action='move_search', healing='<0')}">
            User loses ${abs(meta.healing)}% of its max HP</a>
    </li>
    % endif
</ul>
% endif

% if c.move.changelog or c.move.move_effect.changelog:
${h.h1(_('History'))}
<dl>
    <%
        all_changelog = (
            list(c.move.changelog) + list(c.move.move_effect.changelog))
        all_changelog.sort(key=lambda change: change.changed_in.id, reverse=True)
    %>\

    % for change in all_changelog:
    <dt>Before ${dexlib.version_icons(*change.changed_in.versions)}</dt>
    <dd>
      % if isinstance(change, t.MoveChangelog):
        % if change.type_id is not None:
        Type is ${dexlib.type_link(change.type)}.
        % endif
        % if change.power is not None:
        Has ${change.power} power.
        % endif
        % if change.accuracy is not None:
        Has ${change.accuracy}% accuracy.
        % endif
        % if change.pp is not None:
        Has ${change.pp} PP.
        % endif
        % if change.priority is not None:
        Has priority ${change.priority}.
        % endif
        % if change.target_id is not None:
        Target is ${change.target.name}.
        % endif
        % if change.effect_id is not None:
        ## XXX as_html is more appropriate but adds <p> tags
        Effect is: ${change.short_effect.as_text()}
        % elif change.effect_chance is not None:
        ## If we're showing the entire effect, it'll include the effect chance
        Effect chance is ${change.effect_chance}.
        % endif
      % else:
        ${change.effect}
      % endif
    </dd>
    % endfor
</dl>
% endif


${h.h1(_('Flavor'))}
<div class="dex-column-container">
<div class="dex-column-2x">
    <h2>${_("Flavor Text")}</h2>
    ${dexlib.flavor_text_list(c.move.flavor_text)}
</div>

<div class="dex-column">
    <h2>${_("Foreign Names")}</h2>
    <%dexlib:foreign_names object="${c.move}"/>
</div>
</div>


% if c.move.contest_effect or c.move.super_contest_effect:
${h.h1(_('Contests'))}
<div class="dex-column-container">

% if c.move.contest_effect:
<div class="dex-column">
    <h2>${_("%s Contest") % dexlib.generation_icon(3) | n}</h2>
    <dl>
        <dt>${_("Type")}</dt>
        <dd>${dexlib.pokedex_img('contest-types/{1}/{0}.png'.format(c.move.contest_type.identifier, c.game_language.identifier), alt=c.move.contest_type.name)}</dd>
        <dt>${_("Appeal")}</dt>
        <dd title="${c.move.contest_effect.appeal}">${u'♡' * c.move.contest_effect.appeal}</dd>
        <dt>${_("Jam")}</dt>
        <dd title="${c.move.contest_effect.jam}">${u'♥' * c.move.contest_effect.jam}</dd>
        <dt>${_("Flavor text")}</dt>
        <dd>${c.move.contest_effect.flavor_text}</dd>

        <dt>${_("Use after")}</dt>
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
        <dt>${_("Use before")}</dt>
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
</div>
% endif

% if c.move.super_contest_effect:
<div class="dex-column">
    <h2>${dexlib.generation_icon(4)} Super Contest</h2>
    <dl>
        <dt>${_("Type")}</dt>
        <dd>${dexlib.pokedex_img('contest-types/{1}/{0}.png'.format(c.move.contest_type.identifier, c.game_language.identifier), alt=c.move.contest_type.name)}</dd>
        <dt>${_("Appeal")}</dt>
        <dd title="${c.move.super_contest_effect.appeal}">${u'♡' * c.move.super_contest_effect.appeal}</dd>
        <dt>${_("Flavor text")}</dt>
        <dd>${c.move.super_contest_effect.flavor_text}</dd>

        <dt>${_("Use after")}</dt>
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
        <dt>${_("Use before")}</dt>
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
</div>
% endif

</div>
% endif


${h.h1(_(u'Similar moves'))}
% if c.similar_moves:
<p>${_("These moves all have the same effect as %s") % c.move.name}.</p>
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
<p>${_("No other moves have the same effect as %s") % c.move.name}.</p>
% endif

${h.h1(_(u'Pokémon', context='plural'))}
% if c.move.damage_class.identifier != u'status':
<p>${c.move.type.name} Pokémon get STAB, and have their types highlighted in green.</p>
<p>Pokémon with higher ${u'Special Attack' if c.move.damage_class.identifier == u'special' else u'Attack'} are more suited to ${c.move.name}'s ${c.move.damage_class.name} damage, and have the stat highlighted in green.</p>
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
    method_id = "pokemon:" + h.sanitize_id(method.name)
%>\
    <tr class="header-row" id="${method_id}">
        % for column in columns:
        ${dexlib.pokemon_move_table_column_header(column, method)}
        % endfor
        ${dexlib.pokemon_table_header()}
    </tr>
    <tr class="subheader-row">
        <th colspan="${len(columns) + 13}"><a href="#${method_id}" class="subtle"><strong>${method.name}</strong></a>: ${method.description}</th>
    </tr>
</tbody>
## DATA
<tbody>
% for pokemon, version_group_data in method_list:
    <tr class="\
        % if c.move.damage_class.identifier != u'status':
            % if c.move.type in pokemon.types:
                better-move-type\
            % endif
            % if c.move.damage_class == c.better_damage_classes[pokemon]:
                better-move-stat-${c.better_damage_classes[pokemon].identifier}\
            % endif
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

<p>${_(u"%d Pokémon") % c.pokemon_count}</p>


${h.h1(_('External Links'), id='links')}
<ul class="classic-list">
% if c.move.generation.id <= 1:
<li>${dexlib.generation_icon(1)} <a href="http://www.math.miami.edu/~jam/azure/attacks/${c.move.name[0].lower()}/${c.move.name.lower().replace(' ', '_')}.htm">${_("Azure Heights")}</a></li>
% endif
<li><a href="http://bulbapedia.bulbagarden.net/wiki/${c.move.name.replace(' ', '_')}_%28move%29">${_("Bulbapedia")}</a></li>
% if c.move.generation_id <= 4:
<li>${dexlib.generation_icon(4)} <a href="http://www.legendarypokemon.net/attacks/${c.move.name.replace(' ', '+')}/">${_(u"Legendary Pokémon")}</a></li>
% endif
% if c.move.generation_id <= 5:
## Psypoke's X/Y move ids don't match up with ours.
<li><a href="http://www.psypokes.com/dex/techdex/${"%03d" % c.move.id}">${_("PsyPoke")}</a></li>
% endif
<li><a href="http://www.serebii.net/attackdex-sm/${c.move.name.lower().replace(' ', '')}.shtml">${_("Serebii.net")}</a></li>
<li><a href="http://www.smogon.com/dex/sm/moves/${c.move.name.lower().replace(' ', '_')}">${_("Smogon")}</a></li>
</ul>
</%lib:cache_content>
