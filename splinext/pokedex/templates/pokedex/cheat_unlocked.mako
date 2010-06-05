<%inherit file="/base.mako"/>
<%!
    import random
    random_title = random.choice([
        'idspispopd',
        'iddqd',
        'cass',
        'uuddlrlrba',
        'hold down+b',
        'talk to oak 250 times',
        'its a secret to everyone',
    ])
%>
<%def name="title()">${random_title}</%def>

<div id="dex-cheat-unlocked">
    <img src="${h.static_uri('pokedex', 'images/cheat-unlocked.gif')}" alt="YEAH" class="dex-cheat-unlocked-left">
    <img src="${h.static_uri('pokedex', 'images/cheat-unlocked.gif')}" alt="YEAH" class="dex-cheat-unlocked-right">
    <div class="dex-cheat-unlocked-line1">Success</div>
    <div class="dex-cheat-unlocked-line2">Cheat Unlocked</div>
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
