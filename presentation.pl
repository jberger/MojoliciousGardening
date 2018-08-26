
#!/usr/bin/env perl

use Mojolicious::Lite;

plugin 'RevealJS';

any '/' => { template => 'presentation', layout => 'revealjs' };

helper 'markdown_slide' => sub {
  my ($c, @args) = @_;
  return $c->tag(section => data => { markdown => undef } => sub {
    return $c->tag(script => (type => 'text/template') => @args);
  });
};

app->start;

