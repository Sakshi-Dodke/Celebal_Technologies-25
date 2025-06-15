--  Create the Sales table
CREATE TABLE Sales (
    ProductCategory VARCHAR(50),
    ProductName VARCHAR(50),
    SaleAmount DECIMAL(10,2)
);

-- Inserted the given data
INSERT INTO Sales (ProductCategory, ProductName, SaleAmount) VALUES
('Electronics', 'Laptop', 1000),
('Electronics', 'Phone', 800),
('Electronics', 'Tablet', 500),
('Clothing', 'Shirt', 300),
('Clothing', 'Pants', 400),
('Furniture', 'Sofa', 1200),
('Furniture', 'Bed', 900);

Select * from Sales;

--  Generated Sales Report using ROLLUP
SELECT
    ISNULL(ProductCategory, 'Total') AS ProductCategory,
    CASE 
        WHEN ProductCategory IS NOT NULL AND ProductName IS NULL THEN 'Total'
        WHEN ProductCategory IS NULL AND ProductName IS NULL THEN 'Total'
        ELSE ProductName
    END AS ProductName,
    SUM(SaleAmount) AS TotalSales
FROM Sales
GROUP BY ROLLUP(ProductCategory, ProductName)
ORDER BY 
    GROUPING(ProductCategory),
    ProductCategory,
    GROUPING(ProductName),
    ProductName;