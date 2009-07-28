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
<li>
    The ${c.table_labels[result.__class__]}
    <a href="${url(controller='dex', action=result.__tablename__, name=result.name.lower())}">
    % if result.__tablename__ == 'pokemon':
    ${h.pokedex.pokemon_sprite(result, prefix='icons')}
    % elif result.__tablename__ == 'items':
    ${h.pokedex.pokedex_img("items/%s.png" % h.pokedex.filename_from_name(result.name))}
    % elif result.__tablename__ == 'types':
    ${h.pokedex.type_icon(result)}
    % elif result.__tablename__ == 'moves':
    ${h.pokedex.type_icon(result.type)}
    ${h.pokedex.pokedex_img("chrome/damage-classes/%s.png" % result.category)}
    % endif
    ${result.name}
    </a>
</li>
% endfor
</ul>
