#!/usr/local/bin/perl -w

# $Id: twiddle-regex,v 1.2 1999/10/21 02:00:50 klassa Exp klassa $

##########################################################################
# twiddle-regex
#
# Inspired by redemo.py in the python 1.5.2 distribution.
#
# Author: John Klassa
# Date:   June, 1999
#
# Lets you enter target text as well as a regex, and gives you
# visual feedback on how the latter does against the former.
##########################################################################

use strict;
use Tk;

my @REGEX_OPTS = qw(i s m x);

# Stash warnings away, so we can show them to the user.  I'm assuming
# that this is relatively safe, despite the fact that it allocates
# memory, since it occurs in the context of a "pseudo" signal (a
# warning) and not real, asynchronous, from-the-OS kind of a signal...
# Is this true?

my @warnings;

$SIG{__WARN__} = sub { @warnings = @_ };

# Create the GUI, then go into Tk's main loop.

my $W = init_gui();
MainLoop();


##########################################################################
# init_gui: Create the whole GUI.  Return a hash with keys "w", "f" and
#           "o" (important widgets, frames and regex options, respectively).
#           Each key yields a hashref.
##########################################################################

sub init_gui
{
    my $w = Tk::MainWindow->new;

    # Create frames to hold the various parts of the display.

    my(%f, %w);

    my @opts = qw(-side top -fill both -expand yes);

    $f{text}   = $w->Frame()->pack(@opts);
    $f{regex}  = $w->Frame()->pack(@opts);
    $f{opt}    = $w->Frame()->pack(qw(-side top -fill both));
    $f{result} = $w->Frame()->pack(@opts);

    # Create an exit button, since folks seem to have lost sight of what
    # the window manager "Close" button is for. :-)

    $w->Button(-text => "Exit",
               -command => sub { exit 0 })->pack(-side => "top", -fill => "x");

    # Create a text widget to hold the target text.  Bind the <Key> event
    # to the update routine, so that every keypress results in immediate
    # feedback.

    $f{text}->Label(-text => "Target Text", -background => "#aaaacc")
            ->pack(-side => "top", -fill => "x");
    $w{text} = $f{text}->Text(-height => 5)
	             ->pack(-side => "top", -fill => "both", -expand => "yes");
    $w{text}->bind("<Key>", \&update_display);

    # Create checkbuttons for the various regex options that perl
    # allows.  Bind -command to the update routine so that any changes
    # to the options are reflect in the visuals.

    my %opt = map { $_ => "" } @REGEX_OPTS;

    for my $opt (@REGEX_OPTS)
    {
        my $b = $f{opt}->Checkbutton(-text     => "/$opt",
                                     -onvalue  => $opt,
                                     -offvalue => "",
                                     -variable => \$opt{$opt},
                                     -command  => \&update_display);
        $b->pack(-side => "left", -fill => "x", -expand => "yes");
    }

    # Create a text widget to hold the regex.  Bind the <Key> as above.

    $f{regex}->Label(-text => "Regular Expression", -background => "#aaaacc")
             ->pack(-side => "top", -fill => "x");
    $w{regex} = $f{regex}->Text(-height => 5)
	             ->pack(-side => "top", -fill => "both", -expand => "yes");
    $w{regex}->bind("<Key>", \&update_display);

    # Create a text widget to hold the results.  Create tags for the
    # "pre", "match" and "post" text so that we can highlight 'em
    # nicely.

    $f{result}->Label(-text => "Result", -background => "#aaaacc")
              ->pack(-side => "top", -fill => "x");
    $w{result} = $f{result}->Text(-height => 20)
	             ->pack(-side => "top", -fill => "both", -expand => "yes");
    $w{result}->tag("configure", "pre", "-background", "#aaccaa");
    $w{result}->tag("configure", "match", "-background", "yellow");
    $w{result}->tag("configure", "post", "-background", "#ccaaaa");

    return { w => \%w, f => \%f, o => \%opt };
}


##########################################################################
# update_display: Attempt to apply the regex and report on the results.
##########################################################################

sub update_display
{
    my($w_text, $w_regex, $w_result) = @{$W->{w}}{qw(text regex result)};

    # Get the target text and regex.

    (my $text = $W->{w}{text}->get("1.0", "end")) =~ s/\s+$//;
    (my $regex = $W->{w}{regex}->get("1.0", "end")) =~ s/\s+$//;

    # Compile the regex in an eval block so we don't die.  Is there a
    # good way to tack on regex flags without resorting to the string
    # form of eval?  I like the plain block form better, just for doing
    # try/catch stuff.

    my $flags = join "", grep { not /g/ } @{$W->{o}}{@REGEX_OPTS};

    my $re;

    @warnings = ();

    $re = eval "qr/\$regex/$flags";

    $w_result->delete("1.0", "end");

    # If there was a problem, spell it out.

    if ($@)
    {
        $w_result->insert("end", "Problem with regex: $@");
    }
    elsif (@warnings)
    {
        $w_result->insert("end", "Regex produces warning: @warnings");
    }

    # Otherwise, try out the regex.  If it worked, emit the pre, match
    # and post portions in color, then emit any parenthesized portions
    # with labels.
=head1
    elsif (my @matches = do {  
    	print "option is [$W->{o}{g}]\n";
    	if( $W->{o}{g} eq 'g' ) { ( $text =~ m/$re/g  ) }
    	else                    { ( $text =~ m/$re/   ) }
    	} )
=cut
    elsif (my @matches = ( $text =~ m/$re/   ) )
    {
        $w_result->insert("end", $`, "pre");
        $w_result->insert("end", $&, "match");
        $w_result->insert("end", $', "post");
        $w_result->insert("end", "\n\n");

        if ($` ne "" || $& ne "" || $' ne "")
        {
            my $count = 1;

            $w_result->insert("end", "\n\n");

            for my $match (@matches)
            {
                $w_result->insert("end", "\$$count\n");
                $w_result->insert("end", $match, "match");
                $w_result->insert("end", "\n\n");
                ++$count;
            }
        }
    }
    else
    {
        $w_result->insert("end", "No match.");
    }
}
