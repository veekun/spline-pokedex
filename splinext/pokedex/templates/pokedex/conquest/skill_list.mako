<%inherit file="/base.mako"/>
<%namespace name="conqlib" file="lib.mako"/>

<%! from splinext.pokedex import i18n %>\

<%def name="title()">Warrior Skills - Pokémon Conquest</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url('/dex/conquest')}">${_(u'Conquest')}</a></li>
    <li>${_(u'Warrior Skills')}</li>
</ul>
</%def>

${h.h1(_(u'Skill list'))}
<h2>Generic skills</h2>
<table class="striped-rows dex-ability-list">
<thead>
    <tr class="header-row">
        <th>Name</th>
        <th>Summary</th>
    </tr>
</thead>

<tbody>
    % for skill in c.generic_skills:
    <tr>
        <td><a href="${url(controller='dex_conquest', action='skills', name=skill.name.lower())}">${skill.name}</a></td>
        <td class="markdown effect"><p>No effects yet.</p></td>
    </tr>
    % endfor
</tbody>
</table>

<h2>Unique skills</h2>
<table class="striped-rows dex-ability-list">
<thead>
    <tr class="header-row">
        <th>Name</th>
        <th>Summary</th>
        <th colspan="2">Warrior</th>
    </tr>
</thead>

<tbody>
    % for skill in c.unique_skills:
    <tr>
        <td><a href="${url(controller='dex_conquest', action='skills', name=skill.name.lower())}">${skill.name}</a></td>
        <td class="markdown effect"><p>No effects yet.</p></td>
        <%
        if len(skill.warrior_ranks) == 2:
            rank = skill.warrior_ranks[c.player_index]
            name = _(u'Player')
        else:
            rank, = skill.warrior_ranks
            name = rank.warrior.name
        %>
        <td>${conqlib.warrior_image(rank.warrior, 'small-icons', rank=rank.rank)}</td>
        <td><a href="${url(controller='dex_conquest', action='warriors', name=rank.warrior.name.lower())}">${name}</a></td>
    </tr>
    % endfor
</tbody>
</table>
