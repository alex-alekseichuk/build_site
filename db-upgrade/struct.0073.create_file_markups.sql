-- file markup table definition

CREATE TABLE file_markup (
    id BIGSERIAL PRIMARY KEY,
    file_id VARCHAR(250) NOT NULL,
    document_id VARCHAR(250) NOT NULL,
    package_id VARCHAR(250) NOT NULL,
    page INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL,
    json_markup VARCHAR(5000) NOT NULL,
    svg_markup VARCHAR(5000) NOT NULL,
    auto_ctime TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    auto_mtime TIMESTAMP WITH TIME ZONE
);

ALTER TABLE ONLY file_markup
    ADD CONSTRAINT fk_fm_file FOREIGN KEY (file_id) REFERENCES file(file_id) ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY file_markup
    ADD CONSTRAINT fk_fm_document FOREIGN KEY (document_id) REFERENCES document(document_id) ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;
