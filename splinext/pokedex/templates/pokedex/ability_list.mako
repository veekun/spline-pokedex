<%inherit file="/base.mako"/>

<%def name="title()">Abilities</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li>Abilities</li>
</ul>
</%def>

${h.h1('Ability list')}

<table class="striped-rows dex-ability-list">
<colgroup span="2"></colgroup> <!-- #, gen -->
<colgroup span="1"></colgroup> <!-- name -->
<colgroup span="1"></colgroup> <!-- summary -->
<thead>
    <tr class="header-row">
        <th>#</th>
        <th>Gen</th>
        <th>Name</th>
        <th>Summary</th>
    </tr>
</thead>
<tbody>
    % for ability in c.abilities:
    <tr>
        <td class="number-cell">${ability.id}</td>
        <td>${h.pokedex.generation_icon(ability.generation)}</td>
        <td><a href="${url(controller='dex', action='abilities', name=ability.name.lower())}">${ability.name}</a></td>
        <td class="markdown effect">${ability.short_effect.as_html | n}</td>
    </tr>
    % endfor
</tbody>
</table>

