<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="lib.mako"/>
<%! import re %>\
<%! from splinext.pokedex import i18n %>\

<%def name="title()">\
${_(u"{name} flavor – Pokémon #{number}").format(name=c.form.name, number=c.form.pokemon.species_id)}\
</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li><a href="${url(controller='dex', action='pokemon_list')}">${_(u"Pokémon")}</a></li>
    <li>${h.pokedex.pokemon_link(c.pokemon, content=c.pokemon.species.name, form=None)}</li>
    <li>${c.form.name} flavor</li>
</ul>
</%def>

${dexlib.pokemon_page_header(icon_form=c.form)}


<%lib:cache_content>
${h.h1(_('Essentials'))}
<div class="dex-column-container">
<div class="dex-column">
    <h2>${_("Miscellany")}</h2>
    <dl>
        <dt>${_("Species")}</dt>
        <dd>
            ${c.pokemon.species.genus}
            <a href="${url(controller='dex_search', action='pokemon_search', genus=c.pokemon.species.genus)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="${_("Search:")} " title="${_("Search")}">
            </a>
        </dd>

        <dt>${_("Color")}</dt>
        <dd>
            <span class="dex-color-${c.pokemon.species.color.identifier}"></span>
            ${c.pokemon.species.color.name}
            <a href="${url(controller='dex_search', action='pokemon_search', color=c.pokemon.species.color.identifier)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="${_("Search: ")}" title="${_("Search")}">
            </a>
        </dd>

        <dt>${_("Cry")}</dt>
        <dd>
            ${dexlib.pokemon_cry(c.form)}
        </dd>

        % if c.pokemon.species.generation_id <= 3:
        <dt>${_("Habitat")}</dt>
        <dd>
            ${h.pokedex.pokedex_img('habitats/%s.png' % h.pokedex.filename_from_name(c.pokemon.species.habitat.identifier))}
            ${c.pokemon.species.habitat.name}
            <a href="${url(controller='dex_search', action='pokemon_search', habitat=c.pokemon.species.habitat.identifier)}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="${_("Search:")} " title="${_("Search")}">
            </a>
        </dd>
        % endif

        <dt>${_("Footprint")}</dt>
        <dd>${h.pokedex.species_image(c.pokemon.species, prefix='footprints', use_form=False)}</dd>

        <dt>${_("Shape")}</dt>
        <dd>
            ${h.pokedex.pokedex_img('shapes/%s.png' % c.pokemon.species.shape.identifier, alt='', title=c.pokemon.species.shape.name)}
            ${c.pokemon.species.shape.awesome_name}
            <a href="${url(controller='dex_search', action='pokemon_search', shape=c.pokemon.species.shape.name.lower())}"
                class="dex-subtle-search-link">
                <img src="${h.static_uri('spline', 'icons/magnifier-small.png')}" alt="${_("Search:")} " title="${_("Search")}">
            </a>
        </dd>
    </dl>
</div>

<div class="dex-column">
    <h2>${_("Height")}</h2>
    <div class="dex-size">
        <div class="dex-size-trainer">
            ${h.pokedex.chrome_img('trainer-male.png', alt='Trainer dude', style="height: %.2f%%" % (c.heights['trainer'] * 100))}
            <p class="dex-size-value">
                <input type="text" size="6" value="${h.pokedex.format_height_imperial(c.trainer_height)}" disabled="disabled" id="dex-pokemon-height">
            </p>
        </div>
        <div class="dex-size-pokemon">
            ${h.pokedex.pokemon_form_image(c.form, prefix='cropped', style="height: %.2f%%;" % (c.heights['pokemon'] * 100), form=c.form.name)}
            <div class="js-dex-size-raw">${c.pokemon.height}</div>
            <p class="dex-size-value">
                ${h.pokedex.format_height_imperial(c.pokemon.height)} <br/>
                ${h.pokedex.format_height_metric(c.pokemon.height)}
            </p>
        </div>
    </div>
</div>

