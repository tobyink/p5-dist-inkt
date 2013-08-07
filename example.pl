use strict;
use warnings;
use Dist::Inkt;

my $dist = 'Dist::Inkt'->new(
	'rootdir'  => '.',
	'name'     => 'Dist-Inkt',
	'version'  => '0.001',
);

$dist->BuildTargets;

print $dist->dump(1);
