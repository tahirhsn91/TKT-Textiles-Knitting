--
-- PostgreSQL database dump
--

\restrict R9FYkROb6jBukxShFZVpHSNfZ4KsqOAZ5OQEay9A23POe4Pz5kTZyANZEcKWEk0

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.transaction_header DROP CONSTRAINT IF EXISTS transaction_header_transaction_type_id_transaction_type_master_;
ALTER TABLE IF EXISTS ONLY public.transaction_header DROP CONSTRAINT IF EXISTS transaction_header_party_id_party_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_header DROP CONSTRAINT IF EXISTS transaction_header_location_id_location_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_header DROP CONSTRAINT IF EXISTS transaction_header_job_id_job_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_header DROP CONSTRAINT IF EXISTS transaction_header_fabric_type_id_fabric_type_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_yarn_type_id_yarn_type_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_yarn_count_id_yarn_count_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_yarn_brand_id_yarn_brand_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_uom_id_uom_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_machine_operator_id_machine_operator_master_;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_machine_id_machine_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_header_id_transaction_header_id_fk;
ALTER TABLE IF EXISTS ONLY public.salary_detail DROP CONSTRAINT IF EXISTS salary_detail_operator_id_machine_operator_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.salary_detail DROP CONSTRAINT IF EXISTS salary_detail_header_id_salary_header_id_fk;
ALTER TABLE IF EXISTS ONLY public.operator_salary_settings DROP CONSTRAINT IF EXISTS operator_salary_settings_operator_id_machine_operator_master_id;
ALTER TABLE IF EXISTS ONLY public.operator_salary_records DROP CONSTRAINT IF EXISTS operator_salary_records_operator_id_machine_operator_master_id_;
ALTER TABLE IF EXISTS ONLY public.operator_advances DROP CONSTRAINT IF EXISTS operator_advances_operator_id_machine_operator_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.yarn_type_master DROP CONSTRAINT IF EXISTS yarn_type_master_pkey;
ALTER TABLE IF EXISTS ONLY public.yarn_type_master DROP CONSTRAINT IF EXISTS yarn_type_master_code_unique;
ALTER TABLE IF EXISTS ONLY public.yarn_count_master DROP CONSTRAINT IF EXISTS yarn_count_master_pkey;
ALTER TABLE IF EXISTS ONLY public.yarn_count_master DROP CONSTRAINT IF EXISTS yarn_count_master_count_unique;
ALTER TABLE IF EXISTS ONLY public.yarn_brand_master DROP CONSTRAINT IF EXISTS yarn_brand_master_pkey;
ALTER TABLE IF EXISTS ONLY public.yarn_brand_master DROP CONSTRAINT IF EXISTS yarn_brand_master_code_unique;
ALTER TABLE IF EXISTS ONLY public.uom_master DROP CONSTRAINT IF EXISTS uom_master_pkey;
ALTER TABLE IF EXISTS ONLY public.uom_master DROP CONSTRAINT IF EXISTS uom_master_abbreviation_unique;
ALTER TABLE IF EXISTS ONLY public.transaction_type_master DROP CONSTRAINT IF EXISTS transaction_type_master_pkey;
ALTER TABLE IF EXISTS ONLY public.transaction_type_master DROP CONSTRAINT IF EXISTS transaction_type_master_code_unique;
ALTER TABLE IF EXISTS ONLY public.transaction_header DROP CONSTRAINT IF EXISTS transaction_header_pkey;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_pkey;
ALTER TABLE IF EXISTS ONLY public.salary_header DROP CONSTRAINT IF EXISTS salary_header_pkey;
ALTER TABLE IF EXISTS ONLY public.salary_detail DROP CONSTRAINT IF EXISTS salary_detail_pkey;
ALTER TABLE IF EXISTS ONLY public.salary_detail DROP CONSTRAINT IF EXISTS salary_detail_op_month_year_unique;
ALTER TABLE IF EXISTS ONLY public.salary_detail DROP CONSTRAINT IF EXISTS salary_detail_header_operator_unique;
ALTER TABLE IF EXISTS ONLY public.party_master DROP CONSTRAINT IF EXISTS party_master_pkey;
ALTER TABLE IF EXISTS ONLY public.party_master DROP CONSTRAINT IF EXISTS party_master_code_unique;
ALTER TABLE IF EXISTS ONLY public.operator_salary_settings DROP CONSTRAINT IF EXISTS operator_salary_settings_pkey;
ALTER TABLE IF EXISTS ONLY public.operator_salary_settings DROP CONSTRAINT IF EXISTS operator_salary_settings_operator_id_unique;
ALTER TABLE IF EXISTS ONLY public.operator_salary_records DROP CONSTRAINT IF EXISTS operator_salary_records_pkey;
ALTER TABLE IF EXISTS ONLY public.operator_salary_records DROP CONSTRAINT IF EXISTS operator_salary_records_operator_id_date_unique;
ALTER TABLE IF EXISTS ONLY public.operator_advances DROP CONSTRAINT IF EXISTS operator_advances_pkey;
ALTER TABLE IF EXISTS ONLY public.machine_operator_master DROP CONSTRAINT IF EXISTS machine_operator_master_pkey;
ALTER TABLE IF EXISTS ONLY public.machine_operator_master DROP CONSTRAINT IF EXISTS machine_operator_master_code_unique;
ALTER TABLE IF EXISTS ONLY public.machine_master DROP CONSTRAINT IF EXISTS machine_master_pkey;
ALTER TABLE IF EXISTS ONLY public.machine_master DROP CONSTRAINT IF EXISTS machine_master_machine_number_unique;
ALTER TABLE IF EXISTS ONLY public.location_master DROP CONSTRAINT IF EXISTS location_master_pkey;
ALTER TABLE IF EXISTS ONLY public.location_master DROP CONSTRAINT IF EXISTS location_master_code_unique;
ALTER TABLE IF EXISTS ONLY public.job_master DROP CONSTRAINT IF EXISTS job_master_pkey;
ALTER TABLE IF EXISTS ONLY public.job_master DROP CONSTRAINT IF EXISTS job_master_party_code_unique;
ALTER TABLE IF EXISTS ONLY public.fabric_type_master DROP CONSTRAINT IF EXISTS fabric_type_master_pkey;
ALTER TABLE IF EXISTS ONLY public.fabric_type_master DROP CONSTRAINT IF EXISTS fabric_type_master_code_unique;
ALTER TABLE IF EXISTS ONLY public.department_master DROP CONSTRAINT IF EXISTS department_master_pkey;
ALTER TABLE IF EXISTS ONLY public.department_master DROP CONSTRAINT IF EXISTS department_master_code_unique;
ALTER TABLE IF EXISTS public.yarn_type_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.yarn_count_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.yarn_brand_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.uom_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.transaction_type_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.transaction_header ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.transaction_detail ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.salary_header ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.salary_detail ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.party_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.operator_salary_settings ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.operator_salary_records ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.operator_advances ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.machine_operator_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.machine_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.location_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.job_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.fabric_type_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.department_master ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.yarn_type_master_id_seq;
DROP TABLE IF EXISTS public.yarn_type_master;
DROP SEQUENCE IF EXISTS public.yarn_count_master_id_seq;
DROP TABLE IF EXISTS public.yarn_count_master;
DROP SEQUENCE IF EXISTS public.yarn_brand_master_id_seq;
DROP TABLE IF EXISTS public.yarn_brand_master;
DROP SEQUENCE IF EXISTS public.uom_master_id_seq;
DROP TABLE IF EXISTS public.uom_master;
DROP SEQUENCE IF EXISTS public.transaction_type_master_id_seq;
DROP TABLE IF EXISTS public.transaction_type_master;
DROP SEQUENCE IF EXISTS public.transaction_header_id_seq;
DROP TABLE IF EXISTS public.transaction_header;
DROP SEQUENCE IF EXISTS public.transaction_detail_id_seq;
DROP TABLE IF EXISTS public.transaction_detail;
DROP SEQUENCE IF EXISTS public.salary_header_id_seq;
DROP TABLE IF EXISTS public.salary_header;
DROP SEQUENCE IF EXISTS public.salary_detail_id_seq;
DROP TABLE IF EXISTS public.salary_detail;
DROP SEQUENCE IF EXISTS public.party_master_id_seq;
DROP TABLE IF EXISTS public.party_master;
DROP SEQUENCE IF EXISTS public.operator_salary_settings_id_seq;
DROP TABLE IF EXISTS public.operator_salary_settings;
DROP SEQUENCE IF EXISTS public.operator_salary_records_id_seq;
DROP TABLE IF EXISTS public.operator_salary_records;
DROP SEQUENCE IF EXISTS public.operator_advances_id_seq;
DROP TABLE IF EXISTS public.operator_advances;
DROP SEQUENCE IF EXISTS public.machine_operator_master_id_seq;
DROP TABLE IF EXISTS public.machine_operator_master;
DROP SEQUENCE IF EXISTS public.machine_master_id_seq;
DROP TABLE IF EXISTS public.machine_master;
DROP SEQUENCE IF EXISTS public.location_master_id_seq;
DROP TABLE IF EXISTS public.location_master;
DROP SEQUENCE IF EXISTS public.job_master_id_seq;
DROP TABLE IF EXISTS public.job_master;
DROP SEQUENCE IF EXISTS public.fabric_type_master_id_seq;
DROP TABLE IF EXISTS public.fabric_type_master;
DROP SEQUENCE IF EXISTS public.department_master_id_seq;
DROP TABLE IF EXISTS public.department_master;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: department_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.department_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL
);


