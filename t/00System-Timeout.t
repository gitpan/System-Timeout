use Test::More tests => 5;
BEGIN { use_ok('System::Timeout') };
use System::Timeout qw(system system_ex);

my $s = time;
my $r = system(3, "sleep 9");
my $time_spend = time - $s;
ok($time_spend < 5, "system timeout killed");
#ok($r != 0, "system timeout exit code");

$s = time;
$r = system_ex(3, "sleep 9");
$time_spend = time - $s;
ok($time_spend < 5, "system_ex timeout killed");
#ok($r != 0, "system_ex timeout exit code");

$s = time;
$r = system(5, "perl -e 'sleep 1'");
$time_spend = time - $s;
ok($time_spend < 3, "system no timeout exec");
#ok($r == 0, "system timeout exit code");

$s = time;
$r = system_ex(5, "perl -e 'sleep 1'");
$time_spend = time - $s;
ok($time_spend < 3, "system_ex no timeout exec");
#ok($r == 0, "system_ex timeout exit code");
