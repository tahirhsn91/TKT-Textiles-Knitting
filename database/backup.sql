--
-- PostgreSQL database dump
--

\restrict nSWTMstfXjdcn7qBixPSFreQ0kQkb1MzsqW30wA3HbTKZkKlykhkjkwNxxGigSc

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

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

ALTER TABLE IF EXISTS ONLY public.transaction_header DROP CONSTRAINT IF EXISTS transaction_header_transaction_type_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_header DROP CONSTRAINT IF EXISTS transaction_header_party_id_party_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_header DROP CONSTRAINT IF EXISTS transaction_header_location_id_location_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_header DROP CONSTRAINT IF EXISTS transaction_header_job_id_job_master_id_fk;
ALTER TABLE IF EXISTS ONLY public.transaction_header DROP CONSTRAINT IF EXISTS transaction_header_fabric_type_id_fkey;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_yarn_type_id_fkey;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_yarn_count_id_fkey;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_yarn_brand_id_fkey;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_uom_id_fkey;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_machine_operator_id_fkey;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_machine_id_fkey;
ALTER TABLE IF EXISTS ONLY public.transaction_detail DROP CONSTRAINT IF EXISTS transaction_detail_header_id_transaction_header_id_fk;
ALTER TABLE IF EXISTS ONLY public.operator_salary_settings DROP CONSTRAINT IF EXISTS operator_salary_settings_operator_id_fkey;
ALTER TABLE IF EXISTS ONLY public.operator_salary_records DROP CONSTRAINT IF EXISTS operator_salary_records_operator_id_fkey;
ALTER TABLE IF EXISTS ONLY public.operator_advances DROP CONSTRAINT IF EXISTS operator_advances_operator_id_fkey;
ALTER TABLE IF EXISTS ONLY public.job_master DROP CONSTRAINT IF EXISTS job_master_party_id_fkey;
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
ALTER TABLE IF EXISTS ONLY public.party_master DROP CONSTRAINT IF EXISTS party_master_pkey;
ALTER TABLE IF EXISTS ONLY public.party_master DROP CONSTRAINT IF EXISTS party_master_code_unique;
ALTER TABLE IF EXISTS ONLY public.operator_salary_settings DROP CONSTRAINT IF EXISTS operator_salary_settings_pkey;
ALTER TABLE IF EXISTS ONLY public.operator_salary_settings DROP CONSTRAINT IF EXISTS operator_salary_settings_operator_id_key;
ALTER TABLE IF EXISTS ONLY public.operator_salary_records DROP CONSTRAINT IF EXISTS operator_salary_records_pkey;
ALTER TABLE IF EXISTS ONLY public.operator_salary_records DROP CONSTRAINT IF EXISTS operator_salary_records_operator_id_date_key;
ALTER TABLE IF EXISTS ONLY public.operator_advances DROP CONSTRAINT IF EXISTS operator_advances_pkey;
ALTER TABLE IF EXISTS ONLY public.machine_operator_master DROP CONSTRAINT IF EXISTS machine_operator_master_pkey;
ALTER TABLE IF EXISTS ONLY public.machine_operator_master DROP CONSTRAINT IF EXISTS machine_operator_master_code_key;
ALTER TABLE IF EXISTS ONLY public.machine_master DROP CONSTRAINT IF EXISTS machine_master_pkey;
ALTER TABLE IF EXISTS ONLY public.machine_master DROP CONSTRAINT IF EXISTS machine_master_machine_number_unique;
ALTER TABLE IF EXISTS ONLY public.location_master DROP CONSTRAINT IF EXISTS location_master_pkey;
ALTER TABLE IF EXISTS ONLY public.location_master DROP CONSTRAINT IF EXISTS location_master_code_unique;
ALTER TABLE IF EXISTS ONLY public.job_master DROP CONSTRAINT IF EXISTS job_master_pkey;
ALTER TABLE IF EXISTS ONLY public.job_master DROP CONSTRAINT IF EXISTS job_master_party_code_unique;
ALTER TABLE IF EXISTS ONLY public.fabric_type_master DROP CONSTRAINT IF EXISTS fabric_type_master_pkey;
ALTER TABLE IF EXISTS ONLY public.fabric_type_master DROP CONSTRAINT IF EXISTS fabric_type_master_code_unique;
ALTER TABLE IF EXISTS public.yarn_type_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.yarn_count_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.yarn_brand_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.uom_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.transaction_type_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.transaction_header ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.transaction_detail ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.party_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.operator_salary_settings ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.operator_salary_records ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.operator_advances ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.machine_operator_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.machine_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.location_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.job_master ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.fabric_type_master ALTER COLUMN id DROP DEFAULT;
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
SET default_tablespace = '';