ALTER TABLE public.department_master OWNER TO postgres;

--
-- Name: department_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.department_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.department_master_id_seq OWNER TO postgres;

--
-- Name: department_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.department_master_id_seq OWNED BY public.department_master.id;


--
-- Name: fabric_type_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fabric_type_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL
);


ALTER TABLE public.fabric_type_master OWNER TO postgres;

--
-- Name: fabric_type_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fabric_type_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fabric_type_master_id_seq OWNER TO postgres;

--
-- Name: fabric_type_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fabric_type_master_id_seq OWNED BY public.fabric_type_master.id;


--
-- Name: job_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    party_id integer
);


ALTER TABLE public.job_master OWNER TO postgres;

--
-- Name: job_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_master_id_seq OWNER TO postgres;

--
-- Name: job_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.job_master_id_seq OWNED BY public.job_master.id;


--
-- Name: location_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL
);


ALTER TABLE public.location_master OWNER TO postgres;

--
-- Name: location_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.location_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.location_master_id_seq OWNER TO postgres;

--
-- Name: location_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.location_master_id_seq OWNED BY public.location_master.id;


--
-- Name: machine_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.machine_master (
    id integer NOT NULL,
    name text NOT NULL,
    machine_number text NOT NULL,
    making_rate numeric(10,2) DEFAULT 3.75,
    needle_change_date text,
    needle_brand text DEFAULT 'Sigma'::text,
    sinker_change_date text,
    sinker_brand text DEFAULT 'Kohala'::text
);


