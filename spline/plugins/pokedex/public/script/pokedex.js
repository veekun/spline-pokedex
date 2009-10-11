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

// Stuff for collapsing Pokémon-move tables
pokedex.pokemon_moves = {
    'init': function() {
        $('.dex-pokemon-moves').each(function() {
            var $this = $(this);
            // Remember the arrangement of version columns and separators
            // on page load
            var column_classes = [];
            var num_generations = 0;
            var $version_columns = $this.find('col.dex-col-version');
            $version_columns.each(function() {
                column_classes.push(this.className);
                if ($(this).hasClass('dex-col-last-version')) {
                    num_generations++;
                }
            });
            $this.data('pokemon_moves.first_generation',
                       pokedex.generation_ct - num_generations + 1);
            $this.data('pokemon_moves.column_classes', column_classes);

            // Bind action to the available links
            // Add a row with controls
            var $controls = $('<tr></tr>');
            var vg_start = 0;
            var vg_width = 0;
            for (var i = 0; i < $version_columns.length; i++) {
                vg_width++;
                if ($( $version_columns[i] )
                    .hasClass('dex-col-last-version'))
                {
                    var $control = $(
                        '<td class="fake-link" colspan="' + vg_width + '">'
                        + '<img src="/static/spline/icons/funnel.png" alt="Filter" title="Filter">'
                        + '</td>'
                    );

                    $control.data(
                        'pokemon_moves.column_endpoints', {
                            'start': vg_start,
                            'end':   vg_start + vg_width - 1
                        }
                    );
                    $control.click(pokedex.pokemon_moves.filter_columns);
                    $controls.append($control);
                    vg_start += vg_width;
                    vg_width = 0;
                }
            }
            var $first_tr = $( $this.find('tr')[0] );
            $first_tr.before($controls);

            // Initially filter to only the most recent games, i.e., the last
            // column
            $controls.find('td:last-child').click();
        });
    },

    // Reset filtering
    'show_columns': function(e) {
        var $td = $(e.target).closest('td');
        var $this = $td.closest('table.dex-pokemon-moves');
        $this.find('td, th').css('display', null);

        // Restore column definitions
        $this.find('col.dex-col-version').remove();
        var column_classes = $this.data('pokemon_moves.column_classes');
        for (var col = column_classes.length; col >= 1; col--) {
            $this.prepend('<col class="' + column_classes[col - 1] + '">');
        }

        // Change the filter link back
        var $img = $td.find('img');
        $td.unbind('click', pokedex.pokemon_moves.show_columns);
        $td.click(pokedex.pokemon_moves.filter_columns);
        $img.attr({
            'src':   '/static/spline/icons/funnel.png',
            'alt':   'Filter',
            'title': 'Filter'
        });
    },

    // Show only the columns numbered in the passed list
    'filter_columns': function(e) {
        var $td = $(e.target).closest('td');
        var $tr = $(e.target).closest('tr');
        var $this = $tr.closest('table.dex-pokemon-moves');
        // First unhide everything
        $this.find('td, th').css('display', null);

        // Get the indexes of the columns in the selected generation
        var columns_hash = {};
        var start_end = $td.data('pokemon_moves.column_endpoints');
        for (var i = start_end.start; i <= start_end.end; i++) {
            columns_hash[i + 1] = 1;
        }

        // Write out only the <col> tags for the columns we're keeping
        var column_classes = $this.data('pokemon_moves.column_classes');
        var filter_parts = [];
        $this.find('col.dex-col-version').remove();
        for (var col = column_classes.length; col >= 1; col--) {
            if (columns_hash[col]) {
                $this.prepend('<col class="' + column_classes[col - 1] + '">');
                continue;
            }
            filter_parts.push(':nth-child(' + col + ')')
        }

        // Hide the appropriate cells in every row but the header control row
        var $cells = $this.find('tr:not(.subheader-row)')
                          .not($tr)
                          .find('th, td');
        $cells.add( $this.find('col.dex-col-version') );
        $cells.filter( filter_parts.join(',') )
              .css('display', 'none');

        // Similarly filter the control row
        $tr.find('td').not($td).css('display', 'none');

        // Set the lone remaining filter icon to unfilter
        var $img = $td.find('img');
        $td.unbind('click', pokedex.pokemon_moves.filter_columns);
        $td.click(pokedex.pokemon_moves.show_columns);
        $img.attr({
            'src':   '/static/spline/icons/overlay/funnel--minus.png',
            'alt':   'Unfilter',
            'title': 'Unfilter'
        });
    },
};

$(function() { pokedex.pokemon_moves.init() });



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
