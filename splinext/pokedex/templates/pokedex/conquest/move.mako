<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>
<%namespace name="conqlib" file="lib.mako"/>

<%! from splinext.pokedex import i18n %>

<%def name="title()">\
${_(u'{name} - Moves - Pokémon Conquest').format(name=c.move.name)}
</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url('/dex/conquest')}">${_(u'Conquest')}</a></li>
    <li><a href="${url(controller='dex_conquest', action='moves_list')}">${_(u'Moves')}</a></a>
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
</div>


${h.h1(u'Essentials')}
<div class="dex-page-portrait">
    <p id="dex-page-name">${c.move.name}</p>
    <p id="dex-page-types">${h.pokedex.type_link(c.move.type)}</p>
</div>

<div class="dex-page-beside-portrait">
    <h2>${_(u'Summary')}</h2>
    <p>No effects yet.</p>

    <h2>${_(u"Damage Dealt")}</h2>
    <ul class="dex-type-list">
        % for type_efficacy in sorted(c.move.type.damage_efficacies, key=lambda efficacy: efficacy.target_type.name):
        <li class="dex-damage-dealt-${type_efficacy.damage_factor}">
            ${h.pokedex.type_link(type_efficacy.target_type)} ${h.pokedex.type_efficacy_label[type_efficacy.damage_factor]}
        </li>
        % endfor
    </ul>
</div>


${h.h1(u'Pokémon')}
<table class="dex-pokemon-moves striped-rows">
${conqlib.pokemon_table_columns()}
${conqlib.pokemon_table_header()}

<tbody>
    % for pokemon in c.move.conquest_pokemon:
    <tr>
        ${conqlib.pokemon_table_row(pokemon)}
    </tr>
    % endfor
</tbody>
</table>
