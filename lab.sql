--Organization Management
--Lab 1.1

USE ROLE orgadmin;

ALTER ACCOUNT MYORGACCOUNT SET IS_ORG_ADMIN = TRUE;

--Lab 1.2

ALTER ACCOUNT MYORGACCOUNT SET IS_ORG_ADMIN = FALSE;



--Account Management
--Lab 2.1

USE ROLE orgadmin;

--Create a regular Snowflake account
CREATE ACCOUNT DEMOSNOWSIGHT2
  ADMIN_NAME = admin
  ADMIN_PASSWORD = 'TestPassword1'
  FIRST_NAME = Jane
  LAST_NAME = Smith
  EMAIL = 'myemail43G5G45@demo.com'
  EDITION = enterprise
  REGION = aws_us_west_2;


--Create an open catalog Snowflake account
CREATE ACCOUNT DEMOSNOWSIGHT3
  ADMIN_NAME = admin
  ADMIN_PASSWORD = 'TestPassword1'
  FIRST_NAME = Jane
  LAST_NAME = Smith
  EMAIL = 'myemail43G5G45@demo.com'
  EDITION = enterprise
  REGION = aws_us_west_2
  POLARIS = true;


--View all accounts
SHOW ACCOUNTS;

--Lab 2.2
USE ROLE orgadmin;

ALTER ACCOUNT DEMOSNOWSIGHT2 RENAME TO DEMOSNOWSIGHT4;

--View all accounts
SHOW ACCOUNTS;


--Lab 2.3
USE ROLE orgadmin;

DROP ACCOUNT DEMOSNOWSIGHT4 GRACE_PERIOD_IN_DAYS = 14;

--To restore, use undrop
UNDROP ACCOUNT DEMOSNOWSIGHT4;


--Lab 2.4
--Let's create an organization accountusing DEMOSNOWSIGHT3

USE ROLE ORGADMIN;

CREATE ORGANIZATION ACCOUNT myorgaccount
    ADMIN_NAME = admin
    ADMIN_PASSWORD = 'TestPassword1'
    EMAIL = 'myemail@myorg.org'
    MUST_CHANGE_PASSWORD = true
    EDITION = enterprise;

--Lab 2.5
--Now we are going to create a password policy

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE DATABASE SECURITY;
CREATE OR REPLACE SCHEMA SECURITY.POLICIES;

--Now we can create the password policy

USE SCHEMA SECURITY.POLICIES;

CREATE PASSWORD POLICY PASSWORD_POLICY_PROD_1
    PASSWORD_MIN_LENGTH = 12
    PASSWORD_MAX_LENGTH = 24
    PASSWORD_MIN_UPPER_CASE_CHARS = 2
    PASSWORD_MIN_LOWER_CASE_CHARS = 2
    PASSWORD_MIN_NUMERIC_CHARS = 2
    PASSWORD_MIN_SPECIAL_CHARS = 2
    PASSWORD_MIN_AGE_DAYS = 1
    PASSWORD_MAX_AGE_DAYS = 999
    PASSWORD_MAX_RETRIES = 3
    PASSWORD_LOCKOUT_TIME_MINS = 30
    PASSWORD_HISTORY = 5
    COMMENT = 'production account password policy';

--Apply the policy to an account

ALTER ACCOUNT SET PASSWORD POLICY security.policies.password_policy_prod_1;

--Apply the policy to a user

CREATE USER test_user1;

ALTER USER test_user1 SET PASSWORD POLICY security.policies.password_policy_user;

--To reset a password policy, use UNSET 

ALTER ACCOUNT UNSET PASSWORD POLICY;

--Security
--Lab 3.1

--A user with the ACCOUNTADMIN role can use the ENABLE_IDENTIFIER_FIRST_LOGIN parameter to enable the identifier-first login flow for an account.

USE ROLE ACCOUNTADMIN;

ALTER ACCOUNT SET ENABLE_IDENTIFIER_FIRST_LOGIN = true;

--Lab 3.2

--To create an authentication policy

CREATE AUTHENTICATION POLICY require_mfa_authentication_policy
  AUTHENTICATION_METHODS = ('SAML', 'PASSWORD')
  CLIENT_TYPES = ('SNOWFLAKE_UI', 'SNOWSQL', 'DRIVERS')
  MFA_AUTHENTICATION_METHODS = ('PASSWORD', 'SAML')
  MFA_ENROLLMENT = REQUIRED;

