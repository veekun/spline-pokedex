<%inherit file="/base.mako" />
<%namespace name="lib" file="/lib.mako"/>
<%namespace name="dexlib" file="/pokedex/lib.mako"/>

<%def name="title()">Chain breeding</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li>Gadgets</li>
    <li>Chain breeding</li>
</ul>
</%def>

<h1>Chain breeding</h1>

<p>Select a Pokémon and some egg moves it learns, blah blah.</p>

${h.form(url.current(), method=u'GET')}
<dl class="standard-form">
    ${lib.field(u'pokemon')}
    ${lib.field(u'moves')}

    <dd><button type="submit">Figure it out</button></dd>
</dl>
${h.end_form()}


% if c.did_anything:

## Flatten a recursive structure into a list WOO
<% remaining_nodes = [ (0, c.egg_group_tree) ] %>\
% while remaining_nodes:
    <%
    indent, node = remaining_nodes.pop(0)
    for child_node in node['adjacent']:
        # XXX this will put them in REVERSE ORDER per level.  but there's no order atm.
        remaining_nodes.insert(0, (indent + 1, child_node))
    %>
    % if indent > 1:
    ${'&nbsp; &nbsp; &nbsp; ' * (indent - 1)|n}
    % endif
    % if indent:
    <img src="${h.static_uri('spline', 'icons/arrow-turn-090.png')}">
    % endif

    % if node['node'] == 'me':
    ${dexlib.pokemon_icon(c.pokemon)}
    % else:
    % for pokemon in c.pokemon_by_egg_group[node['node']]:
    ${dexlib.pokemon_icon(pokemon)}
    % endfor
    % endif
    <br>
% endwhile
##% for pokemon, methods in c.results.iteritems():
##${pokemon.full_name} | ${[_.name for _ in methods]}<br>
##% endfor

% endif
