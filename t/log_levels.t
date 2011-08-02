#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most          tests => 24;
use Test::NoWarnings;

use Log::Any::Adapter;
use Log::Any::Plugin;

Log::Any::Adapter->set('Test');
use Log::Any qw($log);

note 'LogLevel has not been applied yet. Check default behaviour.'; {
    $log->debug('debug');
    $log->contains_ok('debug', '... debug gets logged');
    $log->error('error');
    $log->contains_ok('error', '... error gets logged');

    ok( ! $log->can('level'), '... no level method exists' );
}

note 'Applying LogLevel plugin.'; {
    lives_ok { Log::Any::Plugin->add('LogLevels') }
        '... plugin applied ok';
}

note 'Check that enabled message types get logged correctly'; {
    ok( $log->is_error, '... $log->error is enabled' );
    $log->empty_ok('... log should be empty');
    $log->error('error');
    $log->contains_ok('error', '... error gets logged');
}

note 'Check that disabled message types get ignored correctly'; {
    ok( ! $log->is_debug, '... $log->debug should to be disabled' );
    $log->empty_ok('... log should be empty');
    $log->debug('debug');
    #$log->does_not_contain_ok('two');  # does_not_contain_ok is broken in 0.12
    $log->empty_ok('... log should still be empty (debug not logged)');
}

note 'Check synonyms'; {
    ok( ! $log->is_info, '... $log->info should be disabled' );
    ok( ! $log->is_inform, '... $log->inform should be disabled' );
    $log->empty_ok('... log should be empty');
    $log->info('info');
    $log->empty_ok('... log should still be empty (info not logged)');
    $log->inform('inform');
    $log->empty_ok('... log should still be empty (inform not logged)');
}

note 'Check changing the log level'; {
    ok( $log->can('level'), '... level method exists' );
    throws_ok { $log->level('mumble') } qr/Unknown log level/,
        '... unknown log levels cannot be set';
    lives_ok { $log->level('debug') }
        '... known log levels should able to be set';
    is( $log->level, 'debug',  '... log level should now be debug' );
    ok( $log->is_debug, '... $log->debug should now be enabled' );
    $log->empty_ok('... log should be empty');
    $log->debug('debug');
    $log->contains_ok('debug', '... debug gets logged');
}

note 'Check clashing method names'; {
    throws_ok {
        Log::Any::Plugin->add('LogLevels', level_key => 'contains_ok')
    } qr/Test::contains_ok already exists/,
        '... method name clashes get detected';
}
