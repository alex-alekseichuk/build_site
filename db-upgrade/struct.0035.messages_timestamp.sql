BEGIN;

ALTER TABLE legacy_sent_message
      ALTER COLUMN time_sent DROP DEFAULT,
      ALTER COLUMN time_sent TYPE timestamp
            USING cast(timestamp 'epoch' + cast(time_sent as int) * interval '1 second' as timestamp),
      ALTER COLUMN time_sent SET DEFAULT now()
;

COMMIT;