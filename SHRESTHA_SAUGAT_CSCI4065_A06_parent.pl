#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long 'HelpMessage';
use IPC::ShareLite;
use Fcntl qw(:flock);

use constant CWID => 30099843;
use constant DEBUG => 0;
use constant PRODUCER => 0;
use constant CONSUMER => 1;

#--------------------------------------------------------------------------
# Program:              SHRESTHA_SAUGAT_CSCI4065_A06_parent.pl
# Author:               SHRESTHA SAUGAT
# Student Number:       30099843
# Organization: 		The University of Louisiana at Monroe
# Class:                CSCI 4065, Fall 2019
# Assignment:           Homework 6
# Due Date:             04, 20, 2020
#
# Description:          This program forks the Producer and Consumer process. 
#                       It also creates shared memory location for the child 
#                       process to use and synchronize.
#
# Honor Statement:      My signature below attests to the fact that I have
#                       neither given nor received aid on this project.
#
# X __SS___________________________________________________________________
#
#--------------------------------------------------------------------------

# for loop variable
my $i;

# The producer and consumer will write data to and read data from the buffer.
my @buffer = ();

# the data placed in the buffer
my $producerData = 65; # Character 'A'
my $consumerData;

# generic process id
my $gpid;

# producer process id
my $ppid;

# consumer process id
my $cpid;

# 0 means it is the producers turn; 1 means it is the consumers turn
my $turn = 0; 

# 0 means producer is not done; 1 means producer is done
# 0 means consumer is not done; 1 means consumer is done
my $producerDone = 0; 
my $consumerDone = 0; 

# Keep track of how many items the producer has written and the consumer has read
# The value starts a 0 and will be increment upto numberOfData
my $producerCount = 0;
my $consumerCount = 0;

my $sob = 0;
my $nod = 0;


# create the sizeOfBuffer shared memory location
my $key = (CWID * 100000000) + 11111110;
my $sizeOfBuffer = IPC::ShareLite->new(-key=>$key, -create=>'yes', -destroy=>'yes') or die $!;
$sizeOfBuffer->store(10);


# create the numberOfData shared memory location
$key = (CWID * 100000000) + 11111111;
my $numberOfData = IPC::ShareLite->new(-key=>$key, -create=>'yes', -destroy=>'yes') or die $!;
$numberOfData->store($sizeOfBuffer->fetch() + 1);


# create the in shared memory location
$key = (CWID * 100000000) + 22222220;
my $in      = IPC::ShareLite->new(-key=>$key, -create=>'yes', -destroy=>'yes') or die $!;


# create the out shared memory location
$key = (CWID * 100000000) + 22222221;
my $out     = IPC::ShareLite->new(-key=>$key, -create=>'yes', -destroy=>'yes') or die $!;


# create the counter shared memory location
$key = (CWID * 100000000) + 22222222;
my $counter = IPC::ShareLite->new(-key=>$key, -create=>'yes', -destroy=>'yes') or die $!;


# initialize in, out, and counter
$in->store(0);
$out->store(0);
$counter->store(0);

#
# Hello!
#

print STDOUT "  Parent: Start\n";


#--------------------------------------------------------------------------
# The user can supply a value for numberOfData on the command line
#   by typing --n INTEGER or by typing --numberOfData INTEGER
#
# The user can supply a value for sizeOfBuffer on the command line
#   by typing --s INTEGER or by by typing --sizeOfBuffer INTEGER
#--------------------------------------------------------------------------

GetOptions ("help"=>sub{HelpMessage(0)}, "numberOfData=i"=>\$nod, "sizeOfBuffer=i"=>\$sob,)
or HelpMessage(1);

#---------- HelpMessage ----------
=head1 NAME

   parent - DO SOMETHING

=head1 SYNOPSIS

   --help,--h       Print this help
   --number,--n     Number of data to produce and consume
   --size,--s       Size of buffer

=head1 VERSION

   1.0

=cut
#---------- HelpMessage ----------


#
# if the user entered command line arguments 
# then lets figure out the values for sizeOfBuffer and numberOfData
#

$sizeOfBuffer->store($sob);
$numberOfData->store($nod);

if ($sob <= 0 && $nod <= 0) 
{ 
   $sizeOfBuffer->store(10);
   $numberOfData->store($sizeOfBuffer->fetch() + 1); 
}
elsif ($sob <= 0 && $nod > 0) 
{
   $sizeOfBuffer->store(10); 
}
elsif ($sob > 0 && $nod <= 0) 
{ 
   $numberOfData->store($sizeOfBuffer->fetch() + 1); 
}

print STDOUT "  Parent: The size of the buffer is " . $sizeOfBuffer->fetch . "\n";
print STDOUT "  Parent: The number of data writen by the producer and read by the consumer is " . $numberOfData->fetch() . "\n";

#
# intilize the buffer indexes to 'x'
#
print STDOUT "  Parent: buffer = [";
for ($i = 0; $i < $sizeOfBuffer->fetch()-1; $i++)
{
   $key = (CWID * 100000000) + 33333330 + $i;
   $buffer[$i] = IPC::ShareLite->new(-key=>$key, -create=>'yes', -destroy=>'yes') or die $!;
   $buffer[$i]->store("x");
   print STDOUT $buffer[$i]->fetch() . ",";
}
$key = (CWID * 100000000) + 33333330 + $i;
$buffer[$i] = IPC::ShareLite->new(-key=>$key, -create=>'yes', -destroy=>'yes') or die $!;
$buffer[$i]->store("x");
print STDOUT $buffer[$i]->fetch() . "]\n";


#
# create producer child 
#

$ppid = fork();
die if not defined $ppid;

if ($ppid == 0)
{
   exec('./SHRESTHA_SAUGAT_CSCI4065_A06_producer.pl');
   exit;
}


#
# create consumer child 
#

$cpid = fork();
die if not defined $cpid;

if ($cpid == 0)
{
   exec('./SHRESTHA_SAUGAT_CSCI4065_A06_consumer.pl');
   exit;
}


#
# Wait for producer and consumer children to terminate
#

$gpid = wait();
if ($gpid == $ppid)
{
   print STDOUT "  Parent: Producer Ended\n";
   $gpid = wait();
   print STDOUT "  Parent: Consumer Ended\n";
}
else
{
   print STDOUT "  Parent: Consumer Ended\n";
   $gpid = wait();
   print STDOUT "  Parent: Producer Ended\n";
}

#
# Clean up our mess
#

$sizeOfBuffer->destroy(1);
$numberOfData->destroy(1);
$in->destroy(1);
$out->destroy(1);
$counter->destroy(0);
for ($i = 0; $i < $sizeOfBuffer->fetch(); $i++)
{
   $buffer[$i]->destroy(1);
}


#
# Good Bye!
#

print STDOUT "  Parent: End\n";

exit;
