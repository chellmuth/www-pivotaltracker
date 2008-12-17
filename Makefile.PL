use inc::Module::Install;

name     'WWW-PivotalTracker';
all_from 'lib/WWW/PivotalTracker.pm';
author   'Jacob Helwig <jhelwig@cpan.org>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

