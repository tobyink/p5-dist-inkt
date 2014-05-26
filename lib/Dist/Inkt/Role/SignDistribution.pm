package Dist::Inkt::Role::SignDistribution;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.017';

use Moose::Role;
use Module::Signature ();
use File::chdir;
use namespace::autoclean;

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
	$self->rights_for_generated_files->{'SIGNATURE'} ||= [
		'None', 'public-domain'
	];
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
