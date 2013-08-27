package Siebel::Srvrmgr::Regexes;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK =
  qw(SRVRMGR_PROMPT LOAD_PREF_RESP LOAD_PREF_CMD CONN_GREET SIEBEL_ERROR ROWS_RETURNED);

=pod

=head1 NAME

Siebel::Srvmrgr::Regexes - common regexes used by Siebel::Srvrmgr

=head1 SYNOPSIS

	use Siebel::Srvrmgr::Regexes qw(SRVRMGR_PROMPT);

	if($line =~ /SRVRMGR_PROMPT/) {
	
		#do something
	
	}

=head1 DESCRIPTION

This modules exports several pre-compiled regular expressions by demand.

=head1 EXPORTS

=head2 SRVRMGR_PROMPT

Regular expression to match the C<srvrmgr> prompt, with or without any command. It will match the server name, if included.

=cut

sub SRVRMGR_PROMPT {

    return qr/^srvrmgr(\:\w+)?>\s(.*)?$/;

}

=pod

=head2 LOAD_PREF_RESP

Regular expression to match the C<load preferences> response once the command is submitted.

=cut

sub LOAD_PREF_RESP { return qr/^(srvrmgr(\:\w+)?>)?\s?File\:\s.*\.pref$/; }

=pod

=head2 LOAD_PREF_CMD

Regular expression to match the C<load preferences> command when submitted.

=cut

sub LOAD_PREF_CMD { return qr/^(srvrmgr(\:\w+)?>)?\s?load preferences$/; }

=pod

=head2 CONN_GREET

Regular expression to match the first line submitted by a Siebel enterprise when the C<srvrmgr> connects to it. It will look like something like this:

	Siebel Enterprise Applications Siebel Server Manager, Version 8.0.0.7 [20426] LANG_INDEPENDENT

It is a known issue that UTF-8 data with BOM character will cause this regular expression to B<not> match.

=cut

sub CONN_GREET {
    return
qr/^Siebel\sEnterprise\sApplications\sSiebel\sServer\sManager\,\sVersion.*/;
}

=pod

=head2 ROWS_RETURNED

This regular expression should match the last but one line returned by a command, for example:

    136 rows returned.

This line indicated how many rows were returned by a command.

=cut

sub ROWS_RETURNED {

    return qr/^\d+\srows?\sreturned\./;

}

=pod

=head2 SIEBEL_ERROR

This regular expression should match errors from Siebel like, for example:

	SBL-SSM-00003: Error opening SISNAPI connection.
	SBL-NET-01218: The connection was refused by server siebappdev.  No component is listening on port 49170.

The regular expression matches the default error code.

=cut

sub SIEBEL_ERROR {

    return qr/^SBL\-\w{3}\-\d+/;

}

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
