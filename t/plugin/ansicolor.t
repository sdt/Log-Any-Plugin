#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Exception;

use Term::ANSIColor qw( colored );

require Test::NoWarnings if $ENV{RELEASE_TESTING};

use Log::Any::Plugin;

use Log::Any::Test;
use Log::Any qw($log);

my %color = (
    error   => 'red',
    info    => 'blue on_white',
    warning => 'bright_green on_white',
);

note 'LogLevel has not been applied yet. Check default behaviour.'; {
    $log->debug('debug');
    $log->contains_ok('debug', '... debug gets logged');
    $log->error('error');
    $log->contains_ok('error', '... error gets logged');
}

note 'Applying ANSIColor plugin.'; {
    lives_ok { Log::Any::Plugin->add('ANSIColor', %color) }
        '... plugin applied ok';
}

note 'Check that enabled message types get logged correctly'; {
    $log->clear;

    #my @tests = Log::Any->logging_methods;
    my @tests = Log::Any::Plugin::Util->all_logging_methods;
    my @expected;

    for my $method (@tests) {
        my $msg = "This is $method";
        $log->$method($msg);
        push(@expected, expected($method => $msg));
    }

    eq_or_diff($log->msgs, \@expected, 'All logs correctly colored');
    $log->clear;
}

sub expected {
    my ($method, $msg) = @_;

    if (my $c = $color{$method} || $color{default}) {
        $msg = colored([$c], $msg);
    }

    my %alias = Log::Any::Adapter::Util::log_level_aliases();
    $method = $alias{$method} || $method;

    return {
        category => 'main',
        level => $method,
        message => $msg,
    };
}

Test::NoWarnings::had_no_warnings() if $ENV{RELEASE_TESTING};
done_testing();
