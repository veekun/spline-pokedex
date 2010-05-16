<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="lib.mako"/>

<%def name="title()">Items</%def>

<h1>Items</h1>

<p>Pick your pocket:</p>

<ul class="classic-list">
    % for pocket in c.item_pockets:
    <li>
        <a href="${url(controller='dex', action='item_pockets', pocket=pocket.identifier)}">
            ${h.pokedex.pokedex_img(u"chrome/bag/{0}.png".format(pocket.identifier))}
            ${pocket.name}
        </a>
    </li>
    % endfor
</ul>


