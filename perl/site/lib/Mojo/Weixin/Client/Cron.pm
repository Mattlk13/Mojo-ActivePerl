package Mojo::Weixin::Client::Cron;
use POSIX qw(mktime);
sub add_job{
    my $self = shift;
    eval{ require Time::Piece;require Time::Seconds; } ;
    if($@){
        $self->error("调用add_job，请先安装模块 Time::Piece Time::Seconds 两个模块");
        return;
    }
    my($type,$nt,$callback) = @_;
    my $t = $nt;
    if(ref $callback ne 'CODE'){ 
        $self->die("设置的callback无效\n");
    }
    if(ref $nt eq "CODE"){
        $t = $nt->();
    }
    my $time = {};
    if(ref $t eq "HASH"){
        $time = $t;
    }
    else{
        my($hour,$minute,$second) = split /:/,$t;
        $second = 0 if not defined $second ;
        $time = {hour => $hour,minute => $minute,second=> $second};
    }
    my $delay;
    #my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
    my @now = localtime;
    my $now = mktime(@now);
    my @next = @{[@now]};
    for my $k (keys %$time){
          $k eq 'year'        ? ($next[5]=$time->{$k}-1900)
        : $k eq 'month'       ? ($next[4]=$time->{$k}-1)
        : $k eq 'day'         ? ($next[3]=$time->{$k})
        : $k eq 'hour'        ? ($next[2]=$time->{$k})
        : $k eq 'minute'      ? ($next[1]=$time->{$k})
        : $k eq 'second'      ? ($next[0]=$time->{$k})
        : next;
    } 

    my $next = mktime(@next);
    $now = localtime($now);
    $next = localtime($next);

    if($now >= $next){
        if( $time->{month} ) {
            $next->add_years(1);
        }
        elsif( $time->{day} ) {
            $next->add_months(1);
        }
        elsif( $time->{hour} ) {
            $next += ONE_DAY;
        }
        elsif( $time->{minute} ) {
            $next += ONE_HOUR;
        }
        elsif( $time->{second} ) {
            $next += ONE_MINUTE;
        }        
    }    
    
    $self->debug("[$type]下一次触发时间为：" . $next->strftime("%Y/%m/%d %H:%M:%S\n")); 
    $delay = $next - $now;
    my $rand_watcher_id = rand();
    $self->timer($delay,sub{
        eval{
            $callback->();
        };
        $self->error($@) if $@;
        $self->add_job($type,$nt,$callback);
    });
}
1;
