<%inherit file="/base.mako"/>
<%namespace name="lib" file="lib.mako"/>
<%! import re %>\

<%def name="title()">\
% if c.pokemon.name == 'Unown' and c.form:
Unown ${c.form.capitalize()} \
% else:
${c.form.title() if c.form else u''} ${c.pokemon.name} \
% endif
– Pokémon #${c.pokemon.national_id} – Flavor\
</%def>

${lib.pokemon_page_header()}

${h.h1(u'Pokédex Description', id='pokedex')}
<% obdurate = session.get('cheat_obdurate', False) %>\
% for generation in sorted(c.flavor_text):
<div class="dex-pokemon-flavor-generation">${h.pokedex.generation_icon(generation)}</div>
<dl class="dex-pokemon-flavor-text">
% for flavor_text_group in c.flavor_text[generation]:
    <dt>${h.pokedex.version_icons(*(text.version for text in flavor_text_group))}</dt>
    <dd${' class="dex-obdurate"' if obdurate else '' | n}>${h.pokedex.render_flavor_text(flavor_text_group[0].flavor_text, literal=obdurate)}</dd>
% endfor
</dl>

% endfor


${h.h1('Main Game Portraits', id='main-sprites')}
% if c.forms:
<h3>Forms</h3>
<ul class="inline">
% for form in c.forms:
    <li>${h.pokedex.pokemon_link(
            c.pokemon,
            h.pokedex.pokemon_sprite(c.pokemon, prefix='heartgold-soulsilver', form=form),
            to_flavor=True, form=form,
            class_='dex-icon-link' + (' selected' if form == c.form else ''),
    )}</li>
% endfor
</ul>
<p> ${c.pokemon.normal_form.form_group.description} </p>
% endif

% if c.introduced_in.id <= 2:
<h2 id="main-sprites:gen-i"><a href="#main-sprites:gen-i" class="subtle">${h.pokedex.generation_icon(1)} Red &amp; Green, Red &amp; Blue, Yellow</a></h2>
<table class="dex-pokemon-flavor-sprites">
<colgroup span="1"></colgroup> <!-- row headers -->
<colgroup span="2"></colgroup> <!-- 赤い/緑 -->
<colgroup span="2"></colgroup> <!-- Red/Blue -->
<colgroup span="2"></colgroup> <!-- Yellow -->
<thead>
    <tr class="header-row">
        <th></th>
        <th colspan="2">${h.pokedex.version_icons(u'赤い', u'緑')}</th>
        <th colspan="2">${h.pokedex.version_icons(u'Red', u'Blue')}</th>
        <th colspan="2">${h.pokedex.version_icons(u'Yellow')}</th>
    </tr>
</thead>
<tbody>
    <tr>
        <th class="vertical-text">GB</th>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='red-green/gray', form=c.form)}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_sprite(c.pokemon, prefix='red-green/back/gray', form=c.form)}</td>

        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='red-blue/gray', form=c.form)}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_sprite(c.pokemon, prefix='red-blue/back/gray', form=c.form)}</td>

        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='yellow/gray', form=c.form)}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_sprite(c.pokemon, prefix='yellow/back/gray', form=c.form)}</td>
    </tr>
    <tr>
        <th class="vertical-text">SGB</th>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='red-green', form=c.form)}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_sprite(c.pokemon, prefix='red-green/back', form=c.form)}</td>

        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='red-blue', form=c.form)}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_sprite(c.pokemon, prefix='red-blue/back', form=c.form)}</td>

        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='yellow', form=c.form)}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_sprite(c.pokemon, prefix='yellow/back', form=c.form)}</td>
    </tr>
    <tr>
        <th class="vertical-text">GBC</th>
        <td colspan="2" class="dex-pokemon-flavor-no-sprite">—</td>

        <td colspan="2" class="dex-pokemon-flavor-no-sprite">—</td>

        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='yellow/gbc', form=c.form)}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_sprite(c.pokemon, prefix='yellow/back/gbc', form=c.form)}</td>
    </tr>
</tbody>
</table>
% endif