ALTER TABLE public.machine_master OWNER TO postgres;

--
-- Name: machine_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.machine_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.machine_master_id_seq OWNER TO postgres;

--
-- Name: machine_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.machine_master_id_seq OWNED BY public.machine_master.id;


--
-- Name: machine_operator_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.machine_operator_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    department_id integer,
    base_salary numeric(10,2),
    overtime_rate_hr numeric(10,2),
    att_allowance numeric(10,2),
    oth_allowance numeric(10,2),
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.machine_operator_master OWNER TO postgres;

--
-- Name: machine_operator_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.machine_operator_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.machine_operator_master_id_seq OWNER TO postgres;

--
-- Name: machine_operator_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.machine_operator_master_id_seq OWNED BY public.machine_operator_master.id;


--
-- Name: operator_advances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.operator_advances (
    id integer NOT NULL,
    operator_id integer NOT NULL,
    date text NOT NULL,
    amount numeric NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.operator_advances OWNER TO postgres;

--
-- Name: operator_advances_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.operator_advances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.operator_advances_id_seq OWNER TO postgres;

--
-- Name: operator_advances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.operator_advances_id_seq OWNED BY public.operator_advances.id;


--
-- Name: operator_salary_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.operator_salary_records (
    id integer NOT NULL,
    operator_id integer NOT NULL,
    date text NOT NULL,
    base_wage numeric NOT NULL,
    commission numeric DEFAULT '0'::numeric NOT NULL,
    final_salary numeric NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.operator_salary_records OWNER TO postgres;

--
-- Name: operator_salary_records_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.operator_salary_records_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.operator_salary_records_id_seq OWNER TO postgres;

--
-- Name: operator_salary_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.operator_salary_records_id_seq OWNED BY public.operator_salary_records.id;


--
-- Name: operator_salary_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.operator_salary_settings (
    id integer NOT NULL,
    operator_id integer NOT NULL,
    base_daily_wage numeric DEFAULT '0'::numeric NOT NULL
);


ALTER TABLE public.operator_salary_settings OWNER TO postgres;

--
-- Name: operator_salary_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.operator_salary_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.operator_salary_settings_id_seq OWNER TO postgres;

--
-- Name: operator_salary_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.operator_salary_settings_id_seq OWNED BY public.operator_salary_settings.id;


--
-- Name: party_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.party_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    waste_percent numeric(5,2) DEFAULT 1.00
);


ALTER TABLE public.party_master OWNER TO postgres;

--
-- Name: party_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.party_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.party_master_id_seq OWNER TO postgres;

--
-- Name: party_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.party_master_id_seq OWNED BY public.party_master.id;


--
-- Name: salary_detail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.salary_detail (
    id integer NOT NULL,
    header_id integer NOT NULL,
    operator_id integer NOT NULL,
    month integer,
    year integer,
    department_id integer,
    operator_name text NOT NULL,
    basic_salary numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    ot_rate_hr numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    att_allowance numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    oth_allowance numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    present_days numeric(5,1) DEFAULT '0'::numeric NOT NULL,
    absent_days numeric(5,1) DEFAULT '0'::numeric NOT NULL,
    holidays numeric(5,1) DEFAULT '0'::numeric NOT NULL,
    total_attendance numeric(5,1) DEFAULT '0'::numeric NOT NULL,
    total_salary numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    ot_hours numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    ot_amount numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    advance_deduction numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    loan_deduction numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    other_deduction numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    payable_salary numeric(10,2) DEFAULT '0'::numeric NOT NULL
);


ALTER TABLE public.salary_detail OWNER TO postgres;

--
-- Name: salary_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.salary_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.salary_detail_id_seq OWNER TO postgres;

--
-- Name: salary_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.salary_detail_id_seq OWNED BY public.salary_detail.id;


--
-- Name: salary_header; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.salary_header (
    id integer NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    department_ids integer[] DEFAULT '{}'::integer[] NOT NULL,
    posted boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.salary_header OWNER TO postgres;

--
-- Name: salary_header_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.salary_header_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.salary_header_id_seq OWNER TO postgres;

--
-- Name: salary_header_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.salary_header_id_seq OWNED BY public.salary_header.id;


--
-- Name: transaction_detail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction_detail (
    id integer NOT NULL,
    header_id integer NOT NULL,
    machine_id integer,
    machine_operator_id integer,
    yarn_type_id integer,
    yarn_count_id integer,
    yarn_brand_id integer,
    uom_id integer,
    quantity numeric(12,3),
    net_wt numeric(12,3)
);


ALTER TABLE public.transaction_detail OWNER TO postgres;

--
-- Name: transaction_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transaction_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transaction_detail_id_seq OWNER TO postgres;

--
-- Name: transaction_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transaction_detail_id_seq OWNED BY public.transaction_detail.id;


--
-- Name: transaction_header; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction_header (
    id integer NOT NULL,
    transaction_type_id integer NOT NULL,
    date date NOT NULL,
    doc_number text NOT NULL,
    job_id integer,
    party_id integer,
    location_id integer,
    fabric_type_id integer,
    sl text,
    gsm integer,
    reference text
);


ALTER TABLE public.transaction_header OWNER TO postgres;

--
-- Name: transaction_header_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transaction_header_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transaction_header_id_seq OWNER TO postgres;

--
-- Name: transaction_header_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transaction_header_id_seq OWNED BY public.transaction_header.id;


--
-- Name: transaction_type_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction_type_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    action text
);


ALTER TABLE public.transaction_type_master OWNER TO postgres;

--
-- Name: transaction_type_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transaction_type_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transaction_type_master_id_seq OWNER TO postgres;

--
-- Name: transaction_type_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transaction_type_master_id_seq OWNED BY public.transaction_type_master.id;


--
-- Name: uom_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.uom_master (
    id integer NOT NULL,
    name text NOT NULL,
    abbreviation text NOT NULL
);


ALTER TABLE public.uom_master OWNER TO postgres;

--
-- Name: uom_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.uom_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.uom_master_id_seq OWNER TO postgres;

--
-- Name: uom_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.uom_master_id_seq OWNED BY public.uom_master.id;


--
-- Name: yarn_brand_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.yarn_brand_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL
);


