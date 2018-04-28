<%inherit file="/base.mako"/>
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>
<%! from splinext.pokedex import i18n %>\

<%def name="title()">${_("Move Search")}</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u"Pokédex")}</a></li>
    <li><a href="${url(controller='dex', action='moves_list')}">${_("Moves")}</a></li>
    <li>${_("Move Search")}</li>
</ul>
</%def>

<%def name="start_over()">
<p><a href="${url.current()}"><img src="${h.static_uri('spline', 'icons/eraser.png')}" alt=""> ${_("Start over")}</a></p>
</%def>

### RESULTS ###
## Based pretty heavily on the Pokémon search results.  Surprise!
## Four possibilities here: the form wasn't submitted, the form was submitted
## but was bogus, the form was submitted and there are no results, or the form
## was submitted and is good.

% if c.form.was_submitted:
% if not c.form.is_valid:
## Errors
<h1>Results</h1>
${start_over()}

<p>${_("It seems you entered something bogus for:")}</p>
<ul class="classic-list">
    % for field_name in c.form.errors.keys():
    <li>${c.form[field_name].label.text}</li>
    % endfor
</ul>

% elif c.form.is_valid and not c.results:
## No results

<h1>0 results</h1>
${start_over()}

<p>${_("Nothing found.")}</p>

% elif c.form.is_valid:
## Got something

<h1>${len(c.results)} results</h1>
${start_over()}

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

<h1>${_("Move Search")}</h1>
${h.form(url.current(), method='GET')}
<p>${_("Unless otherwise specified: matching moves must match ALL of the criteria, but can match ANY selections within a group.")}</p>
<p>${_("Anything left blank is ignored entirely.")}</p>

<div class="dex-column-container">
<div class="dex-column">
    <h2>${_("Essentials")}</h2>
    <dl class="standard-form">
        ${lib.field('name')}
        <dt>${_("Damage class")}</dt>
        <dd>
            <ul>
                % for a_field in c.form.damage_class:
                <li> <label>
                    ${a_field() | n}
                    ${dexlib.pokedex_img("damage-classes/{0}.png".format(a_field.data), alt=u'')}
                    ${a_field.label}
                </label> </li>
                % endfor
            </ul>
            % for error in c.form.damage_class.errors:
            <p class="error">${error}</p>
            % endfor
        </dd>
        <dt>${_("Introduced in")}</dt>
        <dd>
            <ul>
                % for a_field in c.form.introduced_in:
                <li> <label>
                    ${a_field() | n}
                    ${dexlib.chrome_img("versions/generation-{0}.png".format(a_field.data), alt=u'')}
                    ${a_field.label}
                </label> </li>
                % endfor
            </ul>
            % for error in c.form.introduced_in.errors:
            <p class="error">${error}</p>
            % endfor
        </dd>
        <dt>Target</dt>
        <dd>
            <select id="target" name="target">
                % for option in sorted(c.form.target, key=lambda option: option.label.text):
                ${option()}
                % endfor
            </select>
        </dd>
    </dl>
</div>
<div class="dex-column-2x">
    <h2>${_("Flags")}</h2>
    <ul style="-moz-column-count: 2; -moz-column-gap: 1em; -webkit-column-count: 2; -webkit-column-gap: 1em; column-count: 2; column-gap: 1em;">
        % for field, dummy in c.flag_fields:
        <li>${c.form[field]() | n} ${c.form[field].label() | n}</li>
        % endfor
    </ul>
</div>
</div>

<h2>${_("Effect")}</h2>
<ul>
    <li>${_("Exact same effect as:")} ${lib.bare_field('similar_to')}</li>
    <li><label>${c.form.crit_rate() | n} ${c.form.crit_rate.label()}</label></li>
    <li><label>${c.form.multi_hit() | n} ${c.form.multi_hit.label()}</label></li>
    <li><label>${c.form.multi_turn() | n} ${c.form.multi_turn.label()}</label></li>
</ul>
<div class="dex-column-container">
<div class="dex-column-2x">
    <h3>${_("Category")}</h3>
    <div class="dex-move-search-categories">
        <ul>
            % for field in c.form.category:
            <li>${field() | n} ${field.label() | n}</li>
            % endfor
        </ul>
    </div>
</div>
<div class="dex-column">
    <h3>${_("Status ailment")}</h3>
    <div class="dex-move-search-categories">
        <ul>
            % for field in c.form.ailment:
            <li>${field() | n} ${field.label() | n}</li>
            % endfor
        </ul>
    </div>
</div>
</div>


<h2>${_("Type")}</h2>
<ul class="dex-type-list">
    ## always sort ??? last
    % for a_field in sorted(c.form.type, key=lambda field: field.label.text):
    <li> <label>
        ${dexlib.type_icon(a_field.label.text)}
        ${a_field() | n}
    </label> </li>
    % endfor
</ul>
% for error in c.form.type.errors:
<p class="error">${error}</p>
% endfor

