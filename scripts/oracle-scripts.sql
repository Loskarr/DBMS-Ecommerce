CREATE PLUGGABLE DATABASE ecommercedb  
ADMIN USER eadm  
IDENTIFIED BY pwd  
FILE_NAME_CONVERT = ('pdbseed', 'pdbecommerce');

alter PLUGGABLE DATABASE ecommercedb open read write;

alter session set container = ecommercedb;

grant dba to eadm;

-- conn eadm/pwd@localhost:1521/ecommercedb;
-- Create product and product_category tables first
--SELECT table_name FROM user_tables WHERE table_name IN ('PRODUCT_CATEGORY', 'PRODUCT', 'PRODUCT_ITEM', 'PROMOTION', 'VARIATION', 'VARIATION_OPTION', 'PRODUCT_CONFIGURATION');
SELECT table_name FROM user_tables;

BEGIN
  FOR t IN (SELECT table_name FROM user_tables ) 
  LOOP
--    EXECUTE IMMEDIATE 'DROP TABLE ' || v_table_name;
    BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name;
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLCODE = -942 THEN
          RAISE;
        END IF;
    END;
  END LOOP;
END;
/

-- Create table product_category
CREATE TABLE product_category (
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    parent_category_id NUMBER,
    category_name VARCHAR2(100),
    PRIMARY KEY(id)
);

-- Create table product
CREATE TABLE product (
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    category_id NUMBER,
    name VARCHAR2(100),
    description VARCHAR2(255),
    product_image VARCHAR2(255),
    product_status varchar2(10) default 'AVAIL' --RESTOCK OUTOFSTOCK UNAVAIL
    PRIMARY KEY(id)
);

-- Create other tables
CREATE TABLE product_item (
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    product_id NUMBER,
    SKU VARCHAR2(50),
    quantity_in_stock NUMBER,
    price NUMBER,
    product_item_status varchar2(10) default 'AVAIL', -- SOLDOUT UNVAIL
    PRIMARY KEY(id)
);
CREATE TABLE product_image (
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    product_item_id NUMBER,
    image_url VARCHAR2(255),
    PRIMARY KEY(id)
);
CREATE TABLE promotion (
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    name VARCHAR2(100),
    description VARCHAR2(255),
    discount_rate NUMBER,
    start_date DATE,
    end_date DATE,
    PRIMARY KEY(id)
);

CREATE TABLE promotion_category (
    category_id NUMBER,
    promotion_id NUMBER
);

CREATE TABLE variation (
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    category_id NUMBER,
    name VARCHAR2(100),
    PRIMARY KEY(id)
);

CREATE TABLE variation_option (
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    variation_id NUMBER,
    value VARCHAR2(100),
    PRIMARY KEY(id)
);

CREATE TABLE product_configuration (
    product_item_id NUMBER,
    variation_option_id NUMBER,
    PRIMARY KEY(product_item_id, variation_option_id)
);

INSERT INTO product ( category_id, name, description, product_image)
VALUES (1, 'Laptop', 'High-performance laptop', 'laptop.jpg');

INSERT INTO product_category (id, parent_category_id, category_name)
VALUES (1, NULL, 'Electronics');

INSERT INTO product_category (id, parent_category_id, category_name)
VALUES (2, NULL, 'Clothing');

INSERT INTO product_category (id, parent_category_id, category_name) 
VALUES (3,1, 'Laptops');

INSERT INTO product_item ( product_id, SKU, quantity_in_stock, price)
VALUES (1, 'SKU123', 10, 1500.00);

INSERT INTO product ( category_id, name, description, product_image)
VALUES (1, 'Smartphone', 'Latest smartphone model', 'smartphone.jpg');

INSERT INTO product_item ( product_id, SKU, quantity_in_stock, price)
VALUES (2, 'SKU456', 5,  1000.00);

INSERT INTO product ( category_id, name, description, product_image)
VALUES (2, 'T-Shirt', 'Comfortable cotton T-shirt', 'tshirt.jpg');

INSERT INTO product_item ( product_id, SKU, quantity_in_stock, price)
VALUES (3, 'SKU789', 20,  20.00);

INSERT INTO product_image (product_item_id, image_url)
VALUES (1, 'smartphone.jpg');

INSERT INTO product_image (product_item_id, image_url)
VALUES (2, 'tshirt.jpg');

-- Insert sample data into promotion table
INSERT INTO promotion ( name, description, discount_rate, start_date, end_date)
VALUES ('Summer Sale', 'Up to 50% off on selected items', 0.5, TO_DATE('2024-06-01', 'YYYY-MM-DD'), TO_DATE('2024-07-01', 'YYYY-MM-DD'));

