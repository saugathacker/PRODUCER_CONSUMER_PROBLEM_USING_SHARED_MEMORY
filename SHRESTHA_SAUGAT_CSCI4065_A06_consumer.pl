#!/usr/bin/perl
use strict;
use warnings;
use IPC::ShareLite;
use Fcntl qw(:flock);

use constant CWID => 30099843;

#--------------------------------------------------------------------------
# Program:              SHRESTHA_SAUGAT_CSCI4065_A06_consumer.pl
# Author:               SHRESTHA SAUGAT
# Student Number:       30099843
# Organization: 		The University of Louisiana at Monroe
# Class:                CSCI 4065, Fall 2019
# Assignment:           Homework 6
# Due Date:             04, 20, 2020
#
# Description:          This program consumes until the buffer is empty. 
#                       It checks the value of counter to determnine whether 
#                       it should consume or wait.
#
# Honor Statement:      My signature below attests to the fact that I have
#                       neither given nor received aid on this project.
#
# X __SS___________________________________________________________________
#
#--------------------------------------------------------------------------

# the loop variable
my $i;

# size of the buffer
my $size;

# number of items to produce
my $number;

# number of filled slots in the buffer
my $count;

# points where in the buffer should it read the next item
my $pointer;

# counter for consumer
my $consumerCounter = 0;

# buffer to read the item 
my @buffer;

# array of items to go on the buffer
my @alphabhets = "A".."Z";

# temporary variable to hold the current item
my $element;

# create the sizeOfBuffer shared memory location and fetch the data
my $key = (CWID * 100000000) + 11111110;
my $sizeOfBuffer = IPC::ShareLite->new(-key=>$key) or die $!;
$sizeOfBuffer->lock(LOCK_SH);
$size = $sizeOfBuffer->fetch();
$sizeOfBuffer->unlock();

# create the numberOfData shared memory location and fetch the data
$key = (CWID * 100000000) + 11111111;
my $numberOfData = IPC::ShareLite->new(-key=>$key) or die $!;
$numberOfData->lock(LOCK_SH);
$number = $numberOfData->fetch();
$numberOfData->unlock();

# create the buffer index from 0 to value of sizeOfBuffer
for ($i = 0; $i < $size; $i++)
{
   $key = (CWID * 100000000) + 33333330 + $i;
   $buffer[$i] = IPC::ShareLite->new(-key=>$key) or die $!;
}

# create the out shared memory location
$key = (CWID * 100000000) + 22222221;
my $out     = IPC::ShareLite->new(-key=>$key) or die $!;

# create the counter shared memory location
$key = (CWID * 100000000) + 22222222;
my $counter = IPC::ShareLite->new(-key=>$key) or die $!;

#
# consumes until the numberOfData value
#
while($consumerCounter < $number){

    # fetch data from out shared memory location
    $out -> lock(LOCK_SH);
    $pointer = $out->fetch();
    $out -> unlock();

    # lock the counter exclusively and fetch the data
    $counter -> lock(LOCK_EX);
    $count = $counter->fetch();

    # when the buffer gets empty
    while($count == 0){

        #
        # display the empty message
        #
        print STDOUT "Consumer: Start\n";
        print STDOUT "Consumer: Buffer is empty ... waiting\n";
        print STDOUT "Consumer: buffer = [";
        for ($i = 0; $i < $size - 1; $i++)
        {
            print STDOUT $buffer[$i]->fetch() . ",";
        }
        print STDOUT $buffer[$i]->fetch() . "]\n";
        print STDOUT "Consumer: End\n";

        #unlock and lock the counter and fetch the changed value
        $counter-> unlock();
        $counter -> lock(LOCK_EX);
        $count = $counter->fetch();
    }

    # consumes next item and empty the pointer index in buffer
    $element = $alphabhets[($consumerCounter % 26)];
    $buffer[$pointer]->store("x");

    #
    # display the successfully wrote message
    #
    print STDOUT "Consumer: Start\n";
    print STDOUT "Consumer: Read " .$element." from the buffer[" .$pointer ."]\n";
    print STDOUT "Consumer: buffer = [";
    for ($i = 0; $i < $size-1; $i++)
    {
        print STDOUT $buffer[$i]->fetch() . ",";
    }
    print STDOUT $buffer[$i]->fetch() . "]\n";
    print STDOUT "Consumer: End\n";    

    #
    # increment or decrease the variables for next iteration
    #
    $pointer = ($pointer + 1) % $size;
    $consumerCounter++;
    $count--;

    #
    # store the shared variables
    #
    $out-> store($pointer);
    $counter->store($count);   
}

# unlock the counter
$counter->unlock();