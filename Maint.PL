use strict;
use warnings;
use Dist::Inkt::Profile::TOBYINK;

my $dist = 'Dist::Inkt::Profile::TOBYINK'->new(
	'rootdir'  => '.',
	'name'     => 'Dist-Inkt',
	'version'  => '0.001',
);

$dist->BuildAll;
