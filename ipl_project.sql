use ipl;
-- Questions – Write SQL queries to get data for the following requirements:
SELECT * FROM IPL_BIDDING_DETAILS;
-- 1.Show the percentage of wins of each bidder in the order of highest to lowest percentage.
select *,round(count_bid/sum(count_bid)over() *100,2) percentage from
(select bidder_id,bid_status,count(bid_status) count_bid from ipl_bidding_details 
where BID_STATUS='won'
group by bidder_id,2
order by count_bid desc) t;

-- 2.Display the number of matches conducted at each stadium with the stadium name and city.
select ms.STADIUM_ID,count(ms.MATCH_ID) no_of_matches ,ipls.STADIUM_NAME,city from 
ipl_match_schedule ms join ipl_stadium ipls on 
ms.STADIUM_ID = ipls.STADIUM_ID
group by stadium_id
order by 1 ;

-- 3.In a given stadium, what is the percentage of wins by a team that has won the toss?

select stadium_id,winning_status,count_win,round((count_win/sum(count_win)over(partition by STADIUM_ID))*100,2) perecentage_of_wins from
(select stadium_id,winning_status,count(winning_status) as count_win  from
(select im.MATCH_ID,STADIUM_ID,
if(TOSS_WINNER=MATCH_WINNER,"toss_and_win","toss_and_loss") winning_status
from  ipl_match 
im join ipl_match_schedule ims on im.MATCH_ID = ims.MATCH_ID
where status !='cancelled') t 
group by 1,2
order by 1) T;

select stadium_id,stadium_name, (cnt/sum(cnt) over())*100 percent from (select ims.stadium_id,
(select stadium_name from ipl_stadium ipls where ims.stadium_id = ipls.stadium_id ) stadium_name
,count(Match_winner)cnt from ipl_match_schedule IMS
join ipl_match IM
on IMS.match_id = IM.match_id
where status='completed'
and toss_winner = match_winner
group by stadium_id
order by stadium_id)t;


-- 4.Show the total bids along with the bid team and team name.
select distinct bid_team,count(BIDDER_ID)over(partition by bid_team) count_bid ,team_name
from ipl_bidding_details iplbd
join ipl_team iplt on iplbd.BID_TEAM=iplt.TEAM_ID;

-- 5.Show the team ID who won the match as per the win details.
select match_id,TEAM_ID1,TEAM_ID2,match_winner,
if(match_winner = 1,team_ID1,team_ID2) as `teamid which won the match` from ipl_match;

select * from ipl_team;

-- 6.Display the total matches played, total matches won and total matches 
-- lost by the team along with its team name.
select distinct it.team_id,TEAM_NAME,sum(MATCHES_PLAYED)over(partition by it.team_id) `total matches played`, 
sum(MATCHES_WON)over(partition by it.team_id) `total matches won`,
sum(MATCHES_LOST)over(partition by it.team_id) `total matches lost` from ipl_team_standings its
join ipl_team it on its.TEAM_ID = it.team_id;

-- 7.Display the bowlers for the Mumbai Indians team.
select it.TEAM_ID,itp.PLAYER_ID,PLAYER_ROLE,TEAM_NAME from ipl_team_players itp
join ipl_team it on itp.TEAM_ID=it.TEAM_ID
where PLAYER_ROLE='bowler'and it.remarks like '%MI%';

-- 8.How many all-rounders are there in each team, Display the teams with more than 4 
-- all-rounders in descending order.

select TEAM_ID,count(player_role) as cnt from ipl_team_players
where player_role = 'All-Rounder'
group by TEAM_ID
having cnt >4
order by cnt desc;

-- 9. Write a query to get the total bidders' points for each bidding status of those bidders
-- who bid on CSK when they won the match in M. Chinnaswamy Stadium bidding year-wise.
 -- Note the total bidders’ points in descending order and the year is the bidding year.
-- Display columns: bidding status, bid date as year, total bidder’s points.
create view temp_table as 
select i1.*,i2.TEAM_NAME,i3.STADIUM_ID,i4.STADIUM_NAME,TOTAL_POINTS,i3.MATCH_DATE from ipl_bidding_details i1 join ipl_team i2
on i1.BID_TEAM = i2.TEAM_ID join ipl_match_schedule i3 on i1.SCHEDULE_ID=i3.SCHEDULE_ID 
join ipl_stadium i4 on i3.STADIUM_ID=i4.STADIUM_ID join ipl_bidder_points i5 on i1.BIDDER_ID=i5.BIDDER_ID;

select bidder_id,bid_status,year(bid_date),total_points,sum(total_points)over(partition by bidder_id,bid_status) as total_bidder_points from 
temp_table where bidder_id in(
select bidder_id from temp_table
where TEAM_NAME='Chennai Super Kings' and STADIUM_NAME='M. Chinnaswamy Stadium'
and BID_STATUS='won');

-- 10.Extract the Bowlers and All-Rounders that are in the 5 highest number of wickets.
-- Note 
-- 1. Use the performance_dtls column from ipl_player to get the total number of wickets
 -- 2. Do not use the limit method because it might not give appropriate results when players have 
 -- the same number of wickets
