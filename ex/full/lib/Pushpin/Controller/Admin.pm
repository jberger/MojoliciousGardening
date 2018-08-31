package Pushpin::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller', -signatures;

# sample(main)
sub check ($c) {
  return 1 if $c->session('admin');
  my $conf = $c->app->config;
  my $pw = $c->req->url->to_abs->password;
  return $c->session(admin => 1) if $pw eq $conf->{admin};
  return $c->_basic_auth;
}

sub logout ($c) { $c->session(expires => 1)->_basic_auth }

sub _basic_auth ($c) {
  $c->res->headers->www_authenticate('Basic realm=pushpin');
  $c->rendered(401);
  return 0;
}
# end-sample

1;

