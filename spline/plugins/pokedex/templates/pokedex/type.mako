<%inherit file="/base.mako"/>
<%namespace name="lib" file="lib.mako"/>
<%from pokedex.db import rst%>

<%def name="title()">${c.type.name.title()} — Type #${c.type.id}</%def>

<div id="dex-header">
    <a href="${url.current(name=c.prev_type.name)}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${c.prev_type.id}: ${h.pokedex.type_icon(c.prev_type)}
    </a>
    <a href="${url.current(name=c.next_type.name)}" id="dex-header-next" class="dex-box-link">
        ${c.next_type.id}: ${h.pokedex.type_icon(c.next_type)}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${c.type.id}: ${h.pokedex.type_icon(c.type)}
</div>

<h1 id="essentials"><a href="#essentials" class="subtle">Essentials</a></h1>

<div class="dex-page-portrait">
    <p id="dex-page-name">${c.type.name.title()}</p>
    <p id="dex-page-types">
        ${h.pokedex.type_icon(c.type)}
        ${h.pokedex.damage_class_icon(c.type.damage_class)}<span style="position: absolute" class="faded">*</span>
    </p>
    <p>${h.pokedex.generation_icon(c.type.generation)}</p>
    <br/>
    <p class="faded">*before ${h.pokedex.generation_icon(4)}</p>
</div>

<div class="dex-page-beside-portrait">
    <h2>Damage Dealt</h2>
    <ul class="dex-page-damage">
        ## always sort ??? last
        % for type in sorted(c.type.damage_efficacies, key=lambda type: (type.target_type.id == 18, type.target_type.name)):
        <li class="dex-damage-dealt-${type.damage_factor}">
             ${h.pokedex.type_link(type.target_type)} ${h.pokedex.type_efficacy_label[type.damage_factor]}
        </li>
        % endfor
    </ul>

    <h2>Damage Taken</h2>
    <ul class="dex-page-damage">
        % for type in sorted(c.type.target_efficacies, key=lambda type: (type.damage_type.id == 18, type.damage_type.name)):
        <li class="dex-damage-taken-${type.damage_factor}">
             ${h.pokedex.type_link(type.damage_type)} ${h.pokedex.type_efficacy_label[type.damage_factor]}
        </li>
        % endfor
    </ul>
</div>

<h1 id="pokemon"><a href="#pokemon" class="subtle">Pokémon</a></h1>
% if c.type.name == '???':
${h.literal(rst.RstString(u"""In Generation IV, pure :type:`flying`-types become ???-type during :move:`Roost`. This can be
accomplished with :move:`Conversion`, :move:`Conversion2`, or the ability :ability:`Color Change`. A Pokémon can legitimately have
both Roost and one of these only through the use of :move:`Mimic`, :move:`Sketch`, :move:`Role Play`, or :move:`Skill Swap`.  (No
Pokémon that has :ability:`Trace` or :ability:`Multitype` learns Roost, and Multitype cannot be copied.)

There are `sprites for a ???-type Arceus <{arceus_link}>`_ even though Arceus cannot become ???-type through regular play. Eggs are
purely ???-type before hatching, and are displayed as such in the Generation III status screen.""".format(
    arceus_link=url(controller='dex', action='pokemon_flavor', name='arceus', form='???')
)).as_html)}
% else:
<table class="dex-pokemon-moves striped-rows">
    ${lib.pokemon_table_columns()}
    <thead>
        <tr class="header-row">
            ${lib.pokemon_table_header()}
        </tr>
    </thead>
    <tbody>
        % for pokemon in c.pokemon:
        <tr>
            ${lib.pokemon_table_row(pokemon)}
        </tr>
        % endfor
    </tbody>
</table>
% endif

<h1 id="moves"><a href="#moves" class="subtle">Moves</a></h1>
<table class="dex-pokemon-moves striped-rows">
    <thead>
        <tr class="header-row">
            <th>Move</th>
            <th>Gen</th>
            <th>Class</th>
            <th>PP</th>
            <th>Power</th>
            <th>Acc</th>
            <th>Pri</th>
            <th>Effect</th>
        </tr>
    </thead>
    <tbody>
        % for move in c.moves:
        <tr>
            <td><a href="${url(controller='dex', action='moves', name=move.name.lower())}">${move.name}</a></td>
            <td>${h.pokedex.generation_icon(move.generation)}</td>
            <td>${h.pokedex.damage_class_icon(move.damage_class)}</td>
            <td>${move.pp}</td>
            <td>${move.power}</td>
            <td>${move.accuracy}%</td>
            ## Priority is colored red for slow and green for fast
            % if move.priority == 0:
            <td></td>
            % elif move.priority > 0:
            <td class="dex-priority-fast">${move.priority}</td>
            % else:
            <td class="dex-priority-slow">${move.priority}</td>
            % endif
            <td class="effect">${h.literal(move.short_effect.as_html)}</td>
        </tr>
        % endfor
    </tbody>
</table>

<h1 id="links"><a href="#links" class="subtle">External Links</a></h1>
<ul class="classic-list">
    % if c.type.generation.id <= 1:
    <li>${h.pokedex.generation_icon(1)} <a href="http://www.math.miami.edu/~jam/azure/pokedex/comp/${c.type.name}.htm">Azure Heights</a></li>
    % endif
    % if c.type.name == '???':
    <li><a href="http://bulbapedia.bulbagarden.net/wiki/%3F%3F%3F_(type)">Bulbapedia</a></li>
    <li><a href="http://www.smogon.com/dp/types/questionquestionquestion">Smogon</a></li>
    % else:
    <li><a href="http://bulbapedia.bulbagarden.net/wiki/${c.type.name.title()}_(type)">Bulbapedia</a></li>
    <li><a href="http://www.smogon.com/dp/types/${c.type.name}">Smogon</a></li>
    % endif
</ul>
