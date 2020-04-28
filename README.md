# cli

A lua module to build command line interfaces declaratively.

## Some examples

To write a program with flags and positional arguments, you can do the following:

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

## Usage

The start point of the `cli` module are the functions `cli.program` and `cli.command`. Both have the same interface: a table with the following fields (all of them are optionals):

```
{
    A string containing a description (used for help messages),
    
    A sequence of definitions of command line arguments,
    
    A function to be executed
}
```

The provided function receives as argument a table with all command line arguments filled with their values:

```lua
cli.program {
    cli.flag "a-number" {
        type = cli.number
    },
    
    function(args)
        print(args.a_number)
    end
}
```

If an argument has hyphens in its name, they are replaced with underscores, as in the above example.

Any value returned by the main function (the one present in the `cli.program` table) is passed as an additional argument to the commands' functions:

```lua
a_command = cli.command {
    cli.flag "do-it" {
        type = cli.boolean
    },
    
    function(args, seventeen, nineteen)
        print(args.do_it)
        assert(seventeen == 17)
        assert(nineteen == 19)
    end
}

cli.program {
    function()
        return 17, 19
    end
}
```

### Defining command line arguments

There are two kinds of arguments: flags and positional arguments.

#### Flags

Flags are defined with `cli.flag`, passing to it a name and a table describing it:

```lua
cli.flag "first-flag" {
    "This is the first flag",
    type = cli.boolean
}
```

If the name contains a comma, the word preceding it is interpreted as a short variant of the word after it:

```lua
cli.flag "o,output" {}
```

The description table has the following fields:
- an optional string containing a description;
- a `type` key describing the value this flag accepts. Must be one of `cli.string`, `cli.number` or `cli.boolean`. It defaults to `cli.string`. If it is set to `cli.number`, the module will try to convert the value given at program invocation to a number and prints an error if it can not succeed;
- an optional `default` key containing a default value for this flag. Flags without a default value are considered mandatory.

#### Positional arguments

Positional arguments are defined with `cli.positional`, passing to it a name and a table describing it:

```lua
cli.positional "file" {
    "The file to be read",
    type = cli.string
}
```

The description table has the following fields:
- an optional string containing a description;
- a `type` key describing the value this positional accepts. Must be one of `cli.string` or `cli.number`. It defaults to `cli.string`. If it is set to `cli.number`, the module will try to convert the value given at program invocation to a number and prints an error if it can not succeed;
- an optional `default` key containing a default value for this positional. Positionals without a default value are considered mandatory;
- an optional `many` key telling whether this positional can receive many values at once.

The `many` key is used this way:

```lua
cli.positional "files" {
    "The files to be edited",
    type = cli.string,
    many = true,
    default = { "README.md", "cli.lua" }
}
```

### Localisation

The function `cli.locale` can be used to set the locale of help and error messages:

```lua
cli.locale "pt_BR"
```
