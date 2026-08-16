#!/usr/bin/env perl

use strict; use warnings;
use feature 'say';
use File::Basename;
use FindBin;
use lib "$FindBin::Bin";
use LazyScript;

my @arguments = @ARGV;

my $command = $arguments[0];

sub transpile {
    my $fileGiven = $arguments[1];
    my $basename = $arguments[1] =~ s/\.[^.]+$//r;
    my $fileGoingOut = "$basename.js";

    LazyScript::lex($fileGiven);
    LazyScript::parse();
    LazyScript::generate($fileGoingOut);

    say 'There you go. The new file is titled ' . $fileGoingOut . ' Enjoy.'; 
}

if (grep {$_ eq $command} qw|transpile digest render|) {
    transpile();
}