--
-- PostgreSQL database dump
--

\restrict Z1FdGITzDbaRrVDNkXqEeji9F8i06Xdg1k6hAHXIX2mfUPKwoWx8cXDbVpKOaIl

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

--
-- Name: shift; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.shift AS ENUM (
    'Morning',
    'Night'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _applied_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._applied_migrations (
    name text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: configuration; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuration (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    description text,
    enabled boolean DEFAULT true NOT NULL
);


--
-- Name: configuration_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configuration_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configuration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configuration_id_seq OWNED BY public.configuration.id;


--
-- Name: daily_delivery; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_delivery (
    id integer NOT NULL,
    delivery_date date NOT NULL,
    party_id integer NOT NULL,
    challan_no text NOT NULL,
    sl text,
    gsm integer,
    quantity integer NOT NULL,
    net_weight numeric(12,3) NOT NULL,
    status text DEFAULT 'submitted'::text NOT NULL,
    created_by text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by text,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    reconciled boolean DEFAULT false NOT NULL,
    reconciled_transaction_id integer,
    reconciled_at timestamp without time zone,
    yarn_type_id integer NOT NULL,
    CONSTRAINT daily_delivery_net_weight_check CHECK ((net_weight > (0)::numeric)),
    CONSTRAINT daily_delivery_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT daily_delivery_status_check CHECK ((status = ANY (ARRAY['submitted'::text, 'cancelled'::text])))
);


--
-- Name: daily_delivery_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_delivery_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_delivery_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_delivery_id_seq OWNED BY public.daily_delivery.id;


--
-- Name: daily_production_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_production_detail (
    id integer NOT NULL,
    header_id integer NOT NULL,
    roll_number integer NOT NULL,
    roll_weight numeric(10,3) NOT NULL,
    remarks text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT daily_production_detail_roll_weight_check CHECK ((roll_weight > (0)::numeric))
);


--
-- Name: daily_production_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_production_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_production_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_production_detail_id_seq OWNED BY public.daily_production_detail.id;


--
-- Name: daily_production_header; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_production_header (
    id integer NOT NULL,
    production_date date NOT NULL,
    machine_id integer NOT NULL,
    employee_id integer NOT NULL,
    party_id integer NOT NULL,
    shift public.shift NOT NULL,
    status text DEFAULT 'submitted'::text NOT NULL,
    remarks text,
    created_by text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by text,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    reconciled boolean DEFAULT false NOT NULL,
    reconciled_transaction_id integer,
    reconciled_at timestamp without time zone,
    CONSTRAINT daily_production_header_status_check CHECK ((status = ANY (ARRAY['submitted'::text, 'cancelled'::text])))
);


--
-- Name: daily_production_header_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_production_header_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_production_header_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_production_header_id_seq OWNED BY public.daily_production_header.id;


--
-- Name: department_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.department_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL
);


--
-- Name: department_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.department_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: department_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.department_master_id_seq OWNED BY public.department_master.id;


--
-- Name: employee_advances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_advances (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    date text NOT NULL,
    amount numeric NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: employee_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_master (
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


--
-- Name: employee_salary_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_salary_records (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    date text NOT NULL,
    base_wage numeric NOT NULL,
    commission numeric DEFAULT 0 NOT NULL,
    final_salary numeric NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: employee_salary_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_salary_settings (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    base_daily_wage numeric DEFAULT 0 NOT NULL
);


--
-- Name: fabric_type_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fabric_type_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL
);


--
-- Name: fabric_type_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fabric_type_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fabric_type_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fabric_type_master_id_seq OWNED BY public.fabric_type_master.id;


--
-- Name: job_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    party_id integer
);


--
-- Name: job_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.job_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.job_master_id_seq OWNED BY public.job_master.id;


--
-- Name: location_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL
);


--
-- Name: location_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.location_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: location_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.location_master_id_seq OWNED BY public.location_master.id;


--
-- Name: machine_master; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: machine_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machine_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machine_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machine_master_id_seq OWNED BY public.machine_master.id;


--
-- Name: machine_operator_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machine_operator_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machine_operator_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machine_operator_master_id_seq OWNED BY public.employee_master.id;


--
-- Name: operator_advances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_advances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_advances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_advances_id_seq OWNED BY public.employee_advances.id;


--
-- Name: operator_salary_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_salary_records_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_salary_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_salary_records_id_seq OWNED BY public.employee_salary_records.id;


--
-- Name: operator_salary_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operator_salary_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operator_salary_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operator_salary_settings_id_seq OWNED BY public.employee_salary_settings.id;


--
-- Name: party_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.party_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    waste_percent numeric(5,2) DEFAULT 1.00
);


--
-- Name: party_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.party_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: party_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.party_master_id_seq OWNED BY public.party_master.id;


--
-- Name: plausibility_baseline; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plausibility_baseline (
    id integer NOT NULL,
    operation text NOT NULL,
    field text NOT NULL,
    median numeric(18,6) NOT NULL,
    iqr numeric(18,6) NOT NULL,
    mad numeric(18,6) NOT NULL,
    lower_bound numeric(18,6) NOT NULL,
    upper_bound numeric(18,6) NOT NULL,
    sample_count integer DEFAULT 0 NOT NULL,
    computed_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: plausibility_baseline_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plausibility_baseline_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plausibility_baseline_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plausibility_baseline_id_seq OWNED BY public.plausibility_baseline.id;


--
-- Name: plausibility_feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plausibility_feedback (
    id integer NOT NULL,
    operation text NOT NULL,
    field text NOT NULL,
    entered_value numeric(18,6) NOT NULL,
    expected_low numeric(18,6),
    expected_high numeric(18,6),
    outcome text NOT NULL,
    created_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: plausibility_feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plausibility_feedback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plausibility_feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plausibility_feedback_id_seq OWNED BY public.plausibility_feedback.id;


--
-- Name: salary_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.salary_detail (
    id integer NOT NULL,
    header_id integer NOT NULL,
    employee_id integer NOT NULL,
    month integer,
    year integer,
    department_id integer,
    employee_name text NOT NULL,
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


--
-- Name: salary_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.salary_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: salary_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.salary_detail_id_seq OWNED BY public.salary_detail.id;


--
-- Name: salary_header; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: salary_header_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.salary_header_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: salary_header_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.salary_header_id_seq OWNED BY public.salary_header.id;


--
-- Name: transaction_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_detail (
    id integer NOT NULL,
    header_id integer NOT NULL,
    quantity numeric(12,3),
    net_wt numeric(12,3),
    machine_id integer,
    employee_id integer,
    yarn_type_id integer,
    yarn_count_id integer,
    yarn_brand_id integer,
    uom_id integer
);


--
-- Name: transaction_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaction_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transaction_detail_id_seq OWNED BY public.transaction_detail.id;


--
-- Name: transaction_header; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: transaction_header_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaction_header_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_header_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transaction_header_id_seq OWNED BY public.transaction_header.id;


--
-- Name: transaction_type_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_type_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    action text
);


--
-- Name: transaction_type_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaction_type_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_type_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transaction_type_master_id_seq OWNED BY public.transaction_type_master.id;


--
-- Name: uom_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.uom_master (
    id integer NOT NULL,
    name text NOT NULL,
    abbreviation text NOT NULL
);


--
-- Name: uom_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.uom_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: uom_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.uom_master_id_seq OWNED BY public.uom_master.id;


--
-- Name: yarn_brand_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yarn_brand_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL
);


--
-- Name: yarn_brand_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yarn_brand_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yarn_brand_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.yarn_brand_master_id_seq OWNED BY public.yarn_brand_master.id;


--
-- Name: yarn_count_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yarn_count_master (
    id integer NOT NULL,
    name text NOT NULL,
    count text NOT NULL
);


--
-- Name: yarn_count_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yarn_count_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yarn_count_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.yarn_count_master_id_seq OWNED BY public.yarn_count_master.id;


--
-- Name: yarn_receipt_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yarn_receipt_detail (
    id integer NOT NULL,
    header_id integer NOT NULL,
    yarn_count_id integer NOT NULL,
    quantity integer NOT NULL,
    net_weight numeric(12,3) NOT NULL,
    yarn_brand_id integer NOT NULL,
    CONSTRAINT yarn_receipt_detail_net_weight_check CHECK ((net_weight > (0)::numeric)),
    CONSTRAINT yarn_receipt_detail_quantity_check CHECK ((quantity > 0))
);


--
-- Name: yarn_receipt_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yarn_receipt_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yarn_receipt_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.yarn_receipt_detail_id_seq OWNED BY public.yarn_receipt_detail.id;


--
-- Name: yarn_receipt_header; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yarn_receipt_header (
    id integer NOT NULL,
    receipt_date date NOT NULL,
    party_id integer NOT NULL,
    status text DEFAULT 'submitted'::text NOT NULL,
    created_by text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by text,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    reconciled boolean DEFAULT false NOT NULL,
    reconciled_transaction_id integer,
    reconciled_at timestamp without time zone,
    doc_number text NOT NULL,
    CONSTRAINT yarn_receipt_header_status_check CHECK ((status = ANY (ARRAY['submitted'::text, 'cancelled'::text])))
);


--
-- Name: yarn_receipt_header_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yarn_receipt_header_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yarn_receipt_header_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.yarn_receipt_header_id_seq OWNED BY public.yarn_receipt_header.id;


--
-- Name: yarn_type_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yarn_type_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    make_rate numeric
);


--
-- Name: yarn_type_master_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yarn_type_master_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yarn_type_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.yarn_type_master_id_seq OWNED BY public.yarn_type_master.id;


--
-- Name: configuration id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration ALTER COLUMN id SET DEFAULT nextval('public.configuration_id_seq'::regclass);


--
-- Name: daily_delivery id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_delivery ALTER COLUMN id SET DEFAULT nextval('public.daily_delivery_id_seq'::regclass);


--
-- Name: daily_production_detail id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_detail ALTER COLUMN id SET DEFAULT nextval('public.daily_production_detail_id_seq'::regclass);


--
-- Name: daily_production_header id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header ALTER COLUMN id SET DEFAULT nextval('public.daily_production_header_id_seq'::regclass);


--
-- Name: department_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_master ALTER COLUMN id SET DEFAULT nextval('public.department_master_id_seq'::regclass);


--
-- Name: employee_advances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_advances ALTER COLUMN id SET DEFAULT nextval('public.operator_advances_id_seq'::regclass);


--
-- Name: employee_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_master ALTER COLUMN id SET DEFAULT nextval('public.machine_operator_master_id_seq'::regclass);


--
-- Name: employee_salary_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_records ALTER COLUMN id SET DEFAULT nextval('public.operator_salary_records_id_seq'::regclass);


--
-- Name: employee_salary_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_settings ALTER COLUMN id SET DEFAULT nextval('public.operator_salary_settings_id_seq'::regclass);


--
-- Name: fabric_type_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fabric_type_master ALTER COLUMN id SET DEFAULT nextval('public.fabric_type_master_id_seq'::regclass);


--
-- Name: job_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_master ALTER COLUMN id SET DEFAULT nextval('public.job_master_id_seq'::regclass);


--
-- Name: location_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_master ALTER COLUMN id SET DEFAULT nextval('public.location_master_id_seq'::regclass);


--
-- Name: machine_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_master ALTER COLUMN id SET DEFAULT nextval('public.machine_master_id_seq'::regclass);


--
-- Name: party_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.party_master ALTER COLUMN id SET DEFAULT nextval('public.party_master_id_seq'::regclass);


--
-- Name: plausibility_baseline id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plausibility_baseline ALTER COLUMN id SET DEFAULT nextval('public.plausibility_baseline_id_seq'::regclass);


--
-- Name: plausibility_feedback id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plausibility_feedback ALTER COLUMN id SET DEFAULT nextval('public.plausibility_feedback_id_seq'::regclass);


--
-- Name: salary_detail id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail ALTER COLUMN id SET DEFAULT nextval('public.salary_detail_id_seq'::regclass);


--
-- Name: salary_header id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_header ALTER COLUMN id SET DEFAULT nextval('public.salary_header_id_seq'::regclass);


--
-- Name: transaction_detail id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail ALTER COLUMN id SET DEFAULT nextval('public.transaction_detail_id_seq'::regclass);


--
-- Name: transaction_header id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header ALTER COLUMN id SET DEFAULT nextval('public.transaction_header_id_seq'::regclass);


--
-- Name: transaction_type_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_type_master ALTER COLUMN id SET DEFAULT nextval('public.transaction_type_master_id_seq'::regclass);


--
-- Name: uom_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uom_master ALTER COLUMN id SET DEFAULT nextval('public.uom_master_id_seq'::regclass);


--
-- Name: yarn_brand_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_brand_master ALTER COLUMN id SET DEFAULT nextval('public.yarn_brand_master_id_seq'::regclass);


--
-- Name: yarn_count_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_count_master ALTER COLUMN id SET DEFAULT nextval('public.yarn_count_master_id_seq'::regclass);


--
-- Name: yarn_receipt_detail id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_detail ALTER COLUMN id SET DEFAULT nextval('public.yarn_receipt_detail_id_seq'::regclass);


--
-- Name: yarn_receipt_header id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_header ALTER COLUMN id SET DEFAULT nextval('public.yarn_receipt_header_id_seq'::regclass);


--
-- Name: yarn_type_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_type_master ALTER COLUMN id SET DEFAULT nextval('public.yarn_type_master_id_seq'::regclass);


--
-- Data for Name: _applied_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public._applied_migrations (name, applied_at) FROM stdin;
0000_late_living_tribunal.sql	2026-08-07 12:23:06.827453+00
0001_clumsy_the_spike.sql	2026-08-07 12:23:06.993293+00
0002_sweet_marrow.sql	2026-08-07 12:23:07.134481+00
0003_tearful_klaw.sql	2026-08-07 12:23:07.332609+00
0004_reconcile_daily_production.sql	2026-08-07 12:23:07.570993+00
0005_yarn_receipt.sql	2026-08-07 12:23:07.862902+00
0006_daily_delivery.sql	2026-08-07 12:23:08.028868+00
0007_rename_operator_to_employee.sql	2026-08-07 12:23:08.219926+00
0008_create_configuration.sql	2026-08-07 12:23:08.378242+00
0009_seed_configuration.sql	2026-08-07 12:23:08.548646+00
0010_plausibility_validation.sql	2026-08-11 06:43:15.097289+00
\.


--
-- Data for Name: configuration; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.configuration (id, name, code, description, enabled) FROM stdin;
1	Reconciled lock	0001	used to enable/disable Reconciliation lock in daily operations	t
\.


--
-- Data for Name: daily_delivery; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_delivery (id, delivery_date, party_id, challan_no, sl, gsm, quantity, net_weight, status, created_by, created_at, updated_by, updated_at, reconciled, reconciled_transaction_id, reconciled_at, yarn_type_id) FROM stdin;
24	2026-08-10	13	3754	960+720+370	250	42	1116.150	submitted	Iftikhar 	2026-08-10 07:34:04.360986	\N	2026-08-10 07:34:04.360986	t	190	2026-08-10 10:30:29.442	20
27	2026-08-10	14	D-3757	940+640+384	345	27	759.350	submitted	Iftikhar 	2026-08-10 07:36:55.958949	\N	2026-08-10 07:36:55.958949	t	191	2026-08-10 10:36:36.152	20
25	2026-08-10	14	3755	940+662+395	345	36	1011.850	submitted	Iftikhar 	2026-08-10 07:34:59.665056	\N	2026-08-10 07:34:59.665056	t	191	2026-08-10 10:36:36.152	20
26	2026-08-10	14	3756	940+662+395	345	49	1391.000	submitted	Iftikhar 	2026-08-10 07:35:52.138509	\N	2026-08-10 07:35:52.138509	t	191	2026-08-10 10:36:36.152	20
7	2026-08-01	13	3735	960+720+370	250	27	694.750	submitted	Iftikhar 	2026-08-06 12:19:38.742471	\N	2026-08-06 12:19:38.742471	t	161	2026-08-07 12:37:27.219	20
8	2026-08-03	13	3736	960+720+370	250	47	1233.900	submitted	Iftikhar 	2026-08-06 12:21:22.753913	\N	2026-08-06 12:21:22.753913	t	162	2026-08-07 12:41:07.182	20
17	2026-08-03	15	3737	1020+740+410	\N	37	990.450	submitted	Iftikhar 	2026-08-06 13:28:50.974992	\N	2026-08-06 13:28:50.974992	t	163	2026-08-07 12:47:22.057	20
9	2026-08-04	13	3738	960+720+370	250	20	498.150	submitted	Iftikhar 	2026-08-06 12:22:22.726969	\N	2026-08-06 12:22:22.726969	t	170	2026-08-08 07:01:16.924	20
18	2026-08-04	20	3739	960+670+400	\N	2	39.700	submitted	Iftikhar 	2026-08-06 13:30:30.629482	\N	2026-08-06 13:30:30.629482	t	171	2026-08-08 07:02:25.572	20
11	2026-08-04	16	3740	820	\N	1	5.300	submitted	Iftikhar 	2026-08-06 13:13:02.850451	\N	2026-08-06 13:13:02.850451	t	172	2026-08-08 07:06:33.654	22
12	2026-08-04	16	3740	1160	\N	1	9.500	submitted	Iftikhar 	2026-08-06 13:14:18.421923	\N	2026-08-06 13:14:18.421923	t	172	2026-08-08 07:06:33.654	24
14	2026-08-04	16	3742	1060+730+410	\N	14	401.700	submitted	Iftikhar 	2026-08-06 13:17:32.154431	\N	2026-08-06 13:17:32.154431	t	172	2026-08-08 07:06:33.654	20
16	2026-08-04	16	3742	1160	\N	4	100.050	submitted	Iftikhar 	2026-08-06 13:19:53.154209	\N	2026-08-06 13:19:53.154209	t	172	2026-08-08 07:06:33.654	24
13	2026-08-04	16	3741	1160	\N	19	561.250	submitted	Iftikhar 	2026-08-06 13:15:38.784798	Iftikhar 	2026-08-06 13:20:56.385	t	172	2026-08-08 07:06:33.654	24
15	2026-08-04	16	3742	820	140	1	11.800	submitted	Iftikhar 	2026-08-06 13:18:53.501896	Iftikhar 	2026-08-06 13:21:15.74	t	172	2026-08-08 07:06:33.654	22
19	2026-08-04	17	3743	1050+700+405	210	18	439.850	submitted	Iftikhar 	2026-08-06 13:32:33.689048	\N	2026-08-06 13:32:33.689048	t	173	2026-08-08 07:07:55.163	20
3	2026-08-05	14	3744	940+662+395	250	58	1721.300	submitted	Iftikhar 	2026-08-06 10:11:17.157237	\N	2026-08-06 10:11:17.157237	t	174	2026-08-08 07:09:33.234	20
4	2026-08-05	14	3745	940+662+395	250	59	1717.850	submitted	Iftikhar 	2026-08-06 10:12:28.906007	\N	2026-08-06 10:12:28.906007	t	174	2026-08-08 07:09:33.234	20
10	2026-08-05	13	3746	960+720+370	250	15	384.800	submitted	Iftikhar 	2026-08-06 12:23:52.485668	\N	2026-08-06 12:23:52.485668	t	175	2026-08-08 07:12:14.027	20
5	2026-08-06	14	3747	940+662+395	250	50	1422.800	submitted	Iftikhar 	2026-08-06 10:13:52.292123	Iftikhar 	2026-08-06 13:23:26.528	t	176	2026-08-08 07:13:44.041	20
6	2026-08-06	14	3748	940+662+395	250	59	1663.250	submitted	Iftikhar 	2026-08-06 10:14:46.992303	Iftikhar 	2026-08-06 13:23:55.892	t	176	2026-08-08 07:13:44.041	20
2	2026-08-06	13	3749	960+720+370	245	22	599.300	submitted	Iftikhar 	2026-08-06 09:37:19.084532	Iftikhar 	2026-08-06 12:17:49.83	t	177	2026-08-08 07:15:21.916	20
20	2026-08-07	13	3750	960+720+370	250	25	672.600	submitted	Iftikhar 	2026-08-07 10:24:04.049319	\N	2026-08-07 10:24:04.049319	t	178	2026-08-08 07:16:19.208	20
21	2026-08-07	14	3751	940+640+384	342	52	1514.900	submitted	Iftikhar 	2026-08-07 11:07:58.052085	\N	2026-08-07 11:07:58.052085	t	179	2026-08-08 07:18:48.911	20
22	2026-08-07	14	3752	940+640+384	245	52	1518.400	submitted	Iftikhar 	2026-08-07 15:37:46.719266	\N	2026-08-07 15:37:46.719266	t	179	2026-08-08 07:18:48.911	20
23	2026-08-08	13	3753	960+720+370	250	25	671.800	submitted	Iftikhar 	2026-08-08 06:24:28.201474	\N	2026-08-08 06:24:28.201474	t	180	2026-08-08 07:19:38.526	20
29	2026-08-11	13	3759	960+720+370	250	47	1137.500	submitted	Iftikhar 	2026-08-11 08:02:53.830219	\N	2026-08-11 08:02:53.830219	f	\N	\N	20
28	2026-08-10	16	3758	1160	245	6	150.600	submitted	Iftikhar 	2026-08-10 14:00:45.636968	\N	2026-08-10 14:00:45.636968	t	199	2026-08-11 08:09:50.771	24
30	2026-08-11	16	3760	1060+730+410	\N	60	1564.400	submitted	Iftikhar 	2026-08-11 11:09:58.933201	\N	2026-08-11 11:09:58.933201	f	\N	\N	20
31	2026-08-11	16	D-3761	\N	\N	26	718.900	submitted	Iftikhar 	2026-08-11 11:10:58.071828	\N	2026-08-11 11:10:58.071828	f	\N	\N	24
32	2026-08-11	16	D-3762	1060+730+410	\N	10	270.650	submitted	Iftikhar 	2026-08-11 11:11:52.777587	\N	2026-08-11 11:11:52.777587	f	\N	\N	20
\.


