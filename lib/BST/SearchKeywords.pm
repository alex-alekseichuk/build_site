package BST::SearchKeywords;

use strict;
use warnings;

use Lingua::Stem;
use Data::Dumper;

=head2 tokenize_category_search

get tokens for category search
@param search string
@return reference to array of tokens

=cut

sub tokenize_category_search {
    my $tokens = [];
    my $composite_tokens = [];
    return search_tokenize($tokens, $composite_tokens, lc(shift), $BST::SearchKeywords::CATEGORY_SEARCH_OPTS );
}

=head2 tokenize_manufacturer_search

get tokens for manufacturer search
@param search string
@return reference to array of tokens

=cut

sub tokenize_manufacturer_search {
    my $tokens = [];
    my $composite_tokens = [];
    return search_tokenize($tokens, $composite_tokens, lc(shift), {
		  same_as_space => ','
		, word_trim_chars => './\''
		, inword_break_chars => '\./&\-'
	} );
}

=head2 tokenize_product_search

get tokens for product search
@param search string
@param term string 'and' or 'or'
@return reference to array of tokens

=cut

sub tokenize_product_search {
    my $string = shift;
    my $term = shift || 'and';
    my $tokens = [];
    my $composite_tokens = [];

    search_tokenize($tokens, $composite_tokens, lc($string), $BST::SearchKeywords::PRODUCT_SEARCH_OPTS );

	my (%seen, @unique, @composite_unique);
    my $unique = [];
    my $composite_unique = [];

    if ($term eq 'or') {
        $unique = [ grep { (!($seen{$_}++)) && length($_) > 1 } @$tokens ];
        $composite_unique = [ grep { (!($seen{$_}++)) && length($_) > 1 } @$composite_tokens ];
    	(my $word_chars_only = lc $string) =~ s/\W//g;
	    push(@$composite_unique, $word_chars_only) if ( (!($seen{$word_chars_only}++)) && length($word_chars_only) > 1 );
    } else {
        $unique = [ grep { !($seen{$_}++) } @$tokens ];
        $composite_unique = [ grep { !($seen{$_}++) } @$composite_tokens ];
        (my $word_chars_only = lc $string) =~ s/\W//g;
        push(@$composite_unique, $word_chars_only) unless $seen{$word_chars_only}++;
    }
	return ($unique, $composite_unique);
}

=head2 tokenize_astm_search

it uses regular product search
@param search string
@return astm keyword

=cut

sub tokenize_astm_search {
    my $string = shift;

#    $string =~ s/[^A-Z0-9]//gis;
#    return $string;

    # old implementation
    $string =~ s|\s+||g;
    return tokenize_product_search($string);
}




our $PRODUCT_SEARCH_OPTS = 
{
    column_names => ['product_name', 'mfg_product_id'],
    tokenize_proc => \&tokenize,
    # done first. these chars are treated as word separators.
    same_as_space => '_:,!"#%()\|\*\+\-/',

    # the first of the following that matches is used (though with recursive calls
    # the others will apply also).
    # eliminate these entirely from anywhere in a token
    inword_collapse_chars => '&\.\'\-',
    # eliminate these entirely from the beginning or end of tokens
    word_trim_chars => '\.',
    # treat as separator but *also* put the whole word in
    # inword_break_chars => '&\.\'\-/',
    # transitions from digit to non_digit or non digit to digit
    # if true, the use both the whole token as well as the split one 
    #break_on_digit_non_digit => 1,
    #break_on_non_digit_digit => 1,

    # done after tokenization above
    # stem_lexical simply puts all substrings down to ones of length 3 in.
    # stem_lingual calls Lingua::Stem::stem, which removes any morphological suffixes. 
    stemming_proc => \&stem_lexical,
    stem_length => 3,
};

our $CATEGORY_SEARCH_OPTS =
{
  column_names => ['title']
  , tokenize_proc => \&tokenize
  , same_as_space => '\W'
#  , stemming_proc => \&stem_lingual
  , stemming_proc => \&stem_lexical
  , stem_length => 3
};

