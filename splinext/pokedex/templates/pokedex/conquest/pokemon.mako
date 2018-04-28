<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>
<%namespace name="conqlib" file="lib.mako"/>

<%!
   from itertools import groupby
   from operator import attrgetter

   from splinext.pokedex import i18n
%>\

<%def name="title()">\
${_(u'{name} - Pokémon - Pokémon Conquest').format(name=c.pokemon.name)}
</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url('/dex/conquest')}">${_(u'Conquest')}</a></li>
    <li><a href="${url(controller='dex_conquest', action='pokemon_list')}">${_(u'Pokémon')}</a></a>
    <li>${c.pokemon.name}</li>
</ul>
</%def>

${conqlib.pokemon_page_header()}

${h.h1(_('Essentials'))}

## Portrait block
<div class="dex-page-portrait">
    <p id="dex-page-name">${c.pokemon.name}</p>
    <div id="dex-pokemon-conquest-portrait-sprite">
        ${h.pokedex.species_image(c.pokemon, prefix='conquest')}
    </div>
    <p id="dex-page-types">
        % for type in c.semiform_pokemon.types:
        ${h.pokedex.type_link(type)}
        % endfor
    </p>
</div>

<div class="dex-page-beside-portrait">
<h2>${_(u'Move')}</h2>
<% move = c.pokemon.conquest_move %>
<dl class="dex-conquest-pokemon-move">
    <dt class="dex-cpm-name">Name</dt>
    <dd class="dex-cpm-name"><a href="${url(controller='dex_conquest', action='moves', name=move.name.lower())}">${move.name}</a></dd>

    <dt class="dex-cpm-type">Type</dt>
    <dd class="dex-cpm-type">${h.pokedex.type_link(move.type)}</dd>

    <dt class="dex-cpm-range">Range</dt>
    <dd class="dex-cpm-range">${conqlib.range_image(move)}</dd>

    <dt class="dex-cpm-power">Power</dt>
    <dd>${move.conquest_data.power or u'—'} ${u'★' * move.conquest_data.star_rating}</dd>

    <dt class="dex-cpm-accuracy">Accuracy</dt>
    % if move.conquest_data.accuracy is not None:
    <dd>${move.conquest_data.accuracy}%</dd>
    % else:
    <dd>—</dd>
    % endif

    <dt class="dex-cpm-effect">Effect</dt>
    <dd>${move.conquest_data.short_effect}</dd>
</dl>

<h2>${_(u'Abilities')}</h2>
<dl class="pokemon-abilities">
    % for ability in c.pokemon.conquest_abilities:
    <dt><a href="${url(controller='dex_conquest', action='abilities', name=ability.name.lower())}">${ability.name}</a></dt>
    <dd class="markdown">No effects yet.</dd>
    % endfor
</dl>

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


${h.h1(_('Evolution'))}
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
    <%
        # Weedle and Kakuna don't exist in Conquest but we show them anyway so we can clarify that
        absent = col['species'].conquest_order is None
    %>\
    <td rowspan="${col['span']}"\
        % if col['species'] == c.pokemon:
        ${h.literal(' class="selected"')}\
        % endif
    >
        % if col['species'] == c.pokemon:
        <span class="dex-evolution-chain-pokemon">
            ${h.pokedex.pokemon_icon(col['species'].default_pokemon)}
            ${col['species'].name}
        </span>
        % else:
        <a href="${url(controller='dex' if absent else 'dex_conquest', action='pokemon', name=col['species'].name.lower())}"
           class="dex-evolution-chain-pokemon">
            ${h.pokedex.pokemon_icon(col['species'].default_pokemon)}
            ${col['species'].name}
        </a>
        % endif
        <span class="dex-evolution-chain-method">
            % if absent:
            Not present in Pokémon Conquest
            % elif col['species'].conquest_evolution is not None:
            ${conqlib.conquest_evolution_description(col['species'].conquest_evolution)}
            % endif
        </span>
    </td>
    % endif
    % endfor
