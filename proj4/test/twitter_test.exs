defmodule TwitterTest do
  use ExUnit.Case
  doctest Twitter

  setup_all()  do
    {:ok,eng_id}=Engine.start_link([])
    #:ets.insert(:eid, {"eid",eng_id})
    Twitter.start1(10,2)
    {:ok, eng_id: eng_id}
  end

  #Test Case 1
  test "check if user is online" do
    assert User.isOnline(5) == 1  # 1 means online
    refute User.isOnline(5) == 0  # 0 means offline
  end


 #Test Case 2
  test "register a already registered user" do
    assert Twitter.register(5,5) == :false
    Process.sleep(100)
  end

  # Test Case 3
  test "subscribe to specific user" do
    assert Twitter.subscribe(1,2) == :true
    assert Twitter.subscribe(4,2) == :true
    assert Twitter.getSubList(2) == :true
  end

#   # Test Case 4
  test "generate random subscribers for each user" do
     #assign random_subs to each user and also print the list assigned
     #assert Twitter.generateRandSub(num_usr) == :true
  end

#   # Test Case 5
  test "send subscribers a message" do

     sender = :rand.uniform(10)
     User.send_message(sender,"Go gators!!")==:ok
     Process.sleep(1000)
     Twitter.display_feed(sender,0)
    Process.sleep(100)
  end

  # # Test Case 6
  test "Logout and login a user and check status" do
    Process.sleep(100)
    assert User.logout(1) == :ok
    Process.sleep(100)
    assert User.isOnline(1) == 0
    Process.sleep(100)
    assert User.login(1,1) == :ok
  end

  # #Test Case 7
  test "send message with hashtag and later search for it" do
    Process.sleep(200)
    assert Twitter.queryHashTag("#gators")==:ok
  end

  # # Test Case 8
  test "make random user retweet the tweet it had received" do
     u = :rand.uniform(10)
     Process.sleep(200)
    assert Twitter.retweet(u)==:ok
  end

  # # # Test Case 9
  test "make a user send tweet with mentions " do
     User.send_message(:rand.uniform(10),"Go gators @2 !!")
      Process.sleep(200)
    assert Twitter.query_mentions(2)==:ok
     Process.sleep(100)
  end

  # # Test Case 10
  test "make a user logout and send it a tweet" do

    Process.sleep(200)
    assert User.logout(2)==:ok

     #Mention 2 in a tweet
     User.send_message(:rand.uniform(10),"Welcome to UFL! @2")
     Process.sleep(300)
     #check if user 2 recived it
     assert User.getFeed(2,2)==:ok
     Process.sleep(100)

  end

  # # # Test Case 11
  test "make a user logout and send it a tweet and then again login and get live feeds" do
     User.logout(3)
     Process.sleep(200)
     #Mention 2 in a tweet
     User.send_message(:rand.uniform(10),"Welcome to UFL @3 !!")
     Process.sleep(200)
     User.login(3,3) # usr id is 3 and pswd is 3
     Process.sleep(100)
     assert User.getFeed(3,2) == :ok
     Process.sleep(100)
  end


  # Test Case 12
  test "Delete Account and register again" do
    Process.sleep(100)
    #assert Twitter.delete(7) == :true
    Process.sleep(100)

    # if it was already there then it would have failed
    #assert Twitter.register(7,7) == :true
    Process.sleep(100)
  end

end
