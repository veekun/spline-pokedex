<%inherit file="/base.mako"/>

<h1>Sprites</h1>

<h2>Diamond/Pearl/Platinum</h2>
<table border="1">
<tr>
    <th></th>
    <th colspan="2">Platinum</th>
</tr>
<tr>
    <th class="vertical-text">Normal</th>
    <td>${h.HTML.img(src='/dex/images/platinum/%d.png' % c.pokemon.id, alt='')}</td>
    <td>${h.HTML.img(src='/dex/images/platinum/frame2/%d.png' % c.pokemon.id, alt='')}</td>
</tr>
% if c.pokemon.has_dp_fem_sprite:
<tr>
    <th><div class="vertical-text">Normal<br/>(female)</div></th>
    <td>${h.HTML.img(src='/dex/images/platinum/female/%d.png' % c.pokemon.id, alt='')}</td>
    <td>${h.HTML.img(src='/dex/images/platinum/female/frame2/%d.png' % c.pokemon.id, alt='')}</td>
</tr>
% endif
<tr>
    <th class="vertical-text">Shiny</th>
    <td>${h.HTML.img(src='/dex/images/platinum/shiny/%d.png' % c.pokemon.id, alt='')}</td>
    <td>${h.HTML.img(src='/dex/images/platinum/shiny/frame2/%d.png' % c.pokemon.id, alt='')}</td>
</tr>
% if c.pokemon.has_dp_fem_sprite:
<tr>
    <th class="vertical-text">Shiny<br/>(female)</th>
    <td>${h.HTML.img(src='/dex/images/platinum/shiny/female/%d.png' % c.pokemon.id, alt='')}</td>
    <td>${h.HTML.img(src='/dex/images/platinum/shiny/female/frame2/%d.png' % c.pokemon.id, alt='')}</td>
</tr>
% endif
</table>
