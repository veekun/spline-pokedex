<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>

<%def name="title()">Move Search</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li><a href="${url(controller='dex', action='moves_list')}">Moves</a></li>
    <li>Move Search</li>
</ul>
</%def>

### RESULTS ###
## Based pretty heavily on the Pokémon search results.  Surprise!
## Four possibilities here: the form wasn't submitted, the form was submitted
## but was bogus, the form was submitted and there are no results, or the form
## was submitted and is good.

% if c.form.was_submitted:
<h1>Results</h1>
<p><a href="${url.current()}"><img src="${h.static_uri('spline', 'icons/eraser.png')}" alt=""> Start over</a></p>

% if not c.form.is_valid:
## Errors
<p>It seems you entered something bogus for:</p>
<ul class="classic-list">
    % for field_name in c.form.errors.keys():
    <li>${c.form[field_name].label.text}</li>
    % endfor
</ul>

% elif c.form.is_valid and not c.results:
## No results
<p>Nothing found.</p>

% elif c.form.is_valid:
## Got something

## Display.  Could be one of several options...
% if c.display_mode == 'custom-table':
## Some sort of table.  (Standard table is also done this way.)
## These defs are all at the bottom of this file
<table class="dex-pokemon-moves striped-rows">
% for column in c.display_columns:
${getattr(self, 'col_' + column)()}
% endfor
<tr class="header-row">
    % for column in c.display_columns:
    ${getattr(self, 'th_' + column)()}
    % endfor
</tr>

% for result in c.results:
    <tr>
        % for column in c.display_columns:
        ${getattr(self, 'td_' + column)(result)}
        % endfor
    </tr>
% endfor
</table>

% elif c.display_mode == 'custom-list-bullets':
## Plain bulleted list with a Template.
<ul class="dex-pokemon-search-list classic-list">
    % for result in c.results:
    <li><a href="${url(controller='dex', action='moves', name=result.name.lower())}">${h.pokedex.apply_move_template(c.display_template, result)}</a></li>
    % endfor
</ul>

% elif c.display_mode == 'custom-list':
## Plain unbulleted list with a Template.  Less semantic HTML, but more
## friendly to clipboards.
<div class="dex-pokemon-search-list">
% for result in c.results:
<a href="${url(controller='dex', action='moves', name=result.name.lower())}">${h.pokedex.apply_move_template(c.display_template, result)}</a><br>
% endfor
</div>

% endif  ## display_mode

% endif  ## search performed
% endif  ## form submitted




### SEARCH FORM ###

<h1>Move Search</h1>
${h.form(url.current(), method='GET')}
<p>Unless otherwise specified: matching moves must match ALL of the criteria, but can match ANY selections within a group.</p>
<p>Anything left blank is ignored entirely.</p>

<div class="dex-column-container">
<div class="dex-column">
    <h2>Essentials</h2>
    <dl class="standard-form">
        ${lib.field('name')}
        <dt>Damage class</dt>
        <dd>
            <ul>
                % for a_field in c.form.damage_class:
                <li> <label>
                    ${a_field() | n}
                    ${h.pokedex.pokedex_img("chrome/damage-classes/{0}.png".format(a_field.data), alt=u'')}
                    ${a_field.label}
                </label> </li>
                % endfor
            </ul>
            % for error in c.form.damage_class.errors:
            <p class="error">${error}</p>
            % endfor
        </dd>
        <dt>Introduced in</dt>
        <dd>
            <ul>
                % for a_field in c.form.introduced_in:
                <li> <label>
                    ${a_field() | n}
                    ${h.pokedex.pokedex_img("versions/generation-{0}.png".format(a_field.data), alt=u'')}
                    ${a_field.label}
                </label> </li>
                % endfor
            </ul>
            % for error in c.form.introduced_in.errors:
            <p class="error">${error}</p>
            % endfor
        </dd>
    </dl>
</div>
<div class="dex-column">
    <h2>Flags</h2>
    <p>Exact same effect as: ${lib.bare_field('similar_to')}</p>
    <ul>
        % for field, _ in c.flag_fields:
        <li>${c.form[field]() | n} ${c.form[field].label() | n}</li>
        % endfor
    </ul>
</div>
<div class="dex-column">
    <h2>Categories</h2>
    <div class="dex-move-search-categories">
        ${lib.bare_field('category_operator')}
        <ul>
            % for field in c.form.category:
            <li>${field() | n} ${field.label() | n}</li>
            % endfor
        </ul>
    </div>
</div>
</div>

<h2>Type</h2>
<ul class="dex-type-list">
    ## always sort ??? last
    % for a_field in sorted(c.form.type, key=lambda field: field.label.text):
    <li> <label>
        ${h.pokedex.type_icon(a_field.label.text)}
        ${a_field() | n}
    </label> </li>
    % endfor
</ul>
% for error in c.form.type.errors:
<p class="error">${error}</p>
% endfor

${c.form.shadow_moves()} ${c.form.shadow_moves.label()}

<h2>Numbers</h2>
<dl class="standard-form">
    ${lib.field('accuracy')}
    ${lib.field('pp')}
    ${lib.field('power')}
    ${lib.field('effect_chance')}
    ${lib.field('priority')}
</dl>

