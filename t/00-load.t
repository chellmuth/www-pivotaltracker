#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::PivotalTracker' );
}

diag( "Testing WWW::PivotalTracker $WWW::PivotalTracker::VERSION, Perl $], $^X" );
