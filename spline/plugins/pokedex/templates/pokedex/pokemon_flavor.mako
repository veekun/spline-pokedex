<%inherit file="/base.mako"/>
<%namespace name="lib" file="/pokedex/lib.mako"/>

<h1>Sprites</h1>

<h2>Diamond/Pearl/Platinum</h2>
<table border="1">
<tr>
    <th></th>
    <th colspan="3">${lib.version_icons('Diamond', 'Pearl')}<br/>Diamond/Pearl</th>
    <th colspan="2">${lib.version_icons('Platinum')}<br/>Platinum</th>
</tr>
<tr>
    <th class="vertical-text">Normal</th>
    <td>${lib.pokedex_img('diamond-pearl/%d.png' % c.pokemon.id)}</td>
    <td>${lib.pokedex_img('diamond-pearl/frame2/%d.png' % c.pokemon.id)}</td>
    <td>${lib.pokedex_img('diamond-pearl/back/%d.png' % c.pokemon.id)}</td>
    <td>${lib.pokedex_img('platinum/%d.png' % c.pokemon.id)}</td>
    <td>${lib.pokedex_img('platinum/frame2/%d.png' % c.pokemon.id)}</td>
</tr>
% if c.pokemon.has_dp_fem_sprite:
<tr>
    <th><div class="vertical-text">Normal<br/>(female)</div></th>
    <td>${lib.pokedex_img('diamond-pearl/female/%d.png' % c.pokemon.id)}</td>
    <td>${lib.pokedex_img('diamond-pearl/female/frame2/%d.png' % c.pokemon.id)}</td>
    % if c.pokemon.has_dp_fem_back_sprite:
    <td>${lib.pokedex_img('diamond-pearl/back/female/%d.png' % c.pokemon.id)}</td>
    % else:
    <td>n/a</td>
    % endif
    <td>${lib.pokedex_img('platinum/female/%d.png' % c.pokemon.id)}</td>
    <td>${lib.pokedex_img('platinum/female/frame2/%d.png' % c.pokemon.id)}</td>
</tr>
% endif
<tr>
    <th class="vertical-text">Shiny</th>
    <td>${lib.pokedex_img('diamond-pearl/shiny/%d.png' % c.pokemon.id)}</td>
    <td>${lib.pokedex_img('diamond-pearl/shiny/frame2/%d.png' % c.pokemon.id)}</td>
    <td>${lib.pokedex_img('diamond-pearl/back/shiny/%d.png' % c.pokemon.id)}</td>
    <td>${lib.pokedex_img('platinum/shiny/%d.png' % c.pokemon.id)}</td>
    <td>${lib.pokedex_img('platinum/shiny/frame2/%d.png' % c.pokemon.id)}</td>
</tr>
% if c.pokemon.has_dp_fem_sprite:
<tr>
    <th class="vertical-text">Shiny<br/>(female)</th>
    <td>${lib.pokedex_img('diamond-pearl/shiny/female/%d.png' % c.pokemon.id)}</td>
    <td>${lib.pokedex_img('diamond-pearl/shiny/female/frame2/%d.png' % c.pokemon.id)}</td>
    % if c.pokemon.has_dp_fem_back_sprite:
    <td>${lib.pokedex_img('diamond-pearl/back/shiny/female/%d.png' % c.pokemon.id)}</td>
    % else:
    <td>n/a</td>
    % endif
    <td>${lib.pokedex_img('platinum/shiny/female/%d.png' % c.pokemon.id)}</td>
    <td>${lib.pokedex_img('platinum/shiny/female/frame2/%d.png' % c.pokemon.id)}</td>
</tr>
% endif
</table>
