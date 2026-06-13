INSERT OR IGNORE INTO
resources(id, name, capacity, gap_seconds, currency, allow_animals, created_at)
VALUES
("2eb2f582-ea4a-456c-959e-46f360567b69", "Biberbau", 3, 3600, "Euro", false, unixepoch() * 1000000);

INSERT OR IGNORE INTO
users(id, name, email, password_hash)
VALUES
("4c398982-9a13-4998-9e57-c7417c402f54","Admin","admin@example.com", "$argon2id$v=13$m=19456,t=2,p=1$QmZ6bnZMVXEtMjl6T0Vzb3BCa011TUZxeWw4Q1FnZ3Q$Azq9etboikzyzMRnktHDNNucvZi/GsvWFA7DlkgDu5U" );

