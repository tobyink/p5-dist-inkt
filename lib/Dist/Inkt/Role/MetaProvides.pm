package Dist::Inkt::Role::MetaProvides;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use Moose::Role;
use Module::Metadata;
use namespace::autoclean;

after PopulateMetadata => sub
{
	my $self = shift;
	$self->log("Finding provided packages");
	
	# XXX - should filter result using manifest_skip
	my $provides = 'Module::Metadata'->provides(
		version  => '2',
		dir      => $self->sourcefile('lib'),
	);
	
	$self->metadata->{provides} = $provides;
};

1;
