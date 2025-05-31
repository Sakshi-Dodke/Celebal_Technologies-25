--Create InsertOrderDetails procedure

CREATE PROCEDURE InsertOrderDetails 
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity INT,
    @Discount DECIMAL(5, 2) = 0
AS
BEGIN
    BEGIN TRY
   
        IF @UnitPrice IS NULL
        BEGIN
            SELECT @UnitPrice = ListPrice
            FROM Production.Product
            WHERE ProductID = @ProductID;
        END

        DECLARE @CurrentStock INT, @ReorderLevel INT, @NewStock INT;

        SELECT 
            @CurrentStock = pi.Quantity,
            @ReorderLevel = p.ReorderPoint
        FROM Production.ProductInventory pi
        INNER JOIN Production.Product p ON pi.ProductID = p.ProductID
        WHERE pi.ProductID = @ProductID;

        IF @CurrentStock IS NULL OR @CurrentStock < @Quantity
        BEGIN
            RAISERROR('Not enough stock to fulfill the order.', 16, 1);
            RETURN;
        END

        BEGIN TRANSACTION;
       
        INSERT INTO Sales.SalesOrderDetail (SalesOrderID, ProductID, UnitPrice, OrderQty, UnitPriceDiscount)
        VALUES (@OrderID, @ProductID, @UnitPrice, @Quantity, @Discount);

        -- Check if insert was successful
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('Failed to place the order. Please try again.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Production.ProductInventory
        SET Quantity = Quantity - @Quantity
        WHERE ProductID = @ProductID;

        SET @NewStock = @CurrentStock - @Quantity;

        IF @NewStock < @ReorderLevel
        BEGIN
            PRINT 'Warning: Stock of product dropped below its Reorder Level.';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        RAISERROR('Failed to place the order. Please try again.', 16, 1);
    END CATCH
END;
GO


-- Create UpdateOrderDetails procedure

CREATE PROCEDURE UpdateOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity INT = NULL,
    @Discount DECIMAL(5, 2) = NULL
AS
BEGIN
    BEGIN TRY
        DECLARE @OriginalUnitPrice MONEY;
        DECLARE @OriginalQuantity INT;
        DECLARE @OriginalDiscount DECIMAL(5, 2);

        -- Fetch original values
        SELECT 
            @OriginalUnitPrice = UnitPrice,
            @OriginalQuantity = OrderQty,
            @OriginalDiscount = UnitPriceDiscount
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

        -- Check if the record exists
        IF @OriginalUnitPrice IS NULL
        BEGIN
            RAISERROR('Order detail not found for the given OrderID and ProductID.', 16, 1);
            RETURN;
        END

        -- Replace NULL input values with original values
        SET @UnitPrice = ISNULL(@UnitPrice, @OriginalUnitPrice);
        SET @Quantity = ISNULL(@Quantity, @OriginalQuantity);
        SET @Discount = ISNULL(@Discount, @OriginalDiscount);

        BEGIN TRANSACTION;

        -- Update order details
        UPDATE Sales.SalesOrderDetail
        SET 
            UnitPrice = @UnitPrice,
            OrderQty = @Quantity,
            UnitPriceDiscount = @Discount
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

        -- Adjust inventory
        DECLARE @QuantityDifference INT = @Quantity - @OriginalQuantity;

        UPDATE Production.ProductInventory
        SET Quantity = Quantity - @QuantityDifference
        WHERE ProductID = @ProductID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        RAISERROR('Failed to update order details. Please try again.', 16, 1);
    END CATCH
END;
GO

-- Create GetOrderDetails procedure

CREATE PROCEDURE GetOrderDetails
    @OrderID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Sales.SalesOrderDetail WHERE SalesOrderID = @OrderID)
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR) + ' does not exist';
        RETURN 1;
    END

    SELECT * 
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID;
END;
GO


-- Create DeleteOrderDetails procedure
CREATE PROCEDURE DeleteOrderDetails
    @OrderID INT,
    @ProductID INT
AS
BEGIN
    -- Validate parameters
    IF NOT EXISTS (
        SELECT 1 
        FROM Sales.SalesOrderDetail 
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID
    )
    BEGIN
        PRINT 'Invalid parameters: Either OrderID or ProductID does not exist in this order.';
        RETURN -1;
    END

    -- Proceed to delete
    DELETE FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    RETURN 0;
END;
GO


-- Create FormatDateMMDDYYYY function
CREATE FUNCTION FormatDateMMDDYYYY (@date DATETIME)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CONVERT(VARCHAR(10), @date, 101);
END;
GO