-- 3.Do not use joins in any cases.
-- 4.Display the following columns teamn_name, player_name, and player_role.
create view wickets as
select *,dense_rank()over(order by wickets desc) as drnk from(
select *, 
cast(substr(substr(PERFORMANCE_DTLS,instr(performance_dtls,"W"),instr(performance_dtls,"D")-instr(performance_dtls,"W")),5) as double)
as wickets from ipl_player
order by wickets desc) t;

select team_id,(select team_name from ipl_team where team_id=t1.team_id) as teamname,player_id,player_role
from ipl_team_players t1 where player_id in
(select player_id from wickets
where drnk<=5) and
player_role in('Bowler','All-rounder');



-- 11.show the percentage of toss wins of each bidder and display the results in
-- descending order based on the percentage
select BIDDER_ID,round((Toss_Win/Tot_Count)*100,2) Toss_Win_Percent from
(select BIDDER_ID,count(t1.MATCH_ID) Tot_Count,sum(if(BID_TEAM=TOSS_WINNER,1,0)) Toss_Win 
from ipl_bidding_details t inner join ipl_match_schedule t1 
on t1.SCHEDULE_ID=t.SCHEDULE_ID inner join ipl_match t2 
on t2.MATCH_ID=t1.MATCH_ID group by BIDDER_ID)t order by Toss_Win_Percent desc;

-- 12.find the IPL season which has a duration and max duration.
-- Output columns should be like the below:
 -- Tournment_ID, Tourment_name, Duration column, Duration
 select * from ipl_match_schedule;
 
select * from
 (select TOURNMT_ID,TOURNMT_NAME,from_date,to_date,datediff(to_date,from_date) as duration ,
 rank()over(order by datediff(to_date,from_date) desc) as rnk 
 from ipl_tournament ) t
 where rnk =1;
 

-- 13.Write a query to display to calculate the total points month-wise for the 2017 bid year.
-- sort the results based on total points in descending order and month-wise in ascending order.
-- Note: Display the following columns:
-- 1.Bidder ID, 2. Bidder Name, 3. Bid date as Year, 4. Bid date as Month, 5. Total points
-- Only use joins for the above query queries.
select distinct bidder_id,bidder_name,month,year(bid_date),totalpoints from 
(
select jt.bidder_id,BIDDER_NAME,bid_date,month(bid_date) as month,sum(total_points)over(partition by month(bid_date) ,bidder_id) totalpoints 
from joined_tables jt join ipl_bidder_details ibd on jt.bidder_id = ibd.BIDDER_ID
where year(bid_date)=2017) t
order by totalpoints desc, month asc;

-- 14.Write a query for the above question using sub-queries by having the same constraints as the above question.
select BIDDER_ID,(select BIDDER_NAME from ipl_bidder_details ibrd where BIDDER_ID=t.BIDDER_ID) BIDDER_NAME,
year(BID_DATE) Year,month(BID_DATE) Month,sum(if(BID_STATUS='Won',2,0)) Total_Points
from ipl_bidding_details t where year(BID_DATE)=2017 
group by BIDDER_ID,BIDDER_NAME,Year,Month
order by Total_Points desc,month(BID_DATE) asc;

/*15.Write a query to get the top 3 and bottom 3 bidders based on the total bidding points for the 2018 bidding year.
Output columns should be:
like
Bidder Id, Ranks (optional), Total points, Highest_3_Bidders --> columns contains name of bidder, 
-- Lowest_3_Bidders  --> columns contains name of bidder;*/
create view top_bidders as
(select distinct *,dense_rank()over(order by totalpoints desc) as rnk from 
(select distinct tt.bidder_id,bidder_name,sum(total_points)over(partition by bidder_id) totalpoints
from temp_table tt join ipl_bidder_details t4 on tt.bidder_id = t4.BIDDER_ID
where year(bid_date)=2018) t);

select *,(select bidder_name from top_bidders t1 where bidder_name =t2.bidder_name and rnk in (1,2,3)) as top3_bidders,
(select bidder_name from top_bidders where bidder_name =t2.bidder_name and rnk =21 ) as low3_bidders
from top_bidders t2 ;

/*16.Create two tables called Student_details and Student_details_backup. (Additional Question - Self Study is required)

Table 1: Attributes 		Table 2: Attributes
Student id, Student name, mail id, mobile no.	Student id, student name, mail id, mobile no.

Feel free to add more columns the above one is just an example schema.
Assume you are working in an Ed-tech company namely Great Learning where you will be inserting and modifying the details of the students in the Student details table. Every time the students change their details like their mobile number, You need to update their details in the student details table.  Here is one thing you should ensure whenever the new students' details come, you should also store them in the Student backup table so that if you modify the details in the student details table, you will be having the old details safely.
You need not insert the records separately into both tables rather 
Create a trigger in such a way that It should insert the details into the Student back 
table when you insert the student details into the student table automatically.

*/
CREATE TRIGGER insert_student_backup
AFTER INSERT ON student_details
FOR EACH ROW
BEGIN
  INSERT INTO student_backup_details (
      student_id,
      student_name,
      mail_id,
      mobile_no
  )
  VALUES (
      NEW.student_id,
      NEW.student_name,
      NEW.mail_id,
      NEW.mobile_no
  )
END ;