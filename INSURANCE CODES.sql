  CREATE DATABASE INSURANCE 
USE INSURANCE


SELECT * FROM AGENTS
SELECT * FROM CLAIMS
SELECT * FROM CUSTOMERS
SELECT * FROM POLICIES
SELECT * FROM PREMIUMS
SELECT * FROM RENEWALS
SELECT * FROM UNDERWRITING

----------------------------------------------------------------------------


--1. AGENTS Table
--What the AGENTS section does

--The AGENTS table contains information about insurance agents, including:

--Agent ID and name
--Agent type
--Regions
--Years of experience
--Commission percentage
--Number of policies sold
--Renewal rate
--Agent status
--Joining date

--The query transforms the original agent data by creating additional date-based analytical fields:

--JOIN_YEAR — year the agent joined
--JOIN_MONTH — month the agent joined
--JOIN_QTR — quarter the agent joined
--JOIN_MONTH_NAME — name of the joining month
--It also formats commission and renewal rate percentages for easier presentation.
--Why this is necessary
--The raw JOIN_DATE tells us when an agent joined, but analytical reporting often requires the date to be broken into year, month, and quarter.
--For example, these fields make it easier to answer questions such as:
--How many agents joined each year?
--Which quarter had the highest number of agent hires?
--How many experienced agents are currently active?
--Which region has the most agents?
--Which agents have the highest renewal rates?
--Does agent experience correlate with policy sales?



SELECT * FROM AGENTS

 


----create a view to optimize the code
--Agents_view stores the transformed version of the agent data as a reusable view.

--Instead of repeatedly writing:

--YEAR(JOIN_DATE)
--MONTH(JOIN_DATE)
--DATEPART(QUARTER, JOIN_DATE)
--DATENAME(MONTH, JOIN_DATE)

--you can simply query:

--SELECT * FROM Agents_view;
--Why the view is necessary

--The view provides a centralized analytical layer over the raw AGENTS table.

--It is useful because:

--The transformation logic is written once.
--Analysts can reuse the same calculations.
--Reporting becomes simpler.
--It reduces repetitive SQL.
--It creates a consistent structure for Power BI or other reporting tools.

--Business purpose:
--The AGENTS view is mainly useful for agent performance, workforce analysis, sales productivity, regional analysis, and renewal performance.



DROP VIEW Agents_view


----------------------------------------------------------------------------------------------

--2. CLAIMS Table
--What the CLAIMS section does

--The CLAIMS table contains information about insurance claims, including:

--Claim ID
--Policy ID
--Customer ID
--Claim type
--Incident date
--Reported date
--Claim amount
--Claim status
--Settlement amount
--Processing days
--Fraud information
--Claim severity
--Claim source

--The transformation converts the raw claim data into a more analytical dataset.

--1. Reporting Delay
--DATEDIFF(DAY,INCIDENT_DATE,REPORTED_DATE)

--creates REPROTING_DELAY.

--This calculates how many days passed between the incident and the date the customer reported the claim.

--Why necessary?

--This helps the insurance company understand:

--Whether customers report claims quickly.
--Which claims have unusually long reporting delays.
--Whether delayed reporting is associated with fraud or claim severity.
--2. Unsettled Amount
--CLAIM_AMOUNT - SETTLEMENT_AMOUNT

--creates UNSETTLED_AMOUNT.

--This shows the portion of the claim amount that was not settled.

--Why necessary?

--It helps analyze:

--Claim payment gaps
--Outstanding financial exposure
--Differences between requested and settled amounts
--3. Settlement Rate

--The calculation:

--SETTLEMENT_AMOUNT / CLAIM_AMOUNT * 100

--creates SETTLEMENT_RATE.

--It measures what percentage of the claimed amount was actually settled.

--For example:

--If:

--Claim amount = ₹100,000
--Settlement = ₹80,000

--then settlement rate = 80%.

--Why necessary?

--It helps evaluate claim settlement performance and identify claims where the customer received significantly less than the claimed amount.

--4. Fraud Risk Level

--The code categorizes fraud scores into:

--HIGH RISK
--MEDIUM RISK
--LOW

--based on the FRAUD_SCORE.

--Why necessary?

--A numerical fraud score is useful, but business users often understand risk categories more easily.

--This allows reports to answer:

--How many claims are high fraud risk?
--Which claim types have higher fraud risk?
--Which regions have more suspicious claims?
--What percentage of claims are low/medium/high risk?
--5. Fraud Flag Standardization

--The code standardizes the FRAUD_FLAG values using:

--UPPER(TRIM(FRAUD_FLAG))

--and categorizes them as:

--CONFIRMED
--SUSPECTED
--NO
--UNKNOWN
--Why necessary?

--Real-world datasets frequently contain inconsistent text values such as:

--confirmed
--Confirmed
--CONFIRMED
--suspected

--Standardizing them makes grouping and reporting much more reliable.

--6. Incident Date Attributes

--The code creates:

--INCIDENT_YEAR
--INCIDENT_MONTH
--INCIDENT_MONTH_NAME
--INCIDENT_QTR
--Why necessary?

--These fields allow claims to be analyzed over time.

--For example:

--Claims by year
--Claims by month
--Quarterly claim trends
--Seasonal claim patterns
--CLAIM_STATUS Update

--The code also contains:

--UPDATE CLAIMS
--SET CLAIM_STATUS = 'PENDING'
--WHERE CLAIM_STATUS = 'PENDING Investigation';
--What this does

--It standardizes the claim status by converting:

--PENDING Investigation

--into:

--PENDING

--Why necessary?

--This prevents the same business status from appearing as two separate categories.

--Without standardization, a report might incorrectly show:

--Claim Status	Claims
--PENDING	100
--PENDING Investigation	50

--When they are actually the same business category.



SELECT * FROM CLAIMS


SELECT
CLAIM_ID,
POLICY_ID,
CUSTOMER_ID,
CLAIM_TYPE,
INCIDENT_DATE,
REPORTED_DATE,
CLAIM_AMOUNT,
CLAIM_STATUS,
SETTLEMENT_AMOUNT,
PROCESSING_DAYS,
FRAUD_FLAG,
FORMAT(FRAUD_SCORE,'P2') AS FRAUD_SCORE,
SOURCE,
CLAIM_SEVERITY,
DATEDIFF(DAY,INCIDENT_DATE,REPORTED_DATE) AS REPROTING_DELAY,
(CLAIM_AMOUNT-SETTLEMENT_AMOUNT) AS UNSETTLED_AMOUNT,
CASE 
	WHEN CLAIM_AMOUNT>0 THEN (SETTLEMENT_AMOUNT)/CLAIM_AMOUNT*100
	ELSE 0
END AS SETTLEMENT_RATE,
CASE
	WHEN FRAUD_SCORE > 0.80 THEN 'HIGH RISK'
	WHEN FRAUD_SCORE > 0.50 THEN 'MEDIUM RISK'
	ELSE 'LOW'
END AS FRAUD_RISK_LEVEL,
CASE
    WHEN UPPER(TRIM(FRAUD_FLAG)) = 'CONFIRMED' THEN 'CONFIRMED'
    WHEN UPPER(TRIM(FRAUD_FLAG)) = 'SUSPECTED' THEN 'SUSPECTED'
    WHEN UPPER(TRIM(FRAUD_FLAG)) = 'NO' THEN 'NO'
    ELSE 'UNKNOWN'
END AS FRAUD_FLAG,
YEAR( INCIDENT_DATE) AS INCIDENT_YEAR,
MONTH(INCIDENT_DATE) AS INCIDENT_MONTH,
DATENAME(MONTH,INCIDENT_DATE) AS INCIDENT_MONTH_NAME,
'Q' + CAST(DATEPART(QUARTER, INCIDENT_DATE) AS VARCHAR(1)) AS INCIDENT_QTR
FROM CLAIMS
 
UPDATE CLAIMS
SET CLAIM_STATUS = 'PENDING'
WHERE CLAIM_STATUS = 'PENDING Investigation';



--create a view for the folling claim table

--CLAIMS_VIEW

--CLAIMS_VIEW contains the analytical version of the claims data.

--It combines:

