<%inherit file="/base.mako"/>
<%namespace name="conqlib" file="lib.mako"/>

<%! from splinext.pokedex import i18n %>\

<%def name="title()">Moves - Pokémon Conquest</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">${_(u'Pokédex')}</a></li>
    <li><a href="${url('/dex/conquest')}">${_(u'Conquest')}</a></li>
    <li>${_(u'Moves')}</li>
</ul>
</%def>

${h.h1(_(u'Move list'))}
<table class="striped-rows dex-pokemon-moves">
${conqlib.move_table_columns()}

<thead>
    <tr class="header-row">
        ${conqlib.move_table_header()}
    </tr>
</thead>

<tbody>
    % for move in c.moves:
    <tr>
        ${conqlib.move_table_row(move)}
    </tr>
    % endfor
</tbody>
</table>
