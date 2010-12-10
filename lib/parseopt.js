/**
 * JavaScript Option Parser (parseopt)
 * Copyright (C) 2010  Mathias Panzenböck <grosser.meister.morti@gmx.net>
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA 
 */

/**
 * Construct a new OptionParser.
 * See the demo folder the end of this file for example usage.
 *
 * @param object params   optional Parameter-Object
 *
 * ===== Parameter-Object =====
 *   {
 *      minargs: integer, optional
 *      maxargs: integer, optional
 *      program: string, per default inferred from process.argv
 *      strings: object, optional
 *               Table of strings used in the output. See below.
 *      options: array, optional
 *               Array of option definitions. See below.
 *   }
 *
 * ===== String-Table =====
 *   {
 *      help:      string, default: 'No help available for this option.'
 *      usage:     string, default: 'Usage'
 *      options:   string, default: 'OPTIONS'
 *      arguments: string, default: 'ARGUMENTS'
 *      required:  string, default: 'required'
 *      default:   string, default: 'default'
 *      base:      string, default: 'base'
 *      metavars:  object, optional
 *                 Table of default metavar names per type.
 *                 Per default the type name in capital letters or derived
 *                 from the possible values.
 *   }
 *
 * ===== Option Definition =====
 *   {
 *      // Only when passed to the OptionParser constructor:
 *      name:        string or array
 *      names:       string or array, alias of name
 *                   Only one of both may be used at the same time.
 *
 *                   Names can be long options (e.g. '--foo') and short options
 *                   (e.g. '-f'). The first name is used to indentify the option.
 *                   Names musst be unique and may not contain '='.
 *
 *                   Short options may be combined when passed to a programm. E.g.
 *                   the options '-f' and '-b' can be combined to '-fb'. Only one
 *                   of these combined options may require an argument.
 *
 *                   Short options are separated from ther arguments by space,
 *                   long options per '='. If a long option requires an argument
 *                   and none is passed using '=' it also uses the next commandline
 *                   argument as it's argument (like short options).
 *
 *                   If '--' is encountered all remaining arguments are treated as
 *                   arguments and not as options.
 *
 *      // General fields:
 *      target:      string, per deflault inferred from first name
 *                   This defines the name used in the returned options object.
 *                   Multiple options may have the same target.
 *      default:     any, default: undefined
 *                   The default value associated with a certain target and is
 *                   overwritten by each new option with the same target.
 *      type:        string, default: 'string', see below
 *      required:    boolean, default: false
 *      redefinable: boolean, default: true
 *      help:        string, optional
 *      details:     array, optional
 *                   short list of details shown in braces after the option name
 *                   e.g. integer type options add 'base: '+base if base !== undefined
 *      metavar:     string or array, per deflault inferred from type
 *      onOption:    function (value) -> boolean, optional
 *                   Returning true canceles any further option parsing
 *                   and the parse() method returns null.
 *
 *      // Type: string  (alias: str)
 *      // Type: boolean (alias: bool)
 *      // Type: object  (alias: obj)
 *
 *      // Type: integer (alias: int)
 *      min:         integer, optional
 *      max:         integer, optional
 *      NaN:         boolean, default: false
 *      base:        integer, optional
 *
 *      // Type: float   (alias: number)
 *      min:         float, optional
 *      max:         float, optional
 *      NaN:         boolean, default: false
 *
 *      // Type: flag
 *      value:       boolean, default: true
 *      default:     boolean, default: false
 *
 *      // Type: option
 *      value:       any, per default inferred from first name
 *
 *      // Type: enum
 *      ignoreCase:  boolean, default: true
 *      values:      array or object where the user enteres the field name of
 *                   the object and you get the value of the field
 *
 *      // Type: record
 *      create:      function () -> object, default: Array
 *      args:        array of type definitions (type part of option definitions)
 *
 *      // Type: custom
 *      argc:        integer, default: -1
 *                   Number of required arguments.
 *                   -1 means one optional argument.
 *      parse:       function (string, ...) -> value
 *      stringify:   function (value) -> string, optional
 *   }
 *
 * ===== Option-Arguments =====
 * For the following types exactly one argument is required:
 *   integer, float, string, boolean, object, enum
 *
 * The following types have optional arguments:
 *   flag
 *
 * The following types have no arguments:
 *   option
 *
 * Custom types may set this through the argc field.
 */