--Original claim information
--Reporting delay
--Unsettled amount
--Settlement rate
--Fraud risk level
--Standardized fraud classification
--Year/month/quarter information
--Why the view is necessary

--The view creates a reusable claims analytics layer.

--Instead of repeatedly calculating fraud risk, settlement rate, reporting delay, etc., analysts can simply query:

--SELECT * FROM CLAIMS_VIEW;
--Business purpose

--The claims view supports:

--Claims performance analysis
--Fraud detection analysis
--Settlement analysis
--Claims trend analysis
--Operational efficiency analysis
--Customer claim behavior analysis




CREATE VIEW CLAIMS_VIEW AS
SELECT
CLAIM_ID,
POLICY_ID,
CUSTOMER_ID,
CLAIM_TYPE,
INCIDENT_DATE,
REPORTED_DATE,
CLAIM_AMOUNT,
CLAIM_STATUS,
SETTLEMENT_AMOUNT,
PROCESSING_DAYS,
FRAUD_FLAG,
FORMAT(FRAUD_SCORE,'P2') AS FRAUD_SCORE,
SOURCE,
CLAIM_SEVERITY,
DATEDIFF(DAY,INCIDENT_DATE,REPORTED_DATE) AS REPROTING_DELAY,
(CLAIM_AMOUNT-SETTLEMENT_AMOUNT) AS UNSETTLED_AMOUNT,
CASE 
	WHEN CLAIM_AMOUNT>0 THEN (SETTLEMENT_AMOUNT)/CLAIM_AMOUNT*100
	ELSE 0
END AS SETTLEMENT_RATE,
CASE
	WHEN FRAUD_SCORE > 0.80 THEN 'HIGH RISK'
	WHEN FRAUD_SCORE > 0.50 THEN 'MEDIUM RISK'
	ELSE 'LOW'
END AS FRAUD_RISK_LEVEL,
YEAR( INCIDENT_DATE) AS INCIDENT_YEAR,
MONTH(INCIDENT_DATE) AS INCIDENT_MONTH,
DATENAME(MONTH,INCIDENT_DATE) AS INCIDENT_MONTH_NAME,
'Q' + CAST(DATEPART(QUARTER, INCIDENT_DATE) AS VARCHAR(1)) AS INCIDENT_QTR
FROM CLAIMS
 

 SELECT * FROM CLAIMS_VIEW
--------------------------------------------------------------------------------------------
SELECT * FROM CUSTOMERS


--3. CUSTOMERS Table
--What the CUSTOMERS section does

--The CUSTOMERS table contains customer demographic, financial, geographic, and risk information.

--Important fields include:

--Customer ID
--Customer name
--Age
--Gender
--Marital status
--Occupation
--Annual income
--State
--City
--Credit score
--Customer risk segment
--Customer since date

--The transformation adds several customer segmentation fields.

--1. AGE_GROUP

--Customers are divided into:

--18-24
--25-34
--35-44
--45-54
--55-64
--65+
--Why necessary?

--Age is a numerical value, but age groups are easier to use in business reporting.

--This allows analysis such as:

--Which age group buys the most policies?
--Which age group generates the most claims?
--Which age group has the highest premium?
--Which age group has the highest renewal rate?
--2. INCOME_SEGMENT

--Customers are categorized into:

--Low Income
--Mid Income
--High Income
--Very High Income

--based on annual income.

--Why necessary?

--Income segmentation helps analyze the relationship between:

--Customer income → policy value → premium → claims → renewal

--It can also help identify high-value customer segments.

--3. CREDIT_CATEGORY

--Credit scores are categorized into:

--Excellent
--Good
--Fair
--Poor
--Very Poor
--Why necessary?

--A raw credit score such as 742 may not be as meaningful to a business user as the category GOOD.

--This is useful for:

--Risk analysis
--Customer segmentation
--Underwriting analysis
--Policy pricing analysis
--4. CUSTOMER_TENURE_YEARS

--The code calculates the number of years since the customer became a customer.

--Why necessary?

--This measures the length of the customer relationship.

--It helps answer:

--How long have customers stayed with the company?
--Are long-term customers more likely to renew?
--Are new customers more likely to leave?
--Which customer segments have the highest tenure?
--5. CUSTOMER_TENURE_SEGMENT

--Customers are categorized as:

--NEW
--ESTABLISHED
--LOYAL
--Why necessary?

--This converts a numerical tenure value into a business-friendly segmentation.

--It is particularly useful for customer retention and loyalty analysis.

--6. CUSTOMER SINCE DATE ATTRIBUTES

--The code creates:

--CUSTOMER_SINCE_YEAR
--CUSTOMER_SINCE_MONTH
--CUSTOMER_SINCE_MONTH_NAME
--CUSTOMER_SINCE_QTR
--Why necessary?

--These fields allow customer acquisition trends to be analyzed over time.

--For example:

--Customers acquired by year
--Customers acquired by quarter
--Monthly customer acquisition
--Customer growth trends






SELECT 
CUSTOMER_ID,
CUSTOMER_NAME,
AGE,
GENDER,
MARITAL_STATUS,
OCCUPATION,
ANNUAL_INCOME,
STATE,
CITY,
CREDIT_SCORE,
CUSTOMER_RISK_SEGMENT,
CUSTOMER_SINCE,
CASE
    WHEN AGE < 25 THEN '18-24'
    WHEN AGE < 35 THEN '25-34'
    WHEN AGE < 45 THEN '35-44'
    WHEN AGE < 55 THEN '45-54'
    WHEN AGE < 65 THEN '55-64'
    ELSE '65+'
END AS AGE_GROUP,
CASE
    WHEN ANNUAL_INCOME<300000 THEN 'LOW INCCOME'
    WHEN ANNUAL_INCOME<700000 THEN 'MID INCCOME'
    WHEN ANNUAL_INCOME<1500000 THEN 'HIGH INCCOME'
    ELSE 'VERY HIGH INCOME'
END AS INCOME_SEGMENT,
CASE
    WHEN CREDIT_SCORE >= 750 THEN 'PLATINUM'
    WHEN CREDIT_SCORE >= 700 THEN 'GOLD'
    WHEN CREDIT_SCORE >= 650 THEN 'SILVER'
    WHEN CREDIT_SCORE >= 600 THEN 'BRONZE'
    ELSE 'AT RISK'
END AS CREDIT_CATEGORY,
DATEDIFF(YEAR, CUSTOMER_SINCE, GETDATE()) AS CUSTOMER_TENURE_YEARS,
CASE
    WHEN DATEDIFF(YEAR, CUSTOMER_SINCE,GETDATE()) < 2 THEN 'NEW'
    WHEN DATEDIFF(YEAR, CUSTOMER_SINCE,GETDATE()) < 5 THEN 'ESTABLISHED'
    ELSE 'LOYAL'
END AS CUSTOMER_TENURE_SEGMENT,
YEAR( CUSTOMER_SINCE) AS CUSTOMER_SINCE_YEAR,
MONTH(CUSTOMER_SINCE) AS CUSTOMER_SINCE_MONTH,
DATENAME(MONTH,CUSTOMER_SINCE) AS CUSTOMER_SINCE_MONTH_NAME,
'Q' + CAST(DATEPART(QUARTER, CUSTOMER_SINCE) AS VARCHAR(1)) AS CUSTOMER_SINCE_QTR
FROM customers


SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'POLICIES'
ORDER BY ORDINAL_POSITION;




--CREATE A CUSTOMER VIEW

--CUSTOMER_VIEW

--CUSTOMER_VIEW combines the raw customer information with all the derived segmentation fields.

--Why the view is necessary

--It provides a ready-to-use customer analytics dataset.

--Instead of repeatedly writing the age, income, credit, and tenure CASE statements, users can simply query:

--SELECT * FROM CUSTOMER_VIEW;
--Business purpose

--The customer view supports:

--Customer segmentation
--Customer lifetime analysis
--Risk analysis
--Demographic analysis
--Income analysis
--Credit analysis
--Retention analysis
--Customer acquisition analysis

