# NAME

Log::Any::Plugin - Adapter-modifying plugins for Log::Any

# VERSION

version 0.012

# SYNOPSIS

    use Log::Any::Adapter;
    use Log::Any::Plugin;

    # Create your adapter as normal
    Log::Any::Adapter->set( 'SomeAdapter' );

    # Add plugin to modify its behaviour
    Log::Any::Plugin->add( 'Stringify' );

    # Multiple plugins may be used together
    Log::Any::Plugin->add( 'Levels', level => 'debug' );

# DESCRIPTION

Log::Any::Plugin is a method for augmenting arbitrary instances of
Log::Any::Adapters.

Log::Any::Plugins work much in the same manner as Moose 'around' modifiers to
augment logging behaviour of pre-existing adapters.

# MOTIVATION

Many of the Log::Any::Adapters have extended functionality, such as being
able to selectively disable various log levels, or to handle multiple arguments.

In order for Log::Any to be truly 'any', only the common subset of adapter
functionality can be used. Any specific adapter functionality must be avoided
if there is a possibility of using a different adapter at a later date.

Log::Any::Plugins provide a method to augment adapters with missing
functionality so that a superset of adapter functionality can be used.

# METHODS

## add ( $plugin, \[ %plugin\_args \] )

This is the single method for adding plugins to adapters. It works in a
similar function to Log::Any::Adapter->set()

- $plugin

    The plugin class to add to the currently active adapter. If the class is in
    the Log::Any::Plugin:: namespace, you can simply specify the name, otherwise
    prefix a '+'.

        eg. '+My::Plugin::Class'

- %plugin\_args

    These are plugin specific arguments. See the individual plugin documentation for
    what options are supported.

# PLUGIN DEVELOPMENT

## Build Tools

- You must have [cpanm](https://metacpan.org/pod/App::cpanminus) installed.
- Then install [Dist::Zilla](http://dzil.org/) via `cpanm Dist::Zilla`. This is
        a [Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla)-managed project.

## Setup Dependencies

On initial check out of the project, set-up the required dependencies as follows:

    # Get dependencies
    dzil authordeps --missing | cpanm
    dzil listdeps --author | cpanm

Next run a basic test suite:

    dzil test

Install the necessary missed dependencies as needed via `cpanm` and rerun
tests till they execute successfully.

For example, there's a [known issue](https://rt.cpan.org/Public/Bug/Display.html?id=98689)
requiring explicit installation of [Module::Build::Version](https://metacpan.org/pod/Module%3A%3ABuild%3A%3AVersion).

See the error logs as directed in the `cpanm` output.

## Development

A plugin's entry point is via its `install` method which has the signature:

    install($class, $adapter_class, %args)

`$adapter_class` is the [Log::Any::Adapter](https://metacpan.org/pod/Log%3A%3AAny%3A%3AAdapter) adapter class to be used, e.g.
`Stderr`.

`%args` is a hash of arguments to configure or customise the plugin.

Plugins add new facilities or augment existing facilities, so it's hard to
define confines of their scope. This module packages in several use-case
driven plugins that may serve as examples — check the
[SEE ALSO](#see-also) section.

Once a plugin is implemented, and tests added, re-run the [Setup Dependencies](#setup-dependencies)
steps to get any new required dependencies.

Next, run the full suite of tests through a sequence of:

    dzil test
    dzil test --author
    dzil test --release

Finally to remove any temporarily generated artifacts, run:

    dzil clean

# SEE ALSO

[Log::Any](https://metacpan.org/pod/Log%3A%3AAny), [Log::Any::Plugin::Levels](https://metacpan.org/pod/Log%3A%3AAny%3A%3APlugin%3A%3ALevels), [Log::Any::Plugin::Stringify](https://metacpan.org/pod/Log%3A%3AAny%3A%3APlugin%3A%3AStringify)

# ACKNOWLEDGEMENTS

Thanks to Strategic Data for sponsoring the development of this module.

# AUTHOR

Stephen Thirlwall <sdt@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2019, 2017, 2015, 2014 by Stephen Thirlwall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# CONTRIBUTORS

- José Joaquín Atria <jjatria@gmail.com>
- Kamal Advani <kamal@namingcrisis.net>
