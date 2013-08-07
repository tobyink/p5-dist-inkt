package Dist::Inkt::Role::WriteMetaJSON;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose::Role;
use namespace::autoclean;

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'MetaJSON';
};

sub Build_MetaJSON
{
	my $self = shift;
	my $file = $self->targetfile('META.json');
	$self->log('Writing %s', $file);
	$self->metadata->save($file, { version => '2' });
}

1;
