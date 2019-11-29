defmodule Twitter do
  def start(num_usr, num_msg) do


    # [num_usr, num_msg] = System.argv()
    # num_usr = String.to_integer(num_usr)
    # num_msg = String.to_integer(num_msg)

    # we need to ETS table for storing info
    # to store user and its process id <usr,pid>
    :ets.new(:usrProcessTable,[:set,:public,:named_table])
    # to store the user and its subscriber <usr, List<usr>>
    :ets.new(:subTable,[:set,:public,:named_table])
    # store the the usr and its msg <usr, List<msg>>
    :ets.new(:msgTable,[:set,:public,:named_table])

    :ets.new(:eid,[:set,:public,:named_table])
    :ets.new(:pending, [:set,:public,:named_table])
    :ets.new(:hashtag_table, [:set, :public, :named_table])
    :ets.new(:mentions_table, [:set, :public, :named_table])

    # start twitter engine
    # engines task is to distribute so it wont maintain any state
    {:ok,eng_id}=Engine.start_link([])
    :ets.insert(:eid, {"eid",eng_id})

    # create user process and store its id


    # Enum.each(1..num_usr, fn(x)->
    #   Twitter.register(x,x)
    # end)




    #generate subscribers
    # Enum.each(1..num_usr, fn(x)->
    #   # we will give each user num_usr/10 followers
    #   subList=Enum.reduce(1..:rand.uniform(num_usr), [] ,fn(s,acc)->
    #     rand_sub = :rand.uniform(s)
    #     cond do
    #       rand_sub != x ->acc ++ [rand_sub]
    #       true -> acc ++ []
    #     end
    #   end)
    #   :ets.insert(:subTable,{x, Enum.uniq(subList)})
    # end)




    # Twitter.send_message(num_usr,num_msg)
    # User.send_message(1,"#UFL go gators @3")
    # Process.sleep(100)
    # Twitter.query_mentions(3)
    # # User.logout(3)
    # # User.logout(4)
    # # User.logout(5)
    # Process.sleep(100)
    # #User.login(3,3)
    # Twitter.retweet(1)

    # Twitter.queryHashTag("#UFL")

    # Process.sleep(3000)



    # # pick a random user and a random sub
    # usr = :rand.uniform(num_usr)
    # [{_,subList}] = :ets.lookup(:subTable,usr)
    # cond do
    #   subList==[] ->IO.puts("No tweets")
    #   true->sub = Enum.random(subList)
    #             IO.puts("Looking for #{sub} for #{usr}")
    #             Twitter.query(usr,sub)
    # end
     #loop()
  end




  def generateRandSub(num_usr) do
    Enum.each(1..num_usr, fn(x)->
        # we will give each user num_usr/10 followers
        subList=Enum.reduce(1..:rand.uniform(num_usr), [] ,fn(s,acc)->
          rand_sub = :rand.uniform(s)
          cond do
            rand_sub != x ->acc ++ [rand_sub]
            true -> acc ++ []
          end
        end)
        :ets.insert(:subTable,{x, Enum.uniq(subList)})
      end)
      :true
  end


  def queryHashTag(hashtag) do
    Engine.getHashTag(hashtag)
  end


  def send_message(num_usr,num_msg) do
    Enum.each(1..num_usr, fn(x)->
      Enum.each(1..num_msg, fn(s)->
        spawn(fn->User.send_message(x,"hello#{s} #gators")
      end)
      end)
    end)
  end

  def subscribe(usr,sub) do
    #usr wants to subscribe a person(sub)
    #add that person to the sub's subtable
    result=Engine.subscribe(usr,sub)
    #[{_,subList}] = :ets.lookup(:subTable,sub)
    :true
  end

  def loop() do
    loop()
  end

  # search for given subscriber
  def query(usr,sub) do
    IO.puts(sub)
    Engine.queryForSub(usr,sub)
  end

  def retweet(uid) do
    # get all received message
    User.retweet(uid)
  end

  def register(usr_id,usr_pswd) do
    result = Engine.checkUser(usr_id)

    if result==:false do
      User.start_link([usr_id,usr_pswd,1,[],[],0])

      #IO.puts("User#{usr_id} successfully registered")
      :true
    else
      IO.puts("User#{usr_id} already exists")
      :false
    end
  end

  def delete(uid) do
    Engine.deleteUser(uid)
  end

  def display_feed(uid) do
    result=User.getFeed(uid)
   # result
    :true
  end


  def query_mentions(uid) do
    Engine.queryMention(uid)
  end


end

#Twitter.start