ALTER TABLE public.yarn_brand_master OWNER TO postgres;

--
-- Name: yarn_brand_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.yarn_brand_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.yarn_brand_master_id_seq OWNER TO postgres;

--
-- Name: yarn_brand_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.yarn_brand_master_id_seq OWNED BY public.yarn_brand_master.id;


--
-- Name: yarn_count_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.yarn_count_master (
    id integer NOT NULL,
    name text NOT NULL,
    count text NOT NULL
);


ALTER TABLE public.yarn_count_master OWNER TO postgres;

--
-- Name: yarn_count_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.yarn_count_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.yarn_count_master_id_seq OWNER TO postgres;

--
-- Name: yarn_count_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.yarn_count_master_id_seq OWNED BY public.yarn_count_master.id;


--
-- Name: yarn_type_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.yarn_type_master (
    id integer NOT NULL,
    name text NOT NULL,
    make_rate numeric,
    code text NOT NULL
);


ALTER TABLE public.yarn_type_master OWNER TO postgres;

--
-- Name: yarn_type_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.yarn_type_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.yarn_type_master_id_seq OWNER TO postgres;

--
-- Name: yarn_type_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.yarn_type_master_id_seq OWNED BY public.yarn_type_master.id;


--
-- Name: department_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_master ALTER COLUMN id SET DEFAULT nextval('public.department_master_id_seq'::regclass);


