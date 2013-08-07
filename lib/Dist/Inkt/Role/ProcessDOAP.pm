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
	
	my $model = $self->model;
	my $uri   = 'RDF::Trine::Node::Resource'->new($self->project_uri);
	my $meta  = $self->metadata;
	
	ABSTRACT: foreach ($model->objects_for_predicate_list($uri, $DOAP->shortdesc, $DC->abstract))
	{
		next ABSTRACT unless $_->is_literal;
		$meta->{abstract} = $_->literal_value;
		last ABSTRACT;
	}
	
	# DESCRIPTION
	
	# AUTHORS
	
	# KEYWORDS
	
	# LICENSES
	
	# RESOURCES
	
	# RELEASE_STATUS
};

1;
