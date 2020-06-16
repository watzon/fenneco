-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE chat_members(
    id BIGSERIAL PRIMARY KEY,
    user_id SERIAL NOT NULL,
    chat_id BIGSERIAL NOT NULL,

    created_at TIMESTAMP,
    updated_at TIMESTAMP,

    FOREIGN KEY(user_id) REFERENCES users(id),
    FOREIGN KEY(chat_id) REFERENCES chats(id),
    UNIQUE(user_id, chat_id)
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE chat_members;