--
-- Data for Name: daily_production_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_production_detail (id, header_id, roll_number, roll_weight, remarks, created_at) FROM stdin;
13	4	1	28.000	\N	2026-08-04 09:10:42.87511
14	4	2	29.450	\N	2026-08-04 09:10:42.87511
15	4	3	28.800	\N	2026-08-04 09:10:42.87511
16	4	4	23.300	\N	2026-08-04 09:10:42.87511
17	4	5	29.150	\N	2026-08-04 09:10:42.87511
18	4	6	23.600	\N	2026-08-04 09:10:42.87511
21	6	1	31.150	\N	2026-08-04 09:18:31.354253
22	6	2	29.900	\N	2026-08-04 09:18:31.354253
23	6	3	26.100	\N	2026-08-04 09:18:31.354253
24	6	4	30.350	\N	2026-08-04 09:18:31.354253
25	6	5	27.350	\N	2026-08-04 09:18:31.354253
26	6	6	11.300	\N	2026-08-04 09:18:31.354253
27	7	1	27.300	\N	2026-08-04 09:20:23.329666
28	7	2	17.100	\N	2026-08-04 09:20:23.329666
29	7	3	16.050	\N	2026-08-04 09:20:23.329666
30	7	4	20.550	\N	2026-08-04 09:20:23.329666
31	7	5	25.700	\N	2026-08-04 09:20:23.329666
32	7	6	21.300	\N	2026-08-04 09:20:23.329666
33	7	7	20.400	\N	2026-08-04 09:20:23.329666
36	5	1	29.250	\N	2026-08-04 09:23:18.321417
37	5	2	28.200	\N	2026-08-04 09:23:18.321417
38	5	3	30.850	\N	2026-08-04 09:23:18.321417
39	8	1	28.750	\N	2026-08-04 09:25:40.653893
40	8	2	35.100	\N	2026-08-04 09:25:40.653893
41	8	3	28.800	\N	2026-08-04 09:25:40.653893
42	8	4	28.300	\N	2026-08-04 09:25:40.653893
43	8	5	32.200	\N	2026-08-04 09:25:40.653893
44	8	6	21.750	\N	2026-08-04 09:25:40.653893
45	9	1	26.000	\N	2026-08-04 09:27:15.003235
46	9	2	27.700	\N	2026-08-04 09:27:15.003235
47	9	3	22.700	\N	2026-08-04 09:27:15.003235
48	9	4	29.400	\N	2026-08-04 09:27:15.003235
49	9	5	29.400	\N	2026-08-04 09:27:15.003235
50	9	6	25.850	\N	2026-08-04 09:27:15.003235
51	10	1	26.650	\N	2026-08-04 09:28:57.85111
52	10	2	28.300	\N	2026-08-04 09:28:57.85111
53	10	3	23.900	\N	2026-08-04 09:28:57.85111
54	10	4	19.900	\N	2026-08-04 09:28:57.85111
55	10	5	27.300	\N	2026-08-04 09:28:57.85111
56	10	6	19.200	\N	2026-08-04 09:28:57.85111
57	10	7	22.650	\N	2026-08-04 09:28:57.85111
58	11	1	19.150	\N	2026-08-04 09:30:40.700423
59	11	2	29.650	\N	2026-08-04 09:30:40.700423
60	11	3	29.450	\N	2026-08-04 09:30:40.700423
61	11	4	29.800	\N	2026-08-04 09:30:40.700423
62	11	5	15.300	\N	2026-08-04 09:30:40.700423
63	11	6	25.100	\N	2026-08-04 09:30:40.700423
64	12	1	30.700	\N	2026-08-04 09:34:40.40951
65	12	2	27.750	\N	2026-08-04 09:34:40.40951
66	12	3	36.850	\N	2026-08-04 09:34:40.40951
67	12	4	27.850	\N	2026-08-04 09:34:40.40951
68	12	5	27.800	\N	2026-08-04 09:34:40.40951
69	12	6	27.750	\N	2026-08-04 09:34:40.40951
70	12	7	27.700	\N	2026-08-04 09:34:40.40951
71	13	1	26.750	\N	2026-08-04 09:36:49.21394
72	13	2	26.150	\N	2026-08-04 09:36:49.21394
73	13	3	28.100	\N	2026-08-04 09:36:49.21394
74	13	4	28.100	\N	2026-08-04 09:36:49.21394
75	13	5	29.500	\N	2026-08-04 09:36:49.21394
76	13	6	26.900	\N	2026-08-04 09:36:49.21394
77	13	7	28.150	\N	2026-08-04 09:36:49.21394
78	13	8	29.350	\N	2026-08-04 09:36:49.21394
79	13	9	28.200	\N	2026-08-04 09:36:49.21394
80	14	1	28.900	\N	2026-08-04 09:37:42.188473
81	14	2	28.600	\N	2026-08-04 09:37:42.188473
82	14	3	28.750	\N	2026-08-04 09:37:42.188473
83	14	4	29.900	\N	2026-08-04 09:37:42.188473
84	15	1	26.400	\N	2026-08-04 09:40:48.902839
85	15	2	25.200	\N	2026-08-04 09:40:48.902839
86	15	3	25.700	\N	2026-08-04 09:40:48.902839
87	15	4	27.300	\N	2026-08-04 09:40:48.902839
90	17	1	29.550	\N	2026-08-04 09:45:30.288701
91	17	2	26.100	\N	2026-08-04 09:45:30.288701
92	17	3	24.700	\N	2026-08-04 09:45:30.288701
93	17	4	31.400	\N	2026-08-04 09:45:30.288701
94	17	5	27.550	\N	2026-08-04 09:45:30.288701
95	17	6	31.600	\N	2026-08-04 09:45:30.288701
96	17	7	29.550	\N	2026-08-04 09:45:30.288701
97	17	8	29.950	\N	2026-08-04 09:45:30.288701
98	18	1	33.750	\N	2026-08-04 09:46:52.771207
99	18	2	30.650	\N	2026-08-04 09:46:52.771207
100	18	3	25.900	\N	2026-08-04 09:46:52.771207
101	18	4	32.350	\N	2026-08-04 09:46:52.771207
102	18	5	30.600	\N	2026-08-04 09:46:52.771207
103	19	1	11.500	\N	2026-08-04 09:54:11.999346
104	19	2	24.800	\N	2026-08-04 09:54:11.999346
105	19	3	27.000	\N	2026-08-04 09:54:11.999346
106	19	4	27.050	\N	2026-08-04 09:54:11.999346
107	19	5	24.900	\N	2026-08-04 09:54:11.999346
108	19	6	27.900	\N	2026-08-04 09:54:11.999346
109	19	7	25.200	\N	2026-08-04 09:54:11.999346
110	19	8	25.850	\N	2026-08-04 09:54:11.999346
118	21	1	27.600	\N	2026-08-04 10:01:26.358251
119	21	2	28.750	\N	2026-08-04 10:01:26.358251
120	21	3	24.800	\N	2026-08-04 10:01:26.358251
121	21	4	30.950	\N	2026-08-04 10:01:26.358251
122	21	5	29.900	\N	2026-08-04 10:01:26.358251
123	21	6	29.400	\N	2026-08-04 10:01:26.358251
124	21	7	29.900	\N	2026-08-04 10:01:26.358251
125	22	1	29.500	\N	2026-08-04 10:02:51.515396
126	22	2	29.650	\N	2026-08-04 10:02:51.515396
127	22	3	29.500	\N	2026-08-04 10:02:51.515396
128	22	4	25.850	\N	2026-08-04 10:02:51.515396
129	22	5	34.700	\N	2026-08-04 10:02:51.515396
130	22	6	32.300	\N	2026-08-04 10:02:51.515396
131	22	7	29.500	\N	2026-08-04 10:02:51.515396
132	22	8	29.050	\N	2026-08-04 10:02:51.515396
133	22	9	26.750	\N	2026-08-04 10:02:51.515396
138	23	1	31.150	\N	2026-08-04 10:05:41.440994
139	23	2	28.400	\N	2026-08-04 10:05:41.440994
140	23	3	27.900	\N	2026-08-04 10:05:41.440994
141	23	4	28.850	\N	2026-08-04 10:05:41.440994
142	23	5	31.500	\N	2026-08-04 10:05:41.440994
143	23	6	26.850	\N	2026-08-04 10:05:41.440994
144	24	1	21.300	\N	2026-08-04 10:06:51.146146
145	24	2	25.050	\N	2026-08-04 10:06:51.146146
146	24	3	27.500	\N	2026-08-04 10:06:51.146146
147	24	4	28.850	\N	2026-08-04 10:06:51.146146
148	25	1	27.950	\N	2026-08-04 10:07:59.206754
149	25	2	28.100	\N	2026-08-04 10:07:59.206754
150	25	3	23.000	\N	2026-08-04 10:07:59.206754
151	25	4	23.450	\N	2026-08-04 10:07:59.206754
152	25	5	26.050	\N	2026-08-04 10:07:59.206754
153	25	6	20.000	\N	2026-08-04 10:07:59.206754
154	25	7	22.650	\N	2026-08-04 10:07:59.206754
155	25	8	28.150	\N	2026-08-04 10:07:59.206754
156	26	1	25.450	\N	2026-08-04 10:08:59.403701
157	26	2	29.000	\N	2026-08-04 10:08:59.403701
158	26	3	28.250	\N	2026-08-04 10:08:59.403701
159	26	4	20.850	\N	2026-08-04 10:08:59.403701
160	26	5	28.350	\N	2026-08-04 10:08:59.403701
161	26	6	18.850	\N	2026-08-04 10:08:59.403701
162	27	1	30.200	\N	2026-08-04 10:10:14.184358
163	27	2	30.000	\N	2026-08-04 10:10:14.184358
164	27	3	26.350	\N	2026-08-04 10:10:14.184358
165	27	4	25.850	\N	2026-08-04 10:10:14.184358
166	27	5	17.350	\N	2026-08-04 10:10:14.184358
167	27	6	28.350	\N	2026-08-04 10:10:14.184358
168	27	7	28.100	\N	2026-08-04 10:10:14.184358
169	28	1	30.200	\N	2026-08-04 10:11:18.644384
170	28	2	19.950	\N	2026-08-04 10:11:18.644384
171	28	3	29.500	\N	2026-08-04 10:11:18.644384
172	28	4	30.200	\N	2026-08-04 10:11:18.644384
173	28	5	28.950	\N	2026-08-04 10:11:18.644384
174	28	6	28.750	\N	2026-08-04 10:11:18.644384
175	29	1	31.500	\N	2026-08-04 10:44:10.948865
176	29	2	31.700	\N	2026-08-04 10:44:10.948865
177	29	3	35.950	\N	2026-08-04 10:44:10.948865
178	29	4	27.300	\N	2026-08-04 10:44:10.948865
179	29	5	28.950	\N	2026-08-04 10:44:10.948865
180	29	6	26.950	\N	2026-08-04 10:44:10.948865
181	29	7	29.000	\N	2026-08-04 10:44:10.948865
183	31	1	33.100	\N	2026-08-04 11:02:23.167923
184	31	2	29.550	\N	2026-08-04 11:02:23.167923
185	31	3	30.850	\N	2026-08-04 11:02:23.167923
186	31	4	29.150	\N	2026-08-04 11:02:23.167923
187	31	5	30.400	\N	2026-08-04 11:02:23.167923
188	31	6	32.450	\N	2026-08-04 11:02:23.167923
189	31	7	29.850	\N	2026-08-04 11:02:23.167923
190	31	8	28.100	\N	2026-08-04 11:02:23.167923
191	32	1	25.200	\N	2026-08-04 11:03:01.847261
192	32	2	31.050	\N	2026-08-04 11:03:01.847261
193	33	1	23.800	\N	2026-08-04 11:04:36.849782
194	34	1	30.850	\N	2026-08-04 11:05:46.793537
195	34	2	28.950	\N	2026-08-04 11:05:46.793537
196	34	3	29.400	\N	2026-08-04 11:05:46.793537
197	34	4	32.300	\N	2026-08-04 11:05:46.793537
198	34	5	25.700	\N	2026-08-04 11:05:46.793537
199	34	6	30.850	\N	2026-08-04 11:05:46.793537
200	34	7	31.650	\N	2026-08-04 11:05:46.793537
201	35	1	16.450	\N	2026-08-04 11:06:46.274667
202	35	2	26.550	\N	2026-08-04 11:06:46.274667
203	35	3	34.150	\N	2026-08-04 11:06:46.274667
204	35	4	31.000	\N	2026-08-04 11:06:46.274667
205	36	1	20.000	\N	2026-08-04 11:07:56.979945
206	36	2	25.200	\N	2026-08-04 11:07:56.979945
207	36	3	27.150	\N	2026-08-04 11:07:56.979945
208	36	4	25.500	\N	2026-08-04 11:07:56.979945
209	36	5	23.550	\N	2026-08-04 11:07:56.979945
210	36	6	27.400	\N	2026-08-04 11:07:56.979945
211	36	7	26.250	\N	2026-08-04 11:07:56.979945
212	36	8	9.900	\N	2026-08-04 11:07:56.979945
213	37	1	35.450	\N	2026-08-04 11:08:47.644403
214	37	2	28.250	\N	2026-08-04 11:08:47.644403
215	37	3	27.450	\N	2026-08-04 11:08:47.644403
216	38	1	29.300	\N	2026-08-04 11:10:01.18467
217	38	2	29.450	\N	2026-08-04 11:10:01.18467
218	38	3	29.600	\N	2026-08-04 11:10:01.18467
219	38	4	29.650	\N	2026-08-04 11:10:01.18467
220	38	5	21.300	\N	2026-08-04 11:10:01.18467
221	38	6	28.150	\N	2026-08-04 11:10:01.18467
222	39	1	29.650	\N	2026-08-04 11:14:57.548808
223	39	2	29.750	\N	2026-08-04 11:14:57.548808
224	39	3	29.550	\N	2026-08-04 11:14:57.548808
225	39	4	29.550	\N	2026-08-04 11:14:57.548808
226	39	5	29.750	\N	2026-08-04 11:14:57.548808
227	39	6	29.650	\N	2026-08-04 11:14:57.548808
228	39	7	24.200	\N	2026-08-04 11:14:57.548808
229	39	8	26.550	\N	2026-08-04 11:14:57.548808
230	39	9	28.050	\N	2026-08-04 11:14:57.548808
231	40	1	30.400	\N	2026-08-04 11:15:49.435534
232	40	2	32.000	\N	2026-08-04 11:15:49.435534
233	40	3	30.250	\N	2026-08-04 11:15:49.435534
234	40	4	31.000	\N	2026-08-04 11:15:49.435534
235	40	5	33.500	\N	2026-08-04 11:15:49.435534
236	41	1	21.750	\N	2026-08-04 11:16:54.358067
237	41	2	29.500	\N	2026-08-04 11:16:54.358067
238	41	3	21.850	\N	2026-08-04 11:16:54.358067
239	41	4	29.650	\N	2026-08-04 11:16:54.358067
240	41	5	16.400	\N	2026-08-04 11:16:54.358067
241	42	1	26.250	\N	2026-08-04 11:18:01.178238
242	42	2	26.000	\N	2026-08-04 11:18:01.178238
243	42	3	28.550	\N	2026-08-04 11:18:01.178238
244	42	4	29.850	\N	2026-08-04 11:18:01.178238
245	42	5	32.700	\N	2026-08-04 11:18:01.178238
246	42	6	32.100	\N	2026-08-04 11:18:01.178238
247	42	7	17.000	\N	2026-08-04 11:18:01.178238
248	43	1	26.500	\N	2026-08-04 11:18:37.003406
249	43	2	33.000	\N	2026-08-04 11:18:37.003406
250	43	3	30.350	\N	2026-08-04 11:18:37.003406
251	44	1	29.850	\N	2026-08-04 11:19:37.030411
252	44	2	28.400	\N	2026-08-04 11:19:37.030411
253	44	3	28.200	\N	2026-08-04 11:19:37.030411
254	44	4	27.000	\N	2026-08-04 11:19:37.030411
255	44	5	24.200	\N	2026-08-04 11:19:37.030411
256	44	6	24.700	\N	2026-08-04 11:19:37.030411
257	45	1	32.950	\N	2026-08-04 11:21:22.562363
258	45	2	33.400	\N	2026-08-04 11:21:22.562363
259	45	3	27.800	\N	2026-08-04 11:21:22.562363
260	45	4	25.900	\N	2026-08-04 11:21:22.562363
261	45	5	29.250	\N	2026-08-04 11:21:22.562363
262	45	6	27.250	\N	2026-08-04 11:21:22.562363
263	45	7	32.950	\N	2026-08-04 11:21:22.562363
264	46	1	32.750	\N	2026-08-04 11:22:21.680401
265	46	2	33.300	\N	2026-08-04 11:22:21.680401
266	46	3	34.250	\N	2026-08-04 11:22:21.680401
267	46	4	28.200	\N	2026-08-04 11:22:21.680401
268	46	5	28.050	\N	2026-08-04 11:22:21.680401
269	46	6	29.600	\N	2026-08-04 11:22:21.680401
270	46	7	30.450	\N	2026-08-04 11:22:21.680401
271	46	8	36.000	\N	2026-08-04 11:22:21.680401
272	47	1	22.800	\N	2026-08-04 11:23:27.891391
273	47	2	22.850	\N	2026-08-04 11:23:27.891391
274	47	3	28.750	\N	2026-08-04 11:23:27.891391
275	47	4	30.550	\N	2026-08-04 11:23:27.891391
276	47	5	31.000	\N	2026-08-04 11:23:27.891391
277	47	6	29.750	\N	2026-08-04 11:23:27.891391
278	47	7	29.300	\N	2026-08-04 11:23:27.891391
279	47	8	28.800	\N	2026-08-04 11:23:27.891391
280	48	1	21.800	\N	2026-08-04 11:24:21.364634
281	48	2	24.000	\N	2026-08-04 11:24:21.364634
282	48	3	27.200	\N	2026-08-04 11:24:21.364634
283	48	4	27.700	\N	2026-08-04 11:24:21.364634
284	48	5	26.300	\N	2026-08-04 11:24:21.364634
285	49	1	19.000	\N	2026-08-04 11:25:27.95248
286	49	2	32.450	\N	2026-08-04 11:25:27.95248
287	49	3	25.900	\N	2026-08-04 11:25:27.95248
288	49	4	32.000	\N	2026-08-04 11:25:27.95248
289	49	5	22.800	\N	2026-08-04 11:25:27.95248
290	49	6	25.800	\N	2026-08-04 11:25:27.95248
291	49	7	31.150	\N	2026-08-04 11:25:27.95248
292	49	8	29.250	\N	2026-08-04 11:25:27.95248
293	50	1	19.600	\N	2026-08-04 11:26:53.291837
294	50	2	19.650	\N	2026-08-04 11:26:53.291837
295	50	3	26.300	\N	2026-08-04 11:26:53.291837
296	50	4	25.850	\N	2026-08-04 11:26:53.291837
297	50	5	28.200	\N	2026-08-04 11:26:53.291837
298	50	6	27.450	\N	2026-08-04 11:26:53.291837
299	50	7	25.550	\N	2026-08-04 11:26:53.291837
300	50	8	27.000	\N	2026-08-04 11:26:53.291837
301	16	1	25.600	\N	2026-08-04 13:45:14.162052
302	16	2	14.100	\N	2026-08-04 13:45:14.162052
318	53	1	28.500	\N	2026-08-05 05:19:28.381793
319	53	2	28.750	\N	2026-08-05 05:19:28.381793
320	53	3	20.050	\N	2026-08-05 05:19:28.381793
321	53	4	30.050	\N	2026-08-05 05:19:28.381793
322	53	5	34.200	\N	2026-08-05 05:19:28.381793
323	53	6	32.950	\N	2026-08-05 05:19:28.381793
324	53	7	35.650	\N	2026-08-05 05:19:28.381793
325	54	1	15.100	\N	2026-08-05 05:20:10.782671
332	56	1	28.800	\N	2026-08-05 05:22:54.381768
333	56	2	27.600	\N	2026-08-05 05:22:54.381768
334	56	3	29.450	\N	2026-08-05 05:22:54.381768
335	56	4	28.900	\N	2026-08-05 05:22:54.381768
336	56	5	27.750	\N	2026-08-05 05:22:54.381768
337	56	6	26.050	\N	2026-08-05 05:22:54.381768
338	56	7	25.650	\N	2026-08-05 05:22:54.381768
339	57	1	32.050	\N	2026-08-05 05:23:56.914664
340	57	2	32.050	\N	2026-08-05 05:23:56.914664
341	57	3	35.600	\N	2026-08-05 05:23:56.914664
342	57	4	32.100	\N	2026-08-05 05:23:56.914664
343	57	5	34.250	\N	2026-08-05 05:23:56.914664
344	57	6	33.500	\N	2026-08-05 05:23:56.914664
345	57	7	31.300	\N	2026-08-05 05:23:56.914664
346	57	8	35.200	\N	2026-08-05 05:23:56.914664
347	58	1	20.000	\N	2026-08-05 05:25:07.609832
348	58	2	23.100	\N	2026-08-05 05:25:07.609832
349	58	3	31.450	\N	2026-08-05 05:25:07.609832
350	58	4	33.950	\N	2026-08-05 05:25:07.609832
351	58	5	31.350	\N	2026-08-05 05:25:07.609832
352	58	6	34.300	\N	2026-08-05 05:25:07.609832
353	58	7	33.650	\N	2026-08-05 05:25:07.609832
354	58	8	32.800	\N	2026-08-05 05:25:07.609832
355	58	9	35.050	\N	2026-08-05 05:25:07.609832
356	59	1	26.550	\N	2026-08-05 05:26:18.500287
357	59	2	26.400	\N	2026-08-05 05:26:18.500287
358	59	3	26.800	\N	2026-08-05 05:26:18.500287
359	59	4	26.200	\N	2026-08-05 05:26:18.500287
360	59	5	26.850	\N	2026-08-05 05:26:18.500287
361	59	6	27.250	\N	2026-08-05 05:26:18.500287
362	59	7	26.150	\N	2026-08-05 05:26:18.500287
363	59	8	26.550	\N	2026-08-05 05:26:18.500287
370	52	1	29.650	\N	2026-08-05 14:53:59.237638
371	52	2	27.800	\N	2026-08-05 14:53:59.237638
372	52	3	29.600	\N	2026-08-05 14:53:59.237638
373	52	4	29.150	\N	2026-08-05 14:53:59.237638
374	52	5	29.750	\N	2026-08-05 14:53:59.237638
375	52	6	28.800	\N	2026-08-05 14:53:59.237638
376	52	7	29.650	\N	2026-08-05 14:53:59.237638
377	52	8	19.850	\N	2026-08-05 14:53:59.237638
378	52	9	28.550	\N	2026-08-05 14:53:59.237638
385	51	1	28.100	\N	2026-08-05 23:02:26.289543
386	51	2	29.050	\N	2026-08-05 23:02:26.289543
387	51	3	28.250	\N	2026-08-05 23:02:26.289543
388	51	4	29.800	\N	2026-08-05 23:02:26.289543
389	51	5	28.000	\N	2026-08-05 23:02:26.289543
390	51	6	27.850	\N	2026-08-05 23:02:26.289543
391	60	1	28.400	\N	2026-08-06 05:12:09.379561
392	60	2	29.650	\N	2026-08-06 05:12:09.379561
393	60	3	29.700	\N	2026-08-06 05:12:09.379561
394	60	4	27.750	\N	2026-08-06 05:12:09.379561
395	60	5	17.350	\N	2026-08-06 05:12:09.379561
396	60	6	27.850	\N	2026-08-06 05:12:09.379561
397	60	7	14.300	\N	2026-08-06 05:12:09.379561
398	61	1	31.350	\N	2026-08-06 05:13:41.179759
399	61	2	31.450	\N	2026-08-06 05:13:41.179759
400	61	3	29.650	\N	2026-08-06 05:13:41.179759
401	61	4	29.800	\N	2026-08-06 05:13:41.179759
402	61	5	32.100	\N	2026-08-06 05:13:41.179759
403	61	6	32.100	\N	2026-08-06 05:13:41.179759
404	61	7	30.900	\N	2026-08-06 05:13:41.179759
405	61	8	32.650	\N	2026-08-06 05:13:41.179759
406	61	9	31.750	\N	2026-08-06 05:13:41.179759
407	62	1	30.800	\N	2026-08-06 05:14:54.170255
408	62	2	31.700	\N	2026-08-06 05:14:54.170255
409	62	3	31.100	\N	2026-08-06 05:14:54.170255
410	62	4	30.550	\N	2026-08-06 05:14:54.170255
411	62	5	34.150	\N	2026-08-06 05:14:54.170255
412	62	6	30.600	\N	2026-08-06 05:14:54.170255
413	62	7	29.650	\N	2026-08-06 05:14:54.170255
414	62	8	21.000	\N	2026-08-06 05:14:54.170255
415	62	9	26.600	\N	2026-08-06 05:14:54.170255
423	64	1	24.850	\N	2026-08-06 05:18:20.391739
424	64	2	28.250	\N	2026-08-06 05:18:20.391739
431	66	1	27.350	\N	2026-08-06 05:21:03.119254
432	66	2	28.900	\N	2026-08-06 05:21:03.119254
433	66	3	31.300	\N	2026-08-06 05:21:03.119254
434	66	4	27.400	\N	2026-08-06 05:21:03.119254
435	66	5	34.150	\N	2026-08-06 05:21:03.119254
436	66	6	27.250	\N	2026-08-06 05:21:03.119254
437	66	7	25.650	\N	2026-08-06 05:21:03.119254
438	66	8	29.150	\N	2026-08-06 05:21:03.119254
439	66	9	37.900	\N	2026-08-06 05:21:03.119254
440	67	1	29.050	\N	2026-08-06 05:23:48.398276
441	67	2	26.500	\N	2026-08-06 05:23:48.398276
442	67	3	28.100	\N	2026-08-06 05:23:48.398276
443	67	4	26.050	\N	2026-08-06 05:23:48.398276
444	67	5	27.400	\N	2026-08-06 05:23:48.398276
445	67	6	28.550	\N	2026-08-06 05:23:48.398276
446	67	7	28.850	\N	2026-08-06 05:23:48.398276
447	67	8	26.000	\N	2026-08-06 05:23:48.398276
448	67	9	26.700	\N	2026-08-06 05:23:48.398276
449	67	10	29.150	\N	2026-08-06 05:23:48.398276
450	68	1	23.600	\N	2026-08-06 05:24:47.564861
451	68	2	27.250	\N	2026-08-06 05:24:47.564861
452	68	3	26.450	\N	2026-08-06 05:24:47.564861
453	68	4	26.650	\N	2026-08-06 05:24:47.564861
454	68	5	30.650	\N	2026-08-06 05:24:47.564861
455	68	6	26.600	\N	2026-08-06 05:24:47.564861
456	68	7	28.800	\N	2026-08-06 05:24:47.564861
457	69	1	33.300	\N	2026-08-06 05:25:38.115455
458	69	2	28.150	\N	2026-08-06 05:25:38.115455
459	69	3	25.000	\N	2026-08-06 05:25:38.115455
460	69	4	27.050	\N	2026-08-06 05:25:38.115455
461	69	5	27.150	\N	2026-08-06 05:25:38.115455
462	69	6	30.850	\N	2026-08-06 05:25:38.115455
463	65	1	22.850	\N	2026-08-06 05:26:52.715078
464	65	2	26.450	\N	2026-08-06 05:26:52.715078
465	65	3	26.750	\N	2026-08-06 05:26:52.715078
466	65	4	26.150	\N	2026-08-06 05:26:52.715078
467	65	5	27.800	\N	2026-08-06 05:26:52.715078
468	65	6	28.600	\N	2026-08-06 05:26:52.715078
469	63	1	27.650	\N	2026-08-06 09:50:06.52753
470	63	2	26.650	\N	2026-08-06 09:50:06.52753
471	63	3	34.250	\N	2026-08-06 09:50:06.52753
472	63	4	18.350	\N	2026-08-06 09:50:06.52753
473	63	5	26.350	\N	2026-08-06 09:50:06.52753
474	63	6	30.450	\N	2026-08-06 09:50:06.52753
475	63	7	20.650	\N	2026-08-06 09:50:06.52753
476	55	1	25.000	\N	2026-08-06 10:19:47.339954
477	55	2	22.600	\N	2026-08-06 10:19:47.339954
478	55	3	26.650	\N	2026-08-06 10:19:47.339954
479	55	4	26.650	\N	2026-08-06 10:19:47.339954
480	55	5	22.500	\N	2026-08-06 10:19:47.339954
481	55	6	21.650	\N	2026-08-06 10:19:47.339954
482	70	1	29.050	\N	2026-08-07 05:23:01.634685
483	70	2	29.200	\N	2026-08-07 05:23:01.634685
484	70	3	30.250	\N	2026-08-07 05:23:01.634685
485	70	4	33.650	\N	2026-08-07 05:23:01.634685
486	70	5	27.650	\N	2026-08-07 05:23:01.634685
487	70	6	29.950	\N	2026-08-07 05:23:01.634685
488	71	1	30.950	\N	2026-08-07 05:25:39.804931
489	71	2	29.550	\N	2026-08-07 05:25:39.804931
490	71	3	27.800	\N	2026-08-07 05:25:39.804931
491	71	4	28.500	\N	2026-08-07 05:25:39.804931
492	71	5	28.700	\N	2026-08-07 05:25:39.804931
493	71	6	23.000	\N	2026-08-07 05:25:39.804931
494	71	7	29.750	\N	2026-08-07 05:25:39.804931
495	71	8	28.050	\N	2026-08-07 05:25:39.804931
496	71	9	33.100	\N	2026-08-07 05:25:39.804931
497	72	1	21.750	\N	2026-08-07 05:26:45.829478
498	72	2	28.300	\N	2026-08-07 05:26:45.829478
499	72	3	30.550	\N	2026-08-07 05:26:45.829478
500	72	4	29.300	\N	2026-08-07 05:26:45.829478
501	72	5	29.950	\N	2026-08-07 05:26:45.829478
502	72	6	27.950	\N	2026-08-07 05:26:45.829478
503	72	7	28.400	\N	2026-08-07 05:26:45.829478
504	72	8	29.850	\N	2026-08-07 05:26:45.829478
505	72	9	30.350	\N	2026-08-07 05:26:45.829478
506	73	1	28.200	\N	2026-08-07 05:27:39.547294
507	73	2	31.700	\N	2026-08-07 05:27:39.547294
508	73	3	32.700	\N	2026-08-07 05:27:39.547294
509	73	4	31.650	\N	2026-08-07 05:27:39.547294
510	73	5	25.000	\N	2026-08-07 05:27:39.547294
511	74	1	28.550	\N	2026-08-07 05:28:49.295736
512	74	2	27.400	\N	2026-08-07 05:28:49.295736
513	74	3	27.400	\N	2026-08-07 05:28:49.295736
514	74	4	28.250	\N	2026-08-07 05:28:49.295736
515	74	5	18.450	\N	2026-08-07 05:28:49.295736
516	75	1	37.050	\N	2026-08-07 05:29:56.839702
517	75	2	34.600	\N	2026-08-07 05:29:56.839702
518	75	3	28.800	\N	2026-08-07 05:29:56.839702
519	75	4	24.750	\N	2026-08-07 05:29:56.839702
520	75	5	27.250	\N	2026-08-07 05:29:56.839702
521	75	6	27.600	\N	2026-08-07 05:29:56.839702
522	75	7	28.800	\N	2026-08-07 05:29:56.839702
523	75	8	27.500	\N	2026-08-07 05:29:56.839702
524	76	1	20.050	\N	2026-08-07 05:31:51.762381
525	76	2	28.200	\N	2026-08-07 05:31:51.762381
526	76	3	20.450	\N	2026-08-07 05:31:51.762381
527	76	4	27.400	\N	2026-08-07 05:31:51.762381
528	76	5	25.400	\N	2026-08-07 05:31:51.762381
529	76	6	29.100	\N	2026-08-07 05:31:51.762381
530	76	7	25.750	\N	2026-08-07 05:31:51.762381
531	76	8	28.400	\N	2026-08-07 05:31:51.762381
532	76	9	26.250	\N	2026-08-07 05:31:51.762381
533	76	10	28.750	\N	2026-08-07 05:31:51.762381
534	77	1	21.150	\N	2026-08-07 05:33:08.312801
535	77	2	20.600	\N	2026-08-07 05:33:08.312801
536	77	3	27.300	\N	2026-08-07 05:33:08.312801
537	77	4	26.900	\N	2026-08-07 05:33:08.312801
538	77	5	27.650	\N	2026-08-07 05:33:08.312801
539	77	6	30.100	\N	2026-08-07 05:33:08.312801
540	77	7	27.200	\N	2026-08-07 05:33:08.312801
541	77	8	28.800	\N	2026-08-07 05:33:08.312801
542	77	9	27.400	\N	2026-08-07 05:33:08.312801
543	77	10	28.650	\N	2026-08-07 05:33:08.312801
544	78	1	16.650	\N	2026-08-07 05:34:13.840169
545	78	2	27.000	\N	2026-08-07 05:34:13.840169
546	78	3	17.200	\N	2026-08-07 05:34:13.840169
547	78	4	27.550	\N	2026-08-07 05:34:13.840169
548	78	5	28.200	\N	2026-08-07 05:34:13.840169
549	78	6	26.500	\N	2026-08-07 05:34:13.840169
550	78	7	27.150	\N	2026-08-07 05:34:13.840169
551	78	8	28.350	\N	2026-08-07 05:34:13.840169
552	79	1	30.750	\N	2026-08-07 05:35:10.784899
553	79	2	26.450	\N	2026-08-07 05:35:10.784899
554	79	3	28.050	\N	2026-08-07 05:35:10.784899
555	79	4	27.100	\N	2026-08-07 05:35:10.784899
556	79	5	26.300	\N	2026-08-07 05:35:10.784899
557	79	6	28.650	\N	2026-08-07 05:35:10.784899
558	79	7	27.400	\N	2026-08-07 05:35:10.784899
619	20	1	28.000	\N	2026-08-07 12:32:39.042585
620	20	2	32.950	\N	2026-08-07 12:32:39.042585
621	20	3	27.950	\N	2026-08-07 12:32:39.042585
622	20	4	27.850	\N	2026-08-07 12:32:39.042585
623	20	5	27.900	\N	2026-08-07 12:32:39.042585
624	20	6	28.450	\N	2026-08-07 12:32:39.042585
625	20	7	29.300	\N	2026-08-07 12:32:39.042585
627	88	1	28.600	\N	2026-08-08 05:33:43.300283
628	88	2	29.750	\N	2026-08-08 05:33:43.300283
629	88	3	29.400	\N	2026-08-08 05:33:43.300283
630	88	4	29.350	\N	2026-08-08 05:33:43.300283
631	88	5	29.850	\N	2026-08-08 05:33:43.300283
632	88	6	30.650	\N	2026-08-08 05:33:43.300283
633	89	1	27.350	\N	2026-08-08 05:34:49.051626
634	89	2	27.450	\N	2026-08-08 05:34:49.051626
635	89	3	27.550	\N	2026-08-08 05:34:49.051626
636	89	4	29.100	\N	2026-08-08 05:34:49.051626
637	89	5	27.500	\N	2026-08-08 05:34:49.051626
638	89	6	27.550	\N	2026-08-08 05:34:49.051626
639	89	7	27.450	\N	2026-08-08 05:34:49.051626
640	89	8	23.300	\N	2026-08-08 05:34:49.051626
641	90	1	30.500	\N	2026-08-08 05:35:45.485175
642	90	2	27.550	\N	2026-08-08 05:35:45.485175
643	90	3	28.100	\N	2026-08-08 05:35:45.485175
644	90	4	27.700	\N	2026-08-08 05:35:45.485175
645	90	5	28.550	\N	2026-08-08 05:35:45.485175
646	90	6	21.500	\N	2026-08-08 05:35:45.485175
647	90	7	30.050	\N	2026-08-08 05:35:45.485175
648	91	1	26.050	\N	2026-08-08 05:37:33.883171
649	91	2	26.900	\N	2026-08-08 05:37:33.883171
650	91	3	29.850	\N	2026-08-08 05:37:33.883171
651	91	4	27.650	\N	2026-08-08 05:37:33.883171
652	91	5	20.000	\N	2026-08-08 05:37:33.883171
653	91	6	23.450	\N	2026-08-08 05:37:33.883171
654	92	1	21.600	\N	2026-08-08 05:39:02.666522
655	92	2	28.700	\N	2026-08-08 05:39:02.666522
656	92	3	30.000	\N	2026-08-08 05:39:02.666522
657	92	4	28.450	\N	2026-08-08 05:39:02.666522
658	92	5	26.800	\N	2026-08-08 05:39:02.666522
659	93	1	27.300	\N	2026-08-08 05:41:02.110074
660	93	2	27.300	\N	2026-08-08 05:41:02.110074
661	93	3	25.400	\N	2026-08-08 05:41:02.110074
662	93	4	27.250	\N	2026-08-08 05:41:02.110074
663	93	5	28.050	\N	2026-08-08 05:41:02.110074
664	93	6	27.350	\N	2026-08-08 05:41:02.110074
665	93	7	27.250	\N	2026-08-08 05:41:02.110074
666	93	8	25.000	\N	2026-08-08 05:41:02.110074
667	93	9	29.600	\N	2026-08-08 05:41:02.110074
668	94	1	32.400	\N	2026-08-08 05:42:10.302604
669	94	2	27.450	\N	2026-08-08 05:42:10.302604
670	94	3	27.250	\N	2026-08-08 05:42:10.302604
671	94	4	29.000	\N	2026-08-08 05:42:10.302604
672	94	5	27.250	\N	2026-08-08 05:42:10.302604
673	94	6	27.200	\N	2026-08-08 05:42:10.302604
674	94	7	29.000	\N	2026-08-08 05:42:10.302604
675	94	8	27.250	\N	2026-08-08 05:42:10.302604
676	94	9	25.650	\N	2026-08-08 05:42:10.302604
677	94	10	28.950	\N	2026-08-08 05:42:10.302604
678	95	1	26.000	\N	2026-08-08 05:43:24.316785
679	95	2	29.750	\N	2026-08-08 05:43:24.316785
680	95	3	27.300	\N	2026-08-08 05:43:24.316785
681	95	4	24.900	\N	2026-08-08 05:43:24.316785
682	95	5	28.950	\N	2026-08-08 05:43:24.316785
683	95	6	30.300	\N	2026-08-08 05:43:24.316785
684	95	7	27.650	\N	2026-08-08 05:43:24.316785
685	95	8	25.600	\N	2026-08-08 05:43:24.316785
686	95	9	29.100	\N	2026-08-08 05:43:24.316785
687	95	10	30.650	\N	2026-08-08 05:43:24.316785
688	96	1	20.300	\N	2026-08-08 05:44:27.618161
689	96	2	26.250	\N	2026-08-08 05:44:27.618161
690	96	3	26.400	\N	2026-08-08 05:44:27.618161
691	96	4	26.350	\N	2026-08-08 05:44:27.618161
692	96	5	26.250	\N	2026-08-08 05:44:27.618161
693	96	6	26.700	\N	2026-08-08 05:44:27.618161
694	96	7	26.500	\N	2026-08-08 05:44:27.618161
695	96	8	28.150	\N	2026-08-08 05:44:27.618161
696	97	1	27.500	\N	2026-08-08 05:45:15.246474
697	97	2	27.400	\N	2026-08-08 05:45:15.246474
698	97	3	26.200	\N	2026-08-08 05:45:15.246474
699	97	4	29.000	\N	2026-08-08 05:45:15.246474
700	97	5	34.850	\N	2026-08-08 05:45:15.246474
701	97	6	30.500	\N	2026-08-08 05:45:15.246474
702	98	1	694.750	\N	2026-08-08 06:51:30.145466
703	99	1	1534.500	\N	2026-08-08 06:58:00.950157
704	100	1	2181.850	\N	2026-08-08 07:01:29.883679
705	101	1	17.900	\N	2026-08-08 07:05:24.210104
706	102	1	520.900	\N	2026-08-08 07:07:33.221562
707	103	1	439.600	\N	2026-08-08 07:12:47.109305
708	104	1	2100.900	\N	2026-08-08 07:31:28.848027
709	105	1	29.250	\N	2026-08-09 07:48:31.9882
710	105	2	28.750	\N	2026-08-09 07:48:31.9882
711	105	3	29.450	\N	2026-08-09 07:48:31.9882
712	105	4	28.050	\N	2026-08-09 07:48:31.9882
713	105	5	30.000	\N	2026-08-09 07:48:31.9882
714	105	6	29.500	\N	2026-08-09 07:48:31.9882
715	105	7	29.400	\N	2026-08-09 07:48:31.9882
716	105	8	30.500	\N	2026-08-09 07:48:31.9882
717	106	1	27.450	\N	2026-08-09 07:50:05.863588
718	106	2	27.450	\N	2026-08-09 07:50:05.863588
719	106	3	29.350	\N	2026-08-09 07:50:05.863588
720	106	4	27.850	\N	2026-08-09 07:50:05.863588
721	106	5	27.550	\N	2026-08-09 07:50:05.863588
722	106	6	27.500	\N	2026-08-09 07:50:05.863588
723	106	7	27.450	\N	2026-08-09 07:50:05.863588
724	106	8	24.600	\N	2026-08-09 07:50:05.863588
725	106	9	27.400	\N	2026-08-09 07:50:05.863588
726	106	10	31.700	\N	2026-08-09 07:50:05.863588
727	107	1	32.850	\N	2026-08-09 07:51:04.678261
728	107	2	27.050	\N	2026-08-09 07:51:04.678261
729	107	3	27.750	\N	2026-08-09 07:51:04.678261
730	107	4	29.150	\N	2026-08-09 07:51:04.678261
731	107	5	27.300	\N	2026-08-09 07:51:04.678261
732	107	6	27.500	\N	2026-08-09 07:51:04.678261
733	107	7	27.550	\N	2026-08-09 07:51:04.678261
734	107	8	30.550	\N	2026-08-09 07:51:04.678261
735	107	9	32.150	\N	2026-08-09 07:51:04.678261
736	108	1	28.400	\N	2026-08-09 07:52:30.892115
737	108	2	28.650	\N	2026-08-09 07:52:30.892115
738	108	3	23.900	\N	2026-08-09 07:52:30.892115
739	108	4	25.900	\N	2026-08-09 07:52:30.892115
740	108	5	21.450	\N	2026-08-09 07:52:30.892115
741	108	6	27.000	\N	2026-08-09 07:52:30.892115
742	109	1	28.650	\N	2026-08-09 07:53:28.839697
743	109	2	29.100	\N	2026-08-09 07:53:28.839697
744	109	3	28.650	\N	2026-08-09 07:53:28.839697
745	109	4	28.100	\N	2026-08-09 07:53:28.839697
746	109	5	10.600	\N	2026-08-09 07:53:28.839697
756	111	1	28.800	\N	2026-08-09 07:56:12.533537
757	111	2	29.550	\N	2026-08-09 07:56:12.533537
758	111	3	28.100	\N	2026-08-09 07:56:12.533537
759	111	4	23.700	\N	2026-08-09 07:56:12.533537
760	111	5	28.750	\N	2026-08-09 07:56:12.533537
761	111	6	27.200	\N	2026-08-09 07:56:12.533537
762	111	7	27.300	\N	2026-08-09 07:56:12.533537
763	111	8	28.900	\N	2026-08-09 07:56:12.533537
764	111	9	26.500	\N	2026-08-09 07:56:12.533537
765	111	10	27.300	\N	2026-08-09 07:56:12.533537
766	112	1	24.800	\N	2026-08-09 07:58:42.067577
767	112	2	28.050	\N	2026-08-09 07:58:42.067577
768	112	3	28.000	\N	2026-08-09 07:58:42.067577
769	112	4	28.850	\N	2026-08-09 07:58:42.067577
770	112	5	27.100	\N	2026-08-09 07:58:42.067577
771	112	6	27.550	\N	2026-08-09 07:58:42.067577
772	112	7	27.000	\N	2026-08-09 07:58:42.067577
773	112	8	29.050	\N	2026-08-09 07:58:42.067577
774	112	9	27.150	\N	2026-08-09 07:58:42.067577
775	112	10	29.450	\N	2026-08-09 07:58:42.067577
776	113	1	18.300	\N	2026-08-09 07:59:33.485241
777	113	2	27.000	\N	2026-08-09 07:59:33.485241
778	113	3	32.900	\N	2026-08-09 07:59:33.485241
779	113	4	28.050	\N	2026-08-09 07:59:33.485241
780	113	5	26.200	\N	2026-08-09 07:59:33.485241
781	113	6	34.600	\N	2026-08-09 07:59:33.485241
790	115	1	22.250	\N	2026-08-09 08:03:42.711767
791	115	2	26.150	\N	2026-08-09 08:03:42.711767
792	115	3	26.350	\N	2026-08-09 08:03:42.711767
793	115	4	23.200	\N	2026-08-09 08:03:42.711767
794	115	5	28.400	\N	2026-08-09 08:03:42.711767
795	115	6	27.700	\N	2026-08-09 08:03:42.711767
796	115	7	26.800	\N	2026-08-09 08:03:42.711767
797	115	8	27.500	\N	2026-08-09 08:03:42.711767
798	114	1	28.250	\N	2026-08-09 08:05:59.593048
799	114	2	26.100	\N	2026-08-09 08:05:59.593048
800	114	3	26.350	\N	2026-08-09 08:05:59.593048
801	114	4	26.350	\N	2026-08-09 08:05:59.593048
802	114	5	27.000	\N	2026-08-09 08:05:59.593048
803	114	6	26.550	\N	2026-08-09 08:05:59.593048
804	114	7	26.300	\N	2026-08-09 08:05:59.593048
805	114	8	26.450	\N	2026-08-09 08:05:59.593048
806	110	1	28.950	\N	2026-08-09 08:41:15.456616
807	110	2	20.450	\N	2026-08-09 08:41:15.456616
808	110	3	27.400	\N	2026-08-09 08:41:15.456616
809	110	4	27.250	\N	2026-08-09 08:41:15.456616
810	110	5	26.700	\N	2026-08-09 08:41:15.456616
811	110	6	27.250	\N	2026-08-09 08:41:15.456616
812	110	7	29.250	\N	2026-08-09 08:41:15.456616
813	110	8	27.350	\N	2026-08-09 08:41:15.456616
814	110	9	26.850	\N	2026-08-09 08:41:15.456616
815	116	1	27.900	\N	2026-08-10 05:23:01.976288
816	116	2	29.800	\N	2026-08-10 05:23:01.976288
817	116	3	27.250	\N	2026-08-10 05:23:01.976288
818	116	4	28.650	\N	2026-08-10 05:23:01.976288
819	116	5	30.800	\N	2026-08-10 05:23:01.976288
820	116	6	28.950	\N	2026-08-10 05:23:01.976288
821	117	1	29.550	\N	2026-08-10 05:24:06.205199
822	117	2	29.250	\N	2026-08-10 05:24:06.205199
823	117	3	28.950	\N	2026-08-10 05:24:06.205199
824	117	4	30.150	\N	2026-08-10 05:24:06.205199
825	117	5	29.150	\N	2026-08-10 05:24:06.205199
826	117	6	29.250	\N	2026-08-10 05:24:06.205199
827	117	7	28.350	\N	2026-08-10 05:24:06.205199
828	117	8	26.300	\N	2026-08-10 05:24:06.205199
829	117	9	26.500	\N	2026-08-10 05:24:06.205199
830	117	10	28.500	\N	2026-08-10 05:24:06.205199
831	118	1	29.350	\N	2026-08-10 05:25:09.40753
832	118	2	30.350	\N	2026-08-10 05:25:09.40753
833	118	3	28.150	\N	2026-08-10 05:25:09.40753
834	118	4	29.200	\N	2026-08-10 05:25:09.40753
835	118	5	27.700	\N	2026-08-10 05:25:09.40753
836	118	6	31.550	\N	2026-08-10 05:25:09.40753
837	118	7	27.600	\N	2026-08-10 05:25:09.40753
838	118	8	28.050	\N	2026-08-10 05:25:09.40753
839	118	9	30.600	\N	2026-08-10 05:25:09.40753
840	119	1	26.800	\N	2026-08-10 05:26:09.923348
841	119	2	25.150	\N	2026-08-10 05:26:09.923348
842	119	3	15.950	\N	2026-08-10 05:26:09.923348
843	119	4	16.450	\N	2026-08-10 05:26:09.923348
844	119	5	20.350	\N	2026-08-10 05:26:09.923348
845	119	6	20.350	\N	2026-08-10 05:26:09.923348
846	119	7	17.350	\N	2026-08-10 05:26:09.923348
847	119	8	24.000	\N	2026-08-10 05:26:09.923348
848	119	9	22.900	\N	2026-08-10 05:26:09.923348
849	120	1	20.250	\N	2026-08-10 05:27:03.589931
850	120	2	24.450	\N	2026-08-10 05:27:03.589931
851	120	3	28.650	\N	2026-08-10 05:27:03.589931
852	120	4	26.800	\N	2026-08-10 05:27:03.589931
853	120	5	21.250	\N	2026-08-10 05:27:03.589931
854	120	6	23.500	\N	2026-08-10 05:27:03.589931
855	120	7	25.850	\N	2026-08-10 05:27:03.589931
856	120	8	26.750	\N	2026-08-10 05:27:03.589931
857	121	1	27.900	\N	2026-08-10 05:28:03.324527
858	121	2	28.100	\N	2026-08-10 05:28:03.324527
859	121	3	28.850	\N	2026-08-10 05:28:03.324527
860	121	4	28.100	\N	2026-08-10 05:28:03.324527
861	121	5	29.150	\N	2026-08-10 05:28:03.324527
862	121	6	28.100	\N	2026-08-10 05:28:03.324527
863	121	7	28.650	\N	2026-08-10 05:28:03.324527
864	121	8	28.300	\N	2026-08-10 05:28:03.324527
865	122	1	27.450	\N	2026-08-10 05:28:46.604898
866	122	2	27.050	\N	2026-08-10 05:28:46.604898
867	122	3	32.100	\N	2026-08-10 05:28:46.604898
868	123	1	33.750	\N	2026-08-10 05:30:46.537843
869	123	2	30.250	\N	2026-08-10 05:30:46.537843
870	123	3	27.250	\N	2026-08-10 05:30:46.537843
871	123	4	27.300	\N	2026-08-10 05:30:46.537843
872	123	5	27.200	\N	2026-08-10 05:30:46.537843
873	123	6	28.250	\N	2026-08-10 05:30:46.537843
874	123	7	25.800	\N	2026-08-10 05:30:46.537843
875	123	8	27.250	\N	2026-08-10 05:30:46.537843
876	123	9	27.350	\N	2026-08-10 05:30:46.537843
884	125	1	25.900	\N	2026-08-10 05:33:23.641765
885	125	2	26.600	\N	2026-08-10 05:33:23.641765
886	125	3	25.000	\N	2026-08-10 05:33:23.641765
887	125	4	26.600	\N	2026-08-10 05:33:23.641765
888	125	5	26.850	\N	2026-08-10 05:33:23.641765
889	125	6	28.200	\N	2026-08-10 05:33:23.641765
890	125	7	25.150	\N	2026-08-10 05:33:23.641765
891	125	8	27.700	\N	2026-08-10 05:33:23.641765
892	124	1	24.600	\N	2026-08-10 05:34:55.986537
893	124	2	26.650	\N	2026-08-10 05:34:55.986537
894	124	3	24.300	\N	2026-08-10 05:34:55.986537
895	124	4	23.900	\N	2026-08-10 05:34:55.986537
896	124	5	25.050	\N	2026-08-10 05:34:55.986537
897	124	6	23.100	\N	2026-08-10 05:34:55.986537
898	124	7	25.650	\N	2026-08-10 05:34:55.986537
899	126	1	28.800	\N	2026-08-11 05:24:27.73266
900	126	2	28.150	\N	2026-08-11 05:24:27.73266
901	126	3	30.000	\N	2026-08-11 05:24:27.73266
902	126	4	23.550	\N	2026-08-11 05:24:27.73266
903	126	5	27.300	\N	2026-08-11 05:24:27.73266
904	127	1	29.550	\N	2026-08-11 05:26:47.336666
905	127	2	27.650	\N	2026-08-11 05:26:47.336666
906	127	3	29.200	\N	2026-08-11 05:26:47.336666
907	127	4	29.450	\N	2026-08-11 05:26:47.336666
908	127	5	29.650	\N	2026-08-11 05:26:47.336666
909	127	6	29.550	\N	2026-08-11 05:26:47.336666
910	128	1	27.350	\N	2026-08-11 05:31:19.677755
911	128	2	27.100	\N	2026-08-11 05:31:19.677755
912	128	3	29.550	\N	2026-08-11 05:31:19.677755
913	128	4	29.050	\N	2026-08-11 05:31:19.677755
914	128	5	25.450	\N	2026-08-11 05:31:19.677755
915	128	6	21.700	\N	2026-08-11 05:31:19.677755
916	128	7	28.100	\N	2026-08-11 05:31:19.677755
917	128	8	28.200	\N	2026-08-11 05:31:19.677755
918	128	9	18.350	\N	2026-08-11 05:31:19.677755
919	129	1	24.050	\N	2026-08-11 05:36:02.008856
920	129	2	22.450	\N	2026-08-11 05:36:02.008856
921	129	3	19.950	\N	2026-08-11 05:36:02.008856
922	129	4	25.250	\N	2026-08-11 05:36:02.008856
923	129	5	16.250	\N	2026-08-11 05:36:02.008856
924	129	6	11.950	\N	2026-08-11 05:36:02.008856
925	129	7	23.600	\N	2026-08-11 05:36:02.008856
926	130	1	28.500	\N	2026-08-11 05:36:52.435471
927	130	2	28.600	\N	2026-08-11 05:36:52.435471
928	130	3	23.000	\N	2026-08-11 05:36:52.435471
929	130	4	28.100	\N	2026-08-11 05:36:52.435471
930	131	1	31.600	\N	2026-08-11 05:38:13.686446
931	131	2	26.100	\N	2026-08-11 05:38:13.686446
932	131	3	28.500	\N	2026-08-11 05:38:13.686446
933	131	4	33.950	\N	2026-08-11 05:38:13.686446
934	131	5	27.400	\N	2026-08-11 05:38:13.686446
935	131	6	27.350	\N	2026-08-11 05:38:13.686446
936	131	7	29.100	\N	2026-08-11 05:38:13.686446
937	131	8	28.250	\N	2026-08-11 05:38:13.686446
938	132	1	27.050	\N	2026-08-11 05:39:17.78189
939	132	2	23.750	\N	2026-08-11 05:39:17.78189
940	132	3	27.400	\N	2026-08-11 05:39:17.78189
941	132	4	27.200	\N	2026-08-11 05:39:17.78189
942	132	5	27.750	\N	2026-08-11 05:39:17.78189
943	132	6	27.150	\N	2026-08-11 05:39:17.78189
944	132	7	27.250	\N	2026-08-11 05:39:17.78189
945	132	8	27.450	\N	2026-08-11 05:39:17.78189
946	132	9	27.200	\N	2026-08-11 05:39:17.78189
947	132	10	29.100	\N	2026-08-11 05:39:17.78189
948	133	1	16.800	\N	2026-08-11 05:40:14.148997
949	133	2	27.400	\N	2026-08-11 05:40:14.148997
950	133	3	26.250	\N	2026-08-11 05:40:14.148997
951	133	4	27.450	\N	2026-08-11 05:40:14.148997
952	133	5	27.850	\N	2026-08-11 05:40:14.148997
953	133	6	25.800	\N	2026-08-11 05:40:14.148997
954	133	7	29.500	\N	2026-08-11 05:40:14.148997
955	133	8	28.600	\N	2026-08-11 05:40:14.148997
956	133	9	28.450	\N	2026-08-11 05:40:14.148997
957	134	1	33.200	\N	2026-08-11 05:42:02.246542
958	134	2	30.250	\N	2026-08-11 05:42:02.246542
959	134	3	28.050	\N	2026-08-11 05:42:02.246542
\.


