package Dist::Inkt::Role::ProcessDOAP;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007';

use Moose::Role;
use List::MoreUtils 'uniq';
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
my $CPAN = 'RDF::Trine::Namespace'->new('http://purl.org/NET/cpan-uri/terms#');
my $DC   = 'RDF::Trine::Namespace'->new('http://purl.org/dc/terms/');
my $DOAP = 'RDF::Trine::Namespace'->new('http://usefulinc.com/ns/doap#');
my $DEPS = 'RDF::Trine::Namespace'->new('http://ontologi.es/doap-deps#');
my $FOAF = 'RDF::Trine::Namespace'->new('http://xmlns.com/foaf/0.1/');
my $NFO  = 'RDF::Trine::Namespace'->new('http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#');
my $SKOS = 'RDF::Trine::Namespace'->new('http://www.w3.org/2004/02/skos/core#');

after PopulateMetadata => sub
{
	my $self = shift;
	
	$self->log('Processing the DOAP vocabulary');
	
	my $meta = $self->metadata;
	
	delete $meta->{abstract} if $meta->{abstract} eq 'unknown';
	$meta->{abstract} ||= $_
		for grep defined, $self->doap_project->shortdesc;
		
	$meta->{description} ||= $_
		for grep defined, $self->doap_project->description;
	
	push @{ $meta->{license} }, $self->cpanmeta_license_code;
	
	my $r = $self->cpanmeta_resources;
	$meta->{resources}{$_} ||= $r->{$_} for keys %$r;
	
	push @{ $meta->{keywords} }, $self->cpanmeta_keywords;
	
	for my $role ($self->model->objects(RDF::Trine::iri($self->project_uri), $CPAN->x_help_wanted))
	{
		next unless $role->uri =~ /(\w+)\z/;
		push @{ $meta->{x_help_wanted} ||= [] }, $1;
	}
};

sub cpanmeta_license_code
{
	my $self = shift;

	my @r;
	for (@{ $self->doap_project->license })
	{
		my $license_code = {
			'http://www.gnu.org/licenses/agpl-3.0.txt'              => 'open_source',
			'http://www.apache.org/licenses/LICENSE-1.1'            => 'apache_1_1',
			'http://www.apache.org/licenses/LICENSE-2.0'            => 'apache',
			'http://www.apache.org/licenses/LICENSE-2.0.txt'        => 'apache',
			'http://www.perlfoundation.org/artistic_license_1_0'    => 'artistic',
			'http://opensource.org/licenses/artistic-license.php'   => 'artistic',
			'http://www.perlfoundation.org/artistic_license_2_0'    => 'artistic_2',
			'http://opensource.org/licenses/artistic-license-2.0.php'  => 'artistic_2',
			'http://www.opensource.org/licenses/bsd-license.php'    => 'bsd',
			'http://creativecommons.org/publicdomain/zero/1.0/'     => 'unrestricted',
			'http://www.freebsd.org/copyright/freebsd-license.html' => 'open_source',
			'http://www.gnu.org/copyleft/fdl.html'                  => 'open_source',
			'http://www.opensource.org/licenses/gpl-license.php'    => 'gpl',
			'http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt'  => 'gpl',
			'http://www.opensource.org/licenses/gpl-2.0.php'        => 'gpl2',
			'http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt'  => 'gpl2',
			'http://www.opensource.org/licenses/gpl-3.0.html'       => 'gpl3',
			'http://www.gnu.org/licenses/gpl-3.0.txt'               => 'gpl3',
			'http://www.opensource.org/licenses/lgpl-license.php'   => 'lgpl',
			'http://www.opensource.org/licenses/lgpl-2.1.php'       => 'lgpl2',
			'http://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt' => 'lgpl2',
			'http://www.opensource.org/licenses/lgpl-3.0.html'      => 'lgpl3',
			'http://www.gnu.org/licenses/lgpl-3.0.txt'              => 'lgpl3',
			'http://www.opensource.org/licenses/mit-license.php'    => 'mit',
			'http://www.mozilla.org/MPL/MPL-1.0.txt'                => 'mozilla',
			'http://www.mozilla.org/MPL/MPL-1.1.txt'                => 'mozilla',
			'http://opensource.org/licenses/mozilla1.1.php'         => 'mozilla',
			'http://www.openssl.org/source/license.html'            => 'open_source',
			'http://dev.perl.org/licenses/'                         => 'perl',
			'http://www.opensource.org/licenses/postgresql'         => 'open_source',
			'http://trolltech.com/products/qt/licenses/licensing/qpl'  => 'open_source',
			'http://h71000.www7.hp.com/doc/83final/BA554_90007/apcs02.html'  => 'unrestricted',
			'http://www.openoffice.org/licenses/sissl_license.html' => 'open_source',
			'http://www.zlib.net/zlib_license.html'                 => 'open_source',
			}->{ $_->uri };

		push @r, $license_code if $license_code;
	}
	
	@r ? uniq(@r) : ('unknown');
}

sub cpanmeta_resources
{
	my $self = shift;

	my %resources;
	
	$resources{license}    = [ map $_->uri, @{ $self->doap_project->license } ];
	$resources{homepage} ||= $_->uri for @{ $self->doap_project->homepage };
	
	my (@bug) = map $_->uri, $self->doap_project->bug_database;
	for (@bug) {
		if (/^mailto:(.+)/i) {
			$resources{bugtracker}{mailto} ||= $1;
		}
		else {
			$resources{bugtracker}{web} ||= $_;
		}
	}
	
	REPO: for my $repo (@{$self->doap_project->repository})
	{
		if ($repo->location || $repo->browse)
		{
			my $r = {};
			$r->{url}  = $repo->location->uri if $repo->location;
			$r->{web}  = $repo->browse->uri   if $repo->browse;
			for my $type (@{ $repo->rdf_type || [] }) {
				$r->{type} ||= lc($1) if $type->uri =~ m{[/#](\w+)Repository$};
			}
			$resources{repository} = $r;
			last REPO;
		}
	}
	
	($resources{X_mailinglist}) =
		map  { $_->uri }
		grep defined,
		$self->doap_project->mailing_list;
	
	($resources{X_wiki}) =
		map  { $_->uri }
		grep defined,
		$self->doap_project->wiki;

	($resources{X_identifier}) =
		map  { $_->uri }
		grep defined,
		$self->doap_project->rdf_about;

	delete $resources{$_} for grep !defined $resources{$_}, keys %resources;
	
	return \%resources;
}

sub cpanmeta_keywords
{
	my $self = shift;
	my $model = $self->model;
	
	my %keywords;
	CATEGORY: for my $cat (@{ $self->doap_project->category || [] })
	{
		LABEL: for my $label ($model->objects_for_predicate_list($cat, $SKOS->prefLabel, $RDFS->label, $DOAP->name, $FOAF->name))
		{
			next LABEL unless $label->is_literal;
			$keywords{ uc $label->literal_value } = $label->literal_value;
			next CATEGORY;
		}
	}
	
	sort values %keywords;
}

1;
