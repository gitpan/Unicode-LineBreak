#! perl

use constant MANDATORY => 3;
use constant DIRECT_ALLOWED => 2;
use constant DIRECT_PROHIBITED => -1;
use constant INDIRECT_PROHIBITED => -2;

my @CLASSES = qw{BK CR LF NL SP
OP CL QU GL NS NSid EX SY IS PR PO NU AL ID IN HY BA BB B2 CB ZW CM WJ
H2 H3 JL JV JT
SG AI SAcm SAal XX};
my $OMIT = qr{BK|CM|CR|LF|NL|SP|AI|H2|H3|JL|JV|JT|SA|SG|XX|...};
@CLASSES = (grep(!/$OMIT/, @CLASSES), grep(/$OMIT/, @CLASSES));
my %ACTIONS = ('!' => MANDATORY,
	       'SP*×' => INDIRECT_PROHIBITED,
               '×' => DIRECT_PROHIBITED,
               '÷' => DIRECT_ALLOWED,
    );

print <<"EOF";
#-*- perl -*-

=encoding utf8

This file is automatically generated.  DON'T EDIT THIS FILE MANUALLY.

=cut

package Unicode::LineBreak;

EOF

my @rules = ();
while (<>) {
    chomp $_;
    s/^\s+//;
    if (!/\S/ or /^\#/) {
        next;
    } elsif (/Assign a line breaking class/) {
        next;
    } elsif (/Treat X CM\* as if it were X/) {
        next;
    } elsif (/Treat any remaining CM as i. i. were AL/) {
        next;
    }

    my ($left, $break, $right) = split(/\s*(!|SP\*\s*×|×|÷)\s*/, $_);
    $left = &class2re($left);
    $right = &class2re($right);
    $break =~ s/\s+//g;
    $break = $ACTIONS{$break};

    push @rules, [$left, $break, $right];
}

sub class2re {
    my $class = shift;

    if ($class =~ /\(([^)]+)\)/) {
	$class = &inclusive2re($1);
    } elsif ($class =~ /[[]\^([^]]+)\]/) {
	$class = &exclusive2re($1);
    } elsif ($class =~ /(\S+)/) {
	if ($& eq 'ALL') {
	    $class = qr{.+};
	} else {
	    $class = qr{$&};
	}
    } else {
	$class = qr{.+};
    }
    return $class;
}

sub inclusive2re {
    my $class = shift;
    $class =~ s/^\s+//; $class =~ s/\s+$//;
    $class = join '|', split /\s*\|\s*/, $class;
    return qr{$class};
}

sub exclusive2re {
    my $class = shift;
    $class =~ s/^\s+//; $class =~ s/\s+$//;
    my @class = split /\s*\|\s*/, $class;
    my %class;

    foreach my $c (@class) {
        $class{$c} = 1;
    }
    @class = ();
    foreach my $c (@CLASSES) {
        push @class, $c unless $class{$c};
    }
    $class = join('|', @class);
    return qr{$class};
}

my $i = 0;
print "our %lb_IDX = (\n";
foreach my $c (@CLASSES) {
    print <<"EOF";
    '$c' => $i,
EOF
   $i++;
}
print ");\n\n";

    print <<"EOF";
use constant M => 'MANDATORY';
use constant D => 'DIRECT';
use constant I => 'INDIRECT';
use constant P => 'PROHIBITED';
EOF
print "\n";

my @rule_classes = grep !/$OMIT/, @CLASSES;
print <<EOF;
our \$RULES_MAP = [
EOF
print "    #";
foreach my $c (@rule_classes) { $c =~ /(.)(.)/; print $1.lc($2) }
print "\n";
foreach my $b (@rule_classes) {
    print "    [";

    foreach my $a (@rule_classes) {
	my $direct = undef;
	my $indirect = undef;
	my $mandatory = undef;
	foreach my $r (@rules) {
	    my ($before, $action, $after) = @{$r};
	    if ($b =~ /$before/ and $a =~ /$after/) {
		if ($action == MANDATORY) {
		    $mandatory = 1;
		    last;
		} elsif ($action == INDIRECT_PROHIBITED) {
		    $direct = 0 unless defined $direct;
		    $indirect = 0 unless defined $indirect;
		} elsif ($action == DIRECT_PROHIBITED) {
		    $direct = 0 unless defined $direct;
		} elsif ($action == DIRECT_ALLOWED) {
		    $direct = 1 unless defined $direct;
		}
	    }

	    if ("SP" =~ /$before/ and $a =~ /$after/) {
		if ($action == DIRECT_ALLOWED) {
		    $indirect = 1 unless defined $indirect;
		} elsif ($action == DIRECT_PROHIBITED or
			 $action == INDIRECT_PROHIBITED) {
		    $indirect = 0 unless defined $indirect;
		}
	    }

	    last if defined $direct and defined $indirect;
	}
	my $action;
	if ($mandatory) {
	    $action = 'M'; # '!';
	} elsif ($direct) {
	    $action = 'D'; # '_';
	} elsif ($indirect) {
	    $action = 'I'; # '%';
	} else {
	    $action = 'P'; # '^';
	}

	print "$action,";
    }
    print "], # $b\n";
}
print <<EOF;
];

1;
EOF