--Apply to an account
ALTER ACCOUNT SET AUTHENTICATION POLICY require_mfa_authentication_policy;

--Apply to a user
ALTER USER test_user1 SET AUTHENTICATION POLICY require_mfa_authentication_policy;

--Ideally, you want a seperate policy for administrators to prevent lockout. This one SHOULD allow passwords as an authenitcation method
CREATE AUTHENTICATION POLICY admin_authentication_policy
  AUTHENTICATION_METHODS = ('SAML', 'PASSWORD')
  CLIENT_TYPES = ('SNOWFLAKE_UI', 'SNOWSQL', 'DRIVERS');

--Make sure you replace <administrator_name> with your admin user
ALTER USER <administrator_name> SET AUTHENTICATION POLICY admin_authentication_policy;

SHOW AUTHENTICATION POLICIES;

--Lab 3.3
--First create a network rules

CREATE NETWORK RULE my_ip_address
  TYPE = IPV4
  VALUE_LIST = (<enter ip address>,current_ip_address)
  COMMENT ='ip range';

--Then we create the network policy
CREATE NETWORK POLICY mypolicy1 ALLOWED_IP_LIST=(my_ip_address)
                                BLOCKED_IP_LIST=(<block_list>);

DESC NETWORK POLICY mypolicy1;


--Lab 3.4

--Create permissions for adding packages
USE ROLE ACCOUNTADMIN;

CREATE ROLE trust_center_admin_role;
GRANT APPLICATION ROLE SNOWFLAKE.TRUST_CENTER_ADMIN TO ROLE trust_center_admin_role;

CREATE ROLE trust_center_viewer_role;
GRANT APPLICATION ROLE SNOWFLAKE.TRUST_CENTER_VIEWER TO ROLE trust_center_viewer_role;

GRANT ROLE trust_center_admin_role TO USER <Example_admin_user>;

GRANT ROLE trust_center_viewer_role TO USER <example_nonadmin_user>;

--Data Governance
--Lab 4.1

USE ROLE ACCOUNTADMIN;
CREATE ROLE IF NOT EXISTS dq_tutorial_role;

GRANT CREATE DATABASE ON ACCOUNT TO ROLE dq_tutorial_role;
GRANT EXECUTE DATA METRIC FUNCTION ON ACCOUNT TO ROLE dq_tutorial_role;
GRANT APPLICATION ROLE SNOWFLAKE.DATA_QUALITY_MONITORING_VIEWER TO ROLE dq_tutorial_role;
GRANT DATABASE ROLE SNOWFLAKE.USAGE_VIEWER TO ROLE dq_tutorial_role;
GRANT DATABASE ROLE SNOWFLAKE.DATA_METRIC_USER TO ROLE dq_tutorial_role;

CREATE WAREHOUSE IF NOT EXISTS dq_tutorial_wh;
GRANT USAGE ON WAREHOUSE dq_tutorial_wh TO ROLE dq_tutorial_role;

SHOW GRANTS TO ROLE dq_tutorial_role;

GRANT ROLE dq_tutorial_role TO ROLE SYSADMIN;
GRANT ROLE dq_tutorial_role TO USER <admin_user>;

--Lab 4.2

USE ROLE dq_tutorial_role;
CREATE DATABASE IF NOT EXISTS dq_tutorial_db;
CREATE SCHEMA IF NOT EXISTS sch;

CREATE TABLE customers (
  account_number NUMBER(38,0),
  first_name VARCHAR(16777216),
  last_name VARCHAR(16777216),
  email VARCHAR(16777216),
  phone VARCHAR(16777216),
  created_at TIMESTAMP_NTZ(9),
  street VARCHAR(16777216),
  city VARCHAR(16777216),
  state VARCHAR(16777216),
  country VARCHAR(16777216),
  zip_code NUMBER(38,0)
);

USE WAREHOUSE dq_tutorial_wh;

INSERT INTO customers (account_number, city, country, email, first_name, last_name, phone, state, street, zip_code)
  VALUES (1589420, 'san francisco', 'usa', 'john.doe@', 'john', 'doe', 1234567890, null, null, null);

INSERT INTO customers (account_number, city, country, email, first_name, last_name, phone, state, street, zip_code)
  VALUES (8028387, 'san francisco', 'usa', 'bart.simpson@example.com', 'bart', 'simpson', 1012023030, null, 'market st', 94102);

