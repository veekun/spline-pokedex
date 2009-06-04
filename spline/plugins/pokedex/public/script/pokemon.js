// onload: damage taken table
$(function() {
    // Damage Taken table is more useful if people can see all the types that
    // do 2x damage, etc., at a time.  Let's facilitate that: when a user
    // hovers over a type, fade out all the types that do NOT have the same
    // efficacy, leaving all those with the same efficacy most obvious
    $('#dex-pokemon-damage-taken li').hover(function() {
        $('#dex-pokemon-damage-taken li:not(.' + this.className + ')').addClass('faded');
    }, function() {
        $('#dex-pokemon-damage-taken li').removeClass('faded');
    });
});

// onload: mini exp calculator
$(function() {
    // This just takes a level and sticks in some calculated exp

    var base_exp = $('#dex-pokemon-exp-base').text();

    // Event handler to update the calculated EXP
    var update_exp_handler = function() {
        var $level_textbox = $('#dex-pokemon-exp-level');
        var level = pokedex.parse_integer($level_textbox.val(), 1, 100);

        if (level == undefined) {
            // Not a number from 1 to 100; bail!
            $level_textbox.addClass('error');
            return;
        }
        else {
            $level_textbox.removeClass('error');
        }

        var exp = pokedex.formulae.earned_exp({
            'base_exp': base_exp,
            'level': level,
        });

        $('#dex-pokemon-exp').text(exp);
    };

    // Run the above handler when the level is changed, but also during load
    // (i.e. now) to fix the initial value
    $('#dex-pokemon-exp-level').keyup(update_exp_handler);
    update_exp_handler();
});

// onload: stats table
$(function() {
    var $textboxes = $('input#dex-pokemon-stats-level, input#dex-pokemon-stats-effort');
    var $parent_table = $textboxes.parents('table.dex-pokemon-stats');
    var $stat_rows = $parent_table.find('tr:has(td.dex-pokemon-stats-result)');

    // Since JS is obviously enabled, let the people change the level/EVs
    $textboxes.removeAttr('disabled');

    // Event handler to update the calculated stats
    var update_stats_handler = function() {
        // Error checking; make sure we have integers in both boxes
        var bail = false;       // becomes true if we find an error
        var box_ranges = {      // textboxes and possible values
            'level':  {'min': 1, 'max': 100},
            'effort': {'min': 0, 'max': 255}
        };
        var input = {};         // parsed integer values
        for (var box in box_ranges) {
            var range = box_ranges[box];
            var $textbox = $('#dex-pokemon-stats-' + box);
            var value = pokedex.parse_integer($textbox.val(),
                                              range.min, range.max);
            if (value == undefined) {
                $textbox.addClass('error');
                bail = true;
            }
            else {
                $textbox.removeClass('error');
                input[box] = value;
            }
        }

        if (bail) return;

        // Iterate over each stat row and update accordingly
        $stat_rows.each(function() {
            var $row = $(this);
            var $cells = $row.find('td.dex-pokemon-stats-result');

            // Use HP or general stat formula?
            var stat_name = $row.find('th:first-child').text();
            var formula;
            if (stat_name.match(/HP/))
                formula = pokedex.formulae.calculated_hp;
            else
                formula = pokedex.formulae.calculated_stat;

            // Calculate and update the table
            var base_stat = $row.find('.dex-pokemon-stats-bar').text()
            var min_stat = formula({
                'iv':        0,
                'base_stat': base_stat,
                'level':     input.level,
                'effort':    input.effort
            });
            var max_stat = formula({
                'iv':        31,
                'base_stat': base_stat,
                'level':     input.level,
                'effort':    input.effort
            });
            $( $cells[0] ).text(min_stat);
            $( $cells[1] ).text(max_stat);
        });
    };

    // Update the stats when a key is pressed in a textbox...
    $textboxes.keyup(update_stats_handler);
    // ...but also now during page load, as e.g. firefox might remember old input
    update_stats_handler();
});
