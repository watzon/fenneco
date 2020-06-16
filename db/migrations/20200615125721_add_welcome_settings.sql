-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE chat_settings
    ADD welcomes BOOLEAN,
    ADD welcome_message TEXT,
    ADD welcome_delay VARCHAR;

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
ALTER TABLE chat_settings
    DROP welcomes BOOLEAN,
    DROP welcome_message TEXT,
    DROP welcome_delay VARCHAR;