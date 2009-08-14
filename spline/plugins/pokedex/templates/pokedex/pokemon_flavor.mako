<%inherit file="/base.mako"/>

<%def name="title()">${c.pokemon.name}</%def>

<h1>Pokédex Description</h1>
% for generation, version_texts in sorted(c.flavor_text.items(), \
                                          key=lambda (k, v): k.id):
<div class="dex-pokemon-flavor-generation">${h.pokedex.generation_icon(generation)}</div>
<dl class="dex-pokemon-flavor-text">
    % for version, flavor_text in sorted(version_texts.items(), \
                                         key=lambda (k, v): k.id):
    <dt>${h.pokedex.version_icons(version)}</dt>
    <dd>${flavor_text}</dd>
    % endfor
</dl>
% endfor


<h1>Main Game Sprites</h1>

<h2>${h.pokedex.generation_icon(1)} Blue, Red &amp; Blue, Yellow</h2>
<table>
<tr class="header-row">
    <th></th>
    <td class="vertical-line" rowspan="2"></td>
    <th>Blue</th>
    <td class="vertical-line" rowspan="2"></td>
    <th>${h.pokedex.version_icons(u'Red', u'Blue')}</th>
    <td class="vertical-line" rowspan="2"></td>
    <th>${h.pokedex.version_icons(u'Yellow')}</th>
    <td class="vertical-line" rowspan="2"></td>
    <th></th>
</tr>
<tr>
    <th class="vertical-text">Normal</th>
    <td>${h.pokedex.pokedex_img('jp-blue/%d.png' % c.pokemon.id)}</td>
    <td>${h.pokedex.pokedex_img('red-blue/%d.png' % c.pokemon.id)}</td>
    <td>${h.pokedex.pokedex_img('yellow/%d.png' % c.pokemon.id)}</td>

    <td>${h.pokedex.pokedex_img('red-blue/back/%d.png' % c.pokemon.id)}</td>
</tr>
</table>

<h2>${h.pokedex.generation_icon(2)} Gold &amp; Silver, Crystal</h2>
<table>
<tr class="header-row">
    <th></th>
    <td class="vertical-line" rowspan="3"></td>
    <th>${h.pokedex.version_icons(u'Gold')}</th>
    <td class="vertical-line" rowspan="3"></td>
    <th>${h.pokedex.version_icons(u'Silver')}</th>
    <td class="vertical-line" rowspan="3"></td>
    <th>${h.pokedex.version_icons(u'Crystal')}</th>
    <td class="vertical-line" rowspan="3"></td>
    <th></th>
</tr>
<tr>
    <th class="vertical-text">Normal</th>
    <td>${h.pokedex.pokedex_img('gold/%d.png' % c.pokemon.id)}</td>
    <td>${h.pokedex.pokedex_img('silver/%d.png' % c.pokemon.id)}</td>
    <td>${h.pokedex.pokedex_img('crystal/%d.gif' % c.pokemon.id)}</td>

    <td>${h.pokedex.pokedex_img('gold/back/%d.png' % c.pokemon.id)}</td>
</tr>
<tr>
    <th class="vertical-text">Shiny</th>
    <td>${h.pokedex.pokedex_img('gold/shiny/%d.png' % c.pokemon.id)}</td>
    <td>${h.pokedex.pokedex_img('silver/shiny/%d.png' % c.pokemon.id)}</td>
    <td>${h.pokedex.pokedex_img('crystal/shiny/%d.gif' % c.pokemon.id)}</td>

    <td>${h.pokedex.pokedex_img('gold/back/shiny/%d.png' % c.pokemon.id)}</td>
</tr>
</table>

<h2>${h.pokedex.generation_icon(3)} Ruby &amp; Sapphire, Emerald, Fire Red &amp; Leaf Green</h2>
<table>
<tr class="header-row">
    <th></th>
    <td class="vertical-line" rowspan="3"></td>
    <th colspan="2">${h.pokedex.version_icons(u'Ruby', u'Sapphire')}</th>
    <td class="vertical-line" rowspan="3"></td>
    <th>${h.pokedex.version_icons(u'Emerald')}</th>
    <td class="vertical-line" rowspan="3"></td>
    <th colspan="2">${h.pokedex.version_icons(u'Fire Red', u'Leaf Green')}</th>
    <!-- XXX emerald animated? -->
</tr>
<tr>
    <th class="vertical-text">Normal</th>
    <td>${h.pokedex.pokedex_img('ruby-sapphire/%d.png' % c.pokemon.id)}</td>
    <td>${h.pokedex.pokedex_img('ruby-sapphire/back/%d.png' % c.pokemon.id)}</td>

    <td>${h.pokedex.pokedex_img('emerald/%d.png' % c.pokemon.id)}</td>
    <td>${h.pokedex.pokedex_img('firered-leafgreen/%d.png' % c.pokemon.id)}</td>
    <td>${h.pokedex.pokedex_img('firered-leafgreen/back/%d.png' % c.pokemon.id)}</td>
</tr>
<tr>
    <th class="vertical-text">Shiny</th>
    <td>${h.pokedex.pokedex_img('ruby-sapphire/shiny/%d.png' % c.pokemon.id)}</td>
    <td>${h.pokedex.pokedex_img('ruby-sapphire/back/shiny/%d.png' % c.pokemon.id)}</td>

    <td>${h.pokedex.pokedex_img('emerald/shiny/%d.png' % c.pokemon.id)}</td>
    <td>${h.pokedex.pokedex_img('firered-leafgreen/shiny/%d.png' % c.pokemon.id)}</td>
    <td>${h.pokedex.pokedex_img('firered-leafgreen/back/shiny/%d.png' % c.pokemon.id)}</td>
