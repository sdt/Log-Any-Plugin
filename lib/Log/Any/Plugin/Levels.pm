package Log::Any::Plugin::Levels;
# ABSTRACT: Logging-level filtering plugin for log adapters

use strict;
use warnings;
use Carp qw(croak);
use Hash::Util qw( lock_hash );
use Log::Any;

use Log::Any::Plugin::Util qw( around get_old_method set_new_method );

my $level_count = 0;
my %level_val = map { $_ => ++$level_count } Log::Any->logging_methods();
lock_hash(%level_val);

# Inside-out storage for level field.
# Normally, we'd clear this out in a DESTROY method, but given the bounded
# nature of $log creation, this shouldn't be necessary. (TODO: check this)
my %level_store;

sub install {
    my ($class, $adapter_class, %args) = @_;

    my $accessor = $args{accessor} || 'level';
    croak $adapter_class . '::' . $accessor
        . q( already exists - use 'accessor' to specify another method name)
        if get_old_method($adapter_class, $accessor);

    my $default_level = _verify_level($args{level} || 'warning');

    # Create the $log->level accessor
    set_new_method($adapter_class, $accessor, sub {
        my $self = shift;
        if (@_) {
            my $level = shift;
            if ($level eq 'default') {
                delete $level_store{$self};
            }
            else {
                $level_store{$self} = _verify_level($level);
            }
        }
        return $level_store{$self} || 'default';
    });

    # Augment the $log->debug methods
    for my $method_name ( Log::Any->logging_methods() ) {
        my $level = $method_name;

        my $old_method = get_old_method($adapter_class, $method_name);
        set_new_method($adapter_class, $method_name, sub {
            my $self = shift;
            return if $level_val{ $level_store{$self} || $default_level }
                    > $level_val{$level};
            $self->$old_method(@_);
        });
    }

    # Augment the $log->is_debug methods
    for my $method_name ( Log::Any->detection_methods() ) {
        my $level = $method_name;
        $level =~ s/^is_//;

        my $old_method = get_old_method($adapter_class, $method_name);
        set_new_method($adapter_class, $method_name, sub {
            my $self = shift;
            return ($level_val{ $level_store{$self} || $default_level }
                    <= $level_val{$level})
                && $self->$old_method(@_);
        });
    }
}

sub _verify_level {
    my ($level) = @_;
    croak('Unknown log level ' . $level)
        unless exists $level_val{$level};
    return $level;
}

1;

__END__

=pod

=head1 NAME

Log::Any::Plugin::FilterArgs - custom log-level filtering for log adapters

=head1 SYNOPSIS

    # Set up some kind of logger.
    use Log::Any::Adapter;
    Log::Any::Adapter->set('SomeAdapter');

    # Apply the Levels plugin to your logger
    use Log::Any::Plugin;
    Log::Any::Plugin->add('Levels', level => 'debug');


    # In your modules
    use Log::Any qw($log);

    $log->trace('trace'); # this log is ignored
    $log->error('error'); # this log gets through

    $log->level('trace');
    $log->trace('trace'); # this gets through now

=head1 DESCRIPTION

Log::Any leaves the decision of which log levels to ignore and which to
actually log down to the individual adapters. Many adapters simply log
everything.

Log::Any::Plugin::Levels allows you to add level filtering functionality into
any adapter. Logs lower than $log->level are ignored.

The $log->is_debug family of functions are modified to reflect this level.

=head1 CONFIGURATION

Configuration values are passed as key-value pairs when adding the plugin:
    Log::Any::Plugin->add('Levels',
                            level    => 'debug',
                            accessor => 'my_level');

=head2 level => $default_level

The global log level, which defaults to 'warning'. See the level method below
for a discussion on how this is applied.

=head2 accessor => $accessor_name

This is the name of the $log->level accessor function.

The default value is 'level'. This can be changed to avoid any name clashes
that may occur. An exception will be thrown in the case of a name clash.

=head1 METHODS

There are no methods in this package which should be directly called by the
user. Use Log::Any::Plugin->add() instead.

=head2 install

Private method called by Log::Any::Plugin->add()

=head1 ADAPTER METHODS

The following methods are injected into the adapter class.

=head2 level( [ $log_level ] )

Accessor for the current log level in the calling $log object.

All $log objects start with the default level specified when adding the
plugin.  Individual $log objects can set a custom level with this accessor.

To reset to the default log level, specify 'default'.

=head1 SEE ALSO

L<Log::Any::Plugin>

=head1 ACKNOWLEDGEMENTS

Thanks to Strategic Data for sponsoring the development of this module.

=cut
