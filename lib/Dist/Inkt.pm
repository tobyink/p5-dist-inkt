package Dist::Inkt;

use 5.010001;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.014';

use Moose;
use Module::Metadata;
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

has lead_module => (
	is       => 'ro',
	isa      => Str,
	lazy     => 1,
	builder  => '_build_lead_module',
);

sub _build_lead_module
{
	my $self = shift;
	(my $name = $self->name) =~ s/-/::/g;
	return $name;
}

has version => (
	is       => 'ro',
	isa      => Str,
	lazy     => 1,
	builder  => '_build_version',
);

sub _build_version
{
	my $self = shift;
	my $mm = 'Module::Metadata'->new_from_module(
		$self->lead_module,
		inc => [$self->sourcefile('lib')],
	);
	return $mm->{version}{original};
}

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
		targetfile  => 'child',
		cleartarget => 'remove_tree',
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
		no_index       => { directory => [qw/ eg examples inc t xt /] },
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
	
	$self->cleartarget;
	
	$self->Build_Files if $self->DOES('Dist::Inkt::Role::CopyFiles');
	
	for my $target (@{ $self->targets })
	{
		next if $self->DOES('Dist::Inkt::Role::CopyFiles') && $target eq 'Files';
		
		my $method = "Build_$target";
		$self->$method;
	}
}

sub BuildManifest
{
	my $self = shift;
	
	my $file = $self->targetfile('MANIFEST');
	$self->log("Writing $file");
	$self->rights_for_generated_files->{'MANIFEST'} ||= [
		'None', 'public-domain'
	] if $self->DOES('Dist::Inkt::Role::WriteCOPYRIGHT');
	
	my $rule = 'Path::Iterator::Rule'->new->file;
	my $root = $self->targetdir;
	my @files = map { path($_)->relative($root) } $rule->all($root);
	
	$file->spew(map "$_\n", sort 'MANIFEST', @files);
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
	$self->BuildTarball unless $ENV{PERL_DIST_INKT_NOTARBALL};
	$self->cleartarget unless $ENV{PERL_DIST_INKT_KEEPDIR};
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

=for stopwords gzipped tarball

=head1 NAME

Dist::Inkt - yet another distribution builder

=head1 STATUS

Experimental.

=head1 DESCRIPTION

L<Dist::Zilla> didn't have the prerequisite amount of crazy for me, so
I wrote this instead.

Dist::Inkt itself does virtually nothing; it creates an empty directory,
generates a MANIFEST file, and then wraps it all up into a gzipped
tarball. But it provides various hooks along the way for subclasses
to grab hold of. So the general idea is that you write a subclass of
Dist::Inkt, which consumes various Moose::Roles to do the actual work
of populating the distribution with files.

As such, Dist::Inkt is not so much a distribution builder, as it is a
framework for writing your own distribution builder.

Several roles of varying utility are bundled with Dist::Inkt, as is
L<Dist::Inkt::Profile::TOBYINK>, a subclass of Dist::Inkt which consumes
all of these roles.

=head1 COMPANIONS

Dist::Inkt does just one thing - building the tarball from some
checkout of the repo.

Although roles could theoretically be written for other tasks, out of
the box, Dist::Inkt doesn't do any of the following:

=over

=item B<< Minting new distributions >>

I'm writing a separate tool, L<Dist::Inktly::Minty> for that.

=item B<< Test suite running >>

Use L<App::Prove> or L<App::ForkProve>.

=item B<< CPAN Uploading >>

Use L<CPAN::Uploader>.

=item B<< Changing the version number across many files >>

Use L<Perl::Version>.

=item B<< Integration with version control tools >>

Just use C<hg> or C<svn> or C<git> of whatever as you normally would.
None of the files generated by Dist::Inkt should probably be checked
into your repo.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Dist-Inkt>.

=head1 SEE ALSO

If you are not me, then you may well want one of these instead:

=over

=item *

L<Dist::Zilla>

=item *

L<Dist::Milla>

=item *

L<Minilla>

=back

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