INSERT INTO customers (account_number, city, country, email, first_name, last_name, phone, state, street, zip_code)
  VALUES
    (1589420, 'san francisco', 'usa', 'john.doe@example.com', 'john', 'doe', 1234567890, 'ca', 'concar dr', 94402),
    (2834123, 'san mateo', 'usa', 'jane.doe@example.com', 'jane', 'doe', 3641252911, 'ca', 'concar dr', 94402),
    (4829381, 'san mateo', 'usa', 'jim.doe@example.com', 'jim', 'doe', 3641252912, 'ca', 'concar dr', 94402),
    (9821802, 'san francisco', 'usa', 'susan.smith@example.com', 'susan', 'smith', 1234567891, 'ca', 'geary st', 94121),
    (8028387, 'san francisco', 'usa', 'bart.simpson@example.com', 'bart', 'simpson', 1012023030, 'ca', 'market st', 94102);

--Lab 4.3

CREATE DATA METRIC FUNCTION IF NOT EXISTS
  invalid_email_count (ARG_T table(ARG_C1 STRING))
  RETURNS NUMBER AS
  'SELECT COUNT_IF(FALSE = (
    ARG_C1 REGEXP ''^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$''))
    FROM ARG_T';

ALTER TABLE customers SET DATA_METRIC_SCHEDULE = '5 MINUTE';

ALTER TABLE customers ADD DATA METRIC FUNCTION
  invalid_email_count ON (email);

SELECT * FROM TABLE(INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES(
  REF_ENTITY_NAME => 'dq_tutorial_db.sch.customers',
  REF_ENTITY_DOMAIN => 'TABLE'));

SELECT scheduled_time, measurement_time, table_name, metric_name, value
FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS
WHERE TRUE
AND METRIC_NAME = 'INVALID_EMAIL_COUNT'
AND METRIC_DATABASE = 'DQ_TUTORIAL_DB'
LIMIT 100;

ALTER TABLE customers DROP DATA METRIC FUNCTION
  invalid_email_count ON (email);

--Lab 4.4

USE ROLE dq_tutorial_role;
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.DATA_QUALITY_MONITORING_USAGE_HISTORY
WHERE TRUE
AND START_TIME >= CURRENT_TIMESTAMP - INTERVAL '3 days'
LIMIT 100;

--Clean resources
USE ROLE ACCOUNTADMIN;
DROP DATABASE dq_tutorial_db;
DROP WAREHOUSE dq_tutorial_wh;
DROP ROLE dq_tutorial_role;



--Data Governance
--Lab 5.1

-- Create sample databases

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE DATABASE SNOWTEST; -- Database storing the tags
CREATE OR REPLACE DATABASE SNOWTEST2;
CREATE OR REPLACE DATABASE SNOWTEST3;

-- We need to create a schema for the object tags

CREATE OR REPLACE SCHEMA SNOWTEST.TAGS;

-- Let's create a tag for the different database objects

CREATE OR REPLACE TAG SNOWTEST.TAGS.tag_options allowed_values 'sales','finance';

-- We can look at the tags
SELECT GET_DDL('tag', 'tag_options');

-- We can Tag objects by using the ALTER command and SET TAG

ALTER DATABASE SNOWTEST2 SET TAG tag_options = 'sales';

-- We can ONLY add tags where there is an available option

ALTER DATABASE SNOWTEST3 SET TAG tag_options = 'IT'; -- Should display an error

-- ALTER the Tag to add the IT Option

ALTER TAG SNOWTEST.TAGS.tag_options add allowed_values 'IT';
ALTER DATABASE SNOWTEST3 SET TAG SNOWTEST.TAGS.tag_options = 'IT';

-- We can always see all the available options for a tag in Snowflake

SELECT SYSTEM$GET_TAG_ALLOWED_VALUES('SNOWTEST.TAGS.TAG_OPTIONS');

-- Furthermore, we can see what objects have various tags
--Clean up

DROP DATABASE SNOWTEST;
DROP DATABASE SNOWTEST3;
DROP DATABASE SNOWTEST3;


--Lab 5.2
-- Create a sample data and table with ID, Social Security number, Age and Credit Card

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE DATABASE SNOWTEST;
CREATE OR REPLACE SCHEMA SNOWTEST.DATA_CLASS;
CREATE OR REPLACE TABLE SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL(
    ID VARCHAR(10)
    , SSN VARCHAR(11) 
    , AGE NUMERIC 
    , CREDIT_CARD VARCHAR(19) 
);


