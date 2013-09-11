package Dist::Inkt::Role::WriteLICENSE;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.010';

use Moose::Role;
use Software::LicenseUtils;
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'LICENSE';
};

sub Build_LICENSE
{
	my $self = shift;
	
	my $file = $self->targetfile('LICENSE');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	
	my $L = $self->metadata->{license};
	unless (@{ $L || [] }==1)
	{
		$self->log('WARNING: did not find exactly one licence; found %d', scalar(@{ $L || [] }));
		return;
	}
	
	my ($class) = 'Software::LicenseUtils'->guess_license_from_meta("license: '$L->[0]'\n");
	unless ($class)
	{
		$self->log("WARNING: could not grok licence '%s'", @$L);
		return;
	}
	
	eval "require $class;";
	my $licence = $class->new({
		year   => [localtime]->[5] + 1900,
		holder => Moose::Util::english_list(
			sort map $_->to_string('compact'), $self->doap_project->gather_all_maintainers
		),
	});
	
	$file->spew_utf8( $licence->fulltext );
}

1;