</tr>
% endfor
</tbody>
</table>


${h.h1(_('Stats'))}
<p>Base stats in Conquest are derived from calculated level 100 stats from the main series.  Attack matches either Attack or Special Attack, usually depending on the main-series damage class of the Pokémon's move but occasionally breaking from that if the other stat is much higher.  Defense matches the average of Defense and Special Defense.  HP and Speed are the same.</p>
<%
    default_stat_link = 100
%>
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
        <th><label for="dex-pokemon-stats-level">${_("Link")}</label></th>
        <th><input type="text" size="3" value="${default_stat_link}" disabled="disabled" id="dex-pokemon-conquest-stats-link"></th>
    </tr>
    <tr class="header-row">
        <th><!-- stat name --></th>
        <th><!-- bar and value --></th>
        <th><abbr title="${_(u"Percentile rank")}">${_(u"Pctile")}</abbr></th>
        <th>${_(u"Min IVs")}</th>
        <th>${_(u"Max IVs")}</th>
    </tr>
</thead>
<% info = c.stats.pop('range') %>
<tbody>
<tr class="color1">
    <th>Range</th>
    <td>
        <div class="dex-pokemon-stats-bar-container">
            <div class="dex-pokemon-stats-bar" style="margin-right: ${(1 - info['percentile']) * 100}%; background-color: ${info['background']}; border-color: ${info['border']};">${info['value']}</div>
        </div>
    </td>
    <td class="dex-pokemon-stats-pctile">${"%0.1f" % (info['percentile'] * 100)}</td>
    <td></td>
    <td></td>
</tr>
</tbody>
<tbody>
    % for pokemon_stat in (stat for stat in c.pokemon.conquest_stats if stat.stat.is_base):
<%
        stat_info = c.stats[pokemon_stat.stat.identifier]
%>\
    <tr class="color1">
        <th>${pokemon_stat.stat.name}</th>
        <td>
            <div class="dex-pokemon-stats-bar-container">
                <div class="dex-pokemon-stats-bar" style="margin-right: ${(1 - stat_info['percentile']) * 100}%; background-color: ${stat_info['background']}; border-color: ${stat_info['border']};">${pokemon_stat.base_stat}</div>
            </div>
        </td>
        <td class="dex-pokemon-stats-pctile">${"%0.1f" % (stat_info['percentile'] * 100)}</td>
        <td class="dex-pokemon-stats-result">${pokemon_stat.base_stat * 100 // default_stat_link}</td>
        <td class="dex-pokemon-stats-result">${pokemon_stat.base_stat * 100 // default_stat_link + 31}</td>
    </tr>
    % endfor
</tbody>
<tbody>
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
</tbody>
</table>


${h.h1(_(u'Warrior Links'), id=_(u'max-links'))}
<form id="link-threshold" method="GET" action="${url.current()}#${_(u'max-links')}">
<p>
    Only show warriors with at least a ${c.link_form.link(size=3)}% link.
    <button type="submit">Go!</button>
</p>

% for error in c.link_form.link.errors:
<p class="error">${error}</p>
% endfor
</form>

<table class="dex-pokemon-moves dex-warriors striped-rows">
<colgroup span="3"></colgroup>
${conqlib.warrior_table_columns()}
${conqlib.warrior_table_header(link_cols=True)}

<tbody>
    % for warrior, max_links in groupby(c.max_links, key=attrgetter('warrior')):
    <% max_links = list(max_links) %>
    <tr class="${'perfect-link' if max_links[-1].max_link == 100 else ''}">
        % for i, max_link in enumerate(max_links):
        <td class="max-link">${max_link.max_link}%</td>
        % endfor
        % for dummy_rank in range(i, 2):
        <td class="max-link"></td>
        % endfor
        ${conqlib.warrior_table_row(warrior, ranks=[link.warrior_rank for link in max_links])}
    </tr>
    % endfor
</tbody>
</table>
