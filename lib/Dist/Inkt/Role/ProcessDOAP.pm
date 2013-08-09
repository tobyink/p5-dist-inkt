package Dist::Inkt::Role::ProcessDOAP;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose::Role;
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
my $CPAN = RDF::Trine::Namespace->new('http://purl.org/NET/cpan-uri/terms#');
my $DC   = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');
my $DOAP = RDF::Trine::Namespace->new('http://usefulinc.com/ns/doap#');
my $DEPS = RDF::Trine::Namespace->new('http://ontologi.es/doap-deps#');
my $FOAF = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
my $NFO  = RDF::Trine::Namespace->new('http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#');
my $SKOS = RDF::Trine::Namespace->new('http://www.w3.org/2004/02/skos/core#');

after PopulateMetadata => sub
{
	my $self = shift;
	
	$self->log('Processing the DOAP vocabulary');
	
	my $meta  = $self->metadata;
	
	$meta->{abstract}    = $_ for $self->doap_shortdesc;
	$meta->{description} = $_ for $self->doap_description;
	
	push @{ $meta->{license} }, $self->doap_license;
	
	my $r = $self->doap_resources;
	$meta->{resources}{$_} ||= $r->{$_} for keys %$r;
	
	push @{ $meta->{keywords} }, $self->doap_category;
};

sub doap_shortdesc
{
	shift->_doap_single_literal($DOAP->shortdesc, $DC->abstract);
}

sub doap_description
{
	shift->_doap_single_literal($DOAP->description, $DC->description);
}

sub _doap_single_literal
{
	my $self = shift;
	my $model = $self->model;
	my $uri   = 'RDF::Trine::Node::Resource'->new($self->project_uri);
	
	for ($model->objects_for_predicate_list($uri, @_))
	{
		return $_->literal_value if $_->is_literal;
	}
	
	return;
}

sub doap_license
{
	my $self = shift;
	my $model = $self->model;
	my $uri   = 'RDF::Trine::Node::Resource'->new($self->project_uri);

	my @r;
	for ($model->objects_for_predicate_list($uri, $DOAP->license, $DC->license))
	{
		next unless $_->is_resource;
		
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
	
	return @r;
}

sub doap_resources
{
	my $self = shift;
	my $model = $self->model;
	my $uri   = 'RDF::Trine::Node::Resource'->new($self->project_uri);

	my %resources;
	
	$resources{license} = [
		map  { $_->uri }
		grep { $_->is_resource }
		$model->objects_for_predicate_list($uri, $DOAP->license, $DC->license)
	];
	
	($resources{homepage}) =
		map  { $_->uri }
		grep { $_->is_resource }
		$model->objects_for_predicate_list($uri, $DOAP->homepage, $FOAF->homepage, $FOAF->page);
	
	my (@bug) =
		map  { $_->uri }
		grep { $_->is_resource }
		$model->objects($uri, $DOAP->uri('bug-database'));
	for (@bug) {
		if (/^mailto:(.+)/i) {
			$resources{bugtracker}{mailto} ||= $1;
		}
		else {
			$resources{bugtracker}{web} ||= $_;
		}
	}
	
	REPO: foreach my $repo ($model->objects($uri, $DOAP->repository))
	{
		next REPO if $repo->is_literal;
		
		my ($browse) =
			map  { $_->uri }
			grep { $_->is_resource }
			$model->objects_for_predicate_list($repo, $DOAP->uri('browse'));
		my ($location) =
			map  { $_->uri }
			grep { $_->is_resource }
			$model->objects_for_predicate_list($repo, $DOAP->uri('location'));
		my ($type) =
			map  { $_->uri }
			grep { $_->is_resource }
			$model->objects_for_predicate_list($repo, $RDF->uri('type'));
		
		if ($location || $browse)
		{
			my $repo = {};
			$repo->{url}  = $location if $location;
			$repo->{web}  = $browse if $browse;
			$repo->{type} = lc($1) if "$type" =~ m{(\w+)Repository$};
			$resources{repository} = $repo;
			last REPO;
		}
	}
	
	($resources{X_mailinglist}) =
		map  { $_->uri }
		grep { $_->is_resource }
		$model->objects($uri, $DOAP->uri('mailing-list'));
	
	($resources{X_wiki}) =
		map  { $_->uri }
		grep { $_->is_resource }
		$model->objects($uri, $DOAP->uri('wiki'));
	
	delete $resources{$_} for grep !defined $resources{$_}, keys %resources;
	
	return \%resources;
}

sub doap_category
{
	my $self = shift;
	my $model = $self->model;
	my $uri   = 'RDF::Trine::Node::Resource'->new($self->project_uri);
	
	my %keywords;
	CATEGORY: foreach my $cat ($model->objects_for_predicate_list($uri, $DOAP->category, $DC->subject))
	{
		if ($cat->is_literal)
		{
			$keywords{ uc $cat->literal_value } = $cat->literal_value;
		}
		else
		{
			LABEL: foreach my $label ($model->objects_for_predicate_list($cat, $SKOS->prefLabel, $RDFS->label, $DOAP->name, $FOAF->name))
			{
				next LABEL unless $label->is_literal;
				$keywords{ uc $label->literal_value } = $label->literal_value;
				next CATEGORY;
			}
		}
	}
	
	sort values %keywords;
}

1;
