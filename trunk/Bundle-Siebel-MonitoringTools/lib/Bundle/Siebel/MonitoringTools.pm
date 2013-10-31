package Bundle::Siebel::MonitoringTools;

use 5.008009;
use strict;
use warnings;

our $VERSION = 0.03;

1;
__END__
=head1 NAME

Bundle::Siebel::MonitoringTools - bundle for installing all Perl dependencies for Siebel Monitoring Tools project

=head1 DESCRIPTION

This is a bundle to install all distributions that are required for the L<Siebel::Srvrmgr> API to work.

If you don't know what it is a Perl CPAN bundle, don't worry: just installing this distribution will take care of everything else.

L<Siebel::Srvrmgr> is an API to monitor Siebel On Premise CRM systems. You may find more information about in the project website.

=head2 EXPORT

None by default.

=head1 CONTENTS

    namespace::autoclean [0.13]
    Moose [2.0401]
    FSA::Rules [0.32]
    MooseX::Storage [0.33]
    Moose::Util::TypeConstraints [2.0402]
    MooseX::Params::Validate [0.15]
    MooseX::AbstractFactory [0.004000]
    MooseX::Singleton [0.27]
    MooseX::FollowPBP [0.05]
    Log::Log4perl [1.41]
    YAML::Syck [1.27]
    Config::Tiny [2.14]
    DBD::ODBC [1.43]
    DBI [1.623]
    Nagios::Plugin [0.36]
    Config::Tiny [2.14]
    DBD::ODBC [1.43]
    DBI [1.623]
    Term::Pulse [0.05]
    XML::Rabbit [0.3]
    Devel::CheckOS [1.71]
    Class::Data::Inheritable [0.08]
    Test::Class [0.36]
    Test::Memory::Cycle [1.04]
    Test::Most [0.25]
    Test::Pod [1.22]
    Test::Pod::Coverage [1.08]
	Test::Moose [2.0801]

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr>

=item *

L<CPAN>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<E<gt>

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

