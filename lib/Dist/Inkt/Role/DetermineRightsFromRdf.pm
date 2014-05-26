package Dist::Inkt::Role::DetermineRightsFromRdf;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.015';

use Moose::Role;
use RDF::Trine qw( iri literal statement variable );
use List::MoreUtils qw( uniq );
use Path::Tiny qw( path );
use Path::Iterator::Rule;
use Software::License;
use Software::LicenseUtils;
use Types::Standard -types;
use namespace::autoclean;

use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
my $CPAN = RDF::Trine::Namespace->new('http://purl.org/NET/cpan-uri/terms#');
my $DC   = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');
my $DOAP = RDF::Trine::Namespace->new('http://usefulinc.com/ns/doap#');
my $FOAF = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
my $NFO  = RDF::Trine::Namespace->new('http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#');
my $SKOS = RDF::Trine::Namespace->new('http://www.w3.org/2004/02/skos/core#');

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

1;
