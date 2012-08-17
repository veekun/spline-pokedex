<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>
<%namespace name="conqlib" file="lib.mako"/>

<%! from splinext.pokedex import i18n %>

<%def name="title()">\
${_(u'{name} - Abilities - Pokémon Conquest').format(name=c.ability.name)}
</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url('/dex/conquest')}">${_(u'Conquest')}</a></li>
    <li><a href="${url(controller='dex_conquest', action='abilities_list')}">${_(u'Abilities')}</a></a>
    <li>${c.ability.name}</li>
</ul>
</%def>

<div id="dex-header">
    <a href="${url.current(name=c.prev_ability.name.lower())}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${c.prev_ability.name}
    </a>
    <a href="${url.current(name=c.next_ability.name.lower())}" id="dex-header-next" class="dex-box-link">
        ${c.next_ability.name}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${c.ability.name}

    % if c.ability.effect:
    <ul class="inline-menu">
        <li><a href="${url(controller='dex', action='abilities', name=c.ability.name.lower())}">Main</a></li>
        <li>${_(u'Conquest')}</li>
    </ul>
    % endif
</div>


${h.h1(u'Essentials')}
<div class="dex-page-portrait">
    <p id="dex-page-name">${c.ability.name}</p>
</div>

<div class="dex-page-beside-portrait">
<h2>${_(u'Summary')}</h2>
<p>No effects yet.</p>
</div>


${h.h1(u'Pokémon')}
<table class="dex-pokemon-moves striped-rows">
${conqlib.pokemon_table_columns()}
${conqlib.pokemon_table_header()}

<tbody>
    % for pokemon in c.ability.conquest_pokemon:
    <tr>
        ${conqlib.pokemon_table_row(pokemon)}
    </tr>
    % endfor
</tbody>
</table>
