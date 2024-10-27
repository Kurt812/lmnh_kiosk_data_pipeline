""" This file contains all code required to create & seed database tables. """

DROP TABLE IF EXISTS rating_interaction CASCADE;
DROP TABLE IF EXISTS request_interaction CASCADE;
DROP TABLE IF EXISTS rating CASCADE;
DROP TABLE IF EXISTS request CASCADE;
DROP TABLE IF EXISTS exhibition CASCADE;
DROP TABLE IF EXISTS department CASCADE;
DROP TABLE IF EXISTS floor CASCADE;

CREATE TABLE department (
    department_id SMALLINT,
    department_name VARCHAR(100) UNIQUE NOT NULL,
    PRIMARY KEY (department_id)
);

CREATE TABLE floor (
    floor_id INT,
    floor_name VARCHAR(100) UNIQUE NOT NULL,
    PRIMARY KEY (floor_id)
);

CREATE TABLE exhibition (
    exhibition_id INT GENERATED ALWAYS AS IDENTITY,
    exhibition_name VARCHAR(100) NOT NULL,
    exhibition_description TEXT,
    department_id SMALLINT,
    floor_id SMALLINT,
    exhibition_start_date DATE DEFAULT CURRENT_DATE CONSTRAINT future_event CHECK (exhibition_start_date <= CURRENT_DATE),
    public_id TEXT UNIQUE NOT NULL,
    PRIMARY KEY (exhibition_id),
    FOREIGN KEY (department_id) REFERENCES department (department_id),
    FOREIGN KEY (floor_id) REFERENCES floor (floor_id) 
);

CREATE TABLE request(
    request_id SMALLINT, 
    request_value SMALLINT UNIQUE NOT NULL CHECK (request_value = 0 OR request_value = 1), 
    request_description VARCHAR(100),
    CONSTRAINT valid_match_request CHECK ( 
        (request_value = 0 AND request_description ILIKE 'assistance') 
        OR (request_value = 1 AND request_description ILIKE 'emergency')),
    PRIMARY KEY (request_id)
);

CREATE TABLE rating(
    rating_id SMALLINT, 
    rating_value SMALLINT UNIQUE NOT NULL,
    rating_description VARCHAR(100) UNIQUE NOT NULL,
    PRIMARY KEY (rating_id)
);

CREATE TABLE request_interaction (
    request_interaction_id BIGINT GENERATED ALWAYS AS IDENTITY,
    exhibition_id SMALLINT,
    request_id SMALLINT, --1 or 2
    event_at TIMESTAMP CONSTRAINT future_event CHECK (event_at <= (CURRENT_TIMESTAMP+ INTERVAL '1 hour' + INTERVAL '1 second')), --to account for timezone and give buffer
    PRIMARY KEY (request_interaction_id),
    FOREIGN KEY (exhibition_id) REFERENCES exhibition (exhibition_id),
    FOREIGN KEY (request_id) REFERENCES request (request_id)

);

CREATE TABLE rating_interaction (
    rating_interaction_id BIGINT GENERATED ALWAYS AS IDENTITY,
    exhibition_id SMALLINT,
    rating_id SMALLINT, --between 1 and 5
    event_at TIMESTAMP CONSTRAINT future_event CHECK (event_at <= (CURRENT_TIMESTAMP + INTERVAL '1 hour' + INTERVAL '1 second')),
    PRIMARY KEY (rating_interaction_id),
    FOREIGN KEY (exhibition_id) REFERENCES exhibition (exhibition_id),
    FOREIGN KEY (rating_id) REFERENCES rating (rating_id)
);


INSERT INTO department (department_id, department_name) VALUES
(1, 'Geology'),
(2, 'Entomology'),
(3, 'Zoology'),
(4, 'Ecology'),
(5, 'Paleontology');


INSERT INTO floor (floor_id, floor_name) VALUES
(1, 'Vault'),
(2, '1'),
(3, '2'),
(4, '3');


INSERT INTO request (request_id, request_value, request_description) VALUES
(1, 0, 'assistance'),
(2, 1, 'emergency');


INSERT INTO rating (rating_id, rating_value, rating_description) VALUES
(1, 0, 'terrible'),
(2, 1, 'bad'),
(3, 2, 'neutral'),
(4, 3, 'good'),
(5, 4, 'amazing');


INSERT INTO exhibition (exhibition_name, exhibition_description, department_id, floor_id, exhibition_start_date, public_id) VALUES
('Measureless to Man', 'An immersive 3D experience: delve deep into a previously-inaccessible cave system.', 1, 2, '08/23/21', 'EXH_00'),
('Adaptation', 'How insect evolution has kept pace with an industrialised world', 2, 1, '07/01/19', 'EXH_01'),
('The Crenshaw Collection', 'An exhibition of 18th Century watercolours, mostly focused on South American wildlife.', 3, 3, '03/03/21', 'EXH_02'),
('Cetacean Sensations', 'Whales: from ancient myth to critically endangered.', 3, 2, '07/01/19', 'EXH_03'),
('Our Polluted World', 'A hard-hitting exploration of humanity''s impact on the environment.', 4, 4, '05/12/21', 'EXH_04'),
('Thunder Lizards', 'How new research is making scientists rethink what dinosaurs really looked like.', 5, 2, '02/01/23', 'EXH_05');











