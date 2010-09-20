<%inherit file="/base.mako"/>
<%namespace name="lib" file="lib.mako"/>
<%! import re %>\

<%def name="flavor_name()">\
% if c.pokemon.name == 'Unown' and c.form:
Unown ${c.form.capitalize()}\
% elif c.form:
${c.form.title()} ${c.pokemon.name}\
% else:
${c.pokemon.name}\
% endif
</%def>

<%def name="title()">${flavor_name()} flavor - Pokémon #${c.pokemon.national_id}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li><a href="${url(controller='dex', action='pokemon_list')}">Pokémon</a></li>
    <li>${h.pokedex.pokemon_link(c.pokemon)}</li>
    <li>${flavor_name()} flavor</li>
</ul>
</%def>

${lib.pokemon_page_header()}
${h.h1('Essentials')}
<div class="dex-column-container">
<div class="dex-column">
    <h2>Miscellany</h2>
    <dl>
        <dt>Species</dt>
        <dd>
            ${c.pokemon.species}
            <a href="${url(controller='dex_search', action='pokemon_search', species=c.pokemon.species)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>

        <dt>Color</dt>
        <dd style="color: ${c.pokemon.color};">
            ${c.pokemon.color}
            <a href="${url(controller='dex_search', action='pokemon_search', color=c.pokemon.color)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>

        <dt>Cry</dt>
<%
        # Shaymin (and nothing else) has different cries for its different forms
        if c.pokemon.national_id == 492:
            cry_path = 'cries/{0}-{1}.ogg'.format(c.pokemon.national_id, c.form)
        else:
            cry_path = 'cries/{0}.ogg'.format(c.pokemon.national_id)

        cry_path = url(controller='dex', action='media', path=cry_path)
%>\
        <dd>
            <audio src="${cry_path}" controls preload="auto" class="cry">
                <!-- Totally the best fallback -->
                <a href="${cry_path}">Download</a>
            </audio>
        </dd>

        % if c.pokemon.generation.id <= 3:
        <dt>Habitat ${h.pokedex.version_icons(u'FireRed', u'LeafGreen')}</dt>
        <dd>
            ${h.pokedex.pokedex_img('chrome/habitats/%s.png' % h.pokedex.filename_from_name(c.pokemon.habitat))}
            ${c.pokemon.habitat}
            <a href="${url(controller='dex_search', action='pokemon_search', habitat=c.pokemon.habitat)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>
        % endif

        <dt>Pawprint</dt>
        <dd>${h.pokedex.pokemon_sprite(c.pokemon, prefix='pawprints', form=None)}</dd>

        % if c.pokemon.generation.id <= 4:
        <dt>Shape ${h.pokedex.generation_icon(4)}</dt>
        <dd>
            ${h.pokedex.pokedex_img('chrome/shapes/%d.png' % c.pokemon.shape.id, alt='', title=c.pokemon.shape.name)}
            ${c.pokemon.shape.awesome_name}
            <a href="${url(controller='dex_search', action='pokemon_search', shape=c.pokemon.shape.name.lower())}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="Search: " title="Search">
            </a>
        </dd>
        % endif
    </dl>
</div>

<div class="dex-column">
    <h2>Height</h2>
    <div class="dex-size">
        <div class="dex-size-trainer">
            ${h.pokedex.pokedex_img('chrome/trainer-male.png', alt='Trainer dude', style="height: %.2f%%" % (c.heights['trainer'] * 100))}
            <p class="dex-size-value">
                <input type="text" size="6" value="${h.pokedex.format_height_imperial(c.trainer_height)}" disabled="disabled" id="dex-pokemon-height">
            </p>
        </div>
        <div class="dex-size-pokemon">
            ${h.pokedex.pokemon_sprite(c.pokemon, prefix='cropped-pokemon', style="height: %.2f%%;" % (c.heights['pokemon'] * 100), form=c.form)}
            <div class="js-dex-size-raw">${c.pokemon.height}</div>
            <p class="dex-size-value">
                ${h.pokedex.format_height_imperial(c.pokemon_height)} <br/>
                ${h.pokedex.format_height_metric(c.pokemon_height)}
            </p>
        </div>
    </div>
</div>

<div class="dex-column">
    <h2>Weight</h2>
    <div class="dex-size">
        <div class="dex-size-trainer">
            ${h.pokedex.pokedex_img('chrome/trainer-female.png', alt='Trainer dudette', style="height: %.2f%%" % (c.weights['trainer'] * 100))}
            <p class="dex-size-value">
                <input type="text" size="6" value="${h.pokedex.format_weight_imperial(c.trainer_weight)}" disabled="disabled" id="dex-pokemon-weight">
            </p>
        </div>
        <div class="dex-size-pokemon">
            ${h.pokedex.pokemon_sprite(c.pokemon, prefix='cropped-pokemon', style="height: %.2f%%;" % (c.weights['pokemon'] * 100), form=c.form)}
            <div class="js-dex-size-raw">${c.pokemon.weight}</div>
            <p class="dex-size-value">
                ${h.pokedex.format_weight_imperial(c.pokemon_weight)} <br/>
                ${h.pokedex.format_weight_metric(c.pokemon_weight)}
            </p>
        </div>
    </div>
