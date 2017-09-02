/*** CSS spriting ***/
/* Versions */

/* Generations */

/* Pokémon icons */
<%
    width, height = 40, 30
    per_row = 25
    count = 802
%>
span.sprite-icon { display: inline-block; height: ${height}px; width: ${width}px; background: url(${h.static_uri('pokedex', 'images/css-sprite-pokemon-icons.png')}) no-repeat; vertical-align: middle; }
% for n in range(count):
span.sprite-icon-${n + 1} { background-position: ${-width * (n % per_row)}px ${-height * (n // per_row)}px; }
% endfor
