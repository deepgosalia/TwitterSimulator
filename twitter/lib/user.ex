defmodule User do
  use GenServer
  def start_link(usr_info) do
    {:ok,usr_process_id} = GenServer.start_link(__MODULE__, usr_info)
    usr_id = Enum.at(usr_info, 0)
    usr_pswd = Enum.at(usr_info, 1)
    live = Enum.at(usr_info, 2)
    :ets.insert(:usrProcessTable,{usr_id, [usr_pswd,live,usr_process_id]})
  end

  def init(usr_info) do
    Process.flag(:trap_exit, true)
    {:ok,usr_info}
  end

  def login(usr_id, usr_pswd) do
    pid = User.getPID(usr_id)
    GenServer.cast(pid, {:loginUser,usr_pswd,usr_id})
  end

  def logout(uid)do
    pid = User.getPID(uid)
    GenServer.cast(pid, {:logOutUser})
  end

  def isOnline(uid) do
    pid = User.getPID(uid)
    status = GenServer.call(pid, :getUserStatus)
    status
  end

  def send_message(uid,m_count, message) do
    pid = User.getPID(uid)
    id = Integer.digits(uid) ++ Integer.digits(m_count)
    id = Integer.to_string(Integer.undigits(id))

    :ets.insert(:msgTable,{id,[message,uid]})
    User.addMessageSend(id,pid)
    # send it to the engine
    GenServer.cast(pid, {:sendMsg,uid,id})
  end

  def receive_message(from,to,message_id) do
    sub = User.getPID(to)
    status = User.isOnline(to)
    cond do
      status == 0 ->GenServer.cast(sub,{:addToPending,message_id,from,to})
      true->User.addMessageRec(message_id,sub);
            GenServer.cast(sub,{:rec_msg,from,to,message_id})
    end
    # add message to its list
  end

  def getPID(uid) do
    [{_,data}] = :ets.lookup(:usrProcessTable, uid)
    pid = Enum.at(data,2)
    pid
  end

  def addMessageRec(message_id,pid) do
    GenServer.cast(pid, {:addMsgRec,message_id})
  end

  def getListRec(pid) do
    {:ok,list}=GenServer.call(pid,{:getListRec})
    list
  end

  def addMessageSend(message_id,pid) do
    GenServer.cast(pid, {:addMsgSend,message_id})
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
      {:noreply,[Enum.at(state, 0),Enum.at(state, 1),1,Enum.at(state, 3),Enum.at(state, 4)]}
    end
    {:noreply,state}
  end


  # TODO add whether it was a mention or retweet
  def handle_cast({:displayPendingMsg,uid},state) do


    pid = User.getPID(uid)


    cond do
      :ets.member(:pending, uid) -> [{_,list}]=:ets.lookup(:pending, uid)
      Enum.each(list, fn([m,f])->
        #User.addMesageRec(m,pid)
        GenServer.cast(pid, {:addMsgRec,m})
        GenServer.cast(pid, {:rec_msg,f,uid,m})
      end)
      true->IO.puts("no tweets")
    end







    # add it to the current state

    {:noreply,state}
  end



  def handle_cast({:addToPending,message_id,from,to},state) do
    #IO.inspect(:ets.lookup(:pending, to))
    cond do
      :ets.member(:pending, to) -> [{_,curr_list}]=:ets.lookup(:pending, to)
            curr_list=curr_list ++ [[message_id,from]]
            :ets.insert(:pending, {to,curr_list})
      true->:ets.insert(:pending, {to,[[message_id,from]]})
    end
    {:noreply,state}
  end

  def handle_cast({:logOutUser},state) do
    # here we simply change the state of the user
    {:noreply,[Enum.at(state, 0),Enum.at(state, 1),0,Enum.at(state, 3),Enum.at(state, 4)]}
  end

  def handle_cast({:addMsgSend,message_id},state) do
    #get list
    list = Enum.at(state,4)
    # append new message id
    list = list ++ [message_id]
    {:noreply, [Enum.at(state, 0),Enum.at(state, 1),Enum.at(state, 2),Enum.at(state, 3),list]}
  end

  def handle_cast({:addMsgRec,message_id},state) do
    list = Enum.at(state,3)
    # append new message id
    list = list ++ [message_id]
    {:noreply, [Enum.at(state, 0),Enum.at(state, 1),Enum.at(state, 2),list,Enum.at(state, 4)]}
  end

  def handle_cast({:rec_msg,from,to,message_id},state) do
    #:ets.insert(:msgTable,{time_stamp,message})
    [{_,[message,from]}] = :ets.lookup(:msgTable, message_id)
    IO.puts("User#{to}: #{message} from #{from}")
    {:noreply,state}
  end

  def handle_cast({:sendMsg,uid,msg},state) do
    Engine.distributeMsg(uid,msg);
    {:noreply,state}
  end

  def handle_cast({:getSubMsg,sub},state) do

    #[{_,data}] = :ets.lookup(:usrProcessTable, usr)
    #subPID = Enum.at(data,2)
    # get entire msg list of that user
    list = Enum.at(state, 3)
   # IO.inspect(list)
    # for each message search in table
    IO.puts("Here are your result")
    Enum.each(list, fn (message_id) ->
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
