package Dist::Inkt::Role::WriteMakefilePL;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moose::Role;
use Types::Standard -types;
use Data::Dump 'pp';
use namespace::autoclean;

sub DYNAMIC_CONFIG_PATH () { 'meta/DYNAMIC_CONFIG.PL' };

has has_shared_files => (
	is      => 'ro',
	isa     => Bool,
	lazy    => 1,
	builder => '_build_has_shared_files',
);

sub _build_has_shared_files
{
	my $self = shift;
	!! $self->sourcefile('share')->is_dir;
}

after PopulateMetadata => sub {
	my $self = shift;
	$self->metadata->{prereqs}{configure}{requires}{'ExtUtils::MakeMaker'} = '6.31'
		if !defined $self->metadata->{prereqs}{configure}{requires}{'ExtUtils::MakeMaker'};
	$self->metadata->{prereqs}{configure}{requires}{'File::ShareDir::Install'} = '0.02'
		if $self->has_shared_files
		&& !defined $self->metadata->{prereqs}{configure}{requires}{'File::ShareDir::Install'};
	$self->metadata->{dynamic_config} = 1
		if $self->sourcefile(DYNAMIC_CONFIG_PATH)->exists;
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

	my $dynamic_config = do
	{
		my $dc = $self->sourcefile(DYNAMIC_CONFIG_PATH);
		$dc->exists ? "\ndo {\n${\ $dc->slurp_utf8 }\n};" : '';
	};
	
	my $share = '';
	if ($self->has_shared_files)
	{
		$share = "\nuse File::ShareDir::Install;\n"
			. "install_share 'share';\n"
			. "{ package MY; use File::ShareDir::Install qw(postamble) };\n";
	}
	
	my $makefile = do { local $/ = <DATA> };
	$makefile =~ s/%%%METADATA%%%/$dump/;
	$makefile =~ s/%%%SHARE%%%/$share/;
	$makefile =~ s/%%%DYNAMIC_CONFIG%%%/$dynamic_config/;
	$file->spew_utf8($makefile);
}

1;

__DATA__
use strict;
use ExtUtils::MakeMaker 6.31;

my $meta = %%%METADATA%%%;

my %dynamic_config;%%%DYNAMIC_CONFIG%%%

my %WriteMakefileArgs = (
	ABSTRACT           => $meta->{abstract},
	AUTHOR             => $meta->{author},
	DISTNAME           => $meta->{name},
	DISTVNAME          => sprintf('%s-%s', $meta->{name}, $meta->{version}),
	EXE_FILES          => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
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

sub FixMakefile
{
	return unless -d 'inc';
	my $file = shift;
	
	local *MAKEFILE;
	open MAKEFILE, "< $file" or die "FixMakefile: Couldn't open $file: $!; bailing out";
	my $makefile = do { local $/; <MAKEFILE> };
	close MAKEFILE or die $!;
	
	$makefile =~ s/\b(test_harness\(\$\(TEST_VERBOSE\), )/$1'inc', /;
	$makefile =~ s/( -I\$\(INST_ARCHLIB\))/ -Iinc$1/g;
	$makefile =~ s/( "-I\$\(INST_LIB\)")/ "-Iinc"$1/g;
	$makefile =~ s/^(FULLPERL = .*)/$1 "-Iinc"/m;
	$makefile =~ s/^(PERL = .*)/$1 "-Iinc"/m;
	
	open  MAKEFILE, "> $file" or die "FixMakefile: Couldn't open $file: $!; bailing out";
	print MAKEFILE $makefile or die $!;
	close MAKEFILE or die $!;
}
%%%SHARE%%%
my $mm = WriteMakefile(%WriteMakefileArgs);
FixMakefile($mm->{FIRST_MAKEFILE} || 'Makefile');
exit(0);