<div class="dex-column">
    <h2>${_("Weight")}</h2>
    <div class="dex-size">
        <div class="dex-size-trainer">
            ${h.pokedex.chrome_img('trainer-female.png', alt='Trainer dudette', style="height: %.2f%%" % (c.weights['trainer'] * 100))}
            <p class="dex-size-value">
                <input type="text" size="6" value="${h.pokedex.format_weight_imperial(c.trainer_weight)}" disabled="disabled" id="dex-pokemon-weight">
            </p>
        </div>
        <div class="dex-size-pokemon">
            ${h.pokedex.pokemon_form_image(c.form, prefix='cropped', style="height: %.2f%%;" % (c.weights['pokemon'] * 100), form=c.form.name)}
            <div class="js-dex-size-raw">${c.pokemon.weight}</div>
            <p class="dex-size-value">
                ${h.pokedex.format_weight_imperial(c.pokemon.weight)} <br/>
                ${h.pokedex.format_weight_metric(c.pokemon.weight)}
            </p>
        </div>
    </div>
</div>
</div>

${h.h1(_(u'Pokédex Description'), id=_('pokedex', context='anchor'))}
${dexlib.flavor_text_list(c.pokemon.species.flavor_text, 'dex-pokemon-flavor-text')}

${h.h1(_('Main Game Portraits'), id=_('main-sprites', context='anchor'))}
% if len(c.pokemon.species.forms) > 1:
<h3>${_("Forms")}</h3>
<ul class="inline">
% for form in c.pokemon.species.forms:
    % if form.form_identifier == 'unknown' and c.pokemon.species.identifier == 'arceus':
        ## No Arceus-??? in B/W
        <% prefix = 'main-sprites/heartgold-soulsilver' %>
    % else:
        <% prefix = 'main-sprites/black-white' %>
    % endif
    <li>${h.pokedex.pokemon_link(
            c.pokemon,
            h.pokedex.pokemon_form_image(form, prefix=prefix),
            to_flavor=True, form=form.form_identifier,
            class_='dex-icon-link' + (' selected' if form == c.form else ''),
    )}</li>
% endfor
</ul>
<p> ${c.pokemon.species.form_description} </p>
% endif

% if c.form.introduced_in_version_group_id <= 2:
<h2 id="main-sprites:gen-i"><a href="#main-sprites:gen-i" class="subtle">${h.pokedex.generation_icon(1)} ${_("Red & Green, Red & Blue, Yellow")}</a></h2>
<table class="dex-pokemon-flavor-sprites">
<colgroup span="1"></colgroup> <!-- row headers -->
<colgroup span="2"></colgroup> <!-- 赤い/緑 -->
<colgroup span="2"></colgroup> <!-- Red/Blue -->
<colgroup span="2"></colgroup> <!-- Yellow -->
<thead>
    <tr class="header-row">
        <th></th>
        <th colspan="2">${h.pokedex.version_icons(u'Red (jp.)', u'Green')}</th>
        <th colspan="2">${h.pokedex.version_icons(u'Red', u'Blue')}</th>
        <th colspan="2">${h.pokedex.version_icons(u'Yellow')}</th>
    </tr>
</thead>
<tbody>
    <tr>
        <th class="vertical-text">${_("GB")}</th>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/red-green/gray')}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/red-green/back/gray')}</td>

        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/red-blue/gray')}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/red-blue/back/gray')}</td>

        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/yellow/gray')}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/yellow/back/gray')}</td>
    </tr>
    <tr>
        <th class="vertical-text">${_("SGB")}</th>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/red-green')}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/red-green/back')}</td>

        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/red-blue')}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/red-blue/back')}</td>

        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/yellow')}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/yellow/back')}</td>
    </tr>
    <tr>
        <th class="vertical-text">${_("GBC")}</th>
        <td colspan="2" class="dex-pokemon-flavor-no-sprite">—</td>

        <td colspan="2" class="dex-pokemon-flavor-no-sprite">—</td>

        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/yellow/gbc')}</td>
        <td class="dex-pokemon-flavor-rby-back">${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/yellow/back/gbc')}</td>
    </tr>
</tbody>
</table>
% endif

% if c.form.introduced_in_version_group_id <= 4:
<h2 id="main-sprites:gen-ii"><a href="#main-sprites:gen-ii" class="subtle">${h.pokedex.generation_icon(2)} ${_("Gold & Silver, Crystal")}</a></h2>
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
        <th class="vertical-text">${_("Normal")}</th>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/gold')}</td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/gold/back')}</td>

        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/silver')}</td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/silver/back')}</td>

        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/crystal')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/crystal/animated')}
        </td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/crystal/back')}</td>
    </tr>
    <tr>
        <th class="vertical-text">${_("Shiny")}</th>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/gold/shiny')}</td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/gold/back/shiny')}</td>

        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/silver/shiny')}</td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/silver/back/shiny')}</td>

        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/crystal/shiny')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/crystal/animated/shiny')}
        </td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/crystal/back/shiny')}</td>
    </tr>