CREATE VIEW CUSTOMER_VIEW AS 
SELECT 
CUSTOMER_ID,
CUSTOMER_NAME,
AGE,
GENDER,
MARITAL_STATUS,
OCCUPATION,
ANNUAL_INCOME,
STATE,
CITY,
CREDIT_SCORE,
CUSTOMER_RISK_SEGMENT,
CUSTOMER_SINCE,
CASE
    WHEN AGE < 25 THEN '18-24'
    WHEN AGE < 35 THEN '25-34'
    WHEN AGE < 45 THEN '35-44'
    WHEN AGE < 55 THEN '45-54'
    WHEN AGE < 65 THEN '55-64'
    ELSE '65+'
END AS AGE_GROUP,
CASE
    WHEN ANNUAL_INCOME<300000 THEN 'LOW INCCOME'
    WHEN ANNUAL_INCOME<700000 THEN 'MID INCCOME'
    WHEN ANNUAL_INCOME<1500000 THEN 'HIGH INCCOME'
    ELSE 'VERY HIGH INCOME'
END AS INCOME_SEGMENT,
CASE
    WHEN CREDIT_SCORE >= 750 THEN 'PLATINUM'
    WHEN CREDIT_SCORE >= 700 THEN 'GOLD'
    WHEN CREDIT_SCORE >= 650 THEN 'SILVER'
    WHEN CREDIT_SCORE >= 600 THEN 'BRONZE'
    ELSE 'AT RISK'
END AS CREDIT_CATEGORY,
DATEDIFF(YEAR, CUSTOMER_SINCE, GETDATE()) AS CUSTOMER_TENURE_YEARS,
CASE
    WHEN DATEDIFF(YEAR, CUSTOMER_SINCE,GETDATE()) < 2 THEN 'NEW'
    WHEN DATEDIFF(YEAR, CUSTOMER_SINCE,GETDATE()) < 5 THEN 'ESTABLISHED'
    ELSE 'LOYAL'
END AS CUSTOMER_TENURE_SEGMENT,
YEAR( CUSTOMER_SINCE) AS CUSTOMER_SINCE_YEAR,
MONTH(CUSTOMER_SINCE) AS CUSTOMER_SINCE_MONTH,
DATENAME(MONTH,CUSTOMER_SINCE) AS CUSTOMER_SINCE_MONTH_NAME,
'Q' + CAST(DATEPART(QUARTER, CUSTOMER_SINCE) AS VARCHAR(1)) AS CUSTOMER_SINCE_QTR
FROM customers



SELECT * FROM CUSTOMER_VIEW



------------------------------------------------------------------------------------------------------------
--4. POLICIES Table

--This is one of the most important transformations in your project because it adds a large number of business and analytical fields to the raw policy data.

--The raw POLICIES table contains:

--Policy ID
--Customer ID
--Policy type
--Sales channel
--Agent ID
--Start date
--End date
--Sum insured
--Annual premium
--Payment mode
--Risk score
--Risk band
--Policy status
--Discount
--Commission

--The transformation converts this raw policy information into an analytics-ready policy dataset.

--1. POLICY_DURATION_DAYS

--Calculates how many days the policy is active between its start and end date.

--Why necessary?

--It allows analysis of policy duration.

--2. POLICY_DURATION_SEGMENT

--Policies are grouped into:

--Short Term
--Medium Term
--Long Term
--Why necessary?

--Business users can compare policy performance by duration.

--3. POLICY START/END DATE ATTRIBUTES

--The transformation creates:

--Start year
--End year
--Start month
--Start month name
--Start quarter
--Why necessary?

--These fields allow policy sales and policy periods to be analyzed over time.

--4. SALES_CHANNEL_GROUP

--The original sales channels are consolidated into broader groups:

--DIGITAL
--INTERMEDIARY
--PARTNERSHIP
--DIRECT
--Why necessary?

--Instead of analyzing many individual channels, management can compare major distribution strategies.

--For example:

--Digital vs Agent/Broker vs Partnership vs Direct

--This is useful for evaluating channel performance.

--5. SUM_INSURED_BAND

--The sum insured is categorized into:

--Low
--Medium
--High
--Very High
--Why necessary?

--This identifies the financial value of policies.

--It helps determine:

--Where the company's biggest exposures are.
--Which customer segments buy high-value policies.
--Which policy types have high coverage.
--6. PREMIUM_BAND

--Annual premiums are categorized into:

--Low Premium
--Medium Premium
--High Premium
--Very High Premium
--Why necessary?

--This makes it easier to identify high-value premium customers and compare premium revenue across segments.

--7. PREMIUM_TO_SUM_INSURED_PCT

--This calculates the premium relative to the insured amount.

--Why necessary?

--It provides an indication of how much premium is being charged relative to the amount of insurance coverage.

--This is useful for:

--Pricing analysis
--Policy profitability
--Comparing policies
--Risk/pricing evaluation
--8. PREMIUM_RATE_BAND

--The premium-to-sum-insured percentage is further categorized into:

--Low Rate
--Medium Rate
--High Rate
--Invalid
--Why necessary?

--Again, this converts a numerical metric into an easy-to-understand business category.

--9. CALCULATED_RISK_BAND

--The code independently categorizes RISK_SCORE into:

--Low
--Medium
--High
--Very High
--Why necessary?

--This creates a standardized risk classification based directly on the numerical risk score.

--It can be compared with the existing RISK_BAND.

--10. POLICY_STATUS_GROUP

--Policy statuses are consolidated into:

--Active
--Inactive
--Cancelled
--Other
--Why necessary?

--This simplifies policy status analysis.

--For example, EXPIRED and LAPSED are both effectively inactive from a business perspective.

--11. DAYS_TO_EXPIRY

--This calculates the number of days remaining until the policy expires.

--Why necessary?

--This is extremely important for renewal management.

--The company can identify policies that are approaching expiration.

--12. EXPIRY_SEGMENT

--Policies are classified into:

--Expired
--Expiring within 30 days
--Expiring within 90 days
--Active — Not Expiring Soon
--Why necessary?

--This converts the expiry date into an actionable business category.

--For example, the company can focus its renewal team on:

--EXPIRING WITHIN 30 DAYS

--13. RENEWAL_OPPORTUNITY_FLAG

--This creates a binary flag:

--1 = renewal opportunity
--0 = not currently a renewal opportunity
--Why necessary?

--This is particularly useful for dashboards and automated reporting.

--Instead of repeatedly calculating which policies expire within 90 days, the report can simply filter:

--RENEWAL_OPPORTUNITY_FLAG = 1
--14. DISCOUNT_BAND

--Discounts are classified as:

--No Discount
--Low Discount
--Medium Discount
--High Discount
--Why necessary?

--It allows management to evaluate the impact of discounts on premium revenue.

--15. COMMISSION_BAND

--Commission percentages are grouped into:

--No Commission
--Low
--Medium
--High
--Why necessary?

--This supports agent compensation and distribution-cost analysis.

--16. NET_PREMIUM

--The code calculates:

--Annual Premium − Discount

--This represents the premium after discount.

--Why necessary?

--Gross premium does not represent the actual premium after discounts.

--Net premium gives a more useful measure for revenue analysis.

--17. COMMISSION_AMOUNT

--The code calculates the monetary commission based on the net premium and commission percentage.

--Why necessary?

--A percentage is useful, but management often needs the actual monetary commission amount.

--This allows analysis of:

--Agent costs
--Distribution expenses
--Policy profitability
--Commission by agent/channel
--18. PAYMENT_FREQUENCY_GROUP

--Payment modes are grouped into:

--Installment
--Lump Sum
--Other
--Why necessary?

--This simplifies payment behavior analysis.

--Instead of analyzing monthly, quarterly, half-yearly, annual, etc. separately, management can compare:

--Installment vs Lump Sum

--19. POLICY_SEGMENT

--This is a higher-level business segmentation combining:

--Risk
--Premium value

--The categories are:

--Low Risk High Value
--High Risk High Value
--High Risk
--High Value
--Standard
--Why necessary?

--This is one of the most useful fields in the policy transformation.

--It helps management identify strategically important policies.

--For example:

--HIGH RISK + HIGH VALUE

--could represent policies that require additional underwriting attention.


SELECT * FROM POLICIES


