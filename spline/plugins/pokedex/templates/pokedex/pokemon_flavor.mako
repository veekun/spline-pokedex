<%inherit file="/base.mako"/>

<%def name="title()">${c.pokemon.name}</%def>

<ul class="see-also">
<li> <img src="${h.static_uri('spline', 'icons/arrow-180-medium.png')}" alt="See also:"> <a href="${url.current(action='pokemon')}">Return to main Pokédex page</a> </li>
</ul>

<h1>Pokédex Description</h1>
% for generation, version_texts in sorted(c.flavor_text.items(), \
                                          key=lambda (k, v): k.id):
<div class="dex-pokemon-flavor-generation">${h.pokedex.generation_icon(generation)}</div>
<dl class="dex-pokemon-flavor-text">
<%
    class_ = ''
    if session.get('cheat_obdurate', False):
        class_ = ' class="dex-obdurate"'
%>\
    % for versions, flavor_text in version_texts:
    <dt>${h.pokedex.version_icons(*versions)}</dt>
    <dd${h.literal(class_)}>${flavor_text}</dd>
    % endfor
</dl>
% endfor


<h1>Main Game Portraits</h1>
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

% if c.introduced_in.id <= 2:
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

% if c.introduced_in.id <= 4:
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

% if c.introduced_in.id <= 7:
<% show_rusa = not (c.pokemon.name == u'Deoxys' and c.form) %>\
<% show_emerald = not (c.pokemon.name == u'Deoxys' and c.form != 'speed') %>\
<% show_frlg = (c.pokemon.generation_id == 1
                or c.pokemon.name == u'Teddiursa'
                or (c.pokemon.name == u'Deoxys' and c.form in ('attack', 'defense'))) %>\
<h2>${h.pokedex.generation_icon(3)} Ruby &amp; Sapphire, Emerald, Fire Red &amp; Leaf Green</h2>
## Deoxys is a giant mess.
## Normal only exists in R/S; Speed only in Emerald; Attack only in LG; Defense only in FR.
<table>
<tr class="header-row">
    <th></th>
% if show_rusa:
    <td class="vertical-line" rowspan="3"></td>
    <th colspan="2">${h.pokedex.version_icons(u'Ruby', u'Sapphire')}</th>
% endif
% if show_emerald:
    <td class="vertical-line" rowspan="3"></td>
    <th>${h.pokedex.version_icons(u'Emerald')}</th>
% endif
% if show_frlg:
    <td class="vertical-line" rowspan="3"></td>
    <th colspan="2">${h.pokedex.version_icons(u'Fire Red', u'Leaf Green')}</th>
% endif
</tr>
<tr>
    <th class="vertical-text">Normal</th>
% if show_rusa:
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='ruby-sapphire', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='ruby-sapphire/back', form=c.form)}</td>
% endif

% if show_emerald:
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald/frame2', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald/animated', form=c.form)}
    </td>
% endif

% if show_frlg:
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='firered-leafgreen', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='firered-leafgreen/back', form=c.form)}</td>
% endif
</tr>
<tr>
    <th class="vertical-text">Shiny</th>
% if show_rusa:
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='ruby-sapphire/shiny', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='ruby-sapphire/back/shiny', form=c.form)}</td>
% endif

% if show_emerald:
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald/shiny', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald/shiny/frame2', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald/shiny/animated', form=c.form)}
    </td>
% endif

% if show_frlg:
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='firered-leafgreen/shiny', form=c.form)}</td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='firered-leafgreen/back/shiny', form=c.form)}</td>
% endif
</tr>
</table>
% endif

% if c.pokemon.generation_id <= 4:
<h2>${h.pokedex.generation_icon(4)} Diamond &amp; Pearl, Platinum, Heart Gold &amp; Soul Silver</h2>
<% dpp_rowspan = 1 + 2 + (3 if c.pokemon.has_gen4_fem_sprite else 0) %>\
<table>
<tr class="header-row">
    <th></th>
    ## Rotom forms only exist beyond Platinum
    % if c.introduced_in.id <= 8:
    <td class="vertical-line" rowspan="${dpp_rowspan}"></td>
    <th colspan="2">${h.pokedex.version_icons(u'Diamond', u'Pearl')}</th>
    % endif
    % if c.introduced_in.id <= 9:
    <td class="vertical-line" rowspan="${dpp_rowspan}"></td>
    <th colspan="2">${h.pokedex.version_icons(u'Platinum')}</th>
    % endif
    <td class="vertical-line" rowspan="${dpp_rowspan}"></td>
    <th colspan="2">${h.pokedex.version_icons(u'Heart Gold', u'Soul Silver')}</th>
