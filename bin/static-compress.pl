#!/usr/bin/perl

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;

use BST qw(config);

my $home = BST::config('home');
my $root_static = BST::config('root_static');
my $temp = BST::config('temp');

my $config = {
	groups => [
		{
			name => 'style',
			type => 'css',
			files => [
				'/css/reset.css',
				'/css/layout.css',
				'/css/globals.css',
				'/css/blocks.css',
			]
		},
		{
			name => 'common',
			type => 'css',
			files => [
				'/css/jquery-ui-themeroller.css',
				'/css/jquery-tablesorter.css',
				'/css/sidebar.css',
			]
		},
		{
			name => 'ie',
			type => 'css',
			files => [
				'/css/ie.css'
			]
		},
		{
			name => 'no-sidebar',
			type => 'css',
			files => [
				'/css/no-sidebar.css'
			]
		},
		{
			name => 'hidegreen',
			type => 'css',
			files => [
				'/css/hidegreen.css'
			]
		},
		{
			name => 'autocomplete',
			type => 'css',
			files => [
				'/css/jquery-autocomplete.css'
			]
		},
		{
			name => 'toc',
			type => 'css',
			files => [
				'/css/toc.css',
				'/css/jquery-autocomplete.css'
			]
		},
		{
			name => 'common',
			type => 'js',
			files => [
				'/js/jquery.js',
				'/js/jquery.bgiframe.min.js',
				'/js/jquery-ui.js',
				'/js/jquery.tooltip.js',
				'/js/jquery.form.js',
				'/js/jquery.namespace.js',
				'/js/jquery.tmpl.1.1.1.js',
				'/js/bs.common.js',
				'/js/bs.common.templates.js',
				'/js/jquery.tablesorter.js',
				'/js/tablesorter.js'
			]
		},
		{
			name => 'sidebar',
			type => 'js',
			files => [
				'/js/sidebar.js',
				'/js/sidebar.templates.js',
			]
		},
		{
			name => 'jstoc',
			type => 'js',
			files => [
				'/js/jquery.timers.js',
				'/js/jquery.json.js',
				'/js/jquery.tablednd.js',
				'/js/toc.autocomplete.js',
				'/js/toc.templates.js',
			]
		},
		{
			name => 'compose',
			type => 'js',
			files => [
				'/js/jquery.autocomplete.min.js',
				'/js/compose_templates.js',
				'/js/compose.js',
			]
		},
		{
			name => 'contacts-cart',
			type => 'js',
			files => [
				'/js/contacts-cart.js',
			]
		},
	],
	command => {
		'css' => "java -jar $home/yuicompressor-2.4.2/build/yuicompressor-2.4.2.jar %s -o $root_static/css/%s",
		'js' => "java -jar $home/yuicompressor-2.4.2/build/yuicompressor-2.4.2.jar %s -o $root_static/js/%s",
	}
};

for my $group (@{$config->{groups}}) {
	@{$group->{files}} = map {"$root_static$_"} @{$group->{files}};
	my $files = join " ", @{$group->{files}};

	my $groupfile = "$temp/$group->{name}.$group->{type}";

	system("cat $files > $groupfile");

	print sprintf $config->{command}->{$group->{type}}, "$temp/$group->{name}.$group->{type}", "$group->{name}.pack.$group->{type}";
	print "\n";

	system(sprintf $config->{command}->{$group->{type}}, $groupfile, "$group->{name}.pack.$group->{type}");
	unlink($groupfile);
}