function OptionParser (params) {
	this.optionsPerName = {};
	this.defaultValues  = {};
	this.options        = [];

	if (params !== undefined) {
		this.minargs = params.minargs == 0 ? undefined : params.minargs;
		this.maxargs = params.maxargs;
		this.program = params.program;
		this.strings = params.strings;

		if (this.minargs > this.maxargs) {
			throw new Error('minargs > maxargs');
		}
	}

	if (this.strings === undefined) {
		this.strings = {};
	}

	defaults(this.strings, {
		help:      'No help available for this option.',
		usage:     'Usage',
		options:   'OPTIONS',
		arguments: 'ARGUMENTS',
		required:  'required',
		default:   'default',
		base:      'base',
		metavars:  {}
	});

	defaults(this.strings.metavars, METAVARS);

	if (this.program === undefined) {
		this.program = process.argv[0] + ' ' + process.argv[1];
	}

	if (params !== undefined && params.options !== undefined) {
		for (var i in params.options) {
			var opt = params.options[i];
			var names;

			if (opt instanceof Array || typeof(opt) == 'string') {
				opt = undefined;
				names = opt;
			}
			else {
				names = opt.names;
				if (names === undefined) {
					names = opt.name;
					delete opt.name;
				}
				else {
					delete opt.names;
				}
			}
			this.add(names, opt);
		}
	}
}

