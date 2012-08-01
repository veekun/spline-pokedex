<%inherit file="/base.mako"/>

<%! from splinext.pokedex import i18n %>\

<%def name="title()">Moves - Pokémon Conquest</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url('/dex/conquest')}">${_(u'Conquest')}</a></li>
    <li>${_(u'Moves')}</li>
</ul>
</%def>

${h.h1(_(u'Move list'))}
<table class="striped-rows dex-pokemon-moves">
<thead>
    <tr class="header-row">
        <th>Name</th>
        <th>Type</th>
        <th>Summary</th>
    </tr>
</thead>

<tbody>
    % for move in c.moves:
    <tr>
        <td><a href="${url(controller='dex_conquest', action='moves', name=move.name.lower())}">${move.name}</a></td>
        <td>${h.pokedex.type_link(move.type)}</td>
        <td class="markdown effect"><p>No effects yet.</p></td>
    </tr>
    % endfor
</tbody>
</table>
