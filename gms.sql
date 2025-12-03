create database gms;

use gms;

--TABLES:
--Customer Table
CREATE TABLE customer (
    cust_id INT PRIMARY KEY,
    cust_name VARCHAR(255),
    cust_phone VARCHAR(15),
    cust_type VARCHAR(20),
);

select * from customer;

--Produvt Table
CREATE TABLE product (
    prod_id INT PRIMARY KEY,
    prod_name VARCHAR(255),
    prod_price DOUBLE PRECISION ,
    prod_quantity INT ,
    prod_group VARCHAR(20)
);
select * from product;

--Supplier Table
create table supplier
(s_id int primary key,
factory_name varchar(60),
focal_person varchar(80),
s_date date,
address varchar(80),
bank varchar(70),
branch varchar(50),
account_no bigint,
contact bigint,
s_type varchar(30),
s_status varchar(30));

select * from supplier;

--PCls Table
CREATE TABLE PCls (
    pcl_no INT PRIMARY KEY,
    p_date DATE NOT NULL,
    created_by VARCHAR(80) NOT NULL,
    date_effect DATE NOT NULL,
    prod_id INT NOT NULL,
    p_status VARCHAR(40),
    onhand_rate DOUBLE PRECISION  CHECK (onhand_rate > 0),
    last_rate DOUBLE PRECISION  CHECK (last_rate > 0),
    diff AS (onhand_rate - last_rate) PERSISTED,
    CONSTRAINT fk_product_id FOREIGN KEY (prod_id) REFERENCES product (prod_id) ON DELETE CASCADE
);
select * from PCls;

--Inventory Table
CREATE TABLE inventory (
  prod_id INT  NULL,
  Quantaisle INT DEFAULT NULL,
  Quantstore INT DEFAULT NULL,
  CONSTRAINT fkprod_id FOREIGN KEY (prod_id) REFERENCES product (prod_id) ON DELETE CASCADE
);

select * from inventory

--Employee Table
create table Employee
(
	emp_id int not null,
    name varchar(45) not null,
    dob varchar(45) not null,
    eType varchar(45) not null,
    doj varchar(45) not null,
    primary key (emp_id)
)
Select * from Employee
--Users Table
create table users
(username varchar(50),
passward int,
emp_id int not null,
primary key(emp_id),
CONSTRAINT fk_emp_id FOREIGN KEY (emp_id) REFERENCES Employee (emp_id) ON DELETE CASCADE
);
Select * from users
--Sales Table
CREATE TABLE sales (
  Transno INT PRIMARY KEY,
  amount DOUBLE PRECISION ,
  cust_id INT ,
  emp_id int not null,
  exchange DOUBLE PRECISION  DEFAULT NULL,
  discount DOUBLE PRECISION  DEFAULT NULL,
  transtype VARCHAR(45) DEFAULT NULL,
  posteddate DATE DEFAULT NULL,
  postedby varchar(45) DEFAULT NULL,
  paid_amount DOUBLE PRECISION  DEFAULT NULL,
  CONSTRAINT fk_cust_id FOREIGN KEY (cust_id) REFERENCES customer(cust_id) ON DELETE CASCADE,
  CONSTRAINT fk_empid FOREIGN KEY (emp_id) REFERENCES users (emp_id) ON DELETE CASCADE

);
select * from sales

--Sales Child Table
CREATE TABLE sales_child (
  Transno INT NOT NULL,
  prod_id INT NOT NULL,
  quantity INT  NOT NULL,
  rate DOUBLE PRECISION  NOT NULL,
  entry_date DATE NOT NULL,
  prod_amount DOUBLE PRECISION  NOT NULL,
  PRIMARY KEY (Transno, prod_id),
  CONSTRAINT fk_Transno FOREIGN KEY (Transno) REFERENCES sales (Transno) ON DELETE CASCADE,
  CONSTRAINT fk_prod_id FOREIGN KEY (prod_id) REFERENCES product (prod_id) ON DELETE CASCADE
);
select * from sales_child
--Refund Table 
CREATE TABLE refund (
  refund_no int NOT NULL,
  prod_id int DEFAULT NULL,
  quantity int DEFAULT NULL,
  rate double precision DEFAULT NULL,
  date date DEFAULT NULL,
  refundedby int DEFAULT NULL,
  Transno int DEFAULT NULL,
  PRIMARY KEY (refund_no),
  CONSTRAINT prodid_for_refund FOREIGN KEY (Transno, prod_id) REFERENCES sales_child (Transno, prod_id),
  CONSTRAINT sales_refund_transno FOREIGN KEY (Transno) REFERENCES sales (Transno) ON DELETE CASCADE
);
select * from refund
--PurchaseOrder Table
create table PurchaseOrder
(
	orderNo int not null,
    orderDate varchar(45) not null,
    s_id int not null,
	emp_id int not null,
    quantity int not null,
    costValue varchar(45) not null,
    saleValue varchar(45) not null,
    orderStatus varchar(45) not null,
    appDate varchar(45) not null,
    appBy varchar(45) not null,
    primary key (orderNo),
    constraint supID foreign key (s_id) references supplier(s_id) ON DELETE CASCADE,
	CONSTRAINT emp_id FOREIGN KEY (emp_id) REFERENCES Employee (emp_id) ON DELETE CASCADE
);