SET default_table_access_method = heap;

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
    machine_number text NOT NULL
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
-- Name: machine_operator_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machine_operator_master (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL
);


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

ALTER SEQUENCE public.machine_operator_master_id_seq OWNED BY public.machine_operator_master.id;


--
-- Name: operator_advances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operator_advances (
    id integer NOT NULL,
    operator_id integer NOT NULL,
    date text NOT NULL,
    amount numeric NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT now()
);


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

ALTER SEQUENCE public.operator_advances_id_seq OWNED BY public.operator_advances.id;


--
-- Name: operator_salary_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operator_salary_records (
    id integer NOT NULL,
    operator_id integer NOT NULL,
    date text NOT NULL,
    base_wage numeric NOT NULL,
    commission numeric DEFAULT 0 NOT NULL,
    final_salary numeric NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


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

ALTER SEQUENCE public.operator_salary_records_id_seq OWNED BY public.operator_salary_records.id;


--
-- Name: operator_salary_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operator_salary_settings (
    id integer NOT NULL,
    operator_id integer NOT NULL,
    base_daily_wage numeric DEFAULT 0 NOT NULL
);


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

ALTER SEQUENCE public.operator_salary_settings_id_seq OWNED BY public.operator_salary_settings.id;


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
-- Name: transaction_detail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_detail (
    id integer NOT NULL,
    header_id integer NOT NULL,
    quantity numeric(12,3),
    net_wt numeric(12,3),
    machine_id integer,
    machine_operator_id integer,
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
-- Name: machine_operator_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_operator_master ALTER COLUMN id SET DEFAULT nextval('public.machine_operator_master_id_seq'::regclass);


--
-- Name: operator_advances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_advances ALTER COLUMN id SET DEFAULT nextval('public.operator_advances_id_seq'::regclass);


--
-- Name: operator_salary_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_salary_records ALTER COLUMN id SET DEFAULT nextval('public.operator_salary_records_id_seq'::regclass);


--
-- Name: operator_salary_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_salary_settings ALTER COLUMN id SET DEFAULT nextval('public.operator_salary_settings_id_seq'::regclass);


--
-- Name: party_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.party_master ALTER COLUMN id SET DEFAULT nextval('public.party_master_id_seq'::regclass);


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
-- Name: yarn_type_master id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yarn_type_master ALTER COLUMN id SET DEFAULT nextval('public.yarn_type_master_id_seq'::regclass);


--
-- Data for Name: fabric_type_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fabric_type_master (id, name, code) FROM stdin;
3	RIB (2X1)	RIB (2X1)
4	RIB (1X1)	RIB (1X1)
1	Single Jersey	SJ
2	2-Fleece	2-Fleece
13	3-Fleece	3-Fleece
14	Single Jersey Double Tar	Single Jersey Double Tar
15	RIB (1X1) Double Tar	RIB (1X1) Double Tar
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
20	Job#0001	Job#0001	14
21	Job#0002	Job#0002	14
24	Job#0003	Job#0003	14
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

COPY public.machine_master (id, name, machine_number) FROM stdin;
18	M#04	M-004
19	M#05	M-005
20	M#06	M-006
21	M#07	M-007
22	M#08	M-008
23	M#09	M-009
24	M#10	M-010
25	M#01	M#001
14	M#02	M-002
15	M#03	M-003
\.


--
-- Data for Name: machine_operator_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.machine_operator_master (id, name, code) FROM stdin;
1	Umaid	001
2	Nasir	002
4	Rasheed	003
3	Sajiid Rehman	004
5	Zain	005
6	Rashid	006
\.


--
-- Data for Name: operator_advances; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.operator_advances (id, operator_id, date, amount, notes, created_at) FROM stdin;
\.


--
-- Data for Name: operator_salary_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.operator_salary_records (id, operator_id, date, base_wage, commission, final_salary, created_at) FROM stdin;
\.


--
-- Data for Name: operator_salary_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.operator_salary_settings (id, operator_id, base_daily_wage) FROM stdin;
1	2	1200
2	4	1200.00
3	6	1200.00
4	3	1200.00
5	1	1200.00
6	5	1200.00
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
\.


--
-- Data for Name: transaction_detail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_detail (id, header_id, quantity, net_wt, machine_id, machine_operator_id, yarn_type_id, yarn_count_id, yarn_brand_id, uom_id) FROM stdin;
275	26	23.000	609.850	\N	\N	20	28	\N	1
276	27	24.000	626.150	\N	\N	20	28	\N	1
277	28	24.000	619.850	\N	\N	20	28	\N	1
278	29	59.000	1185.600	\N	\N	20	29	\N	1
280	42	11.000	498.960	\N	\N	25	2	1	1
229	16	40.000	1784.960	\N	\N	19	2	1	1
230	16	49.000	2201.450	\N	\N	19	1	1	1
231	17	24.000	609.300	\N	\N	20	28	\N	1
232	15	59.000	1523.000	\N	\N	20	\N	\N	1
233	18	53.000	1334.350	\N	\N	20	28	\N	1
234	19	55.000	1410.200	\N	\N	20	28	\N	1
237	21	12.000	396.000	\N	\N	20	28	\N	1
238	14	1.000	7908.664	\N	\N	\N	\N	\N	1
246	24	52.000	1281.150	\N	\N	20	28	\N	1
247	25	24.000	613.000	\N	\N	20	33	\N	1
253	30	11.000	396.000	\N	\N	13	20	18	1
254	30	55.000	2483.650	\N	\N	16	15	1	1
255	30	45.000	2004.350	\N	\N	25	2	1	1
256	31	45.000	1095.300	\N	\N	20	29	\N	1
257	32	38.000	957.700	\N	\N	20	29	\N	1
258	33	36.000	962.450	\N	\N	20	29	\N	1
259	34	43.000	1094.900	\N	\N	20	29	\N	1
260	35	43.000	1092.600	\N	\N	20	26	\N	1
261	36	38.000	966.150	\N	\N	20	29	\N	1
262	37	37.000	976.050	\N	\N	20	29	\N	1
263	22	56.000	1409.950	\N	\N	20	28	\N	1
264	23	15.000	540.000	\N	\N	13	20	18	1
265	23	40.000	1775.340	\N	\N	16	15	1	1
266	23	50.000	2292.370	\N	\N	25	2	1	1
267	38	50.000	2227.980	\N	\N	16	1	1	1
268	38	10.000	360.000	\N	\N	13	20	18	1
269	38	40.000	1806.470	\N	\N	1	2	1	1
270	39	1.000	33.600	\N	\N	23	22	\N	1
271	40	21.000	921.390	\N	\N	23	2	\N	1
272	41	2.000	90.720	\N	\N	14	1	1	1
273	41	11.000	498.960	\N	\N	25	2	1	1
274	20	56.000	1405.200	\N	\N	20	28	\N	1
\.


--
-- Data for Name: transaction_header; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_header (id, transaction_type_id, date, doc_number, job_id, party_id, location_id, fabric_type_id, sl, gsm, reference) FROM stdin;
40	3	2026-05-18	GP#218137	\N	14	\N	3	\N	\N	4700013990
41	3	2026-05-20	GP#218543	\N	14	\N	13	\N	\N	4700013934-13772
20	6	2026-05-06	3498	\N	14	\N	13	\N	\N	4700013703
26	6	2026-05-11	3507	\N	14	\N	13	\N	\N	4700013772
27	6	2026-05-11	3508	\N	14	\N	13	\N	\N	4700013772
28	6	2026-05-13	3517	\N	14	\N	13	\N	\N	4700013772
29	6	2026-05-13	3518	\N	14	\N	13	\N	\N	4700013851
42	3	2026-06-20	GP#218543	\N	14	\N	13	\N	\N	4700013934-13772
16	3	2026-05-05	GP#215461	\N	14	\N	\N	\N	\N	4700013772
17	6	2026-05-05	3488	\N	14	\N	13	\N	\N	4700013632
15	6	2026-05-02	3482	\N	14	\N	13	\N	\N	4700013632
18	6	2026-05-05	3489	\N	14	\N	\N	\N	\N	4700013703
19	6	2026-05-05	3490	\N	14	\N	13	\N	\N	4700013703
21	3	2026-05-06	GP#215800	\N	14	\N	13	\N	\N	4700013772
14	3	2026-04-30	Opening Balance	\N	14	\N	13	\N	\N	Opening Balance
24	6	2026-05-09	3503	\N	14	\N	13	\N	\N	4700013772
25	6	2026-05-11	3506	\N	14	\N	13	\N	\N	4700013772
30	3	2026-05-13	GP#217343	\N	14	\N	13	\N	\N	4700013934
31	6	2026-05-16	3523	\N	14	\N	13	\N	\N	4700013851
32	6	2026-05-16	3524	\N	14	\N	\N	\N	\N	4700013934
33	6	2026-05-16	3525	\N	14	\N	13	\N	\N	4700013934
34	6	2026-05-18	3531	\N	14	\N	13	\N	\N	4700013851
35	6	2026-05-18	3532	\N	14	\N	13	\N	\N	4700013851
36	6	2026-05-18	3533	\N	14	\N	13	\N	\N	4700013934
37	6	2026-05-19	3539	\N	14	\N	13	\N	\N	4700013934
22	6	2026-05-08	3501	\N	14	\N	13	\N	\N	4700013703
23	3	2026-05-08	GP#216212	\N	14	\N	13	\N	\N	4700013851
38	3	2026-05-18	GP#218136	\N	14	\N	13	\N	\N	4700014021
39	3	2026-05-18	GP#218137	\N	14	\N	3	\N	\N	4700013990
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
\.


--
-- Data for Name: yarn_count_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_count_master (id, name, count) FROM stdin;
2	30s	30
15	16s	16
13	20s	20
16	24s	24
17	26s	26
18	32s	32
3	40s	40
4	60s	60
19	75/36	75/36
20	50/36	50/36
21	40-D	40-D
22	70-D	70-D
23	30s+75/36+10s	1
26	30s+75/36+16s	2
27	30s+75/36+20s	3
28	30s+50/36+10s	4
29	30s+50/36+16s	5
30	30s+50/36+20s	6
31	20s+75/36+10s	7
32	20s+75/36+16s	8
33	20s+50/36+10s	9
35	20s+50/36+16s	A1
1	10s	10
14	08s	08
37	20s+70-D Lycra	20s+70-D Lycra
38	30s+40-D Lycra	30s+40-D Lycra
39	20s+40-D Lycra	20s+40-D Lycra
36	30s+70-D Lyc 1.5 Tar	30s+70-D Lyc 1.5 Tar
40	30s+70-D Lyc D.Tar	30s+70-D Lyc D.Tar
\.


--
-- Data for Name: yarn_type_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yarn_type_master (id, name, code, make_rate) FROM stdin;
2	Polyester 75/36	POLY_75/36	\N
15	PC (65/35)	PC_65/35	\N
16	PC (75/25)	PC_75/25	\N
19	PC (60/40)	PC_60/40	\N
13	Polyester 50/36	POLY_50/36	\N
25	PC (80/20)	PC_80/20	\N
22	Single Jersey	SJ	3.00
1	100% Cotton	CTN	999.99
21	2-Fleece	2FL	3.00
20	3-Fleece	3FL	3.75
18	HG 	HG	\N
14	PC (52/48)	PC_52/48	\N
17	CVC (60/40)	CVC_60/40	\N
24	RIB (1X1)	RIB_(1X1)	4.00
23	RIB (2X1)	RIB_(2X1)	4.00
\.


--
-- Name: fabric_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.fabric_type_master_id_seq', 15, true);


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

SELECT pg_catalog.setval('public.machine_operator_master_id_seq', 6, true);


--
-- Name: operator_advances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operator_advances_id_seq', 1, false);


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

SELECT pg_catalog.setval('public.party_master_id_seq', 19, true);


--
-- Name: transaction_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_detail_id_seq', 280, true);


--
-- Name: transaction_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_header_id_seq', 42, true);


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

SELECT pg_catalog.setval('public.yarn_brand_master_id_seq', 18, true);


--
-- Name: yarn_count_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_count_master_id_seq', 40, true);


--
-- Name: yarn_type_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yarn_type_master_id_seq', 25, true);


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
-- Name: machine_operator_master machine_operator_master_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_operator_master
    ADD CONSTRAINT machine_operator_master_code_key UNIQUE (code);


--
-- Name: machine_operator_master machine_operator_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_operator_master
    ADD CONSTRAINT machine_operator_master_pkey PRIMARY KEY (id);


--
-- Name: operator_advances operator_advances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_advances
    ADD CONSTRAINT operator_advances_pkey PRIMARY KEY (id);


--
-- Name: operator_salary_records operator_salary_records_operator_id_date_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_salary_records
    ADD CONSTRAINT operator_salary_records_operator_id_date_key UNIQUE (operator_id, date);


--
-- Name: operator_salary_records operator_salary_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_salary_records
    ADD CONSTRAINT operator_salary_records_pkey PRIMARY KEY (id);


--
-- Name: operator_salary_settings operator_salary_settings_operator_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_salary_settings
    ADD CONSTRAINT operator_salary_settings_operator_id_key UNIQUE (operator_id);


--
-- Name: operator_salary_settings operator_salary_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_salary_settings
    ADD CONSTRAINT operator_salary_settings_pkey PRIMARY KEY (id);


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
-- Name: job_master job_master_party_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_master
    ADD CONSTRAINT job_master_party_id_fkey FOREIGN KEY (party_id) REFERENCES public.party_master(id);


--
-- Name: operator_advances operator_advances_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_advances
    ADD CONSTRAINT operator_advances_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.machine_operator_master(id);


--
-- Name: operator_salary_records operator_salary_records_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_salary_records
    ADD CONSTRAINT operator_salary_records_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.machine_operator_master(id);


--
-- Name: operator_salary_settings operator_salary_settings_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operator_salary_settings
    ADD CONSTRAINT operator_salary_settings_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.machine_operator_master(id);


--
-- Name: transaction_detail transaction_detail_header_id_transaction_header_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_header_id_transaction_header_id_fk FOREIGN KEY (header_id) REFERENCES public.transaction_header(id) ON DELETE CASCADE;


--
-- Name: transaction_detail transaction_detail_machine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_machine_id_fkey FOREIGN KEY (machine_id) REFERENCES public.machine_master(id);


--
-- Name: transaction_detail transaction_detail_machine_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_machine_operator_id_fkey FOREIGN KEY (machine_operator_id) REFERENCES public.machine_operator_master(id);


--
-- Name: transaction_detail transaction_detail_uom_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_uom_id_fkey FOREIGN KEY (uom_id) REFERENCES public.uom_master(id);


--
-- Name: transaction_detail transaction_detail_yarn_brand_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_yarn_brand_id_fkey FOREIGN KEY (yarn_brand_id) REFERENCES public.yarn_brand_master(id);


--
-- Name: transaction_detail transaction_detail_yarn_count_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_yarn_count_id_fkey FOREIGN KEY (yarn_count_id) REFERENCES public.yarn_count_master(id);


--
-- Name: transaction_detail transaction_detail_yarn_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_detail
    ADD CONSTRAINT transaction_detail_yarn_type_id_fkey FOREIGN KEY (yarn_type_id) REFERENCES public.yarn_type_master(id);


--
-- Name: transaction_header transaction_header_fabric_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_fabric_type_id_fkey FOREIGN KEY (fabric_type_id) REFERENCES public.fabric_type_master(id);


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
-- Name: transaction_header transaction_header_transaction_type_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_header
    ADD CONSTRAINT transaction_header_transaction_type_id_fk FOREIGN KEY (transaction_type_id) REFERENCES public.transaction_type_master(id);


--
-- PostgreSQL database dump complete
--

\unrestrict nSWTMstfXjdcn7qBixPSFreQ0kQkb1MzsqW30wA3HbTKZkKlykhkjkwNxxGigSc

