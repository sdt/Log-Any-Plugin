package Log::Any::Plugin::Levels;
# ABSTRACT: Logging-level filtering plugin for log adapters

use strict;
use warnings;
use Carp qw(croak);
use Hash::Util qw( lock_hash );
use Log::Any;

use Log::Any::Plugin::Util qw( get_old_method set_new_method );

my $level_count = 1;
my %level_value = map { $_ => $level_count++ } Log::Any->logging_methods();
my %level_name = reverse %level_value;
$level_value{all} = 1;
lock_hash(%level_value);

my $default_value = $level_value{warning};

# Inside-out storage for level field.
my %selected_level_value;
my %selected_level_name;

sub install {
    my ($class, $adapter_class, %args) = @_;

    my $accessor = $args{accessor} || 'level';
    croak $adapter_class . '::' . $accessor
        . q( already exists - use 'accessor' to specify another method name)
        if get_old_method($adapter_class, $accessor);

    if ($args{level}) {
        $default_value = _get_level_value($args{level});
    }

    # Create the $log->level accessor
    set_new_method($adapter_class, $accessor, sub {
        my $self = shift;
        if (@_) {
            my $level_name = shift;
            $selected_level_value{$self} = _get_level_value($level_name);
            $selected_level_name{$self} = $level_name;
        }
        return $selected_level_name{$self};
    });

    # Augment the $log->debug methods
    for my $method_name ( Log::Any->logging_methods() ) {
        my $level = $level_value{$method_name};

        my $old_method = get_old_method($adapter_class, $method_name);
        set_new_method($adapter_class, $method_name, sub {
            my $self = shift;
            return if ($selected_level_value{$self} || $default_value) > $level;
            $self->$old_method(@_);
        });
    }

    # Augment the $log->is_debug methods
    for my $method_name ( Log::Any->detection_methods() ) {
        my $level = $method_name;
        $level =~ s/^is_//;
        $level = $level_value{$level};

        my $old_method = get_old_method($adapter_class, $method_name);
        set_new_method($adapter_class, $method_name, sub {
            my $self = shift;
            return (($selected_level_value{$self} || $default_value) <= $level)
                && $self->$old_method(@_);
        });
    }
}

sub _get_level_value {
    my ($level_name) = @_;
    return $default_value if ($level_name eq 'default');
    croak('Unknown log level ' . $level_name)
        unless exists $level_value{$level_name};
    return $level_value{$level_name};
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
