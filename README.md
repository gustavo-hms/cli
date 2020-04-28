# cli

A lua module to build command line interfaces declaratively.

## Some examples

To write a program with flags and positional arguments, you do the following:

```lua
local cli = require "cli"

cli.locale "en_US"

cli.program {
	"A description of the program",
	
	cli.flag "o,one" {
		"The first option",
		type = cli.string
	},
	
	cli.flag "the-other" {
		"The second option",
		type = cli.number,
		default = 17
	},
	
	cli.positional "file" {
		"The input file",
		type = cli.string
	},
	
	function(args)
		print(string.format("One: %s.", args.one))
		print(string.format("Two plus 1: %d.", args.the_other + 1))
		print(string.format("File: %s.", args.file))
	end
}
```

Supposing this is the code for a program called `test-cli`, running `test-cli -o value input.txt` will print:

```
One: value
Two plus 1: 18
File: input.txt
```

### Automatic help messages

In the above example, running  `test-cli --help` or `test-cli -h` will print:

```
A description of the program

Usage:

    test-cli [options] file

    Options and arguments without a default value are mandatory.

Options:

    -o, --one <string>
        The first option

    --the-other <number> (default: 17)
        The second option

Arguments:

    file
        The input file

```

### Subcommands

Your program can be easily divided into subcommands:

```lua
local cli = require "cli"

cli.locale "en_US"

add = cli.command {
	"Add all the given numbers",

	function(args)
		local sum = 0

		for _, v in ipairs(args.numbers) do
			sum = sum + v
		end

		print(sum)
	end
}

max = cli.command {
	"Find the maximum value",

	function(args)
		print(math.max(table.unpack(args.numbers)))
	end
}

all_above = cli.command {
	"Prints all numbers above the given value",

	cli.flag "c,cutoff" {
		"The value above which all numbers are retained",

		type = cli.number
	},

	function(args)
		for _, v in ipairs(args.numbers) do
			if v > args.cutoff then
				print(v)
			end
		end
	end
}

cli.program {
	"A program to compute numbers",

	cli.positional "numbers" {
		"The numbers to operate upon",

		type = cli.number,
		many = true,
		default = {1, 3, 17}
	}
}
```

Supposing this is the code for an hypothetical `compute`, running `compute --help` will print:

```
A program to compute numbers

Usage:

    compute add numbers...
        Add all the given numbers

    compute all-above [options] numbers...
        Prints all numbers above the given value

    compute max numbers...
        Find the maximum value

You can run

    compute <command> --help

to get more details about a specific command.

```

And, then, running `compute all-above --help`:

```
Prints all numbers above the given value

Usage:

    compute all-above [options] numbers...

    Options and arguments without a default value are mandatory.

Options:

    -c, --cutoff <number>
        The value above which all numbers are retained

Arguments:

    numbers... (default: 1 3 17)
        The numbers to operate upon

```
