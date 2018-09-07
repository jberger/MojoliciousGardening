
#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::ByteStream 'b';

app->static->paths(['.']);

plugin 'RevealJS';

any '/' => {
  template => 'presentation',
  layout => 'revealjs',
  hljs_theme_url => 'github-gist.css',
};

helper markdown_fragment => sub {
  my ($c, $num) = @_;
  $c->render_to_string(inline => '<!-- .element: class="fragment" <% if (defined $num) { %> data-fragment-index="<%= $num %>" <% } %> -->', num => $num);
};

helper section_group => sub {
  my ($c, $transition, @sections) = @_;
  my @out;
  for my $section (@sections) {
    my @class;
    push @class, "$transition-in"  unless $section eq $sections[0];
    push @class, "$transition-out" unless $section eq $sections[-1];
    push @out, $c->t(section =>  ('data-transition' => join(' ', @class)), $section);
  }
  return b join("\n", @out);
};


app->start;

