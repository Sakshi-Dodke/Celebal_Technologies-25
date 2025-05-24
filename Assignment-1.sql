USE AdventureWorks2022;
GO

--List of all customers
SELECT *
FROM Sales.Customer;

--List of all customers where company name ends in 'N'
SELECT 
    c.CustomerID,
    s.Name AS CompanyName
FROM Sales.Customer c
INNER JOIN Sales.Store s 
    ON c.StoreID = s.BusinessEntityID
WHERE s.Name LIKE '%N';

-- List of all customers who live in Berlin or London  
SELECT 
    c.CustomerID,
    s.Name AS StoreName,
    a.City,
    a.StateProvinceID,
    a.PostalCode
FROM Sales.Customer c
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
INNER JOIN Person.BusinessEntityAddress bea ON c.CustomerID = bea.BusinessEntityID
INNER JOIN Person.Address a ON bea.AddressID = a.AddressID
WHERE a.City IN ('Berlin', 'London');

-- List of all customers who live in UK or USA 
SELECT 
    c.CustomerID,
    s.Name AS StoreName,
    a.City,
    sp.Name AS StateProvince,
    cr.Name AS CountryRegion
FROM Sales.Customer c
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
INNER JOIN Person.BusinessEntityAddress bea ON c.CustomerID = bea.BusinessEntityID
INNER JOIN Person.Address a ON bea.AddressID = a.AddressID
INNER JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
INNER JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name IN ('United Kingdom', 'United States');

-- List of all products sorted by product name  
SELECT *
FROM Production.Product
ORDER BY Name ASC;

--List of all products where product name starts with an A  
SELECT *
FROM Production.Product
WHERE Name LIKE 'A%';

--List of customers who ever placed an order  
SELECT DISTINCT
    c.CustomerID,
    s.Name AS StoreName
FROM Sales.Customer c
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
INNER JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID;

--List of Customers who live in London and have bought chai  
SELECT DISTINCT
    c.CustomerID,
    p.FirstName,
    p.LastName,
    a.City,
    prd.Name AS ProductName
FROM Sales.Customer c
INNER JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
INNER JOIN Person.BusinessEntityAddress bea ON c.CustomerID = bea.BusinessEntityID
INNER JOIN Person.Address a ON bea.AddressID = a.AddressID
INNER JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
INNER JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product prd ON sod.ProductID = prd.ProductID
WHERE a.City = 'London'
  AND prd.Name = 'Chai';

-- List of customers who never place an order  
SELECT c.CustomerID, p.FirstName, p.LastName
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
WHERE soh.CustomerID IS NULL;

--List of customers who ordered Tofu
SELECT DISTINCT c.CustomerID, p.FirstName, p.LastName
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product pr ON sod.ProductID = pr.ProductID
WHERE pr.Name = 'Tofu';

--Details of first order of the system
SELECT TOP 1 *
FROM Sales.SalesOrderHeader
ORDER BY OrderDate ASC;

--Find the details of the most expensive order date
SELECT TOP 1 OrderDate, soh.SalesOrderID, SUM(sod.LineTotal) AS TotalOrderValue
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY soh.SalesOrderID, OrderDate
ORDER BY TotalOrderValue DESC;

--For each order get the OrderID and Average quantity of items in that order  
SELECT SalesOrderID, AVG(OrderQty) AS AvgQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

--For each order get the orderID, minimum quantity and maximum quantity for that order  
SELECT SalesOrderID, MIN(OrderQty) AS MinQty, MAX(OrderQty) AS MaxQty
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

--Get a list of all managers and total number of employees who report to them. 
SELECT 
    Manager.BusinessEntityID AS ManagerID,
    p.FirstName + ' ' + p.LastName AS ManagerName,
    COUNT(e.BusinessEntityID) AS NumEmployees
FROM HumanResources.Employee e
JOIN HumanResources.Employee Manager ON e.OrganizationNode.GetAncestor(1) = Manager.OrganizationNode
JOIN Person.Person p ON Manager.BusinessEntityID = p.BusinessEntityID
GROUP BY Manager.BusinessEntityID, p.FirstName, p.LastName;

