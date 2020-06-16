-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE chat_settings(
    id SERIAL PRIMARY KEY,
    chat_id BIGSERIAL NOT NULL,
    gbans BOOLEAN,
    gban_command VARCHAR,
    fbans BOOLEAN,
    fban_command VARCHAR,

    created_at TIMESTAMP,
    updated_at TIMESTAMP,

    FOREIGN KEY(chat_id) REFERENCES chats(id),
    UNIQUE(chat_id)
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE chat_settings;