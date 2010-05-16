<%inherit file="/base.mako"/>
<%namespace name='dexlib' file='lib.mako'/>

<%def name="title()">${c.ability.name} – Ability #${c.ability.id}</%def>

<div id="dex-header">
    <a href="${url.current(name=c.prev_ability.name.lower(), form=None)}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${c.prev_ability.id}: ${c.prev_ability.name}
    </a>
    <a href="${url.current(name=c.next_ability.name.lower(), form=None)}" id="dex-header-next" class="dex-box-link">
        ${c.next_ability.id}: ${c.next_ability.name}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${c.ability.id}: ${c.ability.name}
</div>

${h.h1('Essentials')}

<div class="dex-page-portrait">
    <p id="dex-page-name">${c.ability.name}</p>
    <p>${h.pokedex.generation_icon(c.ability.generation)}</p>
</div>

<div class="dex-page-beside-portrait">
    <h2>Summary</h2>
    <p>${h.literal(c.ability.short_effect.as_html)}</p>
</div>

${h.h1('Effect')}
<div class="dex-effect">
    ${h.literal(c.ability.effect.as_html)}
</div>
<h2>Flavor Text</h2>
<dl class="dex-pokemon-flavor-text">
    % for flavor_text in c.ability.flavor_text:
<%
    text = flavor_text.flavor_text
    text = text.replace('-\n', '-')
    text = text.replace('\n', ' ')
%>
    <dt>${h.pokedex.version_icons(*flavor_text.version_group.versions)}</dt>
    <dd>${text}</dd>
    % endfor
</dl>

${h.h1(u'Pokémon', id='pokemon')}
<table class="dex-pokemon-moves striped-rows">
    ${dexlib.pokemon_table_columns()}
    <thead>
        <tr class="header-row">
            ${dexlib.pokemon_table_header()}
        </tr>
    </thead>
    <tbody>
        % for pokemon in c.pokemon:
        <tr>
            ${dexlib.pokemon_table_row(pokemon)}
        </tr>
        % endfor
    </tbody>
</table>