select * from PurchaseOrder;

--ProdOrder Table
create table ProdOrder
(
	orderNo int not null,
    prod_id int not null,
	primary key(orderNo, prod_id),
    constraint fkprod foreign key (prod_id) references product(prod_id) ON DELETE CASCADE,
	constraint fkpurchase_o foreign key (orderNo) references PurchaseOrder (orderNo) ON DELETE CASCADE,
);





--VIEWS:
--View for customer purchase history
CREATE VIEW purchase_history AS
(SELECT C.cust_name, C.cust_phone, C.cust_type,S.Transno,S.posteddate,S.postedby,S.amount,S.paid_amount 
FROM customer as C
INNER JOIN sales as S ON C.cust_id =S.cust_id);

select * from purchase_history;



--TRIGGERS:
-- Create the trigger for product price updating
CREATE TRIGGER UpdateProductPrice
ON PCls
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE product
    SET prod_price = 
        CASE
            WHEN PCls.last_rate IS NOT NULL AND PCls.date_effect >= GETDATE() THEN PCls.last_rate
            WHEN PCls.onhand_rate IS NOT NULL THEN PCls.onhand_rate
            ELSE product.prod_price
        END
    FROM product
    JOIN inserted AS PCls ON product.prod_id = PCls.prod_id;
END;

-- Create the trigger for difference  calculation in PCls
CREATE TRIGGER CalDiff
ON PCls
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @onhand_rate DOUBLE PRECISION;
    DECLARE @last_rate DOUBLE PRECISION;
    DECLARE @diff DOUBLE PRECISION;

    -- Get the values from the inserted row
    SELECT @onhand_rate = I.onhand_rate,
           @last_rate = I.last_rate
    FROM INSERTED as I;

    SET @diff = COALESCE(@onhand_rate, 0) - COALESCE(@last_rate, 0);

    UPDATE PCls
    SET onhand_rate = @onhand_rate,
        last_rate = @last_rate
    FROM INSERTED
    WHERE PCls.pcl_no = INSERTED.pcl_no;
END;

-- Trigger to update quantity after sales
CREATE TRIGGER sales_child_AFTER_INSERT
ON sales_child 
AFTER INSERT 
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @product_quantity INT;
    DECLARE @aisle_quantity INT;

    -- Get the quantity of the product from the product table
    SELECT TOP 1 @product_quantity = prod_quantity 
    FROM product 
    WHERE prod_id = (SELECT TOP 1 prod_id FROM INSERTED);

    -- Get the quantity of the product on aisle from the inventory table
    SELECT TOP 1 @aisle_quantity = Quantaisle
    FROM inventory
    WHERE prod_id = (SELECT TOP 1 prod_id FROM inserted);

    -- Check if aisle_quantity is zero
    IF (@aisle_quantity = 0)
    BEGIN
        THROW 50000, 'Product with id not available in inventory', 1;
        RETURN
    END;

    -- Update the product table with the new quantity
    UPDATE product
    SET prod_quantity = @product_quantity - (SELECT TOP 1 quantity FROM inserted)
    WHERE prod_id = (SELECT TOP 1 prod_id FROM inserted);

    -- Update the inventory table with the new aisle quantity
    UPDATE inventory
    SET Quantaisle = @aisle_quantity - (SELECT TOP 1 quantity FROM inserted)
    WHERE prod_id = (SELECT TOP 1 prod_id FROM inserted);

END;


-- Trigger to update quantity after refund
CREATE TRIGGER refund_AFTER_INSERT 
ON refund
AFTER INSERT  
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @refund_quantity_var INT;
    DECLARE @refund_rate_var DECIMAL(10, 2);
    DECLARE @exchange_value DECIMAL(10, 2);
    
    -- Assuming you want to handle only one record at a time
    SELECT TOP 1 @refund_quantity_var = I.quantity,
                 @refund_rate_var = I.rate
    FROM INSERTED as I;

    SET @exchange_value = @refund_quantity_var * @refund_rate_var;

    -- Update the exchange column in the sales table
    UPDATE sales
    SET exchange = exchange + @exchange_value
    WHERE Transno = (SELECT TOP 1 Transno FROM INSERTED);
