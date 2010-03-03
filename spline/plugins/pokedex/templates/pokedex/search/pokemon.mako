<%inherit file="/base.mako"/>
<%namespace name="lib" file="/pokedex/lib.mako"/>

<%def name="title()">Pokémon Search</%def>


${h.form(url.current(), method='GET')}
<h1>Pokémon Search</h1>

<dl class="standard-form">
    <dt>${c.form.name.label() | n}</dt>
    <dd>${c.form.name() | n}</dd>
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
