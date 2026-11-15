-- sign all messages as 'processed' as we have new scheme of statuses
BEGIN;
UPDATE legacy_sent_message SET message_status = 'processed';
COMMIT;
