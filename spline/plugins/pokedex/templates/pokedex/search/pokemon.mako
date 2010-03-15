<%inherit file="/base.mako"/>
<%namespace name="lib" file="/pokedex/lib.mako"/>

<%def name="title()">Pokémon Search</%def>

<%def name="field(name)">
    <dt>${c.form[name].label() | n}</dt>
    <dd>${c.form[name]() | n}</dd>
    % for error in c.form[name].errors:
    <dd class="error">${error}</dd>
    % endfor
</%def>


${h.form(url.current(), method='GET')}
<h1>Pokémon Search</h1>

<h2>Essentials and flavor</h2>
<dl class="standard-form">
    ${field('name')}
    ${field('ability')}
    ${field('color')}
    ${field('habitat')}
    <dt>${c.form.gender_rate.label() | n}</dt>
    <dd>${c.form.gender_rate_operator() | n} ${c.form.gender_rate() | n}</dd>
    <dt>${c.form.egg_group.label() | n}</dt>
    <dd>
        ${c.form.egg_group_operator() | n}
        % for widget in c.form.egg_group:
        ${widget() | n}
        % endfor
    </dd>
</dl>

<h2>Type</h2>
<p>Type must be ${c.form.type_operator() | n}.</p>
% for error in c.form.type_operator.errors:
<p class="error">${error}</p>
% endfor
## Umm.  This class is increasingly misnamed.
<ul class="dex-page-damage">
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

<h2>Evolution</h2>
<div class="dex-column-container">
<div class="dex-column">
    <dl class="standard-form">
        ${field('evolution_stage')}
    </dl>
</div>
<div class="dex-column">
    <dl class="standard-form">
        ${field('evolution_position')}
    </dl>
</div>
<div class="dex-column">
    <dl class="standard-form">
        ${field('evolution_special')}
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

% if c.search_performed:
<h1>Results</h1>
<p><a href="${url.current()}">Clear form</a></p>

## Generic Pokémon table, for now.  Cooler stuff later
<table class="dex-pokemon-moves striped-rows">
${lib.pokemon_table_columns()}
<tr class="header-row">
    ${lib.pokemon_table_header()}
</tr>
% for result in c.results:
<tr>
    ${lib.pokemon_table_row(result)}
</tr>
% endfor
</table>

% endif