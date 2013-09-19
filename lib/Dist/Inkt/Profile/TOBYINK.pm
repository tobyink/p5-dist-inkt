package Dist::Inkt::Profile::TOBYINK;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

use Moose;

extends 'Dist::Inkt';

with qw(
	Dist::Inkt::Role::ReadMetaDir
	Dist::Inkt::Role::ProcessDOAP
	Dist::Inkt::Role::ProcessDOAPDeps
	Dist::Inkt::Role::CopyStandardDocuments
	Dist::Inkt::Role::CopyFiles
	Dist::Inkt::Role::MetaProvides
	Dist::Inkt::Role::MetaProvidesScripts
	Dist::Inkt::Role::WriteMakefilePL
	Dist::Inkt::Role::WriteMetaJSON
	Dist::Inkt::Role::WriteMetaYML
	Dist::Inkt::Role::WriteDOAP
	Dist::Inkt::Role::WriteChanges
	Dist::Inkt::Role::WriteCOPYRIGHT
	Dist::Inkt::Role::WriteCREDITS
	Dist::Inkt::Role::WriteLICENSE
	Dist::Inkt::Role::WriteREADME
	Dist::Inkt::Role::WriteINSTALL
	Dist::Inkt::Role::SignDistribution
);

1;
