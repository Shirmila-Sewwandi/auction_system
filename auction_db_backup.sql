--
-- PostgreSQL database dump
--

\restrict EGxCH9bU2dEi4mugWX7L0FVAf7eE4OwRVqvbubXmB4REuh3lpCkrZeBfEhuCMg0

-- Dumped from database version 16.15
-- Dumped by pg_dump version 16.15

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


--
-- Name: auction_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auction_results (
    result_id bigint NOT NULL,
    listing_id bigint NOT NULL,
    winner_id bigint,
    winning_bid_id bigint,
    final_price numeric(12,2),
    reserve_met boolean NOT NULL,
    result_status character varying(30) NOT NULL,
    closed_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: auction_results_result_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auction_results_result_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auction_results_result_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auction_results_result_id_seq OWNED BY public.auction_results.result_id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    log_id bigint NOT NULL,
    user_id bigint,
    action character varying(100) NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id bigint NOT NULL,
    old_value text,
    new_value text,
    description text,
    ip_address character varying(45),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: audit_logs_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_log_id_seq OWNED BY public.audit_logs.log_id;


--
-- Name: bids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bids (
    bid_id bigint NOT NULL,
    listing_id bigint NOT NULL,
    bidder_id bigint NOT NULL,
    amount numeric(12,2) NOT NULL,
    status character varying(20) NOT NULL,
    placed_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: bids_bid_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bids_bid_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bids_bid_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bids_bid_id_seq OWNED BY public.bids.bid_id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    category_id integer NOT NULL,
    name character varying(100) NOT NULL,
    description character varying(255),
    is_active boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categories_category_id_seq OWNED BY public.categories.category_id;


--
-- Name: disputes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disputes (
    dispute_id bigint NOT NULL,
    auction_result_id bigint NOT NULL,
    raised_by bigint NOT NULL,
    assigned_moderator_id bigint,
    dispute_type character varying(50) NOT NULL,
    reason character varying(255) NOT NULL,
    description text,
    status character varying(30) NOT NULL,
    resolution text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone
);


--
-- Name: disputes_dispute_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.disputes_dispute_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: disputes_dispute_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.disputes_dispute_id_seq OWNED BY public.disputes.dispute_id;


--
-- Name: listing_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.listing_images (
    image_id bigint NOT NULL,
    listing_id bigint NOT NULL,
    image_path character varying(500) NOT NULL,
    display_order integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: listing_images_image_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.listing_images_image_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: listing_images_image_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.listing_images_image_id_seq OWNED BY public.listing_images.image_id;


--
-- Name: listings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.listings (
    listing_id bigint NOT NULL,
    seller_id bigint NOT NULL,
    category_id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    condition character varying(100),
    provenance text,
    starting_price numeric(12,2) NOT NULL,
    reserve_price numeric(12,2),
    current_price numeric(12,2) NOT NULL,
    min_bid_increment numeric(12,2) NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    original_end_time timestamp with time zone NOT NULL,
    status character varying(30) NOT NULL,
    moderation_status character varying(30) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    anti_sniping_extensions integer NOT NULL,
    anti_sniping_window_minutes integer NOT NULL,
    anti_sniping_extension_minutes integer NOT NULL,
    max_anti_sniping_extensions integer
);


--
-- Name: listings_listing_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.listings_listing_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: listings_listing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.listings_listing_id_seq OWNED BY public.listings.listing_id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    notification_id bigint NOT NULL,
    user_id bigint NOT NULL,
    type character varying(50) NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    is_read boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    read_at timestamp with time zone
);


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_notification_id_seq OWNED BY public.notifications.notification_id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    payment_id bigint NOT NULL,
    auction_result_id bigint NOT NULL,
    payer_id bigint NOT NULL,
    payee_id bigint NOT NULL,
    amount numeric(12,2) NOT NULL,
    payment_status character varying(20) NOT NULL,
    escrow_status character varying(20) NOT NULL,
    paid_at timestamp with time zone,
    released_at timestamp with time zone,
    refunded_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: payments_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payments_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payments_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payments_payment_id_seq OWNED BY public.payments.payment_id;


--
-- Name: platform_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_config (
    config_id integer NOT NULL,
    min_bid_increment numeric(12,2) NOT NULL,
    anti_sniping_window_minutes integer NOT NULL,
    anti_sniping_extension_minutes integer NOT NULL,
    max_anti_sniping_extensions integer,
    platform_fee_percent numeric(5,2) NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by bigint
);


--
-- Name: platform_config_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.platform_config_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: platform_config_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.platform_config_config_id_seq OWNED BY public.platform_config.config_id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    role_id integer NOT NULL,
    role_name character varying(50) NOT NULL,
    description character varying(255)
);


--
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_role_id_seq OWNED BY public.roles.role_id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    user_id bigint NOT NULL,
    role_id integer NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    user_id bigint NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    phone character varying(20),
    is_verified boolean NOT NULL,
    status character varying(20) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: auction_results result_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_results ALTER COLUMN result_id SET DEFAULT nextval('public.auction_results_result_id_seq'::regclass);


--
-- Name: audit_logs log_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN log_id SET DEFAULT nextval('public.audit_logs_log_id_seq'::regclass);


--
-- Name: bids bid_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bids ALTER COLUMN bid_id SET DEFAULT nextval('public.bids_bid_id_seq'::regclass);


--
-- Name: categories category_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories ALTER COLUMN category_id SET DEFAULT nextval('public.categories_category_id_seq'::regclass);


--
-- Name: disputes dispute_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputes ALTER COLUMN dispute_id SET DEFAULT nextval('public.disputes_dispute_id_seq'::regclass);


--
-- Name: listing_images image_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listing_images ALTER COLUMN image_id SET DEFAULT nextval('public.listing_images_image_id_seq'::regclass);


--
-- Name: listings listing_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listings ALTER COLUMN listing_id SET DEFAULT nextval('public.listings_listing_id_seq'::regclass);


--
-- Name: notifications notification_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN notification_id SET DEFAULT nextval('public.notifications_notification_id_seq'::regclass);


--
-- Name: payments payment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments ALTER COLUMN payment_id SET DEFAULT nextval('public.payments_payment_id_seq'::regclass);


--
-- Name: platform_config config_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_config ALTER COLUMN config_id SET DEFAULT nextval('public.platform_config_config_id_seq'::regclass);


--
-- Name: roles role_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN role_id SET DEFAULT nextval('public.roles_role_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.alembic_version (version_num) FROM stdin;
46799e5ebe5b
\.


--
-- Data for Name: auction_results; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auction_results (result_id, listing_id, winner_id, winning_bid_id, final_price, reserve_met, result_status, closed_at) FROM stdin;
1	11	\N	\N	\N	f	No Bids	2026-10-01 07:15:05.754997+00
2	12	\N	\N	\N	f	Reserve Not Met	2026-10-01 07:15:05.810167+00
3	13	\N	\N	\N	f	Reserve Not Met	2026-10-01 07:15:05.864812+00
4	14	7	10	350.00	t	Sold	2026-10-01 07:15:05.921296+00
5	15	8	11	150.00	t	Sold	2026-10-01 07:15:05.992271+00
6	16	9	12	700.00	t	Sold	2026-10-01 07:15:06.057466+00
7	17	10	13	800.00	t	Sold	2026-10-01 07:15:06.13813+00
8	18	7	14	120.00	t	Sold	2026-10-01 07:15:06.217234+00
9	19	8	15	250.00	t	Sold	2026-10-01 07:15:06.29226+00
10	20	9	16	450.00	t	Sold	2026-10-01 07:15:06.38921+00
11	21	10	17	300.00	t	Sold	2026-10-01 07:15:06.479258+00
12	22	7	18	600.00	t	Sold	2026-10-01 07:15:06.570733+00
13	23	8	19	350.00	t	Sold	2026-10-01 07:15:06.664284+00
14	24	9	20	400.00	t	Sold	2026-10-01 07:15:06.755283+00
15	25	10	21	950.00	t	Sold	2026-10-01 07:15:06.849371+00
16	10	10	22	210.00	t	Sold	2026-10-01 07:29:04.959516+00
17	5	\N	\N	\N	f	No Bids	2026-10-01 08:15:06.596689+00
18	6	\N	\N	\N	f	No Bids	2026-10-01 08:15:07.011415+00
19	7	8	2	85.00	t	Sold	2026-10-01 08:15:07.028496+00
20	8	9	4	625.00	t	Sold	2026-10-01 08:15:07.048116+00
21	9	10	6	1250.00	t	Sold	2026-10-01 08:15:07.065336+00
22	38	\N	\N	\N	f	No Bids	2026-10-22 12:25:05.7229+00
23	39	\N	\N	\N	f	Reserve Not Met	2026-10-22 12:25:05.77565+00
24	40	\N	\N	\N	f	Reserve Not Met	2026-10-22 12:25:05.826052+00
25	41	7	32	350.00	t	Sold	2026-10-22 12:25:05.872819+00
26	42	8	33	150.00	t	Sold	2026-10-22 12:25:05.938018+00
27	43	9	34	700.00	t	Sold	2026-10-22 12:25:05.997629+00
28	44	10	35	800.00	t	Sold	2026-10-22 12:25:06.070717+00
29	45	7	36	120.00	t	Sold	2026-10-22 12:25:06.144298+00
30	46	8	37	250.00	t	Sold	2026-10-22 12:25:06.226794+00
31	47	9	38	450.00	t	Sold	2026-10-22 12:25:06.364319+00
32	48	10	39	300.00	t	Sold	2026-10-22 12:25:06.444332+00
33	49	7	40	600.00	t	Sold	2026-10-22 12:25:06.523731+00
34	50	8	41	350.00	t	Sold	2026-10-22 12:25:06.606714+00
35	51	9	42	400.00	t	Sold	2026-10-22 12:25:06.688968+00
36	52	10	43	950.00	t	Sold	2026-10-22 12:25:06.774361+00
37	26	\N	\N	\N	f	No Bids	2026-10-22 12:25:31.31321+00
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_logs (log_id, user_id, action, entity_type, entity_id, old_value, new_value, description, ip_address, created_at) FROM stdin;
1	2	LISTING_REJECTED	Listing	3	{"moderation_status": "Pending Review"}	{"moderation_status": "Rejected", "reason": "Unable to verify authenticity"}	Unable to verify authenticity	\N	2026-10-01 07:15:05.428415+00
2	3	LISTING_SUSPENDED	Listing	4	{"moderation_status": "Pending Review"}	{"moderation_status": "Suspended", "reason": "Requires additional compliance review"}	Requires additional compliance review	\N	2026-10-01 07:15:05.455+00
3	2	LISTING_APPROVED	Listing	5	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:05.476546+00
4	2	LISTING_APPROVED	Listing	6	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:05.501287+00
5	2	LISTING_APPROVED	Listing	7	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:05.525039+00
6	7	BID_PLACED	Bid	1	\N	{"listing_id": 7, "amount": "80.00"}	\N	\N	2026-10-01 07:15:05.540058+00
7	8	BID_PLACED	Bid	2	\N	{"listing_id": 7, "amount": "85.00"}	\N	\N	2026-10-01 07:15:05.571521+00
8	3	LISTING_APPROVED	Listing	8	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:05.596082+00
9	7	BID_PLACED	Bid	3	\N	{"listing_id": 8, "amount": "600.00"}	\N	\N	2026-10-01 07:15:05.606478+00
10	9	BID_PLACED	Bid	4	\N	{"listing_id": 8, "amount": "625.00"}	\N	\N	2026-10-01 07:15:05.625955+00
11	2	LISTING_APPROVED	Listing	9	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:05.650682+00
12	8	BID_PLACED	Bid	5	\N	{"listing_id": 9, "amount": "1200.00"}	\N	\N	2026-10-01 07:15:05.660992+00
13	10	BID_PLACED	Bid	6	\N	{"listing_id": 9, "amount": "1250.00"}	\N	\N	2026-10-01 07:15:05.67518+00
14	2	LISTING_APPROVED	Listing	10	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:05.701248+00
15	7	BID_PLACED	Bid	7	\N	{"listing_id": 10, "amount": "200.00"}	\N	\N	2026-10-01 07:15:05.711166+00
16	2	LISTING_APPROVED	Listing	11	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:05.73601+00
17	\N	AUCTION_CLOSED	Listing	11	\N	{"result_status": "No Bids", "final_price": null}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:05.754997+00
18	3	LISTING_APPROVED	Listing	12	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:05.779829+00
19	8	BID_PLACED	Bid	8	\N	{"listing_id": 12, "amount": "50.00"}	\N	\N	2026-10-01 07:15:05.78989+00
20	\N	AUCTION_CLOSED	Listing	12	\N	{"result_status": "Reserve Not Met", "final_price": null}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:05.810167+00
21	2	LISTING_APPROVED	Listing	13	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:05.832961+00
22	9	BID_PLACED	Bid	9	\N	{"listing_id": 13, "amount": "300.00"}	\N	\N	2026-10-01 07:15:05.843554+00
23	\N	AUCTION_CLOSED	Listing	13	\N	{"result_status": "Reserve Not Met", "final_price": null}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:05.864812+00
24	2	LISTING_APPROVED	Listing	14	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:05.88771+00
25	7	BID_PLACED	Bid	10	\N	{"listing_id": 14, "amount": "350.00"}	\N	\N	2026-10-01 07:15:05.898115+00
26	\N	AUCTION_CLOSED	Listing	14	\N	{"result_status": "Sold", "final_price": "350.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:05.921296+00
27	7	PAYMENT_MADE	Payment	1	\N	{"amount": "350.00"}	\N	\N	2026-10-01 07:15:05.934392+00
28	3	LISTING_APPROVED	Listing	15	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:05.959222+00
29	8	BID_PLACED	Bid	11	\N	{"listing_id": 15, "amount": "150.00"}	\N	\N	2026-10-01 07:15:05.970369+00
30	\N	AUCTION_CLOSED	Listing	15	\N	{"result_status": "Sold", "final_price": "150.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:05.992271+00
31	8	PAYMENT_MADE	Payment	2	\N	{"amount": "150.00"}	\N	\N	2026-10-01 07:15:06.004242+00
32	2	LISTING_APPROVED	Listing	16	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:06.025569+00
33	9	BID_PLACED	Bid	12	\N	{"listing_id": 16, "amount": "700.00"}	\N	\N	2026-10-01 07:15:06.035665+00
34	\N	AUCTION_CLOSED	Listing	16	\N	{"result_status": "Sold", "final_price": "700.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:06.057466+00
35	9	PAYMENT_MADE	Payment	3	\N	{"amount": "700.00"}	\N	\N	2026-10-01 07:15:06.071792+00
36	9	DISPUTE_RAISED	Dispute	1	\N	{"dispute_type": "item_not_as_described", "reason": "Canvas has undisclosed restoration"}	\N	\N	2026-10-01 07:15:06.083372+00
37	2	LISTING_APPROVED	Listing	17	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:06.106155+00
38	10	BID_PLACED	Bid	13	\N	{"listing_id": 17, "amount": "800.00"}	\N	\N	2026-10-01 07:15:06.118035+00
39	\N	AUCTION_CLOSED	Listing	17	\N	{"result_status": "Sold", "final_price": "800.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:06.13813+00
40	10	PAYMENT_MADE	Payment	4	\N	{"amount": "800.00"}	\N	\N	2026-10-01 07:15:06.150611+00
41	10	DISPUTE_RAISED	Dispute	2	\N	{"dispute_type": "item_not_received", "reason": "Item has not arrived"}	\N	\N	2026-10-01 07:15:06.163082+00
42	3	LISTING_APPROVED	Listing	18	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:06.183507+00
43	7	BID_PLACED	Bid	14	\N	{"listing_id": 18, "amount": "120.00"}	\N	\N	2026-10-01 07:15:06.195522+00
44	\N	AUCTION_CLOSED	Listing	18	\N	{"result_status": "Sold", "final_price": "120.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:06.217234+00
45	7	PAYMENT_MADE	Payment	5	\N	{"amount": "120.00"}	\N	\N	2026-10-01 07:15:06.229725+00
46	7	DISPUTE_RAISED	Dispute	3	\N	{"dispute_type": "other", "reason": "Plate arrived with a hairline crack"}	\N	\N	2026-10-01 07:15:06.243183+00
47	2	LISTING_APPROVED	Listing	19	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:06.262103+00
48	8	BID_PLACED	Bid	15	\N	{"listing_id": 19, "amount": "250.00"}	\N	\N	2026-10-01 07:15:06.27204+00
49	\N	AUCTION_CLOSED	Listing	19	\N	{"result_status": "Sold", "final_price": "250.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:06.29226+00
50	8	PAYMENT_MADE	Payment	6	\N	{"amount": "250.00"}	\N	\N	2026-10-01 07:15:06.304989+00
51	8	DISPUTE_RAISED	Dispute	4	\N	{"dispute_type": "item_not_as_described", "reason": "Coin weight does not match listing"}	\N	\N	2026-10-01 07:15:06.321269+00
52	2	DISPUTE_UNDER_REVIEW	Dispute	4	\N	{"status": "Under Review", "resolution": "Requesting seller provide a certificate of authenticity"}	Requesting seller provide a certificate of authenticity	\N	2026-10-01 07:15:06.333666+00
53	3	LISTING_APPROVED	Listing	20	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:06.357784+00
54	9	BID_PLACED	Bid	16	\N	{"listing_id": 20, "amount": "450.00"}	\N	\N	2026-10-01 07:15:06.367773+00
55	\N	AUCTION_CLOSED	Listing	20	\N	{"result_status": "Sold", "final_price": "450.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:06.38921+00
56	9	PAYMENT_MADE	Payment	7	\N	{"amount": "450.00"}	\N	\N	2026-10-01 07:15:06.403812+00
57	9	DISPUTE_RAISED	Dispute	5	\N	{"dispute_type": "item_not_as_described", "reason": "Colors differ noticeably from photos"}	\N	\N	2026-10-01 07:15:06.415344+00
58	3	DISPUTE_UNDER_REVIEW	Dispute	5	\N	{"status": "Under Review", "resolution": "Awaiting additional photos from buyer"}	Awaiting additional photos from buyer	\N	2026-10-01 07:15:06.425967+00
59	2	LISTING_APPROVED	Listing	21	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:06.447658+00
60	10	BID_PLACED	Bid	17	\N	{"listing_id": 21, "amount": "300.00"}	\N	\N	2026-10-01 07:15:06.458327+00
61	\N	AUCTION_CLOSED	Listing	21	\N	{"result_status": "Sold", "final_price": "300.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:06.479258+00
62	10	PAYMENT_MADE	Payment	8	\N	{"amount": "300.00"}	\N	\N	2026-10-01 07:15:06.492422+00
63	10	DISPUTE_RAISED	Dispute	6	\N	{"dispute_type": "item_not_received", "reason": "Tracking shows no movement in 10 days"}	\N	\N	2026-10-01 07:15:06.504053+00
64	2	DISPUTE_UNDER_REVIEW	Dispute	6	\N	{"status": "Under Review", "resolution": "Contacting shipping carrier for an update"}	Contacting shipping carrier for an update	\N	2026-10-01 07:15:06.515534+00
65	2	LISTING_APPROVED	Listing	22	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:06.538705+00
66	7	BID_PLACED	Bid	18	\N	{"listing_id": 22, "amount": "600.00"}	\N	\N	2026-10-01 07:15:06.5491+00
67	\N	AUCTION_CLOSED	Listing	22	\N	{"result_status": "Sold", "final_price": "600.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:06.570733+00
68	7	PAYMENT_MADE	Payment	9	\N	{"amount": "600.00"}	\N	\N	2026-10-01 07:15:06.582547+00
69	7	DISPUTE_RAISED	Dispute	7	\N	{"dispute_type": "item_not_as_described", "reason": "Facsimile, not an original as implied"}	\N	\N	2026-10-01 07:15:06.593839+00
70	2	ESCROW_REFUNDED	Payment	9	\N	\N	\N	\N	2026-10-01 07:15:06.606923+00
71	2	DISPUTE_RESOLVED	Dispute	7	\N	{"status": "Resolved", "resolution": "Listing was misleading \\u2014 buyer refunded in full"}	Listing was misleading — buyer refunded in full	\N	2026-10-01 07:15:06.606923+00
72	3	LISTING_APPROVED	Listing	23	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:06.632886+00
73	8	BID_PLACED	Bid	19	\N	{"listing_id": 23, "amount": "350.00"}	\N	\N	2026-10-01 07:15:06.644402+00
74	\N	AUCTION_CLOSED	Listing	23	\N	{"result_status": "Sold", "final_price": "350.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:06.664284+00
75	8	PAYMENT_MADE	Payment	10	\N	{"amount": "350.00"}	\N	\N	2026-10-01 07:15:06.675591+00
76	8	DISPUTE_RAISED	Dispute	8	\N	{"dispute_type": "item_not_received", "reason": "Item never arrived after 3 weeks"}	\N	\N	2026-10-01 07:15:06.686784+00
77	3	ESCROW_REFUNDED	Payment	10	\N	\N	\N	\N	2026-10-01 07:15:06.69717+00
78	3	DISPUTE_RESOLVED	Dispute	8	\N	{"status": "Resolved", "resolution": "Seller could not provide proof of postage \\u2014 buyer refunded"}	Seller could not provide proof of postage — buyer refunded	\N	2026-10-01 07:15:06.69717+00
79	2	LISTING_APPROVED	Listing	24	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:06.722616+00
80	9	BID_PLACED	Bid	20	\N	{"listing_id": 24, "amount": "400.00"}	\N	\N	2026-10-01 07:15:06.732918+00
81	\N	AUCTION_CLOSED	Listing	24	\N	{"result_status": "Sold", "final_price": "400.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:06.755283+00
82	9	PAYMENT_MADE	Payment	11	\N	{"amount": "400.00"}	\N	\N	2026-10-01 07:15:06.767403+00
83	9	DISPUTE_RAISED	Dispute	9	\N	{"dispute_type": "other", "reason": "Buyer changed their mind after purchase"}	\N	\N	2026-10-01 07:15:06.779035+00
84	2	ESCROW_RELEASED	Payment	11	\N	\N	\N	\N	2026-10-01 07:15:06.789282+00
85	2	DISPUTE_RESOLVED	Dispute	9	\N	{"status": "Resolved", "resolution": "Item matched listing exactly \\u2014 funds released to seller"}	Item matched listing exactly — funds released to seller	\N	2026-10-01 07:15:06.789282+00
86	3	LISTING_APPROVED	Listing	25	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:15:06.813777+00
87	10	BID_PLACED	Bid	21	\N	{"listing_id": 25, "amount": "950.00"}	\N	\N	2026-10-01 07:15:06.824567+00
88	\N	AUCTION_CLOSED	Listing	25	\N	{"result_status": "Sold", "final_price": "950.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:15:06.849371+00
89	10	PAYMENT_MADE	Payment	12	\N	{"amount": "950.00"}	\N	\N	2026-10-01 07:15:06.875575+00
90	10	DISPUTE_RAISED	Dispute	10	\N	{"dispute_type": "item_not_as_described", "reason": "Stone size seemed smaller than described"}	\N	\N	2026-10-01 07:15:06.894528+00
91	3	ESCROW_RELEASED	Payment	12	\N	\N	\N	\N	2026-10-01 07:15:06.909301+00
92	3	DISPUTE_RESOLVED	Dispute	10	\N	{"status": "Resolved", "resolution": "Measurements independently verified as accurate \\u2014 funds released"}	Measurements independently verified as accurate — funds released	\N	2026-10-01 07:15:06.909301+00
93	10	BID_PLACED	Bid	22	\N	{"listing_id": 10, "amount": "210"}	\N	\N	2026-10-01 07:23:09.867935+00
94	10	LISTING_CREATED	Listing	26	\N	{"title": "Golder Brooch", "starting_price": "5000"}	\N	\N	2026-10-01 07:26:04.447561+00
95	10	LISTING_CREATED	Listing	27	\N	{"title": "Golder Brooch", "starting_price": "5000"}	\N	\N	2026-10-01 07:26:14.85583+00
96	2	LISTING_REJECTED	Listing	27	{"moderation_status": "Pending Review"}	{"moderation_status": "Rejected", "reason": "duplicate"}	duplicate	\N	2026-10-01 07:27:06.718166+00
97	2	LISTING_APPROVED	Listing	26	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-01 07:27:08.715756+00
98	\N	AUCTION_CLOSED	Listing	10	\N	{"result_status": "Sold", "final_price": "210.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 07:29:04.959516+00
99	\N	AUCTION_CLOSED	Listing	5	\N	{"result_status": "No Bids", "final_price": null}	Closed automatically by the background auction-closer job	\N	2026-10-01 08:15:06.596689+00
100	\N	AUCTION_CLOSED	Listing	6	\N	{"result_status": "No Bids", "final_price": null}	Closed automatically by the background auction-closer job	\N	2026-10-01 08:15:07.011415+00
101	\N	AUCTION_CLOSED	Listing	7	\N	{"result_status": "Sold", "final_price": "85.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 08:15:07.028496+00
102	\N	AUCTION_CLOSED	Listing	8	\N	{"result_status": "Sold", "final_price": "625.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 08:15:07.048116+00
103	\N	AUCTION_CLOSED	Listing	9	\N	{"result_status": "Sold", "final_price": "1250.00"}	Closed automatically by the background auction-closer job	\N	2026-10-01 08:15:07.065336+00
104	2	LISTING_REJECTED	Listing	30	{"moderation_status": "Pending Review"}	{"moderation_status": "Rejected", "reason": "Unable to verify authenticity"}	Unable to verify authenticity	\N	2026-10-22 12:25:05.427211+00
105	3	LISTING_SUSPENDED	Listing	31	{"moderation_status": "Pending Review"}	{"moderation_status": "Suspended", "reason": "Requires additional compliance review"}	Requires additional compliance review	\N	2026-10-22 12:25:05.46174+00
106	2	LISTING_APPROVED	Listing	32	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:05.484986+00
107	2	LISTING_APPROVED	Listing	33	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:05.503917+00
108	2	LISTING_APPROVED	Listing	34	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:05.521703+00
109	7	BID_PLACED	Bid	23	\N	{"listing_id": 34, "amount": "80.00"}	\N	\N	2026-10-22 12:25:05.531173+00
110	8	BID_PLACED	Bid	24	\N	{"listing_id": 34, "amount": "85.00"}	\N	\N	2026-10-22 12:25:05.557249+00
111	3	LISTING_APPROVED	Listing	35	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:05.581261+00
112	7	BID_PLACED	Bid	25	\N	{"listing_id": 35, "amount": "600.00"}	\N	\N	2026-10-22 12:25:05.590874+00
113	9	BID_PLACED	Bid	26	\N	{"listing_id": 35, "amount": "625.00"}	\N	\N	2026-10-22 12:25:05.602886+00
114	2	LISTING_APPROVED	Listing	36	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:05.62579+00
115	8	BID_PLACED	Bid	27	\N	{"listing_id": 36, "amount": "1200.00"}	\N	\N	2026-10-22 12:25:05.636571+00
116	10	BID_PLACED	Bid	28	\N	{"listing_id": 36, "amount": "1250.00"}	\N	\N	2026-10-22 12:25:05.650545+00
117	2	LISTING_APPROVED	Listing	37	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:05.675752+00
118	7	BID_PLACED	Bid	29	\N	{"listing_id": 37, "amount": "200.00"}	\N	\N	2026-10-22 12:25:05.685024+00
119	2	LISTING_APPROVED	Listing	38	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:05.707215+00
120	\N	AUCTION_CLOSED	Listing	38	\N	{"result_status": "No Bids", "final_price": null}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:05.7229+00
121	3	LISTING_APPROVED	Listing	39	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:05.747395+00
122	8	BID_PLACED	Bid	30	\N	{"listing_id": 39, "amount": "50.00"}	\N	\N	2026-10-22 12:25:05.757162+00
123	\N	AUCTION_CLOSED	Listing	39	\N	{"result_status": "Reserve Not Met", "final_price": null}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:05.77565+00
124	2	LISTING_APPROVED	Listing	40	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:05.79631+00
125	9	BID_PLACED	Bid	31	\N	{"listing_id": 40, "amount": "300.00"}	\N	\N	2026-10-22 12:25:05.807536+00
126	\N	AUCTION_CLOSED	Listing	40	\N	{"result_status": "Reserve Not Met", "final_price": null}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:05.826052+00
127	2	LISTING_APPROVED	Listing	41	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:05.845243+00
128	7	BID_PLACED	Bid	32	\N	{"listing_id": 41, "amount": "350.00"}	\N	\N	2026-10-22 12:25:05.854255+00
129	\N	AUCTION_CLOSED	Listing	41	\N	{"result_status": "Sold", "final_price": "350.00"}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:05.872819+00
130	7	PAYMENT_MADE	Payment	13	\N	{"amount": "350.00"}	\N	\N	2026-10-22 12:25:05.88459+00
131	3	LISTING_APPROVED	Listing	42	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:05.909187+00
132	8	BID_PLACED	Bid	33	\N	{"listing_id": 42, "amount": "150.00"}	\N	\N	2026-10-22 12:25:05.91819+00
133	\N	AUCTION_CLOSED	Listing	42	\N	{"result_status": "Sold", "final_price": "150.00"}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:05.938018+00
134	8	PAYMENT_MADE	Payment	14	\N	{"amount": "150.00"}	\N	\N	2026-10-22 12:25:05.949115+00
135	2	LISTING_APPROVED	Listing	43	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:05.968391+00
136	9	BID_PLACED	Bid	34	\N	{"listing_id": 43, "amount": "700.00"}	\N	\N	2026-10-22 12:25:05.978105+00
137	\N	AUCTION_CLOSED	Listing	43	\N	{"result_status": "Sold", "final_price": "700.00"}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:05.997629+00
138	9	PAYMENT_MADE	Payment	15	\N	{"amount": "700.00"}	\N	\N	2026-10-22 12:25:06.010305+00
139	9	DISPUTE_RAISED	Dispute	11	\N	{"dispute_type": "item_not_as_described", "reason": "Canvas has undisclosed restoration"}	\N	\N	2026-10-22 12:25:06.021126+00
140	2	LISTING_APPROVED	Listing	44	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:06.042672+00
141	10	BID_PLACED	Bid	35	\N	{"listing_id": 44, "amount": "800.00"}	\N	\N	2026-10-22 12:25:06.051825+00
142	\N	AUCTION_CLOSED	Listing	44	\N	{"result_status": "Sold", "final_price": "800.00"}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:06.070717+00
143	10	PAYMENT_MADE	Payment	16	\N	{"amount": "800.00"}	\N	\N	2026-10-22 12:25:06.082456+00
144	10	DISPUTE_RAISED	Dispute	12	\N	{"dispute_type": "item_not_received", "reason": "Item has not arrived"}	\N	\N	2026-10-22 12:25:06.093713+00
145	3	LISTING_APPROVED	Listing	45	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:06.111948+00
146	7	BID_PLACED	Bid	36	\N	{"listing_id": 45, "amount": "120.00"}	\N	\N	2026-10-22 12:25:06.123733+00
147	\N	AUCTION_CLOSED	Listing	45	\N	{"result_status": "Sold", "final_price": "120.00"}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:06.144298+00
148	7	PAYMENT_MADE	Payment	17	\N	{"amount": "120.00"}	\N	\N	2026-10-22 12:25:06.155293+00
149	7	DISPUTE_RAISED	Dispute	13	\N	{"dispute_type": "other", "reason": "Plate arrived with a hairline crack"}	\N	\N	2026-10-22 12:25:06.166563+00
150	2	LISTING_APPROVED	Listing	46	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:06.189479+00
151	8	BID_PLACED	Bid	37	\N	{"listing_id": 46, "amount": "250.00"}	\N	\N	2026-10-22 12:25:06.198596+00
152	\N	AUCTION_CLOSED	Listing	46	\N	{"result_status": "Sold", "final_price": "250.00"}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:06.226794+00
153	8	PAYMENT_MADE	Payment	18	\N	{"amount": "250.00"}	\N	\N	2026-10-22 12:25:06.251694+00
154	8	DISPUTE_RAISED	Dispute	14	\N	{"dispute_type": "item_not_as_described", "reason": "Coin weight does not match listing"}	\N	\N	2026-10-22 12:25:06.276778+00
155	2	DISPUTE_UNDER_REVIEW	Dispute	14	\N	{"status": "Under Review", "resolution": "Requesting seller provide a certificate of authenticity"}	Requesting seller provide a certificate of authenticity	\N	2026-10-22 12:25:06.296813+00
156	3	LISTING_APPROVED	Listing	47	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:06.33592+00
157	9	BID_PLACED	Bid	38	\N	{"listing_id": 47, "amount": "450.00"}	\N	\N	2026-10-22 12:25:06.345759+00
158	\N	AUCTION_CLOSED	Listing	47	\N	{"result_status": "Sold", "final_price": "450.00"}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:06.364319+00
159	9	PAYMENT_MADE	Payment	19	\N	{"amount": "450.00"}	\N	\N	2026-10-22 12:25:06.375748+00
160	9	DISPUTE_RAISED	Dispute	15	\N	{"dispute_type": "item_not_as_described", "reason": "Colors differ noticeably from photos"}	\N	\N	2026-10-22 12:25:06.386305+00
161	3	DISPUTE_UNDER_REVIEW	Dispute	15	\N	{"status": "Under Review", "resolution": "Awaiting additional photos from buyer"}	Awaiting additional photos from buyer	\N	2026-10-22 12:25:06.396481+00
162	2	LISTING_APPROVED	Listing	48	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:06.41715+00
163	10	BID_PLACED	Bid	39	\N	{"listing_id": 48, "amount": "300.00"}	\N	\N	2026-10-22 12:25:06.426149+00
164	\N	AUCTION_CLOSED	Listing	48	\N	{"result_status": "Sold", "final_price": "300.00"}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:06.444332+00
165	10	PAYMENT_MADE	Payment	20	\N	{"amount": "300.00"}	\N	\N	2026-10-22 12:25:06.455716+00
166	10	DISPUTE_RAISED	Dispute	16	\N	{"dispute_type": "item_not_received", "reason": "Tracking shows no movement in 10 days"}	\N	\N	2026-10-22 12:25:06.4659+00
167	2	DISPUTE_UNDER_REVIEW	Dispute	16	\N	{"status": "Under Review", "resolution": "Contacting shipping carrier for an update"}	Contacting shipping carrier for an update	\N	2026-10-22 12:25:06.475697+00
168	2	LISTING_APPROVED	Listing	49	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:06.496227+00
169	7	BID_PLACED	Bid	40	\N	{"listing_id": 49, "amount": "600.00"}	\N	\N	2026-10-22 12:25:06.506038+00
170	\N	AUCTION_CLOSED	Listing	49	\N	{"result_status": "Sold", "final_price": "600.00"}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:06.523731+00
171	7	PAYMENT_MADE	Payment	21	\N	{"amount": "600.00"}	\N	\N	2026-10-22 12:25:06.534316+00
172	7	DISPUTE_RAISED	Dispute	17	\N	{"dispute_type": "item_not_as_described", "reason": "Facsimile, not an original as implied"}	\N	\N	2026-10-22 12:25:06.544607+00
173	2	ESCROW_REFUNDED	Payment	21	\N	\N	\N	\N	2026-10-22 12:25:06.554031+00
174	2	DISPUTE_RESOLVED	Dispute	17	\N	{"status": "Resolved", "resolution": "Listing was misleading \\u2014 buyer refunded in full"}	Listing was misleading — buyer refunded in full	\N	2026-10-22 12:25:06.554031+00
175	3	LISTING_APPROVED	Listing	50	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:06.578766+00
176	8	BID_PLACED	Bid	41	\N	{"listing_id": 50, "amount": "350.00"}	\N	\N	2026-10-22 12:25:06.587699+00
177	\N	AUCTION_CLOSED	Listing	50	\N	{"result_status": "Sold", "final_price": "350.00"}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:06.606714+00
178	8	PAYMENT_MADE	Payment	22	\N	{"amount": "350.00"}	\N	\N	2026-10-22 12:25:06.618274+00
179	8	DISPUTE_RAISED	Dispute	18	\N	{"dispute_type": "item_not_received", "reason": "Item never arrived after 3 weeks"}	\N	\N	2026-10-22 12:25:06.628856+00
180	3	ESCROW_REFUNDED	Payment	22	\N	\N	\N	\N	2026-10-22 12:25:06.638504+00
181	3	DISPUTE_RESOLVED	Dispute	18	\N	{"status": "Resolved", "resolution": "Seller could not provide proof of postage \\u2014 buyer refunded"}	Seller could not provide proof of postage — buyer refunded	\N	2026-10-22 12:25:06.638504+00
182	2	LISTING_APPROVED	Listing	51	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:06.660848+00
183	9	BID_PLACED	Bid	42	\N	{"listing_id": 51, "amount": "400.00"}	\N	\N	2026-10-22 12:25:06.67028+00
184	\N	AUCTION_CLOSED	Listing	51	\N	{"result_status": "Sold", "final_price": "400.00"}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:06.688968+00
185	9	PAYMENT_MADE	Payment	23	\N	{"amount": "400.00"}	\N	\N	2026-10-22 12:25:06.700185+00
186	9	DISPUTE_RAISED	Dispute	19	\N	{"dispute_type": "other", "reason": "Buyer changed their mind after purchase"}	\N	\N	2026-10-22 12:25:06.710378+00
187	2	ESCROW_RELEASED	Payment	23	\N	\N	\N	\N	2026-10-22 12:25:06.719889+00
188	2	DISPUTE_RESOLVED	Dispute	19	\N	{"status": "Resolved", "resolution": "Item matched listing exactly \\u2014 funds released to seller"}	Item matched listing exactly — funds released to seller	\N	2026-10-22 12:25:06.719889+00
189	3	LISTING_APPROVED	Listing	52	{"moderation_status": "Pending Review"}	{"moderation_status": "Approved", "reason": null}	\N	\N	2026-10-22 12:25:06.744693+00
190	10	BID_PLACED	Bid	43	\N	{"listing_id": 52, "amount": "950.00"}	\N	\N	2026-10-22 12:25:06.755935+00
191	\N	AUCTION_CLOSED	Listing	52	\N	{"result_status": "Sold", "final_price": "950.00"}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:06.774361+00
192	10	PAYMENT_MADE	Payment	24	\N	{"amount": "950.00"}	\N	\N	2026-10-22 12:25:06.78505+00
193	10	DISPUTE_RAISED	Dispute	20	\N	{"dispute_type": "item_not_as_described", "reason": "Stone size seemed smaller than described"}	\N	\N	2026-10-22 12:25:06.796082+00
194	3	ESCROW_RELEASED	Payment	24	\N	\N	\N	\N	2026-10-22 12:25:06.805668+00
195	3	DISPUTE_RESOLVED	Dispute	20	\N	{"status": "Resolved", "resolution": "Measurements independently verified as accurate \\u2014 funds released"}	Measurements independently verified as accurate — funds released	\N	2026-10-22 12:25:06.805668+00
196	\N	AUCTION_CLOSED	Listing	26	\N	{"result_status": "No Bids", "final_price": null}	Closed automatically by the background auction-closer job	\N	2026-10-22 12:25:31.31321+00
198	7	BID_PLACED	Bid	44	\N	{"listing_id": 32, "amount": "250.12345"}	\N	\N	2026-10-22 12:27:38.127499+00
\.


--
-- Data for Name: bids; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bids (bid_id, listing_id, bidder_id, amount, status, placed_at) FROM stdin;
1	7	7	80.00	Accepted	2026-10-01 07:15:05.540058+00
2	7	8	85.00	Accepted	2026-10-01 07:15:05.571521+00
3	8	7	600.00	Accepted	2026-10-01 07:15:05.606478+00
4	8	9	625.00	Accepted	2026-10-01 07:15:05.625955+00
5	9	8	1200.00	Accepted	2026-10-01 07:15:05.660992+00
6	9	10	1250.00	Accepted	2026-10-01 07:15:05.67518+00
7	10	7	200.00	Accepted	2026-10-01 07:15:05.711166+00
8	12	8	50.00	Accepted	2026-10-01 07:15:05.78989+00
9	13	9	300.00	Accepted	2026-10-01 07:15:05.843554+00
10	14	7	350.00	Accepted	2026-10-01 07:15:05.898115+00
11	15	8	150.00	Accepted	2026-10-01 07:15:05.970369+00
12	16	9	700.00	Accepted	2026-10-01 07:15:06.035665+00
13	17	10	800.00	Accepted	2026-10-01 07:15:06.118035+00
14	18	7	120.00	Accepted	2026-10-01 07:15:06.195522+00
15	19	8	250.00	Accepted	2026-10-01 07:15:06.27204+00
16	20	9	450.00	Accepted	2026-10-01 07:15:06.367773+00
17	21	10	300.00	Accepted	2026-10-01 07:15:06.458327+00
18	22	7	600.00	Accepted	2026-10-01 07:15:06.5491+00
19	23	8	350.00	Accepted	2026-10-01 07:15:06.644402+00
20	24	9	400.00	Accepted	2026-10-01 07:15:06.732918+00
21	25	10	950.00	Accepted	2026-10-01 07:15:06.824567+00
22	10	10	210.00	Accepted	2026-10-01 07:23:09.867935+00
23	34	7	80.00	Accepted	2026-10-22 12:25:05.531173+00
24	34	8	85.00	Accepted	2026-10-22 12:25:05.557249+00
25	35	7	600.00	Accepted	2026-10-22 12:25:05.590874+00
26	35	9	625.00	Accepted	2026-10-22 12:25:05.602886+00
27	36	8	1200.00	Accepted	2026-10-22 12:25:05.636571+00
28	36	10	1250.00	Accepted	2026-10-22 12:25:05.650545+00
29	37	7	200.00	Accepted	2026-10-22 12:25:05.685024+00
30	39	8	50.00	Accepted	2026-10-22 12:25:05.757162+00
31	40	9	300.00	Accepted	2026-10-22 12:25:05.807536+00
32	41	7	350.00	Accepted	2026-10-22 12:25:05.854255+00
33	42	8	150.00	Accepted	2026-10-22 12:25:05.91819+00
34	43	9	700.00	Accepted	2026-10-22 12:25:05.978105+00
35	44	10	800.00	Accepted	2026-10-22 12:25:06.051825+00
36	45	7	120.00	Accepted	2026-10-22 12:25:06.123733+00
37	46	8	250.00	Accepted	2026-10-22 12:25:06.198596+00
38	47	9	450.00	Accepted	2026-10-22 12:25:06.345759+00
39	48	10	300.00	Accepted	2026-10-22 12:25:06.426149+00
40	49	7	600.00	Accepted	2026-10-22 12:25:06.506038+00
41	50	8	350.00	Accepted	2026-10-22 12:25:06.587699+00
42	51	9	400.00	Accepted	2026-10-22 12:25:06.67028+00
43	52	10	950.00	Accepted	2026-10-22 12:25:06.755935+00
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categories (category_id, name, description, is_active, created_at) FROM stdin;
1	Furniture	Furniture items	t	2026-10-01 07:15:05.224137+00
2	Jewelry	Jewelry items	t	2026-10-01 07:15:05.224137+00
3	Art	Art items	t	2026-10-01 07:15:05.224137+00
4	Coins & Currency	Coins & Currency items	t	2026-10-01 07:15:05.224137+00
5	Books & Manuscripts	Books & Manuscripts items	t	2026-10-01 07:15:05.224137+00
6	Ceramics & Glass	Ceramics & Glass items	t	2026-10-01 07:15:05.224137+00
7	Textiles & Rugs	Textiles & Rugs items	t	2026-10-01 07:15:05.224137+00
8	Clocks & Watches	Clocks & Watches items	t	2026-10-01 07:15:05.224137+00
9	Militaria	Militaria items	t	2026-10-01 07:15:05.224137+00
10	Musical Instruments	Musical Instruments items	t	2026-10-01 07:15:05.224137+00
\.


--
-- Data for Name: disputes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.disputes (dispute_id, auction_result_id, raised_by, assigned_moderator_id, dispute_type, reason, description, status, resolution, created_at, resolved_at) FROM stdin;
1	6	9	\N	item_not_as_described	Canvas has undisclosed restoration	\N	Open	\N	2026-10-01 07:15:06.083372+00	\N
2	7	10	\N	item_not_received	Item has not arrived	\N	Open	\N	2026-10-01 07:15:06.163082+00	\N
3	8	7	\N	other	Plate arrived with a hairline crack	\N	Open	\N	2026-10-01 07:15:06.243183+00	\N
4	9	8	2	item_not_as_described	Coin weight does not match listing	\N	Under Review	Requesting seller provide a certificate of authenticity	2026-10-01 07:15:06.321269+00	\N
5	10	9	3	item_not_as_described	Colors differ noticeably from photos	\N	Under Review	Awaiting additional photos from buyer	2026-10-01 07:15:06.415344+00	\N
6	11	10	2	item_not_received	Tracking shows no movement in 10 days	\N	Under Review	Contacting shipping carrier for an update	2026-10-01 07:15:06.504053+00	\N
7	12	7	2	item_not_as_described	Facsimile, not an original as implied	\N	Resolved	Listing was misleading — buyer refunded in full	2026-10-01 07:15:06.593839+00	2026-10-01 07:15:06.269987+00
8	13	8	3	item_not_received	Item never arrived after 3 weeks	\N	Resolved	Seller could not provide proof of postage — buyer refunded	2026-10-01 07:15:06.686784+00	2026-10-01 07:15:06.351949+00
9	14	9	2	other	Buyer changed their mind after purchase	\N	Resolved	Item matched listing exactly — funds released to seller	2026-10-01 07:15:06.779035+00	2026-10-01 07:15:06.436341+00
10	15	10	3	item_not_as_described	Stone size seemed smaller than described	\N	Resolved	Measurements independently verified as accurate — funds released	2026-10-01 07:15:06.894528+00	2026-10-01 07:15:06.544689+00
11	27	9	\N	item_not_as_described	Canvas has undisclosed restoration	\N	Open	\N	2026-10-22 12:25:06.021126+00	\N
12	28	10	\N	item_not_received	Item has not arrived	\N	Open	\N	2026-10-22 12:25:06.093713+00	\N
13	29	7	\N	other	Plate arrived with a hairline crack	\N	Open	\N	2026-10-22 12:25:06.166563+00	\N
14	30	8	2	item_not_as_described	Coin weight does not match listing	\N	Under Review	Requesting seller provide a certificate of authenticity	2026-10-22 12:25:06.276778+00	\N
15	31	9	3	item_not_as_described	Colors differ noticeably from photos	\N	Under Review	Awaiting additional photos from buyer	2026-10-22 12:25:06.386305+00	\N
16	32	10	2	item_not_received	Tracking shows no movement in 10 days	\N	Under Review	Contacting shipping carrier for an update	2026-10-22 12:25:06.4659+00	\N
17	33	7	2	item_not_as_described	Facsimile, not an original as implied	\N	Resolved	Listing was misleading — buyer refunded in full	2026-10-22 12:25:06.544607+00	2026-10-22 12:25:06.611842+00
18	34	8	3	item_not_received	Item never arrived after 3 weeks	\N	Resolved	Seller could not provide proof of postage — buyer refunded	2026-10-22 12:25:06.628856+00	2026-10-22 12:25:06.696349+00
19	35	9	2	other	Buyer changed their mind after purchase	\N	Resolved	Item matched listing exactly — funds released to seller	2026-10-22 12:25:06.710378+00	2026-10-22 12:25:06.778325+00
20	36	10	3	item_not_as_described	Stone size seemed smaller than described	\N	Resolved	Measurements independently verified as accurate — funds released	2026-10-22 12:25:06.796082+00	2026-10-22 12:25:06.863476+00
\.


--
-- Data for Name: listing_images; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.listing_images (image_id, listing_id, image_path, display_order, created_at) FROM stdin;
1	1	uploads/demo/sage.png	0	2026-10-01 07:15:05.385651+00
2	2	uploads/demo/slate.png	0	2026-10-01 07:15:05.408394+00
3	3	uploads/demo/terracotta.png	0	2026-10-01 07:15:05.41797+00
4	4	uploads/demo/plum.png	0	2026-10-01 07:15:05.445659+00
5	5	uploads/demo/amber.png	0	2026-10-01 07:15:05.4669+00
6	6	uploads/demo/sage.png	0	2026-10-01 07:15:05.486982+00
7	7	uploads/demo/slate.png	0	2026-10-01 07:15:05.514641+00
8	8	uploads/demo/terracotta.png	0	2026-10-01 07:15:05.588137+00
9	9	uploads/demo/plum.png	0	2026-10-01 07:15:05.641618+00
10	10	uploads/demo/amber.png	0	2026-10-01 07:15:05.691971+00
11	11	uploads/demo/sage.png	0	2026-10-01 07:15:05.726321+00
12	12	uploads/demo/slate.png	0	2026-10-01 07:15:05.770864+00
13	13	uploads/demo/terracotta.png	0	2026-10-01 07:15:05.823611+00
14	14	uploads/demo/plum.png	0	2026-10-01 07:15:05.878813+00
15	15	uploads/demo/amber.png	0	2026-10-01 07:15:05.949962+00
16	16	uploads/demo/sage.png	0	2026-10-01 07:15:06.016392+00
17	17	uploads/demo/slate.png	0	2026-10-01 07:15:06.096068+00
18	18	uploads/demo/terracotta.png	0	2026-10-01 07:15:06.174557+00
19	19	uploads/demo/plum.png	0	2026-10-01 07:15:06.253804+00
20	20	uploads/demo/amber.png	0	2026-10-01 07:15:06.348592+00
21	21	uploads/demo/sage.png	0	2026-10-01 07:15:06.438745+00
22	22	uploads/demo/slate.png	0	2026-10-01 07:15:06.529858+00
23	23	uploads/demo/terracotta.png	0	2026-10-01 07:15:06.62377+00
24	24	uploads/demo/plum.png	0	2026-10-01 07:15:06.713618+00
25	25	uploads/demo/amber.png	0	2026-10-01 07:15:06.805125+00
26	26	uploads/listings/26/6516f5e51f9c4c889fd3d3e2cc494e44.webp	0	2026-10-01 07:26:11.990326+00
27	28	uploads/demo/sage.png	0	2026-10-22 12:25:05.056707+00
28	29	uploads/demo/slate.png	0	2026-10-22 12:25:05.404954+00
29	30	uploads/demo/terracotta.png	0	2026-10-22 12:25:05.415984+00
30	31	uploads/demo/plum.png	0	2026-10-22 12:25:05.452987+00
31	32	uploads/demo/amber.png	0	2026-10-22 12:25:05.476363+00
32	33	uploads/demo/sage.png	0	2026-10-22 12:25:05.494307+00
33	34	uploads/demo/slate.png	0	2026-10-22 12:25:05.51362+00
34	35	uploads/demo/terracotta.png	0	2026-10-22 12:25:05.572686+00
35	36	uploads/demo/plum.png	0	2026-10-22 12:25:05.616976+00
36	37	uploads/demo/amber.png	0	2026-10-22 12:25:05.666534+00
37	38	uploads/demo/sage.png	0	2026-10-22 12:25:05.698446+00
38	39	uploads/demo/slate.png	0	2026-10-22 12:25:05.739088+00
39	40	uploads/demo/terracotta.png	0	2026-10-22 12:25:05.787222+00
40	41	uploads/demo/plum.png	0	2026-10-22 12:25:05.837335+00
41	42	uploads/demo/amber.png	0	2026-10-22 12:25:05.900808+00
42	43	uploads/demo/sage.png	0	2026-10-22 12:25:05.959763+00
43	44	uploads/demo/slate.png	0	2026-10-22 12:25:06.034725+00
44	45	uploads/demo/terracotta.png	0	2026-10-22 12:25:06.10387+00
45	46	uploads/demo/plum.png	0	2026-10-22 12:25:06.179201+00
46	47	uploads/demo/amber.png	0	2026-10-22 12:25:06.32309+00
47	48	uploads/demo/sage.png	0	2026-10-22 12:25:06.408983+00
48	49	uploads/demo/slate.png	0	2026-10-22 12:25:06.487685+00
49	50	uploads/demo/terracotta.png	0	2026-10-22 12:25:06.570038+00
50	51	uploads/demo/plum.png	0	2026-10-22 12:25:06.65256+00
51	52	uploads/demo/amber.png	0	2026-10-22 12:25:06.735355+00
\.


--
-- Data for Name: listings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.listings (listing_id, seller_id, category_id, title, description, condition, provenance, starting_price, reserve_price, current_price, min_bid_increment, start_time, end_time, original_end_time, status, moderation_status, created_at, updated_at, anti_sniping_extensions, anti_sniping_window_minutes, anti_sniping_extension_minutes, max_anti_sniping_extensions) FROM stdin;
1	4	1	Georgian Mahogany Card Table	A fine georgian mahogany card table, carefully preserved and offered from a private collection.	Good	Private collection	150.00	\N	150.00	1.00	2026-10-01 05:15:05.153993+00	2026-10-01 08:15:05.153993+00	2026-10-01 08:15:05.153993+00	Pending	Pending Review	2026-10-01 07:15:05.385651+00	2026-10-01 07:15:05.385651+00	0	5	10	\N
2	5	2	Edwardian Diamond Ring	A fine edwardian diamond ring, carefully preserved and offered from a private collection.	Good	Private collection	900.00	\N	900.00	1.00	2026-10-01 05:15:05.176034+00	2026-10-01 08:15:05.176034+00	2026-10-01 08:15:05.176034+00	Pending	Pending Review	2026-10-01 07:15:05.408394+00	2026-10-01 07:15:05.408394+00	0	5	10	\N
5	5	6	Victorian Silver Tea Set	A fine victorian silver tea set, carefully preserved and offered from a private collection.	Good	Private collection	220.00	\N	220.00	1.00	2026-10-01 05:15:05.229354+00	2026-10-01 08:15:05.229354+00	2026-10-01 08:15:05.229354+00	Closed	Approved	2026-10-01 07:15:05.4669+00	2026-10-01 08:15:06.596689+00	0	5	10	\N
3	6	3	Unverified Oil Painting	A fine unverified oil painting, carefully preserved and offered from a private collection.	Good	Private collection	300.00	\N	300.00	1.00	2026-10-01 05:15:05.184885+00	2026-10-01 08:15:05.184885+00	2026-10-01 08:15:05.184885+00	Cancelled	Rejected	2026-10-01 07:15:05.41797+00	2026-10-01 07:15:05.428415+00	0	5	10	\N
4	4	9	Antique Firearm Collection	A fine antique firearm collection, carefully preserved and offered from a private collection.	Good	Private collection	500.00	\N	500.00	1.00	2026-10-01 05:15:05.209954+00	2026-10-01 08:15:05.209954+00	2026-10-01 08:15:05.209954+00	Cancelled	Suspended	2026-10-01 07:15:05.445659+00	2026-10-01 07:15:05.455+00	0	5	10	\N
10	6	3	Limited Edition Lithograph	A fine limited edition lithograph, carefully preserved and offered from a private collection.	Good	Private collection	200.00	\N	210.00	1.00	2026-10-01 05:15:05.4339+00	2026-10-01 07:29:05.4339+00	2026-10-01 07:19:05.4339+00	Closed	Approved	2026-10-01 07:15:05.691971+00	2026-10-01 07:29:04.959516+00	1	5	10	\N
8	10	6	Qing Dynasty Porcelain Vase	A fine qing dynasty porcelain vase, carefully preserved and offered from a private collection.	Good	Private collection	600.00	\N	625.00	1.00	2026-10-01 05:15:05.33962+00	2026-10-01 08:15:05.33962+00	2026-10-01 08:15:05.33962+00	Closed	Approved	2026-10-01 07:15:05.588137+00	2026-10-01 08:15:07.048116+00	0	5	10	\N
6	6	5	First Edition Dickens Novel	A fine first edition dickens novel, carefully preserved and offered from a private collection.	Good	Private collection	400.00	\N	400.00	1.00	2026-10-01 05:15:05.247548+00	2026-10-01 08:15:05.247548+00	2026-10-01 08:15:05.247548+00	Closed	Approved	2026-10-01 07:15:05.486982+00	2026-10-01 08:15:07.011415+00	0	5	10	\N
9	5	10	Stradivarius-style Violin	A fine stradivarius-style violin, carefully preserved and offered from a private collection.	Good	Private collection	1200.00	\N	1250.00	1.00	2026-10-01 05:15:05.387847+00	2026-10-01 08:15:05.387847+00	2026-10-01 08:15:05.387847+00	Closed	Approved	2026-10-01 07:15:05.641618+00	2026-10-01 08:15:07.065336+00	0	5	10	\N
7	4	2	Art Deco Sapphire Brooch	A fine art deco sapphire brooch, carefully preserved and offered from a private collection.	Good	Private collection	80.00	\N	85.00	1.00	2026-10-01 05:15:05.272515+00	2026-10-01 08:15:05.272515+00	2026-10-01 08:15:05.272515+00	Closed	Approved	2026-10-01 07:15:05.514641+00	2026-10-01 08:15:07.028496+00	0	5	10	\N
26	10	2	Golder Brooch	Golden Brooch by Hades\n1 of only 10 pieces available in the world	Brand New	Owned	5000.00	10000.00	5000.00	1.00	2026-10-01 06:30:00+00	2026-10-02 06:30:00+00	2026-10-02 06:30:00+00	Closed	Approved	2026-10-01 07:26:04.447561+00	2026-10-22 12:25:31.31321+00	0	5	10	\N
11	4	8	Unsold Victorian Clock	A fine unsold victorian clock, carefully preserved and offered from a private collection.	Good	Private collection	90.00	\N	90.00	1.00	2026-10-01 05:15:05.465113+00	2026-10-01 07:15:04.48284+00	2026-10-01 07:17:05.465113+00	Closed	Approved	2026-10-01 07:15:05.726321+00	2026-10-01 07:15:05.754997+00	0	5	10	\N
12	5	4	Rare Gold Coin Collection	A fine rare gold coin collection, carefully preserved and offered from a private collection.	Good	Private collection	50.00	5000.00	50.00	1.00	2026-10-01 05:15:05.505511+00	2026-10-01 07:15:04.536137+00	2026-10-01 07:17:05.505511+00	Closed	Approved	2026-10-01 07:15:05.770864+00	2026-10-01 07:15:05.810167+00	1	5	10	\N
13	6	7	Persian Silk Rug	A fine persian silk rug, carefully preserved and offered from a private collection.	Good	Private collection	300.00	3000.00	300.00	1.00	2026-10-01 05:15:05.553599+00	2026-10-01 07:15:04.584996+00	2026-10-01 07:17:05.553599+00	Closed	Approved	2026-10-01 07:15:05.823611+00	2026-10-01 07:15:05.864812+00	1	5	10	\N
14	10	1	Regency Dining Chairs	A fine regency dining chairs, carefully preserved and offered from a private collection.	Good	Private collection	350.00	350.00	350.00	1.00	2026-10-01 05:15:05.603667+00	2026-10-01 07:15:04.637024+00	2026-10-01 07:17:05.603667+00	Closed	Approved	2026-10-01 07:15:05.878813+00	2026-10-01 07:15:05.921296+00	1	5	10	\N
15	4	2	Art Nouveau Hair Comb	A fine art nouveau hair comb, carefully preserved and offered from a private collection.	Good	Private collection	150.00	150.00	150.00	1.00	2026-10-01 05:15:05.668217+00	2026-10-01 07:15:04.700214+00	2026-10-01 07:17:05.668217+00	Closed	Approved	2026-10-01 07:15:05.949962+00	2026-10-01 07:15:05.992271+00	1	5	10	\N
16	5	3	Impressionist Landscape Study	A fine impressionist landscape study, carefully preserved and offered from a private collection.	Good	Private collection	700.00	700.00	700.00	1.00	2026-10-01 05:15:05.728874+00	2026-10-01 07:15:04.75948+00	2026-10-01 07:17:05.728874+00	Closed	Approved	2026-10-01 07:15:06.016392+00	2026-10-01 07:15:06.057466+00	1	5	10	\N
17	6	8	18th Century Pocket Watch	A fine 18th century pocket watch, carefully preserved and offered from a private collection.	Good	Private collection	800.00	800.00	800.00	1.00	2026-10-01 05:15:05.8013+00	2026-10-01 07:15:04.834322+00	2026-10-01 07:17:05.8013+00	Closed	Approved	2026-10-01 07:15:06.096068+00	2026-10-01 07:15:06.13813+00	1	5	10	\N
18	10	6	Delft Blue Porcelain Plate	A fine delft blue porcelain plate, carefully preserved and offered from a private collection.	Good	Private collection	120.00	120.00	120.00	1.00	2026-10-01 05:15:05.872159+00	2026-10-01 07:15:04.904824+00	2026-10-01 07:17:05.872159+00	Closed	Approved	2026-10-01 07:15:06.174557+00	2026-10-01 07:15:06.217234+00	1	5	10	\N
19	4	4	Roman Silver Denarius	A fine roman silver denarius, carefully preserved and offered from a private collection.	Good	Private collection	250.00	250.00	250.00	1.00	2026-10-01 05:15:05.944708+00	2026-10-01 07:15:04.974256+00	2026-10-01 07:17:05.944708+00	Closed	Approved	2026-10-01 07:15:06.253804+00	2026-10-01 07:15:06.29226+00	1	5	10	\N
20	5	7	Hand-Knotted Kilim Rug	A fine hand-knotted kilim rug, carefully preserved and offered from a private collection.	Good	Private collection	450.00	450.00	450.00	1.00	2026-10-01 05:15:06.030817+00	2026-10-01 07:15:05.062343+00	2026-10-01 07:17:06.030817+00	Closed	Approved	2026-10-01 07:15:06.348592+00	2026-10-01 07:15:06.38921+00	1	5	10	\N
21	6	10	Vintage Brass Trumpet	A fine vintage brass trumpet, carefully preserved and offered from a private collection.	Good	Private collection	300.00	300.00	300.00	1.00	2026-10-01 05:15:06.112774+00	2026-10-01 07:15:05.14377+00	2026-10-01 07:17:06.112774+00	Closed	Approved	2026-10-01 07:15:06.438745+00	2026-10-01 07:15:06.479258+00	1	5	10	\N
22	10	5	First Folio Facsimile	A fine first folio facsimile, carefully preserved and offered from a private collection.	Good	Private collection	600.00	600.00	600.00	1.00	2026-10-01 05:15:06.1956+00	2026-10-01 07:15:05.22633+00	2026-10-01 07:17:06.1956+00	Closed	Approved	2026-10-01 07:15:06.529858+00	2026-10-01 07:15:06.570733+00	1	5	10	\N
23	4	9	WWII Medal Set	A fine wwii medal set, carefully preserved and offered from a private collection.	Good	Private collection	350.00	350.00	350.00	1.00	2026-10-01 05:15:06.280986+00	2026-10-01 07:15:05.312593+00	2026-10-01 07:17:06.280986+00	Closed	Approved	2026-10-01 07:15:06.62377+00	2026-10-01 07:15:06.664284+00	1	5	10	\N
24	5	1	Tiffany Style Lamp	A fine tiffany style lamp, carefully preserved and offered from a private collection.	Good	Private collection	400.00	400.00	400.00	1.00	2026-10-01 05:15:06.36246+00	2026-10-01 07:15:05.395529+00	2026-10-01 07:17:06.36246+00	Closed	Approved	2026-10-01 07:15:06.713618+00	2026-10-01 07:15:06.755283+00	1	5	10	\N
25	6	2	Emerald Cut Sapphire Pendant	A fine emerald cut sapphire pendant, carefully preserved and offered from a private collection.	Good	Private collection	950.00	950.00	950.00	1.00	2026-10-01 05:15:06.445749+00	2026-10-01 07:15:05.476542+00	2026-10-01 07:17:06.445749+00	Closed	Approved	2026-10-01 07:15:06.805125+00	2026-10-01 07:15:06.849371+00	1	5	10	\N
27	10	2	Golder Brooch	Golden Brooch by Hades\n1 of only 10 pieces available in the world	Brand New	Owned	5000.00	10000.00	5000.00	1.00	2026-10-01 06:30:00+00	2026-10-02 06:30:00+00	2026-10-02 06:30:00+00	Cancelled	Rejected	2026-10-01 07:26:14.85583+00	2026-10-01 07:27:06.718166+00	0	5	10	\N
28	4	1	Georgian Mahogany Card Table	A fine georgian mahogany card table, carefully preserved and offered from a private collection.	Good	Private collection	150.00	\N	150.00	1.00	2026-10-22 10:25:05.108918+00	2026-10-22 13:25:05.108918+00	2026-10-22 13:25:05.108918+00	Pending	Pending Review	2026-10-22 12:25:05.056707+00	2026-10-22 12:25:05.056707+00	0	5	10	\N
29	5	2	Edwardian Diamond Ring	A fine edwardian diamond ring, carefully preserved and offered from a private collection.	Good	Private collection	900.00	\N	900.00	1.00	2026-10-22 10:25:05.458211+00	2026-10-22 13:25:05.458211+00	2026-10-22 13:25:05.458211+00	Pending	Pending Review	2026-10-22 12:25:05.404954+00	2026-10-22 12:25:05.404954+00	0	5	10	\N
32	5	6	Victorian Silver Tea Set	A fine victorian silver tea set, carefully preserved and offered from a private collection.	Good	Private collection	220.00	\N	250.12	1.00	2026-10-22 10:25:05.529833+00	2026-10-22 13:25:05.529833+00	2026-10-22 13:25:05.529833+00	Active	Approved	2026-10-22 12:25:05.476363+00	2026-10-22 12:27:38.127499+00	0	5	10	\N
30	6	3	Unverified Oil Painting	A fine unverified oil painting, carefully preserved and offered from a private collection.	Good	Private collection	300.00	\N	300.00	1.00	2026-10-22 10:25:05.469322+00	2026-10-22 13:25:05.469322+00	2026-10-22 13:25:05.469322+00	Cancelled	Rejected	2026-10-22 12:25:05.415984+00	2026-10-22 12:25:05.427211+00	0	5	10	\N
31	4	9	Antique Firearm Collection	A fine antique firearm collection, carefully preserved and offered from a private collection.	Good	Private collection	500.00	\N	500.00	1.00	2026-10-22 10:25:05.506007+00	2026-10-22 13:25:05.506007+00	2026-10-22 13:25:05.506007+00	Cancelled	Suspended	2026-10-22 12:25:05.452987+00	2026-10-22 12:25:05.46174+00	0	5	10	\N
33	6	5	First Edition Dickens Novel	A fine first edition dickens novel, carefully preserved and offered from a private collection.	Good	Private collection	400.00	\N	400.00	1.00	2026-10-22 10:25:05.547734+00	2026-10-22 13:25:05.547734+00	2026-10-22 13:25:05.547734+00	Active	Approved	2026-10-22 12:25:05.494307+00	2026-10-22 12:25:05.503917+00	0	5	10	\N
34	4	2	Art Deco Sapphire Brooch	A fine art deco sapphire brooch, carefully preserved and offered from a private collection.	Good	Private collection	80.00	\N	85.00	1.00	2026-10-22 10:25:05.567081+00	2026-10-22 13:25:05.567081+00	2026-10-22 13:25:05.567081+00	Active	Approved	2026-10-22 12:25:05.51362+00	2026-10-22 12:25:05.557249+00	0	5	10	\N
35	10	6	Qing Dynasty Porcelain Vase	A fine qing dynasty porcelain vase, carefully preserved and offered from a private collection.	Good	Private collection	600.00	\N	625.00	1.00	2026-10-22 10:25:05.626137+00	2026-10-22 13:25:05.626137+00	2026-10-22 13:25:05.626137+00	Active	Approved	2026-10-22 12:25:05.572686+00	2026-10-22 12:25:05.602886+00	0	5	10	\N
36	5	10	Stradivarius-style Violin	A fine stradivarius-style violin, carefully preserved and offered from a private collection.	Good	Private collection	1200.00	\N	1250.00	1.00	2026-10-22 10:25:05.670551+00	2026-10-22 13:25:05.670551+00	2026-10-22 13:25:05.670551+00	Active	Approved	2026-10-22 12:25:05.616976+00	2026-10-22 12:25:05.650545+00	0	5	10	\N
37	6	3	Limited Edition Lithograph	A fine limited edition lithograph, carefully preserved and offered from a private collection.	Good	Private collection	200.00	\N	200.00	1.00	2026-10-22 10:25:05.720073+00	2026-10-22 12:39:05.720073+00	2026-10-22 12:29:05.720073+00	Active	Approved	2026-10-22 12:25:05.666534+00	2026-10-22 12:25:05.685024+00	1	5	10	\N
38	4	8	Unsold Victorian Clock	A fine unsold victorian clock, carefully preserved and offered from a private collection.	Good	Private collection	90.00	\N	90.00	1.00	2026-10-22 10:25:05.752095+00	2026-10-22 12:25:04.770373+00	2026-10-22 12:27:05.752095+00	Closed	Approved	2026-10-22 12:25:05.698446+00	2026-10-22 12:25:05.7229+00	0	5	10	\N
39	5	4	Rare Gold Coin Collection	A fine rare gold coin collection, carefully preserved and offered from a private collection.	Good	Private collection	50.00	5000.00	50.00	1.00	2026-10-22 10:25:05.792486+00	2026-10-22 12:25:04.824096+00	2026-10-22 12:27:05.792486+00	Closed	Approved	2026-10-22 12:25:05.739088+00	2026-10-22 12:25:05.77565+00	1	5	10	\N
40	6	7	Persian Silk Rug	A fine persian silk rug, carefully preserved and offered from a private collection.	Good	Private collection	300.00	3000.00	300.00	1.00	2026-10-22 10:25:05.840984+00	2026-10-22 12:25:04.874461+00	2026-10-22 12:27:05.840984+00	Closed	Approved	2026-10-22 12:25:05.787222+00	2026-10-22 12:25:05.826052+00	1	5	10	\N
41	10	1	Regency Dining Chairs	A fine regency dining chairs, carefully preserved and offered from a private collection.	Good	Private collection	350.00	350.00	350.00	1.00	2026-10-22 10:25:05.891147+00	2026-10-22 12:25:04.921411+00	2026-10-22 12:27:05.891147+00	Closed	Approved	2026-10-22 12:25:05.837335+00	2026-10-22 12:25:05.872819+00	1	5	10	\N
42	4	2	Art Nouveau Hair Comb	A fine art nouveau hair comb, carefully preserved and offered from a private collection.	Good	Private collection	150.00	150.00	150.00	1.00	2026-10-22 10:25:05.954609+00	2026-10-22 12:25:04.986176+00	2026-10-22 12:27:05.954609+00	Closed	Approved	2026-10-22 12:25:05.900808+00	2026-10-22 12:25:05.938018+00	1	5	10	\N
43	5	3	Impressionist Landscape Study	A fine impressionist landscape study, carefully preserved and offered from a private collection.	Good	Private collection	700.00	700.00	700.00	1.00	2026-10-22 10:25:06.013676+00	2026-10-22 12:25:05.045538+00	2026-10-22 12:27:06.013676+00	Closed	Approved	2026-10-22 12:25:05.959763+00	2026-10-22 12:25:05.997629+00	1	5	10	\N
44	6	8	18th Century Pocket Watch	A fine 18th century pocket watch, carefully preserved and offered from a private collection.	Good	Private collection	800.00	800.00	800.00	1.00	2026-10-22 10:25:06.088602+00	2026-10-22 12:25:05.11897+00	2026-10-22 12:27:06.088602+00	Closed	Approved	2026-10-22 12:25:06.034725+00	2026-10-22 12:25:06.070717+00	1	5	10	\N
45	10	6	Delft Blue Porcelain Plate	A fine delft blue porcelain plate, carefully preserved and offered from a private collection.	Good	Private collection	120.00	120.00	120.00	1.00	2026-10-22 10:25:06.157761+00	2026-10-22 12:25:05.191226+00	2026-10-22 12:27:06.157761+00	Closed	Approved	2026-10-22 12:25:06.10387+00	2026-10-22 12:25:06.144298+00	1	5	10	\N
46	4	4	Roman Silver Denarius	A fine roman silver denarius, carefully preserved and offered from a private collection.	Good	Private collection	250.00	250.00	250.00	1.00	2026-10-22 10:25:06.232843+00	2026-10-22 12:25:05.270372+00	2026-10-22 12:27:06.232843+00	Closed	Approved	2026-10-22 12:25:06.179201+00	2026-10-22 12:25:06.226794+00	1	5	10	\N
47	5	7	Hand-Knotted Kilim Rug	A fine hand-knotted kilim rug, carefully preserved and offered from a private collection.	Good	Private collection	450.00	450.00	450.00	1.00	2026-10-22 10:25:06.376317+00	2026-10-22 12:25:05.412392+00	2026-10-22 12:27:06.376317+00	Closed	Approved	2026-10-22 12:25:06.32309+00	2026-10-22 12:25:06.364319+00	1	5	10	\N
48	6	10	Vintage Brass Trumpet	A fine vintage brass trumpet, carefully preserved and offered from a private collection.	Good	Private collection	300.00	300.00	300.00	1.00	2026-10-22 10:25:06.462656+00	2026-10-22 12:25:05.492986+00	2026-10-22 12:27:06.462656+00	Closed	Approved	2026-10-22 12:25:06.408983+00	2026-10-22 12:25:06.444332+00	1	5	10	\N
49	10	5	First Folio Facsimile	A fine first folio facsimile, carefully preserved and offered from a private collection.	Good	Private collection	600.00	600.00	600.00	1.00	2026-10-22 10:25:06.541237+00	2026-10-22 12:25:05.572377+00	2026-10-22 12:27:06.541237+00	Closed	Approved	2026-10-22 12:25:06.487685+00	2026-10-22 12:25:06.523731+00	1	5	10	\N
50	4	9	WWII Medal Set	A fine wwii medal set, carefully preserved and offered from a private collection.	Good	Private collection	350.00	350.00	350.00	1.00	2026-10-22 10:25:06.623639+00	2026-10-22 12:25:05.654452+00	2026-10-22 12:27:06.623639+00	Closed	Approved	2026-10-22 12:25:06.570038+00	2026-10-22 12:25:06.606714+00	1	5	10	\N
51	5	1	Tiffany Style Lamp	A fine tiffany style lamp, carefully preserved and offered from a private collection.	Good	Private collection	400.00	400.00	400.00	1.00	2026-10-22 10:25:06.705988+00	2026-10-22 12:25:05.73716+00	2026-10-22 12:27:06.705988+00	Closed	Approved	2026-10-22 12:25:06.65256+00	2026-10-22 12:25:06.688968+00	1	5	10	\N
52	6	2	Emerald Cut Sapphire Pendant	A fine emerald cut sapphire pendant, carefully preserved and offered from a private collection.	Good	Private collection	950.00	950.00	950.00	1.00	2026-10-22 10:25:06.788579+00	2026-10-22 12:25:05.822717+00	2026-10-22 12:27:06.788579+00	Closed	Approved	2026-10-22 12:25:06.735355+00	2026-10-22 12:25:06.774361+00	1	5	10	\N
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications (notification_id, user_id, type, title, message, is_read, created_at, read_at) FROM stdin;
1	6	LISTING_MODERATED	Listing rejected	Your listing 'Unverified Oil Painting' was rejected. Reason: Unable to verify authenticity	f	2026-10-01 07:15:05.428415+00	\N
2	4	LISTING_MODERATED	Listing suspended	Your listing 'Antique Firearm Collection' was suspended. Reason: Requires additional compliance review	f	2026-10-01 07:15:05.455+00	\N
3	5	LISTING_MODERATED	Listing approved	Your listing 'Victorian Silver Tea Set' was approved.	f	2026-10-01 07:15:05.476546+00	\N
4	6	LISTING_MODERATED	Listing approved	Your listing 'First Edition Dickens Novel' was approved.	f	2026-10-01 07:15:05.501287+00	\N
5	4	LISTING_MODERATED	Listing approved	Your listing 'Art Deco Sapphire Brooch' was approved.	f	2026-10-01 07:15:05.525039+00	\N
6	7	BID_CONFIRMED	Bid placed	Your bid of 80.00 on 'Art Deco Sapphire Brooch' was accepted.	f	2026-10-01 07:15:05.540058+00	\N
7	8	BID_CONFIRMED	Bid placed	Your bid of 85.00 on 'Art Deco Sapphire Brooch' was accepted.	f	2026-10-01 07:15:05.571521+00	\N
8	7	OUTBID	You've been outbid	Someone placed a higher bid on 'Art Deco Sapphire Brooch'. The new price is 85.00.	f	2026-10-01 07:15:05.571521+00	\N
9	10	LISTING_MODERATED	Listing approved	Your listing 'Qing Dynasty Porcelain Vase' was approved.	f	2026-10-01 07:15:05.596082+00	\N
10	7	BID_CONFIRMED	Bid placed	Your bid of 600.00 on 'Qing Dynasty Porcelain Vase' was accepted.	f	2026-10-01 07:15:05.606478+00	\N
11	9	BID_CONFIRMED	Bid placed	Your bid of 625.00 on 'Qing Dynasty Porcelain Vase' was accepted.	f	2026-10-01 07:15:05.625955+00	\N
12	7	OUTBID	You've been outbid	Someone placed a higher bid on 'Qing Dynasty Porcelain Vase'. The new price is 625.00.	f	2026-10-01 07:15:05.625955+00	\N
13	5	LISTING_MODERATED	Listing approved	Your listing 'Stradivarius-style Violin' was approved.	f	2026-10-01 07:15:05.650682+00	\N
14	8	BID_CONFIRMED	Bid placed	Your bid of 1200.00 on 'Stradivarius-style Violin' was accepted.	f	2026-10-01 07:15:05.660992+00	\N
15	10	BID_CONFIRMED	Bid placed	Your bid of 1250.00 on 'Stradivarius-style Violin' was accepted.	f	2026-10-01 07:15:05.67518+00	\N
16	8	OUTBID	You've been outbid	Someone placed a higher bid on 'Stradivarius-style Violin'. The new price is 1250.00.	f	2026-10-01 07:15:05.67518+00	\N
17	6	LISTING_MODERATED	Listing approved	Your listing 'Limited Edition Lithograph' was approved.	f	2026-10-01 07:15:05.701248+00	\N
18	7	BID_CONFIRMED	Bid placed	Your bid of 200.00 on 'Limited Edition Lithograph' was accepted.	f	2026-10-01 07:15:05.711166+00	\N
19	6	AUCTION_EXTENDED	Auction extended	A late bid on 'Limited Edition Lithograph' extended the closing time to 2026-10-01T07:29:05.433900+00:00.	f	2026-10-01 07:15:05.711166+00	\N
20	4	LISTING_MODERATED	Listing approved	Your listing 'Unsold Victorian Clock' was approved.	f	2026-10-01 07:15:05.73601+00	\N
21	4	AUCTION_NO_BIDS	No bids received	'Unsold Victorian Clock' closed with no bids.	f	2026-10-01 07:15:05.754997+00	\N
22	5	LISTING_MODERATED	Listing approved	Your listing 'Rare Gold Coin Collection' was approved.	f	2026-10-01 07:15:05.779829+00	\N
23	8	BID_CONFIRMED	Bid placed	Your bid of 50.00 on 'Rare Gold Coin Collection' was accepted.	f	2026-10-01 07:15:05.78989+00	\N
24	5	AUCTION_EXTENDED	Auction extended	A late bid on 'Rare Gold Coin Collection' extended the closing time to 2026-10-01T07:27:05.505511+00:00.	f	2026-10-01 07:15:05.78989+00	\N
25	5	AUCTION_RESERVE_NOT_MET	Reserve not met	'Rare Gold Coin Collection' closed without meeting the reserve price.	f	2026-10-01 07:15:05.810167+00	\N
26	8	AUCTION_LOST	Auction ended	'Rare Gold Coin Collection' has closed. You did not win this item.	f	2026-10-01 07:15:05.810167+00	\N
27	6	LISTING_MODERATED	Listing approved	Your listing 'Persian Silk Rug' was approved.	f	2026-10-01 07:15:05.832961+00	\N
28	9	BID_CONFIRMED	Bid placed	Your bid of 300.00 on 'Persian Silk Rug' was accepted.	f	2026-10-01 07:15:05.843554+00	\N
29	6	AUCTION_EXTENDED	Auction extended	A late bid on 'Persian Silk Rug' extended the closing time to 2026-10-01T07:27:05.553599+00:00.	f	2026-10-01 07:15:05.843554+00	\N
30	6	AUCTION_RESERVE_NOT_MET	Reserve not met	'Persian Silk Rug' closed without meeting the reserve price.	f	2026-10-01 07:15:05.864812+00	\N
31	9	AUCTION_LOST	Auction ended	'Persian Silk Rug' has closed. You did not win this item.	f	2026-10-01 07:15:05.864812+00	\N
32	10	LISTING_MODERATED	Listing approved	Your listing 'Regency Dining Chairs' was approved.	f	2026-10-01 07:15:05.88771+00	\N
33	7	BID_CONFIRMED	Bid placed	Your bid of 350.00 on 'Regency Dining Chairs' was accepted.	f	2026-10-01 07:15:05.898115+00	\N
34	10	AUCTION_EXTENDED	Auction extended	A late bid on 'Regency Dining Chairs' extended the closing time to 2026-10-01T07:27:05.603667+00:00.	f	2026-10-01 07:15:05.898115+00	\N
35	7	AUCTION_WON	You won!	You won 'Regency Dining Chairs' for 350.00. Payment instructions to follow.	f	2026-10-01 07:15:05.921296+00	\N
36	10	AUCTION_SOLD	Your item sold	'Regency Dining Chairs' sold for 350.00.	f	2026-10-01 07:15:05.921296+00	\N
37	10	PAYMENT_RECEIVED	Payment received	Payment of 350.00 has been placed in escrow for your sale.	f	2026-10-01 07:15:05.934392+00	\N
38	4	LISTING_MODERATED	Listing approved	Your listing 'Art Nouveau Hair Comb' was approved.	f	2026-10-01 07:15:05.959222+00	\N
39	8	BID_CONFIRMED	Bid placed	Your bid of 150.00 on 'Art Nouveau Hair Comb' was accepted.	f	2026-10-01 07:15:05.970369+00	\N
40	4	AUCTION_EXTENDED	Auction extended	A late bid on 'Art Nouveau Hair Comb' extended the closing time to 2026-10-01T07:27:05.668217+00:00.	f	2026-10-01 07:15:05.970369+00	\N
41	8	AUCTION_WON	You won!	You won 'Art Nouveau Hair Comb' for 150.00. Payment instructions to follow.	f	2026-10-01 07:15:05.992271+00	\N
42	4	AUCTION_SOLD	Your item sold	'Art Nouveau Hair Comb' sold for 150.00.	f	2026-10-01 07:15:05.992271+00	\N
43	4	PAYMENT_RECEIVED	Payment received	Payment of 150.00 has been placed in escrow for your sale.	f	2026-10-01 07:15:06.004242+00	\N
44	5	LISTING_MODERATED	Listing approved	Your listing 'Impressionist Landscape Study' was approved.	f	2026-10-01 07:15:06.025569+00	\N
45	9	BID_CONFIRMED	Bid placed	Your bid of 700.00 on 'Impressionist Landscape Study' was accepted.	f	2026-10-01 07:15:06.035665+00	\N
46	5	AUCTION_EXTENDED	Auction extended	A late bid on 'Impressionist Landscape Study' extended the closing time to 2026-10-01T07:27:05.728874+00:00.	f	2026-10-01 07:15:06.035665+00	\N
47	9	AUCTION_WON	You won!	You won 'Impressionist Landscape Study' for 700.00. Payment instructions to follow.	f	2026-10-01 07:15:06.057466+00	\N
48	5	AUCTION_SOLD	Your item sold	'Impressionist Landscape Study' sold for 700.00.	f	2026-10-01 07:15:06.057466+00	\N
49	5	PAYMENT_RECEIVED	Payment received	Payment of 700.00 has been placed in escrow for your sale.	f	2026-10-01 07:15:06.071792+00	\N
50	5	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Impressionist Landscape Study'.	f	2026-10-01 07:15:06.083372+00	\N
51	6	LISTING_MODERATED	Listing approved	Your listing '18th Century Pocket Watch' was approved.	f	2026-10-01 07:15:06.106155+00	\N
52	10	BID_CONFIRMED	Bid placed	Your bid of 800.00 on '18th Century Pocket Watch' was accepted.	f	2026-10-01 07:15:06.118035+00	\N
106	4	AUCTION_SOLD	Your item sold	'WWII Medal Set' sold for 350.00.	f	2026-10-01 07:15:06.664284+00	\N
53	6	AUCTION_EXTENDED	Auction extended	A late bid on '18th Century Pocket Watch' extended the closing time to 2026-10-01T07:27:05.801300+00:00.	f	2026-10-01 07:15:06.118035+00	\N
54	10	AUCTION_WON	You won!	You won '18th Century Pocket Watch' for 800.00. Payment instructions to follow.	f	2026-10-01 07:15:06.13813+00	\N
55	6	AUCTION_SOLD	Your item sold	'18th Century Pocket Watch' sold for 800.00.	f	2026-10-01 07:15:06.13813+00	\N
56	6	PAYMENT_RECEIVED	Payment received	Payment of 800.00 has been placed in escrow for your sale.	f	2026-10-01 07:15:06.150611+00	\N
57	6	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding '18th Century Pocket Watch'.	f	2026-10-01 07:15:06.163082+00	\N
58	10	LISTING_MODERATED	Listing approved	Your listing 'Delft Blue Porcelain Plate' was approved.	f	2026-10-01 07:15:06.183507+00	\N
59	7	BID_CONFIRMED	Bid placed	Your bid of 120.00 on 'Delft Blue Porcelain Plate' was accepted.	f	2026-10-01 07:15:06.195522+00	\N
60	10	AUCTION_EXTENDED	Auction extended	A late bid on 'Delft Blue Porcelain Plate' extended the closing time to 2026-10-01T07:27:05.872159+00:00.	f	2026-10-01 07:15:06.195522+00	\N
61	7	AUCTION_WON	You won!	You won 'Delft Blue Porcelain Plate' for 120.00. Payment instructions to follow.	f	2026-10-01 07:15:06.217234+00	\N
62	10	AUCTION_SOLD	Your item sold	'Delft Blue Porcelain Plate' sold for 120.00.	f	2026-10-01 07:15:06.217234+00	\N
63	10	PAYMENT_RECEIVED	Payment received	Payment of 120.00 has been placed in escrow for your sale.	f	2026-10-01 07:15:06.229725+00	\N
64	10	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Delft Blue Porcelain Plate'.	f	2026-10-01 07:15:06.243183+00	\N
65	4	LISTING_MODERATED	Listing approved	Your listing 'Roman Silver Denarius' was approved.	f	2026-10-01 07:15:06.262103+00	\N
66	8	BID_CONFIRMED	Bid placed	Your bid of 250.00 on 'Roman Silver Denarius' was accepted.	f	2026-10-01 07:15:06.27204+00	\N
67	4	AUCTION_EXTENDED	Auction extended	A late bid on 'Roman Silver Denarius' extended the closing time to 2026-10-01T07:27:05.944708+00:00.	f	2026-10-01 07:15:06.27204+00	\N
68	8	AUCTION_WON	You won!	You won 'Roman Silver Denarius' for 250.00. Payment instructions to follow.	f	2026-10-01 07:15:06.29226+00	\N
69	4	AUCTION_SOLD	Your item sold	'Roman Silver Denarius' sold for 250.00.	f	2026-10-01 07:15:06.29226+00	\N
70	4	PAYMENT_RECEIVED	Payment received	Payment of 250.00 has been placed in escrow for your sale.	f	2026-10-01 07:15:06.304989+00	\N
71	4	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Roman Silver Denarius'.	f	2026-10-01 07:15:06.321269+00	\N
72	8	DISPUTE_UPDATED	Dispute under review	The dispute regarding 'Roman Silver Denarius' is now under review.	f	2026-10-01 07:15:06.333666+00	\N
73	4	DISPUTE_UPDATED	Dispute under review	The dispute regarding 'Roman Silver Denarius' is now under review.	f	2026-10-01 07:15:06.333666+00	\N
74	5	LISTING_MODERATED	Listing approved	Your listing 'Hand-Knotted Kilim Rug' was approved.	f	2026-10-01 07:15:06.357784+00	\N
75	9	BID_CONFIRMED	Bid placed	Your bid of 450.00 on 'Hand-Knotted Kilim Rug' was accepted.	f	2026-10-01 07:15:06.367773+00	\N
76	5	AUCTION_EXTENDED	Auction extended	A late bid on 'Hand-Knotted Kilim Rug' extended the closing time to 2026-10-01T07:27:06.030817+00:00.	f	2026-10-01 07:15:06.367773+00	\N
77	9	AUCTION_WON	You won!	You won 'Hand-Knotted Kilim Rug' for 450.00. Payment instructions to follow.	f	2026-10-01 07:15:06.38921+00	\N
78	5	AUCTION_SOLD	Your item sold	'Hand-Knotted Kilim Rug' sold for 450.00.	f	2026-10-01 07:15:06.38921+00	\N
79	5	PAYMENT_RECEIVED	Payment received	Payment of 450.00 has been placed in escrow for your sale.	f	2026-10-01 07:15:06.403812+00	\N
80	5	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Hand-Knotted Kilim Rug'.	f	2026-10-01 07:15:06.415344+00	\N
81	9	DISPUTE_UPDATED	Dispute under review	The dispute regarding 'Hand-Knotted Kilim Rug' is now under review.	f	2026-10-01 07:15:06.425967+00	\N
82	5	DISPUTE_UPDATED	Dispute under review	The dispute regarding 'Hand-Knotted Kilim Rug' is now under review.	f	2026-10-01 07:15:06.425967+00	\N
83	6	LISTING_MODERATED	Listing approved	Your listing 'Vintage Brass Trumpet' was approved.	f	2026-10-01 07:15:06.447658+00	\N
84	10	BID_CONFIRMED	Bid placed	Your bid of 300.00 on 'Vintage Brass Trumpet' was accepted.	f	2026-10-01 07:15:06.458327+00	\N
85	6	AUCTION_EXTENDED	Auction extended	A late bid on 'Vintage Brass Trumpet' extended the closing time to 2026-10-01T07:27:06.112774+00:00.	f	2026-10-01 07:15:06.458327+00	\N
86	10	AUCTION_WON	You won!	You won 'Vintage Brass Trumpet' for 300.00. Payment instructions to follow.	f	2026-10-01 07:15:06.479258+00	\N
87	6	AUCTION_SOLD	Your item sold	'Vintage Brass Trumpet' sold for 300.00.	f	2026-10-01 07:15:06.479258+00	\N
88	6	PAYMENT_RECEIVED	Payment received	Payment of 300.00 has been placed in escrow for your sale.	f	2026-10-01 07:15:06.492422+00	\N
89	6	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Vintage Brass Trumpet'.	f	2026-10-01 07:15:06.504053+00	\N
90	10	DISPUTE_UPDATED	Dispute under review	The dispute regarding 'Vintage Brass Trumpet' is now under review.	f	2026-10-01 07:15:06.515534+00	\N
91	6	DISPUTE_UPDATED	Dispute under review	The dispute regarding 'Vintage Brass Trumpet' is now under review.	f	2026-10-01 07:15:06.515534+00	\N
92	10	LISTING_MODERATED	Listing approved	Your listing 'First Folio Facsimile' was approved.	f	2026-10-01 07:15:06.538705+00	\N
93	7	BID_CONFIRMED	Bid placed	Your bid of 600.00 on 'First Folio Facsimile' was accepted.	f	2026-10-01 07:15:06.5491+00	\N
94	10	AUCTION_EXTENDED	Auction extended	A late bid on 'First Folio Facsimile' extended the closing time to 2026-10-01T07:27:06.195600+00:00.	f	2026-10-01 07:15:06.5491+00	\N
95	7	AUCTION_WON	You won!	You won 'First Folio Facsimile' for 600.00. Payment instructions to follow.	f	2026-10-01 07:15:06.570733+00	\N
96	10	AUCTION_SOLD	Your item sold	'First Folio Facsimile' sold for 600.00.	f	2026-10-01 07:15:06.570733+00	\N
97	10	PAYMENT_RECEIVED	Payment received	Payment of 600.00 has been placed in escrow for your sale.	f	2026-10-01 07:15:06.582547+00	\N
98	10	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'First Folio Facsimile'.	f	2026-10-01 07:15:06.593839+00	\N
99	7	ESCROW_REFUNDED	Payment refunded	Your payment of 600.00 has been refunded.	f	2026-10-01 07:15:06.606923+00	\N
100	10	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'First Folio Facsimile' is now resolved.	f	2026-10-01 07:15:06.606923+00	\N
101	7	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'First Folio Facsimile' is now resolved.	f	2026-10-01 07:15:06.606923+00	\N
102	4	LISTING_MODERATED	Listing approved	Your listing 'WWII Medal Set' was approved.	f	2026-10-01 07:15:06.632886+00	\N
103	8	BID_CONFIRMED	Bid placed	Your bid of 350.00 on 'WWII Medal Set' was accepted.	f	2026-10-01 07:15:06.644402+00	\N
104	4	AUCTION_EXTENDED	Auction extended	A late bid on 'WWII Medal Set' extended the closing time to 2026-10-01T07:27:06.280986+00:00.	f	2026-10-01 07:15:06.644402+00	\N
105	8	AUCTION_WON	You won!	You won 'WWII Medal Set' for 350.00. Payment instructions to follow.	f	2026-10-01 07:15:06.664284+00	\N
107	4	PAYMENT_RECEIVED	Payment received	Payment of 350.00 has been placed in escrow for your sale.	f	2026-10-01 07:15:06.675591+00	\N
108	4	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'WWII Medal Set'.	f	2026-10-01 07:15:06.686784+00	\N
109	8	ESCROW_REFUNDED	Payment refunded	Your payment of 350.00 has been refunded.	f	2026-10-01 07:15:06.69717+00	\N
110	8	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'WWII Medal Set' is now resolved.	f	2026-10-01 07:15:06.69717+00	\N
111	4	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'WWII Medal Set' is now resolved.	f	2026-10-01 07:15:06.69717+00	\N
112	5	LISTING_MODERATED	Listing approved	Your listing 'Tiffany Style Lamp' was approved.	f	2026-10-01 07:15:06.722616+00	\N
113	9	BID_CONFIRMED	Bid placed	Your bid of 400.00 on 'Tiffany Style Lamp' was accepted.	f	2026-10-01 07:15:06.732918+00	\N
114	5	AUCTION_EXTENDED	Auction extended	A late bid on 'Tiffany Style Lamp' extended the closing time to 2026-10-01T07:27:06.362460+00:00.	f	2026-10-01 07:15:06.732918+00	\N
115	9	AUCTION_WON	You won!	You won 'Tiffany Style Lamp' for 400.00. Payment instructions to follow.	f	2026-10-01 07:15:06.755283+00	\N
116	5	AUCTION_SOLD	Your item sold	'Tiffany Style Lamp' sold for 400.00.	f	2026-10-01 07:15:06.755283+00	\N
117	5	PAYMENT_RECEIVED	Payment received	Payment of 400.00 has been placed in escrow for your sale.	f	2026-10-01 07:15:06.767403+00	\N
118	5	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Tiffany Style Lamp'.	f	2026-10-01 07:15:06.779035+00	\N
119	5	ESCROW_RELEASED	Funds released	The escrowed payment of 400.00 has been released to you.	f	2026-10-01 07:15:06.789282+00	\N
120	9	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'Tiffany Style Lamp' is now resolved.	f	2026-10-01 07:15:06.789282+00	\N
121	5	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'Tiffany Style Lamp' is now resolved.	f	2026-10-01 07:15:06.789282+00	\N
122	6	LISTING_MODERATED	Listing approved	Your listing 'Emerald Cut Sapphire Pendant' was approved.	f	2026-10-01 07:15:06.813777+00	\N
123	10	BID_CONFIRMED	Bid placed	Your bid of 950.00 on 'Emerald Cut Sapphire Pendant' was accepted.	f	2026-10-01 07:15:06.824567+00	\N
124	6	AUCTION_EXTENDED	Auction extended	A late bid on 'Emerald Cut Sapphire Pendant' extended the closing time to 2026-10-01T07:27:06.445749+00:00.	f	2026-10-01 07:15:06.824567+00	\N
125	10	AUCTION_WON	You won!	You won 'Emerald Cut Sapphire Pendant' for 950.00. Payment instructions to follow.	f	2026-10-01 07:15:06.849371+00	\N
126	6	AUCTION_SOLD	Your item sold	'Emerald Cut Sapphire Pendant' sold for 950.00.	f	2026-10-01 07:15:06.849371+00	\N
127	6	PAYMENT_RECEIVED	Payment received	Payment of 950.00 has been placed in escrow for your sale.	f	2026-10-01 07:15:06.875575+00	\N
128	6	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Emerald Cut Sapphire Pendant'.	f	2026-10-01 07:15:06.894528+00	\N
129	6	ESCROW_RELEASED	Funds released	The escrowed payment of 950.00 has been released to you.	f	2026-10-01 07:15:06.909301+00	\N
130	10	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'Emerald Cut Sapphire Pendant' is now resolved.	f	2026-10-01 07:15:06.909301+00	\N
131	6	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'Emerald Cut Sapphire Pendant' is now resolved.	f	2026-10-01 07:15:06.909301+00	\N
132	10	BID_CONFIRMED	Bid placed	Your bid of 210 on 'Limited Edition Lithograph' was accepted.	f	2026-10-01 07:23:09.867935+00	\N
133	7	OUTBID	You've been outbid	Someone placed a higher bid on 'Limited Edition Lithograph'. The new price is 210.	f	2026-10-01 07:23:09.867935+00	\N
134	10	LISTING_MODERATED	Listing rejected	Your listing 'Golder Brooch' was rejected. Reason: duplicate	f	2026-10-01 07:27:06.718166+00	\N
135	10	LISTING_MODERATED	Listing approved	Your listing 'Golder Brooch' was approved.	f	2026-10-01 07:27:08.715756+00	\N
136	10	AUCTION_WON	You won!	You won 'Limited Edition Lithograph' for 210.00. Payment instructions to follow.	f	2026-10-01 07:29:04.959516+00	\N
137	6	AUCTION_SOLD	Your item sold	'Limited Edition Lithograph' sold for 210.00.	f	2026-10-01 07:29:04.959516+00	\N
138	7	AUCTION_LOST	Auction ended	'Limited Edition Lithograph' has closed. You did not win this item.	f	2026-10-01 07:29:04.959516+00	\N
139	5	AUCTION_NO_BIDS	No bids received	'Victorian Silver Tea Set' closed with no bids.	f	2026-10-01 08:15:06.596689+00	\N
140	6	AUCTION_NO_BIDS	No bids received	'First Edition Dickens Novel' closed with no bids.	f	2026-10-01 08:15:07.011415+00	\N
141	8	AUCTION_WON	You won!	You won 'Art Deco Sapphire Brooch' for 85.00. Payment instructions to follow.	f	2026-10-01 08:15:07.028496+00	\N
142	4	AUCTION_SOLD	Your item sold	'Art Deco Sapphire Brooch' sold for 85.00.	f	2026-10-01 08:15:07.028496+00	\N
143	7	AUCTION_LOST	Auction ended	'Art Deco Sapphire Brooch' has closed. You did not win this item.	f	2026-10-01 08:15:07.028496+00	\N
144	9	AUCTION_WON	You won!	You won 'Qing Dynasty Porcelain Vase' for 625.00. Payment instructions to follow.	f	2026-10-01 08:15:07.048116+00	\N
145	10	AUCTION_SOLD	Your item sold	'Qing Dynasty Porcelain Vase' sold for 625.00.	f	2026-10-01 08:15:07.048116+00	\N
146	7	AUCTION_LOST	Auction ended	'Qing Dynasty Porcelain Vase' has closed. You did not win this item.	f	2026-10-01 08:15:07.048116+00	\N
147	10	AUCTION_WON	You won!	You won 'Stradivarius-style Violin' for 1250.00. Payment instructions to follow.	f	2026-10-01 08:15:07.065336+00	\N
148	5	AUCTION_SOLD	Your item sold	'Stradivarius-style Violin' sold for 1250.00.	f	2026-10-01 08:15:07.065336+00	\N
149	8	AUCTION_LOST	Auction ended	'Stradivarius-style Violin' has closed. You did not win this item.	f	2026-10-01 08:15:07.065336+00	\N
150	6	LISTING_MODERATED	Listing rejected	Your listing 'Unverified Oil Painting' was rejected. Reason: Unable to verify authenticity	f	2026-10-22 12:25:05.427211+00	\N
151	4	LISTING_MODERATED	Listing suspended	Your listing 'Antique Firearm Collection' was suspended. Reason: Requires additional compliance review	f	2026-10-22 12:25:05.46174+00	\N
152	5	LISTING_MODERATED	Listing approved	Your listing 'Victorian Silver Tea Set' was approved.	f	2026-10-22 12:25:05.484986+00	\N
153	6	LISTING_MODERATED	Listing approved	Your listing 'First Edition Dickens Novel' was approved.	f	2026-10-22 12:25:05.503917+00	\N
154	4	LISTING_MODERATED	Listing approved	Your listing 'Art Deco Sapphire Brooch' was approved.	f	2026-10-22 12:25:05.521703+00	\N
155	7	BID_CONFIRMED	Bid placed	Your bid of 80.00 on 'Art Deco Sapphire Brooch' was accepted.	f	2026-10-22 12:25:05.531173+00	\N
156	8	BID_CONFIRMED	Bid placed	Your bid of 85.00 on 'Art Deco Sapphire Brooch' was accepted.	f	2026-10-22 12:25:05.557249+00	\N
157	7	OUTBID	You've been outbid	Someone placed a higher bid on 'Art Deco Sapphire Brooch'. The new price is 85.00.	f	2026-10-22 12:25:05.557249+00	\N
158	10	LISTING_MODERATED	Listing approved	Your listing 'Qing Dynasty Porcelain Vase' was approved.	f	2026-10-22 12:25:05.581261+00	\N
159	7	BID_CONFIRMED	Bid placed	Your bid of 600.00 on 'Qing Dynasty Porcelain Vase' was accepted.	f	2026-10-22 12:25:05.590874+00	\N
160	9	BID_CONFIRMED	Bid placed	Your bid of 625.00 on 'Qing Dynasty Porcelain Vase' was accepted.	f	2026-10-22 12:25:05.602886+00	\N
161	7	OUTBID	You've been outbid	Someone placed a higher bid on 'Qing Dynasty Porcelain Vase'. The new price is 625.00.	f	2026-10-22 12:25:05.602886+00	\N
162	5	LISTING_MODERATED	Listing approved	Your listing 'Stradivarius-style Violin' was approved.	f	2026-10-22 12:25:05.62579+00	\N
163	8	BID_CONFIRMED	Bid placed	Your bid of 1200.00 on 'Stradivarius-style Violin' was accepted.	f	2026-10-22 12:25:05.636571+00	\N
164	10	BID_CONFIRMED	Bid placed	Your bid of 1250.00 on 'Stradivarius-style Violin' was accepted.	f	2026-10-22 12:25:05.650545+00	\N
165	8	OUTBID	You've been outbid	Someone placed a higher bid on 'Stradivarius-style Violin'. The new price is 1250.00.	f	2026-10-22 12:25:05.650545+00	\N
166	6	LISTING_MODERATED	Listing approved	Your listing 'Limited Edition Lithograph' was approved.	f	2026-10-22 12:25:05.675752+00	\N
167	7	BID_CONFIRMED	Bid placed	Your bid of 200.00 on 'Limited Edition Lithograph' was accepted.	f	2026-10-22 12:25:05.685024+00	\N
168	6	AUCTION_EXTENDED	Auction extended	A late bid on 'Limited Edition Lithograph' extended the closing time to 2026-10-22T12:39:05.720073+00:00.	f	2026-10-22 12:25:05.685024+00	\N
169	4	LISTING_MODERATED	Listing approved	Your listing 'Unsold Victorian Clock' was approved.	f	2026-10-22 12:25:05.707215+00	\N
170	4	AUCTION_NO_BIDS	No bids received	'Unsold Victorian Clock' closed with no bids.	f	2026-10-22 12:25:05.7229+00	\N
171	5	LISTING_MODERATED	Listing approved	Your listing 'Rare Gold Coin Collection' was approved.	f	2026-10-22 12:25:05.747395+00	\N
172	8	BID_CONFIRMED	Bid placed	Your bid of 50.00 on 'Rare Gold Coin Collection' was accepted.	f	2026-10-22 12:25:05.757162+00	\N
173	5	AUCTION_EXTENDED	Auction extended	A late bid on 'Rare Gold Coin Collection' extended the closing time to 2026-10-22T12:37:05.792486+00:00.	f	2026-10-22 12:25:05.757162+00	\N
174	5	AUCTION_RESERVE_NOT_MET	Reserve not met	'Rare Gold Coin Collection' closed without meeting the reserve price.	f	2026-10-22 12:25:05.77565+00	\N
175	8	AUCTION_LOST	Auction ended	'Rare Gold Coin Collection' has closed. You did not win this item.	f	2026-10-22 12:25:05.77565+00	\N
176	6	LISTING_MODERATED	Listing approved	Your listing 'Persian Silk Rug' was approved.	f	2026-10-22 12:25:05.79631+00	\N
177	9	BID_CONFIRMED	Bid placed	Your bid of 300.00 on 'Persian Silk Rug' was accepted.	f	2026-10-22 12:25:05.807536+00	\N
178	6	AUCTION_EXTENDED	Auction extended	A late bid on 'Persian Silk Rug' extended the closing time to 2026-10-22T12:37:05.840984+00:00.	f	2026-10-22 12:25:05.807536+00	\N
179	6	AUCTION_RESERVE_NOT_MET	Reserve not met	'Persian Silk Rug' closed without meeting the reserve price.	f	2026-10-22 12:25:05.826052+00	\N
180	9	AUCTION_LOST	Auction ended	'Persian Silk Rug' has closed. You did not win this item.	f	2026-10-22 12:25:05.826052+00	\N
181	10	LISTING_MODERATED	Listing approved	Your listing 'Regency Dining Chairs' was approved.	f	2026-10-22 12:25:05.845243+00	\N
182	7	BID_CONFIRMED	Bid placed	Your bid of 350.00 on 'Regency Dining Chairs' was accepted.	f	2026-10-22 12:25:05.854255+00	\N
183	10	AUCTION_EXTENDED	Auction extended	A late bid on 'Regency Dining Chairs' extended the closing time to 2026-10-22T12:37:05.891147+00:00.	f	2026-10-22 12:25:05.854255+00	\N
184	7	AUCTION_WON	You won!	You won 'Regency Dining Chairs' for 350.00. Payment instructions to follow.	f	2026-10-22 12:25:05.872819+00	\N
185	10	AUCTION_SOLD	Your item sold	'Regency Dining Chairs' sold for 350.00.	f	2026-10-22 12:25:05.872819+00	\N
186	10	PAYMENT_RECEIVED	Payment received	Payment of 350.00 has been placed in escrow for your sale.	f	2026-10-22 12:25:05.88459+00	\N
187	4	LISTING_MODERATED	Listing approved	Your listing 'Art Nouveau Hair Comb' was approved.	f	2026-10-22 12:25:05.909187+00	\N
188	8	BID_CONFIRMED	Bid placed	Your bid of 150.00 on 'Art Nouveau Hair Comb' was accepted.	f	2026-10-22 12:25:05.91819+00	\N
189	4	AUCTION_EXTENDED	Auction extended	A late bid on 'Art Nouveau Hair Comb' extended the closing time to 2026-10-22T12:37:05.954609+00:00.	f	2026-10-22 12:25:05.91819+00	\N
190	8	AUCTION_WON	You won!	You won 'Art Nouveau Hair Comb' for 150.00. Payment instructions to follow.	f	2026-10-22 12:25:05.938018+00	\N
191	4	AUCTION_SOLD	Your item sold	'Art Nouveau Hair Comb' sold for 150.00.	f	2026-10-22 12:25:05.938018+00	\N
192	4	PAYMENT_RECEIVED	Payment received	Payment of 150.00 has been placed in escrow for your sale.	f	2026-10-22 12:25:05.949115+00	\N
193	5	LISTING_MODERATED	Listing approved	Your listing 'Impressionist Landscape Study' was approved.	f	2026-10-22 12:25:05.968391+00	\N
194	9	BID_CONFIRMED	Bid placed	Your bid of 700.00 on 'Impressionist Landscape Study' was accepted.	f	2026-10-22 12:25:05.978105+00	\N
195	5	AUCTION_EXTENDED	Auction extended	A late bid on 'Impressionist Landscape Study' extended the closing time to 2026-10-22T12:37:06.013676+00:00.	f	2026-10-22 12:25:05.978105+00	\N
196	9	AUCTION_WON	You won!	You won 'Impressionist Landscape Study' for 700.00. Payment instructions to follow.	f	2026-10-22 12:25:05.997629+00	\N
197	5	AUCTION_SOLD	Your item sold	'Impressionist Landscape Study' sold for 700.00.	f	2026-10-22 12:25:05.997629+00	\N
198	5	PAYMENT_RECEIVED	Payment received	Payment of 700.00 has been placed in escrow for your sale.	f	2026-10-22 12:25:06.010305+00	\N
199	5	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Impressionist Landscape Study'.	f	2026-10-22 12:25:06.021126+00	\N
200	6	LISTING_MODERATED	Listing approved	Your listing '18th Century Pocket Watch' was approved.	f	2026-10-22 12:25:06.042672+00	\N
201	10	BID_CONFIRMED	Bid placed	Your bid of 800.00 on '18th Century Pocket Watch' was accepted.	f	2026-10-22 12:25:06.051825+00	\N
202	6	AUCTION_EXTENDED	Auction extended	A late bid on '18th Century Pocket Watch' extended the closing time to 2026-10-22T12:37:06.088602+00:00.	f	2026-10-22 12:25:06.051825+00	\N
203	10	AUCTION_WON	You won!	You won '18th Century Pocket Watch' for 800.00. Payment instructions to follow.	f	2026-10-22 12:25:06.070717+00	\N
204	6	AUCTION_SOLD	Your item sold	'18th Century Pocket Watch' sold for 800.00.	f	2026-10-22 12:25:06.070717+00	\N
205	6	PAYMENT_RECEIVED	Payment received	Payment of 800.00 has been placed in escrow for your sale.	f	2026-10-22 12:25:06.082456+00	\N
206	6	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding '18th Century Pocket Watch'.	f	2026-10-22 12:25:06.093713+00	\N
207	10	LISTING_MODERATED	Listing approved	Your listing 'Delft Blue Porcelain Plate' was approved.	f	2026-10-22 12:25:06.111948+00	\N
208	7	BID_CONFIRMED	Bid placed	Your bid of 120.00 on 'Delft Blue Porcelain Plate' was accepted.	f	2026-10-22 12:25:06.123733+00	\N
209	10	AUCTION_EXTENDED	Auction extended	A late bid on 'Delft Blue Porcelain Plate' extended the closing time to 2026-10-22T12:37:06.157761+00:00.	f	2026-10-22 12:25:06.123733+00	\N
210	7	AUCTION_WON	You won!	You won 'Delft Blue Porcelain Plate' for 120.00. Payment instructions to follow.	f	2026-10-22 12:25:06.144298+00	\N
211	10	AUCTION_SOLD	Your item sold	'Delft Blue Porcelain Plate' sold for 120.00.	f	2026-10-22 12:25:06.144298+00	\N
212	10	PAYMENT_RECEIVED	Payment received	Payment of 120.00 has been placed in escrow for your sale.	f	2026-10-22 12:25:06.155293+00	\N
213	10	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Delft Blue Porcelain Plate'.	f	2026-10-22 12:25:06.166563+00	\N
214	4	LISTING_MODERATED	Listing approved	Your listing 'Roman Silver Denarius' was approved.	f	2026-10-22 12:25:06.189479+00	\N
215	8	BID_CONFIRMED	Bid placed	Your bid of 250.00 on 'Roman Silver Denarius' was accepted.	f	2026-10-22 12:25:06.198596+00	\N
216	4	AUCTION_EXTENDED	Auction extended	A late bid on 'Roman Silver Denarius' extended the closing time to 2026-10-22T12:37:06.232843+00:00.	f	2026-10-22 12:25:06.198596+00	\N
217	8	AUCTION_WON	You won!	You won 'Roman Silver Denarius' for 250.00. Payment instructions to follow.	f	2026-10-22 12:25:06.226794+00	\N
218	4	AUCTION_SOLD	Your item sold	'Roman Silver Denarius' sold for 250.00.	f	2026-10-22 12:25:06.226794+00	\N
219	4	PAYMENT_RECEIVED	Payment received	Payment of 250.00 has been placed in escrow for your sale.	f	2026-10-22 12:25:06.251694+00	\N
220	4	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Roman Silver Denarius'.	f	2026-10-22 12:25:06.276778+00	\N
221	8	DISPUTE_UPDATED	Dispute under review	The dispute regarding 'Roman Silver Denarius' is now under review.	f	2026-10-22 12:25:06.296813+00	\N
222	4	DISPUTE_UPDATED	Dispute under review	The dispute regarding 'Roman Silver Denarius' is now under review.	f	2026-10-22 12:25:06.296813+00	\N
223	5	LISTING_MODERATED	Listing approved	Your listing 'Hand-Knotted Kilim Rug' was approved.	f	2026-10-22 12:25:06.33592+00	\N
224	9	BID_CONFIRMED	Bid placed	Your bid of 450.00 on 'Hand-Knotted Kilim Rug' was accepted.	f	2026-10-22 12:25:06.345759+00	\N
225	5	AUCTION_EXTENDED	Auction extended	A late bid on 'Hand-Knotted Kilim Rug' extended the closing time to 2026-10-22T12:37:06.376317+00:00.	f	2026-10-22 12:25:06.345759+00	\N
226	9	AUCTION_WON	You won!	You won 'Hand-Knotted Kilim Rug' for 450.00. Payment instructions to follow.	f	2026-10-22 12:25:06.364319+00	\N
227	5	AUCTION_SOLD	Your item sold	'Hand-Knotted Kilim Rug' sold for 450.00.	f	2026-10-22 12:25:06.364319+00	\N
228	5	PAYMENT_RECEIVED	Payment received	Payment of 450.00 has been placed in escrow for your sale.	f	2026-10-22 12:25:06.375748+00	\N
229	5	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Hand-Knotted Kilim Rug'.	f	2026-10-22 12:25:06.386305+00	\N
230	9	DISPUTE_UPDATED	Dispute under review	The dispute regarding 'Hand-Knotted Kilim Rug' is now under review.	f	2026-10-22 12:25:06.396481+00	\N
231	5	DISPUTE_UPDATED	Dispute under review	The dispute regarding 'Hand-Knotted Kilim Rug' is now under review.	f	2026-10-22 12:25:06.396481+00	\N
232	6	LISTING_MODERATED	Listing approved	Your listing 'Vintage Brass Trumpet' was approved.	f	2026-10-22 12:25:06.41715+00	\N
233	10	BID_CONFIRMED	Bid placed	Your bid of 300.00 on 'Vintage Brass Trumpet' was accepted.	f	2026-10-22 12:25:06.426149+00	\N
234	6	AUCTION_EXTENDED	Auction extended	A late bid on 'Vintage Brass Trumpet' extended the closing time to 2026-10-22T12:37:06.462656+00:00.	f	2026-10-22 12:25:06.426149+00	\N
235	10	AUCTION_WON	You won!	You won 'Vintage Brass Trumpet' for 300.00. Payment instructions to follow.	f	2026-10-22 12:25:06.444332+00	\N
236	6	AUCTION_SOLD	Your item sold	'Vintage Brass Trumpet' sold for 300.00.	f	2026-10-22 12:25:06.444332+00	\N
237	6	PAYMENT_RECEIVED	Payment received	Payment of 300.00 has been placed in escrow for your sale.	f	2026-10-22 12:25:06.455716+00	\N
238	6	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Vintage Brass Trumpet'.	f	2026-10-22 12:25:06.4659+00	\N
239	10	DISPUTE_UPDATED	Dispute under review	The dispute regarding 'Vintage Brass Trumpet' is now under review.	f	2026-10-22 12:25:06.475697+00	\N
240	6	DISPUTE_UPDATED	Dispute under review	The dispute regarding 'Vintage Brass Trumpet' is now under review.	f	2026-10-22 12:25:06.475697+00	\N
241	10	LISTING_MODERATED	Listing approved	Your listing 'First Folio Facsimile' was approved.	f	2026-10-22 12:25:06.496227+00	\N
242	7	BID_CONFIRMED	Bid placed	Your bid of 600.00 on 'First Folio Facsimile' was accepted.	f	2026-10-22 12:25:06.506038+00	\N
243	10	AUCTION_EXTENDED	Auction extended	A late bid on 'First Folio Facsimile' extended the closing time to 2026-10-22T12:37:06.541237+00:00.	f	2026-10-22 12:25:06.506038+00	\N
244	7	AUCTION_WON	You won!	You won 'First Folio Facsimile' for 600.00. Payment instructions to follow.	f	2026-10-22 12:25:06.523731+00	\N
245	10	AUCTION_SOLD	Your item sold	'First Folio Facsimile' sold for 600.00.	f	2026-10-22 12:25:06.523731+00	\N
246	10	PAYMENT_RECEIVED	Payment received	Payment of 600.00 has been placed in escrow for your sale.	f	2026-10-22 12:25:06.534316+00	\N
247	10	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'First Folio Facsimile'.	f	2026-10-22 12:25:06.544607+00	\N
248	7	ESCROW_REFUNDED	Payment refunded	Your payment of 600.00 has been refunded.	f	2026-10-22 12:25:06.554031+00	\N
249	10	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'First Folio Facsimile' is now resolved.	f	2026-10-22 12:25:06.554031+00	\N
250	7	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'First Folio Facsimile' is now resolved.	f	2026-10-22 12:25:06.554031+00	\N
251	4	LISTING_MODERATED	Listing approved	Your listing 'WWII Medal Set' was approved.	f	2026-10-22 12:25:06.578766+00	\N
252	8	BID_CONFIRMED	Bid placed	Your bid of 350.00 on 'WWII Medal Set' was accepted.	f	2026-10-22 12:25:06.587699+00	\N
253	4	AUCTION_EXTENDED	Auction extended	A late bid on 'WWII Medal Set' extended the closing time to 2026-10-22T12:37:06.623639+00:00.	f	2026-10-22 12:25:06.587699+00	\N
254	8	AUCTION_WON	You won!	You won 'WWII Medal Set' for 350.00. Payment instructions to follow.	f	2026-10-22 12:25:06.606714+00	\N
255	4	AUCTION_SOLD	Your item sold	'WWII Medal Set' sold for 350.00.	f	2026-10-22 12:25:06.606714+00	\N
256	4	PAYMENT_RECEIVED	Payment received	Payment of 350.00 has been placed in escrow for your sale.	f	2026-10-22 12:25:06.618274+00	\N
257	4	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'WWII Medal Set'.	f	2026-10-22 12:25:06.628856+00	\N
258	8	ESCROW_REFUNDED	Payment refunded	Your payment of 350.00 has been refunded.	f	2026-10-22 12:25:06.638504+00	\N
259	8	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'WWII Medal Set' is now resolved.	f	2026-10-22 12:25:06.638504+00	\N
260	4	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'WWII Medal Set' is now resolved.	f	2026-10-22 12:25:06.638504+00	\N
261	5	LISTING_MODERATED	Listing approved	Your listing 'Tiffany Style Lamp' was approved.	f	2026-10-22 12:25:06.660848+00	\N
262	9	BID_CONFIRMED	Bid placed	Your bid of 400.00 on 'Tiffany Style Lamp' was accepted.	f	2026-10-22 12:25:06.67028+00	\N
263	5	AUCTION_EXTENDED	Auction extended	A late bid on 'Tiffany Style Lamp' extended the closing time to 2026-10-22T12:37:06.705988+00:00.	f	2026-10-22 12:25:06.67028+00	\N
264	9	AUCTION_WON	You won!	You won 'Tiffany Style Lamp' for 400.00. Payment instructions to follow.	f	2026-10-22 12:25:06.688968+00	\N
265	5	AUCTION_SOLD	Your item sold	'Tiffany Style Lamp' sold for 400.00.	f	2026-10-22 12:25:06.688968+00	\N
266	5	PAYMENT_RECEIVED	Payment received	Payment of 400.00 has been placed in escrow for your sale.	f	2026-10-22 12:25:06.700185+00	\N
267	5	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Tiffany Style Lamp'.	f	2026-10-22 12:25:06.710378+00	\N
268	5	ESCROW_RELEASED	Funds released	The escrowed payment of 400.00 has been released to you.	f	2026-10-22 12:25:06.719889+00	\N
269	9	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'Tiffany Style Lamp' is now resolved.	f	2026-10-22 12:25:06.719889+00	\N
270	5	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'Tiffany Style Lamp' is now resolved.	f	2026-10-22 12:25:06.719889+00	\N
271	6	LISTING_MODERATED	Listing approved	Your listing 'Emerald Cut Sapphire Pendant' was approved.	f	2026-10-22 12:25:06.744693+00	\N
272	10	BID_CONFIRMED	Bid placed	Your bid of 950.00 on 'Emerald Cut Sapphire Pendant' was accepted.	f	2026-10-22 12:25:06.755935+00	\N
273	6	AUCTION_EXTENDED	Auction extended	A late bid on 'Emerald Cut Sapphire Pendant' extended the closing time to 2026-10-22T12:37:06.788579+00:00.	f	2026-10-22 12:25:06.755935+00	\N
274	10	AUCTION_WON	You won!	You won 'Emerald Cut Sapphire Pendant' for 950.00. Payment instructions to follow.	f	2026-10-22 12:25:06.774361+00	\N
275	6	AUCTION_SOLD	Your item sold	'Emerald Cut Sapphire Pendant' sold for 950.00.	f	2026-10-22 12:25:06.774361+00	\N
276	6	PAYMENT_RECEIVED	Payment received	Payment of 950.00 has been placed in escrow for your sale.	f	2026-10-22 12:25:06.78505+00	\N
277	6	DISPUTE_RAISED	A dispute has been raised	A dispute was raised regarding 'Emerald Cut Sapphire Pendant'.	f	2026-10-22 12:25:06.796082+00	\N
278	6	ESCROW_RELEASED	Funds released	The escrowed payment of 950.00 has been released to you.	f	2026-10-22 12:25:06.805668+00	\N
279	10	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'Emerald Cut Sapphire Pendant' is now resolved.	f	2026-10-22 12:25:06.805668+00	\N
280	6	DISPUTE_UPDATED	Dispute resolved	The dispute regarding 'Emerald Cut Sapphire Pendant' is now resolved.	f	2026-10-22 12:25:06.805668+00	\N
281	10	AUCTION_NO_BIDS	No bids received	'Golder Brooch' closed with no bids.	f	2026-10-22 12:25:31.31321+00	\N
282	7	BID_CONFIRMED	Bid placed	Your bid of 250.12345 on 'Victorian Silver Tea Set' was accepted.	f	2026-10-22 12:27:38.127499+00	\N
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payments (payment_id, auction_result_id, payer_id, payee_id, amount, payment_status, escrow_status, paid_at, released_at, refunded_at, created_at, updated_at) FROM stdin;
1	4	7	10	350.00	Paid	Held	2026-10-01 07:15:05.661757+00	\N	\N	2026-10-01 07:15:05.934392+00	2026-10-01 07:15:05.934392+00
2	5	8	4	150.00	Paid	Held	2026-10-01 07:15:05.723243+00	\N	\N	2026-10-01 07:15:06.004242+00	2026-10-01 07:15:06.004242+00
3	6	9	5	700.00	Paid	Held	2026-10-01 07:15:05.784241+00	\N	\N	2026-10-01 07:15:06.071792+00	2026-10-01 07:15:06.071792+00
4	7	10	6	800.00	Paid	Held	2026-10-01 07:15:05.856336+00	\N	\N	2026-10-01 07:15:06.150611+00	2026-10-01 07:15:06.150611+00
5	8	7	10	120.00	Paid	Held	2026-10-01 07:15:05.929112+00	\N	\N	2026-10-01 07:15:06.229725+00	2026-10-01 07:15:06.229725+00
6	9	8	4	250.00	Paid	Held	2026-10-01 07:15:06.000121+00	\N	\N	2026-10-01 07:15:06.304989+00	2026-10-01 07:15:06.304989+00
7	10	9	5	450.00	Paid	Held	2026-10-01 07:15:06.086035+00	\N	\N	2026-10-01 07:15:06.403812+00	2026-10-01 07:15:06.403812+00
8	11	10	6	300.00	Paid	Held	2026-10-01 07:15:06.166713+00	\N	\N	2026-10-01 07:15:06.492422+00	2026-10-01 07:15:06.492422+00
9	12	7	10	600.00	Paid	Refunded	2026-10-01 07:15:06.248571+00	\N	2026-10-01 07:15:06.270865+00	2026-10-01 07:15:06.582547+00	2026-10-01 07:15:06.606923+00
10	13	8	4	350.00	Paid	Refunded	2026-10-01 07:15:06.33285+00	\N	2026-10-01 07:15:06.352866+00	2026-10-01 07:15:06.675591+00	2026-10-01 07:15:06.69717+00
11	14	9	5	400.00	Paid	Released	2026-10-01 07:15:06.416691+00	2026-10-01 07:15:06.437156+00	\N	2026-10-01 07:15:06.767403+00	2026-10-01 07:15:06.789282+00
12	15	10	6	950.00	Paid	Released	2026-10-01 07:15:06.518186+00	2026-10-01 07:15:06.545572+00	\N	2026-10-01 07:15:06.875575+00	2026-10-01 07:15:06.909301+00
13	25	7	10	350.00	Paid	Held	2026-10-22 12:25:05.947223+00	\N	\N	2026-10-22 12:25:05.88459+00	2026-10-22 12:25:05.88459+00
14	26	8	4	150.00	Paid	Held	2026-10-22 12:25:06.00829+00	\N	\N	2026-10-22 12:25:05.949115+00	2026-10-22 12:25:05.949115+00
15	27	9	5	700.00	Paid	Held	2026-10-22 12:25:06.069475+00	\N	\N	2026-10-22 12:25:06.010305+00	2026-10-22 12:25:06.010305+00
16	28	10	6	800.00	Paid	Held	2026-10-22 12:25:06.14185+00	\N	\N	2026-10-22 12:25:06.082456+00	2026-10-22 12:25:06.082456+00
17	29	7	10	120.00	Paid	Held	2026-10-22 12:25:06.214464+00	\N	\N	2026-10-22 12:25:06.155293+00	2026-10-22 12:25:06.155293+00
18	30	8	4	250.00	Paid	Held	2026-10-22 12:25:06.317804+00	\N	\N	2026-10-22 12:25:06.251694+00	2026-10-22 12:25:06.251694+00
19	31	9	5	450.00	Paid	Held	2026-10-22 12:25:06.434654+00	\N	\N	2026-10-22 12:25:06.375748+00	2026-10-22 12:25:06.375748+00
20	32	10	6	300.00	Paid	Held	2026-10-22 12:25:06.514334+00	\N	\N	2026-10-22 12:25:06.455716+00	2026-10-22 12:25:06.455716+00
21	33	7	10	600.00	Paid	Refunded	2026-10-22 12:25:06.593095+00	\N	2026-10-22 12:25:06.612795+00	2026-10-22 12:25:06.534316+00	2026-10-22 12:25:06.554031+00
22	34	8	4	350.00	Paid	Refunded	2026-10-22 12:25:06.677122+00	\N	2026-10-22 12:25:06.697308+00	2026-10-22 12:25:06.618274+00	2026-10-22 12:25:06.638504+00
23	35	9	5	400.00	Paid	Released	2026-10-22 12:25:06.758736+00	2026-10-22 12:25:06.779208+00	\N	2026-10-22 12:25:06.700185+00	2026-10-22 12:25:06.719889+00
24	36	10	6	950.00	Paid	Released	2026-10-22 12:25:06.843741+00	2026-10-22 12:25:06.864372+00	\N	2026-10-22 12:25:06.78505+00	2026-10-22 12:25:06.805668+00
\.


--
-- Data for Name: platform_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.platform_config (config_id, min_bid_increment, anti_sniping_window_minutes, anti_sniping_extension_minutes, max_anti_sniping_extensions, platform_fee_percent, updated_at, updated_by) FROM stdin;
1	1.00	5	10	\N	0.00	2026-10-01 07:15:00.905589+00	\N
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (role_id, role_name, description) FROM stdin;
1	SELLER	Can list items for auction
2	BIDDER	Can place bids on auctions
3	MODERATOR	Reviews listings, reports, and disputes
4	ADMIN	Full platform administration
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_roles (user_id, role_id, assigned_at) FROM stdin;
1	4	2026-10-01 07:15:02.686831+00
2	3	2026-10-01 07:15:02.686831+00
3	3	2026-10-01 07:15:02.686831+00
4	1	2026-10-01 07:15:02.686831+00
5	1	2026-10-01 07:15:02.686831+00
6	1	2026-10-01 07:15:02.686831+00
7	2	2026-10-01 07:15:02.686831+00
8	2	2026-10-01 07:15:02.686831+00
9	2	2026-10-01 07:15:02.686831+00
10	1	2026-10-01 07:15:02.686831+00
10	2	2026-10-01 07:15:02.686831+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (user_id, first_name, last_name, email, password_hash, phone, is_verified, status, created_at, updated_at) FROM stdin;
1	Ada	Admin	admin@demo.com	$2b$12$IG9j3zTKUzWEBNVxCCUGse1.xeITo/nOWxQe5j9/V6mpahGjLBD4O	\N	t	Active	2026-10-01 07:15:02.686831+00	2026-10-01 07:15:02.686831+00
2	Mo	Deratorz	moderator@demo.com	$2b$12$K0dOa9jTGQvIZc0KS0JzneCrqmXXEtqNBjgRbc7ERbOsqeYlGhf3i	\N	t	Active	2026-10-01 07:15:02.686831+00	2026-10-01 07:15:02.686831+00
3	Rae	Reviewer	moderator2@demo.com	$2b$12$zoh3P78ywKzSSwDpxW9qU.yfuV900ZnTj0SdefwJxalyAy3EdCpzG	\N	t	Active	2026-10-01 07:15:02.686831+00	2026-10-01 07:15:02.686831+00
4	Sam	Seller	seller@demo.com	$2b$12$K/pNjxV9CT8RZYtz.1lMoOGh7JVGEbM4NpWxt3YWJi.r9BhJzGlIG	\N	t	Active	2026-10-01 07:15:02.686831+00	2026-10-01 07:15:02.686831+00
5	Sally	Smith	seller2@demo.com	$2b$12$zo4RAT0kGG0sAEqfZ4doj.aA7nbfTJBM2N6VjrFDtnGR14DXV.UeS	\N	t	Active	2026-10-01 07:15:02.686831+00	2026-10-01 07:15:02.686831+00
6	Steve	Stone	seller3@demo.com	$2b$12$MaUnbBJEJdOlMNMIGg.kBObgeEuFbxT6YCKGni/L3xG.NdpCvgXoq	\N	t	Active	2026-10-01 07:15:02.686831+00	2026-10-01 07:15:02.686831+00
7	Bea	Bidder	bidder@demo.com	$2b$12$T4em.6WhuUaDfX/Vow9Jq.iHrccDb9VKECNf.WhzdyX1o0rTMrevS	\N	t	Active	2026-10-01 07:15:02.686831+00	2026-10-01 07:15:02.686831+00
8	Ben	Bidderson	bidder2@demo.com	$2b$12$A16iJaUKRv4NpQkwaY67z.PZgQzWYEcfizyt2pVpQEh8H7pFLgugy	\N	t	Active	2026-10-01 07:15:02.686831+00	2026-10-01 07:15:02.686831+00
9	Bill	Byers	bidder3@demo.com	$2b$12$z4IRe0UIPbhBlDlWD0RAnuVVbwpSjhDYLswxTLrN0kO0oMtzlqcCq	\N	t	Active	2026-10-01 07:15:02.686831+00	2026-10-01 07:15:02.686831+00
10	Robin	Rivera	sellerbidder@demo.com	$2b$12$Ii3uOTLnXP9Z5uy9NjgEROVw7U0LSWCvpL9AsPBVAejnVWS6rRb36	\N	t	Active	2026-10-01 07:15:02.686831+00	2026-10-01 07:15:02.686831+00
\.


--
-- Name: auction_results_result_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auction_results_result_id_seq', 37, true);


--
-- Name: audit_logs_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_logs_log_id_seq', 199, true);


--
-- Name: bids_bid_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.bids_bid_id_seq', 44, true);


--
-- Name: categories_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.categories_category_id_seq', 10, true);


--
-- Name: disputes_dispute_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.disputes_dispute_id_seq', 20, true);


--
-- Name: listing_images_image_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.listing_images_image_id_seq', 51, true);


--
-- Name: listings_listing_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.listings_listing_id_seq', 52, true);


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notifications_notification_id_seq', 282, true);


--
-- Name: payments_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.payments_payment_id_seq', 24, true);


--
-- Name: platform_config_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.platform_config_config_id_seq', 1, false);


--
-- Name: roles_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.roles_role_id_seq', 4, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_user_id_seq', 12, true);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: auction_results auction_results_listing_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_results
    ADD CONSTRAINT auction_results_listing_id_key UNIQUE (listing_id);


--
-- Name: auction_results auction_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_results
    ADD CONSTRAINT auction_results_pkey PRIMARY KEY (result_id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (log_id);


--
-- Name: bids bids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bids
    ADD CONSTRAINT bids_pkey PRIMARY KEY (bid_id);


--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- Name: disputes disputes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputes
    ADD CONSTRAINT disputes_pkey PRIMARY KEY (dispute_id);


--
-- Name: listing_images listing_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listing_images
    ADD CONSTRAINT listing_images_pkey PRIMARY KEY (image_id);


--
-- Name: listings listings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listings
    ADD CONSTRAINT listings_pkey PRIMARY KEY (listing_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- Name: payments payments_auction_result_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_auction_result_id_key UNIQUE (auction_result_id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (payment_id);


--
-- Name: platform_config platform_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_config
    ADD CONSTRAINT platform_config_pkey PRIMARY KEY (config_id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- Name: roles roles_role_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_role_name_key UNIQUE (role_name);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: ix_audit_logs_action_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_logs_action_created_at ON public.audit_logs USING btree (action, created_at);


--
-- Name: ix_audit_logs_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_logs_entity ON public.audit_logs USING btree (entity_type, entity_id, created_at);


--
-- Name: ix_bids_bidder_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_bids_bidder_id ON public.bids USING btree (bidder_id);


--
-- Name: ix_bids_listing_amount; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_bids_listing_amount ON public.bids USING btree (listing_id, amount);


--
-- Name: ix_bids_listing_placed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_bids_listing_placed_at ON public.bids USING btree (listing_id, placed_at);


--
-- Name: ix_disputes_status_moderator; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_disputes_status_moderator ON public.disputes USING btree (status, assigned_moderator_id);


--
-- Name: ix_listings_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_listings_category_id ON public.listings USING btree (category_id);


--
-- Name: ix_listings_seller_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_listings_seller_id ON public.listings USING btree (seller_id);


--
-- Name: ix_listings_status_end_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_listings_status_end_time ON public.listings USING btree (status, end_time);


--
-- Name: ix_notifications_user_read_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notifications_user_read_created ON public.notifications USING btree (user_id, is_read, created_at);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: auction_results auction_results_listing_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_results
    ADD CONSTRAINT auction_results_listing_id_fkey FOREIGN KEY (listing_id) REFERENCES public.listings(listing_id);


--
-- Name: auction_results auction_results_winner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_results
    ADD CONSTRAINT auction_results_winner_id_fkey FOREIGN KEY (winner_id) REFERENCES public.users(user_id);


--
-- Name: auction_results auction_results_winning_bid_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_results
    ADD CONSTRAINT auction_results_winning_bid_id_fkey FOREIGN KEY (winning_bid_id) REFERENCES public.bids(bid_id);


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: bids bids_bidder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bids
    ADD CONSTRAINT bids_bidder_id_fkey FOREIGN KEY (bidder_id) REFERENCES public.users(user_id);


--
-- Name: bids bids_listing_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bids
    ADD CONSTRAINT bids_listing_id_fkey FOREIGN KEY (listing_id) REFERENCES public.listings(listing_id);


--
-- Name: disputes disputes_assigned_moderator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputes
    ADD CONSTRAINT disputes_assigned_moderator_id_fkey FOREIGN KEY (assigned_moderator_id) REFERENCES public.users(user_id);


--
-- Name: disputes disputes_auction_result_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputes
    ADD CONSTRAINT disputes_auction_result_id_fkey FOREIGN KEY (auction_result_id) REFERENCES public.auction_results(result_id);


--
-- Name: disputes disputes_raised_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputes
    ADD CONSTRAINT disputes_raised_by_fkey FOREIGN KEY (raised_by) REFERENCES public.users(user_id);


--
-- Name: listing_images listing_images_listing_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listing_images
    ADD CONSTRAINT listing_images_listing_id_fkey FOREIGN KEY (listing_id) REFERENCES public.listings(listing_id);


--
-- Name: listings listings_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listings
    ADD CONSTRAINT listings_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(category_id);


--
-- Name: listings listings_seller_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listings
    ADD CONSTRAINT listings_seller_id_fkey FOREIGN KEY (seller_id) REFERENCES public.users(user_id);


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: payments payments_auction_result_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_auction_result_id_fkey FOREIGN KEY (auction_result_id) REFERENCES public.auction_results(result_id);


--
-- Name: payments payments_payee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_payee_id_fkey FOREIGN KEY (payee_id) REFERENCES public.users(user_id);


--
-- Name: payments payments_payer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_payer_id_fkey FOREIGN KEY (payer_id) REFERENCES public.users(user_id);


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id);


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- PostgreSQL database dump complete
--

\unrestrict EGxCH9bU2dEi4mugWX7L0FVAf7eE4OwRVqvbubXmB4REuh3lpCkrZeBfEhuCMg0

