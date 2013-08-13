package Dist::Inkt::Role::WriteChanges;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use Moose::Role;
use RDF::DOAP::ChangeSets;
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'Changes';
};

sub Build_Changes
{
	my $self = shift;
	my $file = $self->targetfile('Changes');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	$file->spew_utf8($self->doap_project->changelog);
}

1;
