package Log::Any::Plugin::FilterArgs;

use strict;
use warnings;

use Log::Any::Plugin::Util qw( around );

use Data::Dumper;

sub install {
    my ($class, $adapter_class, %args) = @_;

    my $filter = $args{filter} || \&default_filter;

    # Inject the filter into the existing logging methods
    #
    for my $method_name ( Log::Any->logging_methods() ) {
        around($adapter_class, $method_name, sub {
            my ($old_method, $self, @args) = @_;
            $old_method->($self, $filter->(@args));
        });
    }
}

sub default_filter {
    my (@args) = @_;

    local $Data::Dumper::Indent    = 0;
    local $Data::Dumper::Pair      = '=';
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Terse     = 1;

    return join('', map { ref $_ ? Dumper($_) : $_ } @args);
}

1;

__END__

=pod

=head1 NAME

Log::Any::Plugin::FilterArgs - custom argument filtering for log adapters

=head1 SYNOPSIS

    # Set up some kind of logger
    use Log::Any::Adapter;
    Log::Any::Adapter->set('SomeAdapter');

    # Apply your own argument filter.
    use Log::Any::Plugin;
    Log::Any::Plugin->add('FilterArgs', \&my_filter);

=head1 DESCRIPTION

Log::Any logging functions are only defined to have a single $msg argument.
Some adapters accept multiple arguments (like print does), but many don't.
You may also want to do some sort of stringification of hash and list refs.

Log::Any::Plugin::FilterArgs allows you to inject a function into every logging
call, so that when you write this:

    $log->error( ... );

you effectively get this:

    $log->error( my_filter( ... ) );

=head1 CONFIGURATION

These configuration values are passed as key-value pairs:
    Log::Any::Plugin->add('FilterArgs', filter => \&my_filter);

=head2 my_filter => &filter_function

The filter function takes a list of arguments and should return a single string.

The default filter joins the arguments together, and uses Data::Dumper to
expand list and hash refs.

=head1 METHODS

There are no methods in this package which should be directly called by the
user.  Use Log::Any::Plugin->add() instead.

=head1 AUTHOR

Stephen Thirlwall <stephen.thirlwall@strategicdata.com.au>

=cut
