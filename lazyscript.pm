
package LazyScript;

use strict;
use warnings;
use feature 'say';
use diagnostics;

my @tokens = ();

my $expectingClosingBracket = 0; 
# same lazy error system as JulietScript. If I wanted to upgrade it, 
# I would add a ledger that marks what line last turned this true

# argue token to push
sub add_to_tokens {
    my $itemToPush = shift;
    push(@tokens, $itemToPush);
}

# checks if the closing bracket is 0, and throws an error if its not.
# I know that this would lock you out of nested loops but I don't care.
sub checkClosingBracketState {
    $expectingClosingBracket == 1 and die "You must close the previous block before opening a new one.";
    return 1;
}

# argue file to lex
sub lex {
    my $fileToLex = shift;

    open(my $fh, '<', $fileToLex) or die 'Failed to open ' . $fileToLex . ' . Are you sure it exists?';
    while (my $line = <$fh>) {
        if ($line =~ /let\s(?<variable>\w+)\s=\slisten/) {
            add_to_tokens({
                type => 'assigned_listen',
                assign_to => $+{variable} 
            });
        } elsif ($line =~ /listen/) {
            add_to_tokens({
                type => 'plain_listen'
            });
        } elsif ($line =~ /speak\s("|')(?<output>.*?)("|')/) {
            add_to_tokens({
                type => 'speak',
                output => $+{output}
            });
        } elsif ($line =~ /constant\s(?<variable_name>\w+)\s=\s(?<assignment>.*)/ || $line =~ /(?<variable_name>\w+)\s=\s(?<assignment>.*)\salways/) {
            add_to_tokens({
                type => 'constant_creation',
                name => $+{variable_name},
                value => $+{assignment}
            });
        } elsif ($line =~ /if\s(?<attempt>.*)\sfails\s(?<rescue>.*)$/) {
            add_to_tokens({
                type => 'if_fails',
                attempt => $+{attempt},
                rescue_with => $+{rescue}
            });
        } elsif ($line =~ /if\s(?<comparison>.*)\s===\seither\s(?<value_one>.*)\,\s(?<value_two>.*)\,\s(?<value_three>.*)\sthen\s\{/) {
            # I decided on 3 arguments because it's the perfect mix: 2 is short enough to use an OR; 4 or more is in .includes() territory.
            # I'm also hard coding this into a special conditional because it makes coding easier and only loses a couple of implementations.
            $expectingClosingBracket = 1;
            add_to_tokens({
                type => 'either_conditional',
                comparison => $+{comparison},
                first_value => $+{value_one},
                second_value => $+{value_two},
                third_value => $+{value_three}
            });
        } elsif (
            $line =~ /
            (if\s(?<condition>\w)\sthen(?<result>.*)$) | 
            ((?<result>.*)\s(assuming|granted)\s(?<condition>.*)$) |
            ((?<result>.*)\sif\s(?<condition>.*)$)
            /x) {
            add_to_tokens({
                type => 'conditional',
                condition => $+{condition},
                result => $+{result}
            });
        } elsif ($line =~ /(?<result>.*)\sunless\s(?<condition>.*)/) {
            add_to_tokens({
                type => 'unless',
                condition => $+{condition},
                result => $+{result}
            });
        } elsif ($line =~ /while\s\((?<thing_is_true>.*)\)\sdo\s(\{?)/) {
            $expectingClosingBracket = 1 if checkClosingBracketState();
            add_to_tokens({
                type => 'while_opening',
                condition => $+{thing_is_true}
            });
        } elsif ($line =~ /\}/) {
            if ($expectingClosingBracket == 0) {
                die 'Unexpected curly bracket -- } -- detected on line ' . $.;
            }
            $expectingClosingBracket = 0;
            add_to_tokens({
                type => 'closing_bracket'
            });
        } elsif ($line =~ /(until|before)\s\((?<condition>.*)\)\sdo\s\{/) {
            $expectingClosingBracket = 1 if checkClosingBracketState();
            add_to_tokens({
                type => 'until_opening',
                condition => $+{condition}
            });
        } elsif ($line =~ /loop\s\{/) {
            $expectingClosingBracket = 1 if checkClosingBracketState();
            add_to_tokens({
                type => 'generic_loop'
            });
        } else {
            # Let node.js do the linting; I'm not gonna verify your JavaScript.
            add_to_tokens({
                type => 'javascript',
                content => $line
            });
        }
    }

    close $fh;

    @tokens == 0                 and die 'Failed to locate any LazyScript keywords in the file ' . $fileToLex;
    $expectingClosingBracket == 1 and die 'There is a missing curly bracket somewhere in ' . $fileToLex; # this is a terrible error message. I'm sorry in advance.

    # for debugging purposes
    # say 'Tokens generated:';
    # say "$_->{'type'}" for @tokens;
}

my @snippets = ();

# argue snippet to push
sub pushSnippet {
    my $snippetToPush = shift;
    push(@snippets, $snippetToPush);
}

sub parse {
    for my $token (@tokens) {
        my $type = $token->{'type'};

        if ($type eq 'assigned_listen') {
            pushSnippet(qq{
            const $token->{'assign_to'} = await rl.question('');
            });
        } elsif ($type eq 'plain_listen') {
            pushSnippet(qq{
            await rl.question('');
            });
        } elsif ($type eq 'speak') {
            pushSnippet(qq{
            console.log("$token->{'output'}");
            });
        } elsif ($type eq 'javascript') {
            pushSnippet($token->{'content'});
        } elsif ($type eq 'constant_creation') {
            pushSnippet(qq{
            const $token->{'name'} = $token->{'value'};
            });
        } elsif ($type eq 'if_fails') {
            pushSnippet(qq{
            try {
                $token->{'attempt'};
            } catch {
                $token->{'rescue_with'};
            }
            });
        } elsif ($type eq 'conditional') {
            pushSnippet(qq{
                if ($token->{'condition'}) {
                    $token->{'result'};
                }
            });
        } elsif ($type eq 'unless') {
            pushSnippet(qq{
                if (!$token->{'condition'}) {
                    $token->{'result'};
                }
            });
        } elsif ($type eq 'while_opening') {
            pushSnippet(qq[
            while ($token->{'condition'}) {
            ]);
        } elsif ($type eq 'closing_bracket') {
            pushSnippet(qq[
            }
            ]);
        } elsif ($type eq 'until_opening') {
            pushSnippet(qq[
            while (!$token->{'condition'}) {
            ]);
        } elsif ($type eq 'generic_loop') {
            pushSnippet(qq[
            while (true) {
            ]);
        } elsif ($type eq 'either_conditional') {
            pushSnippet(qq[
            if ($token->{'comparison'} === $token->{'first_value'} || $token->{'comparison'} === $token->{'second_value'} || $token->{'comparison'} === $token->{'third_value'}) {
            ]);
        }
    }
}


# add_to_tokens({
#     type => 'either_conditional',
#     comparison => $+{comparison},
#     first_value => $+{value_one},
#     second_value => $+{value_two},
#     third_value => $+{value_three}
# });

# argue the name of the output file 
sub generate {
    my $outputFileName = shift;

    my $readlineBoilerplate = qq{
    import readline from 'node:readline/promises';
    import { stdin as input, stdout as output } from 'node:process';

    const rl = readline.createInterface({ input, output });
    };

    die 'An internal action failed: parser' if @snippets == 0;

    open(my $newFh, '>', $outputFileName);
    print $newFh $readlineBoilerplate;
    for my $snippet (@snippets) {
        print $newFh $snippet;
    }
    print $newFh "rl.close();";
    close $newFh;
    return $outputFileName
}

1;