--
-- Data for Name: daily_production_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_production_header (id, production_date, machine_id, employee_id, party_id, shift, status, remarks, created_by, created_at, updated_by, updated_at, reconciled, reconciled_transaction_id, reconciled_at) FROM stdin;
55	2026-08-04	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-05 05:21:33.592011	Iftikhar	2026-08-06 10:19:47.34	t	147	2026-08-06 10:29:27.695
59	2026-08-04	23	2	13	Night	submitted	\N	Iftikhar	2026-08-05 05:26:18.500287	\N	2026-08-05 05:26:18.500287	t	147	2026-08-06 10:29:27.695
54	2026-08-04	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-05 05:20:10.782671	\N	2026-08-05 05:20:10.782671	t	148	2026-08-06 10:31:01.798
53	2026-08-04	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-05 05:19:28.381793	\N	2026-08-05 05:19:28.381793	t	150	2026-08-06 13:26:01.721
56	2026-08-04	25	9	14	Night	submitted	\N	Iftikhar	2026-08-05 05:22:54.381768	\N	2026-08-05 05:22:54.381768	t	150	2026-08-06 13:26:01.721
57	2026-08-04	14	9	14	Night	submitted	\N	Iftikhar	2026-08-05 05:23:56.914664	\N	2026-08-05 05:23:56.914664	t	150	2026-08-06 13:26:01.721
7	2026-08-01	18	7	17	Morning	submitted	\N	Iftikhar	2026-08-04 09:20:23.329666	\N	2026-08-04 09:20:23.329666	t	135	2026-08-04 13:14:03.613
15	2026-08-01	18	2	17	Night	submitted	\N	Iftikhar	2026-08-04 09:40:48.902839	\N	2026-08-04 09:40:48.902839	t	135	2026-08-04 13:14:03.613
58	2026-08-04	15	2	14	Night	submitted	\N	Iftikhar	2026-08-05 05:25:07.609832	\N	2026-08-05 05:25:07.609832	t	150	2026-08-06 13:26:01.721
60	2026-08-05	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-06 05:12:09.379561	\N	2026-08-06 05:12:09.379561	t	\N	2026-08-06 10:06:16.658
61	2026-08-05	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-06 05:13:41.179759	\N	2026-08-06 05:13:41.179759	t	\N	2026-08-06 10:06:16.658
62	2026-08-05	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-06 05:14:54.170255	\N	2026-08-06 05:14:54.170255	t	\N	2026-08-06 10:06:16.658
66	2026-08-05	14	9	14	Night	submitted	\N	Iftikhar	2026-08-06 05:21:03.119254	\N	2026-08-06 05:21:03.119254	t	\N	2026-08-06 10:06:16.658
20	2026-08-01	24	3	13	Night	submitted	\N	Iftikhar	2026-08-04 09:55:40.418218	abc	2026-08-07 12:32:39.043	t	139	2026-08-04 13:59:37.313
98	2026-07-31	25	18	13	Morning	submitted	\N	Hsn	2026-08-08 06:51:30.145466	\N	2026-08-08 06:51:30.145466	f	\N	\N
102	2026-07-31	25	18	15	Morning	submitted	\N	Hsn	2026-08-08 07:07:33.221562	\N	2026-08-08 07:07:33.221562	f	\N	\N
104	2026-07-31	25	18	14	Morning	submitted	\N	Hsn	2026-08-08 07:31:28.848027	\N	2026-08-08 07:31:28.848027	f	\N	\N
130	2026-08-10	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-11 05:36:52.435471	\N	2026-08-11 05:36:52.435471	t	197	2026-08-11 08:02:34.807
126	2026-08-10	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-11 05:24:27.73266	\N	2026-08-11 05:24:27.73266	t	198	2026-08-11 08:05:44.312
24	2026-08-02	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-04 10:06:51.146146	\N	2026-08-04 10:06:51.146146	t	136	2026-08-04 13:17:25.823
4	2026-08-01	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-04 09:10:42.87511	\N	2026-08-04 09:10:42.87511	t	132	2026-08-04 12:35:23.619
6	2026-08-01	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 09:18:31.354253	\N	2026-08-04 09:18:31.354253	t	132	2026-08-04 12:35:23.619
5	2026-08-01	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 09:16:42.696457	Iftikhar	2026-08-04 09:23:18.322	t	132	2026-08-04 12:35:23.619
12	2026-08-01	25	3	14	Night	submitted	\N	Iftikhar	2026-08-04 09:34:40.40951	\N	2026-08-04 09:34:40.40951	t	132	2026-08-04 12:35:23.619
13	2026-08-01	14	9	14	Night	submitted	\N	Iftikhar	2026-08-04 09:36:49.21394	\N	2026-08-04 09:36:49.21394	t	132	2026-08-04 12:35:23.619
14	2026-08-01	15	2	14	Night	submitted	\N	Iftikhar	2026-08-04 09:37:42.188473	\N	2026-08-04 09:37:42.188473	t	132	2026-08-04 12:35:23.619
21	2026-08-02	25	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 10:01:26.358251	\N	2026-08-04 10:01:26.358251	t	133	2026-08-04 12:43:09.691
22	2026-08-02	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 10:02:51.515396	\N	2026-08-04 10:02:51.515396	t	133	2026-08-04 12:43:09.691
23	2026-08-02	15	7	14	Morning	submitted	\N	Iftikhar	2026-08-04 10:03:57.20679	Iftikhar	2026-08-04 10:05:41.441	t	133	2026-08-04 12:43:09.691
29	2026-08-02	25	9	14	Night	submitted	\N	Iftikhar	2026-08-04 10:44:10.948865	\N	2026-08-04 10:44:10.948865	t	133	2026-08-04 12:43:09.691
31	2026-08-02	14	9	14	Night	submitted	\N	Iftikhar	2026-08-04 11:02:23.167923	\N	2026-08-04 11:02:23.167923	t	133	2026-08-04 12:43:09.691
32	2026-08-02	15	2	14	Night	submitted	\N	Iftikhar	2026-08-04 11:03:01.847261	\N	2026-08-04 11:03:01.847261	t	133	2026-08-04 12:43:09.691
38	2026-08-03	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-04 11:10:01.18467	\N	2026-08-04 11:10:01.18467	t	134	2026-08-04 13:06:18.972
39	2026-08-03	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 11:14:57.548808	\N	2026-08-04 11:14:57.548808	t	134	2026-08-04 13:06:18.972
40	2026-08-03	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-04 11:15:49.435534	\N	2026-08-04 11:15:49.435534	t	134	2026-08-04 13:06:18.972
45	2026-08-03	25	9	14	Night	submitted	\N	Iftikhar	2026-08-04 11:21:22.562363	\N	2026-08-04 11:21:22.562363	t	134	2026-08-04 13:06:18.972
46	2026-08-03	14	9	14	Night	submitted	\N	Iftikhar	2026-08-04 11:22:21.680401	\N	2026-08-04 11:22:21.680401	t	134	2026-08-04 13:06:18.972
47	2026-08-03	15	2	14	Night	submitted	\N	Iftikhar	2026-08-04 11:23:27.891391	\N	2026-08-04 11:23:27.891391	t	134	2026-08-04 13:06:18.972
25	2026-08-02	21	1	16	Morning	submitted	\N	Iftikhar	2026-08-04 10:07:59.206754	\N	2026-08-04 10:07:59.206754	t	136	2026-08-04 13:17:25.823
33	2026-08-02	18	2	16	Night	submitted	\N	Iftikhar	2026-08-04 11:04:36.849782	\N	2026-08-04 11:04:36.849782	t	136	2026-08-04 13:17:25.823
34	2026-08-02	21	9	16	Night	submitted	\N	Iftikhar	2026-08-04 11:05:46.793537	\N	2026-08-04 11:05:46.793537	t	136	2026-08-04 13:17:25.823
16	2026-08-01	18	2	20	Night	submitted	\N	Iftikhar	2026-08-04 09:41:28.654011	Iftikhar	2026-08-04 13:45:14.172	t	137	2026-08-04 13:53:44.511
8	2026-08-01	21	1	16	Morning	submitted	\N	Iftikhar	2026-08-04 09:25:40.653893	\N	2026-08-04 09:25:40.653893	t	138	2026-08-04 13:57:14.007
17	2026-08-01	21	9	16	Night	submitted	\N	Iftikhar	2026-08-04 09:45:30.288701	\N	2026-08-04 09:45:30.288701	t	138	2026-08-04 13:57:14.007
9	2026-08-01	22	8	13	Morning	submitted	\N	Iftikhar	2026-08-04 09:27:15.003235	\N	2026-08-04 09:27:15.003235	t	139	2026-08-04 13:59:37.313
10	2026-08-01	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-04 09:28:57.85111	\N	2026-08-04 09:28:57.85111	t	139	2026-08-04 13:59:37.313
18	2026-08-01	22	9	13	Night	submitted	\N	Iftikhar	2026-08-04 09:46:52.771207	\N	2026-08-04 09:46:52.771207	t	139	2026-08-04 13:59:37.313
19	2026-08-01	23	2	13	Night	submitted	\N	Iftikhar	2026-08-04 09:54:11.999346	\N	2026-08-04 09:54:11.999346	t	139	2026-08-04 13:59:37.313
11	2026-08-01	24	1	15	Morning	submitted	\N	Iftikhar	2026-08-04 09:30:40.700423	\N	2026-08-04 09:30:40.700423	t	140	2026-08-04 14:01:03.54
26	2026-08-02	22	8	13	Morning	submitted	\N	Iftikhar	2026-08-04 10:08:59.403701	\N	2026-08-04 10:08:59.403701	t	141	2026-08-04 14:03:06.842
27	2026-08-02	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-04 10:10:14.184358	\N	2026-08-04 10:10:14.184358	t	141	2026-08-04 14:03:06.842
35	2026-08-02	22	2	13	Night	submitted	\N	Iftikhar	2026-08-04 11:06:46.274667	\N	2026-08-04 11:06:46.274667	t	141	2026-08-04 14:03:06.842
36	2026-08-02	23	2	13	Night	submitted	\N	Iftikhar	2026-08-04 11:07:56.979945	\N	2026-08-04 11:07:56.979945	t	141	2026-08-04 14:03:06.842
28	2026-08-02	24	1	15	Morning	submitted	\N	Iftikhar	2026-08-04 10:11:18.644384	\N	2026-08-04 10:11:18.644384	t	142	2026-08-04 14:05:21.393
37	2026-08-02	24	9	15	Night	submitted	\N	Iftikhar	2026-08-04 11:08:47.644403	\N	2026-08-04 11:08:47.644403	t	142	2026-08-04 14:05:21.393
41	2026-08-03	18	7	16	Morning	submitted	\N	Iftikhar	2026-08-04 11:16:54.358067	\N	2026-08-04 11:16:54.358067	t	143	2026-08-04 14:07:52.264
42	2026-08-03	21	1	16	Morning	submitted	\N	Iftikhar	2026-08-04 11:18:01.178238	\N	2026-08-04 11:18:01.178238	t	143	2026-08-04 14:07:52.264
48	2026-08-03	18	2	16	Night	submitted	\N	Iftikhar	2026-08-04 11:24:21.364634	\N	2026-08-04 11:24:21.364634	t	143	2026-08-04 14:07:52.264
49	2026-08-03	21	9	16	Night	submitted	\N	Iftikhar	2026-08-04 11:25:27.95248	\N	2026-08-04 11:25:27.95248	t	143	2026-08-04 14:07:52.264
43	2026-08-03	22	8	13	Morning	submitted	\N	Iftikhar	2026-08-04 11:18:37.003406	\N	2026-08-04 11:18:37.003406	t	144	2026-08-04 14:10:05.393
44	2026-08-03	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-04 11:19:37.030411	\N	2026-08-04 11:19:37.030411	t	144	2026-08-04 14:10:05.393
50	2026-08-03	23	2	13	Night	submitted	\N	Iftikhar	2026-08-04 11:26:53.291837	\N	2026-08-04 11:26:53.291837	t	144	2026-08-04 14:10:05.393
64	2026-08-05	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-06 05:18:20.391739	\N	2026-08-06 05:18:20.391739	t	146	2026-08-06 10:08:54.843
68	2026-08-05	23	2	13	Night	submitted	\N	Iftikhar	2026-08-06 05:24:47.564861	\N	2026-08-06 05:24:47.564861	t	146	2026-08-06 10:08:54.843
69	2026-08-05	24	9	13	Night	submitted	\N	Iftikhar	2026-08-06 05:25:38.115455	\N	2026-08-06 05:25:38.115455	t	146	2026-08-06 10:08:54.843
63	2026-08-05	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-06 05:16:12.272644	Iftikhar	2026-08-06 09:50:06.528	t	146	2026-08-06 10:08:54.843
52	2026-08-04	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-05 05:18:12.192286	abc	2026-08-05 14:53:59.24	t	150	2026-08-06 13:26:01.721
51	2026-08-04	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-05 05:15:40.749114	abc	2026-08-05 23:02:26.29	t	150	2026-08-06 13:26:01.721
100	2026-07-31	25	18	16	Morning	submitted	\N	Hsn	2026-08-08 07:01:29.883679	\N	2026-08-08 07:01:29.883679	t	193	2026-08-11 06:59:11.495
99	2026-07-31	25	18	16	Morning	submitted	\N	Hsn	2026-08-08 06:58:00.950157	\N	2026-08-08 06:58:00.950157	t	193	2026-08-11 06:59:11.495
101	2026-07-31	25	18	16	Morning	submitted	\N	Hsn	2026-08-08 07:05:24.210104	\N	2026-08-08 07:05:24.210104	t	193	2026-08-11 06:59:11.495
129	2026-08-10	22	7	13	Morning	submitted	\N	Iftikhar	2026-08-11 05:36:02.008856	\N	2026-08-11 05:36:02.008856	t	197	2026-08-11 08:02:34.807
70	2026-08-06	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-07 05:23:01.634685	\N	2026-08-07 05:23:01.634685	t	153	2026-08-07 06:27:57.242
71	2026-08-06	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-07 05:25:39.804931	\N	2026-08-07 05:25:39.804931	t	153	2026-08-07 06:27:57.242
72	2026-08-06	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-07 05:26:45.829478	\N	2026-08-07 05:26:45.829478	t	153	2026-08-07 06:27:57.242
75	2026-08-06	25	9	14	Night	submitted	\N	Iftikhar	2026-08-07 05:29:56.839702	\N	2026-08-07 05:29:56.839702	t	153	2026-08-07 06:27:57.242
76	2026-08-06	14	2	14	Night	submitted	\N	Iftikhar	2026-08-07 05:31:51.762381	\N	2026-08-07 05:31:51.762381	t	153	2026-08-07 06:27:57.242
77	2026-08-06	15	2	14	Night	submitted	\N	Iftikhar	2026-08-07 05:33:08.312801	\N	2026-08-07 05:33:08.312801	t	153	2026-08-07 06:27:57.242
73	2026-08-06	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-07 05:27:39.547294	\N	2026-08-07 05:27:39.547294	t	154	2026-08-07 06:30:21.369
74	2026-08-06	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-07 05:28:49.295736	\N	2026-08-07 05:28:49.295736	t	154	2026-08-07 06:30:21.369
78	2026-08-06	23	2	13	Night	submitted	\N	Iftikhar	2026-08-07 05:34:13.840169	\N	2026-08-07 05:34:13.840169	t	154	2026-08-07 06:30:21.369
79	2026-08-06	24	9	13	Night	submitted	\N	Iftikhar	2026-08-07 05:35:10.784899	\N	2026-08-07 05:35:10.784899	t	154	2026-08-07 06:30:21.369
134	2026-08-10	22	2	13	Night	submitted	\N	Iftikhar	2026-08-11 05:42:02.246542	\N	2026-08-11 05:42:02.246542	t	197	2026-08-11 08:02:34.807
128	2026-08-10	15	7	14	Morning	submitted	\N	Iftikhar	2026-08-11 05:31:19.677755	\N	2026-08-11 05:31:19.677755	t	198	2026-08-11 08:05:44.312
127	2026-08-10	14	1	14	Morning	submitted	\N	Iftikhar	2026-08-11 05:26:47.336666	\N	2026-08-11 05:26:47.336666	t	198	2026-08-11 08:05:44.312
131	2026-08-10	25	9	14	Night	submitted	\N	Iftikhar	2026-08-11 05:38:13.686446	\N	2026-08-11 05:38:13.686446	t	198	2026-08-11 08:05:44.312
132	2026-08-10	14	9	14	Night	submitted	\N	Iftikhar	2026-08-11 05:39:17.78189	\N	2026-08-11 05:39:17.78189	t	198	2026-08-11 08:05:44.312
133	2026-08-10	15	2	14	Night	submitted	\N	Iftikhar	2026-08-11 05:40:14.148997	\N	2026-08-11 05:40:14.148997	t	198	2026-08-11 08:05:44.312
67	2026-08-05	15	2	14	Night	submitted	\N	Iftikhar	2026-08-06 05:23:48.398276	\N	2026-08-06 05:23:48.398276	t	\N	2026-08-06 10:06:16.658
65	2026-08-05	25	9	14	Night	submitted	\N	Iftikhar	2026-08-06 05:19:32.340692	Iftikhar	2026-08-06 05:26:52.716	t	\N	2026-08-06 10:06:16.658
103	2026-07-31	25	18	17	Morning	submitted	\N	Hsn	2026-08-08 07:12:47.109305	\N	2026-08-08 07:12:47.109305	f	\N	\N
91	2026-08-07	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-08 05:37:33.883171	\N	2026-08-08 05:37:33.883171	t	166	2026-08-08 06:23:16.557
92	2026-08-07	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-08 05:39:02.666522	\N	2026-08-08 05:39:02.666522	t	166	2026-08-08 06:23:16.557
96	2026-08-07	23	2	13	Night	submitted	\N	Iftikhar	2026-08-08 05:44:27.618161	\N	2026-08-08 05:44:27.618161	t	166	2026-08-08 06:23:16.557
97	2026-08-07	24	9	13	Night	submitted	\N	Iftikhar	2026-08-08 05:45:15.246474	\N	2026-08-08 05:45:15.246474	t	166	2026-08-08 06:23:16.557
88	2026-08-07	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-08 05:33:43.300283	\N	2026-08-08 05:33:43.300283	t	167	2026-08-08 06:25:49.267
89	2026-08-07	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-08 05:34:49.051626	\N	2026-08-08 05:34:49.051626	t	167	2026-08-08 06:25:49.267
90	2026-08-07	15	7	14	Morning	submitted	\N	Iftikhar	2026-08-08 05:35:45.485175	\N	2026-08-08 05:35:45.485175	t	167	2026-08-08 06:25:49.267
93	2026-08-07	25	9	14	Night	submitted	\N	Iftikhar	2026-08-08 05:41:02.110074	\N	2026-08-08 05:41:02.110074	t	167	2026-08-08 06:25:49.267
94	2026-08-07	14	9	14	Night	submitted	\N	Iftikhar	2026-08-08 05:42:10.302604	\N	2026-08-08 05:42:10.302604	t	167	2026-08-08 06:25:49.267
95	2026-08-07	15	2	14	Night	submitted	\N	Iftikhar	2026-08-08 05:43:24.316785	\N	2026-08-08 05:43:24.316785	t	167	2026-08-08 06:25:49.267
108	2026-08-08	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-09 07:52:30.892115	\N	2026-08-09 07:52:30.892115	t	186	2026-08-10 09:23:21.156
109	2026-08-08	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-09 07:53:28.839697	\N	2026-08-09 07:53:28.839697	t	186	2026-08-10 09:23:21.156
113	2026-08-08	22	2	13	Night	submitted	\N	Iftikhar	2026-08-09 07:59:33.485241	\N	2026-08-09 07:59:33.485241	t	186	2026-08-10 09:23:21.156
115	2026-08-08	24	9	13	Night	submitted	\N	Iftikhar	2026-08-09 08:03:42.711767	\N	2026-08-09 08:03:42.711767	t	186	2026-08-10 09:23:21.156
114	2026-08-08	23	2	13	Night	submitted	\N	Iftikhar	2026-08-09 08:02:40.567269	Iftikhar	2026-08-09 08:05:59.595	t	186	2026-08-10 09:23:21.156
116	2026-08-09	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-10 05:23:01.976288	\N	2026-08-10 05:23:01.976288	t	187	2026-08-10 09:25:50.817
117	2026-08-09	14	1	14	Morning	submitted	\N	Iftikhar	2026-08-10 05:24:06.205199	\N	2026-08-10 05:24:06.205199	t	187	2026-08-10 09:25:50.817
118	2026-08-09	15	7	14	Morning	submitted	\N	Iftikhar	2026-08-10 05:25:09.40753	\N	2026-08-10 05:25:09.40753	t	187	2026-08-10 09:25:50.817
122	2026-08-09	14	9	14	Night	submitted	\N	Iftikhar	2026-08-10 05:28:46.604898	\N	2026-08-10 05:28:46.604898	t	187	2026-08-10 09:25:50.817
123	2026-08-09	15	9	14	Night	submitted	\N	Iftikhar	2026-08-10 05:30:46.537843	\N	2026-08-10 05:30:46.537843	t	187	2026-08-10 09:25:50.817
105	2026-08-08	25	1	14	Morning	submitted	\N	Iftikhar	2026-08-09 07:48:31.9882	\N	2026-08-09 07:48:31.9882	t	188	2026-08-10 09:27:37.036
106	2026-08-08	14	8	14	Morning	submitted	\N	Iftikhar	2026-08-09 07:50:05.863588	\N	2026-08-09 07:50:05.863588	t	188	2026-08-10 09:27:37.036
107	2026-08-08	15	8	14	Morning	submitted	\N	Iftikhar	2026-08-09 07:51:04.678261	\N	2026-08-09 07:51:04.678261	t	188	2026-08-10 09:27:37.036
111	2026-08-08	14	9	14	Night	submitted	\N	Iftikhar	2026-08-09 07:56:12.533537	\N	2026-08-09 07:56:12.533537	t	188	2026-08-10 09:27:37.036
112	2026-08-08	15	2	14	Night	submitted	\N	Iftikhar	2026-08-09 07:58:42.067577	\N	2026-08-09 07:58:42.067577	t	188	2026-08-10 09:27:37.036
110	2026-08-08	25	9	14	Night	submitted	\N	Iftikhar	2026-08-09 07:54:53.092125	Iftikhar	2026-08-09 08:41:15.456	t	188	2026-08-10 09:27:37.036
119	2026-08-09	22	7	13	Morning	submitted	\N	Iftikhar	2026-08-10 05:26:09.923348	\N	2026-08-10 05:26:09.923348	t	189	2026-08-10 10:26:19.752
120	2026-08-09	23	7	13	Morning	submitted	\N	Iftikhar	2026-08-10 05:27:03.589931	\N	2026-08-10 05:27:03.589931	t	189	2026-08-10 10:26:19.752
121	2026-08-09	24	1	13	Morning	submitted	\N	Iftikhar	2026-08-10 05:28:03.324527	\N	2026-08-10 05:28:03.324527	t	189	2026-08-10 10:26:19.752
125	2026-08-09	24	9	13	Night	submitted	\N	Iftikhar	2026-08-10 05:33:23.641765	\N	2026-08-10 05:33:23.641765	t	189	2026-08-10 10:26:19.752
124	2026-08-09	22	9	13	Night	submitted	\N	Iftikhar	2026-08-10 05:32:19.376356	Iftikhar	2026-08-10 05:34:55.987	t	189	2026-08-10 10:26:19.752
\.