INSERT INTO promotion ( name, description, discount_rate, start_date, end_date)
VALUES ('Clearance Sale', 'Last chance to buy at discounted prices', 0.3, TO_DATE('2024-04-01', 'YYYY-MM-DD'), TO_DATE('2024-04-30', 'YYYY-MM-DD'));

-- Insert sample data into variation and variation_option tables
INSERT INTO variation ( category_id, name)
VALUES (1, 'Color');

INSERT INTO variation_option ( variation_id, value)
VALUES (1, 'Red');

INSERT INTO variation_option ( variation_id, value)
VALUES (1, 'Blue');

-- Insert sample data into promotion_category table
INSERT INTO promotion_category (category_id, promotion_id)
VALUES (1, 1);

INSERT INTO promotion_category (category_id, promotion_id)
VALUES (1, 2);

-- Insert sample data into product_configuration table
INSERT INTO product_configuration (product_item_id, variation_option_id)
VALUES (1, 1);

INSERT INTO product_configuration (product_item_id, variation_option_id)
VALUES (1, 2);

INSERT INTO product_configuration (product_item_id, variation_option_id)
VALUES (3, 2);

-- Add foreign key constraints after inserting data into tables
ALTER TABLE product
ADD CONSTRAINT fk_product_category_id FOREIGN KEY (category_id) REFERENCES product_category(id) ON DELETE SET NULL;

ALTER TABLE product_item
ADD CONSTRAINT fk_product_id FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE;

ALTER TABLE product_image
ADD CONSTRAINT fk_product_item_id FOREIGN KEY (product_item_id) REFERENCES product_item(id) ON DELETE CASCADE

ALTER TABLE promotion_category
ADD CONSTRAINT fk_promotion_category_id FOREIGN KEY (category_id) REFERENCES product_category(id) ON DELETE SET NULL;

ALTER TABLE promotion_category
ADD CONSTRAINT fk_promotion_id FOREIGN KEY (promotion_id) REFERENCES promotion(id) ON DELETE SET NULL;

ALTER TABLE variation
ADD CONSTRAINT fk_variation_category FOREIGN KEY (category_id) REFERENCES product_category(id) ON DELETE SET NULL;

ALTER TABLE variation_option
ADD CONSTRAINT fk_variation_id FOREIGN KEY (variation_id) REFERENCES variation(id) ON DELETE CASCADE;

ALTER TABLE product_configuration
ADD CONSTRAINT fk_pc_product_item_id FOREIGN KEY (product_item_id) REFERENCES product_item(id) ON DELETE CASCADE;

ALTER TABLE product_configuration
ADD CONSTRAINT fk_pc_variation_option_id FOREIGN KEY (variation_option_id) REFERENCES variation_option(id) ON DELETE SET NULL;

-- Create table shop_order
CREATE TABLE shop_order(
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    user_id NUMBER,
    order_date DATE,
    payment_method VARCHAR2(100),
    shipping_address VARCHAR2(255),
    shipping_method_id NUMBER,
    order_total NUMBER,
    order_status VARCHAR2(100),
    paid BOOLEAN,
    PRIMARY KEY(id)
);

-- Create table shipping_method
CREATE TABLE shipping_method(
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    name VARCHAR2(100),
    price NUMBER,
    PRIMARY KEY(id)
);

-- Create table order_status
CREATE TABLE order_status(
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    status VARCHAR2(100),
    PRIMARY KEY(id)
);

-- Create table order_line
CREATE TABLE order_line(
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    product_item_id NUMBER,
    order_id NUMBER,
    quantity NUMBER,
    PRIMARY KEY(id)
    -- PRIMARY KEY(product_item_id, order_id)
);

CREATE TABLE site_user (
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    email_address VARCHAR2(255),
    phone_number VARCHAR2(20),
    picture_url VARCHAR2(255),
    password VARCHAR2(255),
    last_name VARCHAR2(100),
    first_name VARCHAR2(100),
    role varchar2(3) default 'cus',
    PRIMARY KEY(id)
);

CREATE TABLE user_wallet(
    user_id NUMBER PRIMARY KEY,
    wallet_balance NUMBER DEFAULT =0
);
-- Create table address
CREATE TABLE address (
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    street_number VARCHAR2(50),
    address_line1 VARCHAR2(255),
    address_line2 VARCHAR2(255),
    city VARCHAR2(100),
    region VARCHAR2(100),
    postal_code VARCHAR2(20),
    country_id NUMBER,
    PRIMARY KEY(id)
);

-- Create table user_address
CREATE TABLE user_address (
    user_id NUMBER,
    address_id NUMBER,
    is_default boolean, -- Assuming 1 for default, 0 for non-default
    CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES site_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_address_id FOREIGN KEY (address_id) REFERENCES address(id) ON DELETE CASCADE
);

