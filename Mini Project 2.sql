SELECT COUNT(*) AS Total_Rows
FROM dbo.Central_Superstore

CREATE TABLE DimCustomer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    Customer_ID VARCHAR(50) NOT NULL,
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50)
);

INSERT INTO DimCustomer (Customer_ID, Customer_Name, Segment)
SELECT DISTINCT Customer_ID,Customer_Name,Segment
FROM dbo.Central_Superstore

SELECT *
FROM DimCustomer

CREATE TABLE DimCategory (CategoryKey INT IDENTITY(1,1) PRIMARY KEY,Category VARCHAR(50),
    Sub_Category VARCHAR(50));

INSERT INTO DimCategory (Category, Sub_Category)
SELECT DISTINCT Category,Sub_Category
FROM dbo.Central_Superstore

SELECT *
FROM DimCategory;

CREATE TABLE DimProduct (ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    Product_ID VARCHAR(50) NOT NULL,
    Product_Name VARCHAR(255),
    CategoryKey INT
)

INSERT INTO DimProduct (Product_ID, Product_Name, CategoryKey)
SELECT DISTINCT s.Product_ID,
    s.Product_Name,c.CategoryKey
FROM dbo.Central_Superstore s

    JOIN DimCategory c
    ON s.Category = c.Category
    AND s.Sub_Category = c.Sub_Category


    SELECT COUNT(*) AS Total_Products
FROM DimProduct

CREATE TABLE DimLocation (LocationKey INT IDENTITY(1,1) PRIMARY KEY,
    Country VARCHAR(100),City VARCHAR(100),
    State VARCHAR(100),Postal_Code VARCHAR(20),
    Region VARCHAR(50))

INSERT INTO DimLocation (Country, City, State, Postal_Code, Region)
SELECT DISTINCT Country,City,State,Postal_Code,Region
FROM dbo.Central_Superstore

SELECT COUNT(*) AS Total_Locations
FROM DimLocation

CREATE TABLE DimShipMode (
    ShipModeKey INT IDENTITY(1,1) PRIMARY KEY,
    Ship_Mode VARCHAR(50)
)

INSERT INTO DimShipMode (Ship_Mode)
SELECT DISTINCT Ship_Mode
FROM dbo.Central_Superstore

SELECT COUNT(*) AS Total_ShipModes
FROM DimShipMode

CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,FullDate DATE,
     Year INT,Quarter INT,Month INT,
   MonthName VARCHAR(20), Day INT
)

INSERT INTO DimDate (DateKey, FullDate, Year, Quarter, Month, MonthName, Day)
SELECT DISTINCT
    CONVERT(INT, CONVERT(VARCHAR(8), Order_Date, 112)),
    CAST(Order_Date AS DATE),
    YEAR(Order_Date),
    DATEPART(QUARTER, Order_Date),
    MONTH(Order_Date),
    DATENAME(MONTH, Order_Date),
    DAY(Order_Date)
FROM dbo.Central_Superstore
WHERE Order_Date IS NOT NULL

SELECT COUNT(*) AS Total_Dates
FROM DimDate

CREATE TABLE FactSales (
    SalesKey INT IDENTITY(1,1) PRIMARY KEY,
    Order_ID VARCHAR(50),
    OrderDateKey INT,ShipDateKey INT,CustomerKey INT,
    ProductKey INT,ShipModeKey INT,LocationKey INT,
    CategoryKey INT,Sales DECIMAL(18,2),Quantity INT,
    Discount DECIMAL(5,2),Profit DECIMAL(18,2)
)

INSERT INTO FactSales (
    Order_ID,OrderDateKey,ShipDateKey,
    CustomerKey,ProductKey,ShipModeKey,LocationKey,
    CategoryKey, Sales, Quantity,Discount, Profit
)
SELECT
    s.Order_ID,
    CONVERT(INT, CONVERT(VARCHAR(8), s.Order_Date, 112)),
    CONVERT(INT, CONVERT(VARCHAR(8), s.Ship_Date, 112)),
    c.CustomerKey,p.ProductKey,sm.ShipModeKey,
    l.LocationKey,cat.CategoryKey, s.Sales,
      s.Quantity,s.Discount, s.Profit

