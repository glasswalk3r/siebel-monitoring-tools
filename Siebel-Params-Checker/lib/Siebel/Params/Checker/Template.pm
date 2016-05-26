package Siebel::Params::Checker::Template;
use warnings;
use strict;
use Exporter qw(import);
use Carp;
use Template 2.26;
# VERSION
our @EXPORT_OK = qw(gen_report);
our $TEMPLATE;

sub gen_report {
    my ( $comp_name, $header_ref, $rows_ref, $output_path ) = @_;
    my $template = Template->new(
        {
            ENCODING   => 'utf8',
            TRIM       => 1,
            OUTPUT     => $output_path,
            PRE_CHOMP  => 1,
            POST_CHOMP => 1,
        }
    );
    unless (defined($TEMPLATE))
    {
        local $/ = undef;
        $TEMPLATE = <DATA>;
        close(DATA);
    }
    my $vars = {
        title   => "Report of parameters of $comp_name component",
        header  => $header_ref,
        rows    => $rows_ref,
        version => $VERSION
    };

    $template->process( \$TEMPLATE, $vars )
      or confess $template->error();

    return 1;
}

1;

__DATA__
<!DOCTYPE html>
<html><head>
<!-- CSS borrowed from https://www.smashingmagazine.com/2008/08/top-10-css-table-designs/ -->
<style>
body
{
	line-height: 1.6em;
}
#box-table-a
{
	font-family: "Lucida Sans Unicode", "Lucida Grande", Sans-Serif;
	font-size: 12px;
	margin: 45px;
	width: 480px;
	text-align: left;
	border-collapse: collapse;
}
#footer {
	font-family: "Lucida Sans Unicode", "Lucida Grande", Sans-Serif;
	font-size: 10px;
}
#box-table-a th
{
	font-size: 13px;
	font-weight: normal;
	padding: 8px;
	background: #b9c9fe;
	border-top: 4px solid #aabcfe;
	border-bottom: 1px solid #fff;
	color: #039;
}
#box-table-a td
{
	padding: 8px;
	background: #e8edff; 
	border-bottom: 1px solid #fff;
	color: #669;
	border-top: 1px solid transparent;
    text-align:center; 
    vertical-align:middle;
}
#first-left
{
	font-size: 13px;
	font-weight: bold;
	padding: 8px;
	background: #d0dafd;
	border-top: 4px solid #aabcfe;
	border-bottom: 1px solid #fff;
    text-align:left !important; 
	color: #039;
}
#box-table-a tr:hover td
{
	background: #d0dafd;
	color: #339;
}
</style>
<title>[% title %]</title>
</head>
<body>
<h1>[% title %]</h1>
<table id="box-table-a">
<thead>
<tr>
[% FOREACH column IN header %]
<th scope="col">[% column %]</th>
[% END %]
</tr>
</thead>
<tbody>
[% FOREACH row IN rows %]
<tr>
[% first = 1 %]
[% FOREACH column IN row %]
[% IF first %]
<td id="first-left">[% column %]</td>
[% first = 0 %]
[% ELSE %]
<td>[% column %]</td>
[% END %]
[% END %]
</tr>
[% END %]
</tbody>
</table>
<hr>
<p id="footer">Generated with Siebel::Params::Checker version [% version %].</p>
</body>
</html>
