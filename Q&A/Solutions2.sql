-- What are average sales for a customer's first transaction, second transaction, and third or more transaction?
-- As the time stamp is not given, results might vary as a customer could have done multiple transactions in a day.
-- Query is written for sales2, can be used for sales1 just by changing the table name to sales1
    
select b.trans_no,avg(b.Sales) from
	( -- Table to rank the transactions higher than 3 as three
	select a.CustomerID,a.TransactionDate,a.Sales,
    case when trans_rank >= 3 then 3 else trans_rank end as trans_no from
		( -- Table to rank the transactions partitioned by customer ID and Transaction Date in ascending order
		select CustomerID,TransactionDate,Sales,
        dense_rank() over(partition by CustomerID order by TransactionDate asc) trans_rank from sales2
        ) a
	) b
group by 1; 

/*Answers 
tansaction1: 1603.13
transaction2: 1142.22
transaction3: 925.32*/  
 
##################################################################################################################################

-- What % of total sales do the top 5 selling stores account for?
-- Query is written for sales2 as there is no data for stores in sales1
select round(sum(x.top5)*100/( /*To Select Total Sales*/ select sum(sales) from sales2),2) as '% from top5' 
from 
	( -- This table is to limit the top 5 sales of a store
	 select storeid,sum(sales) as top5 
		from sales2 group by 1 order by 2 desc 
	 limit 5
     ) x;
     
/*Answer
  % from top5: 11.36 %*/  
 
##################################################################################################################################     
     
-- Which month had the most sales?
-- Query is written for sales2, can be used for sales1 just by changing the table name to sales1
select monthname(transactiondate) as 'Month',sum(sales) as 'Sales' 
	from sales2 
	group by 1 order by 2 desc;
    
/*Answer
December: 9,373,059*/  
 
##################################################################################################################################    
    


-- What % of customers shopped in 2 different months or more?
-- Query is written for sales2, can be used for sales1 just by changing the table name to sales1
select round(count(*)*100/(/*total unique customers*/select count(distinct(customerid)) from sales2),2) as 'Percentage' from 
	( -- To extract the count of transactions done in more than 2 months
     select CustomerID,count(*) as 'ct' from 
		( -- To find out the first transaction in each month to compare with other months transactions
         select customerid,
			row_number() over(partition by customerid,month(TransactionDate) order by transactiondate asc) as 'ranked' 
				from sales2 order by 1,2 desc
		) x
    where x.ranked = 1    
	group by 1
		having ct > 1
    ) y;
    
/*Answer
 Percentage - 14.09*/  
 
##################################################################################################################################    


-- For customers that shopped more than once and spent between $500 and $1000 on their first purchase, 
-- what is the average spend for the second purchase?
-- Query is written for sales2 can be used for sales1 by changing the table name
select round(avg(Sales),2) as 'Avg Sale for Second Transaction' 
				from 
				( -- Filtering second transactions using rank
				select Sales, dense_rank() over(partition by CustomerID order by TransactionDate desc) as rank2 from sales2 where CustomerID in  
					   ( -- Filtering where customerid's who made their first transaction between 500 and 1000
					   select CustomerID from 
								( -- Selecting customer id's who made their first transaction between 500 and 1000
							select CustomerID,Sales,
							dense_rank() over(partition by CustomerID order by TransactionDate desc) as rank1 
							from sales2 
								where CustomerID in (  -- Filtering where customerid's who made more than 1 transaction
													 select CustomerID from 
															( -- Selecting customerid's who made more than 1 transaction
															select CustomerID,count(TransactionDate) as cnt from sales2 group by 1 having cnt > 1
															) a
													)
								) b
						   where b.rank1 = 1 and b.Sales between 500 and 1000
					   )
			   ) c
         where c.rank2 = 2;
         
 /*Answer
 Average Sale for second Transaction:
 1604.03*/  
 
##################################################################################################################################



















