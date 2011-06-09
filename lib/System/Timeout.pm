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

our $VERSION = '0.01';

sub system
{
    return system_ex(@_);
}

sub system_ex
{
    return 0 unless $_[0];
    my $r = 0;
    my $start = time;
    unless ($_[0] =~ /^\d+$/)
    {
        $r = CORE::system(@_);
    }
    else
    {
        my $timeout_secs = shift @_;
        eval
        {
            my $child;
            my $status = 0;
            local %SIG;
            $SIG{ALRM} = sub {alarm 0; $SIG{CHLD} = sub{waitpid(-1,WNOHANG);}; kill KILL=> $child; CORE::die "child_timeout";};
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
            elsif ($@ =~ /child_timeout/ or $@ =~ /cannot_fork/)
            {
                $r = -1;
            }
            else
            {
                $r = -1;
            }
        }
    }
    my $end = time;
    my $timecost = $end - $start;
    System::Timeout::log('system', $r, $timecost, $$, @_);
    System::Timeout::log('system_fail', $r, $timecost, $$, @_) unless $r == 0 ;
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

System::Timeout - Extend <system()> to Allow Timeout after specified seconds


=head1 SYNOPSIS

  use System::Timeout qw(system system_ex);
  system("3", "sleep 9");
  system_ex("3", "sleep 9");

  % timeout --timeout=3 "sleep 9"  #Run command "Sleep 9" and timeout after 3 seconds


=head1 DESCRIPTION

This module extends <system()> to allow timeout after the specified seconds and log the command in file.

This can be useful when invoking <system()> in daemon.

This also include a cli tool "timeout" which can be easily used to force command exit after specified seconds.

This module is based on core function <fork()> and <exec()>.


=head1 AUTHOR

Written by Chen Gang, yikuyiku.com@gmail.com


=head1 COPYRIGHT

Copyright (c) 2011 Chen Gang.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


