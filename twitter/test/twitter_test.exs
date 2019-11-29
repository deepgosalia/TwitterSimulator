defmodule TwitterTest do
  use ExUnit.Case
  doctest Twitter



  # Test Case 1
  test "register 5 users" do
    Twitter.start(5,2)
    Enum.each(1..5, fn(x)->
     assert Twitter.register(x,x) == :true
    end)
    # this below line will be only executed if the above was successful
    IO.puts("All users successfully registered")
  end


 # Test Case 2
  test "register a already registered user" do
    # here we have asumed user id same as user password
    Twitter.start(5,2)
    Enum.each(1..5, fn(x)->
     assert Twitter.register(x,x) == :true
    end)

    # tryin registereing already registered user
    assert Twitter.register(5,5) == :false
  end



  # Test Case 3
  test "subscribe to specific user" do
    Twitter.start(5,2)
    Enum.each(1..5, fn(x)->
     assert Twitter.register(x,x) == :true
    end)

    # make user 1 subscribe to user 2,4
    assert Twitter.subscribe(1,2) == :true
    assert Twitter.subscribe(1,4) == :true

  end

  # Test Case 4
  test "generate random subscribers for each user" do
    num_usr = 10
    num_msg = 2
    Twitter.start(num_usr,num_msg)

    #register 10 user
    Enum.each(1..num_usr, fn(x)->
      assert Twitter.register(x,x) == :true
     end)

     #assign random_subs to each user
     assert Twitter.generateRandSub(num_usr) == :true
  end

  # Test Case 5
  test "make subscribers and send them a message" do
    num_usr = 10
    num_msg = 2
    Twitter.start(num_usr,num_msg)

    #register 10 user
    Enum.each(1..num_usr, fn(x)->
      assert Twitter.register(x,x) == :true
     end)

     #assign subs to any user(say 1)
     assert Twitter.subscribe(1,2) == :true
     assert Twitter.subscribe(1,7) == :true
     assert Twitter.subscribe(1,10) == :true



     # make User1 post a message
     assert User.send_message(1,"Go gators!!") == :true

  end

  # Test Case 6
  test "generate random subscribers and make each user send message" do
    num_usr = 10
    num_msg = 5
    Twitter.start(num_usr,num_msg)

    #register 10 user
    Enum.each(1..num_usr, fn(x)->
      assert Twitter.register(x,x) == :true
     end)

     #generate random subs
     assert Twitter.generateRandSub(num_usr) == :true

     #Send random message
    assert Twitter.send_message(num_usr,num_msg) == :ok

  end

  # Test Case 7
  test "send message with hashtag and later search for it" do

    num_usr = 10
    num_msg = 5
    Twitter.start(num_usr,num_msg)

    #register 10 user
    Enum.each(1..num_usr, fn(x)->
      assert Twitter.register(x,x) == :true
     end)

     #generate random subs
     assert Twitter.generateRandSub(num_usr) == :true

     #Send random message "hello1 #gators"
     assert Twitter.send_message(num_usr,num_msg) == :ok

    #query hash tag
     assert Twitter.queryHashTag("#gators")==:ok

  end

  # Test Case 8
  test "make random user retweet the tweet it had received" do
    num_usr = 10
    num_msg = 5
    Twitter.start(num_usr,num_msg)

    #register 10 user
    Enum.each(1..num_usr, fn(x)->
      assert Twitter.register(x,x) == :true
     end)

     #generate random subs
     assert Twitter.generateRandSub(num_usr) == :true

     #Send random message "hello1 #gators"
     assert Twitter.send_message(num_usr,num_msg) == :ok

     #Send retweet
     assert Twitter.retweet(:rand.uniform(num_usr)) == :ok
  end

  # Test Case 9
  test "make all user send message and query if user was mentioned " do
    num_usr = 10
    num_msg = 5
    Twitter.start(num_usr,num_msg)

    #register 10 user
    Enum.each(1..num_usr, fn(x)->
      assert Twitter.register(x,x) == :true
     end)

     #generate random subs
     assert Twitter.generateRandSub(num_usr) == :true

     # make user1 send @2 which is mentioning user 2
     assert User.send_message(1,"Go gators!! @2") == :true

     # query for mentions
     assert Twitter.query_mentions(2)
  end

  # Test Case 10
  test "make a user logout and check its status" do
    num_usr = 10
    num_msg = 5
    Twitter.start(num_usr,num_msg)

    #register 10 user
    Enum.each(1..num_usr, fn(x)->
      assert Twitter.register(x,x) == :true
     end)
     assert User.logout(2) == :ok
  end

  # Test Case 11
  test "Delete Account" do
    Twitter.start(5,2)
    Enum.each(1..5, fn(x)->
     assert Twitter.register(x,x) == :true
    end)
    assert Twitter.delete(2) == :true

  end

end