${c.form.shadow_moves()} ${c.form.shadow_moves.label()}

<h2>${_("Numbers")}</h2>
<div class="dex-column-container">
<div class="dex-column">
    <dl class="standard-form">
        ${lib.field('accuracy')}
        ${lib.field('pp')}
        ${lib.field('power')}
        ${lib.field('priority')}
    </dl>
</div>
<div class="dex-column">
    <dl class="standard-form">
        ${lib.field('recoil')}
        ${lib.field('healing')}
        ${lib.field('ailment_chance')}
        ${lib.field('flinch_chance')}
        ${lib.field('stat_chance')}
    </dl>
</div>
<div class="dex-column">
    <dl class="standard-form">
    % for subfield in c.form.stat_change:
        <dt>${subfield.stat.name}</dt>
        <dd>${subfield()}</dd>
        % for error in subfield.errors:
        <dd class="error">${error}</dd>
        % endfor
    % endfor
    </dl>
</div>
</div>

<h2>${_(u"Pokémon")}</h2>
<div class="dex-column-container">
<div class="dex-column">
    <h3>${_(u"Pokémon")}</h3>
    <p>${_(u"Moves must be learnable by at least one of these Pokémon:")}</p>
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
    <h3>${_("Learned by")}</h3>
    ${lib.bare_field('pokemon_method')}
</div>
<div class="dex-column">
    <h3>${_("Version")}</h3>
    ${dexlib.pretty_version_group_field(c.form.pokemon_version_group, c.generations)}
</div>
</div>

<h2>${_("Display and sorting")}</h2>
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
        ${_("Drag or double-click us!")}
    </p>
    ${lib.bare_field('column', class_='js-dex-search-column-picker')}
</div>
<div class="dex-column dex-search-display-list">
    <h3>${c.form.format.label() | n}</h3>
    ${lib.bare_field('format')}
</div>
<div class="dex-column dex-search-display-list-reference">
    <h3>${_("Formatting codes")}</h3>
    <p>${_("e.g.: <code>* $name ($type)</code> becomes <code>&bull; Surf (water)</code>") | n}</p>
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
    <button type="submit">${_("Search", context="button")}</button>
    <button type="reset">${_("Reset form")}</button>
</p>
${h.end_form()}


### Display columns defs
<%def name="col_id()"><col class="dex-col-id"></%def>
<%def name="th_id()"><th>${_("Num")}</th></%def>
<%def name="td_id(move)"><td>${move.id}</td></%def>

<%def name="col_name()"><col class="dex-col-name"></%def>
<%def name="th_name()"><th>${_("Name")}</th></%def>
<%def name="td_name(move)"><td><a href="${url(controller='dex', action='moves', name=move.name.lower())}">${move.name}</a></td></%def>

<%def name="col_type()"><col class="dex-col-type"></%def>
<%def name="th_type()"><th>${_("Type")}</th></%def>
<%def name="td_type(move)"><td>${dexlib.type_link(move.type)}</td></%def>

<%def name="col_class()"><col class="dex-col-type"></%def>
<%def name="th_class()"><th>${_("Class")}</th></%def>
<%def name="td_class(move)"><td>${dexlib.damage_class_icon(move.damage_class)}</td></%def>

<%def name="col_pp()"><col class="dex-col-stat"></%def>
<%def name="th_pp()"><th>${_("PP")}</th></%def>
<%def name="td_pp(move)"><td>${move.pp or u'—'}</td></%def>

<%def name="col_power()"><col class="dex-col-stat"></%def>
<%def name="th_power()"><th>${_("Power")}</th></%def>
<%def name="td_power(move)">\
% if move.power is not None:
<td>${move.power}</td>
% elif move.damage_class.identifier == 'status':
<td>—</td>\
% else:
<td>*</td>\
% endif
</%def>

<%def name="col_accuracy()"><col class="dex-col-stat"></%def>
<%def name="th_accuracy()"><th>${_("Acc")}</th></%def>
<%def name="td_accuracy(move)">\
% if move.accuracy:
<td>${move.accuracy}%</td>\
% else:
<td>—</td>\
% endif
</%def>

<%def name="col_priority()"><col class="dex-col-stat"></%def>
<%def name="th_priority()"><th>${_("Pri")}</th></%def>
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
<%def name="th_effect_chance()"><th>${_("Eff")}</th></%def>
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
<%def name="th_effect()"><th>${_("Effect")}</th></%def>
<%def name="td_effect(move)"><td class="markdown effect">${move.short_effect}</td></%def>

<%def name="col_link()"><col class="dex-col-link"></%def>
<%def name="th_link()"><th></th></%def>
<%def name="td_link(move)"><td><a href="${url(controller='dex', action='moves', name=move.name.lower())}"><img src="${h.static_uri('spline', 'icons/arrow.png')}" alt="-&gt;"></a></td></%def>
