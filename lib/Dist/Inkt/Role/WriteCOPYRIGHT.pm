package Dist::Inkt::Role::WriteCOPYRIGHT;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose::Role;
use List::MoreUtils qw( uniq );
use Path::Tiny qw( path );
use Path::Iterator::Rule;
use RDF::Trine qw( iri literal statement variable );
use Software::License;
use Software::LicenseUtils;
use Types::Standard -types;
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
my $CPAN = RDF::Trine::Namespace->new('http://purl.org/NET/cpan-uri/terms#');
my $DC   = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');
my $DOAP = RDF::Trine::Namespace->new('http://usefulinc.com/ns/doap#');
my $FOAF = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
my $NFO  = RDF::Trine::Namespace->new('http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#');
my $SKOS = RDF::Trine::Namespace->new('http://www.w3.org/2004/02/skos/core#');

use constant FORMAT_URI => 'http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/';

use MooX::Struct -rw,
	CopyrightFile => [
		qw/ $header @files @license /,
		to_string => \&_serialize_file,
	],
	HeaderSection => [
		qw/ $format $upstream_name $upstream_contact $source /,
		to_string => \&_serialize_stanza,
	],
	FilesSection => [
		qw/ @files $copyright $license $comment /,
		to_string => \&_serialize_stanza,
	],
	LicenseSection => [
		qw/ $license $body /,
		to_string => \&_serialize_stanza,
	],
;

my %DEB = qw(
	Software::License::Apache_1_1     Apache-1.1
	Software::License::Apache_2_0     Apache-2.0
	Software::License::Artistic_1_0   Artistic-1.0
	Software::License::Artistic_2_0   Artistic-2.0
	Software::License::BSD            BSD-3-clause
	Software::License::CC0_1_0        CC0
	Software::License::GFDL_1_2       GFDL-1.2
	Software::License::GFDL_1_3       GFDL-1.3
	Software::License::GPL_1          GPL-1.0
	Software::License::GPL_2          GPL-2.0
	Software::License::GPL_3          GPL-3.0
	Software::License::LGPL_2_1       LGPL-2.1
	Software::License::LGPL_3_0       GPL-3.0
	Software::License::MIT            Expat
	Software::License::Mozilla_1_0    MPL-1.0
	Software::License::Mozilla_1_1    MPL-1.1
	Software::License::QPL_1_0        QPL-1.0
	Software::License::Zlib           Zlib
);

my %URIS = (
	'http://www.gnu.org/licenses/agpl-3.0.txt'              => 'AGPL_3',
	'http://www.apache.org/licenses/LICENSE-1.1'            => 'Apache_1_1',
	'http://www.apache.org/licenses/LICENSE-2.0'            => 'Apache_2_0',
	'http://www.apache.org/licenses/LICENSE-2.0.txt'        => 'Apache_2_0',
	'http://www.perlfoundation.org/artistic_license_1_0'    => 'Artistic_1_0',
	'http://opensource.org/licenses/artistic-license.php'   => 'Artistic_1_0',
	'http://www.perlfoundation.org/artistic_license_2_0'    => 'Artistic_2_0',
	'http://opensource.org/licenses/artistic-license-2.0.php'  => 'Artistic_2_0',
	'http://www.opensource.org/licenses/bsd-license.php'    => 'BSD',
	'http://creativecommons.org/publicdomain/zero/1.0/'     => 'CC0_1_0',
	'http://www.freebsd.org/copyright/freebsd-license.html' => 'FreeBSD',
	'http://www.gnu.org/copyleft/fdl.html'                  => 'GFDL_1_3',
	'http://www.opensource.org/licenses/gpl-license.php'    => 'GPL_1',
	'http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt'  => 'GPL_1',
	'http://www.opensource.org/licenses/gpl-2.0.php'        => 'GPL_2',
	'http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt'  => 'GPL_2',
	'http://www.opensource.org/licenses/gpl-3.0.html'       => 'GPL_3',
	'http://www.gnu.org/licenses/gpl-3.0.txt'               => 'GPL_3',
	'http://www.opensource.org/licenses/lgpl-2.1.php'       => 'LGPL_2_1',
	'http://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt' => 'LGPL_2_1',
	'http://www.opensource.org/licenses/lgpl-3.0.html'      => 'LGPL_3_0',
	'http://www.gnu.org/licenses/lgpl-3.0.txt'              => 'LGPL_3_0',
	'http://www.opensource.org/licenses/mit-license.php'    => 'MIT',
	'http://www.mozilla.org/MPL/MPL-1.0.txt'                => 'Mozilla_1_0',
	'http://www.mozilla.org/MPL/MPL-1.1.txt'                => 'Mozilla_1_1',
	'http://opensource.org/licenses/mozilla1.1.php'         => 'Mozilla_1_1',
	'http://www.openssl.org/source/license.html'            => 'OpenSSL',
	'http://dev.perl.org/licenses/'                         => 'Perl_5',
	'http://www.opensource.org/licenses/postgresql'         => 'PostgreSQL',
	'http://trolltech.com/products/qt/licenses/licensing/qpl'  => 'QPL_1_0',
	'http://h71000.www7.hp.com/doc/83final/BA554_90007/apcs02.html'  => 'SSLeay',
	'http://www.openoffice.org/licenses/sissl_license.html' => 'Sun',
	'http://www.zlib.net/zlib_license.html'                 => 'Zlib',
);
eval("require Software::License::$_") for uniq values %URIS;

