package Dist::Inkt;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose;
use Types::Standard -types;
use Types::Path::Tiny -types;
use namespace::autoclean;

with qw(
	Dist::Inkt::Role::ReadMetaDir
	Dist::Inkt::Role::ProcessDOAP
	Dist::Inkt::Role::WriteMetaJSON
	Dist::Inkt::Role::WriteMetaYML
	Dist::Inkt::Role::WriteMetaTTL
	Dist::Inkt::Role::WriteChanges
);

has name => (
	is       => 'ro',
	isa      => Str,
	required => 1,
);

has version => (
	is       => 'ro',
	isa      => Str,
	required => 1,
);

has rootdir => (
	is       => 'ro',
	isa      => AbsDir,
	required => 1,
	coerce   => 1,
	handles  => {
		sourcefile => 'child',
	},
);

has targetdir => (
	is       => 'ro',
	isa      => AbsDir,
	lazy     => 1,
	coerce   => 1,
	builder  => '_build_targetdir',
	handles  => {
		targetfile => 'child',
	},
);

sub _build_targetdir
{
	my $self = shift;
	my $name = sprintf('%s-%s', $self->name, $self->version);
	
	my $dir = $self->rootdir->child($name);
	$dir->mkpath;
	return $dir;
}

has model => (
	is       => 'ro',
	isa      => InstanceOf['RDF::Trine::Model'],
	lazy     => 1,
	builder  => '_build_model',
);

sub _build_model
{
	require RDF::Trine;
	return 'RDF::Trine::Model'->temporary_model;
}

has metadata => (
	is       => 'ro',
	isa      => InstanceOf['CPAN::Meta'],
	lazy     => 1,
	builder  => '_build_metadata',
);

sub _build_metadata
{
	require CPAN::Meta;
	my $self = shift;
	return 'CPAN::Meta'->new({
		name     => $self->name,
		version  => $self->version,
		no_index => { directory => [qw/ inc t xt /] },
	});
}

has project_uri => (
	is       => 'ro',
	isa      => Str,
	lazy     => 1,
	builder  => '_build_project_uri',
);

sub _build_project_uri
{
	my $self = shift;
	sprintf('http://purl.org/NET/cpan-uri/dist/%s/project', $self->name);
}

has targets => (
	is       => 'ro',
	isa      => ArrayRef[Str],
	default  => sub { [] },
);

sub BUILD
{
	my $self = shift;
	$self->PopulateModel;
	$self->PopulateMetadata;
}

sub PopulateModel {}
sub PopulateMetadata {}

sub BuildTargets
{
	my $self = shift;
	
	for my $target (@{ $self->targets })
	{
		my $method = "Build_$target";
		$self->$method;
	}
}

sub log
{
	my $self = shift;
	my ($fmt, @args) = @_;
	printf STDERR "$fmt\n", @args;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Inkt - yet another distribution builder

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Dist-Inkt>.

=head1 SEE ALSO

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

