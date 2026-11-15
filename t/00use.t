use strict;

use Test::More qw(no_plan);

my @modules = qw~
Catalyst::Runtime
Catalyst::Plugin::ConfigLoader
Catalyst::Plugin::Static::Simple
Catalyst::Action::RenderView
Catalyst::Plugin::Session
Catalyst::Plugin::Session::Store::FastMmap
Catalyst::Plugin::Session::State::Cookie
YAML
JSON
DBIx::Class::Schema::Loader
Class::Singleton
Catalyst::View::JSON
Catalyst::Controller::FormBuilder
Log::Dispatch
Class::Factory
Catalyst::View::Download
Template::Plugin::XML::Escape
Image::Magick
Smart::Comments
Image::Magick::Thumbnail::PDF
Proc::Daemon
DateTime::Format::Pg
MIME::Lite
MIME::Base64
Log::Dispatch
Log::Dispatch::File::Stamped
Log::Dispatch::Config
Catalyst::Plugin::Log::Dispatch
Tie::STDERR
Template::Plugin::DateTime
Template::Plugin::DateTime::Format
Catalyst::Plugin::Unicode
HTML::Template
Catalyst::View::TT
Email::Valid
Locale::US
Catalyst::Model::DBIC::Schema
Business::OnlinePayment
~;

foreach (@modules) { use_ok($_) }

=a
DBIx::Class::Cursor::Cached
=cut

# Need versions!
use_ok('Template', 2.19);

1;