% if c.introduced_in.id <= 4:
<h2 id="main-sprites:gen-ii"><a href="#main-sprites:gen-ii" class="subtle">${h.pokedex.generation_icon(2)} Gold &amp; Silver, Crystal</a></h2>
<table class="dex-pokemon-flavor-sprites">
<colgroup span="1"></colgroup> <!-- row headers -->
<colgroup span="2"></colgroup> <!-- Gold -->
<colgroup span="2"></colgroup> <!-- Silver -->
<colgroup span="2"></colgroup> <!-- Crystal -->
<thead>
    <tr class="header-row">
        <th></th>
        <th colspan="2">${h.pokedex.version_icons(u'Gold')}</th>
        <th colspan="2">${h.pokedex.version_icons(u'Silver')}</th>
        <th colspan="2">${h.pokedex.version_icons(u'Crystal')}</th>
    </tr>
</thead>
<tbody>
    <tr>
        <th class="vertical-text">Normal</th>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='gold', form=c.form)}</td>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='gold/back', form=c.form)}</td>

        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='silver', form=c.form)}</td>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='silver/back', form=c.form)}</td>

        <td>
            ${h.pokedex.pokemon_sprite(c.pokemon, prefix='crystal', form=c.form)}
            ${h.pokedex.pokemon_sprite(c.pokemon, prefix='crystal/animated', form=c.form)}
        </td>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='crystal/back', form=c.form)}</td>
    </tr>
    <tr>
        <th class="vertical-text">Shiny</th>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='gold/shiny', form=c.form)}</td>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='gold/back/shiny', form=c.form)}</td>

        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='silver/shiny', form=c.form)}</td>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='silver/back/shiny', form=c.form)}</td>

        <td>
            ${h.pokedex.pokemon_sprite(c.pokemon, prefix='crystal/shiny', form=c.form)}
            ${h.pokedex.pokemon_sprite(c.pokemon, prefix='crystal/animated/shiny', form=c.form)}
        </td>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='crystal/back/shiny', form=c.form)}</td>
    </tr>
</tbody>
</table>
% endif

% if c.introduced_in.id <= 7:
<% show_rusa = (c.pokemon.name != u'Deoxys' or c.form == u'normal') %>\
<% show_emerald = (c.pokemon.name != u'Deoxys' or c.form in (u'speed', u'normal')) %>\
<% show_frlg = (c.pokemon.generation_id == 1
                or c.pokemon.name == u'Teddiursa'
                or (c.pokemon.name == u'Deoxys' and c.form in (u'attack', u'defense', u'normal'))) %>\
<h2 id="main-sprites:gen-iii"><a href="#main-sprites:gen-iii" class="subtle">${h.pokedex.generation_icon(3)} Ruby &amp; Sapphire, Emerald, Fire Red &amp; Leaf Green</a></h2>
## Deoxys is a bit of a mess.
## Normal exists everywhere.  Speed only in Emerald; Attack only in LG; Defense only in FR.
<table class="dex-pokemon-flavor-sprites">
<colgroup span="1"></colgroup> <!-- row headers -->
% if show_rusa:
<colgroup span="2"></colgroup> <!-- Ruby/Sapphire -->
% endif
% if show_emerald:
<colgroup span="1"></colgroup> <!-- Emerald—no backsprites -->
% endif
% if show_frlg:
<colgroup span="2"></colgroup> <!-- FireRed/LeafGreen -->
% endif
<thead>
    <tr class="header-row">
        <th></th>
    % if show_rusa:
        <th colspan="2">${h.pokedex.version_icons(u'Ruby', u'Sapphire')}</th>
    % endif
    % if show_emerald:
        <th>${h.pokedex.version_icons(u'Emerald')}</th>
    % endif
    % if show_frlg:
        <th colspan="2">${h.pokedex.version_icons(u'Fire Red', u'Leaf Green')}</th>
    % endif
    </tr>
</thead>
<tbody>
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
            ## Emerald animations don't exist for forms that only exist after a battle starts
            % if c.appears_in_overworld:
            ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald/animated', form=c.form)}
            % endif
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
            % if c.appears_in_overworld:
            ${h.pokedex.pokemon_sprite(c.pokemon, prefix='emerald/shiny/animated', form=c.form)}
            % endif
        </td>
    % endif

    % if show_frlg:
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='firered-leafgreen/shiny', form=c.form)}</td>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='firered-leafgreen/back/shiny', form=c.form)}</td>
    % endif
    </tr>