sub search_tokenize {
    my ($words, $composite_words, $string, $args) = @_;
    # my $nargs = {%$args};
    # $nargs->{stemming_proc} = \&BSUtil::stem_lingual;
    tokenize($words, $composite_words, $string, $args);

    my $tokens = stem_lingual($words, $args);
    my $composite_tokens = stem_lingual($composite_words, $args);
    return ($tokens, $composite_tokens);
}


# called directly at index time, indirectly at search time
sub tokenize {
    my ($words, $composite_words, $string, $args) = @_;
    return unless $string;
    $args ||= {};

    ####
    # convert some chars to space; trim spaces; break on spaces
    ####

    my $origstring = $string;
    my $sas = $args->{same_as_space};
    $string =~ s/[$sas]/ /g if $sas;
    $string =~ s/^\s*//;
    $string =~ s/\s*$//;

    ####
    # break on white-space
    ####

    if ($string =~ m/\s/) {
        my @word_array = split(/\s+/, $string);

        foreach my $token (@word_array) {
            tokenize($words, $composite_words, $token, $args);
        }

    	# also push on the whole thing
	    if (1) {
	        my $mushed = $string;
	        $mushed =~ s/\s//g;
	        #push(@word_array, $mushed);
            tokenize($composite_words, $composite_words, $mushed, $args);
	    }

    }

	####
	# collapse some words:
	#   T-45 --> t45
	####

    elsif ($args->{inword_collapse_chars} && $string =~ /([$args->{inword_collapse_chars}])/) {
	$string =~ s/[$args->{inword_collapse_chars}]//g;
        tokenize($words, $composite_words, $string, $args);
    }

    ####
    # trim chars from start or end of word
    #   inc. --> inc
    #   'n   --> n
    ####

    elsif ($args->{word_trim_chars} && $string =~ /^(.*)[$args->{word_trim_chars}]$/) {
        tokenize($words, $composite_words, $1, $args);
    }
    elsif ($args->{word_trim_chars} && $string =~ /^[$args->{word_trim_chars}](.*)$/) {
        tokenize($words, $composite_words, $1, $args);
	}

	####
    # split words on special characters
    #   v.o.c --> v, o, c, voc
    ####

    elsif ($args->{inword_break_chars} && $string =~ /([$args->{inword_break_chars}])/) {
        my $break_char = $1 eq '.' ? '\.' : $1;
        my @array = split /$break_char/, $string;
        $string =~ s/$break_char//g;
        tokenize($words, $composite_words, $string, $args);
        foreach my $token (@array) { tokenize($words, $composite_words, $token, $args) }
    }

    # ABC123 --> abc123, abc, 123

    elsif ($args->{break_on_digit_non_digit} && $string =~ m/^(\D+)(\d+)$/ ) {
        push(@$words, $1);
        push(@$words, $2);
        push(@$words, $string);
    }

    # 101HW --> 101hw, 101, hw

    elsif ($args->{break_on_non_digit_digit} && $string =~ m/^(\d+)(\D+)$/ ) {
        push(@$words, $1);
        push(@$words, $2);
        push(@$words, $string);
    }

    ####
    # add the word
    ####

    else {
        push(@$words, $string);
        push(@$words, $args->{dictionary}->{$string})
            if $args->{dictionary} && $args->{dictionary}->{$string};
    }

}

sub stem_lexical {
    my ($words, $args) = @_;
    my $stem_length = $args->{stem_length} || 3;
    my $stem_words = [];

    foreach my $word (@$words) {
        while ($word) {
            push(@$stem_words, $word);
            $word =~ s/.$//;
            last if length($word) < $stem_length;
        }
    }
    return $stem_words;
}

sub stem_lingual {
    my ($words, $args) = @_;
    my $stems = [];
    for my $w (@$words) {
        # the stem function will strip off any initial non-letters
        # in that case we just push it on
        my $stem = $w;
        if ($w =~ m/^[a-z]/i) {
            my $stem_words = Lingua::Stem::stem($w);
            # only one
            my $stem = $stem_words->[0];
        }
        # if we put both on then an AND applies
        # push(@$stems, $w eq $stem ? ($w) : ($w, $stem));
        push(@$stems, $stem);
    }
    return $stems;
}
