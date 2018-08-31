
#!/usr/bin/env perl

use Mojolicious::Lite;

plugin 'RevealJS';

push @{ app->static->paths }, '.';

any '/' => { template => 'presentation', layout => 'revealjs' };

helper markdown_fragment => sub {
  my ($c, $num) = @_;
  $c->render_to_string(inline => '<!-- .element: class="fragment" <% if (defined $num) { %> data-fragment-index="<%= $num %>" <% } %> -->', num => $num);
};

app->start;

