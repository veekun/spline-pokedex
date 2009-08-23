<%inherit file="/base.mako"/>

<%def name="title()">Disambiguation</%def>

<h1>${c.input}</h1>
% if c.exact:
<p>Hmmm, there are several things with that name.  Did you mean:</p>
% else:
<p>It seems you don't know how to spell.  Did you mean one of these?</p>
% endif

<ul class="classic-list">
% for result in c.results:
<%
    object = result.object
%>\
<li>
    The ${c.table_labels[object.__class__]}
    <a href="${url(controller='dex', action=object.__tablename__, name=object.name.lower())}">
    % if object.__tablename__ == 'pokemon':
    ${h.pokedex.pokemon_sprite(object, prefix='icons')}
    % elif object.__tablename__ == 'items':
    ${h.pokedex.pokedex_img("items/%s.png" % h.pokedex.filename_from_name(object.name))}
    % elif object.__tablename__ == 'types':
    ${h.pokedex.type_icon(object)}
    % elif object.__tablename__ == 'moves':
    ${h.pokedex.type_icon(object.type)}
    ${h.pokedex.pokedex_img("chrome/damage-classes/%s.png" % object.category)}
    % endif
\
    ${object.name}
    </a>
    % if result.language:
    ("${result.name}" in ${result.language})
    % endif
</li>
% endfor
</ul>