--
-- Data for Name: department_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.department_master (id, name, code) FROM stdin;
1	Administration	0001
3	Loader	0003
4	Checker	0004
2	Operator	0002
\.


--
-- Data for Name: employee_advances; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_advances (id, employee_id, date, amount, notes, created_at) FROM stdin;
1	15	2026-08-06	10000	For rashan k liye	2026-08-06 13:47:29.301977
5	14	2026-08-10	5000	Advance 	2026-08-10 13:37:08.800964
\.


--
-- Data for Name: employee_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_master (id, name, code, department_id, base_salary, overtime_rate_hr, att_allowance, oth_allowance, active) FROM stdin;
10	Iftikhar	9901	1	55000.00	\N	\N	\N	t
11	Imran	9902	1	36000.00	\N	\N	\N	t
12	Liaquat	9903	1	80000.00	\N	\N	\N	t
1	Umaid	001	2	1200.00	\N	2000.00	2000.00	t
2	Nasir	002	2	1200.00	\N	2000.00	2000.00	t
4	Rasheed	003	2	1200.00	\N	2000.00	2000.00	f
3	Sajiid Rehman	004	2	1200.00	\N	2000.00	2000.00	t
5	Zain	005	2	1200.00	\N	2000.00	2000.00	f
6	Rashid	006	2	1200.00	\N	2000.00	2000.00	f
7	Raza	007	2	1200.00	\N	2000.00	2000.00	t
8	Gul Muhammad	008	2	1200.00	\N	2000.00	2000.00	t
9	Kareem	009	2	1200.00	\N	2000.00	2000.00	t
14	Safdar	9905	3	30000.00	100.00	3000.00	\N	t
16	Sardar	9907	3	30000.00	100.00	3000.00	\N	t
15	Dilshad	9906	3	30000.00	100.00	3000.00	\N	t
13	Zulfiqar	9904	4	33000.00	\N	2000.00	\N	f
17	Shiraj	9908	4	33000.00	\N	2000.00	\N	t
18	Quality 	011	2	\N	\N	\N	\N	t
\.


