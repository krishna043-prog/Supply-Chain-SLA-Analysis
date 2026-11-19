-- 1. Staging Table for Raw CSV Import
CREATE TABLE staging_dataco (
    type TEXT, days_for_shipping_real TEXT, days_for_shipment_scheduled TEXT,
    benefit_per_order TEXT, sales_per_customer TEXT, delivery_status TEXT,
    late_delivery_risk TEXT, category_id TEXT, category_name TEXT,
    customer_city TEXT, customer_country TEXT, customer_email TEXT,
    customer_fname TEXT, customer_id TEXT, customer_lname TEXT,
    customer_password TEXT, customer_segment TEXT, customer_state TEXT,
    customer_street TEXT, customer_zipcode TEXT, department_id TEXT,
    department_name TEXT, latitude TEXT, longitude TEXT, market TEXT,
    order_city TEXT, order_country TEXT, order_customer_id TEXT,
    order_date_dateorders TEXT, order_id TEXT, order_item_cardprod_id TEXT,
    order_item_discount TEXT, order_item_discount_rate TEXT, order_item_id TEXT,
    order_item_product_price TEXT, order_item_profit_ratio TEXT,
    order_item_quantity TEXT, sales TEXT, order_item_total TEXT,
    order_profit_per_order TEXT, order_region TEXT, order_state TEXT,
    order_status TEXT, order_zipcode TEXT, product_card_id TEXT,
    product_category_id TEXT, product_description TEXT, product_image TEXT,
    product_name TEXT, product_price TEXT, product_status TEXT,
    shipping_date_dateorders TEXT, shipping_mode TEXT
);

--Verification query
SELECT COUNT(*) FROM staging_dataco;

--2. Core Supply Chain Table
CREATE TABLE supply_chain_raw (
    order_id INT NOT NULL,
    days_for_shipping_real INT,
    days_for_shipment_scheduled INT,
    delivery_status VARCHAR(50),
    order_region VARCHAR(100),
    category_name VARCHAR(100),
    product_price NUMERIC(10,2)
);

--Load Typed Data from Staging
INSERT INTO supply_chain_raw (
    order_id, days_for_shipping_real, days_for_shipment_scheduled,
    delivery_status, order_region, category_name, product_price
)
SELECT 
    order_id::INT,
    days_for_shipping_real::INT,
    days_for_shipment_scheduled::INT,
    delivery_status,
    order_region,
    category_name,
    product_price::NUMERIC(10, 2)
FROM staging_dataco;

--Verification query
SELECT * FROM supply_chain_raw;

-- View 1: Regional SLA Performance
CREATE OR REPLACE VIEW view_regional_sla AS
SELECT 
    order_region,
    COUNT(order_id) AS total_orders,
    SUM(CASE WHEN delivery_status = 'Late delivery' THEN 1 ELSE 0 END) AS late_orders,
    ROUND((SUM(CASE WHEN delivery_status = 'Late delivery' THEN 1 ELSE 0 END)::NUMERIC / COUNT(order_id)) * 100, 2) AS late_delivery_rate_pct,
    ROUND(AVG(days_for_shipping_real), 1) AS avg_actual_shipping_days
FROM supply_chain_raw
GROUP BY order_region;

--Verification query
SELECT * FROM view_regional_sla
ORDER BY late_delivery_rate_pct DESC;


-- View 2: Inventory Operational Friction
CREATE OR REPLACE VIEW view_product_friction AS
SELECT 
    category_name,
    COUNT(order_id) AS units_shipped,
    ROUND(AVG(product_price), 2) AS avg_item_price,
    ROUND(AVG(days_for_shipping_real - days_for_shipment_scheduled), 2) AS avg_days_overdue
FROM supply_chain_raw
GROUP BY category_name
HAVING COUNT(order_id) > 100;

--Verification query
SELECT * FROM view_product_friction
ORDER BY avg_days_overdue DESC;


