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
my %objects_num_outputs;
my %objects_outputs_names;
my %objects_inputs_names;
my %pulses;
my %pulses_dealt_with;
my $pulse_index = 0;
my %outputs;
my $string = "broadcaster->a,b,cXX%a->bXX%b->cXX%c->invXX&inv->aXX";
my $string = "broadcaster->aXX%a->inv,conXX&inv->bXX%b->conXX&con->outputXX";
my $string = "broadcaster->nr,tn,bx,nxXX%bz->rb,mfXX%tn->kb,mdXX%jp->psXX&kc->rxXX%dh->kb,ltXX%lt->cq,kbXX%ps->mf,fhXX%sr->nh,jhXX%jg->tvXX%bx->fd,jgXX%kg->fd,lgXX%fh->dpXX%hv->mf,bzXX%mj->zvXX%rz->gq,mfXX%tc->tdXX%bl->fdXX%lg->fd,qjXX%gq->hc,mfXX%kh->ckXX%td->kb,bmXX%cq->kx,kbXX%zv->tkXX&nh->kh,zv,tk,mj,nx,qm,phXX%tk->mcXX%nr->jp,mfXX%bt->rzXX%dj->nh,qmXX%qt->gb,fdXX%rb->mfXX&ph->kcXX%dp->bt,mfXX&kb->hn,md,tc,tn,mrXX%gb->fd,qsXX&vn->kcXX%rt->kg,fdXX%ck->nh,srXX%qx->rt,fdXX%jh->pt,nhXX%mr->rsXX%nx->nh,djXX%qm->mjXX&fd->bx,kt,jgXX%rs->kb,dhXX%bm->kb,mrXX%tv->qx,fdXX%pt->nhXX%qj->qt,fdXX%kx->kbXX%qs->bl,fdXX%md->hhXX%hh->tc,kbXX%mc->kh,nhXX%hc->hvXX&kt->kcXX&mf->fh,vn,bt,hc,nr,jpXX&hn->kcXX";
my $orig_string = $string;
my $round_number = 0;

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
        $objects_num_outputs {$name} = set_outputs ($name);
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
        #print ("$round_number: Make new object $2 that is $1\n");
        make_new_object ($2, $1);
    }
}

sub send_pulse
{
    my $from = $_ [0];
    my $to = $_ [1];
    my $pulse_low_or_high = $_ [2];
    my $reason = $_ [3];

    #print ("\n$round_number: Sending pulse ($pulse_index) from -> ($from to $to with value: $pulse_low_or_high) -- Reason for pulse = $reason\n");
    $pulses {$pulse_index} = $from . "X" . $to . "X" . $pulse_low_or_high;
    $pulses_dealt_with {$pulse_index} = 0;
    $pulse_index++;
}