-- Create table country
CREATE TABLE country (
    id NUMBER GENERATED BY DEFAULT AS IDENTITY(START with 1 INCREMENT by 1),
    country_name VARCHAR2(100),
    PRIMARY KEY(id)
);
-- Insert sample data into country table
INSERT INTO country (country_name)
VALUES ('USA');

INSERT INTO country (country_name)
VALUES ('Canada');

INSERT INTO country (country_name)
VALUES ('UK');

INSERT INTO country (country_name)
VALUES ('Germany');

INSERT INTO country (country_name)
VALUES ('France');

-- Insert sample data into site_user table
INSERT INTO site_user (email_address, phone_number, picture_url, password, last_name, first_name)
VALUES ('user1@example.com', '123456789', 'https://example.com/user1.jpg', 'password1', 'Doe', 'John');

INSERT INTO site_user (email_address, phone_number, picture_url, password, last_name, first_name)
VALUES ('user2@example.com', '987654321', 'https://example.com/user2.jpg', 'password2', 'Smith', 'Jane');

-- Insert sample data into address table
INSERT INTO address (street_number, address_line1, address_line2, city, region, postal_code, country_id)
VALUES ('123', 'Main Street', 'Apt 1', 'New York', 'NY', '10001', 1);

INSERT INTO address (street_number, address_line1, address_line2, city, region, postal_code, country_id)
VALUES ('456', 'Maple Avenue', '', 'Toronto', 'ON', 'M5G 2N2', 2);

-- Insert sample data into user_address table
INSERT INTO user_address (user_id, address_id, is_default)
VALUES (1, 1, true); -- User 1's default address

INSERT INTO user_address (user_id, address_id, is_default)
VALUES (2, 2, true); -- User 2's default address

-- Insert sample data into shipping_method table
INSERT INTO shipping_method (name, price)
VALUES ('Standard Shipping', 10.00);

INSERT INTO shipping_method (name, price)
VALUES ('Express Shipping', 20.00);

-- Insert sample data into order_status table
INSERT INTO order_status (status)
VALUES ('Pending');

INSERT INTO order_status (status)
VALUES ('Processing');

-- Insert sample data into shop_order table
INSERT INTO shop_order (user_id, order_date, payment_method, shipping_address, shipping_method_id, order_total, order_status_id)
VALUES (1, TO_DATE('2024-04-06', 'YYYY-MM-DD'), 'Credit Card', '123 Main St, City, Country', 1, 100.00, 1);

INSERT INTO shop_order (user_id, order_date, payment_method, shipping_address, shipping_method_id, order_total, order_status_id)
VALUES (2, TO_DATE('2024-04-07', 'YYYY-MM-DD'), 'PayPal', '456 Elm St, City, Country', 2, 150.00, 2);

INSERT INTO shop_order (user_id, order_date, payment_method, shipping_address, shipping_method_id, order_total, order_status_id)
VALUES (1, TO_DATE('2024-04-08', 'YYYY-MM-DD'), 'Cash on Delivery', '789 Oak St, City, Country', 1, 200.00, 1);

INSERT INTO shop_order (user_id, order_date, payment_method, shipping_address, shipping_method_id, order_total, order_status_id)
VALUES (2, TO_DATE('2024-04-09', 'YYYY-MM-DD'), 'Credit Card', '101112 Pine St, City, Country', 2, 250.00, 2);

INSERT INTO shop_order (user_id, order_date, payment_method, shipping_address, shipping_method_id, order_total, order_status_id)
VALUES (1, TO_DATE('2024-04-10', 'YYYY-MM-DD'), 'PayPal', '131415 Cedar St, City, Country', 1, 300.00, 1);

-- Insert sample data into order_line table (assuming product_item_id and order_id exist)
-- You need to replace the values for product_item_id and order_id with actual values from your database

-- For simplicity, let's insert one order line per order
INSERT INTO order_line (product_item_id, order_id, quantity)
VALUES (1, 1, 2);

INSERT INTO order_line (product_item_id, order_id, quantity)
VALUES (2, 2, 1);

INSERT INTO order_line (product_item_id, order_id, quantity)
VALUES (3, 3, 3);

--INSERT INTO order_line (product_item_id, order_id, quantity)
--VALUES (4, 4, 2);
--
--INSERT INTO order_line (product_item_id, order_id, quantity)
--VALUES (5, 5, 1);


-- Add foreign key constraints after inserting data into tables
ALTER TABLE shop_order
ADD CONSTRAINT fk_shipping_method FOREIGN KEY (shipping_method_id) REFERENCES shipping_method(id) ON DELETE SET NULL;

ALTER TABLE shop_order
ADD CONSTRAINT fk_order_status FOREIGN KEY (order_status_id) REFERENCES order_status(id) ON DELETE SET NULL;

