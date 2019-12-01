defmodule User do
  use GenServer
  def start_link(usr_info) do
    {:ok,usr_process_id} = GenServer.start_link(__MODULE__, usr_info)
    usr_id = Enum.at(usr_info, 0)
    usr_pswd = Enum.at(usr_info, 1)
    live = Enum.at(usr_info, 2)

    :ets.insert(:usrProcessTable,{usr_id, [usr_pswd,live,usr_process_id]})
    :ets.insert(:subTable, {usr_id,[]})
    :ets.insert(:mentions_table, {usr_id,[]})
    :ets.insert(:pending, {usr_id,[]})
  end

  def init(usr_info) do
    Process.flag(:trap_exit, true)
    {:ok,usr_info}
  end

  def login(usr_id, usr_pswd) do
    IO.inspect("Checking credentials of User #{usr_id}")
    pid = User.getPID(usr_id)
    GenServer.cast(pid, {:loginUser,usr_pswd,usr_id})
  end

  def logout(uid)do
    pid = User.getPID(uid)
    GenServer.cast(pid, {:logOutUser})
    IO.puts("User #{uid} logged out")
  end

  def isOnline(uid) do
    pid = User.getPID(uid)
    status = GenServer.call(pid, :getUserStatus,:infinity)
    status
  end

  def getFeed(uid,t) do
    pid = User.getPID(uid)
    msg=GenServer.call(pid, {:get_tweets}, :infinity)
    cond do
      msg != [] -> Enum.each(msg, fn([msg_id,type,retweet])->
        [{_,[message,from]}] = :ets.lookup(:msgTable, msg_id)
       # IO.puts("#{type} #{t}")
        cond do
          type == 1 and t == type-># means retweet
          IO.puts("(Retweet---->)User #{uid}: User#{retweet} retweeted tweet of User #{from}: #{message}")
          type == 2 and t == type-> # means mention
          IO.puts("User #{uid}: User#{retweet} mentioned you in tweet: #{message}")
          type == 0 and t == type->IO.puts("User #{uid}: User #{from} tweeted #{message}: Tweet ID: #{msg_id}")
          true -> :true
        end

      end)
      true->:true
    end
  end

  def handle_call({:get_tweets},_from,state) do
    [_uid,_upd,_l,r,_s,_count] = state
    {:reply,r,state}
  end

  def getMessageCount(uid) do
    pid = User.getPID(uid)
    count=GenServer.call(pid, {:getCount})
    count
  end

  # send the count and also update it
  def handle_call({:getCount},_from,state) do
    [uid,upd,l,r,s,count] = state
    {:reply,Enum.at(state, 5),[uid,upd,l,r,s,count+1]}
  end

  def handle_cast({:deleteTweets},state) do
    [uid,upd,l,_r,s,count] = state
    :ets.delete(:usrProcessTable,uid)
    Enum.each(s, fn(m_id) ->
      if (:ets.member(:msgTable,m_id)) do
        :ets.delete(:msgTable,m_id)
      end
    end)
    {:noreply,[uid,upd,l,[],[],count]}
  end


  def retweet(uid) do
    pid = User.getPID(uid)
    # get all received message
    GenServer.cast(pid,{:retweet,uid})
    Process.sleep(1000)
  end

  def handle_cast({:retweet,uid},state) do
    rec_msg = Enum.at(state,3)
    if rec_msg==[]  do
      IO.puts("No Tweets to retweet")
      {:noreply,state}
    else
      [msg_id,_type,_retweet_origin] = Enum.random(rec_msg)
    # send it to subscribers
    [{_,[message,from]}] = :ets.lookup(:msgTable, msg_id)
    pid = User.getPID(uid)
    User.addMessageSend(msg_id,1,from,pid)
    Process.sleep(100)
    # send it to the engine
    IO.puts("You (User #{uid})  retweeted tweet: #{message} of User #{from}")
    GenServer.cast(pid, {:sendMsg,uid,msg_id,1,uid})
    Process.sleep(100)
    {:noreply, state}
    end


  end

  def send_message(uid, message) do

    pid = User.getPID(uid)
    m_count = User.getMessageCount(uid)
    id = Integer.digits(uid) ++ Integer.digits(m_count)
    id = Integer.to_string(Integer.undigits(id))

    IO.puts("#{message} is #{id}")
    :ets.insert(:msgTable,{id,[message,uid]})
    #add to message list
    User.addMessageSend(id,0,0,pid)

    # send it to the engine
    GenServer.cast(pid, {:sendMsg,uid,id,0,0})

  end

  def addMessageSend(message_id,type,retweet_origin,pid) do
    GenServer.cast(pid, {:addMsgSend,message_id,type,retweet_origin})
  end

  def handle_cast({:addMsgSend,message_id,type,retweet_origin},state) do

    [uid,upd,l,r,s,count] = state
    #get list
    list = s
    # append new message id
    list = list ++ [[message_id,type,retweet_origin]]
    {:noreply, [uid,upd,l,r,list,count]}
  end

  def handle_cast({:sendMsg,uid,msg,type,retweet_origin},state) do


    Engine.preProcessMsg(msg)
    Engine.distributeMsg(uid,msg,type,retweet_origin)
    {:noreply,state}
  end


  def receive_message(from,to,message_id,type,retweet_origin) do

    sub = User.getPID(to)
    User.addMessageRec(message_id,type,retweet_origin,sub)
    GenServer.cast(sub,{:rec_msg,from,to,message_id,type,retweet_origin})

    # add message to its list
  end

  def addMessageRec(message_id,type,retweet_origin,pid) do
    GenServer.cast(pid, {:addMsgRec,message_id,type,retweet_origin})

  end

  def handle_cast({:addMsgRec,message_id,type,retweet_origin},state) do
    [uid,upd,l,r,s,count] = state
    list = r
    # append new message id
    list = list ++ [[message_id,type,retweet_origin]]
    {:noreply,[uid,upd,l,list,s,count]}
  end

  def handle_cast({:rec_msg,from,to,message_id,type,retweet_origin},state) do
    #:ets.insert(:msgTable,{time_stamp,message})
    [{_,[message,_f]}] = :ets.lookup(:msgTable, message_id)
    cond do
      type==1 -># means retweet
      IO.puts("User#{to}: User#{from} retweeted tweet of User#{retweet_origin}: #{message}")
      type==2 -> # means mention
      IO.puts("User#{to}: User#{retweet_origin} mentioned you in tweet: #{message}")
      true->IO.puts("User #{to}: User #{from} tweeted #{message}: Tweet ID: #{message_id}")
    end
    {:noreply,state}
  end


  def getPID(uid) do
    #IO.puts(uid)
    [{_,data}] = :ets.lookup(:usrProcessTable, uid)
    pid = Enum.at(data,2)
    pid
  end

  def getListRec(pid) do
    {:ok,list}=GenServer.call(pid,{:getListRec})
    list
  end

  def getListSend(pid) do
    {:ok,list}=GenServer.call(pid,{:getListSend})
    list
  end

  def handle_cast({:loginUser,pswd,uid},state) do
    [{_,data}] = :ets.lookup(:usrProcessTable, uid)
    p = Enum.at(data, 0)
    if(p==pswd) do
      IO.puts("User#{uid} logged in")
      pid = User.getPID(uid)
      GenServer.cast(pid,{:displayPendingMsg,uid})

      {:noreply,[Enum.at(state, 0),Enum.at(state, 1),1,Enum.at(state, 3),Enum.at(state, 4),Enum.at(state, 5)]}
    end
    {:noreply,state}
  end
  # TODO add whether it was a mention or retweet
  def handle_cast({:displayPendingMsg,uid},state) do
    pid = User.getPID(uid)

    cond do
      :ets.member(:pending, uid) -> [{_,list}]=:ets.lookup(:pending, uid)

      Enum.each(list, fn([m,_f,t,o])->
        #User.addMesageRec(m,pid)
        GenServer.cast(pid, {:addMsgRec,m,t,o})

        #GenServer.cast(pid, {:rec_msg,f,uid,m})
      end)
      true->IO.puts("no tweets")
    end
    # add it to the current state

    {:noreply,state}
  end

  def handle_cast({:addToPending,message_id,from,to,type,retweet_origin},state) do

    #IO.inspect(:ets.lookup(:pending, to))
    IO.puts("User not live...add to server")
    cond do
      :ets.member(:pending, to) -> [{_,curr_list}]=:ets.lookup(:pending, to)
            curr_list=curr_list ++ [[message_id,from,type,retweet_origin]]

            :ets.insert(:pending, {to,curr_list})


      true->:ets.insert(:pending, {to,[[message_id,from,type,retweet_origin]]})


    end

    {:noreply,state}
  end

  def handle_cast({:logOutUser},state) do

    # here we simply change the state of the user
    {:noreply,[Enum.at(state, 0),Enum.at(state, 1),0,Enum.at(state, 3),Enum.at(state, 4),Enum.at(state, 5)]}
  end

  def handle_cast({:getSubMsg,sub},state) do

    #[{_,data}] = :ets.lookup(:usrProcessTable, usr)
    #subPID = Enum.at(data,2)
    # get entire msg list of that user
    list = Enum.at(state, 3)
   # IO.inspect(list)
    # for each message search in table
    IO.puts("Here are your result")
    Enum.each(list, fn ([message_id,_type,_retweet_origin]) ->
      [{_,[message,from]}] = :ets.lookup(:msgTable, message_id)
      if from == sub do
        IO.puts("Tweet: #{message} from #{from}")
      end
    end)
    {:noreply,state}
  end

  def handle_call(:getUserStatus,_from, usr_info) do
    {:reply,Enum.at(usr_info,2),usr_info}
  end

  def handle_call({:getListRec},_from,state) do
    {:reply, Enum.at(state, 3),state}
  end

  def handle_call({:getListSend},_from,state) do
    {:reply, Enum.at(state, 4),state}
  end

end