sub broadcast
{
    my $input = $_ [0];

    if ($input !~ m/^broadcaster/)
    {
        return;
    }
    $input =~ s/^broadcaster->//;

    send_pulse ("button", "broadcast2", 0, "button");
    while ($input =~ s/^([a-z]+)(,|X)//)
    {
        my $object_name = $1;
        #print ("$round_number:Object named $object_name\n");
        send_pulse ("broadcast", $object_name, 0, "aaa");
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
    #print ("$round_number: set_inputs - Found $num_inputs for $input!!\n");
    return $num_inputs;
}

sub set_outputs
{
    my $input = $_ [0];
    my $output = $_ [1];
    my $copy_string = $orig_string;
    my $num_outputs = 0;

    while ($copy_string =~ s/XX([%&])($input)->([^,X]+?),/XX$1$2->/)
    {
        my $type = $1;
        my $input = $2;
        my $output = $3;
        $num_outputs++;
        #print ("   $round_number:  $input goes to $output\n");
        $objects_outputs_names {$input . $num_outputs} = $output;
    }
    while ($copy_string =~ s/XX([%&])($input)->([^,X]+?)XX//)
    {
        my $type = $1;
        my $input = $2;
        my $output = $3;
        $num_outputs++;
        #print ("   $round_number:  $input goes to $output\n");
        $objects_outputs_names {$input . $num_outputs} = $output;
    }

    #print ("$round_number:   set_outputs - Found $num_outputs for $input!!\n");
    return $num_outputs;
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
        #print ("$round_number:Flip-flop Object named $object_input goes to $object_output\n");
        send_pulse ($object_input, $object_output, $objects_value {$object_input}, "bbb");
    }
    
    while ($input =~ s/^([a-z]+)->([a-z]+)//)
    {
        my $object_input = $1;
        my $object_output = $2;
        #print ("$round_number:Flip-flop Object named $object_input goes to $object_output\n");
        send_pulse ($object_input, $object_output, $objects_value {$object_input}, "ccc");
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
        #print ("$round_number:Conjunction Object named $object_input goes to $object_output\n");
        send_pulse ($object_input, $object_output, $objects_value {$object_input}, "ddd");
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
            $value_was_set = 1;
            if ($objects_num_inputs {$obj_name} == 1)
            {
                #print ("$round_number:$obj_name is inverter.. Incoming value is: $val so new value is: ");
                if ($val == 0) { $objects_value{$obj_name} = 1; }
                elsif ($val == 1) { $objects_value{$obj_name} = 0; }
                #print ("$round_number:$objects_value{$obj_name}\n");
                $value_was_set = 1;
                
                # Sends any pulses!
                if ($objects_num_outputs {$obj_name} > 0)
                {
                    my $x = 1;
                    while (defined ($objects_outputs_names {$obj_name . $x}))
                    {
                        my $output_obj = $objects_outputs_names {$obj_name . $x};
                        send_pulse ($obj_name, $output_obj, $objects_value {$obj_name}, "eee");
                        $x++;
                    }
                }
            }
            else
            {
                #print ("$round_number:$obj_name is NAND: $val so new value is: ");

                my $x = 1;
                my $is_nand = 0;
                while (defined ($objects_inputs_names {$obj_name . $x}))
                {
                    my $val = get_val_of_object ($objects_inputs_names {$obj_name . $x});
                    #print (":  (is_nand?$is_nand) ii>  $obj_name - input $x is named " . $objects_inputs_names {$obj_name . $x} . " (val=$val) vs value=" . $objects_value {$objects_inputs_names {$obj_name . $x}});
                    if ($val == 0)
                    {
                        $is_nand = 1;
                    }
                    $x++;
                }
                $objects_value{$obj_name} = $is_nand;
                $value_was_set = 1;

                # Sends any pulses!
                if ($objects_num_outputs {$obj_name} > 0)
                {
                    my $x = 1;
                    while (defined ($objects_outputs_names {$obj_name . $x}))
                    {
                        my $output_obj = $objects_outputs_names {$obj_name . $x};
                        send_pulse ($obj_name, $output_obj, $objects_value {$obj_name}, "fff");
                        $x++;
                    }
                }
            }
        }
        if ($objects_type {$obj_name} eq "%")
        {
            #print ("$round_number:   -----> set_object_value: Flipflop.. ");
            #print (" :old_value=" . $objects_value{$obj_name});
            #print (" :input =  " . $val);
            if ($val == 0)
            {
                if ($objects_value{$obj_name} == 0) { $objects_value{$obj_name} = 1; }
                elsif ($objects_value{$obj_name} == 1) { $objects_value{$obj_name} = 0; }

                # Sends any pulses!
                if ($objects_num_outputs {$obj_name} > 0)
                {
                    my $x = 1;
                    while (defined ($objects_outputs_names {$obj_name . $x}))
                    {
                        my $output_obj = $objects_outputs_names {$obj_name . $x};
                        send_pulse ($obj_name, $output_obj, $objects_value {$obj_name}, "ggg");
                        $x++;
                    }
                }
            }
            else 
            { 
                #print (": (No change as high pulse incoming) ");
            }
            #print (": new_value = " . $objects_value{$obj_name} . "\n");
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
                #print ("$round_number:   Potentially dealing with pulse $pulse_id ($from -> $to with val = $val)\n");
                $is_object_set = set_object_value ($to, $val);
                if ($is_object_set)
                {
                    #print ("$round_number:   Dealing with pulse $pulse_id ($from -> $to with val = $val)\n");
                    #print ("$round_number:   ... From $from to $to with $val\n");
                }
            }

            $pulses_dealt_with {$pulse_id} = $is_object_set;
        }
        $pulse_id++;
    }

    while (defined ($pulses {$pulse_id}))
    {
        if ($pulses_dealt_with {$pulse_id} == 0)
        {
            return 0;
        }
    }
    return 1;
}

sub print_state
{
    my $i = $_ [0];
    #print ("$round_number:========$i --- ");
    my $key;
    foreach $key (sort (keys (%objects)))
    {
        #print ("$round_number:, ", $objects_type {$key}, "$key - ", $objects_value {$key});
    }
    #print ("$round_number:\n");
}

sub print_pulse_state
{
    my $i = $_ [0];
    my $key;
    my $high = 0;
    my $low = 0;
    foreach $key (sort (keys (%pulses)))
    {
        #print ("$round_number:$key , ", $pulses {$key}, "\n");
        if ($pulses {$key} =~ m/.*0$/)
        {
            $low++;
        }
        if ($pulses {$key} =~ m/.*1$/)
        {
            $high++;
        }
    }
    print ("$round_number:\nHigh = $high, $low = Low\n");
}

# Main
{
    print ("\n$string\n");
    get_all_objects ();
    for ($round_number = 0; $round_number < 1000; $round_number++)
    {
        $string = $orig_string;
        #print ("\n===============================\n");

        while ($string =~ s/^([^X]+?XX)//)
        {
            my $thingo = $1;
            #print "\n$round_number: Main! with $thingo\n";
            broadcast ($thingo);
            #flip_flop ($thingo);
            #conjunction ($thingo);
            while (!progress_state ())
            {
                #print ("$round_number:Progressing state..\n");
            }
        }
        #print_state ($round_number);
        if ($round_number == 0)
        {
            #print_pulse_state ();
        }
        #if ($round_number % 10 == 0)
        {
            print ("$round_number:Progressing state..\n");
        }
    }
    print_pulse_state ();
}