OptionParser.prototype = {
	/**
	 * Parse command line options.
	 * 
	 * @param array args  Commandline arguments.
	 *                    If undefined process.argv.slice(2) is used.
	 *
	 * @return object
	 *   {
	 *      arguments: array
	 *      options:   object, { target -> value }
	 *   }
	 */
	parse: function (args) {
		if (args === undefined) {
			args = process.argv.slice(2);
		}

		var data = {
			options:   {},
			arguments: []
		};

		for (var name in this.defaultValues) {
			var value = this.defaultValues[name];

			if (value !== undefined) {
				data.options[this.optionsPerName[name].target] = value;
			}
		}

		var got = {};
		var i = 0;
		for (; i < args.length; ++ i) {
			var arg = args[i];

			if (arg == '--') {
				++ i;
				break;
			}
			else if (/^--.+$/.test(arg)) {
				var j = arg.indexOf('=');
				var name, value = undefined;

				if (j == -1) {
					name  = arg;
				}
				else {
					name  = arg.substring(0,j);
					value = arg.substring(j+1);
				}

				var optdef = this.optionsPerName[name];
				
				if (optdef === undefined) {
					throw new Error('unknown option: '+name);
				}

				if (value === undefined) {
					if (optdef.argc < 1) {
						value = optdef.value;
					}
					else if ((i + optdef.argc) >= args.length) {
						throw new Error('option '+name+' needs '+optdef.argc+' arguments');
					}
					else {
						value = optdef.parse.apply(optdef, args.slice(i+1, i+1+optdef.argc));
						i += optdef.argc;
					}
				}
				else if (optdef.argc == 0) {
					throw new Error('option '+name+' does not need an argument');
				}
				else if (optdef.argc > 1) {
					throw new Error('option '+name+' needs '+optdef.argc+' arguments');
				}
				else {
					value = optdef.parse(value);
				}

				if (!optdef.redefinable && optdef.target in got) {
					throw new Error('cannot redefine option '+name);
				}

				got[optdef.target] = true;
				data.options[optdef.target] = value;

				if (optdef.onOption && optdef.onOption(value) === true) {
					return null;
				}
			}
			else if (/^-.+$/.test(arg)) {
				if (arg.indexOf('=') != -1) {
					throw new Error('illegal option syntax: '+arg);
				}

				var tookarg = false;
				arg = arg.substring(1);

				for (var j = 0; j < arg.length; ++ j) {
					var name = '-'+arg[j];
					var optdef = this.optionsPerName[name];
					var value;
					
					if (optdef === undefined) {
						throw new Error('unknown option: '+name);
					}

					if (optdef.argc < 1) {
						value = optdef.value;
					}
					else {
						if (tookarg || (i+optdef.argc) >= args.length) {
							throw new Error('option '+name+' needs '+optdef.argc+' arguments');
						}

						value = optdef.parse.apply(optdef, args.slice(i+1, i+1+optdef.argc));
						i += optdef.argc;
						tookarg = true;
					}

					if (!optdef.redefinable && optdef.target in got) {
						throw new Error('redefined option: '+name);
					}

					got[optdef.target] = true;
					data.options[optdef.target] = value;

					if (optdef.onOption && optdef.onOption(value) === true) {
						return null;
					}
				}
			}
			else {
				data.arguments.push(arg);
			}
		}

		for (; i < args.length; ++ i) {
			data.arguments.push(args[i]);
		}

		var argc = data.arguments.length;
		if ((this.maxargs !== undefined && argc > this.maxargs) ||
				(this.minargs !== undefined && argc < this.minargs)) {
			var msg = 'illegal number of arguments: ' + argc;

			if (this.minargs !== undefined) {
				msg += ', minumum is ' + this.minargs;
				if (this.maxargs !== undefined) {
					msg += ' and maximum is ' + this.maxargs;
				}
			}
			else {
				msg += ', maximum is ' + this.maxargs;
			}

			throw new Error(msg);
		}

		for (var i in this.options) {
			var optdef = this.options[i];
			if (optdef.required && !(optdef.target in got)) {
				throw new Error('missing required option: ' + optdef.names[0]);
			}
		}
		
		return data;
	},
	/**
	 * Add an option definition.
	 *
	 * @param string or array names  Option names
	 * @param object optdef          Option definition
	 */
	add: function (names, optdef) {
		if (typeof(names) == 'string') {
			names = [names];
		}
		else if (names === undefined || names.length == 0) {
			throw new Error('no option name given');
		}

		if (optdef === undefined) {
			optdef = {};
		}

		optdef.names = names;
		
		for (var i in names) {
			var name = names[i];
			var match = /(-*)(.*)/.exec(name);

			if (name.length == 0 || match[1].length < 1 ||
					match[1].length > 2 || match[2].length == 0 ||
					(match[1].length == 1 && match[2].length > 1) ||
					match[2].indexOf('=') != -1) {
				throw new Error('illegal option name: ' + name);
			}

			if (name in this.optionsPerName) {
				throw new Error('option already exists: '+name);
			}
		}

		if (optdef.target === undefined) {
			var target = names[0].replace(/^--?/,'');
			
			if (target.toUpperCase() == target) {
				// FOO-BAR -> FOO_BAR
				target = target.replace(/[^a-zA-Z0-9]+/,'_');
			}
			else {
				// foo-bar -> fooBar
				target = target.split(/[^a-zA-Z0-9]+/);
				for (var i = 1; i < target.length; ++ i) {
					var part = target[i];
	
					if (part) {
						target[i] = part[0].toUpperCase() + part.substring(1);
					}
				}
				target = target.join('');
			}

			optdef.target = target;
		}

		this._initType(optdef, optdef.names[0]);

		if (optdef.redefinable === undefined) {
			optdef.redefinable = true;
		}

		if (optdef.required === undefined) {
			optdef.required = false;
		}

		if (optdef.help === undefined) {
			optdef.help = this.strings.help;
		}
		else {
			optdef.help = optdef.help.trim();
		}
		
		for (var i in names) {
			this.optionsPerName[names[i]] = optdef;
		}
		
		if (optdef.default !== undefined) {
			this.defaultValues[names[0]] = optdef.default;
		}

		this.options.push(optdef);
	},
	/**
	 * Show an error message, usage and exit program with exit code 1.
	 * 
	 * @param string msg       The error message
	 * @param WriteStream out  Where to write the message.
	 *                         If undefined process.stdout is used.
	 */
	error: function (msg, out) {
		if (!out) {
			out = process.stdout;
		}
		out.write('*** '+msg+'\n\n');
		this.usage(undefined, out);
		process.exit(1);
	},
	/**
	 * Print usage message.
	 *
	 * @param string help      Optional additional help message.
	 * @param WriteStream out  Where to write the message.
	 *                         If undefined process.stdout is used.
	 */
	usage: function (help, out) {
		if (!out) {
			out = process.stdout;
		}

		out.write(this.strings.usage+': '+this.program+' ['+
			this.strings.options+']'+(this.maxargs != 0 ?
				' ['+this.strings.arguments+']\n' : '\n'));
		out.write('\n');
		out.write(this.strings.options+':\n');

		for (var i in this.options) {
			var optdef = this.options[i];
			var optnames = [];
			var metavar = optdef.metavar;

			if (metavar instanceof Array) {
				metavar = metavar.join(' ');
			}

			for (var j in optdef.names) {
				var optname = optdef.names[j];

				if (metavar !== undefined) {
					if (optdef.argc < 2 && optname.substring(0,2) == '--') {
						if (optdef.argc < 0) {
							optname = optname+'[='+metavar+']';
						}
						else {
							optname = optname+'='+metavar;
						}
					}
					else {
						optname = optname+' '+metavar;
					}
				}
				optnames.push(optname);
			}

			var details = optdef.details !== undefined ? optdef.details.slice() : [];
			if (optdef.required) {
				details.push(this.strings.required);
			}
			else if (optdef.argc > 0 && optdef.default !== undefined) {
				details.push(this.strings.default+': '+optdef.stringify(optdef.default));
			}

			if (details.length > 0) {
				details = '  (' + details.join(', ') + ')';
			}

			if (metavar !== undefined) {
				optnames[0] += details;
				out.write('  '+optnames.join('\n  '));
			}
			else {
				out.write('  '+optnames.join(', ')+details);
			}
			if (optdef.help) {
				var lines = optdef.help.split('\n');
				for (var j in lines) {
					out.write('\n        '+lines[j]);
				}
			}
			out.write('\n\n');
		}

		if (help !== undefined) {
			out.write(help);
			if (help[help.length-1] != '\n') {
				out.write('\n');
			}
		}
	},
	_initType: function (optdef, name) {
		optdef.name = name;
	
		if (optdef.type === undefined) {
			optdef.type = 'string';
		}
		else if (optdef.type in TYPE_ALIAS) {
			optdef.type = TYPE_ALIAS[optdef.type];
		}
		
		switch (optdef.type) {
			case 'flag':
				if (optdef.value === undefined) {
					optdef.value = true;
				}
				optdef.parse = parseBool;
				optdef.argc  = -1;
	
				if (optdef.default === undefined) {
					optdef.default = this.defaultValues[name];

					if (optdef.default === undefined) {
						optdef.default = false;
					}
				}
				break;
	
			case 'option':
				optdef.argc = 0;
	
				if (optdef.value === undefined) {
					optdef.value = name.replace(/^--?/,'');
				}
				break;
	
			case 'enum':
				this._initEnum(optdef, name);
				break;
	
			case 'integer':
			case 'float':
				this._initNumber(optdef, name);
				break;
	
			case 'record':
				if (optdef.args === undefined || optdef.args.length == 0) {
					throw new Error('record '+name+' needs at least one argument');
				}
				optdef.argc = 0;
				var metavar = [];
				for (var i in optdef.args) {
					var arg = optdef.args[i];
					if (arg.target === undefined) {
						arg.target = i;
					}
					this._initType(arg, name+'['+i+']');
	
					if (arg.argc < 1) {
						throw new Error('argument '+i+' of option '+name+
							' has illegal number of arguments');
					}
					if (arg.metavar instanceof Array) {
						for (var j in arg.metavar) {
							metavar.push(arg.metavar[j]);
						}
					}
					else {
						metavar.push(arg.metavar);
					}
					delete arg.metavar;
					optdef.argc += arg.argc;
				}
				if (optdef.metavar === undefined) {
					optdef.metavar = metavar;
				}
				var onOption = optdef.onOption;
				if (onOption !== undefined) {
					optdef.onOption = function (values) {
						return onOption.apply(this, values);
					};
				}
				if (optdef.create === undefined) {
					optdef.create = Array;
				}
				optdef.parse = function () {
					var values = this.create();
					var parserIndex = 0;
					for (var i = 0; i < arguments.length;) {
						var arg = optdef.args[parserIndex ++];
						var raw = [];
						for (var j = 0; j < arg.argc; ++ j) {
							raw.push(arguments[i+j]);
						}
						values[arg.target] = arg.parse.apply(arg, raw);
						i += arg.argc;
					}
					return values;
				};
				break;
	
			case 'custom':
				if (optdef.argc === undefined || optdef.argc < -1) {
					optdef.argc = -1;
				}
	
				if (optdef.parse === undefined) {
					throw new Error(
						'no parse function defined for custom type option '+name);
				}
				break;
	
			default:
				optdef.argc = 1;
				optdef.parse = PARSERS[optdef.type];
	
				if (optdef.parse === undefined) {
					throw new Error('type of option '+name+' is unknown: '+optdef.type);
				}
		}
	
		initStringify(optdef);
		
		var count = 1;
		if (optdef.metavar === undefined) {
			optdef.metavar = this.strings.metavars[optdef.type];
		}
		
		if (optdef.metavar === undefined) {
			count = 0;
		}
		else if (optdef.metavar instanceof Array) {
			count = optdef.metavar.length;
		}
	
		if (optdef.argc == -1) {
			if (count > 1) {
				throw new Error('illegal number of metavars for option '+name+
					': '+JSON.stringify(optdef.metavar));
			}
		}
		else if (optdef.argc != count) {
			throw new Error('illegal number of metavars for option '+name+
				': '+JSON.stringify(optdef.metavar));
		}
	},
	_initEnum: function (optdef, name) {
		optdef.argc = 1;
	
		if (optdef.ignoreCase === undefined) {
			optdef.ignoreCase = true;
		}
	
		if (optdef.values === undefined || optdef.values.length == 0) {
			throw new Error('no values for enum '+name+' defined');
		}
	
		initStringify(optdef);

		var labels = [];
		var values = {};
		if (optdef.values instanceof Array) {
			for (var i in optdef.values) {
				var value = optdef.values[i];
				var label = String(value);
				values[optdef.ignoreCase ? label.toLowerCase() : label] = value;
				labels.push(optdef.stringify(value));
			}
		}
		else {
			for (var label in optdef.values) {
				var value = optdef.values[label];
				values[optdef.ignoreCase ? label.toLowerCase() : label] = value;
				labels.push(optdef.stringify(label));
			}
			labels.sort();
		}
		optdef.values = values;
		
		
		if (optdef.metavar === undefined) {
			optdef.metavar = '<'+labels.join(', ')+'>';
		}
	
		optdef.parse = function (s) {
			var value = values[optdef.ignoreCase ? s.toLowerCase() : s];
			if (value !== undefined) {
				return value;
			}
			throw new Error('illegal value for option '+name+': '+s);
		};
	},
	_initNumber: function (optdef, name) {
		optdef.argc = 1;
	
		if (optdef.NaN === undefined) {
			optdef.NaN = false;
		}

		if (optdef.min > optdef.max) {
			throw new Error('min > max for option '+name);
		}
		
		var parse, toStr;
		if (optdef.type == 'integer') {
			parse = function (s) {
				var i = NaN;
				if (s.indexOf('.') == -1) {
					i = parseInt(s, optdef.base)
				}
				return i;
			};
			if (optdef.base === undefined) {
				toStr = dec;
			}
			else {
				switch (optdef.base) {
					case  8: toStr = oct; break;
					case 10: toStr = dec; break;
					case 16: toStr = hex; break;
					default: toStr = function (val) {
							return val.toString(optdef.base);
						};
						var detail = this.strings.base+': '+optdef.base;
						if (optdef.details) {
							optdef.details.push(detail);
						}
						else {
							optdef.details = [detail];
						}
				}
			}
		}
		else {
			parse = parseFloat;
			toStr = dec;
		}
	
		if (optdef.metavar === undefined) {
			if (optdef.min === undefined && optdef.max === undefined) {
				optdef.metavar = this.strings.metavars[optdef.type];
			}
			else if (optdef.min === undefined) {
				optdef.metavar = '...'+toStr(optdef.max);
			}
			else if (optdef.max === undefined) {
				optdef.metavar = toStr(optdef.min)+'...';
			}
			else {
				optdef.metavar = toStr(optdef.min)+'...'+toStr(optdef.max);
			}
		}
		optdef.parse = function (s) {
			var n = parse(s);
					
			if ((!this.NaN && isNaN(n))
					|| (optdef.min !== undefined && n < optdef.min)
					|| (optdef.max !== undefined && n > optdef.max)) {
				throw new Error('illegal value for option '+name+': '+s);
			}
	
			return n;
		};
	}
};

