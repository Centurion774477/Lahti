
package LazyScript;

use strict;
use warnings;
use feature 'say';

my @tokens = ();

# argue token to push
sub add_to_tokens {
    my $itemToPush = shift;
    push(@tokens, $itemToPush);
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
        } elsif ($line =~ /constant\s(?<variable_name>\w+)\s=\s(?<assignment>\w+)/ || line =~ /(?<variable_name>\w+)\s=\s(?<assignment>\w+)always/) {
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
        } else {
            # Let node.js do the linting; I'm not gonna verify your JavaScript.
            add_to_tokens({
                type => 'javascript',
                content => $line
            });
        }
    }

    close $fh;

    @tokens == 0 and die 'Failed to locate any LazyScript keywords in the file ' . $fileToLex;

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
            rl.close();
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
        }
    }
}

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
        $snippet =~ s/^\s+//;
        print $newFh $snippet;
    }
    close $newFh;
    return $outputFileName
}

1;