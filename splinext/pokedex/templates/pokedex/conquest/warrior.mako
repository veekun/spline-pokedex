<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>
<%namespace name="conqlib" file="lib.mako"/>

<%! from splinext.pokedex import i18n %>

<%def name="title()">\
${_(u'{name} - Warriors - Pokémon Conquest').format(name=c.warrior.name)}
</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url('/dex/conquest')}">${_(u'Conquest')}</a></li>
    <li><a href="${url(controller='dex_conquest', action='warriors_list')}">${_(u'Warriors')}</a></a>
    <li>${c.warrior.name}</li>
</ul>
</%def>

<div id="dex-header">
    <a href="${url.current(name=c.prev_warrior.name.lower())}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${conqlib.warrior_image(c.prev_warrior, 'small-icons')}
        ${c.prev_warrior.name}
    </a>
    <a href="${url.current(name=c.next_warrior.name.lower())}" id="dex-header-next" class="dex-box-link">
        ${c.next_warrior.name}
        ${conqlib.warrior_image(c.next_warrior, 'small-icons')}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${conqlib.warrior_image(c.warrior, 'big-icons')}<br />
    ${c.warrior.name}
</div>

${h.h1(_('Essentials'))}

## Portrait block
<div class="dex-page-portrait dex-warrior-portrait">
    <p id="dex-page-name">${c.warrior.name}</p>
    <div class="dex-warrior-portrait-sprite">
        ${conqlib.warrior_image(c.warrior, 'portraits')}
    </div>
    <p id="dex-page-types">
        % for type in c.warrior.types:
        ${dexlib.type_link(type)}
        % endfor
    </p>
</div>

<div class="dex-page-beside-portrait">
<h2>${_(u'Warrior Skills')}</h2>
<dl class="pokemon-abilities">  <!-- Well sort of. -->
% for rank in c.warrior.ranks:
    % if c.rank_count > 1:
    <dt class="dex-warrior-skill-rank">${h.pokedex.conquest_rank_label[rank.rank]}</dt>
    % endif

    <dt class="dex-warrior-skill-name"><a href="${url(controller='dex_conquest', action='skills', name=rank.skill.name.lower())}">${rank.skill.name}</a></dt>
    <dd class="markdown">No effects yet.</dd>
% endfor
</dl>

<h2>${_(u'Perfect Links')}</h2>
% for link in c.perfect_links:
<span class="sprite-icon sprite-icon-${link.pokemon_species_id}"></span>\
% endfor

% if c.rank_count > 1:
<h2>${_(u'Warrior Transformation')}</h2>
<dl>
    % for rank in c.warrior.ranks:
    % if rank.transformation:
    <dt>${_(u'Rank {0}').format(h.pokedex.conquest_rank_label[rank.rank])}</dt>
    <dd>${conqlib.conquest_transformation_description(rank.transformation)}.</dd>
    % endif
    % endfor
</dl>
% endif
</div>


${h.h1(_(u'Stats'))}
% for n, rank in enumerate(c.stats):
% if c.rank_count > 1:
<h2>${_(u'Rank {0}').format(h.pokedex.conquest_rank_label[n + 1])}</h2>
% endif

<table class="dex-pokemon-stats">  <!-- Well, sort of... -->
<colgroup>
    <col class="dex-col-stat-name">
    <col class="dex-col-stat-bar">
    <col class="dex-col-stat-pctile">
</colgroup>

<thead>
    <tr class="header-row">
        <th><!-- stat name --></th>
        <th><!-- bar and value --></th>
        <th><abbr title="${_(u"Percentile rank")}">${_(u"Pctile")}</abbr></th>
    </tr>
</thead>

<tbody>
% for stat, value, percentile, color, border in rank:
    <tr class="color1">
        <th>${stat}</th>
        <td>
            <div class="dex-pokemon-stats-bar-container">
                <div class="dex-pokemon-stats-bar" style="margin-right: ${(1 - percentile) * 100}%; background-color: ${color}; border-color: ${border};">${value}</div>
            </div>
        </td>
        <td class="dex-pokemon-stats-pctile">${round(percentile * 100, 1)}</td>
    </tr>
% endfor
</tbody>
</table>
% endfor


${h.h1(_(u'Maximum Links'), id=_(u'max-links'))}
<p>${c.warrior.name}'s perfect links are highlighted in green.</p>

<p>
${_(u"""Note that {name} may not actually be able to obtain all these
Pokémon.  Before setting your heart on a particular Pokémon, check its
evolution conditions and make sure {name} can actually fulfil them.""").format(
    name=c.warrior.name,
)}
</p>

<form id="link-threshold" method="GET" action="${url.current()}#${_(u'max-links')}">
<p>
    Only show Pokémon with at least a ${c.link_form.link(size=3)}% link.
    <button type="submit">Go!</button>
</p>

% for error in c.link_form.link.errors:
<p class="error">${error}</p>
% endfor
</form>

<table class="dex-pokemon-moves striped-rows">
${conqlib.pokemon_table_columns(link_cols=c.rank_count)}
${conqlib.pokemon_table_header(link_cols=c.rank_count)}

<tbody>
    % for max_links in c.max_links:
    <tr class="${'perfect-link' if max_links[-1].max_link == 100 else ''}">
        % for link in max_links:
        <td class="max-link">${link.max_link}%</td>
        % endfor
        ${conqlib.pokemon_table_row(max_links[0].pokemon)}
    </tr>
    % endfor
</tbody>
</table>