function initStringify (optdef) {
	if (optdef.stringify === undefined) {
		optdef.stringify = STRINGIFIERS[optdef.type];
	}
	
	if (optdef.stringify === undefined) {
		optdef.stringify = stringifyAny;
	}
}

function defaults (target, defaults) {
	for (var name in defaults) {
		if (target[name] === undefined) {
			target[name] = defaults[name];
		}
	}
}

function dec (val) {
	return val.toString();
}

function oct (val) {
	return '0'+val.toString(8);
}

function hex (val) {
	return '0x'+val.toString(16);
}

const TRUE_VALUES  = {true:  true, on:  true, 1: true, yes: true};
const FALSE_VALUES = {false: true, off: true, 0: true, no:  true};

function parseBool (s) {
	s = s.trim().toLowerCase();
	if (s in TRUE_VALUES) {
		return true;
	}
	else if (s in FALSE_VALUES) {
		return false;
	}
	else {
		throw new Error('illegal boolean value: '+s);
	}
}

function id (x) {
	return x;
}

const PARSERS = {
	boolean: parseBool,
	string:  id,
	object:  JSON.parse
};

const TYPE_ALIAS = {
	int:    'integer',
	number: 'float',
	bool:   'boolean',
	str:    'string',
	obj:    'object'
};