has debian_copyright => (
	is       => 'ro',
	isa      => InstanceOf[CopyrightFile],
	lazy     => 1,
	builder  => '_build_debian_copyright',
);

our @Licences;
sub _build_debian_copyright
{
	my $self = shift;
	
	my @files = uniq('COPYRIGHT', sort $self->_get_dist_files);
	
	my $c = CopyrightFile->new(
		files   => [],
		license => [],
	);
	
	$c->header(
		HeaderSection->new(
			format           => FORMAT_URI,
			upstream_name    => $self->name,
			upstream_contact => $self->metadata->{author}[0],   # XXX
			source           => $self->metadata->{resources}{homepage},
		),
	);
	
	local @Licences = ();
	local $; = "\034";
	my %group_by;
	for my $f (@files)
	{
		my ($file, $copyright, $licence, $comment) = $self->_handle_file($f);
		push @{ $group_by{$copyright, $licence, (defined $comment ? $comment : '')} }, $file;
	}
	
	push @{ $c->files },
		map {
			my $key = $_;
			my ($copyright, $licence, $comment) = split /\Q$;/;
			FilesSection->new(
				files     => $group_by{$key},
				copyright => $copyright,
				license   => $licence,
				(comment  => $comment)x(defined $comment),
			);
		}
		sort {
			scalar(@{$group_by{$b}}) <=> scalar(@{$group_by{$a}})
		}
		keys %group_by;
	
	my %seen;
	for my $licence (@Licences) {
		next if $seen{ref $licence}++;
		
		my $licence_name;
		if ((ref($licence) || '') =~ /^Software::License::(.+)/) {
			push @Licences, $licence;
			$licence_name = $DEB{ ref $licence } || $1;
		}
		else {
			$licence_name = "$licence";
		}
		
		chomp( my $licence_text = $licence->notice );
		push @{ $c->license }, LicenseSection->new(
			license   => $licence_name,
			body      => $licence_text,
		);
	}
	
	$c;
}

sub _get_dist_files
{
	my $self = shift;
	my $rule = 'Path::Iterator::Rule'->new->file;
	my $dir  = $self->targetdir;
	map { path($_)->relative($dir) } $rule->all($dir);
}

sub _handle_file
{
	my ($self, $f) = @_;
	my ($copyright, $licence, $comment) = $self->_determine_rights($f);
	return ($f, 'Unknown', 'Unknown') unless $copyright;
	
	my $licence_name;
	if ((ref($licence) || '') eq "Software::License::Perl_5") {
		push @Licences => (
			"Software::License::Artistic_1_0"->new({holder => "the copyright holder(s)"}),
			"Software::License::GPL_1"->new({holder => "the copyright holder(s)"}),
		);
		$licence_name = "GPL-1.0+ or Artistic-1.0";
	}
	elsif ((ref($licence) || '') =~ /^Software::License::(.+)/) {
		push @Licences, $licence;
		$licence_name = $DEB{ ref $licence } || $1;
	}
	else {
		$licence_name = "$licence";
	}
	
	return ($f, $copyright, $licence_name, $comment);
}

sub _determine_rights
{
	my ($self, $f) = @_;
	
	if (my @rights = $self->_determine_rights_from_rdf($f))
	{
		return @rights;
	}
	
	if (my @rights = $self->_determine_rights_from_pod($f))
	{
		return @rights;
	}
	
	if (my @rights = $self->_determine_rights_by_convention($f))
	{
		return @rights;
	}
	
	return;
}

