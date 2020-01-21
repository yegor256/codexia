  
--liquibase formatted sql
--changeset liquibase-demo:release_1_0_0.001_create_test_table.sql

CREATE TABLE liquibase_test (
  key VARCHAR(64),
  value VARCHAR(255),
  PRIMARY KEY(key)
);
