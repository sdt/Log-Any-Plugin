package Log::Any::Plugin::ANSIColor;
# ABSTRACT: Auto-colorize logs using Term::ANSIColor based on log level.

use strict;
use warnings;

use Log::Any::Plugin::Util  qw( get_old_method set_new_method );
use Term::ANSIColor         qw( colored );

sub install {
    my ($class, $adapter_class, %args) = @_;

    # Inject the stringifier into the existing logging methods
    #
    for my $method_name ( Log::Any->logging_methods() ) {
        if (my $color = $args{$method_name} || $args{default}) {
            my $old_method = get_old_method($adapter_class, $method_name);
            set_new_method($adapter_class, $method_name, sub {
                my $self = shift;
                $self->$old_method(colored([$color], @_));
            });
        }
    }
}

1;

__END__

=pod

=for Pod::Coverage install

=head1 SYNOPSIS

    # Set up some kind of logger that writes to a terminal
    use Log::Any::Adapter;
    Log::Any::Adapter->set('Stdout');

    # Color it up
    use Log::Any::Plugin;
    Log::Any::Plugin->add('ANSIColor',
        default  => 'cyan',
        error    => 'red',
        warning  => 'yellow',
        critical => 'bright_white on_red',
    );

=head1 DESCRIPTION

This plugin uses Term::ANSIColor to colorize logs based on the loglevel.

=head1 CONFIGURATION

Provide a list of C<$log_level => $color> pairs in the C<add> command.

Any unspecified log levels will use the C<default> color, if it exists,
otherwise they will be passed through untouched.

Colors should be specified as space-separated strings, as per the C<color>
and C<colored> functions from L<Term::ANSIColor>.

=cut
