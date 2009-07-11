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

    // Parses a string that looks like a height and returns a number of
    // decimeters.  Returns undefined if the input is bogus.
    // Accepted input can look like 1'3" or 4.6m or related units.
    'si_prefixes': {
        'M': 1000000,
        'k': 1000,
        'h': 100,
        'dk': 10,
        '': 1,
        'd': 1/10,
        'c': 1/100,
        'm': 1/1000,
        'n': 1/1000000,
        'µ': 1/1000000000,
    },
    'parse_height': function(height) {
        // Disallow empty string
        if (height.test(/^\s*$/))
            return undefined;

        // I am so sorry.  My kingdom for /x.
        // This matches 2', 2ft, 3", 3in, combinations of both, and whitespace
        var match = height.match(/^\s*(?:(\d+)\s*(?:'|ft\.?)\s*)?(?:((?:\d*\.)?\d+)(?:"|in\.?)\s*)?$/i);
        if (match) {
            // Note that match[] contains strings by default...
            var inches = match[1] * 12 + parseFloat(match[2] || 0);
            var ret = inches * 2.54 / 10;  // inches -> cm -> dm
            return ret;
        }

        // This matches 2.3 m with almost any SI prefix on the m
        var match = height.match(/^\s*((?:\d*\.)?\d+)\s*(M|k|h|dk||d|c|m|n|µ)m(?:eter)?s?\s*$/i);
        if (match) {
            var value = match[1];
            var coefficient = pokedex.si_prefixes[match[2]];
            return value * coefficient * 10;  // ?m -> m -> dm
        }

        return undefined;
    },

    'parse_weight': function(weight) {
        // Disallow empty string
        if (height.test(/^\s*$/))
            return undefined;

        // This matches 2 lb, 3 oz, or a combination of such
        var match = weight.match(/^\s*(?:((?:\d*\.)?\d+)\s*(?:lb\.?)\s*)?(?:((?:\d*\.)?\d+)(?:oz\.?)\s*)?$/i);
        if (match) {
            // Note that match[] contains strings by default...
            var ounces = match[1] * 16 + parseFloat(match[2] || 0);
            var ret = ounces / 35.2739619 * 10;  // ounces -> kg -> hg
            return ret;
        }

        var match = weight.match(/^\s*((?:\d*\.)?\d+)\s*(M|k|h|dk||d|c|m|n|µ)g(?:gram)?s?\s*$/i);
        if (match) {
            var value = match[1];
            var coefficient = pokedex.si_prefixes[match[2]];
            return value * coefficient / 100;  // ?g -> g -> hg
        }

        return undefined;
    },

    // Same as spline.plugins.pokedex.helpers.scale_sizes().
    // Normalizes a hash of sizes so the largest is 1.
    'scale_sizes': function(sizes, dimensions) {
        if (!dimensions)
            dimensions = 1;

        var max_size = 0;
        for (var key in sizes) {
            if (sizes[key] > max_size)
                max_size = sizes[key];
        }

        var scaled_sizes = {};
        for (var key in sizes) {
            scaled_sizes[key] = Math.pow(sizes[key] / max_size, 1 / dimensions);
        }

        return scaled_sizes;
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