-- Let's enter some fake sensitive data
INSERT INTO SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL 
VALUES ('A0000001','234-45-6477',24,'4053-0495-0394-0494'),
('A0000002','234-85-3427',28,'4653-0495-0394-0494'),
('A0000003','235-49-6477',43,'4053-0755-0394-0494'),
('A0000004','254-85-6457',57,'4653-4566-0394-0494'),
('A0000005','235-45-6076',34,'4053-0755-0394-0494'),
('A0000006','454-85-6473',21,'4653-0495-0394-0494'),
('A0000008','285-49-6697',17,'4053-0755-0394-0494'),
('A0000009','234-85-7377',12,'4653-0495-0394-0494'),
('A0000010','253-45-6467',87,'4053-0755-0394-0494'),
('A0000012','434-85-6384',58,'4653-0495-0394-0494'),
('A0000013','893-45-4266',34,'4053-0755-0394-0494'),
('A0000011','684-85-9405',74,'4653-0495-3454-0494'),
('A0000014','345-45-6935',28,'4053-0755-0394-0494'),
('A0000015','034-85-6637',53,'4653-0495-0394-0494'),
('A0000016','475-45-5646',34,'4053-0755-0394-0494'),
('A0000017','694-85-6030',38,'4653-0495-0394-0494'),
('A0000018','745-45-5466',36,'4053-0755-0394-0494'),
('A0000019','224-85-3246',74,'4653-0495-0394-0494'),
('A0000020','945-45-9645',45,'4053-0755-0394-0494');

-- Looking at the table values
SELECT *
FROM SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL;

-- Run EXTRACT_SEMANTIC_CATEGORIES to analyze the columns in the table
SELECT EXTRACT_SEMANTIC_CATEGORIES('SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL');

-- The results will be in JSON format. We can flatten to analysis the recommendations

CREATE OR REPLACE TABLE SNOWTEST.DATA_CLASS.CLASSIFICATIONS AS
select t.key::varchar as column_name,
    t.value:"recommendation".privacy_category::varchar as privacy_category,  
    t.value:"recommendation".semantic_category::varchar as semantic_category,
    t.value:"recommendation".coverage::numeric as probability
from table(
        flatten(
            extract_semantic_categories(
                'SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL'
            )::variant
        )
    ) as t
;

-- We can then use this table to review the recommendation and create object tags accordingly
SELECT * FROM SNOWTEST.DATA_CLASS.CLASSIFICATIONS;


DROP DATABASE SNOWTEST;


--Lab 5.3
-- Create a sample data and table with ID, Social Security number, Age and Credit Card

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE DATABASE SNOWTEST;
CREATE OR REPLACE SCHEMA SNOWTEST.DATA_CLASS;
CREATE OR REPLACE TABLE SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL(
    ID VARCHAR(10)
    , SSN VARCHAR(11) 
    , AGE NUMERIC 
    , CREDIT_CARD VARCHAR(19) 
);

-- Let's enter some fake sensitive data

INSERT INTO SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL 
VALUES ('A0000001','234-45-6477',24,'4053-0495-0394-0494'),
('A0000002','234-85-3427',28,'4653-0495-0394-0494'),
('A0000003','235-49-6477',43,'4053-0755-0394-0494'),
('A0000004','254-85-6457',57,'4653-4566-0394-0494'),
('A0000005','235-45-6076',34,'4053-0755-0394-0494'),
('A0000006','454-85-6473',21,'4653-0495-0394-0494'),
('A0000008','285-49-6697',17,'4053-0755-0394-0494'),
('A0000009','234-85-7377',12,'4653-0495-0394-0494'),
('A0000010','253-45-6467',87,'4053-0755-0394-0494'),
('A0000012','434-85-6384',58,'4653-0495-0394-0494'),
('A0000013','893-45-4266',34,'4053-0755-0394-0494'),
('A0000011','684-85-9405',74,'4653-0495-3454-0494'),
('A0000014','345-45-6935',28,'4053-0755-0394-0494'),
('A0000015','034-85-6637',53,'4653-0495-0394-0494'),
('A0000016','475-45-5646',34,'4053-0755-0394-0494'),
('A0000017','694-85-6030',38,'4653-0495-0394-0494'),
('A0000018','745-45-5466',36,'4053-0755-0394-0494'),
('A0000019','224-85-3246',74,'4653-0495-0394-0494'),
('A0000020','945-45-9645',45,'4053-0755-0394-0494');