sub _determine_rights_from_rdf
{
	my ($self, $f) = @_;
	unless ($self->{_rdf_copyright_data})
	{
		my $model = $self->model;
		my $iter  = $model->get_pattern(
			RDF::Trine::Pattern->new(
				statement(variable('subject'), $NFO->fileName, variable('filename')),
				statement(variable('subject'), $DC->license, variable('license')),
				statement(variable('subject'), $DC->rightsHolder, variable('rights_holder')),
				statement(variable('rights_holder'), $FOAF->name, variable('name')),
			),
		);
		my %results;
		while (my $row = $iter->next) {
			my $l = $row->{license}->uri;
			$row->{class} = literal("Software::License::$URIS{$l}")
				if exists $URIS{$l};
			$results{ $row->{filename}->literal_value } = $row;
		}
		$self->{_rdf_copyright_data} = \%results;
	}
	
	if ( my $row = $self->{_rdf_copyright_data}{$f} ) {
		return (
			sprintf("Copyright %d %s.", 1900 + (localtime((stat $f)[9]))[5], $row->{name}->literal_value),
			$row->{class}->literal_value->new({holder => "the copyright holder(s)"}),
		) if $row->{class};
	}
	
	return;
}

sub _determine_rights_from_pod
{
	my ($self, $f) = @_;
	return unless $f =~ /\.(?:pl|pm|pod|t)$/i;
	
	# For files in 'inc' try to figure out the normal (not stripped of pod)
	# module.
	#
	$f = $INC{$1} if $f =~ m{^inc/(.+\.pm)$}i && exists $INC{$1};
	
	my $text = path($f)->absolute($self->targetdir)->slurp;
	
	my @guesses = 'Software::LicenseUtils'->guess_license_from_pod($text);
	if (@guesses) {
		my $copyright =
			join qq[\n],
			map  { s/\s+$//; /[.?!]$/ ? $_ : "$_." }
			grep { /^Copyright/i or /^This software is copyright/ }
			split /(?:\r?\n|\r)/, $text;
		
		$copyright =~ s{E<lt>}{<}g;
		$copyright =~ s{E<gt>}{>}g;
		
		return(
			$copyright,
			$guesses[0]->new({holder => 'the copyright holder(s)'}),
		) if $copyright && $guesses[0];
	}
	
	return;
}

sub _determine_rights_by_convention
{
	my ($self, $f) = @_;
	
	if ($f =~ /^COPYRIGHT$/)
	{
		return(
			'None',
			'public-domain',
			'This file! Automatically generated.',
		);
	}
	
	if ($f =~ m{ inc/Module/Install/(
		Admin | Admin/Include | Base | Bundle | Can | Compiler | Deprecated |
		External | Makefile | PAR | Share | DSL | Admin/Bundle |
		Admin/Compiler | Admin/Find | Admin/Makefile | Admin/Manifest |
		Admin/Metadata | Admin/ScanDeps | Admin/WriteAll | AutoInstall |
		Base/FakeAdmin | Fetch | Include | Inline | MakeMaker | Metadata |
		Run | Scripts | Win32 | With | WriteAll
	).pm }x or $f eq 'inc/Module/Install.pm')
	{
		return(
			'Copyright 2002 - 2012 Brian Ingerson, Audrey Tang and Adam Kennedy.',
			"Software::License::Perl_5"->new({ holder => 'the copyright holder(s)' }),
		);
	}
	
	if ($f eq 'inc/Module/Install/Package.pm')
	{
		return(
			'Copyright (c) 2011. Ingy doet Net.',
			"Software::License::Perl_5"->new({ holder => 'the copyright holder(s)' }),
		);
	}

	if ($f eq 'inc/Module/Package/Dist/RDF.pm')
	{
		return(
			'This software is copyright (c) 2011-2012 by Toby Inkster.',
			"Software::License::Perl_5"->new({ holder => 'the copyright holder(s)' }),
		);
	}

	if ($f eq 'inc/unicore/Name.pm' or $f eq 'inc/utf8.pm')
	{
		return(
			'1993-2012, Larry Wall and others',
			"Software::License::Perl_5"->new({ holder => 'the copyright holder(s)' }),
		);
	}

	return;
}

after BUILD => sub {
	my $self = shift;
	push @{ $self->targets }, 'COPYRIGHT'; # push rather than shift
};

sub Build_COPYRIGHT
{
	my $self = shift;
	my $file = $self->targetfile('COPYRIGHT');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	
	$file->spew_utf8( $self->debian_copyright->to_string );
}

sub _serialize_file
{
	my $self = shift;
	return join "\n",
		map $_->to_string,
		(
			$self->header,
			@{ $self->files },
			@{ $self->license },
		);
}

sub _serialize_stanza
{
	my $self = shift;
	my $str;
	for my $f ($self->FIELDS)
	{
		my $F = join "-", map ucfirst, split "_", $f;
		my $v = $self->$f;
		if ($f eq 'body') {
			$v =~ s{^}" "mg;
			$str .= "$v\n";
		}
		elsif (ref $v eq "ARRAY") {
			$v = join "\n " => @$v;
			$str .= "$F: $v\n";
		}
		elsif (defined $v and length $v) {
			$v =~ s{^}" "mg;
			$str .= "$F:$v\n";
		}
	}
	return $str;
}

1;