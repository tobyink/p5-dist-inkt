package Dist::Inkt::Role::WriteMakefilePL;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose::Role;
use Data::Dump 'pp';
use namespace::autoclean;

after PopulateMetadata => sub {
	my $self = shift;
	$self->metadata->{prereqs}{configure}{requires}{'ExtUtils::MakeMaker'} = '6.30'
		unless defined $self->metadata->{prereqs}{configure}{requires}{'ExtUtils::MakeMaker'};
};

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'MakefilePL';
};

sub Build_MakefilePL
{
	my $self = shift;
	my $file = $self->targetfile('Makefile.PL');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	
	chomp(
		my $dump = pp( $self->metadata->as_struct({version => '2'}) )
	);

	my $dynamic_config = do {
		my $dc = $self->sourcefile('meta/DYNAMIC_CONFIG.PL');
		$dc->exists ? $dc->slurp_utf8 : '';
	};
	
	my $makefile = do { local $/ = <DATA> };
	$makefile =~ s/%%%METADATA%%%/$dump/;
	$makefile =~ s/%%%DYNAMIC_CONFIG%%%/$dynamic_config/;
	$file->spew_utf8($makefile);
}

1;

__DATA__
use strict;
use ExtUtils::MakeMaker 6.30;

my $meta = %%%METADATA%%%;

my %dynamic_config;
DYNAMIC_CONFIG: do {%%%DYNAMIC_CONFIG%%%};

my %WriteMakefileArgs = (
	ABSTRACT           => $meta->{abstract},
	AUTHOR             => $meta->{author},
	DISTNAME           => $meta->{name},
	DISTVNAME          => sprintf('%s-%s', $meta->{name}, $meta->{version}),
	EXE_FILES          => [],  ### XXX - TODO
	LICENSE            => $meta->{license}[0],
	NAME               => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	VERSION            => $meta->{version},
	%dynamic_config,
);

sub deps
{
	my %r;
	for my $stage (@_)
	{
		for my $dep (keys %{$meta->{prereqs}{$stage}{requires}})
		{
			my $ver = $meta->{prereqs}{$stage}{requires}{$dep};
			$r{$dep} = $ver if !exists($r{$dep}) || $ver >= $r{$dep};
		}
	}
	\%r;
}

my ($build_requires, $configure_requires, $runtime_requires, $test_requires);
if ('ExtUtils::MakeMaker'->VERSION >= 6.6303)
{
	$WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build');
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{TEST_REQUIRES}      ||= deps('test');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');
}
elsif ('ExtUtils::MakeMaker'->VERSION >= 6.5503)
{
	$WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build');
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure', 'test');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');	
}
elsif ('ExtUtils::MakeMaker'->VERSION >= 6.52)
{
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure', 'build', 'test');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');	
}
else
{
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('configure', 'build', 'test', 'runtime');	
}

{
	my $minperl = delete $WriteMakefileArgs{PREREQ_PM}{perl};
	exists($WriteMakefileArgs{$_}) && delete($WriteMakefileArgs{$_}{perl})
		for qw(BUILD_REQUIRES TEST_REQUIRES CONFIGURE_REQUIRES);
	if ($minperl and 'ExtUtils::MakeMaker'->VERSION >= 6.48)
	{
		$WriteMakefileArgs{MIN_PERL_VERSION} ||= $minperl;
	}
	elsif ($minperl)
	{
		die "Need Perl >= $minperl" unless $] >= $minperl;
	}
}

WriteMakefile(%WriteMakefileArgs);

exit(0);