SELECT
POLICY_ID,
CUSTOMER_ID,
POLICY_TYPE,
SALES_CHANNEL,
AGENT_ID,
POLICY_START_DATE,
POLICY_END_DATE,
SUM_INSURED,
ANNUAL_PREMIUM,
PAYMENT_MODE,
RISK_SCORE,
RISK_BAND,
POLICY_STATUS,
DISCOUNT_PCT,
COMMISSION_PCT,
DATEDIFF(DAY,POLICY_START_DATE,POLICY_END_DATE) AS POLICY_DURATION_DAYS,
CASE
    WHEN DATEDIFF(DAY, POLICY_START_DATE, POLICY_END_DATE) <= 365 THEN 'SHORT TERM'
    WHEN DATEDIFF(DAY, POLICY_START_DATE, POLICY_END_DATE) <= 730 THEN 'MEDIUM TERM'
    ELSE 'LONG TERM'
END AS POLICY_DURATION_SEGMENT,
YEAR(POLICY_START_DATE) AS POLICY_START_YEAR,
YEAR(POLICY_END_DATE) AS POLICY_END_YEAR,
MONTH(POLICY_START_DATE) AS POLICY_START_MONTH,
DATENAME(MONTH, POLICY_START_DATE) AS POLICY_START_MONTH_NAME,
'Q' + CAST(DATEPART(QUARTER, POLICY_START_DATE) AS VARCHAR(1)) AS POLICY_START_QTR,
CASE
    WHEN SALES_CHANNEL = 'ONLINE' THEN 'DIGITAL'
    WHEN SALES_CHANNEL IN ('AGENT', 'BROKER') THEN 'INTERMEDIARY'
    WHEN SALES_CHANNEL IN ('BANCASSURANCE', 'COOPERATE PARTENR') THEN 'PARTNERSHIP'
    ELSE 'DIRECT'
END AS SALES_CHANNEL_GROUP,
CASE
    WHEN SUM_INSURED < 500000 THEN 'LOW'
    WHEN SUM_INSURED < 1000000 THEN 'MEDIUM'
    WHEN SUM_INSURED < 5000000 THEN 'HIGH'
    ELSE 'VERY HIGH'
END AS SUM_INSURED_BAND,
CASE
    WHEN ANNUAL_PREMIUM < 10000 THEN 'LOW PREMIUM'
    WHEN ANNUAL_PREMIUM < 50000 THEN 'MEDIUM PREMIUM'
    WHEN ANNUAL_PREMIUM < 100000 THEN 'HIGH PREMIUM'
    ELSE 'VERY HIGH PREMIUM'
END AS PREMIUM_BAND,
CASE
    WHEN SUM_INSURED > 0 THEN (ANNUAL_PREMIUM * 100.0) / SUM_INSURED
    ELSE NULL
END AS PREMIUM_TO_SUM_INSURED_PCT,
CASE
    WHEN SUM_INSURED <= 0 THEN 'INVALID'
    WHEN (ANNUAL_PREMIUM * 100.0) / SUM_INSURED < 1 THEN 'LOW RATE'
    WHEN (ANNUAL_PREMIUM * 100.0) / SUM_INSURED < 3 THEN 'MEDIUM RATE'
    ELSE 'HIGH RATE'
END AS PREMIUM_RATE_BAND,
CASE
    WHEN RISK_SCORE >= 80 THEN 'VERY HIGH'
    WHEN RISK_SCORE >= 60 THEN 'HIGH'
    WHEN RISK_SCORE >= 40 THEN 'MEDIUM'
    ELSE 'LOW'
END AS CALCULATED_RISK_BAND,
CASE
    WHEN POLICY_STATUS IN ('ACTIVE', 'IN FORCE') THEN 'ACTIVE'
    WHEN POLICY_STATUS IN ('EXPIRED', 'LAPSED') THEN 'INACTIVE'
    WHEN POLICY_STATUS IN ('CANCELLED', 'TERMINATED') THEN 'CANCELLED'
    ELSE 'OTHER'
END AS POLICY_STATUS_GROUP,
DATEDIFF(DAY,GETDATE(),POLICY_END_DATE) AS DAYS_TO_EXPIRY,
CASE
    WHEN POLICY_END_DATE < GETDATE() THEN 'EXPIRED'
    WHEN DATEDIFF(DAY, GETDATE(), POLICY_END_DATE) <= 30 THEN 'EXPIRING WITHIN 30 DAYS'
    WHEN DATEDIFF(DAY, GETDATE(), POLICY_END_DATE) <= 90 THEN 'EXPIRING WITHIN 90 DAYS'
    ELSE 'ACTIVE - NOT EXPIRING SOON'
END AS EXPIRY_SEGMENT,
CASE
    WHEN POLICY_STATUS = 'ACTIVE' AND POLICY_END_DATE BETWEEN GETDATE() AND DATEADD(DAY, 90, GETDATE()) THEN 1
    ELSE 0
END AS RENEWAL_OPPORTUNITY_FLAG,
CASE
    WHEN DISCOUNT_PCT = 0 THEN 'NO DISCOUNT'
    WHEN DISCOUNT_PCT < 10 THEN 'LOW DISCOUNT'
    WHEN DISCOUNT_PCT < 25 THEN 'MEDIUM DISCOUNT'
    ELSE 'HIGH DISCOUNT'
END AS DISCOUNT_BAND,
CASE
    WHEN COMMISSION_PCT = 0 THEN 'NO COMMISSION'
    WHEN COMMISSION_PCT < 5 THEN 'LOW'
    WHEN COMMISSION_PCT < 10 THEN 'MEDIUM'
    ELSE 'HIGH'
END AS COMMISSION_BAND,
ANNUAL_PREMIUM* (1 - DISCOUNT_PCT / 100) AS NET_PREMIUM,
(ANNUAL_PREMIUM* (1 - DISCOUNT_PCT / 100)) * COMMISSION_PCT / 100 AS COMMISSION_AMOUNT,
CASE 
    WHEN PAYMENT_MODE IN ('MONTHLY', 'QUARTERLY', 'HALF-YEARLY') THEN 'INSTALLMENT'
    WHEN PAYMENT_MODE IN ('ANNUAL', 'YEARLY', 'SINGLE') THEN 'LUMP SUM'
    ELSE 'OTHER'
END AS PAYMENT_FREQUENCY_GROUP,
CASE
    WHEN RISK_SCORE < 40 AND ANNUAL_PREMIUM >= 100000 THEN 'LOW RISK HIGH VALUE'
    WHEN RISK_SCORE >= 80 AND ANNUAL_PREMIUM >= 100000 THEN 'HIGH RISK HIGH VALUE'
    WHEN RISK_SCORE >= 80 THEN 'HIGH RISK'
    WHEN ANNUAL_PREMIUM >= 100000 THEN 'HIGH VALUE'
    ELSE 'STANDARD'
END AS POLICY_SEGMENT
FROM POLICIES






--CREATE A POLICY VIEW


--POLICY_VIEW

--POLICY_VIEW stores all of these transformations in one reusable analytical view.

--Why the view is necessary

--Without the view, every report would need to recreate all the calculations.

--The view creates a single standardized policy analytics layer.

--Business purpose

--The policy view supports:

--Policy portfolio analysis
--Premium analysis
--Risk analysis
--Commission analysis
--Sales-channel analysis
--Renewal analysis
--Expiry monitoring
--Discount analysis
--Customer value analysis
--Payment behavior analysis






CREATE VIEW POLICY_VIEW AS 
SELECT
POLICY_ID,
CUSTOMER_ID,
POLICY_TYPE,
SALES_CHANNEL,
AGENT_ID,
POLICY_START_DATE,
POLICY_END_DATE,
SUM_INSURED,
ANNUAL_PREMIUM,
PAYMENT_MODE,
RISK_SCORE,
RISK_BAND,
POLICY_STATUS,
DISCOUNT_PCT,
COMMISSION_PCT,
DATEDIFF(DAY,POLICY_START_DATE,POLICY_END_DATE) AS POLICY_DURATION_DAYS,
CASE
    WHEN DATEDIFF(DAY, POLICY_START_DATE, POLICY_END_DATE) <= 365 THEN 'SHORT TERM'
    WHEN DATEDIFF(DAY, POLICY_START_DATE, POLICY_END_DATE) <= 730 THEN 'MEDIUM TERM'
    ELSE 'LONG TERM'
