package Siebel::Srvrmgr::Regexes;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(SRVRMGR_PROMPT LOAD_PREF_RESP LOAD_PREF_CMD CONN_GREET);

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

=cut

sub CONN_GREET {
    return
qr/^Siebel\sEnterprise\sApplications\sSiebel\sServer\sManager\,\sVersion.*/;
}

1;
