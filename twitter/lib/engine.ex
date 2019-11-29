defmodule Engine do
  use GenServer
  def start_link(arg) do
    {:ok,eng_id} = GenServer.start_link(__MODULE__, arg)


  end

  def init(arg) do
    Process.flag(:trap_exit, true)
    {:ok,arg}
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
      :ets.member(:usrProcessTable, uid) ->:true
      true->:false
    end
  end

  def handle_cast({:getMentions,uid},state) do
    [{_,msg}] = :ets.lookup(:mentions_table,"@#{uid}")

    Enum.each(msg, fn(tweet)->
      [{_,[message,from]}] = :ets.lookup(:msgTable, tweet)
      IO.puts("User#{from} mentioned you: #{message}")
    end)
    {:noreply,state}
  end

  def handle_cast({:queryHashTag,hashTag},state) do
    [{_,msg}] = :ets.lookup(:hashtag_table,hashTag)
    Enum.each(msg, fn(x)->
      cond  do
        (:ets.member(:msgTable,x))->
          [{_,[message,from]}] = :ets.lookup(:msgTable, x)
          IO.puts("#{message} from User#{from}")
      end
    end)

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
    GenServer.cast(eid, {:addSub,usr,sub})
    :true
  end

  def handle_cast({:addSub,usr,sub},state) do
    [{_,subList}] = :ets.lookup(:subTable,sub)
    subList  = subList ++ [usr]
    :ets.insert(:subTable,{sub, Enum.uniq(subList)}) # uniq to prevent duplicate entries
    {:noreply,state}
  end

  def deleteUser(uid) do
    pid = User.getPID(uid)
    Process.exit(pid, :normal)
    # delete any pending message
    # :ets.delete(:pending, uid)

    # # delelte message that user had sent
    # GenServer.cast(pid, {:deleteTweets})
    # Process.exit(pid, :normal)

  end

  def preProcessMsg(msg_id) do
    [{_,eid}] = :ets.lookup(:eid, "eid")
    GenServer.cast(eid, {:preProcess,msg_id})
  end

  def handle_cast({:preProcess,msg_id},state) do
    #get msg
    [{_,[message,from]}] = :ets.lookup(:msgTable, msg_id)
      charlist = String.split(message," ")
      hashtags = Enum.filter(charlist, fn x-> String.starts_with?(x,"#")==true end)
      users = Enum.filter(charlist, fn x-> String.starts_with?(x,"@")==true end)

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
    [{_,subList}] = :ets.lookup(:subTable, uid)
    [{_,[message,from]}] = :ets.lookup(:msgTable, message_id)
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
        IO.puts(v)
        mentions = v
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
        status == 0 ->GenServer.cast(subPID,{:addToPending,message_id,uid,sub,type,retweet_origin})
        true->
          User.receive_message(uid,sub,message_id,type,retweet_origin)
      end

    end)
    {:noreply,state}
  end

end

