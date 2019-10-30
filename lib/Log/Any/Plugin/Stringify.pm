package Log::Any::Plugin::Stringify;
# ABSTRACT: Custom argument stringification plugin for log adapters

use strict;
use warnings;

use Log::Any::Plugin::Util qw(
    all_logging_methods get_old_method set_new_method
);

use Data::Dumper;

my $separator;


sub install {
    my ($class, $adapter_class, %args) = @_;

    $separator = defined $args{separator} ? $args{separator} : '';
    my $stringifier = $args{stringifier} || \&default_stringifier;

    # Inject the stringifier into the existing logging methods
    #
    for my $method_name ( all_logging_methods() ) {
        my $old_method = get_old_method($adapter_class, $method_name);
        set_new_method($adapter_class, $method_name, sub {
            my $self = shift;
            $self->$old_method($stringifier->(@_));
        });
    }
}

sub default_stringifier {
    my @args = @_;

    local $Data::Dumper::Indent    = 0;
    local $Data::Dumper::Pair      = '=';
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Terse     = 1;

    return join($separator, map { ref $_ ? Dumper($_) : $_ } @args);
}

1;

__END__

=pod

=head1 SYNOPSIS

    # Set up some kind of logger
    use Log::Any::Adapter;
    Log::Any::Adapter->set('SomeAdapter');

    # Apply your own argument stringifier.
    use Log::Any::Plugin;
    Log::Any::Plugin->add('Stringify', \&my_stringifier);

=head1 DESCRIPTION

Log::Any logging functions are only defined to have a single $msg argument.
Some adapters accept multiple arguments (like print does), but many don't.
You may also want to do some sort of stringification of hash and list refs.

Log::Any::Plugin::Stringify allows you to inject an argument stringification
function into every logging call, so that when you write this:

    $log->error( ... );

you effectively get this:

    $log->error( my_function( ... ) );

=head1 CONFIGURATION

These configuration values are passed as key-value pairs:
    Log::Any::Plugin->add('Stringify', stringifier => \&my_func);

=head2 stringifier => &my_func

The stringifier function takes a list of arguments and should return a single
string.

See default_stringifier below for the default stringifier behaviour.

=head2 separator => ''

See default_stringifier below for the default stringifier behaviour.


=head1 METHODS

There are no methods in this package which should be directly called by the
user.  Use Log::Any::Plugin->add() instead.

=head2 install

Private method called by Log::Any::Plugin->add()

=head2 default_stringifier

The default stringifier if no custom stringifier is supplied.

Listrefs and hashrefs are expanded by L<Data::Dumper>, and the whole lot is
concatenated into one string.

The C<separator> configuration argument can be used to customise how log arguments
are separated from each other, e.g. C<trace("hello", "there", [1, 2, 2])> with
a separator of '##' results in: C<hello##there##[1,2,2]> -- the Dumper-driven
output is not affected by the separator.

=head1 SEE ALSO

L<Log::Any::Plugin>

=head1 ACKNOWLEDGEMENTS

Thanks to Strategic Data for sponsoring the development of this module.

=cut