--
-- Data for Name: employee_salary_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_salary_records (id, employee_id, date, base_wage, commission, final_salary, created_at) FROM stdin;
\.


--
-- Data for Name: employee_salary_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_salary_settings (id, employee_id, base_daily_wage) FROM stdin;
1	2	1200
2	4	1200.00
3	6	1200.00
4	3	1200.00
5	1	1200.00
6	5	1200.00
\.


--
-- Data for Name: fabric_type_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fabric_type_master (id, name, code) FROM stdin;
4	RIB (1X1)	RIB (1X1)
2	2-Fleece	2-Fleece
13	3-Fleece	3-Fleece
14	Single Jersey Double Tar	Single Jersey Double Tar
15	RIB (1X1) Double Tar	RIB (1X1) Double Tar
3	RIB (2X1) Double Tar	RIB (2X1) Double Tar
1	Single Jersey	Single Jersey
16	RIB (2X1)	RIB (2X1)
\.


--
-- Data for Name: job_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.job_master (id, name, code, party_id) FROM stdin;
19	Feroze	Feroze	18
16	GWCC	GWCC	15
15	Lucky Knits	Lucky Knits	14
17	Mahad	Mahad	17
14	Perfect	Perfact	16
13	Towellers	Towellers	13
18	Eastern Garments	Eastern	19
\.