</tbody>
</table>
% endif

% if c.form.introduced_in_version_group_id <= 7:
<% show_rusa = c.form.introduced_in_version_group_id <= 5 %>\
<% show_emerald = c.form.introduced_in_version_group_id <= 6 %>\
<% show_frlg = (c.pokemon.species.generation_id == 1
                or c.pokemon.name == u'Teddiursa'
                or c.form.introduced_in_version_group_id == 7) %>\
<h2 id="main-sprites:gen-iii"><a href="#main-sprites:gen-iii" class="subtle">${h.pokedex.generation_icon(3)} ${_("Ruby & Sapphire, Emerald, FireRed & LeafGreen")}</a></h2>
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
        <th class="vertical-text">${_("Normal")}</th>
    % if show_rusa:
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/ruby-sapphire')}</td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/ruby-sapphire/back')}</td>
    % endif

    % if show_emerald:
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/emerald')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/emerald/frame2')}
            ## Emerald animations don't exist for forms that only exist after a battle starts
            % if c.sprite_exists('main-sprites/emerald/animated'):
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/emerald/animated')}
            % endif
        </td>
    % endif

    % if show_frlg:
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/firered-leafgreen')}</td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/firered-leafgreen/back')}</td>
    % endif
    </tr>
    <tr>
        <th class="vertical-text">${_("Shiny")}</th>
    % if show_rusa:
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/ruby-sapphire/shiny')}</td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/ruby-sapphire/back/shiny')}</td>
    % endif

    % if show_emerald:
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/emerald/shiny')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/emerald/shiny/frame2')}
            % if c.sprite_exists('main-sprites/emerald/animated'):
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/emerald/animated/shiny')}
            % endif
        </td>
    % endif

    % if show_frlg:
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/firered-leafgreen/shiny')}</td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/firered-leafgreen/back/shiny')}</td>
    % endif
    </tr>
</tbody>
</table>
% endif

% if c.pokemon.species.generation_id <= 4:
<h2 id="main-sprites:gen-iv"><a href="#main-sprites:gen-iv" class="subtle">${h.pokedex.generation_icon(4)} ${_("Diamond & Pearl, Platinum, HeartGold & SoulSilver")}</a></h2>
<table class="dex-pokemon-flavor-sprites">
<colgroup span="1"></colgroup> <!-- row headers -->
% if c.form.introduced_in_version_group_id <= 8:
<colgroup span="2"></colgroup> <!-- Diamond/Pearl -->
% endif
% if c.form.introduced_in_version_group_id <= 9:
<colgroup span="2"></colgroup> <!-- Platinum -->
% endif
% if c.form.introduced_in_version_group_id <= 10:
<colgroup span="2"></colgroup> <!-- HeartGold/SoulSilver -->
% endif
<thead>
    <tr class="header-row">
        <th></th>
        ## Rotom forms only exist beyond Platinum
        % if c.form.introduced_in_version_group_id <= 8:
        <th colspan="2">${h.pokedex.version_icons(u'Diamond', u'Pearl')}</th>
        % endif
        % if c.form.introduced_in_version_group_id <= 9:
        <th colspan="2">${h.pokedex.version_icons(u'Platinum')}</th>
        % endif
        <th colspan="2">${h.pokedex.version_icons(u'HeartGold', u'SoulSilver')}</th>
    </tr>
</thead>
<tbody>
    <tr>
        <th class="vertical-text">
            ${_("Normal")}
            % if c.pokemon.species.has_gender_differences:
            <br/> ${_("(male)")}
            % endif
        </th>
        % if c.form.introduced_in_version_group_id <= 8:
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/diamond-pearl')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/diamond-pearl/frame2')}
        </td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/diamond-pearl/back')}</td>
        % endif

        % if c.form.introduced_in_version_group_id <= 9:
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/frame2')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/back')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/back/frame2')}
        </td>
        % endif

        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/frame2')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/back')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/back/frame2')}
        </td>
    </tr>
    <tr>
        <th class="vertical-text">
            ${_("Shiny")}
            % if c.pokemon.species.has_gender_differences:
            <br/> ${_("(male)")}
            % endif
        </th>
        % if c.form.introduced_in_version_group_id <= 8:
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/diamond-pearl/shiny')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/diamond-pearl/shiny/frame2')}
        </td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/diamond-pearl/back/shiny')}</td>
        % endif

        % if c.form.introduced_in_version_group_id <= 9:
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/shiny')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/shiny/frame2')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/back/shiny')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/back/shiny/frame2')}
        </td>
        % endif

        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/shiny')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/shiny/frame2')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/back/shiny')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/back/shiny/frame2')}
        </td>
    </tr>
