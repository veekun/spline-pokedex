<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="lib.mako" />
<%! from splinext.pokedex import i18n %>\

<%def name="title()">Abilities</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li>${_(u"Abilities")}</li>
</ul>
</%def>

${h.h1(_('Ability list'))}

<table class="striped-rows dex-ability-list">
<colgroup span="2"></colgroup> <!-- ID, gen -->
<colgroup span="1"></colgroup> <!-- name -->
<colgroup span="1"></colgroup> <!-- summary -->
<thead>
    <tr class="header-row">
        <th>${_(u"ID")}</th>
        <th>${_(u"Gen")}</th>
        <th>${_(u"Name")}</th>
        <th>${_(u"Summary")}</th>
    </tr>
</thead>
<tbody>
    % for ability in c.abilities:
    <tr>
        <td class="number-cell">${ability.id}</td>
        <td>${h.pokedex.generation_icon(ability.generation)}</td>
        <td><a href="${url(controller='dex', action='abilities', name=ability.name.lower())}">${ability.name}</a></td>
        <td class="markdown effect">${ability.short_effect}</td>
    </tr>
    % endfor
</tbody>
</table>

