package Dist::Inkt::Role::WriteCREDITS;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use Moose::Role;
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

after PopulateMetadata => sub {
	my $self = shift;
	my %maint   = map +($_ => 1), $self->doap_project->gather_all_maintainers;
	my @contrib = grep !$maint{$_}, $self->doap_project->gather_all_contributors;
	push @{ $self->metadata->{x_contributors} ||= [] }, map "$_", @contrib if @contrib;
};

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'CREDITS';
};

sub Build_CREDITS
{
	my $self = shift;
	my $file = $self->targetfile('CREDITS');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	
	my $fh = $file->openw_utf8;
	
	my %already;
	for my $role (qw/ maintainer contributor thanks /)
	{
		(my $method = "gather_all_${role}s") =~ s/ss$/s/s;
		my @peeps =
			sort { $a->to_string cmp $b->to_string }
			grep { not $already{$_}++ }
			$self->doap_project->$method;
		next unless @peeps;
		
		printf {$fh} ("%s:\n", ucfirst $role);
		printf {$fh} ("- %s\n", $_->to_string) for @peeps;
		printf {$fh} ("\n");
	}
	
	close($fh);
}

1;
