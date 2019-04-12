-- What % of sales result in a return? 

select count(*) as 'total returns', round(count(r.returnsales)*100/(select count(sales) from sales1),2) as '% Sales Returned "Count"' 
	from 
		(select orderid,sales from sales1) s1 
	inner join  -- To consider values only that are common in both tables
         (select orderid,returnsales from returns_tbl /*where returnsales != 0*/) r -- Can Include Where condition if necessary, need more info on this
	on r.orderid = s1.orderid;
    
/*Answer
 Total Returns = 1565
 % Sales Returned Count = 4.64*/  
 
##################################################################################################################################

-- What % of returns are full returns? 

select round(count(r.returnsales)*100/(select count(sales) from sales1 s1 join returns_tbl r1 on r1.orderid = s1.orderid),2) as '% Sales Returned' 
	from 
		 (select orderid,sales from sales1) s1 
	inner join -- To consider values only that are common in both tables
         (select orderid,returnsales from returns_tbl) r
	on r.orderid = s1.orderid
where s1.sales = r.returnsales; -- to filter only values that are same

/*Answer
% of sales returned = 18.15*/  
 
##################################################################################################################################

-- What is the average return % amount (return % of original sale)? 

select round(avg(r.returnsales*100/s1.sales),2) as 'Average % of returns to Original' 
	from 
		(select orderid,sales from sales1) s1 
	inner join  -- To consider values only that are common in both tables
		(select orderid,returnsales from returns_tbl /*where returnsales != 0*/) r -- Can Include Where condition if necessary, need more info on this 
	on r.orderid = s1.orderid;

/*Answer
Return % of original sale:  52.80*/  
 
##################################################################################################################################

-- What % of returns occur within 7 days of the original sale? 
select round(100*count(b.OrderID)/count(a.OrderID),2) as "% returns" 
	from
		(select distinct(r.OrderID) from sales1 as s join returns_tbl as r on s.OrderID = r.OrderID) as a
	left join
		(select distinct(r.OrderID) from sales1 as s join returns_tbl as r on 
			s.OrderID = r.OrderID and datediff(r.ReturnDate,s.TransactionDate) <= 7
		) as b on a.OrderID = b.OrderID; -- Left Join with both the order id's as same
        
/*Answer
% of returns <= 7 days: 42.50 days*/  
 
##################################################################################################################################


-- What is the average number of days for a return to occur? 
select avg(datediff(r.returndate,s1.transactiondate)) as datediff  
	from 
		(select orderid,TransactionDate from sales1) s1 
	join 
		(select orderid,returndate from returns_tbl /*where returnsales != 0*/) r -- Can Include Where condition if necessary, need more info on this
	on r.orderid = s1.orderid;
 
 -- considering return probability ( In case what is the avg no. of days for a return to occur considering all orders)
select avg(datediff(r.returndate,s1.transactiondate))*(count(r.OrderID)/count(s1.OrderID)) as 'datediff'
	from 
		(select orderid,TransactionDate from sales1) s1
	left join 
		(select orderid,returndate from returns_tbl /*where returnsales != 0*/) r -- Can Include Where condition if necessary, need more info on this
	on s1.OrderID = r.OrderID;
 
/*Answer
Average number of days: 78.44*/  
 
##################################################################################################################################
            
-- Using this data set, how would you approach and answer the question, who is our most valuable customer?

-- The below table first calculates the net ratio of sales done by the customer and penalizing in the denominator with returns to
-- calculate the customers based on their return patterns.alter
-- Then a min max scaler is used to rate each customer that is a customer who made more sales and returned less would get the highest rank
-- Also the orders count and return count can also be considered but as the data didn't mention any details about the returns
-- those metrics are not included in the rating system.
-- If net loss due to returns is given, those can be included to calculate an effective rating.alter
-- Customer RIVES87271 is the most valued one, removed the customer as its causing huge outlier issue.

with test as -- Creating a Common Table Expressionto use later
	(	 -- This table is a sum-up of the join from selected fields from sales1 and returns table
	select s1.customerid, s1.sales,
	ifnull(r1.ret_sales,0) as 'return_sales',
	s1.ct as 'ord_count',
	ifnull(r1.ret_ct,0) as 'ret_count',
	case when ifnull(r1.ret_sales,0) = 0 
		then s1.sales/1 
		else s1.sales/ifnull(r1.ret_sales,0) 
		end as 'sales_ratio'
	from ( -- This table is to select details from sales1 table
		select customerid,sum(sales) as 'sales',count(orderid) as ct 
			from sales1
			group by 1 
		 ) s1
	left join -- Left outer join is used not to miss any values from table sales1
		( -- This table is to select details from returns table
        select customerid,sum(returnsales) as 'ret_sales',count(orderid) as 'ret_ct' 
			from returns_tbl
			group by 1
		) r1 on s1.customerid = r1.customerid
where s1.customerid not in ('GAVAS36530','RIVES87271') -- This is an outlier that causes the ratio to take a bump
having sales_ratio > 1 -- These are the values where return values are greater than order values. Could be mistakes or the data is coming from other source (sales2)
order by 6 desc
	)
select *,
round(5*(sales_ratio - (select min(sales_ratio) from test))/ -- This is a max min scaler multiplied with 5 to get the scoring from 0 to 5
	(	
    (select max(sales_ratio) from test) - (select min(sales_ratio) from test) -- Selecting max and min from the sales_ratio
	),2) as rating 
    from test;




































