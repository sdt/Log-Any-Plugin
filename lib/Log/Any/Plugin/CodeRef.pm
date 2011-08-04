package Log::Any::Plugin::CodeRef;
# ABSTRACT: Code-ref argument support plugin for log adapters

use strict;
use warnings;

use Log::Any::Plugin::Util qw( get_old_method around );

use Data::Dumper;

sub install {
    my ($class, $adapter_class, %args) = @_;

    # Inject the preprocessor into the existing logging methods
    #
    for my $method_name ( Log::Any->logging_methods() ) {
        my $is_method_name = 'is_' . $method_name;
        my $is_method = get_old_method($adapter_class, $is_method_name);
        around($adapter_class, $method_name, sub {
            my ($old_method, $self, @args) = @_;

            return unless $self->$is_method();
            if (ref $args[0] eq 'CODE') {
                $old_method->($self, $args[0]->());
            }
            else {
                $old_method->($self, @args);
            }
        });
    }
}

1;

__END__

=pod

=head1 SYNOPSIS

    # Set up some kind of logger
    use Log::Any::Adapter;
    Log::Any::Adapter->set('SomeAdapter');

    # Apply the CodeRef plugin
    use Log::Any::Plugin;

    # If your adapter doesn't have native level support, add the Levels plugin
    Log::Any::Plugin->add('Levels');

    # Now add the coderef plugin - this must come after the Levels plugin
    Log::Any::Plugin->add('CodeRef');


    # In your modules
    $log->trace( sub { some_complicated_expression() } );

    $log->trace('simple'); # normal args still supported

    # some_complicated_expression() will only be evaluated if $log->is_trace is
    # true

=head1 DESCRIPTION

A common approach to speeding up disabled loggers is to pass a code reference
in place of the regular parameters. The parameters will only be evaluated if the
logger is enabled.

Log::Any::Plugin::CodeRef adds support for this.

Normally, the Dumper call will be executed even if trace messages are disabled:

    $log->trace( Dumper($my_complex_object) );

With the CodeRef plugin, it will be executed only if trace messages are enabled:

    $log->trace( sub { Data::Dumper($my_complex_object) } );

=head1 METHODS

There are no methods in this package which should be directly called by the
user.  Use Log::Any::Plugin->add() instead.

=head2 install

Private method called by Log::Any::Plugin->add()

=head1 CAVEATS

There is a non-zero overhead to using this plugin, and you won't see a win
unless your logging arguments are sufficiently complicated to overcome this.

Don't expect this plugin to magically speed up your logging - please benchmark
any gains before committing to this module.

=cut