const METAVARS = {
	string:  'STRING',
	integer: 'INTEGER',
	float:   'FLOAT',
	boolean: 'BOOLEAN',
	object:  'OBJECT',
	enum:    'VALUE',
	custom:  'VALUE'
};

function stringifyString(s) {
	if (/[\s'"\\<>,]/.test(s)) {
//		s = "'"+s.replace(/\\/g,'\\\\').replace(/'/g, "'\\''")+"'";
		s = JSON.stringify(s);
	}
	return s;
}

function stringifyPrimitive(value) {
	return ''+value;
}

function stringifyAny (value) {
	if (value instanceof Array) {
		var buf = [];
		for (var i in value) {
			buf.push(stringifyAny(value[i]));
		}
		return buf.join(' ');
	}
	else if (typeof(value) == 'string') {
		return stringifyString(value);
	}
	else {
		return String(value);
	}
}

function stringifyInteger (value) {
	if (this.base === undefined) {
		return value.toString();
	}

	switch (this.base) {
		case  8: return oct(value);
		case 16: return hex(value);
		default: return value.toString(this.base);
	}
}

function stringifyRecord (record) {
	var buf = [];
	for (var i = 0; i < this.args.length; ++ i) {
		var arg = this.args[i];
		buf.push(arg.stringify(record[arg.target]));
	}
	return buf.join(' ');
}

const STRINGIFIERS = {
	string:          stringifyString,
	integer:         stringifyInteger,
	boolean:         stringifyPrimitive,
	float:           stringifyPrimitive,
	object:          JSON.stringify,
	enum:            stringifyAny,
	custom:          stringifyAny,
	record:          stringifyRecord
};

exports.OptionParser = OptionParser;