END;

-- Trigger to update product quantity and inventory on new ProdOrder insertion
CREATE TRIGGER UpdateProductAndInventory
ON ProdOrder
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @prod_id INT;
    DECLARE @orderNo INT;
    DECLARE @quantity INT;

    -- Get the values from the inserted row
    SELECT @prod_id = I.prod_id,
           @orderNo = I.orderNo,
           @quantity = P.quantity
    FROM INSERTED as I
    JOIN PurchaseOrder as P ON I.orderNo = P.orderNo;

    -- Update product quantity
    UPDATE product
    SET prod_quantity = prod_quantity + @quantity
    WHERE prod_id = @prod_id;

    -- Update inventory Quantstore
    UPDATE inventory
    SET Quantstore = Quantstore + @quantity
    WHERE prod_id = @prod_id;
END;

-- Trigger to add new item to inventory on product insertion
CREATE TRIGGER AddToInventory
ON product
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @new_prod_id INT;
    DECLARE @new_prod_quantity INT;

    -- Get the values from the inserted row
    SELECT @new_prod_id = prod_id,
           @new_prod_quantity = prod_quantity
    FROM INSERTED;

    -- Check if the product already exists in the inventory
    IF NOT EXISTS (SELECT 1 FROM inventory WHERE prod_id = @new_prod_id)
    BEGIN
        -- If not exists, insert a new record in the inventory table
        INSERT INTO inventory (prod_id, Quantaisle, Quantstore)
        VALUES (@new_prod_id, 0, @new_prod_quantity);
    END
END;



--PROCEDURES:
--Procedure for calculating discount
CREATE PROCEDURE GetDiscount (@p_cust_id INT, @p_discount FLOAT OUTPUT)
AS
BEGIN
    DECLARE @v_cust_type VARCHAR(45);

    SELECT @v_cust_type = cust_type
    FROM customer
    WHERE cust_id = @p_cust_id;
    
      IF @v_cust_type = 'Employee'
        SET @p_discount = 0.25;
    ELSE IF @v_cust_type = 'Member'
        SET @p_discount = 0.1;
    ELSE
        SET @p_discount = 0;
END;


--ADD VALUES TO TABLES
-- Add values to the customer table
INSERT INTO customer (cust_id, cust_name, cust_phone, cust_type) VALUES
(1, 'John Doe', '1234567890', 'Regular'),
(2, 'Jane Smith', '9876543210', 'Employee'),
(3, 'Bob Johnson', '5555555555', 'Member'),
(4, 'Alice Brown', '7777777777', 'Regular'),
(5, 'Charlie Davis', '9999999999', 'Member');

-- Add values to the product table
INSERT INTO product (prod_id, prod_name, prod_price, prod_quantity, prod_group) VALUES
(1, 'Bread', 2.5, 100, 'Food'),
(2, 'Shirt', 25.0, 50, 'Textile'),
(3, 'Mobile Phone', 300.0, 20, 'Non-Food'),
(4, 'Milk', 1.0, 200, 'Food'),
(5, 'Chair', 30.0, 10, 'Non-Food');

-- Add values to the supplier table
INSERT INTO supplier (s_id, factory_name, focal_person, s_date, address, bank, branch, account_no, contact, s_type, s_status) VALUES
(1, 'ABC Electronics', 'John Supplier', '2024-01-01', '123 Main St', 'XYZ Bank', 'Downtown Branch', 123456789, 9876543210, 'Manufacturer', 'Pending'),
(2, 'XYZ Garments', 'Jane Supplier', '2024-01-10', '456 Oak St', 'ABC Bank', 'Uptown Branch', 987654321, 5555555555, 'Wholesaler', 'Approved'),
(3, 'Food World', 'Bob Supplier', '2024-02-01', '789 Elm St', 'PQR Bank', 'Midtown Branch', 456789012, 7777777777, 'Manufacturer', 'Denied'),
(4, 'Furniture Hub', 'Alice Supplier', '2024-02-15', '101 Pine St', 'LMN Bank', 'West Branch', 789012345, 9999999999, 'Wholesaler', 'Approved'),
(5, 'Tech Innovators', 'Charlie Supplier', '2023-02-15', '202 Cedar St', 'OPQ Bank', 'East Branch', 234567890, 1111111111, 'Manufacturer', 'Pending');

