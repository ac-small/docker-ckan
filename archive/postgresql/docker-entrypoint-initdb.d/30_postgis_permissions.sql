CREATE EXTENSION IF NOT EXISTS POSTGIS;
ALTER VIEW geometry_columns OWNER to ckan;
ALTER TABLE spatial_ref_sys OWNER to ckan;