--
-- Name: fabric_type_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fabric_type_master ALTER COLUMN id SET DEFAULT nextval('public.fabric_type_master_id_seq'::regclass);


--
-- Name: job_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_master ALTER COLUMN id SET DEFAULT nextval('public.job_master_id_seq'::regclass);


--
-- Name: location_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_master ALTER COLUMN id SET DEFAULT nextval('public.location_master_id_seq'::regclass);


--
-- Name: machine_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.machine_master ALTER COLUMN id SET DEFAULT nextval('public.machine_master_id_seq'::regclass);


--
-- Name: machine_operator_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.machine_operator_master ALTER COLUMN id SET DEFAULT nextval('public.machine_operator_master_id_seq'::regclass);


--
-- Name: operator_advances id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_advances ALTER COLUMN id SET DEFAULT nextval('public.operator_advances_id_seq'::regclass);


--
-- Name: operator_salary_records id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_salary_records ALTER COLUMN id SET DEFAULT nextval('public.operator_salary_records_id_seq'::regclass);


--
-- Name: operator_salary_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_salary_settings ALTER COLUMN id SET DEFAULT nextval('public.operator_salary_settings_id_seq'::regclass);


--
-- Name: party_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.party_master ALTER COLUMN id SET DEFAULT nextval('public.party_master_id_seq'::regclass);


--
-- Name: salary_detail id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_detail ALTER COLUMN id SET DEFAULT nextval('public.salary_detail_id_seq'::regclass);


--
-- Name: salary_header id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_header ALTER COLUMN id SET DEFAULT nextval('public.salary_header_id_seq'::regclass);


--
-- Name: transaction_detail id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_detail ALTER COLUMN id SET DEFAULT nextval('public.transaction_detail_id_seq'::regclass);


--
-- Name: transaction_header id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_header ALTER COLUMN id SET DEFAULT nextval('public.transaction_header_id_seq'::regclass);


--
-- Name: transaction_type_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_type_master ALTER COLUMN id SET DEFAULT nextval('public.transaction_type_master_id_seq'::regclass);


--
-- Name: uom_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.uom_master ALTER COLUMN id SET DEFAULT nextval('public.uom_master_id_seq'::regclass);


--
-- Name: yarn_brand_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.yarn_brand_master ALTER COLUMN id SET DEFAULT nextval('public.yarn_brand_master_id_seq'::regclass);


--
-- Name: yarn_count_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.yarn_count_master ALTER COLUMN id SET DEFAULT nextval('public.yarn_count_master_id_seq'::regclass);


--
-- Name: yarn_type_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.yarn_type_master ALTER COLUMN id SET DEFAULT nextval('public.yarn_type_master_id_seq'::regclass);


--
-- Data for Name: department_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.department_master (id, name, code) FROM stdin;
1	Administration	ADMIN
2	Knitting Production	KNIT
3	Security	SEC
4	Loading	LOAD
5	Quality Check	QC
6	Knitting	KNT
7	Finishing	FIN
8	Dyeing	DYE
9	Packing	PKG
\.


--
-- Data for Name: fabric_type_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fabric_type_master (id, name, code) FROM stdin;
1	Single Jersey	SJ
2	Rib	RIB
3	Interlock	INT
4	Pique	PIQ
\.


--
-- Data for Name: job_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_master (id, name, code, party_id) FROM stdin;
1	Knitting Order	KO	\N
2	Production Run	PR	\N
3	Quality Check	QC	\N
4	Dispatch Order	DO	\N
\.


--
-- Data for Name: location_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.location_master (id, name, code) FROM stdin;
1	Production Floor A	PFA
2	Production Floor B	PFB
3	Warehouse	WH
4	Dispatch Bay	DB
\.


--
-- Data for Name: machine_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.machine_master (id, name, machine_number, making_rate, needle_change_date, needle_brand, sinker_change_date, sinker_brand) FROM stdin;
1	Flat Knitting Machine A	M-001	3.75	\N	Sigma	\N	Kohala
2	Flat Knitting Machine B	M-002	3.75	\N	Sigma	\N	Kohala
3	Circular Knitting Machine 1	M-003	3.75	\N	Sigma	\N	Kohala
4	Circular Knitting Machine 2	M-004	3.75	\N	Sigma	\N	Kohala
\.