END AS POLICY_DURATION_SEGMENT,
YEAR(POLICY_START_DATE) AS POLICY_START_YEAR,
YEAR(POLICY_END_DATE) AS POLICY_END_YEAR,
MONTH(POLICY_START_DATE) AS POLICY_START_MONTH,
DATENAME(MONTH, POLICY_START_DATE) AS POLICY_START_MONTH_NAME,
'Q' + CAST(DATEPART(QUARTER, POLICY_START_DATE) AS VARCHAR(1)) AS POLICY_START_QTR,
CASE
    WHEN SALES_CHANNEL = 'ONLINE' THEN 'DIGITAL'
    WHEN SALES_CHANNEL IN ('AGENT', 'BROKER') THEN 'INTERMEDIARY'
    WHEN SALES_CHANNEL IN ('BANCASSURANCE', 'COOPERATE PARTENR') THEN 'PARTNERSHIP'
    ELSE 'DIRECT'
END AS SALES_CHANNEL_GROUP,
CASE
    WHEN SUM_INSURED < 500000 THEN 'LOW'
    WHEN SUM_INSURED < 1000000 THEN 'MEDIUM'
    WHEN SUM_INSURED < 5000000 THEN 'HIGH'
    ELSE 'VERY HIGH'
END AS SUM_INSURED_BAND,
CASE
    WHEN ANNUAL_PREMIUM < 10000 THEN 'LOW PREMIUM'
    WHEN ANNUAL_PREMIUM < 50000 THEN 'MEDIUM PREMIUM'
    WHEN ANNUAL_PREMIUM < 100000 THEN 'HIGH PREMIUM'
    ELSE 'VERY HIGH PREMIUM'
END AS PREMIUM_BAND,
CASE
    WHEN SUM_INSURED > 0 THEN (ANNUAL_PREMIUM * 100.0) / SUM_INSURED
    ELSE NULL
END AS PREMIUM_TO_SUM_INSURED_PCT,
CASE
    WHEN SUM_INSURED <= 0 THEN 'INVALID'
    WHEN (ANNUAL_PREMIUM * 100.0) / SUM_INSURED < 1 THEN 'LOW RATE'
    WHEN (ANNUAL_PREMIUM * 100.0) / SUM_INSURED < 3 THEN 'MEDIUM RATE'
    ELSE 'HIGH RATE'
END AS PREMIUM_RATE_BAND,
CASE
    WHEN RISK_SCORE >= 80 THEN 'VERY HIGH'
    WHEN RISK_SCORE >= 60 THEN 'HIGH'
    WHEN RISK_SCORE >= 40 THEN 'MEDIUM'
    ELSE 'LOW'
END AS CALCULATED_RISK_BAND,
CASE
    WHEN POLICY_STATUS IN ('ACTIVE', 'IN FORCE') THEN 'ACTIVE'
    WHEN POLICY_STATUS IN ('EXPIRED', 'LAPSED') THEN 'INACTIVE'
    WHEN POLICY_STATUS IN ('CANCELLED', 'TERMINATED') THEN 'CANCELLED'
    ELSE 'OTHER'
END AS POLICY_STATUS_GROUP,
DATEDIFF(DAY,GETDATE(),POLICY_END_DATE) AS DAYS_TO_EXPIRY,
CASE
    WHEN POLICY_END_DATE < GETDATE() THEN 'EXPIRED'
    WHEN DATEDIFF(DAY, GETDATE(), POLICY_END_DATE) <= 30 THEN 'EXPIRING WITHIN 30 DAYS'
    WHEN DATEDIFF(DAY, GETDATE(), POLICY_END_DATE) <= 90 THEN 'EXPIRING WITHIN 90 DAYS'
    ELSE 'ACTIVE - NOT EXPIRING SOON'
END AS EXPIRY_SEGMENT,
CASE
    WHEN POLICY_STATUS = 'ACTIVE' AND POLICY_END_DATE BETWEEN GETDATE() AND DATEADD(DAY, 90, GETDATE()) THEN 1
    ELSE 0
END AS RENEWAL_OPPORTUNITY_FLAG,
CASE
    WHEN DISCOUNT_PCT = 0 THEN 'NO DISCOUNT'
    WHEN DISCOUNT_PCT < 10 THEN 'LOW DISCOUNT'
    WHEN DISCOUNT_PCT < 25 THEN 'MEDIUM DISCOUNT'
    ELSE 'HIGH DISCOUNT'
END AS DISCOUNT_BAND,
CASE
    WHEN COMMISSION_PCT = 0 THEN 'NO COMMISSION'
    WHEN COMMISSION_PCT < 5 THEN 'LOW'
    WHEN COMMISSION_PCT < 10 THEN 'MEDIUM'
    ELSE 'HIGH'
END AS COMMISSION_BAND,
ANNUAL_PREMIUM* (1 - DISCOUNT_PCT / 100) AS NET_PREMIUM,
(ANNUAL_PREMIUM* (1 - DISCOUNT_PCT / 100)) * COMMISSION_PCT / 100 AS COMMISSION_AMOUNT,
CASE 
    WHEN PAYMENT_MODE IN ('MONTHLY', 'QUARTERLY', 'HALF-YEARLY') THEN 'INSTALLMENT'
    WHEN PAYMENT_MODE IN ('ANNUAL', 'YEARLY', 'SINGLE') THEN 'LUMP SUM'
    ELSE 'OTHER'
END AS PAYMENT_FREQUENCY_GROUP,
CASE
    WHEN RISK_SCORE < 40 AND ANNUAL_PREMIUM >= 100000 THEN 'LOW RISK HIGH VALUE'
    WHEN RISK_SCORE >= 80 AND ANNUAL_PREMIUM >= 100000 THEN 'HIGH RISK HIGH VALUE'
    WHEN RISK_SCORE >= 80 THEN 'HIGH RISK'
    WHEN ANNUAL_PREMIUM >= 100000 THEN 'HIGH VALUE'
    ELSE 'STANDARD'
END AS POLICY_SEGMENT
FROM POLICIES











----------------------------------------------------------------------------
--5. PREMIUMS Table

--The PREMIUMS table contains transaction-level premium/payment information.

--It includes:

--Premium transaction ID
--Policy ID
--Customer ID
--Due date
--Paid date
--Premium amount
--Payment status
--Payment method
--Payment delay
--Channel cost

--This section focuses heavily on data cleaning and payment behavior analysis.

--1. Date Conversion

--The code uses:

--TRY_CONVERT(DATE, DUE_DATE, 103)

--and similar logic for PAID_DATE.

--What this does

--It converts the original date values into proper SQL DATE values.

--Why necessary?

--Raw datasets sometimes contain dates stored as text.

--Converting them into proper dates allows SQL to perform:

--Year calculations
--Month calculations
--Date comparisons
--Time-based analysis
--2. Handling 1900-01-01

--The code converts:

--1900-01-01

--into:

--NULL

--Why necessary?

--1900-01-01 is often used as a placeholder/default date rather than a genuine payment date.

--Treating it as NULL prevents the system from incorrectly interpreting it as an actual payment.

--3. Numeric Conversion

--The code uses TRY_CONVERT to convert:

--Premium amount
--Payment delay
--Channel cost

--into numeric data types.

--Why necessary?

--It makes the data suitable for calculations and reduces the risk of conversion failures from invalid text values.

--4. PAYMENT_DELAY_BAND

--Payment delays are classified as:

--Unknown
--On Time
--1–7 Days Late
--8–30 Days Late
--30+ Days Late
--Why necessary?

--This transforms a raw number into a useful business classification.

--It helps answer:

--How many customers pay on time?
--How many are seriously delayed?
--What percentage of premiums are overdue?
--Which customer/policy segments have payment problems?
--5. PAYMENT_STATUS_GROUP

--Payment statuses are consolidated into:

--Paid
--Pending
--Failed
--Why necessary?

--This creates a standardized high-level payment status.

--It makes dashboards and reports easier to understand.

