package Dist::Inkt::Role::WriteMetaYML;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose::Role;
use namespace::autoclean;

after BUILD => sub {
	my $self = shift;
	push @{ $self->targets }, 'MetaYML';
};

sub Build_MetaYML
{
	my $self = shift;
	my $file = $self->targetfile('META.yml');
	$self->log('Writing %s', $file);
	$self->metadata->save($file, { version => '1.4' });
}

1;
