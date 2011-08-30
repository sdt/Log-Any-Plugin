#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Test::NoWarnings if $ENV{RELEASE_TESTING};


note 'get_class_name'; {

    use Log::Any::Plugin::Util qw( get_class_name );

    is(get_class_name('MyClass'), 'Log::Any::Plugin::MyClass',
        '... short names get prefix');
    is(get_class_name('+MyNamespace::MyClass'), 'MyNamespace::MyClass',
        '... full names get preserved');
}

note 'around'; {

    use Log::Any::Plugin::Util qw( around );

    {
        package TestAround;
        sub new { bless { msg => '' }, shift }
        sub method {
            my $self = shift;
            $self->{msg} .= "@_";
        }
    }

    my $x = TestAround->new;
    $x->method(1, 2, 3);
    is($x->{msg}, '1 2 3', '... inner method works');
    $x->{msg} = '';

    lives_ok {
        around('TestAround', 'method', sub {
            my ($old_method, $self, @args) = @_;
            $self->{msg} .= 'before:';
            $self->$old_method(@args, reverse @args);
            $self->{msg} .= ':after';
        })
    } '... can apply around existing method';

    $x->method(1, 2, 3);
    is($x->{msg}, 'before:1 2 3 3 2 1:after', '... around method works');

    dies_ok { around 'TestAround', 'no_method', sub {} }
        '... cannot apply around non-existant method';
}

note 'before'; {

    use Log::Any::Plugin::Util qw( before );

    {
        package TestBefore;
        sub new { bless { msg => '' }, shift }
        sub method {
            my $self = shift;
            $self->{msg} .= "@_";
        }
    }

    lives_ok {
        before('TestBefore', 'method', sub {
            my ($self, @args) = @_;
            $self->{msg} .= "before[@args]:";
        })
    };

    my $x = TestBefore->new;
    $x->method(1, 2, 3);
    is($x->{msg}, 'before[1 2 3]:1 2 3', '... before method works');

    lives_ok {
        before('TestBefore', 'new_method', sub {
            my ($self, @args) = @_;
            $self->{msg} .= "new[@args]";
        })
    };

    my $y = TestBefore->new;
    $y->new_method(1, 2, 3);
    is($y->{msg}, 'new[1 2 3]', '... new methods work');

}

note 'after'; {

    use Log::Any::Plugin::Util qw( after );

    {
        package TestAfter;
        sub new { bless { msg => '' }, shift }
        sub method {
            my $self = shift;
            $self->{msg} .= "@_";
        }
    }

    lives_ok {
        after('TestAfter', 'method', sub {
            my ($self, @args) = @_;
            $self->{msg} .= ":after[@args]";
        })
    };

    my $x = TestAfter->new;
    $x->method(1, 2, 3);
    is($x->{msg}, '1 2 3:after[1 2 3]', '... after method works');

    lives_ok {
        after('TestAfter', 'new_method', sub {
            my ($self, @args) = @_;
            $self->{msg} .= "[@args]new";
        })
    };

    my $y = TestAfter->new;
    $y->new_method(1, 2, 3);
    is($y->{msg}, '[1 2 3]new', '... new methods work');
}

Test::NoWarnings::had_no_warnings() if $ENV{RELEASE_TESTING};
done_testing();