--Get the OrderID and the total quantity for each order that has a total quantity of greater than 300  
SELECT SalesOrderID, SUM(OrderQty) AS TotalQuantity
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
HAVING SUM(OrderQty) > 300;

--List of all orders placed on or after 1996/12/31  
SELECT SalesOrderID, OrderDate, CustomerID, TotalDue
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '1996-12-31';

--List of all orders shipped to Canada  
SELECT soh.SalesOrderID, soh.OrderDate, a.AddressLine1, cr.Name AS Country
FROM Sales.SalesOrderHeader soh
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name = 'Canada';

--List of all orders with order total > 200
SELECT SalesOrderID, OrderDate, CustomerID, TotalDue
FROM Sales.SalesOrderHeader
WHERE TotalDue > 200;

--List of countries and sales made in each country
SELECT cr.Name AS Country, SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader AS soh
JOIN Person.Address AS a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince AS sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion AS cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.Name
ORDER BY TotalSales DESC;

--List of Customer ContactName and number of orders they placed  
SELECT 
    p.FirstName + ' ' + p.LastName AS ContactName,
    COUNT(soh.SalesOrderID) AS NumberOfOrders
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.Customer AS c ON soh.CustomerID = c.CustomerID
JOIN Person.Person AS p ON c.PersonID = p.BusinessEntityID
GROUP BY p.FirstName, p.LastName
ORDER BY NumberOfOrders DESC;

-- List of customer contactnames who have placed more than 3 orders  
SELECT 
    p.FirstName + ' ' + p.LastName AS ContactName,
    COUNT(soh.SalesOrderID) AS NumberOfOrders
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.Customer AS c ON soh.CustomerID = c.CustomerID
JOIN Person.Person AS p ON c.PersonID = p.BusinessEntityID
GROUP BY p.FirstName, p.LastName
HAVING COUNT(soh.SalesOrderID) > 3
ORDER BY NumberOfOrders DESC;

--List of discontinued products which were ordered between 1/1/1997 and 1/1/1998  
SELECT DISTINCT p.ProductID, p.Name AS ProductName, p.SellEndDate, soh.OrderDate
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE p.SellEndDate IS NOT NULL
  AND soh.OrderDate BETWEEN '1997-01-01' AND '1998-01-01';

--List of employee firstname, lastName, superviser FirstName, LastName  
SELECT 
    e1p.FirstName AS EmployeeFirstName,
    e1p.LastName AS EmployeeLastName,
    e2p.FirstName AS SupervisorFirstName,
    e2p.LastName AS SupervisorLastName
FROM HumanResources.Employee AS e1
JOIN Person.Person AS e1p ON e1.BusinessEntityID = e1p.BusinessEntityID
LEFT JOIN HumanResources.Employee AS e2 ON e1.OrganizationNode.GetAncestor(1) = e2.OrganizationNode
LEFT JOIN Person.Person AS e2p ON e2.BusinessEntityID = e2p.BusinessEntityID
ORDER BY SupervisorLastName, EmployeeLastName;

--List of Employees id and total sale conducted by employee 
SELECT 
    sp.BusinessEntityID AS EmployeeID,
    SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesPerson AS sp ON soh.SalesPersonID = sp.BusinessEntityID
GROUP BY sp.BusinessEntityID
ORDER BY TotalSales DESC;

--List of employees whose FirstName contains character a 
SELECT 
    e.BusinessEntityID,
    p.FirstName,
    p.LastName
FROM HumanResources.Employee AS e
JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
WHERE p.FirstName LIKE '%a%'
ORDER BY p.FirstName;

--List of managers who have more than four people reporting to them.  
SELECT Manager.BusinessEntityID, COUNT(e.BusinessEntityID) AS Reports
FROM HumanResources.Employee e
JOIN HumanResources.Employee Manager ON e.OrganizationNode.GetAncestor(1) = Manager.OrganizationNode
GROUP BY Manager.BusinessEntityID
HAVING COUNT(e.BusinessEntityID) > 4;

-- List of Orders and ProductNames  
SELECT sod.SalesOrderID, p.Name AS ProductName
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID;