</tr>
<tr>
    <th class="vertical-text">
        Normal
        % if c.pokemon.has_gen4_fem_back_sprite:
        <br/> (male)
        % endif
    </th>
    % if c.introduced_in.id <= 8:
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/frame2', form=c.form)}
    </td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/back', form=c.form)}</td>
    % endif

    % if c.introduced_in.id <= 9:
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/back', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/back/frame2', form=c.form)}
    </td>
    % endif

    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/back', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/back/frame2', form=c.form)}
    </td>
</tr>
<tr>
    <th class="vertical-text">
        Shiny
        % if c.pokemon.has_gen4_fem_back_sprite:
        <br/> (male)
        % endif
    </th>
    % if c.introduced_in.id <= 8:
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/shiny', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/shiny/frame2', form=c.form)}
    </td>
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/back/shiny', form=c.form)}</td>
    % endif

    % if c.introduced_in.id <= 9:
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/shiny', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/shiny/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/back/shiny', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='platinum/back/shiny/frame2', form=c.form)}
    </td>
    % endif

    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/shiny', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/shiny/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/back/shiny', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/back/shiny/frame2', form=c.form)}
    </td>
</tr>
% if c.pokemon.has_gen4_fem_sprite:
<tr class="horizontal-line"></tr>
<tr>
    <th><div class="vertical-text">Normal<br/>(female)</div></th>
    % if c.introduced_in.id <= 8:
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/female', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/female/frame2', form=c.form)}
    </td>
    % if c.pokemon.has_gen4_fem_back_sprite:
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/back/female', form=c.form)}</td>
    % else:
    <td>n/a</td>
    % endif
    % endif

    % if c.introduced_in.id <= 9:
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
    % endif

    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/female', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/female/frame2', form=c.form)}
    </td>
    % if c.pokemon.has_gen4_fem_back_sprite:
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/back/female', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/back/female/frame2', form=c.form)}
    </td>
    % else:
    <td>n/a</td>
    % endif
</tr>
<tr>
    <th class="vertical-text">Shiny<br/>(female)</th>
    % if c.introduced_in.id <= 8:
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/shiny/female', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/shiny/female/frame2', form=c.form)}
    </td>
    % if c.pokemon.has_gen4_fem_back_sprite:
    <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/back/shiny/female', form=c.form)}</td>
    % else:
    <td>n/a</td>
    % endif
    % endif

    % if c.introduced_in.id <= 9:
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
    % endif

    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/shiny/female', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/shiny/female/frame2', form=c.form)}
    </td>
    % if c.pokemon.has_gen4_fem_back_sprite:
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/back/shiny/female', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver/back/shiny/female/frame2', form=c.form)}
    </td>
    % else:
    <td>n/a</td>
    % endif
</tr>
% endif
</table>
% endif


<h1>Miscellaneous Game Art</h1>

% if c.pokemon.generation_id <= 4:
<h2> ${h.pokedex.version_icons(u'Heart Gold', u'Soul Silver')} Heart Gold &amp; Soul Silver Overworld </h2>
<% ow_rowspan = 1 + 2 + (3 if c.pokemon.has_gen4_fem_sprite else 0) %>\
<table>
<tr class="header-row">
    % if c.pokemon.has_gen4_fem_sprite:
    <th></th>
    <td class="vertical-line" rowspan="${ow_rowspan}"></td>
    % endif
    <th>Left</th>
    <td class="vertical-line" rowspan="${ow_rowspan}"></td>
    <th>Down</th>
    <td class="vertical-line" rowspan="${ow_rowspan}"></td>
    <th>Up</th>
    <td class="vertical-line" rowspan="${ow_rowspan}"></td>
    <th>Right</th>
</tr>
<tr>
    % if c.pokemon.has_gen4_fem_sprite:
    <th class="vertical-text" rowspan="2">Male</th>
    % endif
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/left', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/left/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/down/frame2', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/down', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/up', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/up/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/right', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/right/frame2', form=c.form)}
    </td>
</tr>
<tr>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/left', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/left/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/down/frame2', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/down', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/up', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/up/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/right', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/right/frame2', form=c.form)}
    </td>
</tr>
% if c.pokemon.has_gen4_fem_sprite:
<tr class="horizontal-line"></tr>
<tr>
    <th class="vertical-text" rowspan="2">Female</th>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/female/left', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/female/left/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/female/down/frame2', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/female/down', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/female/up', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/female/up/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/female/right', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/female/right/frame2', form=c.form)}
    </td>
</tr>
<tr>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/female/left', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/female/left/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/female/down/frame2', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/female/down', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/female/up', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/female/up/frame2', form=c.form)}
    </td>
    <td>
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/female/right', form=c.form)}
        ${h.pokedex.pokemon_sprite(c.pokemon, prefix='overworld/shiny/female/right/frame2', form=c.form)}
    </td>
</tr>
% endif
</table>
% endif



<h1>Other Images</h1>

<h2>Sugimori Art</h2>
<p> ${h.pokedex.pokedex_img('sugimori/%d.png' % c.pokemon.national_id)} </p>