</tbody>
## Chimecho's female back frame 2 sprite has one hand in a slightly different pose
% if c.pokemon.species.has_gender_differences or c.pokemon.id == 358:
<tbody>
    <tr>
        <th class="vertical-text">${_("Normal")}<br/>${_("(female)")}</th>
        % if c.form.introduced_in_version_group_id <= 8:
        % if c.sprite_exists('main-sprites/diamond-pearl/female'):
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/diamond-pearl/female')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/diamond-pearl/female/frame2')}
        </td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif

        % if c.sprite_exists('main-sprites/diamond-pearl/back/female'):
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/diamond-pearl/back/female')}</td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif
        % endif

        % if c.form.introduced_in_version_group_id <= 9:
        % if c.sprite_exists('main-sprites/platinum/female'):
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/female')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/female/frame2')}
        </td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif

        % if c.sprite_exists('main-sprites/platinum/back/female'):
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/back/female')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/back/female/frame2')}
        </td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif
        % endif

        % if c.sprite_exists('main-sprites/heartgold-soulsilver/female'):
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/female')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/female/frame2')}
        </td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif

        % if c.sprite_exists('main-sprites/heartgold-soulsilver/back/female'):
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/back/female')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/back/female/frame2')}
        </td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif
    </tr>
    <tr>
        <th class="vertical-text">${_("Shiny")}<br/>${_("(female)")}</th>
        % if c.form.introduced_in_version_group_id <= 8:
        % if c.sprite_exists('main-sprites/diamond-pearl/female'):
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/diamond-pearl/shiny/female')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/diamond-pearl/shiny/female/frame2')}
        </td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif

        % if c.sprite_exists('main-sprites/diamond-pearl/back/female'):
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/diamond-pearl/back/shiny/female')}</td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif
        % endif

        % if c.form.introduced_in_version_group_id <= 9:
        % if c.sprite_exists('main-sprites/platinum/female'):
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/shiny/female')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/shiny/female/frame2')}
        </td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif

        % if c.sprite_exists('main-sprites/platinum/back/female'):
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/back/shiny/female')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/platinum/back/shiny/female/frame2')}
        </td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif
        % endif

        % if c.sprite_exists('main-sprites/heartgold-soulsilver/female'):
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/shiny/female')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/shiny/female/frame2')}
        </td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif

        % if c.sprite_exists('main-sprites/heartgold-soulsilver/back/female'):
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/back/shiny/female')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/heartgold-soulsilver/back/shiny/female/frame2')}
        </td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif
    </tr>
</tbody>
% endif
</table>
% endif

% if c.pokemon.species.generation_id <= 5:
<h2 id="main-sprites:gen-v"><a href="#main-sprites:gen-v" class="subtle">${h.pokedex.generation_icon(5)} ${_("Black & White")}</a></h2>
<table class="dex-pokemon-flavor-sprites">
<colgroup span="1"></colgroup> <!-- row headers -->
% if c.form.introduced_in_version_group_id <= 11:
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
            ${_("Normal")}
            % if c.pokemon.species.has_gender_differences:
            <br/> ${_("(male)")}
            % endif
        </th>
        % if c.form.introduced_in_version_group_id <= 11:
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/black-white')}</td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/black-white/back')}</td>
        % endif
    </tr>
    <tr>
        <th class="vertical-text">
            ${_("Shiny")}
            % if c.pokemon.species.has_gender_differences:
            <br/> ${_("(male)")}
            % endif
        </th>
        % if c.form.introduced_in_version_group_id <= 11:
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/black-white/shiny')}</td>
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/black-white/back/shiny')}</td>
        % endif
    </tr>
