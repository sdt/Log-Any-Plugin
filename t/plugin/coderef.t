#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most          tests => 10;
use Test::NoWarnings;

use Log::Any::Adapter;
use Log::Any::Plugin;

Log::Any::Adapter->set('Test');
use Log::Any qw($log);

note 'LogLevel has not been applied yet. Check default behaviour.'; {
    $log->clear;
    $log->error(sub { 'something' });
    $log->contains_ok('CODE\(0x', q(... coderefs don't get executed));
}

note 'Applying LogLevel and CodeRef plugin.'; {
    lives_ok { Log::Any::Plugin->add('Levels') }
        '... levels plugin applied ok';
    lives_ok { Log::Any::Plugin->add('CodeRef') }
        '... coderef plugin applied ok';
}

note 'Check coderef behaviour.'; {
    $log->clear;

    $log->error(sub { 'coderef' });
    $log->contains_ok('coderef', '... coderefs get executed');

    $log->error('scalar');
    $log->contains_ok('scalar', '... plain scalars as normal');

    my $got_called = 0;

    ok( $log->is_error, '... errors logs are enabled');
    $log->error(sub { ++$got_called });
    is($got_called, 1, '... coderefs get called when level enabled');

    ok( ! $log->is_trace, '... trace logs are disabled');
    $log->trace(sub { ++$got_called });
    is($got_called, 1, q(... coderefs don't get called when level disabled));
}

note 'Yes warnings?';
