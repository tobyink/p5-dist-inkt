package Dist::Inkt::Role::WriteREADME;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moose::Role;
use Pod::Text;
use namespace::autoclean;

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'README';
};

sub Build_README
{
	my $self = shift;
	
	my $file = $self->targetfile('README');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	
	my $pod = 'Pod::Text'->new(
		sentance => 0,
		width    => 78,
		errors   => 'die',
		quotes   => q[``],
		utf8     => 1,
	);
	
	my $input = $self->lead_module;
	$input =~ s{::}{/}g;
	$input = $self->sourcefile("lib/$input.pm");
	
	$pod->parse_from_file("$input", "$file");
}

1;
