package Dist::Inkt::Role::SignDistribution;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use Moose::Role;
use Module::Signature ();
use File::chdir;
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'SIGNATURE';
};

sub Build_SIGNATURE
{
	my $self = shift;
	my $file = $self->targetfile('SIGNATURE');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	$file->spew('placeholder');
}

after BuildManifest => sub {
	my $self = shift;
	local $CWD = $self->targetdir;
	system("cpansign sign");
	if ($?) {
		$self->log("ERROR: signature failed!!!");
		die("Bailing out");
	}
};

1;
