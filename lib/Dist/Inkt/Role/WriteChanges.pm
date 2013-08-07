package Dist::Inkt::Role::WriteChanges;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose::Role;
use RDF::DOAP::ChangeSets;
use namespace::autoclean;

after BUILD => sub {
	my $self = shift;
	push @{ $self->targets }, 'Changes';
};

sub Build_Changes
{
	my $self = shift;
	my $file = $self->targetfile('Changes');
	
	my $ch = 'RDF::DOAP::ChangeSets'->new($self->project_uri, $self->model);
	$ch->to_file($file);
	
	$self->log('Writing %s', $file);
}

1;