</tr>
</table>

<h2>${h.pokedex.generation_icon(4)} Diamond &amp; Pearl, Platinum</h2>
<% dpp_rowspan = 1 + 2 + (2 if c.pokemon.has_gen4_fem_sprite else 0) %>\
<table>
<tr class="header-row">
    <th></th>
    <td class="vertical-line" rowspan="${dpp_rowspan}"></td>
    <th colspan="2">${h.pokedex.version_icons(u'Diamond', u'Pearl')}</th>
    <td class="vertical-line" rowspan="${dpp_rowspan}"></td>
    <th colspan="2">${h.pokedex.version_icons(u'Platinum')}</th>
</tr>
<tr>
    <th class="vertical-text">Normal</th>
    <td>
        ${h.pokedex.pokedex_img('diamond-pearl/%d.png' % c.pokemon.id)}
        ${h.pokedex.pokedex_img('diamond-pearl/frame2/%d.png' % c.pokemon.id)}
    </td>
    <td>${h.pokedex.pokedex_img('diamond-pearl/back/%d.png' % c.pokemon.id)}</td>

    <td>
        ${h.pokedex.pokedex_img('platinum/%d.png' % c.pokemon.id)}
        ${h.pokedex.pokedex_img('platinum/frame2/%d.png' % c.pokemon.id)}
    </td>
    <td>
        ${h.pokedex.pokedex_img('platinum/back/%d.png' % c.pokemon.id)}
        ${h.pokedex.pokedex_img('platinum/back/frame2/%d.png' % c.pokemon.id)}
    </td>
</tr>
% if c.pokemon.has_gen4_fem_sprite:
<tr>
    <th><div class="vertical-text">Normal<br/>(female)</div></th>
    <td>
        ${h.pokedex.pokedex_img('diamond-pearl/female/%d.png' % c.pokemon.id)}
        ${h.pokedex.pokedex_img('diamond-pearl/female/frame2/%d.png' % c.pokemon.id)}
    </td>
    % if c.pokemon.has_gen4_fem_back_sprite:
    <td>${h.pokedex.pokedex_img('diamond-pearl/back/female/%d.png' % c.pokemon.id)}</td>
    % else:
    <td>n/a</td>
    % endif

    <td>
        ${h.pokedex.pokedex_img('platinum/female/%d.png' % c.pokemon.id)}
        ${h.pokedex.pokedex_img('platinum/female/frame2/%d.png' % c.pokemon.id)}
    </td>
    % if c.pokemon.has_gen4_fem_back_sprite:
    <td>
        ${h.pokedex.pokedex_img('platinum/back/female/%d.png' % c.pokemon.id)}
        ${h.pokedex.pokedex_img('platinum/back/female/frame2/%d.png' % c.pokemon.id)}
    </td>
    % else:
    <td>n/a</td>
    % endif
</tr>
% endif
<tr>
    <th class="vertical-text">Shiny</th>
    <td>
        ${h.pokedex.pokedex_img('diamond-pearl/shiny/%d.png' % c.pokemon.id)}
        ${h.pokedex.pokedex_img('diamond-pearl/shiny/frame2/%d.png' % c.pokemon.id)}
    </td>
    <td>${h.pokedex.pokedex_img('diamond-pearl/back/shiny/%d.png' % c.pokemon.id)}</td>

    <td>
        ${h.pokedex.pokedex_img('platinum/shiny/%d.png' % c.pokemon.id)}
        ${h.pokedex.pokedex_img('platinum/shiny/frame2/%d.png' % c.pokemon.id)}
    </td>
    <td>
        ${h.pokedex.pokedex_img('platinum/back/shiny/%d.png' % c.pokemon.id)}
        ${h.pokedex.pokedex_img('platinum/back/shiny/frame2/%d.png' % c.pokemon.id)}
    </td>
</tr>
% if c.pokemon.has_gen4_fem_sprite:
<tr>
    <th class="vertical-text">Shiny<br/>(female)</th>
    <td>
        ${h.pokedex.pokedex_img('diamond-pearl/shiny/female/%d.png' % c.pokemon.id)}
        ${h.pokedex.pokedex_img('diamond-pearl/shiny/female/frame2/%d.png' % c.pokemon.id)}
    </td>
    % if c.pokemon.has_gen4_fem_back_sprite:
    <td>${h.pokedex.pokedex_img('diamond-pearl/back/shiny/female/%d.png' % c.pokemon.id)}</td>
    % else:
    <td>n/a</td>
    % endif

    <td>
        ${h.pokedex.pokedex_img('platinum/shiny/female/%d.png' % c.pokemon.id)}
        ${h.pokedex.pokedex_img('platinum/shiny/female/frame2/%d.png' % c.pokemon.id)}
    </td>
    % if c.pokemon.has_gen4_fem_back_sprite:
    <td>
        ${h.pokedex.pokedex_img('platinum/back/shiny/female/%d.png' % c.pokemon.id)}
        ${h.pokedex.pokedex_img('platinum/back/shiny/female/frame2/%d.png' % c.pokemon.id)}
    </td>
    % else:
    <td>n/a</td>
    % endif
</tr>
% endif
</table>


<h1>Other Images</h1>

<h2>Sugimori Art</h2>
<p> ${h.pokedex.pokedex_img('sugimori/%d.png' % c.pokemon.id)} </p>
