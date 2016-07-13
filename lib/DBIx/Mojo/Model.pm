package DBIx::Mojo::Model;
use Mojo::Base -base;
use Carp 'croak';
use DBIx::Mojo::Template;
use Hash::Merge qw( merge );

my %DICT_CACHE = ();# для каждого пакета/модуля

has [qw(dbh dict template_vars mt)];


#init once
sub singleton {
  state $singleton = shift->SUPER::new(@_);
}

# child model
sub new {
  my $self = ref $_[0] ? shift : shift->SUPER::new(@_);
  my $singleton = $self->singleton;
  
  $self->dbh($singleton->dbh)
    unless $self->dbh;
    
  $self->template_vars(merge($self->template_vars || {}, $singleton->template_vars))
    if $singleton->template_vars;
  
  my $pkg = ref $self;
  
  $self->dict( $DICT_CACHE{$pkg} ||= DBIx::Mojo::Template->new($pkg, mt=> $self->mt, vars => $self->template_vars) )
    unless $self->dict;
  $self;
}

sub sth {
  my $self = shift;
  my $name = shift;
  my $dict = $self->dict;
  my $st = $dict->{$name}
    or croak "No such name[$name] in SQL dict! @{[ join ':', keys %$dict  ]}";
  #~ my %arg = @_;
  my $sql = $st->template(@_).sprintf("\n--Statement name[%s]", $st->name); # ->template(%$template ? %arg ? %{merge($template, \%arg)} : %$template : %arg)
  my $param = $st->param;
  
  my $sth;

  #~ local $dbh->{TraceLevel} = "3|DBD";
  
  if ($param && $param->{cached}) {
    $sth = $self->dbh->prepare_cached($sql);
    #~ warn "ST cached: ", $sth->{pg_prepare_name};
  } else {
    $sth = $self->dbh->prepare($sql);
  }
  
  return $sth;
  
}

=pod

=encoding utf8

Доброго всем

=head1 DBIx::Mojo::Model

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

DBIx::Mojo::Model - base class for DBI models with templating statements by Mojo::Template.

=head1 SINOPSYS

Init once base singleton for process with dbh and (optional) template vars:

  use DBIx::Mojo::Model;
  DBIx::Mojo::Model->singleton(dbh=>$dbh, template_vars=>$t);

In child model must define SQL dict in __DATA__ of model package:

  package Model::Foo;
  use Mojo::Base 'DBIx::Mojo::Model';
  
  sub new {
    state $self = shift->SUPER::new(mt=>{tag_start=>'{%', tag_end=>'%}'}, @_);
  }
  
  sub foo {
    my $self = ref $_[0] ? shift : shift->new;
    $self->dbh->selectrow_hashref($self->sth('foo', where => 'where id=?',), undef, (shift));
  }
  
  __DATA__
  @@ foo?cache=1
  %# my foo statement with prepare_cached
  select *
  from foo
  {% $where %}
  ;

In controller:

  ...
  my $mFoo = do {require Model::Foo; Model::Foo->new;};
  
  sub actionFoo {
    my $c = shift;
    my $foo = $mFoo->foo($c->param('id'));
    ...
  
  }

=head1 ATTRIBUTES

=head2 dbh

=head2 dict

DBIx::Mojo::Template object. If not defined then will auto create from __DATA__ current model package.

  Model::Foo->new(dict=>DBIx::Mojo::Template->new('Model::Foo', ...), ...)

=head2 mt

Hashref Mojo::Template object attributes. Will passed to C<< DBIx::Mojo::Template->new >> then dict auto create

=head2 template_vars

Hashref variables applies in statement templates.

=head1 METHODS

=head2 new

=head2 singleton

=head2 sth

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;