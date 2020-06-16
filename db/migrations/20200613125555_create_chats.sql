-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE chats(
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR NOT NULL,
    type_string VARCHAR NOT NULL,

    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE chats;