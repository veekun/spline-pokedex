<%inherit file="/base.mako"/>

<%def name="title()">Abilities</%def>

${h.h1('Ability list')}

<table class="striped-rows dex-ability-list">
## gross!  I'm just going with what the nature list does :|
<col>
<col>
<col class="dex-col-first-version">
<col class="dex-col-first-version">
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
        <td>${h.literal(ability.short_effect.as_html)}</td>
    </tr>
    % endfor
</tbody>
</table>

