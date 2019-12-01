defmodule Engine do
  use GenServer
  def start_link(arg) do
    :ets.new(:usrProcessTable,[:set,:public,:named_table])
    # to store the user and its subscriber <usr, List<usr>>
    :ets.new(:subTable,[:set,:public,:named_table])
    # store the the usr and its msg <usr, List<msg>>
    :ets.new(:msgTable,[:set,:public,:named_table])

    :ets.new(:eid,[:set,:public,:named_table])
    :ets.new(:pending, [:set,:public,:named_table])
    :ets.new(:hashtag_table, [:set, :public, :named_table])
    :ets.new(:mentions_table, [:set, :public, :named_table])


    # :ets.insert(:hashtag_table,{"#gators",[]})
    # :ets.insert(:hashtag_table,{"#gators",[]})
    # :ets.insert(:hashtag_table,{"#gators",[]})
    # :ets.insert(:hashtag_table,{"#gators",[]})

    {:ok,eng_id} = GenServer.start_link(__MODULE__, arg)
    :ets.insert(:eid, {"eid",eng_id})
    {:ok, eng_id}
  end

  def init(arg) do
    Process.flag(:trap_exit, true)
    {:ok,arg}
  end


  def getSubList(uid) do
    [{_,subList}] = :ets.lookup(:subTable, uid)
    subList
  end

  def getPID(uid) do
    [{_,data}] = :ets.lookup(:usrProcessTable, uid)
    pid = Enum.at(data,2)
    pid
  end

  def getHashTag(hashTag) do
    [{_,eid}] = :ets.lookup(:eid, "eid")
    GenServer.cast(eid,{:queryHashTag,hashTag})

  end

  def queryMention(uid) do
    [{_,eid}] = :ets.lookup(:eid, "eid")
    GenServer.cast(eid,{:getMentions,uid})

  end


  def checkUser(uid) do
    cond do
      :ets.member(:usrProcessTable, uid) ->
        :true
      true->:false
    end
  end

  def handle_cast({:getMentions,uid},state) do
    [{_,msg}] = :ets.lookup(:mentions_table,"@#{uid}")

    Enum.each(msg, fn(tweet)->
      [{_,[message,from]}] = :ets.lookup(:msgTable, tweet)
      IO.puts("User #{from} mentioned you (User #{uid}): #{message}")
    end)
    {:noreply,state}
  end

  def handle_cast({:queryHashTag,hashTag},state) do
    [{_,msg}] = :ets.lookup(:hashtag_table,hashTag)
    IO.puts("Searching for hashtags")
    IO.puts("\n--->>Here are your results for hashTag #{hashTag}\n")

    if msg != [] do
      Enum.each(msg, fn(x)->

    [{_,[message,from]}] = :ets.lookup(:msgTable, x)
            IO.puts("#{message} tweet from User#{from}: Tweet ID #{x}")
      end)
    else
      IO.puts("no such tags")
    end


    # Enum.each(msg, fn(x)->
    #   cond  do
    #     (:ets.member(:msgTable,x))->
    #       [{_,[message,from]}] = :ets.lookup(:msgTable, x)
    #       IO.puts("#{message} tweet from User#{from}: Tweet ID #{x}")
    #       true->:true
    #   end
    # end)

    {:noreply,state}
  end

  def distributeMsg(uid,msg_id,type,retweet_origin) do
    # for each subscriber existing send them tweet, if not online then save it else send it
    [{_,eid}] = :ets.lookup(:eid, "eid")
    GenServer.cast(eid,{:distMsg,uid,msg_id,type,retweet_origin})

    # get subscriber list for user
  end

  def queryForSub(usr, sub) do
    [{_,subList}] = :ets.lookup(:subTable, usr)
    # first we need to confirm if user is subscribed to that user
    if(Enum.member?(subList, sub)) do
      [{_,data}] = :ets.lookup(:usrProcessTable, usr)
      pid = Enum.at(data,2)
      #subPID = Engine.getPID(sub)
      GenServer.cast(pid, {:getSubMsg,sub})

    end

  end

  def subscribe(usr,sub) do
    [{_,eid}] = :ets.lookup(:eid, "eid")
    result=GenServer.call(eid, {:addSub,usr,sub})
    if result do
      :true
    else
      :false
    end
    # IO.inspect(list)
  end

  def handle_call({:addSub,usr,sub},_from,state) do
    [{_,subList}] = :ets.lookup(:subTable,sub)
    if sub != usr do
      subList  = subList ++ [usr]
      :ets.insert(:subTable,{sub, Enum.uniq(subList)})
    end

     # uniq to prevent duplicate entries
    {:reply,:true,state}
  end

  def deleteUser(uid) do
    pid = User.getPID(uid)
    # Process.exit(pid, :normal)
    # delete any pending message
    :ets.delete(:pending, uid)
    :ets.lookup(:subTable, uid)
    :ets.lookup(:mentions_table, uid)
    # delelte message that user had sent
    GenServer.cast(pid, {:deleteTweets})

    Process.exit(pid, :normal)

  end

  def preProcessMsg(msg_id) do
    [{_,eid}] = :ets.lookup(:eid, "eid")
    GenServer.cast(eid, {:preProcess,msg_id})

  end

  def handle_cast({:preProcess,msg_id},state) do
    #get msg
   # IO.inspect(:ets.lookup(:msgTable, msg_id))
    [{_,[message,_from]}] = :ets.lookup(:msgTable, msg_id)
      charlist = String.split(message," ")
      hashtags = Enum.filter(charlist, fn x-> String.starts_with?(x,"#")==true end)
      _users = Enum.filter(charlist, fn x-> String.starts_with?(x,"@")==true end)

      Enum.each(hashtags,fn x ->
      if(:ets.member(:hashtag_table,x)) do
        [{_,msg}] = :ets.lookup(:hashtag_table,x)
        msg1=msg++[msg_id]
        :ets.insert(:hashtag_table,{x,msg1})
      else
        :ets.insert(:hashtag_table,{x,[msg_id]})
      end
      end)
    {:noreply,state}
  end


  def handle_cast({:distMsg,uid,message_id,type,retweet_origin},state) do

    [{_,c}] = :ets.lookup(:eid, "num")
    if c==0 do
      Process.sleep(10)
      [{_,stime}] = :ets.lookup(:eid, "stime")
      etime = System.os_time(:millisecond)
      time = etime - stime
      IO.puts("Total time is #{time}")
      System.halt(1)
      #:ets.insert(:eid, {"eid",eng_id})

    end
    c= c-1
   :ets.insert(:eid, {"num",c})
    [{_,subList}] = :ets.lookup(:subTable, uid)
    if :ets.member(:msgTable, message_id) do

    [{_,[message,_from]}] = :ets.lookup(:msgTable, message_id)
    #search if there are any mentions
    charlist = String.split(message," ")
    users = Enum.filter(charlist, fn x-> String.starts_with?(x,"@")==true end)

      Enum.each(users,fn x ->
      if(:ets.member(:mentions_table,x)) do
        [{_,msg}] = :ets.lookup(:mentions_table,x)
        msg1=msg++[message_id]
        :ets.insert(:mentions_table,{x,msg1})
      else
        :ets.insert(:mentions_table,{x,[message_id]})
      end
      end)

      # deliver tweet to all the mentions
      Enum.each(users, fn(m)->
        {_,mid}=String.split_at(m,1)

        {v, ""} = Integer.parse(mid)
        #IO.puts(v)
        mentions = v
        #IO.puts("mentions is #{mentions}")
        mPID = User.getPID(mentions)
        status = User.isOnline(mentions)

        cond do
          status == 0 ->GenServer.cast(mPID,{:addToPending,message_id,uid,mentions,2,uid})


          true-> User.receive_message(uid,mentions,message_id,2,uid)

        end

      end)


    Enum.each(subList, fn(sub)->
      subPID = User.getPID(sub)
      status = User.isOnline(sub)


      cond do
        status == 0 ->
          GenServer.cast(subPID,{:addToPending,message_id,uid,sub,type,retweet_origin})

        true->
          User.receive_message(uid,sub,message_id,type,retweet_origin)

      end

    end)
  end
    {:noreply,state}
  end

end