--List of orders place by the best customer  
SELECT TOP 1 soh.CustomerID, COUNT(*) AS OrdersCount
FROM Sales.SalesOrderHeader soh
GROUP BY soh.CustomerID
ORDER BY COUNT(*) DESC;

-- List of orders placed by customers who do not have a Fax number  
SELECT soh.SalesOrderID, soh.OrderDate, c.CustomerID, p.FirstName, p.LastName
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Person.PersonPhone pp ON p.BusinessEntityID = pp.BusinessEntityID AND pp.PhoneNumberTypeID = (
    SELECT PhoneNumberTypeID 
    FROM Person.PhoneNumberType 
    WHERE Name = 'Fax'
)
WHERE pp.PhoneNumber IS NULL;

--List of Postal codes where the product Tofu was shipped 
SELECT DISTINCT a.PostalCode
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
WHERE p.Name = 'Tofu';

--List of product Names that were shipped to France  
SELECT DISTINCT p.Name AS ProductName
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE cr.Name = 'France';

--List of ProductNames and Categories for the supplier 'Specialty Biscuits, Ltd.  
SELECT 
    p.Name AS ProductName,
    pc.Name AS CategoryName
FROM 
    Production.Product p
JOIN 
    Purchasing.ProductVendor pv ON p.ProductID = pv.ProductID
JOIN 
    Purchasing.Vendor v ON pv.BusinessEntityID = v.BusinessEntityID
LEFT JOIN 
    Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN 
    Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE 
    v.Name = 'Specialty Biscuits, Ltd.';

--List of products that were never ordered  
SELECT p.ProductID, p.Name AS ProductName
FROM Production.Product p
LEFT JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
WHERE sod.ProductID IS NULL;

-- List of products where units in stock is less than 10 and units on order are 0.  
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    pi.Quantity AS UnitsInStock,
    p.SafetyStockLevel,
    p.ReorderPoint
FROM 
    Production.Product p
JOIN 
    Production.ProductInventory pi ON p.ProductID = pi.ProductID
WHERE 
    pi.Quantity < 10
    AND p.ReorderPoint = 0;

--List of top 10 countries by sales  
SELECT TOP 10 
    cr.Name AS Country,
    SUM(soh.TotalDue) AS TotalSales
FROM 
    Sales.SalesOrderHeader soh
JOIN 
    Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN 
    Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN 
    Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY 
    cr.Name
ORDER BY 
    TotalSales DESC;

--Number of orders each employee has taken for customers with CustomerIDs between A and AO  
SELECT 
    e.BusinessEntityID AS EmployeeID,
    COUNT(soh.SalesOrderID) AS OrderCount
FROM 
    Sales.SalesOrderHeader soh
JOIN 
    Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN 
    Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
JOIN 
    HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
WHERE 
    c.AccountNumber BETWEEN 'A' AND 'AO'
GROUP BY 
    e.BusinessEntityID;

-- Orderdate of most expensive order  
SELECT 
    TOP 1 OrderDate, TotalDue
FROM 
    Sales.SalesOrderHeader
ORDER BY 
    TotalDue DESC;

--Product name and total revenue from that product 
SELECT 
    p.Name AS ProductName,
    SUM(sod.LineTotal) AS TotalRevenue
FROM 
    Sales.SalesOrderDetail sod
JOIN 
    Production.Product p ON sod.ProductID = p.ProductID
GROUP BY 
    p.Name
ORDER BY 
    TotalRevenue DESC;

 --Supplierid and number of products offered  
SELECT 
    pv.BusinessEntityID AS SupplierID,
    COUNT(p.ProductID) AS ProductCount
FROM 
    Purchasing.ProductVendor pv
JOIN 
    Production.Product p ON pv.ProductID = p.ProductID
GROUP BY 
    pv.BusinessEntityID;

--Top ten customers based on their business  
SELECT 
    c.CustomerID,
    SUM(soh.TotalDue) AS TotalSpent
FROM 
    Sales.SalesOrderHeader soh
JOIN 
    Sales.Customer c ON soh.CustomerID = c.CustomerID
GROUP BY 
    c.CustomerID
ORDER BY 
    TotalSpent DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- What is the total revenue of the company
SELECT 
    SUM(TotalDue) AS TotalRevenue
FROM 
    Sales.SalesOrderHeader;









