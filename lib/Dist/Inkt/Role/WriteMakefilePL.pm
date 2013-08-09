package Dist::Inkt::Role::WriteMakefilePL;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose::Role;
use Data::Dump 'pp';
use namespace::autoclean;

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
	
	my $dump = pp( $self->metadata->as_struct({version => '2'}) );
	chomp $dump;
	$file->spew(
		"use strict;\n",
		"my \$meta = $dump;\n",
		<DATA>,
	);
}

1;

__DATA__

use ExtUtils::MakeMaker;

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
	$build_requires     = deps('build');
	$configure_requires = deps('configure');
	$test_requires      = deps('test');
	$runtime_requires   = deps('runtime');
}
elsif ('ExtUtils::MakeMaker'->VERSION >= 6.5503)
{
	$build_requires     = deps('build');
	$configure_requires = deps('configure', 'test');
	$runtime_requires   = deps('runtime');
}
elsif ('ExtUtils::MakeMaker'->VERSION >= 6.52)
{
	$configure_requires = deps('configure', 'test', 'build');
	$runtime_requires   = deps('runtime');
}
else
{
	$runtime_requires   = deps('runtime', 'configure', 'test', 'build');
}

WriteMakefile(
	ABSTRACT           => $meta->{abstract},
	AUTHOR             => $meta->{author},
	BUILD_REQUIRES     => $build_requires,
	CONFIGURE_REQUIRES => $configure_requires,
	DISTNAME           => $meta->{name},
	DISTVNAME          => sprintf('%s-%s', $meta->{name}, $meta->{version}),
	EXE_FILES          => [],   # XXX - TODO
	LICENSE            => $meta->{license}[0],
	NAME               => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	PREREQ_PM          => $runtime_requires,
	TEST_REQUIRES      => $test_requires,
	VERSION            => $meta->{version},
);

exit(0);

