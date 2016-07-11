use Mojo::Base -strict;

use Test::More;
use DBIx::Mojo::Template;
use Mojo::Util qw(dumper);

my $t = DBIx::Mojo::Template->new(__PACKAGE__, 1=>2);

warn dumper $t;

done_testing();

__DATA__
@@ фу.бар.1?кэш=1

select *
from {%= $фу %} {%= $бар %}
;

@@ фу.бар.2
$$ my ($msg, $hash) = @_;