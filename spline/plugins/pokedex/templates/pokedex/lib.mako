<%def name="pokemon_page_header()">
<div id="dex-header">
    <a href="${url.current(name=c.prev_pokemon.name.lower(), form=None)}" id="dex-header-prev" class="dex-box-link">
        <img src="${h.static_uri('spline', 'icons/control-180.png')}" alt="«">
        ${h.pokedex.pokemon_sprite(prefix='icons', pokemon=c.prev_pokemon)}
        ${c.prev_pokemon.national_id}: ${c.prev_pokemon.name}
    </a>
    <a href="${url.current(name=c.next_pokemon.name.lower(), form=None)}" id="dex-header-next" class="dex-box-link">
        ${c.next_pokemon.national_id}: ${c.next_pokemon.name}
        ${h.pokedex.pokemon_sprite(prefix='icons', pokemon=c.next_pokemon)}
        <img src="${h.static_uri('spline', 'icons/control.png')}" alt="»">
    </a>
    ${h.pokedex.pokemon_sprite(prefix='icons', pokemon=c.pokemon)}
    <br>${c.pokemon.national_id}: ${c.pokemon.name}
    <ul class="inline-menu">
      % for action, label in (('pokemon', u'Pokédex'), \
                                ('pokemon_flavor', u'Flavor')):
        % if action == request.environ['pylons.routes_dict']['action']:
        <li>${label}</li>
        % else:
        <li><a href="${url.current(action=action)}">${label}</a></li>
        % endif
      % endfor
    </ul>
</div>
</%def>
