use strict;
use Socket;
my $hostName = shift;
my ($name,$aliases,$addrtype,$length,@addrs) = gethostbyname($hostName);
foreach my $item (@addrs) {
   my ($a,$b,$c,$d) = unpack('C4',$item);
   if (!(($a == '127') && ($b == '0') && ($c == '0') && ($d == '1'))) {
       print "$a.$b.$c.$d\n";
   }
}
exit 0;
