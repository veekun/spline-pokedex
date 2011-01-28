<%inherit file="/base.mako"/>
<%! from splinext.pokedex import i18n %>\
<%!
    _ = unicode
    import random
    random_title = random.choice([
        _('idspispopd'),
        _('iddqd'),
        _('cass'),
        _('uuddlrlrba'),
        _('hold down+b'),
        _('talk to oak 250 times'),
        _('its a secret to everyone'),
    ])
%>
<%def name="title()">${_(random_title)}</%def>

<div id="dex-cheat-unlocked">
    <img src="${h.static_uri('pokedex', 'images/cheat-unlocked.gif')}" alt="${_("YEAH")}" class="dex-cheat-unlocked-left">
    <img src="${h.static_uri('pokedex', 'images/cheat-unlocked.gif')}" alt="${_("YEAH")}" class="dex-cheat-unlocked-right">
    <div class="dex-cheat-unlocked-line1">${_("Success")}</div>
    <div class="dex-cheat-unlocked-line2">${_("Cheat Unlocked")}</div>
</div>

<ul id="dex-cheat-list">
% for code, enabled in session.items():
  % if code[0:6] == 'cheat_':
<%
    classes = []
    if not enabled:
        classes.append('faded')
    if code == c.this_cheat_key:
        classes.append('this-cheat')
%>\
    <li class="${' '.join(classes)}">${code[6:]}</li>
  % endif
% endfor
</ul>
