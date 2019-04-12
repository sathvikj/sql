# Find the top 3 sellers who had shipped most number of items within 10 days of transaction in 2015

select x.seller_id,count(distinct(x.transaction_id)) as orders from 
(
(select seller_id,transaction_date,shipping_id,transaction_id from transaction) t
join 
(select shipping_id,seller_ship_date from shipping) s on t.shipping_id = s.shipping_id
join 
(select seller_id,name from seller) se on se.seller_id = s.shipping_id 
) x
where datediff(x.seller_ship_date,x.transaction_date) <= 10 and transaction_date >= '2015-01-01'
group by 1
order by 2 desc limit 3

# What was the longest duration a buyer had to wait after the transaction to receive a product in the fashion vertical
  Give the transaction id, carrier name, service name and the wait time ordered by carrier name. Display all transactions
  if there are more than 1 transactions.

select y.transaction_id,y.carrier_name,y.name from (  
select x.transaction_id,x.carrier_name,x.name,
dense_rank() over(order by (x.transaction_date - x.delivery_date) desc) as rank from(
(select transaction_id,shipping_id,transaction_date,leaf_category_id from transaction) t
join 
(select shipping_id,delivery_date,carrier_id from shipping) s on s.shipping_id = t.shipping_id
join 
(select service_id,name from service) se on se.service_id = s.service_id
join 
(select leaf_category_id,vertical from category) c on c.leaf_category_id = t.leaf_category_id
join
(select carrier_id,carrier_name from carrier) ca on ca.carrier_id = s.carrier_id
) x
where x.vertical like "%fashion%"
having rank = 1) y

# Idntify the count of Live Listings as on 2015-07-07. A listing is considered as a live listing
#  on a specific date if that listings auction has not yet ended as of that date. Provide the data
#  across Vertical, Seller Segment and Seller Country

select x.vertical,x.country,x.name,count(*) from ((select seller_id,name,country from seller) s
join
(select seller_id,auction_end_date,leaf_category_id from listing) l on l.seller_id = s.seller_id
join
(select leaf_category_id,vertical from category) c on c.leaf_category_id = l.leaf_category_id) x
where auction_end_date >= '2015-07-07'
order by 1,2,3

# For the period Feb - 2015 to July 2015, which buyer country and seller country combination with 
  highest cross-border (buyer country and seller country not same) transaction amount (Price * Quantity)

select x.buy_country,x.sell_country,sum(x.price*x.quantity) as order_value from (
(select buyer_id,seller_id,transaction_date,price,quantity from transactions 
where buyer_id != seller_id and transaction_date between '2015-02-01' and '2015-07-31') t join
(select buyer_id,country as buy_country from buyer) b on b.buyer_id = t.buyer_id
join
(select seller_id,country as sell_country from seller) s on s.seller_id = t.seller_id) x
group by 1,2

## provide list of sellers and their top three carriers based on their shipping counts, and report transaction per shipping.

select y.name,y.carrier_name,y.rank,y,average from
(select x.name,x.carrier_name,rank() over(order by x.count asc limit 3) as rank,x.sum/x.count as average from
(select se.name,ca.carrier_name,count(shipping_id) as count,sum(tr.tval) as sum from
((select seller_id,name from seller) se
join
(select seller_id,shipping_id,sum(price*quantity) as tval from transaction group by 1,2) tr on tr.seller_id = se.seller_id
join
(select shipping_id,carrier_id from shipping) sh on sh.shipping_id = tr.shipping_id
join
(select carrier_name,carrier_id from carrier) ca on ca.carrer_id = sh.carrier_id))x group by 1,2)y)
order by 1,2 desc