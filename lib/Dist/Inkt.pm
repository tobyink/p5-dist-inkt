package Dist::Inkt;

use 5.010001;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose;
use Types::Standard -types;
use Types::Path::Tiny -types;
use Path::Tiny 'path';
use Path::Iterator::Rule;
use namespace::autoclean;

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
	my $meta = 'CPAN::Meta'->new({
		name           => $self->name,
		version        => $self->version,
		no_index       => { directory => [qw/ inc t xt /] },
		generated_by   => sprintf('%s version %s', ref($self), $self->VERSION),
		dynamic_config => 0,
	});
	for (qw/ license author /) {
		$meta->{$_} = [] if @{$meta->{$_}}==1 && $meta->{$_}[0] eq 'unknown';
	}
	return $meta;	
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
	builder  => '_build_targets',
);

sub _build_targets
{
	return [];
}

sub BUILD
{
	my $self = shift;
	return if $self->{_already_built}++;
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

sub BuildManifest
{
	my $self = shift;
	
	my $file = $self->targetfile('MANIFEST');
	$self->log("Writing $file");
	
	my $rule = 'Path::Iterator::Rule'->new->file;
	my $root = $self->targetdir;
	my @files = map { path($_)->relative($root) } $rule->all($root);
	
	$file->spew(map "$_\n", sort @files);
}

sub BuildTarball
{
	my $self = shift;
	my $file = path($_[0] || sprintf('%s.tar.gz', $self->targetdir));
	$self->log("Writing $file");
	
	require Archive::Tar;
	my $tar = 'Archive::Tar'->new;
	
	my $rule = 'Path::Iterator::Rule'->new->file;
	my $root = $self->targetdir;
	my $pfx  = $root->basename;
	for ($rule->all($root))
	{
		my $abs = path($_);
		$tar->add_files($abs);
		$tar->rename(substr($abs, 1), "$pfx/".$abs->relative($root));
	}
	
	$tar->write($file, Archive::Tar::COMPRESS_GZIP());
}

sub BuildAll
{
	my $self = shift;
	$self->BuildTargets;
	$self->BuildManifest;
	$self->BuildTarball;
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

