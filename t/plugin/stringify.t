#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most          tests => 9;
use Test::NoWarnings;

use Log::Any::Adapter;
use Log::Any::Plugin;

Log::Any::Adapter->set('Test');
use Log::Any qw($log);

note 'Stringify plugin not applied yet. Checking default behaviour.'; {
    $log->debug('debug msg');
    eq_or_diff($log->msgs, [
        { category => 'main', level => 'debug', message => 'debug msg' },
    ], '... single args work as expected');
    $log->error('error msg', 'not logged');
    eq_or_diff($log->msgs, [
        { category => 'main', level => 'debug', message => 'debug msg' },
        { category => 'main', level => 'error', message => 'error msg' },
    ], '... further args skipped as expected');
}

note 'Applying Stringify plugin.'; {
    lives_ok { Log::Any::Plugin->add('Stringify') }
        '... plugin applied ok';
}

note 'Check functionality of default stringifier.'; {
    $log->clear;
    $log->debug('one', 'two', 'three');
    $log->contains_ok('onetwothree', '... multiple args concatenated');

    $log->trace('four', [ 5, 6, 7 ]);
    $log->contains_ok('four\[5,6,7\]', '... listrefs get expanded');

    $log->error('eight', { a => 'one', b => 'two' });
    $log->contains_ok(q(eight{a=\'one\',b=\'two\'}),
        '... hashrefs get expanded');
}

note 'Applying Stringify plugin.'; {
    # Normally you wouldn't stack the same plugin, but for these purposes
    lives_ok { Log::Any::Plugin->add('Stringify',
            stringifier => sub { reverse @_ }) }
        '... plugin applied ok';
}

note 'Check functionality of non-default stringifier.'; {
    $log->clear;
    $log->debug('one', 'two', 'three');
    $log->contains_ok('threetwoone', '... multiple args concatenated');
}

note 'You like warnings?';
