CREATE TABLE tpcds.store (
    s_store_sk integer NOT NULL,
    s_store_id character(16) NOT NULL,
    s_rec_start_date date,
    s_rec_end_date date,
    s_closed_date_sk integer,
    s_store_name character varying(50),
    s_number_employees integer,
    s_floor_space integer,
    s_hours character(20),
    s_manager character varying(40),
    s_market_id integer,
    s_geography_class character varying(100),
    s_market_desc character varying(100),
    s_market_manager character varying(40),
    s_division_id integer,
    s_division_name character varying(50),
    s_company_id integer,
    s_company_name character varying(50),
    s_street_number character varying(10),
    s_street_name character varying(60),
    s_street_type character(15),
    s_suite_number character(10),
    s_city character varying(60),
    s_county character varying(30),
    s_state character(2),
    s_zip character(10),
    s_country character varying(20),
    s_gmt_offset numeric(5,2),
    s_tax_precentage numeric(5,2)
)
WITH (:SMALL_STORAGE)
DISTRIBUTED BY (s_store_sk);
