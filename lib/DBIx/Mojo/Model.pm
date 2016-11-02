package DBIx::Mojo::Model;
use Mojo::Base -base;
use Carp 'croak';
use DBIx::Mojo::Template;
use Hash::Merge qw( merge );

my %DICT_CACHE = ();# для каждого пакета/модуля

has [qw(dbh dict template_vars mt)];
has self_cache_st => 1; # 0 - use DBI caching 1 overvise this module caching

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
    if $singleton->template_vars && %{$singleton->template_vars};
  
  $self->mt(merge($self->mt || {}, $singleton->mt))
    if $singleton->mt && %{$singleton->mt};
  
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
  my $sql = $st->render(@_).sprintf("\n--Statement name[%s]", $st->name); # ->template(%$template ? %arg ? %{merge($template, \%arg)} : %$template : %arg)
  my $param_cached = $st->param && $st->param->{cached} || $st->param->{cache};
  
  return $st->sth || $st->sth($self->dbh->prepare($sql))->sth
    if $self->self_cache_st && $param_cached;

  #~ local $dbh->{TraceLevel} = "3|DBD";
  
  return $self->dbh->prepare_cached($sql)
    if $param_cached;
  
  return $self->dbh->prepare($sql);
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
  @@ foo?cached=1
  %# my foo statement with prepare_cached
  select *
  from foo
  {% $where %}
  ;

In controller:

  ...
  has model => sub { require Model::Foo; Model::Foo->new };
  
  sub actionFoo {
    my $c = shift;
    my $foo = $c->model->foo($c->param('id'));
    ...
  
  }

=head1 ATTRIBUTES

=head2 dbh

=head2 dict

DBIx::Mojo::Template object. If not defined then will auto create from __DATA__ current model package.

  Model::Foo->new(dict=>DBIx::Mojo::Template->new('Model::Foo', ...), ...)

=head2 mt

Hashref Mojo::Template object attributes. Will passed to C<< Mojo::Template->new >> then dict auto create

=head2 template_vars

Hashref variables applies in statement templates.

=head2 self_cache_st

Boolean switch: 0 - use DBI caching ($dbh->prepare_cached) 1 overvise this module caching. The statemnt must defined C<cached> param:

  @@ foo query name?cached=1
  select ...

Defaults is true for save statement inside DBIx::Mojo::Statement object atribute C<sth>.

=head1 METHODS

=head2 new

Define or copy/merge attributes from C<singleton>.

=head2 singleton

Initialize default attributes for child model modules. Mostly C<dbh> and C<template_vars>

=head2 sth

This is main method.

First input arg is dict statement name, next args C<< key => val >> are template variables.
Return DBI prepared (cached if param 'cached' is true) statement.

=head1 Templates

Body of template statement get as:

  $mFoo->dict->{'foo'}->sql

Templates name can has additional params as ulr query:

  @@ foo.bar/baz?a=156&b=c
  ...

then model object the name of statement is url path and query is param:

  $mFoo->dict->{'foo.bar/baz'}->param->{b} # 'c'

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