--6. CHANNEL_COST_PCT

--The code calculates channel cost as a percentage of premium amount.

--Why necessary?

--A monetary channel cost alone doesn't tell you how expensive the channel is relative to premium revenue.

--The percentage allows better comparison between transactions and channels.

--7. NET_PREMIUM

--The code calculates:

--Premium Amount − Channel Cost

--Why necessary?

--This provides a more realistic view of premium revenue after channel-related costs.

--It can be useful for profitability analysis.

--8. PAYMENT_METHOD_GROUP

--Payment methods are grouped into:

--Digital
--Non-Digital
--Other
--Why necessary?

--This enables analysis of the company's digital payment adoption.

--For example:

--What percentage of premiums are paid digitally?
--Is digital payment associated with faster payment?
--Which customer segments prefer digital payment?
--9. Due/Paid Date Attributes

--The transformation creates:

--Due Year
--Due Month
--Paid Year
--Paid Month
--Why necessary?

--These fields allow payment trends to be analyzed over time.




SELECT * FROM PREMIUMS

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'PREMIUM_VIEW'
ORDER BY ORDINAL_POSITION;


SELECT
PREMIUM_TXN_ID,
POLICY_ID,
CUSTOMER_ID,
-- Date conversion
TRY_CONVERT(DATE, DUE_DATE, 103) AS DUE_DATE,
-- Convert 1900-01-01 to NULL
NULLIF(TRY_CONVERT(DATE, PAID_DATE, 103),'1900-01-01') AS PAID_DATE,
-- Numeric conversions
TRY_CONVERT(INT, PREMIUM_AMOUNT) AS PREMIUM_AMOUNT,
PAYMENT_STATUS,
PAYMENT_METHOD,
TRY_CONVERT(INT, PAYMENT_DELAY_DAYS) AS PAYMENT_DELAY_DAYS,
TRY_CONVERT(DECIMAL(10,2), CHANNEL_COST) AS CHANNEL_COST,
-- Payment delay segmentation
CASE
    WHEN TRY_CONVERT(INT, PAYMENT_DELAY_DAYS) IS NULL THEN 'UNKNOWN'
    WHEN TRY_CONVERT(INT, PAYMENT_DELAY_DAYS) <= 0 THEN 'ON TIME'
    WHEN TRY_CONVERT(INT, PAYMENT_DELAY_DAYS) <= 7 THEN '1-7 DAYS LATE'
    WHEN TRY_CONVERT(INT, PAYMENT_DELAY_DAYS) <= 30 THEN '8-30 DAYS LATE'
    ELSE '30+ DAYS LATE'
END AS PAYMENT_DELAY_BAND,
-- Payment status grouping
CASE
    WHEN PAYMENT_STATUS IN ('PAID', 'COMPLETED') THEN 'PAID'
    WHEN PAYMENT_STATUS IN ('PENDING', 'OVERDUE') THEN 'PENDING'
    ELSE 'FAILED'
END AS PAYMENT_STATUS_GROUP,
-- Channel cost percentage
CASE
    WHEN TRY_CONVERT(INT, PREMIUM_AMOUNT) > 0 THEN TRY_CONVERT(DECIMAL(10,2), CHANNEL_COST) * 100.0/ TRY_CONVERT(INT, PREMIUM_AMOUNT)
    ELSE NULL
END AS CHANNEL_COST_PCT,
-- Net premium
TRY_CONVERT(DECIMAL(12,2), PREMIUM_AMOUNT)- TRY_CONVERT(DECIMAL(12,2), CHANNEL_COST) AS NET_PREMIUM,
-- Payment method grouping
CASE
    WHEN PAYMENT_METHOD IN ('UPI', 'DEBIT CARD', 'CC', 'NET BANKING') THEN 'DIGITAL'
    WHEN PAYMENT_METHOD IN('CASH', 'CHEQUE', 'AUTO')THEN 'NON-DIGITAL'
    ELSE 'OTHER'
END AS PAYMENT_METHOD_GROUP,

-- Due date attributes
YEAR(TRY_CONVERT(DATE, DUE_DATE, 103)) AS DUE_YEAR,
MONTH(TRY_CONVERT(DATE, DUE_DATE, 103)) AS DUE_MONTH,

-- Paid date attributes
YEAR(NULLIF(TRY_CONVERT(DATE, PAID_DATE, 103),'1900-01-01')) AS PAID_YEAR,
MONTH(NULLIF(TRY_CONVERT(DATE, PAID_DATE, 103),'1900-01-01')) AS PAID_MONTH
FROM PREMIUMS;




--CREATE A PREMIMUM VIEW

--PREMIUM_VIEW

--PREMIUM_VIEW provides a cleaned and transformed version of the premium transaction data.

--Why the view is necessary

--This view combines:

--Data cleaning + financial calculations + payment segmentation + date analysis

--into one reusable layer.

--Business purpose

--The premium view supports:

--Premium collection analysis
--Payment behavior analysis
--Delinquency analysis
--Digital payment analysis
--Channel cost analysis
--Net premium analysis
--Financial reporting




CREATE VIEW PREMIUM_VIEW AS 


SELECT
PREMIUM_TXN_ID,
POLICY_ID,
CUSTOMER_ID,
-- Date conversion
TRY_CONVERT(DATE, DUE_DATE, 103) AS DUE_DATE,
-- Convert 1900-01-01 to NULL
NULLIF(TRY_CONVERT(DATE, PAID_DATE, 103),'1900-01-01') AS PAID_DATE,
-- Numeric conversions
TRY_CONVERT(INT, PREMIUM_AMOUNT) AS PREMIUM_AMOUNT,
PAYMENT_STATUS,
PAYMENT_METHOD,
TRY_CONVERT(INT, PAYMENT_DELAY_DAYS) AS PAYMENT_DELAY_DAYS,
TRY_CONVERT(DECIMAL(10,2), CHANNEL_COST) AS CHANNEL_COST,
-- Payment delay segmentation
CASE
    WHEN TRY_CONVERT(INT, PAYMENT_DELAY_DAYS) IS NULL THEN 'UNKNOWN'
    WHEN TRY_CONVERT(INT, PAYMENT_DELAY_DAYS) <= 0 THEN 'ON TIME'
    WHEN TRY_CONVERT(INT, PAYMENT_DELAY_DAYS) <= 7 THEN '1-7 DAYS LATE'
    WHEN TRY_CONVERT(INT, PAYMENT_DELAY_DAYS) <= 30 THEN '8-30 DAYS LATE'
    ELSE '30+ DAYS LATE'
END AS PAYMENT_DELAY_BAND,
-- Payment status grouping
CASE
    WHEN PAYMENT_STATUS IN ('PAID', 'COMPLETED') THEN 'PAID'
    WHEN PAYMENT_STATUS IN ('PENDING', 'OVERDUE') THEN 'PENDING'
    ELSE 'FAILED'
END AS PAYMENT_STATUS_GROUP,
-- Channel cost percentage
CASE
    WHEN TRY_CONVERT(INT, PREMIUM_AMOUNT) > 0 THEN TRY_CONVERT(DECIMAL(10,2), CHANNEL_COST) * 100.0/ TRY_CONVERT(INT, PREMIUM_AMOUNT)
    ELSE NULL
END AS CHANNEL_COST_PCT,
-- Net premium
TRY_CONVERT(DECIMAL(12,2), PREMIUM_AMOUNT)- TRY_CONVERT(DECIMAL(12,2), CHANNEL_COST) AS NET_PREMIUM,
-- Payment method grouping
CASE
    WHEN PAYMENT_METHOD IN ('UPI', 'DEBIT CARD', 'CC', 'NET BANKING') THEN 'DIGITAL'
    WHEN PAYMENT_METHOD IN('CASH', 'CHEQUE', 'AUTO')THEN 'NON-DIGITAL'
    ELSE 'OTHER'
END AS PAYMENT_METHOD_GROUP,

-- Due date attributes
YEAR(TRY_CONVERT(DATE, DUE_DATE, 103)) AS DUE_YEAR,
MONTH(TRY_CONVERT(DATE, DUE_DATE, 103)) AS DUE_MONTH,