<h2>Pokémon</h2>
<div class="dex-column-container">
<div class="dex-column">
    <h3>Pokémon</h3>
    <p>Moves must be learnable by at least one of these Pokémon:</p>
    <ul>
        % for field in c.form.pokemon:
        <li>
            ${field(class_='js-dex-suggest js-dex-suggest-pokemon') | n}
            % for error in field.errors:
            <p class="error">${error}</p>
            % endfor
        </li>
        % endfor
    </ul>
</div>
<div class="dex-column">
    <h3>Learned by</h3>
    ${lib.bare_field('pokemon_method')}
</div>
<div class="dex-column">
    <h3>Version</h3>
    ${dexlib.pretty_version_group_field(c.form.pokemon_version_group, c.generations)}
</div>
</div>

<h2>Display and sorting</h2>
<div class="dex-column-container">
<div class="dex-column">
    <dl class="standard-form">
        ${lib.field('display', class_='js-dex-search-display')}
        ${lib.field('sort')}
        ${lib.field('sort_backwards')}
    </dl>
</div>
<div class="dex-column-2x dex-search-display-columns">
    <h3>${c.form.column.label() | n}</h3>
    <p class="js-instructions">
        <img src="${h.static_uri('spline', 'icons/arrow-move.png')}" alt="">
        Drag or double-click us!
    </p>
    ${lib.bare_field('column', class_='js-dex-search-column-picker')}
</div>
<div class="dex-column dex-search-display-list">
    <h3>${c.form.format.label() | n}</h3>
    ${lib.bare_field('format')}
</div>
<div class="dex-column dex-search-display-list-reference">
    <h3>Formatting codes</h3>
    <p>e.g.: <code>* $name ($type)</code> becomes <code>&bull; Surf (water)</code></p>
    <dl class="standard-form">
        <dt><code>*</code></dt>
        <dd>&bull;</dd>

        % for pattern in ( \
            '$id', '$name', '$type', '$damage_class', \
            '$pp', '$power', '$accuracy', '$priority', '$effect_chance', \
            '$effect', \
        ):
        <%! from string import Template %>\
        <% template = Template(pattern) %>\
        <dt><code>${pattern}</code></dt>
        <dd>${h.pokedex.apply_move_template(template, c.surf)}</dd>
        % endfor
    </dl>
</div>
</div>

<p>
    ## Always shorten when the form is submitted!
    ${c.form.shorten(value=1) | n}
    <button type="submit">Search</button>
    <button type="reset">Reset form</button>
</p>
${h.end_form()}


### Display columns defs
<%def name="col_id()"><col class="dex-col-id"></%def>
<%def name="th_id()"><th>Num</th></%def>
<%def name="td_id(move)"><td>${move.id}</td></%def>

<%def name="col_name()"><col class="dex-col-name"></%def>
<%def name="th_name()"><th>Name</th></%def>
<%def name="td_name(move)"><td><a href="${url(controller='dex', action='moves', name=move.name.lower())}">${move.name}</a></td></%def>

<%def name="col_type()"><col class="dex-col-type"></%def>
<%def name="th_type()"><th>Type</th></%def>
<%def name="td_type(move)"><td>${h.pokedex.type_link(move.type)}</td></%def>

<%def name="col_class()"><col class="dex-col-type"></%def>
<%def name="th_class()"><th>Class</th></%def>
<%def name="td_class(move)"><td>${h.pokedex.damage_class_icon(move.damage_class)}</td></%def>

<%def name="col_pp()"><col class="dex-col-stat"></%def>
<%def name="th_pp()"><th>PP</th></%def>
<%def name="td_pp(move)"><td>${move.pp}</td></%def>

<%def name="col_power()"><col class="dex-col-stat"></%def>
<%def name="th_power()"><th>Power</th></%def>
<%def name="td_power(move)"><td>${move.power}</td></%def>

<%def name="col_accuracy()"><col class="dex-col-stat"></%def>
<%def name="th_accuracy()"><th>Acc</th></%def>
<%def name="td_accuracy(move)"><td>${move.accuracy}%</td></%def>

<%def name="col_priority()"><col class="dex-col-stat"></%def>
<%def name="th_priority()"><th>Pri</th></%def>
<%def name="td_priority(move)">\
## Priority is colored red for slow and green for fast
% if move.priority == 0:
<td></td>\
% elif move.priority > 0:
<td class="dex-priority-fast">${move.priority}</td>\
% else:
<td class="dex-priority-slow">${move.priority}</td>\
% endif
</%def>

<%def name="col_effect_chance()"><col class="dex-col-stat"></%def>
<%def name="th_effect_chance()"><th>Eff</th></%def>
<%def name="td_effect_chance(move)">\
<td>\
% if move.effect_chance:
${move.effect_chance}% \
% else:
&mdash; \
% endif
</td>\
</%def>

<%def name="col_effect()"><col class="dex-col-effect"></%def>
<%def name="th_effect()"><th>Effect</th></%def>
<%def name="td_effect(move)"><td class="markdown effect">${move.short_effect.as_html | n}</td></%def>

<%def name="col_link()"><col class="dex-col-link"></%def>
<%def name="th_link()"><th></th></%def>
<%def name="td_link(move)"><td><a href="${url(controller='dex', action='moves', name=move.name.lower())}"><img src="${h.static_uri('spline', 'icons/arrow.png')}" alt="-&gt;"></a></td></%def>
