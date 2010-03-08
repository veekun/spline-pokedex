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

<ul>
    % for result in c.results:
    <li>${h.pokedex.pokemon_link(result)}</li>
    % endfor
</ul>

% endif
