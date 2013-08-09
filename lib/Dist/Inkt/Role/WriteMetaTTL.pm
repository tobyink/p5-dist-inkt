package Dist::Inkt::Role::WriteMetaTTL;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moose::Role;
use RDF::TrineX::Functions 'serialize';
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'MetaTTL';
};

sub Build_MetaTTL
{
	my $self = shift;
	my $file = $self->targetfile('META.ttl');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	
	my $serializer = eval {
		require RDF::TrineX::Serializer::MockTurtleSoup;
		'RDF::TrineX::Serializer::MockTurtleSoup'->new;
	} || 'RDF::Trine::Serializer::Turtle'->new;
	
	serialize(
		$self->model,
		to    => $file->openw,
		using => $serializer,
	);
}

1;
