package Log::Any::Plugin::Util;
# ABSTRACT: Utilities for Log::Any::Plugin classes

use strict;
use warnings;
use Carp qw(croak);

use base qw(Exporter);

our @EXPORT_OK = qw(
    get_old_method
    set_new_method
    get_class_name
);

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
    my ($name) = @_;

    return substr($name, 0, 1) eq '+' ? substr($name, 1)
                                      : 'Log::Any::Plugin::' . $name;
}

1;

__END__

=pod

=head1 DESCRIPTION

These functions are only of use to authors of Log::Any::Plugin classes.

Users should see Log::Any::Plugin instead.

=head1 FUNCTIONS

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

Coderef of the new method.

=back

=head2 get_class_name ( $name )

Creates a fully-qualified class name from the abbreviated class name rules
in Log::Any::Plugin.

=over

=item * $name

Either a namespace suffix, or a fully-qualified class name prefixed with '+'.

=back

=head1 SEE ALSO

L<Log::Any::Plugin>

=head1 ACKNOWLEDGEMENTS

Thanks to Strategic Data for sponsoring the development of this module.

=cut
