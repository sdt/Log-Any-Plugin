package Log::Any::Plugin::Util;
# ABSTRACT: Utilities for Log::Any::Plugin classes

use strict;
use warnings;
use Carp qw(croak);

use base qw(Exporter);

our @EXPORT_OK = qw(
    around
    get_old_method
    set_new_method
    get_class_name
);

sub around {
    my ($class, $method_name, $new_method) = @_;

    my $old_method = get_old_method($class, $method_name);
    croak $class . '::' . $method_name . ' not defined'
        unless defined $old_method;

    my $wrapper = sub {
        my ($self, @args) = @_;
        $new_method->($old_method, $self, @args);
    };

    set_new_method($class, $method_name, $wrapper);
}

sub after {
    my ($class, $method_name, $new_method) = @_;
    my $old_method = get_old_method($class, $method_name);

    if ($old_method) {
        set_new_method($class, $method_name, sub {
            my ($self, @args) = @_;
            $old_method->($self, @args);
            $new_method->($self, @args);
        });
    }
    else {
        set_new_method($class, $method_name, $new_method);
    }
}

sub before {
    my ($class, $method_name, $new_method) = @_;
    my $old_method = get_old_method($class, $method_name);

    if ($old_method) {
        set_new_method($class, $method_name, sub {
            my ($self, @args) = @_;
            $new_method->($self, @args);
            $old_method->($self, @args);
        });
    }
    else {
        set_new_method($class, $method_name, $new_method);
    }
}

sub get_old_method {
    my ($class, $method_name) = @_;
    return $class->can($method_name);
}

sub set_new_method {
    my ($class, $method_name, $new_method) = @_;

    no warnings 'redefine';
    no strict 'refs'; ## no critic (ProhibitNoStrict)
    *{ $class . '::' . $method_name } = $new_method;
}

sub get_class_name {
    my ($prefix, $spec) = @_;

    return ref $spec if ref $spec;
    return substr($spec, 1) if $spec =~ /^\+/;
    return $prefix . $spec;
}

1;

__END__

=pod

=head1 DESCRIPTION

These functions are only of use to authors of Log::Any::Plugin classes.

Users should see Log::Any::Plugin instead.

=head1 FUNCTIONS

=head2 around ( $class, $method_name, &new_method )

Applies an 'around' method modifier to the given method. Semantics are very
similar to the 'around' method modifier in Moose.

Throws an exception if no method by that name exists.

=over

=item * $class

Name of class containing the method.

=item * $method_name

Name of method to be modified.

=item * &new_method

Coderef of the new method. Arguments are passed the same as a Moose 'around'
modifier: ($old_method, $self, @args)

=back

=head2 before ( $class, $method_name, &new_method )

Applies a 'before' method modifier to the given method. Semantics are very
similar to the 'before' method modifier in Moose.

Simply installs the new method if no method by that name exists.

=over

=item * $class

Name of class containing the method.

=item * $method_name

Name of method to be modified.

=item * &new_method

Coderef of the new method. Arguments are passed the same as a Moose 'before'
modifier: ($self, @args)

=back

=head2 after ( $class, $method_name, &new_method )

Applies a 'after' method modifier to the given method. Semantics are very
similar to the 'after' method modifier in Moose.

Simply installs the new method if no method by that name exists.

=over

=item * $class

Name of class containing the method.

=item * $method_name

Name of method to be modified.

=item * &new_method

Coderef of the new method. Arguments are passed the same as a Moose 'after'
modifier: ($self, @args)

=back

=head2 get_old_method ( $class, $method_name )

Returns a coderef of the existing method in the class, or undef if none exists.
Exactly the same semantics as $class->can($method_name).

=head2 set_new_method ( $class, $method_name, &new_method )

Replaces the given method with the new version.

=over

=item * $class

Name of class containing the method.

=item * $method_name

Name of method to be modified.

=item * &new_method

Coderef of the new method. Unlike 'around', this method takes exactly the
same parameters as the original method: ($self, @args)

=back

=head2 get_class_name ( $prefix, $spec )

Creates a fully-qualified class name from the abbreviated class name rules
in Log::Any::Plugin.

=over

=item * $prefix

Fully-qualified namespace prefix to apply by default. eg: 'Log::Any::Plugin::'

=item * $spec

Either a namespace suffix, or a fully-qualified class name prefixed with '+',
or an object instance.

=back

=cut
