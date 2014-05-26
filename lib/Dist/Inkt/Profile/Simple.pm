package Dist::Inkt::Profile::Simple;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.016';

use Moose;

extends 'Dist::Inkt';

with qw(
	Dist::Inkt::Role::CPANfile
	Dist::Inkt::Role::CopyStandardDocuments
	Dist::Inkt::Role::CopyFiles
	Dist::Inkt::Role::MetaProvides
	Dist::Inkt::Role::MetaProvidesScripts
	Dist::Inkt::Role::WriteMakefilePL
	Dist::Inkt::Role::WriteMetaJSON
	Dist::Inkt::Role::WriteMetaYML
	Dist::Inkt::Role::WriteDOAPLite
	Dist::Inkt::Role::WriteLICENSE
	Dist::Inkt::Role::WriteREADME
	Dist::Inkt::Role::WriteINSTALL
);

1;
