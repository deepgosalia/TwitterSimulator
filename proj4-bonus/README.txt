##1. Team Members 

 Deep Chetan Gosalia 5697-9299
 Rohan Nitin Gandhi  1791-0958
 




## for Bonus part run in proj4-bonus folder
  mix run proj4.ex numuser numtweets  (for bonus part)

##2. How to run
  mix test



##3. Functionalities Implemented
1.Register account
2.Send tweet. Tweets can have hashtags and mentions	
3.Subscribe to user's tweets
4.Re-tweets
5.Allow querying tweets subscribed to, tweets with specific hashtags, tweets in which the user is mentioned (my mentions)
6.If the user is connected, deliver the above types of tweets live (without querying)



##4. Test Cases
1.check if user is online
2.Register an already registered user
3.Subsrcibe to a specific user
4.Generate random subscriber for every user
5.Generate random subscribers and make every send a tweet
6.Send tweets with Hashtags and search it.
7.Make random user retweet a tweet it has received.
8.Make all the user tweet and query if user was mentioned.
9.Logout a user and send a tweet
10.login a perivisouly logout user and check if live tweet is recieved
11.delete account and register him again




Check Report-Bonus.pdf for the analysis of bonus part
##5 Performance anaylsis
1.We have implemented the project using genserver where a single server keeps track of every user,tweet, subscription, retweet, hashtags and mentions.
2.The number of users are created with the input given from command line argument. The followers are added randomly to every user.
3.The users tweet and retweet randomly in the project which can be made manual.
4.The users subsrcibe to the tweets and the hashtags randomly.