-- Here is the table, but we have senstive data like SSN and Credit Card information
SELECT * FROM SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL;

-- We want to mask the social security number so it only shows the last 4 digits
SELECT CONCAT('XXX-XX-',RIGHT(SSN,4)) as SSN
FROM SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL;-

-- Create a analyst role

CREATE OR REPLACE ROLE analyst;

GRANT ROLE analyst TO USER <user>;

GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE analyst;
GRANT ALL ON DATABASE SNOWTEST TO ROLE analyst;
GRANT ALL ON SCHEMA SNOWTEST.DATA_CLASS TO ROLE analyst;
GRANT ALL ON TABLE SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL TO ROLE analyst;

-- Create masking policy for SSN number
CREATE OR REPLACE MASKING POLICY ssn_mask AS (val string) RETURNS string ->
  CASE
    WHEN CURRENT_ROLE() = 'ANALYST' THEN val
    ELSE CONCAT('XXX-XX-',RIGHT(val,4))
  END;

  
-- Now apply the masking policy on the sample table SSN column
ALTER TABLE IF EXISTS SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL MODIFY COLUMN SSN SET MASKING POLICY ssn_mask;

-- using the ANALYST role

USE ROLE analyst;
SELECT CURRENT_ROLE();
SELECT * FROM SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL; -- should see plain text value

-- using the ACCOUNTADMIN role

USE ROLE ACCOUNTADMIN;
SELECT * FROM SNOWTEST.DATA_CLASS.SAMPLE_DATA_TBL; -- should see full data mask

-- Clear resources

USE ROLE ACCOUNTADMIN;
DROP DATABASE SNOWTEST;
DROP ROLE ANALYST;

-- Test Your Skills

-- Create three new roles, administration, enrollment and accounting
-- Create a masking policy so that SSN and Credit Card is masked for administration, credit card is masked for enrollment and SSN is masked for finance

--Lab 5.4


-- Create new database

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE DATABASE SNOWTEST;
CREATE OR REPLACE SCHEMA SNOWTEST.PUBLIC;

-- Create roles and apply to the user

CREATE OR REPLACE ROLE ROLE1;
CREATE OR REPLACE ROLE ROLE2;
CREATE OR REPLACE ROLE ROLE3;
CREATE OR REPLACE ROLE SUPERADMIN;

GRANT ROLE SUPERADMIN TO USER <user>;
GRANT ROLE ROLE1 TO USER <user>;
GRANT ROLE ROLE2 TO USER <user>;
GRANT ROLE ROLE3 TO USER <user>;

-- We will create a new table of start, social security, age, CC

CREATE OR REPLACE TABLE SNOWTEST.PUBLIC.SAMPLE_DATA_TBL(
    STATE VARCHAR(2)
    , SSN VARCHAR(11)
    , AGE NUMERIC
    , CC VARCHAR(19)
);

INSERT INTO SNOWTEST.PUBLIC.SAMPLE_DATA_TBL 
VALUES ('KS','234-45-6477',27,'4053 0495 0394 0494'), 
('TX','234-85-6477',67,'4653 0495 0394 0494'), 
('TX','235-45-6477',44,'4053 0755 0394 0494'), 
('MD','234-85-6477',81,'4873 0495 0394 4094'), 
('CA','234-85-0877',18,'4653 0495 0084 0494');

-- Create a mapping table for row-level access

CREATE OR REPLACE TABLE SNOWTEST.PUBLIC.MAPPING (
    ROLE_ENTITLED varchar, STATE varchar
);

-- Insert mapping values

INSERT INTO SNOWTEST.PUBLIC.MAPPING VALUES ('ROLE1','TX'),
('ROLE1','KS'),
('ROLE1','MD'),
('ROLE1','CA'),
('ROLE1','TX'),
('ROLE1','MA'),
('ROLE3','TX'),
('ROLE3','KS');

-- Create row access policy

