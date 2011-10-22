use strict;
use Test::More;
require "t/lb.pl";

BEGIN { plan tests => 11 }

foreach my $lang (qw(ar el fr he ja ja-a ko ru vi vi-decomp zh)) {
    dotest($lang, $lang);
}    

1;