--
-- Data for Name: machine_operator_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.machine_operator_master (id, name, code, department_id, base_salary, overtime_rate_hr, att_allowance, oth_allowance, active) FROM stdin;
1	Operator Alpha	OPA	\N	\N	\N	\N	\N	t
2	Operator Beta	OPB	\N	\N	\N	\N	\N	t
3	Operator Gamma	OPG	\N	\N	\N	\N	\N	t
4	Operator Delta	OPD	\N	\N	\N	\N	\N	t
\.


--
-- Data for Name: operator_advances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.operator_advances (id, operator_id, date, amount, notes, created_at) FROM stdin;
\.


--
-- Data for Name: operator_salary_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.operator_salary_records (id, operator_id, date, base_wage, commission, final_salary, created_at) FROM stdin;
\.


--
-- Data for Name: operator_salary_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.operator_salary_settings (id, operator_id, base_daily_wage) FROM stdin;
\.


--
-- Data for Name: party_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.party_master (id, name, code, waste_percent) FROM stdin;
1	Sunrise Textiles	SUN	1.00
2	Blue Star Fabrics	BSF	1.00
3	Apex Yarns Ltd	AYL	1.00
4	Global Knit Co	GKC	1.00
\.


--
-- Data for Name: salary_detail; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.salary_detail (id, header_id, operator_id, month, year, department_id, operator_name, basic_salary, ot_rate_hr, att_allowance, oth_allowance, present_days, absent_days, holidays, total_attendance, total_salary, ot_hours, ot_amount, advance_deduction, loan_deduction, other_deduction, payable_salary) FROM stdin;
\.


