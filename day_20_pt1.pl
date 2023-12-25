#!/usr/bin/perl
##
#   File : day_20.pl
#   Date : 24/Dec/2023
#   Author : spjspj
#   Purpose : Advent of code - flipflops, broadcaster, conjunctions,
##

use strict;
use POSIX;
use LWP::Simple;
use Socket;
use File::Copy;

my %objects;
my %objects_value;
my %objects_type;
my %objects_num_inputs;
my %objects_inputs_names;
my %pulses;
my %pulses_dealt_with;
my $pulse_index = 0;
my %outputs;
my $string = "broadcaster->a,b,cXX%a->bXX%b->cXX%c->invXX&inv->aXX";

my $string = "broadcaster->aXX%a->inv,conXX&inv->bXX%b->conXX&con->outputXX";

my $orig_string = $string;

sub make_new_object
{
    my $name = $_ [0];
    my $type = $_ [1];

    if ($orig_string =~ m/XX%$name->/) { $type = "%"; }
    if ($orig_string =~ m/XX&$name->/) { $type = "&"; }

    if (!defined ($objects {$name}))
    {
        $objects {$name} = 1;
        $objects_value {$name} = 0;
        $objects_type {$name} = $type;
        $objects_num_inputs {$name} = set_inputs ($name);
    }
    else
    {
        $objects_type {$name} = $type;
    }
}

sub get_all_objects
{
    my $copy_string = $orig_string;
    while ($copy_string =~ s/XX(%|[^a-z])([a-z]+)//)
    {
        print ("Make new object $2 that is $1\n");
        make_new_object ($2, $1);
    }
}

sub send_pulse
{
    my $from = $_ [0];
    my $to = $_ [1];
    my $pulse_low_or_high = $_ [2];

    print (" Sending pulse from $from to $to as $pulse_low_or_high\n");
    $pulses {$pulse_index} = $from . "X" . $to . "X" . $pulse_low_or_high;
    $pulses_dealt_with {$pulse_index} = 0;
    $pulse_index++;
}

sub broadcast
{
    my $input = $_ [0];
    print ("   ========================\n");

    print ("$input???\n");
    if ($input !~ m/^broadcaster/)
    {
        return;
    }
    $input =~ s/^broadcaster->//;

    while ($input =~ s/^([a-z]+)(,|X)//)
    {
        my $object_name = $1;
        print ("Object named $object_name\n");
        make_new_object ($object_name);
        send_pulse ("broadcast", $object_name, 0);
    }
}

sub set_inputs
{
    my $input = $_ [0];
    my $output = $_ [1];
    my $copy_string = $orig_string;
    my $num_inputs = 0;

    while ($copy_string =~ s/XX[%&]([^X]+?)->[^X]*?$input[^X]*?XX/XX/)
    {
        $num_inputs++;
        $objects_inputs_names {$input . $num_inputs} = $1;
    }
    print (" set_inputs - Found $num_inputs for $input!!\n");
    return $num_inputs;
}

sub flip_flop
{
    my $input = $_ [0];

    if ($input !~ m/^%/)
    {
        return;
    }
    $input =~ s/^%//;

    while ($input =~ s/^([a-z]+)->([a-z]+),/$1->/)
    {
        my $object_input = $1;
        my $object_output = $2;
        print ("Flip-flop Object named $object_input goes to $object_output\n");
        make_new_object ($object_input, "%");
        send_pulse ($object_input, $object_output, $objects_value {$object_input});
    }
    
    while ($input =~ s/^([a-z]+)->([a-z]+)//)
    {
        my $object_input = $1;
        my $object_output = $2;
        print ("Flip-flop Object named $object_input goes to $object_output\n");
        make_new_object ($object_input, "%");
        send_pulse ($object_input, $object_output, $objects_value {$object_input});
    }
}

sub conjunction
{
    my $input = $_ [0];

    if ($input !~ m/^&/)
    {
        return;
    }
    $input =~ s/^&//;

    while ($input =~ s/^([a-z]+)->([a-z]+)//)
    {
        my $object_input = $1;
        my $object_output = $2;
        print ("Conjunction Object named $object_input goes to $object_output\n");
        make_new_object ($object_input, "&");
        send_pulse ($object_input, $object_output, $objects_value {$object_input});
    }
}

sub get_val_of_object
{
    my $obj_name = $_ [0];
    return ($objects_value {$obj_name});
}

sub set_object_value
{
    my $obj_name = $_ [0];
    my $val = $_ [1];
    my $value_was_set = 0;

    if (defined ($objects {$obj_name}))
    {
        if ($objects_type {$obj_name} eq "&")
        {
            print ("   -----> set_object_value: Conjunction .. ");
            $value_was_set = 1;
            if ($objects_num_inputs {$obj_name} == 1)
            {
                print ("$obj_name is an inverter!!.. Incoming value is: $val so new value is: ");
                if ($val == 0) { $objects_value{$obj_name} = 1; }
                elsif ($val == 1) { $objects_value{$obj_name} = 0; }
                print ("$objects_value{$obj_name}\n");
                $value_was_set = 1;
            }
            else
            {
                print ("$obj_name is a NAND!!.. if all incoming values are 0: $val so new value is: ");

                my $x = 1;
                my $is_nand = 1;
                while (defined ($objects_inputs_names {$obj_name . $x}))
                {
                    my $val = get_val_of_object ($objects_inputs_names {$obj_name . $x});
                    if ($val == 1)
                    {
                        $is_nand = 0;
                    }
                    $x++;
                }

                $objects_value{$obj_name} = $is_nand;
                $value_was_set = 1;
            }
        }
        if ($objects_type {$obj_name} eq "%")
        {
            print ("   -----> set_object_value: Flipflop.. ");
            print ("value =  " . $objects_value{$obj_name});
            print ("input =  " . $val);
            if ($val == 0)
            {
                if ($objects_value{$obj_name} == 0) { $objects_value{$obj_name} = 1; }
                elsif ($objects_value{$obj_name} == 1) { $objects_value{$obj_name} = 0; }
            }
            else { print ("    (No change as high pulse incoming) "); }
            print (" >> new value = " . $objects_value{$obj_name} . "\n");
            $value_was_set = 1;
        }
    }
    return $value_was_set;
}

sub progress_state
{
    my $pulse_id = 0;
    while (defined ($pulses {$pulse_id}))
    {
        if ($pulses_dealt_with {$pulse_id} == 0)
        {
            my $val = $pulses {$pulse_id};
            my $is_object_set = 0;

            if ($val =~ m/^([^X]+?)X([^X]+?)X([01])/)
            {
                my $from = $1;
                my $to = $2;
                my $val = $3;
                $is_object_set = set_object_value ($to, $val);
                if ($is_object_set)
                {
                    print ("   Dealing with pulse $pulse_id ($from -> $to with val = $val\n");
                    print ("   ... From $from to $to with $val\n");
                }
            }

            $pulses_dealt_with {$pulse_id} = $is_object_set;
        }
        $pulse_id++;
    }
}

# Main
{
    get_all_objects ();
    while ($string =~ s/^([^X]+?XX)//)
    {
        my $thingo = $1;
        broadcast ($thingo);
        flip_flop ($thingo);
        conjunction ($thingo);
        progress_state ();
    }
}