FROM dbo.Central_Superstore s
    JOIN DimCustomer c
    ON s.Customer_ID = c.Customer_ID

    JOIN DimProduct p
    ON s.Product_ID = p.Product_ID
    
    JOIN DimShipMode sm
    ON s.Ship_Mode = sm.Ship_Mode
    
    JOIN DimLocation l
    ON s.Country = l.Country
   
    AND s.City = l.City
    AND s.State = l.State
    AND ISNULL(s.Postal_Code, '') = ISNULL(l.Postal_Code, '')
    AND s.Region = l.Region
JOIN DimCategory cat
    ON s.Category = cat.Category
    AND s.Sub_Category = cat.Sub_Category

    SELECT COUNT(*) AS Total_FactSales
FROM FactSales

ALTER TABLE FactSales
ADD CONSTRAINT FK_FactSales_Customer
FOREIGN KEY (CustomerKey)
REFERENCES DimCustomer(CustomerKey)

ALTER TABLE FactSales
ADD CONSTRAINT FK_FactSales_Product
FOREIGN KEY (ProductKey)
REFERENCES DimProduct(ProductKey)

ALTER TABLE FactSales
ADD CONSTRAINT FK_FactSales_ShipMode
FOREIGN KEY (ShipModeKey)
REFERENCES DimShipMode(ShipModeKey)

ALTER TABLE FactSales
ADD CONSTRAINT FK_FactSales_Location
FOREIGN KEY (LocationKey)
REFERENCES DimLocation(LocationKey)

ALTER TABLE FactSales
ADD CONSTRAINT FK_FactSales_Category
FOREIGN KEY (CategoryKey)
REFERENCES DimCategory(CategoryKey)

ALTER TABLE FactSales
ADD CONSTRAINT FK_FactSales_OrderDate
FOREIGN KEY (OrderDateKey)
REFERENCES DimDate(DateKey)

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
--- اجمالي المبيعات والربج
SELECT
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM FactSales

---دي عشان نحسب المبيعات والربح حسب ال category
SELECT
    c.Category,
    SUM(f.Sales) AS Total_Sales,
    SUM(f.Profit) AS Total_Profit
FROM FactSales f
JOIN DimCategory c
    ON f.CategoryKey = c.CategoryKey
GROUP BY c.Category
ORDER BY Total_Sales DESC

---عدد ال orders
SELECT
    c.Customer_Name,
    COUNT(DISTINCT f.Order_ID) AS Total_Orders
FROM FactSales f
JOIN DimCustomer c
    ON f.CustomerKey = c.CustomerKey
GROUP BY c.Customer_Name
ORDER BY Total_Orders DESC

---المبيعات حسب ال region
SELECT
    l.Region,
    SUM(f.Sales) AS Total_Sales,
    SUM(f.Profit) AS Total_Profit
FROM FactSales f
JOIN DimLocation l
    ON f.LocationKey = l.LocationKey
GROUP BY l.Region
ORDER BY Total_Sales DESC

---المبيعات حسب Ship Mode
SELECT
    s.Ship_Mode,
    SUM(f.Sales) AS Total_Sales,
    SUM(f.Profit) AS Total_Profit
FROM FactSales f
JOIN DimShipMode s
    ON f.ShipModeKey = s.ShipModeKey
GROUP BY s.Ship_Mode

---أعلى 10 منتجات في المبيعات
SELECT TOP 10
    p.Product_Name,
    SUM(f.Sales) AS Total_Sales
FROM FactSales f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey
GROUP BY p.Product_Name
ORDER BY Total_Sales DESC

---أعلى 10 منتجات في الأرباح
SELECT TOP 10
    p.Product_Name,
    SUM(f.Profit) AS Total_Profit
FROM FactSales f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey
GROUP BY p.Product_Name
ORDER BY Total_Profit DESC

---المبيعات حسب السنة
SELECT
    d.Year,
    SUM(f.Sales) AS Total_Sales,
    SUM(f.Profit) AS Total_Profit
FROM FactSales f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey
GROUP BY d.Year
ORDER BY d.Year

---المبيعات حسب الشهر
SELECT
    d.Month,
    d.MonthName,
    SUM(f.Sales) AS Total_Sales
FROM FactSales f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey
GROUP BY d.Month, d.MonthName
ORDER BY d.Month

---المبيعات حسب Segment
SELECT
    c.Segment,
    SUM(f.Sales) AS Total_Sales,
    SUM(f.Profit) AS Total_Profit
