package DBIx::Mojo::Template;
use Mojo::Base -base;
use Mojo::Loader qw(data_section);
use Mojo::Template;
use Mojo::URL;
use Mojo::Util qw(url_unescape);

sub mt {
  state $mt = Mojo::Template->new(vars => 1, prepend=>'no strict qw(vars); no warnings qw(uninitialized);', @_);# line_start=>'$$',
}


sub new {
  my ($class) = shift;
  bless data(@_);
}

sub data {
  my ($pkg, %arg) = @_;
  my $data = {};
  while ( my ($k, $t) = each data_section $pkg)  {
    my $url = Mojo::URL->new($k);
    my ($name, $param) = (url_unescape($url->path), $url->query->to_hash);
    utf8::decode($name);
    $data->{$name} = DBIx::Mojo::Statement->new(name=>$name, sql=>$t, param=>$param, mt=>mt(%{$arg{mt} || {}}), vars=>$arg{vars} || {});
  }
  return $data;
}

our $VERSION = '0.01';

#=============================================
package DBIx::Mojo::Statement;
#=============================================
use Mojo::Base -base;
use Hash::Merge qw(merge);

has [qw(name sql param mt vars)];

use overload '""' => sub { shift->sql };

sub render {
  my $self = shift;
  my $vars =ref $_[0] ? shift : { @_ };
  
  $self->mt->render($self->sql, %$vars ? %{$self->vars} ? merge($vars, $self->vars) : $vars : $self->vars);
  
}

=pod

=encoding utf8

Доброго всем

=head1 DBIx::Mojo::Template

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

DBIx::Mojo::Template - Render SQL statements templates by Mojo::Template

=head1 VERSION

0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DBIx::Mojo::Template;

    my $foo = DBIx::Mojo::Template->new();
    ...


=head1 SUBROUTINES/METHODS


=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/DBIx-POS-Template/issues>. Pull requests also welcome.


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Михаил Че (Mikhail Che).

This module is free software; you can redistribute it and/or modify it under the term of the Perl itself.


=cut

1; # End of DBIx::Mojo::Template