--
-- Data for Name: location_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.location_master (id, name, code) FROM stdin;
13	New Karachi	L-001
14	SITE Area	L-002
15	SITE-II Scheme 33	L-003
16	Landhi Industrial Area	L-004
17	Hub Chowki	L-005
18	Kathor, Super Highway	L-006
\.


--
-- Data for Name: machine_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.machine_master (id, name, machine_number, making_rate, needle_change_date, needle_brand, sinker_change_date, sinker_brand) FROM stdin;
25	M#01	M#001	3.75	2025-12-24	Sigma	2025-12-24	Kohala
14	M#02	M-002	3.75	2026-04-10	Sigma	2026-04-10	Kohala
15	M#03	M-003	3.75	2026-07-29	Sigma	2026-07-29	Kohala
18	M#04	M-004	3.75	2025-11-26	Sigma	2025-11-26	Kohala
19	M#05	M-005	3.00	2026-01-15	Sigma	2026-01-21	Kohala
20	M#06	M-006	3.00	2026-01-13	Sigma	2026-01-13	Sigma/YGH
21	M#07	M-007	4.00	2026-07-16	Sigma	2026-07-16	Sigma
22	M#08	M-008	3.75	2026-04-25	Sigma	2026-04-25	Kohala
23	M#09	M-009	3.75	2026-01-26	Sigma	2026-06-12	Kohala
24	M#10	M-010	3.75	2026-07-31	KE Needle	2026-07-31	Kohala
\.


--
-- Data for Name: party_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.party_master (id, name, code, waste_percent) FROM stdin;
13	Towellers Limited	Towellers	1.00
14	Lucky Knits (Pvt) Limited	Lucky	1.00
15	GWCC Master Apperal	GWCC	1.00
16	Perfect Apparel	Perfect	1.00
17	Mahad International	Mahad	1.00
19	Eastern Garments (Pvt) Limited	Eastern	1.00
18	Feroze 1888 Mills Limited	Feroze	2.00
20	Feroze 1888 Mills Limited (PD)	Feroze PD	2.00
\.


--
-- Data for Name: plausibility_baseline; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.plausibility_baseline (id, operation, field, median, iqr, mad, lower_bound, upper_bound, sample_count, computed_at) FROM stdin;
1	receipt	net_weight	1319.555000	1963.844000	1248.860697	0.000000	7211.087000	26	2026-08-11 07:39:31.168
2	receipt	quantity	24.000000	30.250000	26.686800	0.000000	114.750000	26	2026-08-11 07:39:31.187
3	receipt	wt_per_bag	45.360000	4.512920	1.370987	31.821240	58.898760	26	2026-08-11 07:39:31.194
4	receipt	net_total@receipt:party	2675.056000	3374.720500	2917.896164	0.000000	12799.217500	15	2026-08-11 07:39:31.204
5	receipt	net_total@receipt:count	1319.555000	3704.010000	1598.499290	0.000000	12431.585000	20	2026-08-11 07:39:31.216
6	receipt	net_total@receipt:party+count	1274.195000	3357.367500	1231.247409	0.000000	11346.297500	24	2026-08-11 07:39:31.221
7	receipt	net_total@receipt:party+brand	1270.080000	3831.320000	1242.537408	0.000000	12764.040000	21	2026-08-11 07:39:31.227
8	receipt	net_total@receipt:count+brand	1319.555000	3577.661000	1266.251595	0.000000	12052.538000	22	2026-08-11 07:39:31.245
9	receipt	net_total@receipt:date+party	2675.056000	3374.720500	2917.896164	0.000000	12799.217500	15	2026-08-11 07:39:31.255
10	receipt	net_total@receipt:date+party+count	1274.195000	3357.367500	1231.247409	0.000000	11346.297500	24	2026-08-11 07:39:31.261
21	delivery	net_weight	694.750000	919.200000	656.421150	0.000000	3452.350000	31	2026-08-11 11:11:52.797
22	delivery	quantity	26.000000	33.500000	29.652000	0.000000	126.500000	31	2026-08-11 11:11:52.803
23	delivery	gsm	250.000000	0.000000	0.000000	250.000000	250.000000	21	2026-08-11 11:11:52.811
24	delivery	wt_per_roll	26.872000	3.232967	2.348438	17.173100	36.570900	31	2026-08-11 11:11:52.817
25	delivery	net_total@delivery:party	990.450000	1345.200000	729.883980	0.000000	5026.050000	19	2026-08-11 11:11:52.827
26	delivery	net_total@delivery:type	1379.400000	3013.550000	1821.818880	0.000000	10420.050000	13	2026-08-11 11:11:52.834
27	delivery	net_total@delivery:party+type	683.675000	755.375000	548.006025	0.000000	2949.800000	22	2026-08-11 11:11:52.84
28	delivery	net_total@delivery:party+gsm_band	990.450000	1016.750000	777.549570	0.000000	4040.700000	21	2026-08-11 11:11:52.849
29	delivery	net_total@delivery:type+gsm_band	854.675000	1110.975000	613.870530	0.000000	4187.600000	20	2026-08-11 11:11:52.856
30	delivery	net_total@delivery:date+party	990.450000	1345.200000	729.883980	0.000000	5026.050000	19	2026-08-11 11:11:52.861
31	delivery	net_total@delivery:date+party+type	683.675000	755.375000	548.006025	0.000000	2949.800000	22	2026-08-11 11:11:52.87
\.


