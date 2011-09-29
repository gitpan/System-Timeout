package System::Timeout;
use strict;
use warnings;
use POSIX qw(strftime WNOHANG);
use Fcntl qw(:flock);
use Socket;
use vars qw(@ISA @EXPORT_OK $VERSION);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(system system_ex log);

our $VERSION = '0.04';

sub system
{
    return system_ex(@_);
}

sub system_log
{
    my $start = time;
    my $r = system_ex(@_);
    my $end = time;
    my $timecost = $end - $start;
    System::Timeout::log('system', $r, $timecost, $$, @_);
    System::Timeout::log('system_fail', $r, $timecost, $$, @_) unless $r == 0 ;
    return $r;
}

sub system_ex
{
    return 0 unless $_[0];
    my $r = 0;
    my $timeout_secs;
    if ($_[0] =~ /^\d+$/)
    {
        $timeout_secs = shift @_;
    }
    else
    {
        $timeout_secs = 999999999;
    }

    eval
    {
        my $child;
        my $status = 0;
        local %SIG;
        $SIG{ALRM} = sub {alarm 0; $SIG{CHLD} = sub{waitpid(-1,WNOHANG);}; kill KILL=> $child; CORE::die "child_timeout";};
        $SIG{TERM} = sub {alarm 0; $SIG{CHLD} = sub{waitpid(-1,WNOHANG);}; kill KILL=> $child; CORE::die "parent_killed";};
        $SIG{CHLD} = sub {alarm 0; waitpid(-1,WNOHANG); $status = -1 unless $? == 0; CORE::die "child_exit[$status]";};
        alarm $timeout_secs;
        defined($child = fork) or CORE::die "cannot_fork";
        if($child == 0)
        {
            exec(@_);
        }
        sleep ($timeout_secs + 9);
    };
    if ($@)
    {
        if ($@ =~ /child_exit/)
        {
            my ($child_exit_status) = $@ =~ /child_exit\[(\-?\d+)\]/;
            $r = $child_exit_status;
        }
        elsif ($@ =~ /parent_killed/)
        {
            kill TERM => $$;
            $r = -1;
        }
        elsif ($@ =~ /child_timeout/ or $@ =~ /cannot_fork/)
        {
            $r = -1;
        }
        else
        {
            $r = -1;
        }
    }
    return $r;
}

sub log
{
    return 0 unless $_[0];
    my $logtype = shift;
    my $date_str = strftime "%Y%m%d", localtime;
    my $log = strftime "%Y-%m-%d %H:%M:%S", localtime;
    foreach (@_) 
    {
        my $str = $_;
        $str =~ s/[\t\r\n]//g;
        $log .= "\t".$str;
    }
    $log .= "\n";

    mkdir "log",0644 unless -d "log";
    my $logfile = "log/".$logtype."_".$date_str.".log";

    open my $fh,">>",$logfile or return -1;
    flock $fh,LOCK_EX;
    print $fh $log;
    flock $fh,LOCK_UN;
    close $fh;
}

1;

__END__

=head1 NAME

System::Timeout - extend system() to allow timeout after specified seconds


=head1 SYNOPSIS

  use System::Timeout qw(system system_ex system_log);
  system_ex("sleep 9"); # invoke CORE::system, will not timeout exit
  system_ex("3", "sleep 9"); # timeout exit after 3 seconds

  system("3", "sleep 9"); # just an alias for system_ex, for peoples who want to overlay the Perl build-in

  system_log("3", "sleep 9"); # log the command in file



  % timeout --timeout=3 "sleep 9"  #Run command "Sleep 9" and timeout after 3 seconds


=head1 DESCRIPTION

This module extends system() to allow timeout after the specified seconds.
This also include a cli tool "timeout" which can be easily used to force command exit after specified seconds.
This module is based on core function fork(), exec(), sleep().
These can be useful when invoking system() in daemon.


=head1 AUTHOR

Written by ChenGang, yikuyiku.com@gmail.com


=head1 COPYRIGHT

Copyright (c) 2011 ChenGang.
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
