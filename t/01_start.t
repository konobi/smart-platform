#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;

use_ok('RSP::Server');
ok( RSP::Server->start() );
ok( RSP::Server->stop() );

1;