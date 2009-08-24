<%inherit file="/base.mako"/>

<%def name="title()">${c.pokemon.name}</%def>

<h1>Pokédex Description</h1>
% for generation, version_texts in sorted(c.flavor_text.items(), \
                                          key=lambda (k, v): k.id):
<div class="dex-pokemon-flavor-generation">${h.pokedex.generation_icon(generation)}</div>
<dl class="dex-pokemon-flavor-text">
    % for versions, flavor_text in version_texts:
    <dt>${h.pokedex.version_icons(*versions)}</dt>
    <dd>${flavor_text}</dd>
    % endfor
</dl>
% endfor


<h1>Main Game Sprites</h1>
% if c.forms:
<h3>Forms</h3>
<ul class="inline">
% for form in c.forms:
    <li>${h.pokedex.pokemon_link(
            c.pokemon,
            h.pokedex.pokemon_sprite(c.pokemon, prefix='icons', form=form),
            to_flavor=True, form=form,
            class_='dex-icon-link',
    )}</li>
% endfor
</ul>
% endif

% if c.pokemon.generation_id <= 1:
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
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='jp-blue', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='red-blue', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='yellow', form=c.form)}</td>

    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='red-blue/back', form=c.form)}</td>
</tr>
</table>
% endif

% if c.pokemon.generation_id <= 2:
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
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='gold', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='silver', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='crystal', form=c.form)}</td>

    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='gold/back', form=c.form)}</td>
</tr>
<tr>
    <th class="vertical-text">Shiny</th>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='gold/shiny', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='silver/shiny', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='crystal/shiny', form=c.form)}</td>

    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='gold/back/shiny', form=c.form)}</td>
</tr>
</table>
% endif

% if c.pokemon.generation_id <= 3:
<% show_frlg = (c.pokemon.generation_id == 1 or c.pokemon.name == u'Teddiursa') %>\
<h2>${h.pokedex.generation_icon(3)} Ruby &amp; Sapphire, Emerald, Fire Red &amp; Leaf Green</h2>
<table>
<tr class="header-row">
    <th></th>
    <td class="vertical-line" rowspan="3"></td>
    <th colspan="2">${h.pokedex.version_icons(u'Ruby', u'Sapphire')}</th>
    <td class="vertical-line" rowspan="3"></td>
    <th>${h.pokedex.version_icons(u'Emerald')}</th>
% if show_frlg:
    <td class="vertical-line" rowspan="3"></td>
    <th colspan="2">${h.pokedex.version_icons(u'Fire Red', u'Leaf Green')}</th>
% endif
</tr>
<tr>
    <th class="vertical-text">Normal</th>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='ruby-sapphire', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='ruby-sapphire/back', form=c.form)}</td>

    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald/frame2', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald/animated', form=c.form)}
    </td>
% if show_frlg:
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='firered-leafgreen', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='firered-leafgreen/back', form=c.form)}</td>
% endif
</tr>
<tr>
    <th class="vertical-text">Shiny</th>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='ruby-sapphire/shiny', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='ruby-sapphire/back/shiny', form=c.form)}</td>

    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald/shiny', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald/shiny/frame2', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald/shiny/animated', form=c.form)}
    </td>
% if show_frlg:
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='firered-leafgreen/shiny', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='firered-leafgreen/back/shiny', form=c.form)}</td>
% endif
</tr>
</table>
% endif

% if c.pokemon.generation_id <= 4:
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
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/frame2', form=c.form)}
    </td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/back', form=c.form)}</td>

    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/back', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/back/frame2', form=c.form)}
    </td>
</tr>
% if c.pokemon.has_gen4_fem_sprite:
<tr>
    <th><div class="vertical-text">Normal<br/>(female)</div></th>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/female', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/female/frame2', form=c.form)}
    </td>
    % if c.pokemon.has_gen4_fem_back_sprite:
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/back/female', form=c.form)}</td>
    % else:
    <td>n/a</td>
    % endif

    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/female', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/female/frame2', form=c.form)}
    </td>
    % if c.pokemon.has_gen4_fem_back_sprite:
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/back/female', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/back/female/frame2', form=c.form)}
    </td>
    % else:
    <td>n/a</td>
    % endif
</tr>
% endif
<tr>
    <th class="vertical-text">Shiny</th>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/shiny', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/shiny/frame2', form=c.form)}
    </td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/back/shiny', form=c.form)}</td>

    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/shiny', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/shiny/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/back/shiny', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/back/shiny/frame2', form=c.form)}
    </td>
</tr>
% if c.pokemon.has_gen4_fem_sprite:
<tr>
    <th class="vertical-text">Shiny<br/>(female)</th>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/shiny/female', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/shiny/female/frame2', form=c.form)}
    </td>
    % if c.pokemon.has_gen4_fem_back_sprite:
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/back/shiny/female', form=c.form)}</td>
    % else:
    <td>n/a</td>
    % endif

    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/shiny/female', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/shiny/female/frame2', form=c.form)}
    </td>
    % if c.pokemon.has_gen4_fem_back_sprite:
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/back/shiny/female', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/back/shiny/female/frame2', form=c.form)}
    </td>
    % else:
    <td>n/a</td>
    % endif
</tr>
% endif
</table>
% endif


<h1>Other Images</h1>

<h2>Sugimori Art</h2>
<p> ${h.pokedex.pokedex_img('sugimori/%d.png' % c.pokemon.national_id)} </p>
