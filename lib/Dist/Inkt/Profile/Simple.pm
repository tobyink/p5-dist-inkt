package Dist::Inkt::Profile::Simple;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.015';

use Moose;

extends 'Dist::Inkt';

with qw(
	Dist::Inkt::Role::CopyFiles
	Dist::Inkt::Role::MetaProvides
	Dist::Inkt::Role::MetaProvidesScripts
	Dist::Inkt::Role::WriteMakefilePL
	Dist::Inkt::Role::WriteMetaJSON
	Dist::Inkt::Role::WriteMetaYML
	Dist::Inkt::Role::WriteREADME
);

1;