</tbody>
</table>
% endif

% if c.pokemon.generation_id <= 4:
<h2 id="main-sprites:gen-iv"><a href="#main-sprites:gen-iv" class="subtle">${h.pokedex.generation_icon(4)} Diamond &amp; Pearl, Platinum, Heart Gold &amp; Soul Silver</a></h2>
<table class="dex-pokemon-flavor-sprites">
<colgroup span="1"></colgroup> <!-- row headers -->
% if c.introduced_in.id <= 8:
<colgroup span="2"></colgroup> <!-- Diamond/Pearl -->
% endif
% if c.introduced_in.id <= 9:
<colgroup span="2"></colgroup> <!-- Platinum -->
% endif
% if c.introduced_in.id <= 10:
<colgroup span="2"></colgroup> <!-- HeartGold/SoulSilver -->
% endif
<thead>
    <tr class="header-row">
        <th></th>
        ## Rotom forms only exist beyond Platinum
        % if c.introduced_in.id <= 8:
        <th colspan="2">${h.pokedex.version_icons(u'Diamond', u'Pearl')}</th>
        % endif
        % if c.introduced_in.id <= 9:
        <th colspan="2">${h.pokedex.version_icons(u'Platinum')}</th>
        % endif
        <th colspan="2">${h.pokedex.version_icons(u'Heart Gold', u'Soul Silver')}</th>
    </tr>
</thead>
<tbody>
    <tr>
        <th class="vertical-text">
            Normal
            % if c.pokemon.has_gen4_fem_sprite:
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
            % if c.pokemon.has_gen4_fem_sprite:
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
</tbody>
% if c.pokemon.has_gen4_fem_sprite:
<tbody>
    <tr>
        <th class="vertical-text">Normal<br/>(female)</th>
        % if c.introduced_in.id <= 8:
        <td>
            ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/female', form=c.form)}
            ${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/female/frame2', form=c.form)}
        </td>
        % if c.pokemon.has_gen4_fem_back_sprite:
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='diamond-pearl/back/female', form=c.form)}</td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
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
        <td class="dex-pokemon-flavor-no-sprite">—</td>
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
        <td class="dex-pokemon-flavor-no-sprite">—</td>
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
        <td class="dex-pokemon-flavor-no-sprite">—</td>
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
        <td class="dex-pokemon-flavor-no-sprite">—</td>
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
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif
    </tr>
</tbody>
% endif
</table>
% endif


## Overworld sprites can't exist for alternate formes that are in-battle only
% if c.appears_in_overworld:
${h.h1('Miscellaneous Game Art', id='misc-sprites')}

% if c.pokemon.generation_id <= 4:
<h2> ${h.pokedex.version_icons(u'Heart Gold', u'Soul Silver')} Heart Gold &amp; Soul Silver Overworld </h2>
<table class="dex-pokemon-flavor-sprites">
% if c.pokemon.has_gen4_fem_sprite:
<colgroup span="1"></colgroup> <!-- row headers -->
% endif
<colgroup span="1"></colgroup> <!-- left -->
<colgroup span="1"></colgroup> <!-- down -->
<colgroup span="1"></colgroup> <!-- up -->
<colgroup span="1"></colgroup> <!-- right -->
<thead>
    <tr class="header-row">
        % if c.pokemon.has_gen4_fem_sprite:
        <th></th>
        % endif
        <th>Left</th>
        <th>Down</th>
        <th>Up</th>
        <th>Right</th>
    </tr>
</thead>
<tbody>
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
</tbody>
% if c.pokemon.has_gen4_fem_sprite:
<tbody>
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
</tbody>
% endif
</table>
% endif

% endif  ## appears_in_overworld



${h.h1('Other Images', id='other')}

<h2>Sugimori Art</h2>
<p> ${h.pokedex.pokedex_img('sugimori/%d.png' % c.pokemon.national_id)} </p>
