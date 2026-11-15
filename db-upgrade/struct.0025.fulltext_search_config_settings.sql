BEGIN;

CREATE TEXT SEARCH CONFIGURATION public.buildsite ( COPY = pg_catalog.english );

-- define the synonym dictionary
-- file must be stored in $POSTGRESSHAREDIR/tsearch_data/buildsite_dict.syn,
-- e.g. /usr/share/postgresql/8.3/tsearch_data/buildsite_dict.syn

CREATE TEXT SEARCH DICTIONARY buildsite_dict (
    TEMPLATE = synonym,
    SYNONYMS = buildsite_dict
);

-- register the Ispell dictionary english_ispell,
-- it has its own configuration files

-- copy doc/english.* to $POSTGRESSHAREDIR/tsearch_data/ 
-- (except maybe doc/english.aff -> $POSTGRESSHAREDIR/tsearch_data/english.affix)
-- and english.stop is probably already there.

CREATE TEXT SEARCH DICTIONARY buildsite_ispell (
    TEMPLATE = ispell,
    DictFile = english,
    AffFile = english,
    StopWords = english
);

-- set up the mappings for words in configuration pg

ALTER TEXT SEARCH CONFIGURATION buildsite
    ALTER MAPPING FOR asciiword, asciihword, hword_asciipart,
                      word, hword, hword_part
    WITH buildsite_dict, buildsite_ispell, english_stem;

-- not to index or search some token types that the built-in configuration does handle

ALTER TEXT SEARCH CONFIGURATION buildsite
    DROP MAPPING FOR email, url, url_path, sfloat, float, host;

COMMIT;