-- Paid date attributes
YEAR(NULLIF(TRY_CONVERT(DATE, PAID_DATE, 103),'1900-01-01')) AS PAID_YEAR,
MONTH(NULLIF(TRY_CONVERT(DATE, PAID_DATE, 103),'1900-01-01')) AS PAID_MONTH
FROM PREMIUMS;




-----------------------------------------------------------------------------------------------

--6. RENEWALS Table

--The RENEWALS table focuses specifically on policy renewal activity.

--It contains information such as:

--Renewal ID
--Policy ID
--Customer ID
--Renewal due date
--Old premium
--New premium
--Premium increase percentage
--Claim history
--Loyalty years
--Renewal probability
--Renewal status
--Contact channel

--This transformation primarily focuses on renewal behavior and customer retention.

--1. Renewal Date Attributes

--The code creates:

--Renewal year
--Renewal month
--Renewal month name
--Renewal quarter
--Why necessary?

--This allows renewal activity to be analyzed over time.

--2. PREMIUM_CHANGE_AMOUNT

--The code calculates:

--New Premium − Old Premium

--Why necessary?

--This tells us the actual monetary change in premium at renewal.

--3. CALCULATED_PREMIUM_INCREASE_PCT

--The code calculates the percentage change between old and new premiums.

--Why necessary?

--The monetary increase alone can be misleading.

--For example:

--₹10,000 increase on ₹1,00,000 = 10%
--₹10,000 increase on ₹10,00,000 = 1%

--The percentage provides a fair comparison.

--4. PREMIUM_INCREASE_BAND

--Renewal premium changes are categorized into:

--Premium Decrease
--No Change
--0–5% Increase
--5–10% Increase
--10–20% Increase
--20%+ Increase
--Why necessary?

--This helps management understand how aggressively premiums are changing at renewal.

--It can also help investigate whether large premium increases affect renewal rates.

--5. LOYALTY_SEGMENT

--Customers are categorized based on loyalty years:

--New
--Established
--Loyal
--Highly Loyal
--Why necessary?

--This allows renewal behavior to be compared by customer loyalty.

--For example:

--Highly loyal customers may have a higher renewal probability.

--6. CONTACT_CHANNEL_GROUP

--Contact channels are grouped into:

--Digital
--Voice
--Personal

--For example:

--Digital:

--SMS
--Email
--WhatsApp

--Voice:

--Call
--Why necessary?

--This allows the company to evaluate which communication strategy is associated with better renewal outcomes.



SELECT * FROM RENEWALS
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'RENEWALS'
ORDER BY ORDINAL_POSITION;



SELECT 
RENEWAL_ID,
POLICY_ID,
CUSTOMER_ID,
RENEWAL_DUE_DATE,
YEAR(RENEWAL_DUE_DATE) AS RENEWAL_YEAR,
MONTH(RENEWAL_DUE_DATE) AS RENEWAL_MONTH,
DATENAME(MONTH,RENEWAL_DUE_DATE) AS RENEWAL_MONTH_NAME,
'Q'+CAST(DATEPART(QUARTER, RENEWAL_DUE_DATE) AS VARCHAR(1)) AS RENEWAL_DUE_QTR,
OLD_PREMIUM,
NEW_PREMIUM,
NEW_PREMIUM - OLD_PREMIUM AS PREMIUM_CHANGE_AMOUNT,
CASE
    WHEN OLD_PREMIUM > 0 THEN ((NEW_PREMIUM - OLD_PREMIUM) * 100.0) / OLD_PREMIUM
    ELSE NULL
END AS CALCULATED_PREMIUM_INCREASE_PCT,
CASE
    WHEN PREMIUM_INCREASE_PCT < 0
        THEN 'PREMIUM DECREASE'
    WHEN PREMIUM_INCREASE_PCT = 0
        THEN 'NO CHANGE'
    WHEN PREMIUM_INCREASE_PCT <= 5
        THEN '0-5% INCREASE'
    WHEN PREMIUM_INCREASE_PCT <= 10
        THEN '5-10% INCREASE'
    WHEN PREMIUM_INCREASE_PCT <= 20
        THEN '10-20% INCREASE'
    ELSE '20%+ INCREASE'
END AS PREMIUM_INCREASE_BAND,
PREMIUM_INCREASE_PCT, 
CLAIM_HISTORY_FLAG,
LOYALTY_YEARS,
CASE
    WHEN LOYALTY_YEARS < 2 THEN 'NEW'
    WHEN LOYALTY_YEARS < 5 THEN 'ESTABLISHED'
    WHEN LOYALTY_YEARS < 10 THEN 'LOYAL'
    ELSE 'HIGHLY LOYAL'
END AS LOYALTY_SEGMENT,
RENEWAL_PROBABILITY,
RENEWAL_STATUS,
CONTACT_CHANNEL,
CASE
    WHEN CONTACT_CHANNEL IN ('SMS', 'Email', 'WhatsApp')
        THEN 'DIGITAL'

    WHEN CONTACT_CHANNEL = 'CALL'
        THEN 'VOICE'

    ELSE  'PERSONAL'

END AS CONTACT_CHANNEL_GROUP

FROM RENEWALS


-- CREATE A VIEW FOR RENEWALS

--RENEWALS_VIEW

--The RENEWALS_VIEW combines all renewal-related calculations into one reusable analytical layer.

--Business purpose

--It supports:

--Renewal forecasting
--Customer retention
--Premium change analysis
--Loyalty analysis
--Renewal probability analysis
--Contact channel analysis
--Customer retention strategy

--This is particularly useful for identifying customers who are likely to renew, unlikely to renew, or require additional engagement.




CREATE VIEW RENEWALS_VIEW AS
SELECT 
RENEWAL_ID,
POLICY_ID,
CUSTOMER_ID,
RENEWAL_DUE_DATE,
YEAR(RENEWAL_DUE_DATE) AS RENEWAL_YEAR,
MONTH(RENEWAL_DUE_DATE) AS RENEWAL_MONTH,
DATENAME(MONTH,RENEWAL_DUE_DATE) AS RENEWAL_MONTH_NAME,
'Q'+CAST(DATEPART(QUARTER, RENEWAL_DUE_DATE) AS VARCHAR(1)) AS RENEWAL_DUE_QTR,
OLD_PREMIUM,
NEW_PREMIUM,
NEW_PREMIUM - OLD_PREMIUM AS PREMIUM_CHANGE_AMOUNT,
CASE
    WHEN OLD_PREMIUM > 0 THEN ((NEW_PREMIUM - OLD_PREMIUM) * 100.0) / OLD_PREMIUM
    ELSE NULL
END AS CALCULATED_PREMIUM_INCREASE_PCT,
CASE
    WHEN PREMIUM_INCREASE_PCT < 0
        THEN 'PREMIUM DECREASE'
    WHEN PREMIUM_INCREASE_PCT = 0
        THEN 'NO CHANGE'
    WHEN PREMIUM_INCREASE_PCT <= 5
        THEN '0-5% INCREASE'
    WHEN PREMIUM_INCREASE_PCT <= 10
        THEN '5-10% INCREASE'
    WHEN PREMIUM_INCREASE_PCT <= 20
        THEN '10-20% INCREASE'
    ELSE '20%+ INCREASE'
END AS PREMIUM_INCREASE_BAND,
PREMIUM_INCREASE_PCT, 
CLAIM_HISTORY_FLAG,
LOYALTY_YEARS,
CASE
    WHEN LOYALTY_YEARS < 2 THEN 'NEW'
    WHEN LOYALTY_YEARS < 5 THEN 'ESTABLISHED'
    WHEN LOYALTY_YEARS < 10 THEN 'LOYAL'
    ELSE 'HIGHLY LOYAL'
END AS LOYALTY_SEGMENT,
RENEWAL_PROBABILITY,
RENEWAL_STATUS,
CONTACT_CHANNEL,
CASE
    WHEN CONTACT_CHANNEL IN ('SMS', 'Email', 'WhatsApp')
        THEN 'DIGITAL'

    WHEN CONTACT_CHANNEL = 'CALL'
        THEN 'VOICE'

    ELSE  'PERSONAL'

END AS CONTACT_CHANNEL_GROUP