ALTER TABLE order_line
ADD CONSTRAINT fk_order_product_item FOREIGN KEY (product_item_id) REFERENCES product_item(id) ON DELETE CASCADE;

ALTER TABLE order_line
ADD CONSTRAINT fk_shop_order FOREIGN KEY (order_id) REFERENCES shop_order(id) ON DELETE SET NULL;

CREATE OR REPLACE PROCEDURE Create_Product (
    p_name              IN VARCHAR2,
    p_description       IN VARCHAR2,
    p_category_id       IN NUMBER,
    p_product_image     IN VARCHAR2,
    p_price             IN NUMBER,
    p_sku               IN VARCHAR2,
    p_quantity_in_stock IN NUMBER,
    p_product_item_image_list IN SYS.ODCIVARCHAR2LIST -- List of product item images
)
IS
    v_product_id   NUMBER;
    v_product_item_id   NUMBER; -- Declare a separate variable for product item ID
BEGIN
    -- Insert a new product into the product table
    INSERT INTO product (category_id, name, description, product_image)
    VALUES (p_category_id, p_name, p_description, p_product_image)
    RETURNING id INTO v_product_id;

    -- Insert a new product item into the product_item table
    INSERT INTO product_item (product_id, SKU, quantity_in_stock, price)
    VALUES (v_product_id, p_sku, p_quantity_in_stock, p_price)
    RETURNING id INTO v_product_item_id; -- Use a separate variable to capture the product item ID
    
    -- Insert product item images into the product_image table
    FOR i IN 1..p_product_item_image_list.COUNT LOOP
        INSERT INTO product_image (product_item_id, image_url)
        VALUES (v_product_item_id, p_product_item_image_list(i)); -- Use the product item ID here
    END LOOP;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Product created successfully with ID: ' || v_product_id);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error creating product: ' || SQLERRM);
        RAISE;
END Create_Product;
/


CREATE MATERIALIZED VIEW products_retrieve_materialize_view
refresh complete 
as 
select 
    pi.*,
    p.name,
    p.description,
    p.product_image as image_main,
    pc.category_name,
    pc.id as product_category_id
from product_item pi
inner join product p on p.id = pi.product_id
left join product_category pc on pc.id = p.category_id ;

CREATE OR REPLACE TRIGGER trg_product_after_insert
AFTER INSERT ON product
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    -- Your trigger logic here
    -- Perform necessary operations
    -- Commit or rollback if needed (within the autonomous transaction)
    DBMS_MVIEW.REFRESH('products_retrieve_materialize_view');
    COMMIT; -- Example of a commit within the autonomous transaction
END;
/
CREATE MATERIALIZED VIEW products_with_promotion_materialize_view
REFRESH COMPLETE
AS
SELECT 
    prmv.*, 
    pr.name AS promotion_name, 
    pr.description AS promotion_description, 
    pr.discount_rate, 
    pr.start_date, 
    pr.end_date,
    (prmv.price - (prmv.price * pr.discount_rate)) AS price_after_discount,
    CASE
        WHEN pr.start_date <= CURRENT_DATE AND pr.end_date > CURRENT_DATE THEN 'Available'
        WHEN pr.start_date > CURRENT_DATE THEN 'Upcoming'
        ELSE 'Expired'
    END AS promotion_status,
    GREATEST(0, TO_DATE(pr.end_date, 'YYYY-MM-DD') - TO_DATE(CURRENT_DATE, 'YYYY-MM-DD')) AS date_left
FROM 
    products_retrieve_materialize_view prmv
LEFT JOIN 
    product_category pc ON prmv.product_category_id = pc.id
LEFT JOIN 
    promotion_category pc2 ON pc.id = pc2.category_id
LEFT JOIN 
    promotion pr ON pc2.promotion_id = pr.id;

CREATE MATERIALIZED VIEW products_with_available_promotion_materialize_view
REFRESH COMPLETE
AS
SELECT 
    prmv.*, 
    pr.name AS promotion_name, 
    pr.description AS promotion_description, 
    pr.discount_rate, 
    pr.start_date, 
    pr.end_date,
    (prmv.price - (prmv.price * pr.discount_rate)) AS price_after_discount,
    'Available' AS promotion_status,
    GREATEST(0, TO_DATE(pr.end_date, 'YYYY-MM-DD') - TO_DATE(CURRENT_DATE, 'YYYY-MM-DD')) AS date_left
FROM 
    products_retrieve_materialize_view prmv
LEFT JOIN 
    product_category pc ON prmv.product_category_id = pc.id
LEFT JOIN 
    promotion_category pc2 ON pc.id = pc2.category_id
LEFT JOIN 
    promotion pr ON pc2.promotion_id = pr.id
WHERE 
    pr.start_date <= CURRENT_DATE 
    AND pr.end_date > CURRENT_DATE;
    
select * from products_with_promotion_materialize_view;