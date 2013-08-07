package Dist::Inkt::Role::WriteMetaTTL;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose::Role;
use RDF::TrineX::Functions 'serialize';
use namespace::autoclean;

after BUILD => sub {
	my $self = shift;
	push @{ $self->targets }, 'MetaTTL';
};

sub Build_MetaTTL
{
	my $self = shift;
	my $file = $self->targetfile('META.ttl');
	
	my $serializer = eval {
		require RDF::TrineX::Serializer::MockTurtleSoup;
		'RDF::TrineX::Serializer::MockTurtleSoup'->new;
	} || 'RDF::Trine::Serializer::Turtle'->new;
	
	serialize(
		$self->model,
		to    => $file->openw,
		using => $serializer,
	);
	
	$self->log('Writing %s', $file);
}

1;
