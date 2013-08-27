package Dist::Inkt::Role::ProcessDOAPDeps;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007';

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
	
	$self->log('Processing the DOAP Deps vocabulary');
	
	$self->cpanterms_deps;
	$self->doap_deps;
};


sub cpanterms_deps
{
	my $self = shift;
	
	my $meta  = $self->metadata;
	my $model = $self->model;
	my $uri   = 'RDF::Trine::Node::Resource'->new($self->project_uri);
	
	my @terms = qw(requires build_requires configure_requires test_requires recommends);
	my %term_map = (
		requires           => [ 'runtime',   'requires' ],
		build_requires     => [ 'build',     'requires' ],
		configure_requires => [ 'configure', 'requires' ],
		test_requires      => [ 'test',      'requires' ],
		recommends         => [ 'runtime',   'recommends' ],
	);
	foreach my $term (@terms)
	{
		my ($phase, $level) = @{$term_map{$term}};
		foreach my $dep ($model->objects($uri, $CPAN->$term))
		{
			$self->log("WARNING: $term is deprecated in favour of http://ontologi.es/doap-deps#");
			if ($dep->is_literal)
			{
				my ($mod, $ver) = split /\s+/, $dep->literal_value;
				$ver ||= 0;
				no warnings;
				$meta->{prereqs}{$phase}{$level}{$mod} = $ver
					unless $meta->{prereqs}{$phase}{$level}{$mod} > $ver;
			}
			else
			{
				$self->log("WARNING: Dunno what to do with ${dep}... we'll figure something out eventually.");
			}
		}
	}
}

sub doap_deps
{
	my $self = shift;
	
	my $meta  = $self->metadata;
	my $model = $self->model;
	my $uri   = 'RDF::Trine::Node::Resource'->new($self->project_uri);
	
	foreach my $phase (qw/ configure build test runtime develop /)
	{
		foreach my $level (qw/ requirement recommendation suggestion conflict /)
		{
			my $term = "${phase}-${level}";
			my $level2 = {
				requirement    => 'requires',
				recommendation => 'recommends',
				suggestion     => 'suggests',
				conflict       => 'conflicts',
			}->{$level};
			
			foreach my $dep ( $model->objects($uri, $DEPS->uri($term)) )
			{
				if ($dep->is_literal)
				{
					$self->log("WARNING: ". $DEPS->$term . " expects a resource, not literal $dep!");
					next;
				}
				
				foreach my $ident ( $model->objects($dep, $DEPS->on) )
				{
					unless ($ident->is_literal
					and     $ident->has_datatype
					and     $ident->literal_datatype eq $DEPS->CpanId->uri)
					{
						$self->log("WARNING: Dunno what to do with ${ident}... we'll figure something out eventually.");
						next;
					}
					
					my ($mod, $ver) = split /\s+/, $ident->literal_value;
					$ver ||= 0;
					no warnings;
					$meta->{prereqs}{$phase}{$level2}{$mod} = $ver
						unless $meta->{prereqs}{$phase}{$level2}{$mod} > $ver;
				}
			}
		}
	}
}

1;