</div>
</div>

${h.h1(u'Pokédex Description', id='pokedex')}
${lib.flavor_text_list(c.pokemon.flavor_text, 'dex-pokemon-flavor-text')}

${h.h1('Main Game Portraits', id='main-sprites')}
% if c.forms:
<h3>Forms</h3>
<ul class="inline">
% for form in c.forms:
    <li>${h.pokedex.pokemon_link(
            c.pokemon,
            h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white', form=form),
            to_flavor=True, form=form,
            class_='dex-icon-link' + (' selected' if form == c.form else ''),
    )}</li>
% endfor
</ul>
<p> ${c.pokemon.normal_form.form_group.description.as_html | n} </p>
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
<h2 id="main-sprites:gen-iii"><a href="#main-sprites:gen-iii" class="subtle">${h.pokedex.generation_icon(3)} Ruby &amp; Sapphire, Emerald, FireRed &amp; LeafGreen</a></h2>
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
        <th colspan="2">${h.pokedex.version_icons(u'FireRed', u'LeafGreen')}</th>
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
<h2 id="main-sprites:gen-iv"><a href="#main-sprites:gen-iv" class="subtle">${h.pokedex.generation_icon(4)} Diamond &amp; Pearl, Platinum, HeartGold &amp; SoulSilver</a></h2>
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
        <th colspan="2">${h.pokedex.version_icons(u'HeartGold', u'SoulSilver')}</th>
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

% if c.pokemon.generation_id <= 5:
<h2 id="main-sprites:gen-v"><a href="#main-sprites:gen-v" class="subtle">${h.pokedex.generation_icon(5)} Black &amp; White</a></h2>
<table class="dex-pokemon-flavor-sprites">
<colgroup span="1"></colgroup> <!-- row headers -->
% if c.introduced_in.id <= 11:
<colgroup span="2"></colgroup> <!-- Black/White -->
% endif
<thead>
    <tr class="header-row">
        <th></th>
        <th colspan="2">${h.pokedex.version_icons(u'Black', u'White')}</th>
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
        % if c.introduced_in.id <= 11:
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white', form=c.form)}</td>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/back', form=c.form)}</td>
        % endif
    </tr>
    <tr>
        <th class="vertical-text">
            Shiny
            % if c.pokemon.has_gen4_fem_sprite:
            <br/> (male)
            % endif
        </th>
        % if c.introduced_in.id <= 11:
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/shiny', form=c.form)}</td>
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/back/shiny', form=c.form)}</td>
        % endif
    </tr>
</tbody>
% if c.pokemon.has_gen4_fem_sprite:
<tbody>
    <tr>
        <th class="vertical-text">Normal <br/> (female)</th>
        % if c.introduced_in.id <= 11:
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/female', form=c.form)}</td>
        % if c.pokemon.has_gen4_fem_back_sprite:
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/back/female', form=c.form)}</td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif
        % endif
    </tr>
    <tr>
        <th class="vertical-text">Shiny <br/> (female)</th>
        % if c.introduced_in.id <= 11:
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/shiny/female', form=c.form)}</td>
        % if c.pokemon.has_gen4_fem_back_sprite:
        <td>${h.pokedex.pokemon_sprite(c.pokemon, prefix='black-white/back/shiny/female', form=c.form)}</td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif
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
<h2> ${h.pokedex.version_icons(u'HeartGold', u'SoulSilver')} HeartGold &amp; SoulSilver Overworld </h2>
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

<h2>Official artwork by Ken Sugimori</h2>
## Shenanigans!  Most forms have official art, but a couple do not.
## To resolve this:
## 1. "Default" forms are just (number).png and are guaranteed to exist.
## 2. Other forms are filenamed as usual.
## So, there is no 479-normal.png or 422-west.png.  Ick.
## Conveniently, though, the forms with official art are all "physical" forms
## -- except Shellos and Gastrodon, which have East art.
<p class="dex-sugimori">
    % if (c.pokemon.forme_name and c.pokemon.forme_name != c.form) or (c.pokemon.id in (422, 423)):
    ${h.pokedex.pokedex_img("sugimori/{0}-{1}.png".format(c.pokemon.national_id, c.form))}
    % else:
    ${h.pokedex.pokedex_img("sugimori/{0}.png".format(c.pokemon.national_id))}
    % endif
</p>
