<%inherit file="/base.mako"/>

<h1>${c.pokemon.name}</h1>

<ul>
    % for type in c.pokemon.types:
    <li>${type.name}</li>
    % endfor
</ul>
