// Scoping
var pokedex = {
    // Returns n as an integer iff it is valid and min <= n <= max; otherwise,
    // returns undefined.
    'parse_integer': function(n, min, max) {
        var parsed = parseInt(n);
        if (isNaN(parsed) || parsed != n || n < min || n > max)
            return undefined;

        return parsed;
    },

    // Javascript versions of pokedex.formulae.  Unfortunate to duplicate this,
    // but it's pretty simple and the alternatives are ajax or source code
    // translation.
    'formulae': {
        'calculated_stat': function(params) {
            // Need to fake floor division
            return Math.floor(
                (params.base_stat * 2
                    + params.iv
                    + Math.floor(params.effort / 4))
                * params.level / 100) + 5;
        },
        'calculated_hp': function(params) {
            // Shedinja
            if (params.base_stat == 1)
                return 1;

            return Math.floor(
                (params.base_stat * 2
                    + params.iv
                    + Math.floor(params.effort / 4))
                * params.level / 100) + 10 + params.level;
        },

        'earned_exp': function(params) {
            return Math.floor(params.base_exp * params.level / 7);
        },
    },
};



// Easter egg: obdurate
$(function() {
    $('.dex-obdurate').each(function() {
        var $this = $(this);
        var text = $this.text();

        // Wrap words in these so the browser doesn't break in the middle of a
        // "word"
        var nobr_start = '<nobr>';
        var nobr_end = '</nobr><wbr>';

        var newtext = [ nobr_start ];

        for (var i = 0; i < text.length; i++) {
            var ch = text.substr(i, 1);
            newtext.push('<img src="/dex/media/fonts/diamond-pearl-platinum/' + ch + '.png">');

            if (ch == ' ') {
                // Allow break on spaces
                newtext.push(nobr_end);
                newtext.push(nobr_start);
            }
        }

        newtext.push(nobr_end);
        $this.html(newtext.join(''));
    });
});
