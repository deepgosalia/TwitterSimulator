defmodule Twitter do
  def start() do
    [num_usr, num_msg] = System.argv()
    num_usr = String.to_integer(num_usr)
    num_msg = String.to_integer(num_msg)

    # we need to ETS table for storing info
    # to store user and its process id <usr,pid>
    :ets.new(:usrProcessTable,[:set,:public,:named_table])
    # to store the user and its subscriber <usr, List<usr>>
    :ets.new(:subTable,[:set,:public,:named_table])
    # store the the usr and its msg <usr, List<msg>>
    :ets.new(:msgTable,[:set,:public,:named_table])

    :ets.new(:eid,[:set,:public,:named_table])
    :ets.new(:pending, [:set,:public,:named_table])

    # start twitter engine
    # engines task is to distribute so it wont maintain any state
    {:ok,eng_id}=Engine.start_link([])
    :ets.insert(:eid, {"eid",eng_id})

    # create user process and store its id
    Enum.each(1..num_usr, fn(x)->
      User.start_link([x,x,1,[],[]]) # register user, (Assumed user id is x and pswd is x)
      :ets.insert(:subTable, {x,[]})
    end)

    #generate subscribers
    #Twitter.generateSub(num_usr)
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

    Twitter.send_message(num_usr,num_msg)
    # User.logout(3)
    # User.logout(4)
    # User.logout(5)
    Process.sleep(100)
    #User.login(3,3)
    Twitter.retweet(1)

    Process.sleep(3000)
    # pick a random user and a random sub
    usr = :rand.uniform(num_usr)
    [{_,subList}] = :ets.lookup(:subTable,usr)
    cond do
      subList==[] ->IO.puts("No tweets")
      true->sub = Enum.random(subList)
                IO.puts("Looking for #{sub} for #{usr}")
                Twitter.query(usr,sub)
    end
    loop()
  end



  def send_message(num_usr,num_msg) do
    Enum.each(1..num_usr, fn(x)->
      Enum.each(1..num_msg, fn(s)->
        spawn(fn->User.send_message(x,s,"hello#{s}")
      end)
      end)
    end)
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

  def delete(uid) do
    User.deleteUser(uid)
  end


end

Twitter.start
