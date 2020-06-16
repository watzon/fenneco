-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE gbans(
    id SERIAL PRIMARY KEY,
    user_id SERIAL NOT NULL,
    reason VARCHAR,
    message TEXT,

    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE gbans;