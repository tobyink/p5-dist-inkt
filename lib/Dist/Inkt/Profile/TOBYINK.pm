package Dist::Inkt::Profile::TOBYINK;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.015';

use Moose;

extends 'Dist::Inkt::Profile::Core';

with qw(
	Dist::Inkt::Role::CopyStandardDocuments
	Dist::Inkt::Role::ReadMetaDir
	Dist::Inkt::Role::ProcessDOAP
	Dist::Inkt::Role::ProcessDOAPDeps
	Dist::Inkt::Role::WriteDOAP
	Dist::Inkt::Role::WriteChanges
	Dist::Inkt::Role::WriteCOPYRIGHT
	Dist::Inkt::Role::WriteCREDITS
	Dist::Inkt::Role::WriteLICENSE
	Dist::Inkt::Role::WriteINSTALL
	Dist::Inkt::Role::SignDistribution
);

1;
