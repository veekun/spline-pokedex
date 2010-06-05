<%inherit file="/base.mako"/>
<%namespace name="dexlib" file="lib.mako"/>

<%def name="title()">${c.item_pocket.name} pocket - Items</%def>

<%def name="title_in_page()">
<ul id="breadcrumbs">
    <li><a href="${url('/dex')}">Pokédex</a></li>
    <li><a href="${url(controller='dex', action='items_list')}">Items</a></li>
    <li>${c.item_pocket.name} pocket</li>
</ul>
</%def>

## Menu sort of thing
<ul id="dex-item-pockets">
    % for pocket in c.item_pockets:
    <li>
        <a href="${url(controller='dex', action='item_pockets', pocket=pocket.identifier)}">
            ${h.pokedex.pokedex_img("chrome/bag/{0}{1}.png".format(pocket.identifier, '-selected' if pocket == c.item_pocket else ''))}
        </a>
    </li>
    % endfor
</ul>

<h1>${c.item_pocket.name}</h1>

<table class="striped-rows">
<tr class="header-row">
    % if c.item_pocket.identifier == u'berries':
    <th>Num</th>
    % endif
    <th>Item</th>
</tr>
% for category in c.item_pocket.categories:
% if category.name:
<tr class="subheader-row">
    <th colspan="999">${category.name}</th>
</tr>
% endif
% for item in category.items:
<tr>
    % if c.item_pocket.identifier == u'berries':
    <td>${item.berry.id}</td>
    % endif
    <td>${h.pokedex.item_link(item)}</td>
</tr>
% endfor
% endfor
</table>