FROM RENEWALS
------------------------------------------------------------------------------------

--7. UNDERWRITING Table

--The UNDERWRITING table focuses on the risk assessment performed before or during policy issuance.

--It contains information such as:

--Underwriting ID
--Policy ID
--Customer ID
--Age
--Health score
--Lifestyle
--Medical history
--Smoker status
--BMI
--Occupation risk
--Credit score
--Underwriting score
--Decision
--Premium loading percentage

--This section primarily transforms raw health and risk information into underwriting categories.

--1. HEALTH_SCORE_BAND

--Health scores are categorized into:

--Excellent
--Good
--Average
--Poor
--Why necessary?

--It makes the numerical health score easier to interpret.

--It can be used to compare:

--Health condition
--Policy pricing
--Underwriting decisions
--Premium loading
--2. BMI_CATEGORY

--BMI is categorized into:

--Underweight
--Normal
--Overweight
--Obese Class I
--Obese Class II
--Obese Class III
--Why necessary?

--BMI is a numerical measurement, but the categories provide a more meaningful analytical classification.

--This can help analyze relationships between BMI, underwriting decisions, and premium loading.

--3. Other Risk Attributes

--The view also retains:

--Lifestyle
--Medical history flag
--Smoker flag
--Occupation risk
--Credit score
--Underwriting score
--Decision
--Premium loading
--Why necessary?

--These variables provide multiple dimensions for evaluating insurance risk.

--For example, the business can analyze whether certain risk factors are associated with:

--Higher premium loading
--Policy rejection
--Different underwriting decisions
--Higher underwriting scores





select * from underwriting


SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'underwriting'
ORDER BY ORDINAL_POSITION;




select 
UNDERWRITING_ID,
POLICY_ID,
CUSTOMER_ID,
AGE,
HEALTH_SCORE,
CASE
    WHEN HEALTH_SCORE >= 80 THEN 'EXCELLENT'
    WHEN HEALTH_SCORE >= 60 THEN 'GOOD'
    WHEN HEALTH_SCORE >= 40 THEN 'AVERAGE'
    ELSE 'POOR'
END AS HEALTH_SCORE_BAND,
LIFESTYLE,
MEDICAL_HISTORY_FLAG,
SMOKER_FLAG,
BMI,
CASE
    WHEN BMI < 18.5 THEN 'UNDERWEIGHT'
    WHEN BMI < 25 THEN 'NORMAL'
    WHEN BMI < 30 THEN 'OVERWEIGHT'
    WHEN BMI < 35 THEN 'OBESE CLASS I'
    WHEN BMI < 40 THEN 'OBESE CLASS II'
    ELSE 'OBESE CLASS III'
END AS BMI_CATEGORY,
OCCUPATION_RISK,     
CREDIT_SCORE,
UNDERWRITING_SCORE,
DECISION,
PREMIUM_LOADING_PCT
from underwriting


UPDATE underwriting
SET DECISION = 'PENDING'
WHERE   DECISION = 'Approved with Loading';
-

---CREATE A VIEW FOR THE UNDERWRITE TABLE

--UNDERWRITING_VIEW

--UNDERWRITING_VIEW combines the original underwriting information with:

--Health score band
--BMI category
--Why the view is necessary

--It provides a standardized underwriting analytics layer without modifying the underlying raw underwriting data.

--Business purpose

--The underwriting view supports:

--Risk assessment
--Policy acceptance/rejection analysis
--Health-risk analysis
--Premium loading analysis
--Customer risk analysis
--Underwriting performance analysis


CREATE VIEW UNDERWRITING_VIEW AS 
select 
UNDERWRITING_ID,
POLICY_ID,
CUSTOMER_ID,
AGE,
HEALTH_SCORE,
CASE
    WHEN HEALTH_SCORE >= 80 THEN 'EXCELLENT'
    WHEN HEALTH_SCORE >= 60 THEN 'GOOD'
    WHEN HEALTH_SCORE >= 40 THEN 'AVERAGE'
    ELSE 'POOR'
END AS HEALTH_SCORE_BAND,
LIFESTYLE,
MEDICAL_HISTORY_FLAG,
SMOKER_FLAG,
BMI,
CASE
    WHEN BMI < 18.5 THEN 'UNDERWEIGHT'
    WHEN BMI < 25 THEN 'NORMAL'
    WHEN BMI < 30 THEN 'OVERWEIGHT'
    WHEN BMI < 35 THEN 'OBESE CLASS I'
    WHEN BMI < 40 THEN 'OBESE CLASS II'
    ELSE 'OBESE CLASS III'
END AS BMI_CATEGORY,
OCCUPATION_RISK,     
CREDIT_SCORE,
UNDERWRITING_SCORE,
DECISION,
PREMIUM_LOADING_PCT
from underwriting;




SELECT * FROM AGENTS_VIEW
SELECT * FROM CLAIMS_VIEW
SELECT * FROM POLICY_VIEW
SELECT * FROM CUSTOMER_VIEW
SELECT * FROM PREMIUM_VIEW
SELECT * FROM RENEWALS_VIEW
SELECT * FROM UNDERWRITING_VIEW








--=================================================================


Select 
count(distinct *),
a.POLICY_ID,
a.CUSTOMER_ID,
a.POLICY_TYPE,
a.SALES_CHANNEL,
a.AGENT_ID,
a.POLICY_START_DATE,
a.POLICY_END_DATE,
a.SUM_INSURED,
a.ANNUAL_PREMIUM,
a.PAYMENT_MODE,
a.RISK_SCORE,
a.RISK_BAND,
a.POLICY_STATUS,
a.DISCOUNT_PCT,
a.COMMISSION_PCT,
a.POLICY_DURATION_DAYS,
a.POLICY_DURATION_SEGMENT,
a.POLICY_START_YEAR,
a.POLICY_END_YEAR,
a.POLICY_START_MONTH,
a.POLICY_START_MONTH_NAME,
a.POLICY_START_QTR,
a.SALES_CHANNEL_GROUP,
a.SUM_INSURED_BAND,
a.PREMIUM_BAND,
a.PREMIUM_TO_SUM_INSURED_PCT,
a.PREMIUM_RATE_BAND,
a.CALCULATED_RISK_BAND,
a.POLICY_STATUS_GROUP,
a.DAYS_TO_EXPIRY,
a.EXPIRY_SEGMENT,
a.RENEWAL_OPPORTUNITY_FLAG,
a.DISCOUNT_BAND,
a.COMMISSION_BAND,
a.NET_PREMIUM,
a.COMMISSION_AMOUNT,
a.PAYMENT_FREQUENCY_GROUP,
a.POLICY_SEGMENT,
b.CLAIM_ID,
b.CUSTOMER_ID,
b.CLAIM_TYPE,
b.INCIDENT_DATE,
b.REPORTED_DATE,
b.CLAIM_AMOUNT,
b.CLAIM_STATUS,
b.SETTLEMENT_AMOUNT,
b.PROCESSING_DAYS,
b.FRAUD_FLAG,
b.FRAUD_SCORE,
b.SOURCE,
b.CLAIM_SEVERITY,
b.REPROTING_DELAY,
b.UNSETTLED_AMOUNT,
b.SETTLEMENT_RATE,
b.FRAUD_RISK_LEVEL,
b.INCIDENT_YEAR,	
b.INCIDENT_MONTH,	
b.INCIDENT_MONTH_NAME,
b.INCIDENT_QTR
from POLICY_VIEW as a
left join 
CLAIMS_VIEW as b
on a.policy_id=b.policy_id;




SELECT *
FROM POLICY_VIEW AS a
LEFT JOIN CLAIMS_VIEW AS b
    ON a.POLICY_ID = b.POLICY_ID
WHERE b.CLAIM_ID IS NULL;





SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT(DISTINCT a.POLICY_ID) AS DISTINCT_POLICIES,
    COUNT(DISTINCT b.CLAIM_ID) AS DISTINCT_CLAIMS
FROM POLICY_VIEW AS a
LEFT JOIN CLAIMS_VIEW AS b
    ON a.POLICY_ID = b.POLICY_ID;




 select * from INSURANCE_DATA_MODEL
