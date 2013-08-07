package Dist::Inkt::Role::WriteMetaJSON;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose::Role;
use namespace::autoclean;

after BUILD => sub {
	my $self = shift;
	push @{ $self->targets }, 'MetaJSON';
};

sub Build_MetaJSON
{
	my $self = shift;
	my $file = $self->targetfile('META.json');
	$self->metadata->save($file, { version => '2' });
	$self->log('Writing %s', $file);
}

1;