</tbody>
% if c.pokemon.species.has_gender_differences:
<tbody>
    <tr>
        <th class="vertical-text">${_("Normal")} <br/> ${_("(female)")}</th>
        % if c.form.introduced_in_version_group_id <= 11:
        % if c.sprite_exists('main-sprites/black-white/female'):
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/black-white/female')}</td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif

        % if c.sprite_exists('main-sprites/black-white/back/female'):
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/black-white/back/female')}</td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif
        % endif
    </tr>
    <tr>
        <th class="vertical-text">${_("Shiny")} <br/> ${_("(female)")}</th>
        % if c.form.introduced_in_version_group_id <= 11:
        % if c.sprite_exists('main-sprites/black-white/female'):
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/black-white/shiny/female')}</td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif

        % if c.sprite_exists('main-sprites/black-white/back/female'):
        <td>${h.pokedex.pokemon_form_image(c.form, prefix='main-sprites/black-white/back/shiny/female')}</td>
        % else:
        <td class="dex-pokemon-flavor-no-sprite">—</td>
        % endif
        % endif
    </tr>
</tbody>
% endif
</table>
% endif


% if c.sprite_exists('overworld'):
<% overworld_gender_differences = c.pokemon.species.has_gender_differences and c.sprite_exists('overworld/female') %>
${h.h1(_('Miscellaneous Game Art'), id=_('misc-sprites', context='anchor'))}
<h2> ${h.pokedex.version_icons(u'HeartGold', u'SoulSilver')} ${_("HeartGold & SoulSilver Overworld")} </h2>
<table class="dex-pokemon-flavor-sprites">
% if overworld_gender_differences:
<colgroup span="1"></colgroup> <!-- row headers -->
% endif
<colgroup span="1"></colgroup> <!-- left -->
<colgroup span="1"></colgroup> <!-- down -->
<colgroup span="1"></colgroup> <!-- up -->
<colgroup span="1"></colgroup> <!-- right -->
<thead>
    <tr class="header-row">
        % if overworld_gender_differences:
        <th></th>
        % endif
        <th>${_("Left", context='overworld sprite')}</th>
        <th>${_("Down", context='overworld sprite')}</th>
        <th>${_("Up", context='overworld sprite')}</th>
        <th>${_("Right", context='overworld sprite')}</th>
    </tr>
</thead>
<tbody>
    <tr>
        % if overworld_gender_differences:
        <th class="vertical-text" rowspan="2">Male</th>
        % endif
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/left')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/left/frame2')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/down/frame2')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/down')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/up')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/up/frame2')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/right')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/right/frame2')}
        </td>
    </tr>
    <tr>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/left')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/left/frame2')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/down/frame2')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/down')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/up')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/up/frame2')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/right')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/right/frame2')}
        </td>
    </tr>
</tbody>
% if overworld_gender_differences:
<tbody>
    <tr>
        <th class="vertical-text" rowspan="2">${_("Female")}</th>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/female/left')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/female/left/frame2')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/female/down/frame2')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/female/down')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/female/up')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/female/up/frame2')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/female/right')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/female/right/frame2')}
        </td>
    </tr>
    <tr>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/female/left')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/female/left/frame2')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/female/down/frame2')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/female/down')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/female/up')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/female/up/frame2')}
        </td>
        <td>
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/female/right')}
            ${h.pokedex.pokemon_form_image(c.form, prefix='overworld/shiny/female/right/frame2')}
        </td>
    </tr>
</tbody>
% endif
</table>
% endif  ## appears_in_overworld


<%
sugimori_art = None

if h.pokedex.pokemon_has_media(c.form, 'sugimori', 'png'):
    # We only have separate art per form for some Pokémon
    sugimori_art = h.pokedex.pokemon_form_image(c.form, 'sugimori')
elif (c.form.is_default and
      h.pokedex.pokemon_has_media(c.form, 'sugimori', 'png', use_form=False)):
    # We don't want to show default-form art if we're not the default form, and
    # we also just plain don't have art of a few Pokémon
    sugimori_art = h.pokedex.pokemon_form_image(c.form, 'sugimori', use_form=False)
%>\
% if sugimori_art:
${h.h1(_('Other Images'), id=_('other', context='anchor'))}
<h2>${_("Official artwork by Ken Sugimori")}</h2>
<p class="dex-sugimori">
    ${sugimori_art}
</p>
% endif
</%lib:cache_content>
