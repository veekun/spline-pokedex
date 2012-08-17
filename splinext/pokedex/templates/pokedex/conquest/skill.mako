<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>
<%namespace name="conqlib" file="lib.mako"/>

<%! from splinext.pokedex import i18n %>

<%def name="title()">\
${_(u'{name} - Warrior Skills - Pokémon Conquest').format(name=c.skill.name)}
</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url('/dex/conquest')}">${_(u'Conquest')}</a></li>
    <li><a href="${url(controller='dex_conquest', action='skills_list')}">${_(u'Warrior Skills')}</a></a>
    <li>${c.skill.name}</li>
</ul>
</%def>

<div id="dex-header">
    <a href="${url.current(name=c.prev_skill.name.lower())}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${c.prev_skill.name}
    </a>
    <a href="${url.current(name=c.next_skill.name.lower())}" id="dex-header-next" class="dex-box-link">
        ${c.next_skill.name}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${c.skill.name}
</div>


${h.h1(u'Essentials')}
<div class="dex-page-portrait">
    <p id="dex-page-name">${c.skill.name}</p>
</div>

<div class="dex-page-beside-portrait">
    <h2>${_(u'Summary')}</h2>
    <p>No effects yet.</p>
</div>


${h.h1(u'Warriors')}
<table class="striped-rows dex-pokemon-moves dex-warriors">
${conqlib.warrior_table_columns()}
${conqlib.warrior_table_header()}

% for warrior_rank in c.skill.warrior_ranks:
<tr>
    ${conqlib.warrior_table_row(warrior_rank.warrior, icon_rank=warrior_rank.rank)}
</tr>
% endfor
</table>
