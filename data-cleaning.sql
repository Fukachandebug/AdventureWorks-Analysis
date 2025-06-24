-- Count the Number of New Customers
-- Create a CTE to identify each customer's first purchase date
with FirstPurchase as (
    select
        soh.CustomerID,
        min(soh.OrderDate) as first_purchase_date
    from Sales.SalesOrderHeader soh
    join Sales.Customer c on soh.CustomerID = c.CustomerID
    group by soh.CustomerID, c.StoreID
)

-- Main query to extract detailed sales, customer, and product information
select 
    -- Product details
    p.ProductID,
    p.Name as Product_Name,
    p.Color,
    p.StandardCost,
    p.ListPrice,
    p.Size,

    -- Sales order details
    sod.SalesOrderID,
    sod.OrderQty,
    sod.UnitPrice,
    sod.UnitPriceDiscount,

    -- Financial metrics
    sum(sod.LineTotal) as Total_Amount,
    sum(sod.LineTotal) - sum(sod.OrderQty * p.StandardCost) as Profit,

    -- Order information
    soh.OrderDate,
    soh.CustomerID,
    soh.OnlineOrderFlag,

    -- Customer region details
    st.Name as Region,
    st.CountryRegionCode as Region_Code,

    -- Customer personal details
    pp.Title as Gender,
    concat(pp.FirstName, ' ', coalesce(pp.MiddleName, ''), ' ', pp.LastName) as FullName,

    -- Product hierarchy
    pm.Name as Model_Name,
    ps.Name as Subcategory_Name,
    pc.Name as Category_Name,

    -- Promotion/Offer details
    so.Description as Offer_Desc,
    so.Type as Offer_Type,

    -- Fiscal year classification based on order date
    case 
        when soh.OrderDate >= '2011-05-31' and soh.OrderDate <= '2012-05-30' then 'FY11'
        when soh.OrderDate >= '2012-05-31' and soh.OrderDate <= '2013-05-30' then 'FY12'
        when soh.OrderDate >= '2013-05-31' and soh.OrderDate <= '2014-06-30' then 'FY13'
        else null
    end as FiscalYear,

    -- Business type classification: B2C or B2B
    case
        when sc.StoreID is null then 'B2C'
        else 'B2B'
    end as businesstype,

    -- Customer's first purchase date from the CTE
    fp.first_purchase_date,

    -- Flag to indicate if the current order is the customer's first purchase
    case 
        when soh.OrderDate = fp.first_purchase_date then 1
        else 0
    end as is_first_purchase

-- Joining various related tables for enriched information
from Production.Product p
    join Sales.SalesOrderDetail sod on p.ProductID = sod.ProductID
    join Sales.SalesOrderHeader soh on sod.SalesOrderID = soh.SalesOrderID
    join Sales.Customer sc on soh.CustomerID = sc.CustomerID
    join Sales.SalesTerritory st on sc.TerritoryID = st.TerritoryID
    join Person.Person pp on sc.PersonID = pp.BusinessEntityID
    join Production.ProductModel pm on p.ProductModelID = pm.ProductModelID    
    join Production.ProductSubcategory ps on p.ProductSubcategoryID = ps.ProductSubcategoryID
    join Production.ProductCategory pc on ps.ProductCategoryID = pc.ProductCategoryID
    left join Sales.Store ss on pp.BusinessEntityID = ss.BusinessEntityID
    left join Sales.SpecialOffer so on sod.SpecialOfferID = so.SpecialOfferID
    left join FirstPurchase fp on soh.CustomerID = fp.CustomerID

-- Grouping to support aggregation functions like SUM
group by 
    p.ProductID,
    p.Name,
    p.Color,
    p.StandardCost,
    p.ListPrice,
    p.Size,
    sod.SalesOrderID,
    sod.OrderQty,
    sod.UnitPrice,
    sod.UnitPriceDiscount,
    soh.OrderDate,
    soh.CustomerID,
    soh.OnlineOrderFlag,
    st.Name,
    st.CountryRegionCode,
    pp.Title,
    pp.FirstName,
    pp.MiddleName,
    pp.LastName,
    pm.Name,
    ps.Name,
    pc.Name,
    so.Description,
    so.Type,
    sc.StoreID,
    fp.first_purchase_date;
