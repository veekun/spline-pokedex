<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako" />

<%! from splinext.pokedex import i18n %>\

<%def name="title()">Kingdoms - Pokémon Conquest</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url('/dex/conquest')}">${_(u'Conquest')}</a></li>
    <li>${_(u'Kingdoms')}</li>
</ul>
</%def>

${h.h1(_(u'Kingdom list'))}
<table class="dex-pokemon-moves striped-rows">
<thead>
    <tr class="header-row">
        <th>Name</th>
        <th>Type</th>
    </tr>
</thead>

<tbody>
    % for kingdom in c.kingdoms:
    <tr>
        <td><a href="${url(controller='dex_conquest', action='kingdoms', name=kingdom.name.lower())}">${kingdom.name}</a></td>
        <td>${h.pokedex.type_link(kingdom.type)}</td>
    </tr>
    % endfor
</tbody>
</table>