FROM FactSales f
JOIN DimCustomer c
    ON f.CustomerKey = c.CustomerKey
GROUP BY c.Segment
ORDER BY Total_Sales DESC

---متوسط الخصم
SELECT
    AVG(Discount) AS Average_Discount
FROM FactSales

---إجمالي الكمية المباعة لكل Category
SELECT
    c.Category,
    SUM(f.Quantity) AS Total_Quantity
FROM FactSales f
JOIN DimCategory c
    ON f.CategoryKey = c.CategoryKey
GROUP BY c.Category
ORDER BY Total_Quantity DESC

---المدن الأعلى في المبيعات
SELECT TOP 10
    l.City,
    SUM(f.Sales) AS Total_Sales
FROM FactSales f
JOIN DimLocation l
    ON f.LocationKey = l.LocationKey
GROUP BY l.City
ORDER BY Total_Sales DESC

---العملاء الأعلى في الأرباح
SELECT TOP 10
    c.Customer_Name,
    SUM(f.Profit) AS Total_Profit
FROM FactSales f
JOIN DimCustomer c
    ON f.CustomerKey = c.CustomerKey
GROUP BY c.Customer_Name
ORDER BY Total_Profit DESC

---المنتجات اللي حققت خسارة
SELECT
    p.Product_Name,
    SUM(f.Profit) AS Total_Profit
FROM FactSales f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey
GROUP BY p.Product_Name
HAVING SUM(f.Profit) < 0
ORDER BY Total_Profit

---إجمالي المبيعات حسب الـ Region
WITH RegionSales AS (
    SELECT
        l.Region,
        SUM(f.Sales) AS Total_Sales
    FROM FactSales f
    JOIN DimLocation l
        ON f.LocationKey = l.LocationKey
    GROUP BY l.Region
)
SELECT *
FROM RegionSales
ORDER BY Total_Sales DESC

---أعلى 10 عملاء في المبيعات
WITH CustomerSales AS (
    SELECT
        c.Customer_Name,
        SUM(f.Sales) AS Total_Sales
    FROM FactSales f
    JOIN DimCustomer c
        ON f.CustomerKey = c.CustomerKey
    GROUP BY c.Customer_Name
)
SELECT TOP 10
    Customer_Name,
    Total_Sales
FROM CustomerSales
ORDER BY Total_Sales DESC
------------------
SELECT
    Order_ID,
    Sales,
    Profit,
    CASE
        WHEN Profit > 0 THEN 'Profitable'
        WHEN Profit < 0 THEN 'Loss'
        ELSE 'No Profit'
    END AS Profit_Status
FROM FactSales;

--------------------------------------
SELECT
    Order_ID,
    Sales,
    CASE
        WHEN Sales >= 500 THEN 'High Sales'
        WHEN Sales >= 100 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS Sales_Category
FROM FactSales;

---------------------------------------
CREATE PROCEDURE GetRegionSales
    @Region VARCHAR(50)
AS
BEGIN
    SELECT
        l.Region,
        SUM(f.Sales) AS Total_Sales,
        SUM(f.Profit) AS Total_Profit
    FROM FactSales f
    JOIN DimLocation l
        ON f.LocationKey = l.LocationKey
    WHERE l.Region = @Region
    GROUP BY l.Region;
END;

EXEC GetRegionSales 'Central'
---------------
CREATE VIEW vw_SalesKPIs
AS
SELECT
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    SUM(Quantity) AS Total_Quantity,
    COUNT(DISTINCT Order_ID) AS Total_Orders
FROM FactSales

SELECT *
FROM vw_SalesKPIs

---------------
CREATE VIEW vw_CategoryKPIs
AS
SELECT
    c.Category,
    SUM(f.Sales) AS Total_Sales,
    SUM(f.Profit) AS Total_Profit,
    SUM(f.Quantity) AS Total_Quantity
FROM FactSales f
JOIN DimCategory c
    ON f.CategoryKey = c.CategoryKey
GROUP BY c.Category

SELECT *
FROM vw_CategoryKPIs

create index IX_FactSales_CustomerKey
on FactSales(CustomerKey)

create index IX_FactSales_ProductKey
on FactSales(ProductKey)

create index IX_FactSales_OrderDateKey
on FactSales(OrderDateKey)

create index IX_FactSales_LocationKey
on FactSales(LocationKey)


