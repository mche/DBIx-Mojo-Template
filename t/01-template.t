use Mojo::Base -strict;

use Test::More;
use DBIx::Mojo::Template;
use Mojo::Util qw(dumper);
binmode STDERR, ":utf8";

my $t = DBIx::Mojo::Template->new(__PACKAGE__, vars=>{'фу'=>'фу1', 'бар'=>'бар1'}, mt=>{tag_start=>'{%', tag_end=>'%}',});

like $t->{'фу/бар.1'}, qr/\$фу/, 'string';

like $t->{'фу/бар.1'}->render, qr/фу1.бар1/, 'render global vars';
like $t->{'фу/бар.1'}->render('бар'=>'бар2'), qr/фу1.бар2/, 'render merge vars';
is $t->{'фу.бар.2'}->render('бла'=>'бла2'), "фу.бар.2\n", 'expr+comment';
is $t->render('фу.бар.2', 'бла'=>'бла2'), "фу.бар.2\n", 'render dict key';



done_testing();

__DATA__
@@ фу/бар.1?кэш=1

select *, 1 as "колонка"
from {%= $фу %}.{%= $бар %}
;

@@ фу.бар.2
%# 123
% my ($hash) = @_;
фу.бар.2