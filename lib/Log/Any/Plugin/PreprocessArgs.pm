package Log::Any::Plugin::PreprocessArgs;
# ABSTRACT: Custom argument preprocessing plugin for log adapters

use strict;
use warnings;

use Log::Any::Plugin::Util qw( around );

use Data::Dumper;

sub install {
    my ($class, $adapter_class, %args) = @_;

    my $preprocessor = $args{preprocessor} || \&default_preprocessor;

    # Inject the preprocessor into the existing logging methods
    #
    for my $method_name ( Log::Any->logging_methods() ) {
        around($adapter_class, $method_name, sub {
            my ($old_method, $self, @args) = @_;
            $old_method->($self, $preprocessor->(@args));
        });
    }
}

sub default_preprocessor {
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

=head1 SYNOPSIS

    # Set up some kind of logger
    use Log::Any::Adapter;
    Log::Any::Adapter->set('SomeAdapter');

    # Apply your own argument preprocessor.
    use Log::Any::Plugin;
    Log::Any::Plugin->add('PreprocessArgs', \&my_func);

=head1 DESCRIPTION

Log::Any logging functions are only defined to have a single $msg argument.
Some adapters accept multiple arguments (like print does), but many don't.
You may also want to do some sort of stringification of hash and list refs.

Log::Any::Plugin::PreprocessArgs allows you to inject an argument preprocessing
function into every logging call, so that when you write this:

    $log->error( ... );

you effectively get this:

    $log->error( my_function( ... ) );

=head1 CONFIGURATION

These configuration values are passed as key-value pairs:
    Log::Any::Plugin->add('PreprocessArgs', preprocessor => \&my_func);

=head2 preprocessor => &my_func

The preprocessor function takes a list of arguments and should return a single
string.

See default_preprocessor below for the default preprocessor.

=head1 METHODS

There are no methods in this package which should be directly called by the
user.  Use Log::Any::Plugin->add() instead.

=head2 install

Private method called by Log::Any::Plugin->add()

=head2 default_preprocessor

The default preprocessor function if none is supplied. Listrefs and hashrefs are
expanded by Data::Dumper, and the whole lot is concatenated into one string.

=cut
