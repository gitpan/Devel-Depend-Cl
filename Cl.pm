
package Devel::Depend::Cl;

use 5.006;
use strict ;
use warnings ;
use Carp ;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(PreprocessorDepend);
our $VERSION = '0.01';

#------------------------------------------------------------------------------------------------

sub Depend
{
my $cpp                     = shift || 'cl.exe' ;
my $file_to_depend          = shift || confess "No file to depend!\n" ;
my $switches                = shift ;
my $include_system_includes = shift ;
my $add_child_callback      = shift ;
my $display_cpp_output      = shift ;

my $command = "$cpp -nologo -showIncludes -Zs $switches $file_to_depend" ;

my $errors ;

my @cpp_output = `$command` ;
$errors = "command: $command : $!" if $! ;

for(@cpp_output)
	{
	$errors .= $_ if(/No such file or directory/) ;
	}
	
@cpp_output = grep {/^\QNote: including file:/} @cpp_output ;

@cpp_output = map { s|\\|/|g; $_ } @cpp_output ;

unless($include_system_includes)
{
	my @includes = split(';', $ENV{INCLUDE});
	for my $include (@includes)
	{
		$include =~ s|\\|/|g;
		@cpp_output = grep { ! m~^\QNote: including file:\E\s+\Q$include~i} @cpp_output ;
	}

}
	
my %node_levels ;
my %nodes ;
my %parent_at_level = (0 => {__NAME => $file_to_depend}) ;

for(@cpp_output)
	{
	print STDERR $_ if($display_cpp_output) ;

	chomp ;
	my ($level, $name) = /^\QNote: including file:\E(\s+)(.*)/ ;

	$level = length $level ;
	
	my $node ;
	unless (exists $nodes{$name})
		{
		$nodes{$name} = {__NAME => $name} ;
		}
		
	$node = $nodes{$name} ;
		
	$node_levels{$level}{$name} = $node unless exists $node_levels{$level}{$name} ;
	
	$parent_at_level{$level} = $node ;
	
	my $parent = $parent_at_level{$level - 1} ;
	
	unless(exists $parent->{$name})
		{
		$parent->{$name} = $node ;
		$add_child_callback->($parent->{__NAME} => $name) if(defined $add_child_callback) ;
		}
	}

return((! defined $errors), \%node_levels, \%nodes, $parent_at_level{0}, $errors) ;
}

*PreprocessorDepend = \&Depend;

#-------------------------------------------------------------------------------

1 ;


=head1 NAME

Devel::Depend::Cl - Perl extension for extracting dependency trees from c files with B<'cl'> compiler

=head1 SYNOPSIS

 use Devel::Depend::Cl;
  
 my ($success, $includ_levels, $included_files) = Devel::Depend::Cl::Depend
 							(
 							  undef
 							, '/usr/include/stdio.h'
 							, '' # switches to cpp
 							, 0 # include system includes
 							) ;

=head1 DESCRIPTION

I<Depend> calls B<cl> (as a c pre-processor) to extract all the included files. If the call succeds,
I<Depend> returns a list consiting of the following items:

This code is based on Devel::Depend::Cpp.


=over 2

=item [1] Success flag set to 1

=item [2] A reference to a hash where the included files are sorted perl level. A file can appear simulteanously at different levels

=item [3] A reference to a hash representing an include tree

=back

If the call faills, I<Depend> returns a list consiting of the following items:

=over 2

=item [1] Success flag set to 0

=item [2] A string containing an error message

=back


I<Depend> takes the following arguments:

=over 2

=item 1/ the name of the 'cl.exe' binary to use. undef to use the first 'cl.exe' in your path

=item 2/ The name of the file to depend

=item 3/ A string to be passed to b<cl>, ex: '-DDEBUG'

=item 4/ A boolean indicating if the system include files should be included in the result (anything in $ENV{INCLUDE})

=item 5/ a sub reference to be called everytime a node is added (see I<depender.pl> in Devel::Depend::Cpp for an example)

=item 6/ A boolean indicating if the output of B<cl> should be dumped on screen

=back

=head2 EXPORT

None .

=head1 DEPENDENCIES

B<cpp>.

=head1 AUTHOR

Emil Jansson based on Devel::Depend::Cpp.

=head1 SEE ALSO

B<Devel::Depend::Cpp> and B<PBS>.

=cut