CREATE ROW ACCESS POLICY SNOWTEST.PUBLIC.TEST_POLICY AS
(state_filter varchar) RETURNS BOOLEAN ->  -- This will provide a true or false on the row based on the mapping table
CURRENT_ROLE() = 'SUPERADMIN'
OR EXISTS (
    SELECT 1 FROM SNOWTEST.PUBLIC.MAPPING
    WHERE STATE = state_filter
    AND ROLE_ENTITLED = CURRENT_ROLE());

-- Apply the row access policy on the created table

ALTER TABLE SNOWTEST.PUBLIC.SAMPLE_DATA_TBL ADD ROW ACCESS POLICY SNOWTEST.PUBLIC.TEST_POLICY ON (STATE);

-- Grant permissions to all of the roles

USE ROLE ACCOUNTADMIN;
GRANT SELECT ON SNOWTEST.PUBLIC.SAMPLE_DATA_TBL TO ROLE ROLE1;
GRANT SELECT ON SNOWTEST.PUBLIC.SAMPLE_DATA_TBL TO ROLE ROLE2;
GRANT SELECT ON SNOWTEST.PUBLIC.SAMPLE_DATA_TBL TO ROLE ROLE3;
GRANT SELECT ON SNOWTEST.PUBLIC.SAMPLE_DATA_TBL TO ROLE SUPERADMIN;

GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE ROLE1;
GRANT ALL ON DATABASE SNOWTEST TO ROLE ROLE1;
GRANT ALL ON SCHEMA SNOWTEST.PUBLIC TO ROLE ROLE1;

GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE ROLE2;
GRANT ALL ON DATABASE SNOWTEST TO ROLE ROLE2;
GRANT ALL ON SCHEMA SNOWTEST.PUBLIC TO ROLE ROLE2;

GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE ROLE3;
GRANT ALL ON DATABASE SNOWTEST TO ROLE ROLE3;
GRANT ALL ON SCHEMA SNOWTEST.PUBLIC TO ROLE ROLE3;

GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE SUPERADMIN;
GRANT ALL ON DATABASE SNOWTEST TO ROLE SUPERADMIN;
GRANT ALL ON SCHEMA SNOWTEST.PUBLIC TO ROLE SUPERADMIN;

-- Test the access by role

USE ROLE SUPERADMIN;
SELECT CURRENT_ROLE();
SELECT * FROM SNOWTEST.PUBLIC.SAMPLE_DATA_TBL;

USE ROLE ROLE1;
SELECT CURRENT_ROLE();
SELECT * FROM SNOWTEST.PUBLIC.SAMPLE_DATA_TBL;

USE ROLE ROLE2;
SELECT CURRENT_ROLE();
SELECT * FROM SNOWTEST.PUBLIC.SAMPLE_DATA_TBL;

USE ROLE ROLE3;
SELECT CURRENT_ROLE();
SELECT * FROM SNOWTEST.PUBLIC.SAMPLE_DATA_TBL;

USE ROLE ACCOUNTADMIN;

-- Clear resources

USE ROLE ACCOUNTADMIN;

DROP DATABASE SNOWTEST;
DROP ROLE ROLE1;
DROP ROLE ROLE2;
DROP ROLE ROLE3;
DROP ROLE SUPERADMIN;

-- Test Your Skills

-- Use the below 

CREATE OR REPLACE DATABASE SNOWTEST;
CREATE OR REPLACE SCHEMA SNOWTEST.PUBLIC;

CREATE OR REPLACE TABLE SNOWTEST.PUBLIC.SAMPLE_DATA_TBL(
    ID VARCHAR(5)
    , ANIMAL VARCHAR(10)
    , PASSWORD VARCHAR(10)
    , REGION VARCHAR(2)
);

INSERT INTO SNOWTEST.PUBLIC.SAMPLE_DATA_TBL 
VALUES ('A0001','Dog','DDKe43##@','N'),('A0002','Cat','24454##@','S'),('A0003','Mouse','334452552@','N'),('A0004','Pig','JILL12345','N'),('A0005','Dog','PASS321','W'),('A0006','Dog','LMONKEY','E'),('A0007','Horse','JILL12345','S'),('A0008','Cat','whisker@$','W'),('A0009','Dog','Melon','N')
;

SELECT *
FROM SNOWTEST.PUBLIC.SAMPLE_DATA_TBL
;

-- Using row access policies and masking, make it such that the password is masked from everyone, TeamA can only see regions 'N' and 'S', TeamB can see everything, TeamC can only see the region W and has everything by ID masked and TeamD can only see dogs