--
-- Data for Name: plausibility_feedback; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.plausibility_feedback (id, operation, field, entered_value, expected_low, expected_high, outcome, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: salary_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.salary_detail (id, header_id, employee_id, month, year, department_id, employee_name, basic_salary, ot_rate_hr, att_allowance, oth_allowance, present_days, absent_days, holidays, total_attendance, total_salary, ot_hours, ot_amount, advance_deduction, loan_deduction, other_deduction, payable_salary) FROM stdin;
\.


--
-- Data for Name: salary_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.salary_header (id, month, year, department_ids, posted, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: transaction_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_detail (id, header_id, quantity, net_wt, machine_id, employee_id, yarn_type_id, yarn_count_id, yarn_brand_id, uom_id) FROM stdin;
496	153	6.000	179.750	25	1	20	28	1	1
497	153	8.000	236.350	25	9	20	28	1	1
498	153	9.000	259.400	14	8	20	28	1	1
499	153	10.000	259.750	14	2	20	28	1	1
500	153	9.000	256.400	15	8	20	28	1	1
501	153	10.000	265.750	15	2	20	28	1	1
506	155	7.000	175.000	25	1	20	42	1	1
507	155	6.000	158.600	25	9	20	42	1	1
508	155	9.000	281.750	14	8	20	42	1	1
509	155	9.000	269.050	14	9	20	42	1	1
510	155	9.000	266.150	15	8	20	42	1	1
511	155	10.000	276.350	15	2	20	42	1	1
518	157	14.000	635.040	\N	\N	20	2	2	1
520	159	25.000	1134.000	\N	\N	20	2	2	1
521	159	28.000	1270.080	\N	\N	20	1	20	1
525	161	27.000	694.750	\N	\N	20	23	2	1
527	163	37.000	990.450	\N	\N	20	23	1	1
540	136	4.000	102.700	18	7	20	26	3	1
541	136	1.000	23.800	18	2	20	26	3	1
542	136	8.000	199.350	21	1	24	39	3	1
543	136	7.000	209.700	21	9	24	39	3	1
547	166	6.000	153.900	23	7	20	23	1	1
548	166	8.000	206.900	23	2	20	23	1	1
549	166	5.000	135.550	24	1	20	23	1	1
550	166	6.000	175.450	24	9	20	23	1	1
557	151	34.000	1542.240	\N	\N	\N	1	1	1
558	151	12.000	432.000	\N	\N	\N	41	18	1
559	151	50.000	2268.000	\N	\N	\N	17	1	1
560	152	30.000	1360.800	\N	\N	20	1	1	1
561	152	17.000	612.000	\N	\N	20	41	18	1
562	152	29.000	1278.310	\N	\N	20	17	1	1
568	170	20.000	498.150	\N	\N	\N	\N	\N	\N
570	172	1.000	5.300	\N	\N	22	13	3	1
571	172	1.000	9.500	\N	\N	24	13	3	1
572	172	19.000	561.250	\N	\N	24	13	3	1
573	172	14.000	401.700	\N	\N	20	26	13	1
574	172	1.000	11.800	\N	\N	22	13	3	1
575	172	4.000	100.050	\N	\N	24	13	3	1
577	174	58.000	1721.300	\N	\N	20	28	1	1
578	174	59.000	1717.850	\N	\N	20	28	1	1
580	176	50.000	1422.800	\N	\N	20	28	1	1
581	176	59.000	1663.250	\N	\N	20	28	1	1
583	178	25.000	672.600	\N	\N	20	23	2	1
586	180	25.000	671.800	\N	\N	20	23	2	1
590	147	6.000	145.050	23	7	20	23	2	1
591	147	8.000	212.750	23	2	20	23	2	1
593	146	7.000	184.350	23	7	20	23	2	1
594	146	7.000	190.000	23	2	20	23	2	1
595	146	2.000	53.100	24	1	20	23	2	1
596	146	6.000	171.500	24	9	20	23	2	1
608	181	1.000	2675.056	\N	\N	20	23	2	\N
611	164	1.000	7436.424	\N	\N	20	29	1	1
613	183	1.000	706.962	\N	\N	20	29	3	\N
615	185	1.000	50.764	\N	\N	20	37	1	1
618	186	6.000	167.050	22	2	20	23	2	1
619	186	6.000	155.300	23	7	20	23	2	1
620	186	8.000	213.350	23	2	20	23	2	1
621	186	5.000	125.100	24	1	20	23	2	1
622	186	8.000	208.350	24	9	20	23	2	1
628	188	8.000	234.900	25	1	20	42	1	1
629	188	9.000	241.450	25	9	20	42	1	1
630	188	10.000	278.300	14	8	20	42	1	1
631	188	10.000	276.100	14	9	20	42	1	1
632	188	9.000	261.850	15	8	20	42	1	1
633	188	10.000	277.000	15	2	20	42	1	1
639	190	42.000	1116.150	\N	\N	20	23	2	1
641	191	36.000	1011.850	\N	\N	20	42	1	1
642	191	49.000	1391.000	\N	\N	20	42	1	1
643	191	27.000	759.350	\N	\N	20	42	1	1
645	182	1.000	4466.360	\N	\N	20	26	1	1
649	194	121.000	3993.000	\N	\N	20	19	18	1
651	195	31.000	1023.000	\N	\N	2	19	18	1
652	195	45.000	1485.000	\N	\N	2	19	18	1
654	139	6.000	161.050	22	8	20	23	2	1
655	139	5.000	153.250	22	9	20	23	2	1
656	139	7.000	167.900	23	7	20	23	2	1
657	139	8.000	194.200	23	2	20	23	2	1
661	197	7.000	143.500	22	7	20	23	2	1
662	197	3.000	91.500	22	2	20	23	2	1
663	197	4.000	108.200	24	1	20	23	2	1
670	199	6.000	150.600	\N	\N	24	13	3	1
672	200	8.000	176.450	\N	\N	22	17	1	1
481	148	1.000	15.100	18	7	20	26	1	1
484	150	6.000	171.050	25	1	20	28	1	1
485	150	7.000	194.200	25	9	20	28	1	1
486	150	9.000	252.800	14	8	20	28	1	1
487	150	8.000	266.050	14	9	20	28	1	1
488	150	7.000	210.150	15	8	20	28	1	1
489	150	9.000	275.650	15	2	20	28	1	1
502	154	5.000	149.250	23	7	20	23	1	1
503	154	8.000	198.600	23	2	20	23	1	1
504	154	5.000	130.050	24	1	20	23	1	1
505	154	7.000	194.700	24	9	20	23	1	1
519	158	100.000	4536.000	\N	\N	24	13	3	1
526	162	47.000	1233.900	\N	\N	20	23	2	1
528	132	6.000	162.300	25	1	20	29	1	1
529	132	7.000	206.400	25	3	20	29	1	1
530	132	3.000	88.300	14	8	20	29	1	1
531	132	9.000	251.200	14	9	20	29	1	1
532	132	6.000	156.150	15	8	20	29	1	1
533	132	4.000	116.150	15	2	20	29	1	1
538	140	6.000	148.450	24	1	20	23	1	1
539	140	7.000	202.400	24	3	20	23	1	1
429	133	7.000	201.300	25	8	20	29	1	1
430	133	7.000	211.350	25	9	20	29	1	1
431	133	9.000	266.800	14	8	20	29	1	1
432	133	8.000	243.450	14	9	20	29	1	1
433	133	6.000	174.650	15	7	20	29	1	1
434	133	2.000	56.250	15	2	20	29	1	1
435	134	6.000	167.450	25	1	20	29	1	1
436	134	7.000	209.500	25	9	20	29	1	1
437	134	9.000	256.700	14	8	20	29	1	1
438	134	8.000	252.600	14	9	20	29	1	1
439	134	5.000	157.150	15	8	20	29	1	1
440	134	8.000	223.800	15	2	20	29	1	1
441	135	7.000	148.400	18	7	20	26	19	1
442	135	4.000	104.600	18	2	20	26	19	1
447	137	2.000	39.700	18	2	20	29	1	1
448	138	6.000	174.900	21	1	24	39	3	1
449	138	8.000	230.400	21	9	24	39	3	1
456	141	6.000	150.750	22	8	20	23	2	1
457	141	4.000	108.150	22	2	20	23	2	1
458	141	7.000	186.200	23	7	20	23	2	1
459	141	8.000	184.950	23	2	20	23	2	1
460	142	6.000	167.550	24	1	20	23	1	1
461	142	3.000	91.150	24	9	20	23	1	1
462	143	5.000	119.150	18	7	20	26	3	1
463	143	5.000	127.000	18	2	20	26	3	1
464	143	7.000	192.450	21	1	20	26	3	1
465	143	8.000	218.350	21	9	20	26	3	1
466	144	3.000	89.850	22	8	20	23	2	1
467	144	6.000	162.350	23	7	20	23	2	1
468	144	8.000	199.600	23	2	20	23	2	1
551	167	6.000	177.600	25	1	20	42	1	1
552	167	9.000	244.500	25	9	20	42	1	1
553	167	8.000	217.250	14	8	20	42	1	1
554	167	10.000	281.400	14	9	20	42	1	1
555	167	7.000	193.950	15	7	20	42	1	1
556	167	10.000	280.200	15	2	20	42	1	1
567	169	127.000	5760.720	\N	\N	\N	1	1	1
569	171	2.000	39.700	\N	\N	\N	\N	\N	\N
576	173	18.000	439.850	\N	\N	20	26	19	1
579	175	15.000	384.800	\N	\N	20	23	2	1
582	177	22.000	599.300	\N	\N	20	23	2	1
584	179	52.000	1514.900	\N	\N	20	42	1	1
585	179	52.000	1518.400	\N	\N	20	42	1	1
612	165	1.000	1908.837	\N	\N	20	23	3	1
614	184	1.000	455.460	\N	\N	20	29	1	1
616	168	54.000	2442.290	\N	\N	\N	1	1	\N
617	168	33.000	1478.100	\N	\N	\N	17	1	\N
623	187	6.000	173.350	25	1	20	42	1	1
624	187	10.000	285.950	14	1	20	42	1	1
625	187	3.000	86.600	14	9	20	42	1	1
626	187	9.000	262.550	15	7	20	42	1	1
627	187	9.000	254.400	15	9	20	42	1	1
634	189	9.000	189.300	22	7	20	23	2	1
635	189	7.000	173.250	22	9	20	23	2	1
636	189	8.000	197.500	23	7	20	23	2	1
637	189	8.000	227.150	24	1	20	23	2	1
638	189	8.000	212.000	24	9	20	23	2	1
644	192	108.000	4898.880	\N	\N	20	2	3	1
646	193	1.000	1534.500	25	18	24	39	3	1
647	193	1.000	2181.850	25	18	20	26	3	1
648	193	1.000	17.900	25	18	22	13	3	1
653	196	23.000	828.000	\N	\N	20	41	18	1
658	160	11.000	498.960	\N	\N	20	2	2	1
659	160	12.000	432.000	\N	\N	20	19	18	1
660	160	28.000	1270.080	\N	\N	20	1	15	1
664	198	5.000	137.800	25	1	20	28	1	1
665	198	8.000	232.250	25	9	20	28	1	1
666	198	6.000	175.050	14	1	20	28	1	1
667	198	10.000	271.300	14	9	20	28	1	1
668	198	9.000	234.850	15	7	20	28	1	1
669	198	9.000	238.100	15	2	20	28	1	1
\.


--
-- Data for Name: transaction_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_header (id, transaction_type_id, date, doc_number, job_id, party_id, location_id, fabric_type_id, sl, gsm, reference) FROM stdin;
153	5	2026-08-06	20260806	15	14	18	13	\N	\N	\N
155	5	2026-08-05	20260805	15	14	\N	13	\N	\N	\N
157	3	2026-08-03	169827	13	13	\N	13	\N	\N	\N
159	3	2026-08-06	169950	13	13	\N	13	\N	\N	\N
161	6	2026-08-01	3735	13	13	\N	13	960+720+370	\N	\N
163	6	2026-08-03	3737	16	15	\N	13	\N	\N	\N
167	5	2026-08-07	20260807	15	14	\N	13	\N	\N	\N
151	3	2026-08-05	228836	\N	14	\N	13	\N	\N	4700015011
169	3	2026-08-04	852	14	16	\N	\N	\N	\N	\N
171	6	2026-08-04	3739	\N	20	\N	13	\N	\N	\N
173	6	2026-08-04	3743	17	17	\N	13	\N	\N	\N
175	6	2026-08-05	3746	13	13	\N	13	\N	\N	\N
177	6	2026-08-06	3749	13	13	\N	13	\N	\N	\N
179	6	2026-08-07	3751,3752	15	14	\N	13	\N	\N	\N
147	5	2026-08-04	20260804	13	13	\N	13	\N	\N	\N
181	3	2026-07-31	August-26 >----> Opening	\N	13	\N	13	\N	\N	August-26 >----> Opening
165	3	2026-07-31	August-26 >----> Opening	16	15	\N	13	\N	\N	August-26 >----> Opening
183	3	2026-07-31	August-26 >----> Opening	\N	17	\N	13	\N	\N	August-26 >----> Opening
185	3	2026-07-31	August-26 >----> Opening	\N	19	\N	13	\N	\N	August-26 >----> Opening
187	5	2026-08-09	20260809	15	14	\N	13	\N	\N	\N
189	5	2026-08-09	20260809	13	13	\N	13	\N	\N	\N
191	6	2026-08-10	3755,3756,3757	15	14	\N	13	940+640+384	\N	4700015011
193	5	2026-07-31	20260731-1	\N	16	\N	13	\N	\N	20260731-1
195	4	2026-08-01	20260801-1	\N	16	\N	13	\N	\N	20260801-1
197	5	2026-08-10	20260810	13	13	\N	13	\N	\N	\N
199	6	2026-08-10	3758	14	16	\N	4	1160	\N	\N
148	5	2026-08-04	20260804	14	16	\N	13	\N	\N	\N
150	5	2026-08-04	20260804	15	14	\N	13	\N	\N	\N
154	5	2026-08-06	20260808	13	13	\N	13	\N	\N	\N
158	3	2026-08-04	0268	14	16	\N	4	\N	\N	\N
162	6	2026-08-03	3736	13	13	\N	13	960+720+370	\N	\N
132	5	2026-08-01	20260801-01	15	14	13	13	\N	\N	20260801-01
140	5	2026-08-01	20260801-01	16	15	\N	13	\N	\N	20260801-01
136	5	2026-08-02	20260802-01	14	16	\N	13	\N	\N	20260802-01
166	5	2026-08-07	20260807	13	13	\N	13	960+720+370	\N	\N
152	3	2026-08-03	228548	15	14	18	13	\N	\N	4700014961
133	5	2026-08-02	20260802-01	15	14	\N	13	\N	\N	20260802-01
134	5	2026-08-03	20260803-01	15	14	\N	13	\N	\N	20260803-01
135	5	2026-08-01	20260801-01	17	17	\N	13	\N	\N	20260801-01
137	5	2026-08-01	20260801-01	\N	20	\N	13	\N	\N	20260802-01
138	5	2026-08-01	20260801-01	14	16	\N	4	\N	\N	20260801-01
141	5	2026-08-02	20260802-01	13	13	\N	13	\N	\N	20260802-01
142	5	2026-08-02	20260802-01	16	15	\N	13	\N	\N	20260802-01
143	5	2026-08-03	20260803-01	14	16	\N	13	\N	\N	20260803-01
144	5	2026-08-03	20260803-01	13	13	\N	13	\N	\N	20260803-01
170	6	2026-08-04	3738	13	13	\N	13	\N	\N	\N
172	6	2026-08-04	3740,3741,3742	\N	16	\N	13	\N	\N	\N
174	6	2026-08-05	3744,3745	15	14	\N	13	\N	\N	\N
176	6	2026-08-06	3747,3748	15	14	\N	13	\N	\N	\N
178	6	2026-08-07	3750	13	13	\N	13	\N	\N	\N
180	6	2026-08-08	3753	13	13	\N	13	\N	\N	\N
146	5	2026-08-05	20260805	13	13	\N	13	\N	\N	\N
164	3	2026-07-31	August-26 >----> Opening	\N	14	\N	13	\N	\N	August-26 >----> Opening
184	3	2026-07-31	August-26 >----> Opening	\N	20	\N	13	\N	\N	August-26 >----> Opening
168	3	2026-08-05	47*15011	15	14	\N	13	\N	\N	47*15011
186	5	2026-08-08	20260808	13	13	\N	13	\N	\N	\N
188	5	2026-08-08	20260808	15	14	\N	13	\N	\N	\N
190	6	2026-08-10	3754	13	13	\N	13	\N	\N	\N
192	3	2026-08-10	0320	14	16	\N	13	\N	\N	\N
182	3	2026-07-31	August-26 >----> Opening	\N	16	\N	4	\N	\N	August-26 >----> Opening
194	3	2026-08-01	20260801-1	\N	16	\N	13	\N	\N	20260801-1
196	3	2026-08-05	4700015011	15	14	18	13	\N	\N	4700015011
139	5	2026-08-01	20260801-01	13	13	\N	13	\N	\N	20260801-01
160	3	2026-08-01	169808	13	13	\N	13	\N	\N	\N
198	5	2026-08-10	20260810	15	14	\N	13	\N	\N	\N
200	6	2026-08-01	3734	\N	20	\N	1	\N	\N	3734
\.


--
-- Data for Name: transaction_type_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_type_master (id, name, code, action) FROM stdin;
7	Fabric Delivery Return	Fabric_Delivery_Return	Plus
3	Yarn Receipt	Yarn_Receipt	Plus
4	Yarn Return	Yarn_Return	Minus
6	Fabric Delivery	Fabric_Dispatch	Minus
5	Fabric Production	Fabric_Production	\N
\.


--
-- Data for Name: uom_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.uom_master (id, name, abbreviation) FROM stdin;
3	Meter	MTR
1	KG	KG
2	GM	GM
4	PCS	PCS
\.


--
-- Data for Name: yarn_brand_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_brand_master (id, name, code) FROM stdin;
2	Premium	Premium
3	Faisal	Faisal
1	Gadoon	Gadoon
4	Tata	Tata
13	Fazal	Fazal
14	Gul Ahmed	Gul Ahmed
15	Metco	Metco
16	Ibrahim Fiber	Ibrahim
17	Feroze	Feroze
18	CHINA	CHINA
19	Shahzad	Shahzad
20	Relince 	Relince 
\.


--
-- Data for Name: yarn_count_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_count_master (id, name, count) FROM stdin;
19	75/36	75/36
20	50/36	50/36
21	40-D	40-D
22	70-D	70-D
37	20s+70-D Lycra	20s+70-D Lycra
38	30s+40-D Lycra	30s+40-D Lycra
39	20s+40-D Lycra	20s+40-D Lycra
36	30s+70-D Lyc 1.5 Tar	30s+70-D Lyc 1.5 Tar
40	30s+70-D Lyc D.Tar	30s+70-D Lyc D.Tar
1	10s	10s
15	16s	16s
13	20s	20s
33	20s+50/36+10s	20s+50/36+10s
35	20s+50/36+16s	20s+50/36+16s
31	20s+75/36+10s	20s+75/36+10s
32	20s+75/36+16s	20s+75/36+16s
16	24s	24s
17	26s	26s
2	30s	30s
29	30s+50/36+16s	30s+50/36+16s
28	30s+50/36+10s	30s+50/36+10s
30	30s+50/36+20s	30s+50/36+20s
23	30s+75/36+10s	30s+75/36+10s
26	30s+75/36+16s	30s+75/36+16s
27	30s+75/36+20s	30s+75/36+20s
18	32s	32s
3	40s	40s
4	60s	60s
14	08s	08s
41	100/36	100/36
42	26sCTN+100/36+10/1(52/48)	26sCTN+100/36+10/1(52/48)
43	100/20	100/20
\.


--
-- Data for Name: yarn_receipt_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_receipt_detail (id, header_id, yarn_count_id, quantity, net_weight, yarn_brand_id) FROM stdin;
3	3	2	11	498.960	2
4	3	19	12	432.000	18
5	3	1	28	1270.080	15
6	4	2	14	635.040	2
13	7	13	100	4536.000	3
15	9	2	25	1134.000	2
16	9	1	28	1270.080	20
17	5	1	30	1360.800	1
18	5	19	17	612.000	18
19	5	17	29	1278.310	1
20	6	1	34	1542.240	1
21	6	19	12	432.000	18
22	6	17	50	2268.000	1
23	10	1	127	5760.720	1
26	12	26	1	4466.360	1
31	13	23	1	1908.837	3
34	14	29	1	7436.424	1
35	15	29	1	706.962	3
37	11	23	1	2675.056	2
38	16	29	1	455.460	1
41	17	1	54	2442.290	1
42	17	17	33	1478.100	1
43	18	37	1	50.764	1
44	19	2	108	4898.880	3
45	20	19	121	3993.000	18
46	21	41	23	828.000	18
\.


--
-- Data for Name: yarn_receipt_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_receipt_header (id, receipt_date, party_id, status, created_by, created_at, updated_by, updated_at, reconciled, reconciled_transaction_id, reconciled_at, doc_number) FROM stdin;
6	2026-08-05	14	submitted	Iftikhar 	2026-08-06 07:04:15.540986	Iftikhar 	2026-08-06 13:25:13.63	t	151	2026-08-06 13:29:06.366	47*15011
5	2026-08-03	14	submitted	Iftikhar 	2026-08-06 07:00:54.830412	Iftikhar 	2026-08-06 13:24:52.614	t	152	2026-08-06 13:30:37.422	47*14961
4	2026-08-03	13	submitted	Iftikhar 	2026-08-05 15:17:31.325144	\N	2026-08-05 15:17:31.325144	t	157	2026-08-07 09:28:55.475	169827
7	2026-08-04	16	submitted	Iftikhar 	2026-08-06 12:06:12.637753	\N	2026-08-06 12:06:12.637753	t	158	2026-08-07 09:39:44.079	0268
10	2026-08-04	16	submitted	Iftikhar 	2026-08-07 05:50:24.91951	\N	2026-08-07 05:50:24.91951	t	158	2026-08-07 09:39:44.079	852
9	2026-08-06	13	submitted	Iftikhar 	2026-08-06 12:15:37.982881	\N	2026-08-06 12:15:37.982881	t	159	2026-08-07 12:26:22.021	169950
3	2026-08-01	13	submitted	Iftikhar 	2026-08-05 15:13:49.011076	\N	2026-08-05 15:13:49.011076	t	160	2026-08-07 12:33:24.717	169808
14	2026-07-31	14	submitted	Hsn	2026-08-07 14:04:45.734997	Hsn	2026-08-07 14:05:12.041	t	164	2026-08-07 14:14:03.798	August 26 >----> Opening
13	2026-07-31	15	submitted	Hsn	2026-08-07 14:01:43.346427	Hsn	2026-08-07 14:03:58.678	t	165	2026-08-07 14:15:04.336	August-26 >---->  Opening
17	2026-08-05	14	submitted	Iftikhar 	2026-08-07 15:32:50.82745	Iftikhar 	2026-08-08 06:29:51.408	t	168	2026-08-08 06:47:23.411	47*15011
11	2026-07-31	13	submitted	Hsn	2026-08-07 13:32:38.03277	Hsn	2026-08-07 14:08:00.394	t	181	2026-08-08 07:39:21.867	August-26 >----> Opening
12	2026-07-31	16	submitted	Hsn	2026-08-07 13:43:04.390777	\N	2026-08-07 13:43:04.390777	t	182	2026-08-08 07:41:43.774	August-26 >---->Opening
15	2026-07-31	17	submitted	Hsn	2026-08-07 14:07:25.390882	\N	2026-08-07 14:07:25.390882	t	183	2026-08-08 07:44:51.579	August-26 >----> Opening
16	2026-07-31	20	submitted	Hsn	2026-08-07 14:11:11.661753	\N	2026-08-07 14:11:11.661753	t	184	2026-08-08 07:45:42.665	August-26 >----> Opening
18	2026-07-31	19	submitted	Hsn	2026-08-08 06:43:38.165898	\N	2026-08-08 06:43:38.165898	t	185	2026-08-08 07:46:23.931	August-26 >----> Opening
19	2026-08-10	16	submitted	Iftikhar 	2026-08-10 13:32:11.635391	\N	2026-08-10 13:32:11.635391	t	192	2026-08-11 06:12:17.383	0320
20	2026-08-01	16	submitted	Hsn	2026-08-11 07:04:47.713807	\N	2026-08-11 07:04:47.713807	t	194	2026-08-11 07:07:00.433	16237
21	2026-08-05	14	submitted	Iftikhar 	2026-08-11 07:39:31.106192	\N	2026-08-11 07:39:31.106192	t	196	2026-08-11 07:41:22.139	47*15011
\.


--
-- Data for Name: yarn_type_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_type_master (id, name, code, make_rate) FROM stdin;
15	PC (65/35)	PC_65/35	\N
16	PC (75/25)	PC_75/25	\N
19	PC (60/40)	PC_60/40	\N
25	PC (80/20)	PC_80/20	\N
22	Single Jersey	SJ	3.00
21	2-Fleece	2FL	3.00
20	3-Fleece	3FL	3.75
18	HG 	HG	\N
14	PC (52/48)	PC_52/48	\N
17	CVC (60/40)	CVC_60/40	\N
24	RIB (1X1)	RIB_(1X1)	4.00
23	RIB (2X1)	RIB_(2X1)	4.00
2	Polyester	POLYESTER	\N
1	100% Cotton	CTN	\N
\.


--
-- Name: configuration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.configuration_id_seq', 1, true);


--
-- Name: daily_delivery_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_delivery_id_seq', 32, true);


--
-- Name: daily_production_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_production_detail_id_seq', 959, true);


--
-- Name: daily_production_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_production_header_id_seq', 134, true);


--
-- Name: department_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.department_master_id_seq', 4, true);


--
-- Name: fabric_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.fabric_type_master_id_seq', 16, true);


--
-- Name: job_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.job_master_id_seq', 24, true);


--
-- Name: location_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.location_master_id_seq', 18, true);


--
-- Name: machine_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_master_id_seq', 28, true);


--
-- Name: machine_operator_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machine_operator_master_id_seq', 18, true);


--
-- Name: operator_advances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operator_advances_id_seq', 5, true);


--
-- Name: operator_salary_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operator_salary_records_id_seq', 1, false);


--
-- Name: operator_salary_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operator_salary_settings_id_seq', 6, true);


--
-- Name: party_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.party_master_id_seq', 20, true);


--
-- Name: plausibility_baseline_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.plausibility_baseline_id_seq', 64, true);


--
-- Name: plausibility_feedback_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.plausibility_feedback_id_seq', 1, false);


--
-- Name: salary_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.salary_detail_id_seq', 6, true);


--
-- Name: salary_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.salary_header_id_seq', 1, true);


--
-- Name: transaction_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_detail_id_seq', 672, true);


--
-- Name: transaction_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_header_id_seq', 200, true);


--
-- Name: transaction_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_type_master_id_seq', 7, true);


--
-- Name: uom_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.uom_master_id_seq', 12, true);


--
-- Name: yarn_brand_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_brand_master_id_seq', 20, true);


--
-- Name: yarn_count_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_count_master_id_seq', 44, true);


--
-- Name: yarn_receipt_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_receipt_detail_id_seq', 46, true);


--
-- Name: yarn_receipt_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_receipt_header_id_seq', 21, true);


--
-- Name: yarn_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_type_master_id_seq', 25, true);


--
-- Name: _applied_migrations _applied_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._applied_migrations
    ADD CONSTRAINT _applied_migrations_pkey PRIMARY KEY (name);


--
-- Name: configuration configuration_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration
    ADD CONSTRAINT configuration_code_unique UNIQUE (code);


--
-- Name: configuration configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration
    ADD CONSTRAINT configuration_pkey PRIMARY KEY (id);


--
-- Name: daily_delivery daily_delivery_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_delivery
    ADD CONSTRAINT daily_delivery_pkey PRIMARY KEY (id);


--
-- Name: daily_production_detail daily_production_detail_header_roll_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_detail
    ADD CONSTRAINT daily_production_detail_header_roll_unique UNIQUE (header_id, roll_number);


--
-- Name: daily_production_detail daily_production_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_detail
    ADD CONSTRAINT daily_production_detail_pkey PRIMARY KEY (id);


--
-- Name: daily_production_header daily_production_header_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header
    ADD CONSTRAINT daily_production_header_pkey PRIMARY KEY (id);


--
-- Name: department_master department_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_master
    ADD CONSTRAINT department_master_code_unique UNIQUE (code);


--
-- Name: department_master department_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_master
    ADD CONSTRAINT department_master_pkey PRIMARY KEY (id);


--
-- Name: employee_advances employee_advances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_advances
    ADD CONSTRAINT employee_advances_pkey PRIMARY KEY (id);


--
-- Name: employee_master employee_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_master
    ADD CONSTRAINT employee_master_code_unique UNIQUE (code);


--
-- Name: employee_master employee_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_master
    ADD CONSTRAINT employee_master_pkey PRIMARY KEY (id);


--
-- Name: employee_salary_records employee_salary_records_employee_id_date_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_records
    ADD CONSTRAINT employee_salary_records_employee_id_date_unique UNIQUE (employee_id, date);


--
-- Name: employee_salary_records employee_salary_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_records
    ADD CONSTRAINT employee_salary_records_pkey PRIMARY KEY (id);


--
-- Name: employee_salary_settings employee_salary_settings_employee_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_settings
    ADD CONSTRAINT employee_salary_settings_employee_id_unique UNIQUE (employee_id);


--
-- Name: employee_salary_settings employee_salary_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_settings
    ADD CONSTRAINT employee_salary_settings_pkey PRIMARY KEY (id);


--
-- Name: fabric_type_master fabric_type_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fabric_type_master
    ADD CONSTRAINT fabric_type_master_code_unique UNIQUE (code);


--
-- Name: fabric_type_master fabric_type_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fabric_type_master
    ADD CONSTRAINT fabric_type_master_pkey PRIMARY KEY (id);


--
-- Name: job_master job_master_party_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_master
    ADD CONSTRAINT job_master_party_code_unique UNIQUE (party_id, code);


--
-- Name: job_master job_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_master
    ADD CONSTRAINT job_master_pkey PRIMARY KEY (id);


--
-- Name: location_master location_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_master
    ADD CONSTRAINT location_master_code_unique UNIQUE (code);


--
-- Name: location_master location_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_master
    ADD CONSTRAINT location_master_pkey PRIMARY KEY (id);


--
-- Name: machine_master machine_master_machine_number_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_master
    ADD CONSTRAINT machine_master_machine_number_unique UNIQUE (machine_number);


--
-- Name: machine_master machine_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_master
    ADD CONSTRAINT machine_master_pkey PRIMARY KEY (id);


--
-- Name: party_master party_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.party_master
    ADD CONSTRAINT party_master_code_unique UNIQUE (code);


--
-- Name: party_master party_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.party_master
    ADD CONSTRAINT party_master_pkey PRIMARY KEY (id);


--
-- Name: plausibility_baseline plausibility_baseline_operation_field_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plausibility_baseline
    ADD CONSTRAINT plausibility_baseline_operation_field_unique UNIQUE (operation, field);


--
-- Name: plausibility_baseline plausibility_baseline_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plausibility_baseline
    ADD CONSTRAINT plausibility_baseline_pkey PRIMARY KEY (id);


--
-- Name: plausibility_feedback plausibility_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plausibility_feedback
    ADD CONSTRAINT plausibility_feedback_pkey PRIMARY KEY (id);


--
-- Name: salary_detail salary_detail_emp_month_year_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_emp_month_year_unique UNIQUE (employee_id, month, year);


--
-- Name: salary_detail salary_detail_header_employee_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_header_employee_unique UNIQUE (header_id, employee_id);


--
-- Name: salary_detail salary_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_pkey PRIMARY KEY (id);


--
-- Name: salary_header salary_header_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_header
    ADD CONSTRAINT salary_header_pkey PRIMARY KEY (id);


--
-- Name: transaction_detail transaction_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_pkey PRIMARY KEY (id);


--
-- Name: transaction_header transaction_header_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_pkey PRIMARY KEY (id);


--
-- Name: transaction_type_master transaction_type_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_type_master
    ADD CONSTRAINT transaction_type_master_code_unique UNIQUE (code);


--
-- Name: transaction_type_master transaction_type_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_type_master
    ADD CONSTRAINT transaction_type_master_pkey PRIMARY KEY (id);


--
-- Name: uom_master uom_master_abbreviation_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uom_master
    ADD CONSTRAINT uom_master_abbreviation_unique UNIQUE (abbreviation);


--
-- Name: uom_master uom_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uom_master
    ADD CONSTRAINT uom_master_pkey PRIMARY KEY (id);


--
-- Name: yarn_brand_master yarn_brand_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_brand_master
    ADD CONSTRAINT yarn_brand_master_code_unique UNIQUE (code);


--
-- Name: yarn_brand_master yarn_brand_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_brand_master
    ADD CONSTRAINT yarn_brand_master_pkey PRIMARY KEY (id);


--
-- Name: yarn_count_master yarn_count_master_count_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_count_master
    ADD CONSTRAINT yarn_count_master_count_unique UNIQUE (count);


--
-- Name: yarn_count_master yarn_count_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_count_master
    ADD CONSTRAINT yarn_count_master_pkey PRIMARY KEY (id);


--
-- Name: yarn_receipt_detail yarn_receipt_detail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_detail
    ADD CONSTRAINT yarn_receipt_detail_pkey PRIMARY KEY (id);


--
-- Name: yarn_receipt_header yarn_receipt_header_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_header
    ADD CONSTRAINT yarn_receipt_header_pkey PRIMARY KEY (id);


--
-- Name: yarn_type_master yarn_type_master_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_type_master
    ADD CONSTRAINT yarn_type_master_code_unique UNIQUE (code);


--
-- Name: yarn_type_master yarn_type_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_type_master
    ADD CONSTRAINT yarn_type_master_pkey PRIMARY KEY (id);


--
-- Name: daily_delivery_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX daily_delivery_date_idx ON public.daily_delivery USING btree (delivery_date, party_id);


--
-- Name: daily_delivery_reconcile_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX daily_delivery_reconcile_idx ON public.daily_delivery USING btree (delivery_date, party_id, reconciled);


--
-- Name: daily_production_header_reconcile_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX daily_production_header_reconcile_idx ON public.daily_production_header USING btree (production_date, party_id, reconciled);


--
-- Name: daily_production_header_summary_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX daily_production_header_summary_idx ON public.daily_production_header USING btree (production_date, machine_id, employee_id, party_id, shift);


--
-- Name: plausibility_feedback_operation_field_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX plausibility_feedback_operation_field_idx ON public.plausibility_feedback USING btree (operation, field);


--
-- Name: yarn_receipt_header_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX yarn_receipt_header_date_idx ON public.yarn_receipt_header USING btree (receipt_date, party_id);


--
-- Name: yarn_receipt_header_reconcile_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX yarn_receipt_header_reconcile_idx ON public.yarn_receipt_header USING btree (receipt_date, party_id, reconciled);


--
-- Name: daily_delivery daily_delivery_party_id_party_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_delivery
    ADD CONSTRAINT daily_delivery_party_id_party_master_id_fk FOREIGN KEY (party_id) REFERENCES public.party_master(id);


--
-- Name: daily_delivery daily_delivery_reconciled_transaction_id_transaction_header_id_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_delivery
    ADD CONSTRAINT daily_delivery_reconciled_transaction_id_transaction_header_id_ FOREIGN KEY (reconciled_transaction_id) REFERENCES public.transaction_header(id) ON DELETE SET NULL;


--
-- Name: daily_delivery daily_delivery_yarn_type_id_yarn_type_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_delivery
    ADD CONSTRAINT daily_delivery_yarn_type_id_yarn_type_master_id_fk FOREIGN KEY (yarn_type_id) REFERENCES public.yarn_type_master(id);


--
-- Name: daily_production_detail daily_production_detail_header_id_daily_production_header_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_detail
    ADD CONSTRAINT daily_production_detail_header_id_daily_production_header_id_fk FOREIGN KEY (header_id) REFERENCES public.daily_production_header(id) ON DELETE CASCADE;


--
-- Name: daily_production_header daily_production_header_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header
    ADD CONSTRAINT daily_production_header_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: daily_production_header daily_production_header_machine_id_machine_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header
    ADD CONSTRAINT daily_production_header_machine_id_machine_master_id_fk FOREIGN KEY (machine_id) REFERENCES public.machine_master(id);


--
-- Name: daily_production_header daily_production_header_party_id_party_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header
    ADD CONSTRAINT daily_production_header_party_id_party_master_id_fk FOREIGN KEY (party_id) REFERENCES public.party_master(id);


--
-- Name: daily_production_header daily_production_header_reconciled_transaction_id_transaction_h; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_production_header
    ADD CONSTRAINT daily_production_header_reconciled_transaction_id_transaction_h FOREIGN KEY (reconciled_transaction_id) REFERENCES public.transaction_header(id) ON DELETE SET NULL;


--
-- Name: employee_advances employee_advances_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_advances
    ADD CONSTRAINT employee_advances_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: employee_salary_records employee_salary_records_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_records
    ADD CONSTRAINT employee_salary_records_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: employee_salary_settings employee_salary_settings_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_salary_settings
    ADD CONSTRAINT employee_salary_settings_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: salary_detail salary_detail_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: salary_detail salary_detail_header_id_salary_header_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_detail
    ADD CONSTRAINT salary_detail_header_id_salary_header_id_fk FOREIGN KEY (header_id) REFERENCES public.salary_header(id) ON DELETE CASCADE;


--
-- Name: transaction_detail transaction_detail_employee_id_employee_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_employee_id_employee_master_id_fk FOREIGN KEY (employee_id) REFERENCES public.employee_master(id);


--
-- Name: transaction_detail transaction_detail_header_id_transaction_header_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_header_id_transaction_header_id_fk FOREIGN KEY (header_id) REFERENCES public.transaction_header(id) ON DELETE CASCADE;


--
-- Name: transaction_detail transaction_detail_machine_id_machine_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_machine_id_machine_master_id_fk FOREIGN KEY (machine_id) REFERENCES public.machine_master(id);


--
-- Name: transaction_detail transaction_detail_uom_id_uom_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_uom_id_uom_master_id_fk FOREIGN KEY (uom_id) REFERENCES public.uom_master(id);


--
-- Name: transaction_detail transaction_detail_yarn_brand_id_yarn_brand_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_yarn_brand_id_yarn_brand_master_id_fk FOREIGN KEY (yarn_brand_id) REFERENCES public.yarn_brand_master(id);


--
-- Name: transaction_detail transaction_detail_yarn_count_id_yarn_count_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_yarn_count_id_yarn_count_master_id_fk FOREIGN KEY (yarn_count_id) REFERENCES public.yarn_count_master(id);


--
-- Name: transaction_detail transaction_detail_yarn_type_id_yarn_type_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_yarn_type_id_yarn_type_master_id_fk FOREIGN KEY (yarn_type_id) REFERENCES public.yarn_type_master(id);


--
-- Name: transaction_header transaction_header_fabric_type_id_fabric_type_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_fabric_type_id_fabric_type_master_id_fk FOREIGN KEY (fabric_type_id) REFERENCES public.fabric_type_master(id);


--
-- Name: transaction_header transaction_header_job_id_job_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_job_id_job_master_id_fk FOREIGN KEY (job_id) REFERENCES public.job_master(id);


--
-- Name: transaction_header transaction_header_location_id_location_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_location_id_location_master_id_fk FOREIGN KEY (location_id) REFERENCES public.location_master(id);


--
-- Name: transaction_header transaction_header_party_id_party_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_party_id_party_master_id_fk FOREIGN KEY (party_id) REFERENCES public.party_master(id);


--
-- Name: transaction_header transaction_header_transaction_type_id_transaction_type_master_; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_transaction_type_id_transaction_type_master_ FOREIGN KEY (transaction_type_id) REFERENCES public.transaction_type_master(id);


--
-- Name: yarn_receipt_detail yarn_receipt_detail_header_id_yarn_receipt_header_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_detail
    ADD CONSTRAINT yarn_receipt_detail_header_id_yarn_receipt_header_id_fk FOREIGN KEY (header_id) REFERENCES public.yarn_receipt_header(id) ON DELETE CASCADE;


--
-- Name: yarn_receipt_detail yarn_receipt_detail_yarn_brand_id_yarn_brand_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_detail
    ADD CONSTRAINT yarn_receipt_detail_yarn_brand_id_yarn_brand_master_id_fk FOREIGN KEY (yarn_brand_id) REFERENCES public.yarn_brand_master(id);


--
-- Name: yarn_receipt_detail yarn_receipt_detail_yarn_count_id_yarn_count_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_detail
    ADD CONSTRAINT yarn_receipt_detail_yarn_count_id_yarn_count_master_id_fk FOREIGN KEY (yarn_count_id) REFERENCES public.yarn_count_master(id);


--
-- Name: yarn_receipt_header yarn_receipt_header_party_id_party_master_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_header
    ADD CONSTRAINT yarn_receipt_header_party_id_party_master_id_fk FOREIGN KEY (party_id) REFERENCES public.party_master(id);


--
-- Name: yarn_receipt_header yarn_receipt_header_reconciled_transaction_id_transaction_heade; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_receipt_header
    ADD CONSTRAINT yarn_receipt_header_reconciled_transaction_id_transaction_heade FOREIGN KEY (reconciled_transaction_id) REFERENCES public.transaction_header(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict Z1FdGITzDbaRrVDNkXqEeji9F8i06Xdg1k6hAHXIX2mfUPKwoWx8cXDbVpKOaIl

