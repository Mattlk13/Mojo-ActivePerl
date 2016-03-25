sub Mojo::Weixin::_synccheck{
    my $self = shift;
    if($self->_sync_running or $self->_synccheck_running){
        $self->_synccheck_running(0);
        $self->emit("synccheck_over");
        return;
    }
    $self->_synccheck_running(1);
    my $api = "https://". ($self->domain eq "wx2.qq.com"?"webpush2.weixin.qq.com":"webpush.weixin.qq.com") . "/cgi-bin/mmwebwx-bin/synccheck";
    my $callback = sub {
        my $data = shift;
        #window.synccheck={retcode:"0",selector:"0"}
        my($retcode,$selector) = $data=~/window\.synccheck=\{retcode:"([^"]+)",selector:"([^"]+)"\}/g;
        $self->_synccheck_running(0);
        $self->emit("synccheck_over",$retcode,$selector); 
    };
    my @query_string = (
        r           =>  $self->now(),
        skey        =>  $self->skey,
        sid         =>  $self->wxsid,
        uin         =>  $self->wxuin,
        deviceid    =>  $self->deviceid,
        synckey     =>  join("|",map {$_->{Key} . "_" . $_->{Val};} @{$self->sync_key->{List}}),
        _           =>  $self->now(),
    );
    $self->http_get($self->gen_url2($api,@query_string),{Referer=>"https://" .$self->domain . "/"},$callback);
}
1;