--
-- Data for Name: salary_header; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.salary_header (id, month, year, department_ids, posted, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: transaction_detail; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transaction_detail (id, header_id, machine_id, machine_operator_id, yarn_type_id, yarn_count_id, yarn_brand_id, uom_id, quantity, net_wt) FROM stdin;
\.


--
-- Data for Name: transaction_header; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transaction_header (id, transaction_type_id, date, doc_number, job_id, party_id, location_id, fabric_type_id, sl, gsm, reference) FROM stdin;
\.


--
-- Data for Name: transaction_type_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transaction_type_master (id, name, code, action) FROM stdin;
1	Knitting Order	KO	issue
2	Production Run	PR	receipt
3	Quality Check	QC	transfer
4	Dispatch Order	DO	issue
\.


--
-- Data for Name: uom_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.uom_master (id, name, abbreviation) FROM stdin;
1	Kilogram	KG
2	Gram	GM
3	Meter	MTR
4	Piece	PCS
\.


--
-- Data for Name: yarn_brand_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.yarn_brand_master (id, name, code) FROM stdin;
1	Vardhman	VAR
2	Nahar	NAH
3	Trident	TRI
4	Welspun	WEL
\.


--
-- Data for Name: yarn_count_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.yarn_count_master (id, name, count) FROM stdin;
1	20s (20)	20
2	30s (30)	30
3	40s (40)	40
4	60s (60)	60
\.


--
-- Data for Name: yarn_type_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.yarn_type_master (id, name, make_rate, code) FROM stdin;
1	Cotton	\N	COT
2	Polyester	\N	PES
3	Viscose	\N	VIS
4	Nylon	\N	NYL
\.


--
-- Name: department_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.department_master_id_seq', 9, true);


--
-- Name: fabric_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fabric_type_master_id_seq', 4, true);


--
-- Name: job_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_master_id_seq', 4, true);


--
-- Name: location_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.location_master_id_seq', 4, true);


--
-- Name: machine_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.machine_master_id_seq', 4, true);


--
-- Name: machine_operator_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.machine_operator_master_id_seq', 4, true);


--
-- Name: operator_advances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.operator_advances_id_seq', 1, false);


--
-- Name: operator_salary_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.operator_salary_records_id_seq', 1, false);


--
-- Name: operator_salary_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.operator_salary_settings_id_seq', 1, false);


--
-- Name: party_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.party_master_id_seq', 4, true);


--
-- Name: salary_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.salary_detail_id_seq', 1, false);


--
-- Name: salary_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.salary_header_id_seq', 1, false);


--
-- Name: transaction_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transaction_detail_id_seq', 1, false);


--
-- Name: transaction_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transaction_header_id_seq', 1, true);


--
-- Name: transaction_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transaction_type_master_id_seq', 4, true);


--
-- Name: uom_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.uom_master_id_seq', 4, true);


--
-- Name: yarn_brand_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.yarn_brand_master_id_seq', 4, true);


--
-- Name: yarn_count_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.yarn_count_master_id_seq', 4, true);


--
-- Name: yarn_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.yarn_type_master_id_seq', 4, true);


--
-- Name: department_master department_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_master
    ADD CONSTRAINT department_master_code_unique UNIQUE (code);


--
-- Name: department_master department_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.department_master
    ADD CONSTRAINT department_master_pkey PRIMARY KEY (id);


--
-- Name: fabric_type_master fabric_type_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fabric_type_master
    ADD CONSTRAINT fabric_type_master_code_unique UNIQUE (code);


--
-- Name: fabric_type_master fabric_type_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fabric_type_master
    ADD CONSTRAINT fabric_type_master_pkey PRIMARY KEY (id);


--
-- Name: job_master job_master_party_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_master
    ADD CONSTRAINT job_master_party_code_unique UNIQUE (party_id, code);


--
-- Name: job_master job_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_master
    ADD CONSTRAINT job_master_pkey PRIMARY KEY (id);


--
-- Name: location_master location_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_master
    ADD CONSTRAINT location_master_code_unique UNIQUE (code);


--
-- Name: location_master location_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_master
    ADD CONSTRAINT location_master_pkey PRIMARY KEY (id);


--
-- Name: machine_master machine_master_machine_number_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.machine_master
    ADD CONSTRAINT machine_master_machine_number_unique UNIQUE (machine_number);


--
-- Name: machine_master machine_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.machine_master
    ADD CONSTRAINT machine_master_pkey PRIMARY KEY (id);


--
-- Name: machine_operator_master machine_operator_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.machine_operator_master
    ADD CONSTRAINT machine_operator_master_code_unique UNIQUE (code);


--
-- Name: machine_operator_master machine_operator_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.machine_operator_master
    ADD CONSTRAINT machine_operator_master_pkey PRIMARY KEY (id);


--
-- Name: operator_advances operator_advances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_advances
    ADD CONSTRAINT operator_advances_pkey PRIMARY KEY (id);


--
-- Name: operator_salary_records operator_salary_records_operator_id_date_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_salary_records
    ADD CONSTRAINT operator_salary_records_operator_id_date_unique UNIQUE (operator_id, date);


--
-- Name: operator_salary_records operator_salary_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_salary_records
    ADD CONSTRAINT operator_salary_records_pkey PRIMARY KEY (id);


--
-- Name: operator_salary_settings operator_salary_settings_operator_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_salary_settings
    ADD CONSTRAINT operator_salary_settings_operator_id_unique UNIQUE (operator_id);


--
-- Name: operator_salary_settings operator_salary_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_salary_settings
    ADD CONSTRAINT operator_salary_settings_pkey PRIMARY KEY (id);


--
-- Name: party_master party_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.party_master
    ADD CONSTRAINT party_master_code_unique UNIQUE (code);


--
-- Name: party_master party_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.party_master
    ADD CONSTRAINT party_master_pkey PRIMARY KEY (id);


--
-- Name: salary_detail salary_detail_header_operator_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_header_operator_unique UNIQUE (header_id, operator_id);


--
-- Name: salary_detail salary_detail_op_month_year_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_op_month_year_unique UNIQUE (operator_id, month, year);


--
-- Name: salary_detail salary_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_pkey PRIMARY KEY (id);


--
-- Name: salary_header salary_header_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_header
    ADD CONSTRAINT salary_header_pkey PRIMARY KEY (id);


--
-- Name: transaction_detail transaction_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_pkey PRIMARY KEY (id);


--
-- Name: transaction_header transaction_header_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_pkey PRIMARY KEY (id);


--
-- Name: transaction_type_master transaction_type_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_type_master
    ADD CONSTRAINT transaction_type_master_code_unique UNIQUE (code);


--
-- Name: transaction_type_master transaction_type_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_type_master
    ADD CONSTRAINT transaction_type_master_pkey PRIMARY KEY (id);


--
-- Name: uom_master uom_master_abbreviation_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.uom_master
    ADD CONSTRAINT uom_master_abbreviation_unique UNIQUE (abbreviation);


--
-- Name: uom_master uom_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.uom_master
    ADD CONSTRAINT uom_master_pkey PRIMARY KEY (id);


--
-- Name: yarn_brand_master yarn_brand_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.yarn_brand_master
    ADD CONSTRAINT yarn_brand_master_code_unique UNIQUE (code);


--
-- Name: yarn_brand_master yarn_brand_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.yarn_brand_master
    ADD CONSTRAINT yarn_brand_master_pkey PRIMARY KEY (id);


--
-- Name: yarn_count_master yarn_count_master_count_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.yarn_count_master
    ADD CONSTRAINT yarn_count_master_count_unique UNIQUE (count);


--
-- Name: yarn_count_master yarn_count_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.yarn_count_master
    ADD CONSTRAINT yarn_count_master_pkey PRIMARY KEY (id);


--
-- Name: yarn_type_master yarn_type_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.yarn_type_master
    ADD CONSTRAINT yarn_type_master_code_unique UNIQUE (code);


--
-- Name: yarn_type_master yarn_type_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.yarn_type_master
    ADD CONSTRAINT yarn_type_master_pkey PRIMARY KEY (id);


--
-- Name: operator_advances operator_advances_operator_id_machine_operator_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_advances
    ADD CONSTRAINT operator_advances_operator_id_machine_operator_master_id_fk FOREIGN KEY (operator_id) REFERENCES public.machine_operator_master(id);


--
-- Name: operator_salary_records operator_salary_records_operator_id_machine_operator_master_id_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_salary_records
    ADD CONSTRAINT operator_salary_records_operator_id_machine_operator_master_id_ FOREIGN KEY (operator_id) REFERENCES public.machine_operator_master(id);


--
-- Name: operator_salary_settings operator_salary_settings_operator_id_machine_operator_master_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.operator_salary_settings
    ADD CONSTRAINT operator_salary_settings_operator_id_machine_operator_master_id FOREIGN KEY (operator_id) REFERENCES public.machine_operator_master(id);


--
-- Name: salary_detail salary_detail_header_id_salary_header_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_header_id_salary_header_id_fk FOREIGN KEY (header_id) REFERENCES public.salary_header(id) ON DELETE CASCADE;


--
-- Name: salary_detail salary_detail_operator_id_machine_operator_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_operator_id_machine_operator_master_id_fk FOREIGN KEY (operator_id) REFERENCES public.machine_operator_master(id);


--
-- Name: transaction_detail transaction_detail_header_id_transaction_header_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_header_id_transaction_header_id_fk FOREIGN KEY (header_id) REFERENCES public.transaction_header(id) ON DELETE CASCADE;


--
-- Name: transaction_detail transaction_detail_machine_id_machine_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_machine_id_machine_master_id_fk FOREIGN KEY (machine_id) REFERENCES public.machine_master(id);


--
-- Name: transaction_detail transaction_detail_machine_operator_id_machine_operator_master_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_machine_operator_id_machine_operator_master_ FOREIGN KEY (machine_operator_id) REFERENCES public.machine_operator_master(id);


--
-- Name: transaction_detail transaction_detail_uom_id_uom_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_uom_id_uom_master_id_fk FOREIGN KEY (uom_id) REFERENCES public.uom_master(id);


--
-- Name: transaction_detail transaction_detail_yarn_brand_id_yarn_brand_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_yarn_brand_id_yarn_brand_master_id_fk FOREIGN KEY (yarn_brand_id) REFERENCES public.yarn_brand_master(id);


--
-- Name: transaction_detail transaction_detail_yarn_count_id_yarn_count_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_yarn_count_id_yarn_count_master_id_fk FOREIGN KEY (yarn_count_id) REFERENCES public.yarn_count_master(id);


--
-- Name: transaction_detail transaction_detail_yarn_type_id_yarn_type_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_yarn_type_id_yarn_type_master_id_fk FOREIGN KEY (yarn_type_id) REFERENCES public.yarn_type_master(id);


--
-- Name: transaction_header transaction_header_fabric_type_id_fabric_type_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_fabric_type_id_fabric_type_master_id_fk FOREIGN KEY (fabric_type_id) REFERENCES public.fabric_type_master(id);


--
-- Name: transaction_header transaction_header_job_id_job_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_job_id_job_master_id_fk FOREIGN KEY (job_id) REFERENCES public.job_master(id);


--
-- Name: transaction_header transaction_header_location_id_location_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_location_id_location_master_id_fk FOREIGN KEY (location_id) REFERENCES public.location_master(id);


--
-- Name: transaction_header transaction_header_party_id_party_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_party_id_party_master_id_fk FOREIGN KEY (party_id) REFERENCES public.party_master(id);


--
-- Name: transaction_header transaction_header_transaction_type_id_transaction_type_master_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_transaction_type_id_transaction_type_master_ FOREIGN KEY (transaction_type_id) REFERENCES public.transaction_type_master(id);


--
-- PostgreSQL database dump complete
--

\unrestrict R9FYkROb6jBukxShFZVpHSNfZ4KsqOAZ5OQEay9A23POe4Pz5kTZyANZEcKWEk0

