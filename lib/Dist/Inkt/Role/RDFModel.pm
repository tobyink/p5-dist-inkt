package Dist::Inkt::Role::RDFModel;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moose::Role;
use Types::Standard -types;
use namespace::autoclean;

has model => (
	is       => 'ro',
	isa      => InstanceOf['RDF::Trine::Model'],
	lazy     => 1,
	builder  => '_build_model',
);

sub _build_model
{
	require RDF::Trine;
	return 'RDF::Trine::Model'->temporary_model;
}

1;
