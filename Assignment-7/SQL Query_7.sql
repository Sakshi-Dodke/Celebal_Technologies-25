-- Let assume Examples:
-- Source Table: source_customer
-- Target Table: dim_customer
-- Common columns: customer_id, customer_name, email, address, updated_at
-- SCD Type 2 and above will use additional metadata columns: effective_date, expiry_date, is_current 

-- 1. SCD Type 0 (Fixed Dimension) : No changes are made to existing records.
CREATE PROCEDURE scd_type_0
AS
BEGIN
    INSERT INTO dim_customer (customer_id, customer_name, email, address)
    SELECT s.customer_id, s.customer_name, s.email, s.address
    FROM source_customer s
    LEFT JOIN dim_customer d ON s.customer_id = d.customer_id
    WHERE d.customer_id IS NULL;
END;
GO

-- 2. SCD Type 1 (Overwrite)
CREATE PROCEDURE scd_type_1
AS
BEGIN
    -- Insert new records
    INSERT INTO dim_customer (customer_id, customer_name, email, address)
    SELECT s.customer_id, s.customer_name, s.email, s.address
    FROM source_customer s
    LEFT JOIN dim_customer d ON s.customer_id = d.customer_id
    WHERE d.customer_id IS NULL;

    -- Overwrite existing records
    UPDATE d
    SET d.customer_name = s.customer_name,
        d.email = s.email,
        d.address = s.address
    FROM dim_customer d
    INNER JOIN source_customer s ON d.customer_id = s.customer_id;
END;
GO

-- 3. SCD Type 2 (History Tracking) 
CREATE PROCEDURE scd_type_2
AS
BEGIN
    DECLARE @current_date DATE = GETDATE();

    -- Expire old records
    UPDATE d
    SET d.expiry_date = @current_date,
        d.is_current = 0
    FROM dim_customer d
    INNER JOIN source_customer s ON d.customer_id = s.customer_id
    WHERE d.is_current = 1 AND (
        d.customer_name != s.customer_name OR
        d.email != s.email OR
        d.address != s.address
    );

    -- Insert new records
    INSERT INTO dim_customer (customer_id, customer_name, email, address, effective_date, expiry_date, is_current)
    SELECT s.customer_id, s.customer_name, s.email, s.address, @current_date, NULL, 1
    FROM source_customer s
    LEFT JOIN dim_customer d ON s.customer_id = d.customer_id AND d.is_current = 1
    WHERE d.customer_id IS NULL OR (
        d.customer_name != s.customer_name OR
        d.email != s.email OR
        d.address != s.address
    );
END;
GO

-- 4. SCD Type 3 (Partial History in Same Row) 
CREATE PROCEDURE scd_type_3
AS
BEGIN
    -- Insert new records
    INSERT INTO dim_customer (customer_id, customer_name, email, address, prev_address)
    SELECT s.customer_id, s.customer_name, s.email, s.address, NULL
    FROM source_customer s
    LEFT JOIN dim_customer d ON s.customer_id = d.customer_id
    WHERE d.customer_id IS NULL;

    -- Update changed records and keep previous address
    UPDATE d
    SET d.prev_address = d.address,
        d.address = s.address,
        d.customer_name = s.customer_name,
        d.email = s.email
    FROM dim_customer d
    INNER JOIN source_customer s ON d.customer_id = s.customer_id
    WHERE d.address != s.address;
END;
GO

--5. SCD Type 4 (Separate History Table)
CREATE PROCEDURE scd_type_4
AS
BEGIN
    DECLARE @current_date DATE = GETDATE();

    -- Archive current record to history
    INSERT INTO dim_customer_history (customer_id, customer_name, email, address, archived_at)
    SELECT d.customer_id, d.customer_name, d.email, d.address, @current_date
    FROM dim_customer d
    INNER JOIN source_customer s ON d.customer_id = s.customer_id
    WHERE d.customer_name != s.customer_name OR
          d.email != s.email OR
          d.address != s.address;

    -- Update current record
    UPDATE d
    SET d.customer_name = s.customer_name,
        d.email = s.email,
        d.address = s.address
    FROM dim_customer d
    INNER JOIN source_customer s ON d.customer_id = s.customer_id;

    -- Insert new records
    INSERT INTO dim_customer (customer_id, customer_name, email, address)
    SELECT s.customer_id, s.customer_name, s.email, s.address
    FROM source_customer s
    LEFT JOIN dim_customer d ON s.customer_id = d.customer_id
    WHERE d.customer_id IS NULL;
END;
GO

--6. SCD Type 5 – Type 1 with Surrogate Key
CREATE PROCEDURE scd_type_5
AS
BEGIN
    -- Assuming surrogate key: customer_sk
    DECLARE @current_date DATE = GETDATE();

    -- Archive old version with surrogate key
    INSERT INTO dim_customer_history (customer_sk, customer_id, customer_name, email, address, archived_at)
    SELECT d.customer_sk, d.customer_id, d.customer_name, d.email, d.address, @current_date
    FROM dim_customer d
    INNER JOIN source_customer s ON d.customer_id = s.customer_id
    WHERE d.customer_name != s.customer_name OR
          d.email != s.email OR
          d.address != s.address;

    -- Overwrite current dimension table
    UPDATE d
    SET d.customer_name = s.customer_name,
        d.email = s.email,
        d.address = s.address
    FROM dim_customer d
    INNER JOIN source_customer s ON d.customer_id = s.customer_id;

    -- Insert new records
    INSERT INTO dim_customer (customer_id, customer_name, email, address)
    SELECT s.customer_id, s.customer_name, s.email, s.address
    FROM source_customer s
    LEFT JOIN dim_customer d ON s.customer_id = d.customer_id
    WHERE d.customer_id IS NULL;
END;
GO

--SCD Type 6 – Hybrid of Type 1 + 2 + 3

CREATE PROCEDURE scd_type_6
AS
BEGIN
    DECLARE @current_date DATE = GETDATE();

    -- Expire existing record (Type 2 behavior)
    UPDATE d
    SET d.expiry_date = @current_date,
        d.is_current = 0
    FROM dim_customer d
    INNER JOIN source_customer s ON d.customer_id = s.customer_id
    WHERE d.is_current = 1 AND (
        d.customer_name != s.customer_name OR
        d.email != s.email OR
        d.address != s.address
    );

    -- Insert new record with prev_address (Type 3) + new row (Type 2)
    INSERT INTO dim_customer (
        customer_id, customer_name, email, address, prev_address,
        effective_date, expiry_date, is_current
    )
    SELECT 
        s.customer_id,
        s.customer_name,
        s.email,
        s.address,
        d.address,
        @current_date,
        NULL,
        1
    FROM source_customer s
    INNER JOIN dim_customer d ON s.customer_id = d.customer_id
    WHERE d.is_current = 0 AND (
        d.customer_name != s.customer_name OR
        d.email != s.email OR
        d.address != s.address
    );

    -- Insert brand new records
    INSERT INTO dim_customer (
        customer_id, customer_name, email, address, prev_address,
        effective_date, expiry_date, is_current
    )
    SELECT 
        s.customer_id, s.customer_name, s.email, s.address, NULL, @current_date, NULL, 1
    FROM source_customer s
    LEFT JOIN dim_customer d ON s.customer_id = d.customer_id
    WHERE d.customer_id IS NULL;
END;
GO
