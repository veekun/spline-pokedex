<%inherit file="/base.mako"/>

<%! from splinext.pokedex import i18n %>\

<%def name="title()">Abilities - Pokémon Conquest</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url('/dex/conquest')}">${_(u'Conquest')}</a></li>
    <li>${_(u'Abilities')}</li>
</ul>
</%def>

${h.h1(_(u'Ability list'))}
<table class="striped-rows dex-ability-list">
<thead>
    <tr class="header-row">
        <th>Name</th>
        <th>Summary</th>
    </tr>
</thead>

<tbody>
    % for ability in c.abilities:
    <tr>
        <td><a href="${url(controller='dex_conquest', action='abilities', name=ability.name.lower())}">${ability.name}</a></td>
        <td class="markdown effect"><p>No effects yet.</p></td>
    </tr>
    % endfor
</tbody>
</table>