-- Create FormatDateYYYYMMDD function
CREATE FUNCTION FormatDateYYYYMMDD (@date DATETIME)
RETURNS VARCHAR(8)
AS
BEGIN
    RETURN CONVERT(VARCHAR(8), @date, 112);
END;
GO

-- Create vwCustomerOrders view
CREATE VIEW vwCustomerOrders
AS
SELECT 
    COALESCE(S.Name, P.LastName + ' ' + P.FirstName) AS CompanyName,
    SOH.SalesOrderID AS OrderID,
    SOH.OrderDate,
    SOD.ProductID,
    PR.Name AS ProductName,
    SOD.OrderQty AS Quantity,
    SOD.UnitPrice,
    SOD.OrderQty * SOD.UnitPrice AS TotalPrice
FROM 
    Sales.SalesOrderHeader AS SOH
JOIN 
    Sales.Customer AS C ON SOH.CustomerID = C.CustomerID
LEFT JOIN 
    Sales.Store AS S ON C.StoreID = S.BusinessEntityID
LEFT JOIN 
    Person.Person AS P ON C.PersonID = P.BusinessEntityID
JOIN 
    Sales.SalesOrderDetail AS SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN 
    Production.Product AS PR ON SOD.ProductID = PR.ProductID;
GO


-- Create a vwCustomerOrdersYesterday view
CREATE VIEW vwCustomerOrdersYesterday
AS
SELECT * 
FROM vwCustomerOrders
WHERE OrderDate = CONVERT(DATE, GETDATE() - 1);
GO

-- Create MyProducts view
CREATE VIEW MyProducts AS
SELECT 
    P.ProductID,
    P.Name AS ProductName,
    COALESCE(P.Size, 'N/A') AS QuantityPerUnit,  -- Approximation
    P.ListPrice AS UnitPrice,
    V.Name AS CompanyName,
    PC.Name AS CategoryName
FROM 
    Production.Product P
JOIN 
    Purchasing.ProductVendor PV ON P.ProductID = PV.ProductID
JOIN 
    Purchasing.Vendor V ON PV.BusinessEntityID = V.BusinessEntityID
JOIN 
    Production.ProductSubcategory PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
JOIN 
    Production.ProductCategory PC ON PSC.ProductCategoryID = PC.ProductCategoryID
WHERE 
    P.DiscontinuedDate IS NULL;
GO

---
CREATE TRIGGER trg_DeleteOrder
ON Orders
INSTEAD OF DELETE
AS
BEGIN
    -- Delete related records from Order Details table
    DELETE FROM [Order Details]
    WHERE OrderID IN (SELECT OrderID FROM DELETED);

    -- Delete the order from Orders table
    DELETE FROM Orders
    WHERE OrderID IN (SELECT OrderID FROM DELETED);
END;

----
DELIMITER $$

CREATE TRIGGER check_stock_before_insert
BEFORE INSERT ON OrderDetails
FOR EACH ROW
BEGIN
    DECLARE current_stock INT;

    -- Get the current stock for the product
    SELECT UnitsInStock INTO current_stock
    FROM Products
    WHERE ProductID = NEW.ProductID;

    -- Check if there's enough stock
    IF current_stock < NEW.Quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order cannot be placed due to insufficient stock.';
    ELSE
        -- Sufficient stock: update the Products table
        UPDATE Products
        SET UnitsInStock = UnitsInStock - NEW.Quantity
        WHERE ProductID = NEW.ProductID;
    END IF;
END$$

DELIMITER ;


-----------------------Sample Table Structure--------------------------
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    UnitsInStock INT
);

CREATE TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY,
    ProductID INT,
    Quantity INT,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE TABLE Sales.SalesOrderDetail (
    SalesOrderDetailID INT PRIMARY KEY,
    SalesOrderID INT,
    ProductID INT,
    Quantity INT,
    FOREIGN KEY (SalesOrderID) REFERENCES Sales.SalesOrderHeader(SalesOrderID)
);

CREATE TABLE Sales.SalesOrderHeader (
    SalesOrderID INT PRIMARY KEY,
    OrderDate DATE
);

-- Insert Products
INSERT INTO Products VALUES (1, 'Laptop', 50);
INSERT INTO Products VALUES (2, 'Mouse', 100);

-- Insert OrderDetails
INSERT INTO OrderDetails VALUES (101, 1, 5); 

SELECT * FROM Products;

SELECT * FROM OrderDetails;