-- Add values to the PCls table
INSERT INTO PCls (pcl_no, p_date, created_by, date_effect, prod_id, p_status, onhand_rate, last_rate) VALUES
(1, '2024-01-05', 'Aaila', '2024-01-01', 1, 'approved', 2.0, 1.8),
(2, '2024-01-15', 'Izzah', '2024-01-10', 2, 'approved', 25.5, 24.0),
(3, '2024-02-05', 'Maryam', '2024-02-01', 3, 'crititcal', 280.0, 290.0),
(4, '2024-02-20', 'Izzah', '2024-02-15', 4, 'approved', 0.8, 1.0),
(5, '2023-02-20', 'Maryam', '2023-02-15', 5, 'pending', 35.0, 32.0);

-- Add values to the inventory table
INSERT INTO inventory (prod_id, Quantaisle, Quantstore) VALUES
(1, 20, 80),
(2, 10, 40),
(3, 5, 15),
(4, 50, 150),
(5, 2, 8);


-- Add values to the sales table
INSERT INTO sales (Transno, amount, cust_id, emp_id, exchange, discount, transtype, posteddate, postedby, paid_amount) VALUES
(1, 50.0, 1, 3, 0.0, 0.0, 'Cash', '2024-01-10', 'Aaila', 50.0),
(2, 300.0, 2, 4, 0.0, 0.0, 'Card', '2024-01-20', 'Izzah', 300.0),
(3, 5.0, 3, 1, 0.0, 0.0, 'EasyPaisa', '2024-02-05', 'Maryam', 5.0),
(4, 2.0, 4, 2, 0.0, 0.0, 'Cash', '2024-02-25', 'Zainab', 2.0),
(5, 100.0, 5, 3, 0.0, 0.0, 'Card', '2023-03-01', 'Aaila', 100.0);

-- Add values to the sales_child table
INSERT INTO sales_child (Transno, prod_id, quantity, rate, entry_date, prod_amount) VALUES
(1, 1, 5, 2.0, '2024-01-10', 10.0),
(2, 2, 2, 25.0, '2024-01-20', 50.0),
(3, 3, 1, 5.0, '2024-02-05', 5.0),
(4, 4, 1, 2.0, '2024-02-25', 2.0),
(5, 5, 3, 35.0, '2023-03-01', 105.0);

-- Add values to the refund table
INSERT INTO refund (refund_no, prod_id, quantity, rate, date, refundedby, Transno) VALUES
(1, 1, 1, 2.0, '2024-01-15', 1, 1),
(2, 2, 1, 25.0, '2024-01-25', 2, 2),
(3, 3, 1, 5.0, '2024-02-10', 3, 3),
(4, 4, 1, 2.0, '2024-02-28', 4, 4),
(5, 5, 2, 35.0, '2023-03-05', 5, 5);

-- Add values to the PurchaseOrder table
INSERT INTO PurchaseOrder (orderNo, orderDate, s_id, emp_id, quantity, costValue, saleValue, orderStatus, appDate, appBy) VALUES
(1, '2024-01-05', 1, 5, 50, '100.0', '150.0', 'Pending', '2024-01-10', 'Sana'),
(2, '2024-01-20', 2, 5, 20, '500.0', '600.0', 'Approved', '2024-01-25', 'Sana'),
(3, '2024-02-10', 3, 5, 5, '250.0', '300.0', 'Denied', '2024-02-15', 'Sana'),
(4, '2024-02-28', 4, 5, 10, '20.0', '25.0', 'Approved', '2024-03-05', 'Sana'),
(5, '2023-03-05', 5, 5, 30, '1000.0', '1200.0', 'Pending', '2023-03-10', 'Sana');

-- Add values to the ProdOrder table
INSERT INTO ProdOrder (orderNo, prod_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);



--Add values into users table
insert into users values
('maryam',1234,1),
('zainab',5678,2),
('aaila',9101,3),
('izzah',1213,4);

SELECT * FROM users

-- Add values to the Employee table
INSERT INTO Employee (emp_id, name, dob, eType, doj) VALUES
(1, 'Maryam', '1990-01-01', 'Cashier', '2024-01-01'),
(2, 'Zainab', '1995-02-15', 'Cashier', '2024-01-10'),
(3, 'Aaila', '1998-05-20', 'Cashier', '2024-02-01'),
(4, 'Izzah', '1992-09-30', 'Cashier', '2024-02-15'),
(5, 'Sana', '1990-10-20', 'Manager', '2023-02-15');

