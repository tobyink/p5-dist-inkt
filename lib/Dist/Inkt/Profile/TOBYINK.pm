package Dist::Inkt::Profile::TOBYINK;

use Moose;

extends 'Dist::Inkt';

with qw(
	Dist::Inkt::Role::ReadMetaDir
	Dist::Inkt::Role::ProcessDOAP
	Dist::Inkt::Role::WriteMetaJSON
	Dist::Inkt::Role::WriteMetaYML
	Dist::Inkt::Role::WriteMetaTTL
	Dist::Inkt::Role::WriteChanges
);

1;
