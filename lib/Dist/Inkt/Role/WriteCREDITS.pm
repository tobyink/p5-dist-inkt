package Dist::Inkt::Role::WriteCREDITS;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose::Role;
use RDF::Trine qw( iri literal statement variable );
use Types::Standard -types;
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

after PopulateMetadata => sub {
	my $self = shift;
	push @{ $self->metadata->{author} },
		map $_->{display},
		grep $_->{role} eq 'maintainer',
		@{ $self->people };
	push @{ $self->metadata->{x_contributors} },
		map $_->{display},
		grep $_->{role} eq 'contributor',
		@{ $self->people };
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
	
	for my $role (qw/ maintainer contributor thanks /)
	{
		my @peeps =
			sort { $a->{display_long} cmp $b->{display_long} }
			grep { $_->{role} eq $role }
			@{ $self->people };
		next unless @peeps;
		
		printf $fh "%s:\n", ucfirst $role;
		printf $fh "- $_->{display_long}\n" for @peeps;
		printf $fh "\n";
	}
	
	close($fh);
}

use RDF::Trine::Namespace qw( RDF RDFS OWL XSD );
my $DBUG = RDF::Trine::Namespace->new('http://ontologi.es/doap-bugs#');
my $DCS  = RDF::Trine::Namespace->new('http://ontologi.es/doap-changeset#');
my $DOAP = RDF::Trine::Namespace->new('http://usefulinc.com/ns/doap#');
my $FOAF = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');

my @predicates = (
	$DOAP->maintainer,
	$DOAP->developer,
	$DOAP->documenter,
	$DOAP->translator,
	$DOAP->tester,
	$DOAP->helper,
	$DBUG->reporter,
	$DBUG->assignee,
	$DCS->blame,
	$DCS->thanks,
	$DCS->uri("released-by"),
);

my %roles = (
	$DOAP->maintainer  => "maintainer",
	$DOAP->developer   => "contributor",
	$DOAP->documenter  => "contributor",
	$DOAP->translator  => "contributor",
	$DOAP->tester      => "thanks",
	$DOAP->helper      => "thanks",
	$DBUG->reporter    => "thanks",
	$DBUG->assignee    => "contributor",
	$DCS->blame        => "contributor",
	$DCS->thanks       => "thanks",
	$DCS->uri("released-by") => "maintainer",
);

has people => (
	is       => 'ro',
	isa      => ArrayRef[HashRef],
	lazy     => 1,
	builder  => '_build_people',
);

sub _build_people
{
	my $self  = shift;
	my $model = $self->model;
	
	my %people;
	for my $p (@predicates)
	{
		for my $o ($model->objects(undef, $p))
		{
			$people{$o}{node} = $o;
			push @{ $people{$o}{predicates} }, $p;
		}
	}
	
	for my $p (values %people)
	{
		$p->{role} = +{ map { ;$roles{$_} => 1 } @{$p->{predicates}} };
		delete $p->{predicates};
		
		if ($p->{role}{maintainer})
			{ $p->{role} = "maintainer" }
		elsif ($p->{role}{contributor})
			{ $p->{role} = "contributor" }
		elsif ($p->{role}{thanks})
			{ $p->{role} = "thanks" }
		
		if ($p->{node}->is_resource
		and $p->{node}->uri =~ m{^http://purl.org/NET/cpan-uri/person/(\w+)$})
		{
			$p->{cpanid} = uc $1;
		}
		
		($p->{name}) =
			map  $_->literal_value,
			grep $_->is_literal,
			$model->objects_for_predicate_list($p->{node}, $FOAF->name, $RDFS->label);
		
		($p->{mbox}) =
			map  $_->uri,
			grep $_->is_resource,
			$model->objects_for_predicate_list($p->{node}, $FOAF->mbox);
		$p->{mbox} //= sprintf('mailto:%s@cpan.org', lc($p->{cpanid})) if $p->{cpanid};
		
		($p->{nick}) =
			map  $_->literal_value,
			grep $_->is_literal,
			$model->objects_for_predicate_list($p->{node}, $FOAF->nick);
		$p->{nick} //= $p->{cpanid};
		
		(my $mbox = $p->{mbox}) =~ s/^mailto://i;
		
		$p->{display} = $mbox
			? sprintf("%s <%s>", ($p->{name}//$p->{nick}//"Anon"), $mbox)
			: sprintf("%s",      ($p->{name}//$p->{nick}//"Anon"));
		
		$p->{display_long} = $p->{display};
		$p->{display_long} = $mbox
			? sprintf("%s (cpan:%s) <%s>", ($p->{name}//$p->{nick}//"Anon"), uc($p->{cpanid}), $mbox)
			: sprintf("%s (cpan:%s)",      ($p->{name}//$p->{nick}//"Anon"), uc($p->{cpanid}))
			if $p->{cpanid};
	}
	
	return [ values %people ];
}

1;
